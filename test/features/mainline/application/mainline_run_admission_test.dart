import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_run_admission.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_participation_policy.dart';

ActivityParticipationRequest _request({
  int characterId = 42,
  ActivityController controller = ActivityController.human,
  ActivityClock clock = ActivityClock.realtime,
  ActivityEntryKind entryKind = ActivityEntryKind.replay,
}) => ActivityParticipationRequest(
  contentId: 'mainline_1_1',
  contentKind: ActivityContentKind.mainline,
  characterId: characterId,
  loadoutPlanId: 'persistent_plan_42',
  participation: ActivityParticipationMode.direct,
  controller: controller,
  clock: clock,
  entryKind: entryKind,
);

MainlineRunAdmission _admit(
  ActivityParticipationRequest request, {
  int currentLeaderId = 7,
  bool requestedIdleEligible = true,
  String runId = 'run_1',
  String stageId = 'mainline_1_1',
  String loadoutSnapshotId = 'opaque_snapshot_1',
}) => admitMainlineRun(
  request: request,
  currentLeaderId: currentLeaderId,
  requestedIdleEligible: requestedIdleEligible,
  runId: runId,
  stageId: stageId,
  loadoutSnapshotId: loadoutSnapshotId,
);

Object _captureError(void Function() action) {
  try {
    action();
  } catch (error) {
    return error;
  }
  fail('expected an error');
}

void main() {
  group('participant admission', () {
    test('realtime replay keeps the requested eligible participant', () {
      for (final controller in ActivityController.values) {
        final request = _request(controller: controller);

        final admission = _admit(request);

        expect(admission.request, same(request), reason: controller.name);
        expect(admission.selection.participantId, 42);
        expect(
          admission.selection.source,
          MainlineParticipantSource.requestedIdleEligible,
        );
        expect(admission.run.participantId, 42);
      }
    });

    test('headless replay always begins the run with current leader', () {
      for (final controller in ActivityController.values) {
        for (final eligible in [true, false]) {
          final admission = _admit(
            _request(controller: controller, clock: ActivityClock.headless),
            requestedIdleEligible: eligible,
          );

          expect(admission.selection.participantId, 7);
          expect(
            admission.selection.source,
            MainlineParticipantSource.currentLeader,
          );
          expect(admission.run.participantId, 7);
        }
      }
    });

    test('first clear and sweep begin the run with current leader', () {
      for (final entryKind in [
        ActivityEntryKind.firstClear,
        ActivityEntryKind.sweep,
      ]) {
        for (final clock in ActivityClock.values) {
          final admission = _admit(
            _request(clock: clock, entryKind: entryKind),
            requestedIdleEligible: false,
          );

          expect(admission.selection.participantId, 7, reason: '$entryKind');
          expect(
            admission.selection.source,
            MainlineParticipantSource.currentLeader,
          );
          expect(admission.run.participantId, 7);
        }
      }
    });
  });

  group('delegation and failure', () {
    test(
      'policy rejection preserves its type and message with no admission',
      () {
        final request = _request();
        MainlineRunAdmission? published;

        final admissionError = _captureError(
          () => published = _admit(request, requestedIdleEligible: false),
        );

        expect(
          admissionError,
          isA<MainlineParticipationRefusedError>().having(
            (error) => error.message,
            'message',
            'Visible replay requires the requested character to be '
                'eligible and idle; no leader fallback',
          ),
        );
        expect(published, isNull);
      },
    );

    test(
      'policy runs before MainlineRun validation and no fallback occurs',
      () {
        final request = _request();

        final error = _captureError(
          () => _admit(
            request,
            requestedIdleEligible: false,
            runId: ' ',
            stageId: ' ',
            loadoutSnapshotId: ' ',
          ),
        );

        expect(error, isA<MainlineParticipationRefusedError>());
      },
    );

    test('run arguments and actual owner come from explicit inputs', () {
      final request = _request(characterId: 91);

      final admission = _admit(
        request,
        runId: 'run_exact',
        stageId: 'mainline_exact',
        loadoutSnapshotId: 'opaque_snapshot_exact',
      );

      expect(admission.request, same(request));
      expect(admission.selection.participantId, 91);
      expect(admission.run.runId, 'run_exact');
      expect(admission.run.currentStageId, 'mainline_exact');
      expect(
        admission.run.loadoutSnapshots.single.loadoutSnapshotId,
        'opaque_snapshot_exact',
      );
      expect(admission.run.participantId, admission.selection.participantId);
      expect(
        admission.run.growthAndInjuryOwnerId,
        admission.selection.actualParticipantId,
      );
      expect(
        admission.run.loadoutSnapshots.single.loadoutSnapshotId,
        isNot(request.loadoutPlanId),
      );
    });

    test('each successful call returns fresh admission selection and run', () {
      final request = _request();

      final first = _admit(request);
      final second = _admit(request);

      expect(first, isNot(same(second)));
      expect(first.request, same(request));
      expect(second.request, same(request));
      expect(first.selection, isNot(same(second.selection)));
      expect(first.run, isNot(same(second.run)));
      expect(
        first.run.loadoutSnapshots.single,
        isNot(same(second.run.loadoutSnapshots.single)),
      );
    });

    test('run validation failure returns no partial admission', () {
      MainlineRunAdmission? published;

      expect(
        () => published = _admit(_request(), runId: ' '),
        throwsArgumentError,
      );

      expect(published, isNull);
    });
  });

  test('source is a single thin admission seam without inferred policy', () {
    final source = File(
      'lib/features/mainline/application/mainline_run_admission.dart',
    ).readAsStringSync();
    final imports = RegExp(
      "^import '([^']+)';",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();

    expect(imports, [
      '../../battle/domain/phase0a/activity_participation_request.dart',
      '../domain/mainline_participation_policy.dart',
      '../domain/mainline_run.dart',
    ]);
    expect(
      RegExp(
        r'^MainlineRunAdmission admitMainlineRun\(',
        multiLine: true,
      ).allMatches(source),
      hasLength(1),
    );
    expect(
      source.indexOf('MainlineParticipationPolicy.resolveParticipant'),
      lessThan(source.indexOf('MainlineRun.begin')),
    );
    expect(source, contains('participantId: selection.participantId'));
    for (final forbidden in const [
      'CurrentLeaderResolver',
      'CharacterAvailability',
      'GameRepository',
      'SaveData',
      'rootBundle',
      'occupancy',
      'injury',
      'loadoutPlanId',
      '.characterId',
      '.contentKind',
      '.participation',
      '.controller',
      '.clock',
      '.entryKind',
      'fallback',
      'catch',
      'switch',
      'repository',
      'persistence',
      'host',
      "'/data/",
      'candidate',
      'tuning',
      'preset',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
