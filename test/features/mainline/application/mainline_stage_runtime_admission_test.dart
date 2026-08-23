import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_stage_runtime_admission.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_stage_occupancy_runtime.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_participation_policy.dart';
import 'package:wuxia_idle/features/mainline/domain/mentor_insight_policy.dart';

import '../../../support/dart_source_contract.dart';

const _unblocked = MentorInsightBlockingStatus();

ActivityParticipationRequest _request({
  ActivityContentKind contentKind = ActivityContentKind.mainline,
  ActivityParticipationMode participation = ActivityParticipationMode.direct,
  ActivityEntryKind entryKind = ActivityEntryKind.firstClear,
  int characterId = 42,
}) => ActivityParticipationRequest(
  contentId: 'mainline_1_1',
  contentKind: contentKind,
  characterId: characterId,
  loadoutPlanId: 'persistent_plan_42',
  participation: participation,
  controller: ActivityController.human,
  clock: ActivityClock.realtime,
  entryKind: entryKind,
);

MentorInsightChoice _choice(String stageId, [int? characterId]) =>
    MentorInsightChoice(stageId: stageId, menteeCharacterId: characterId);

MentorInsightCompanion _companion(String stageId, int characterId) =>
    MentorInsightCompanion(stageId: stageId, characterId: characterId);

MainlineStageRuntimeAdmissionPrepared _prepare({
  ActivityParticipationRequest? request,
  int currentLeaderId = 7,
  bool requestedIdleEligible = true,
  String runId = 'run_1',
  String stageId = 'stage_a',
  String loadoutSnapshotId = 'opaque_snapshot_1',
  MentorInsightStageOccupancyRuntime? occupancyPredecessor,
  MentorInsightChoice? mentorChoice,
  MentorInsightBlockingStatus blockingStatus = _unblocked,
}) => prepareMainlineStageRuntimeAdmission(
  request: request ?? _request(),
  currentLeaderId: currentLeaderId,
  requestedIdleEligible: requestedIdleEligible,
  runId: runId,
  stageId: stageId,
  loadoutSnapshotId: loadoutSnapshotId,
  occupancyPredecessor:
      occupancyPredecessor ?? MentorInsightStageOccupancyRuntime.empty(),
  mentorChoice: mentorChoice ?? _choice(stageId, 91),
  blockingStatus: blockingStatus,
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
  group('prepared mainline stage admission', () {
    test('keeps exact R14 and R15 values until one commit publishes', () {
      final request = _request();
      final choice = _choice('stage_exact', 91);
      const blockingStatus = MentorInsightBlockingStatus();
      final predecessor = MentorInsightStageOccupancyRuntime.empty();
      final base = predecessor.snapshot;

      final prepared = _prepare(
        request: request,
        currentLeaderId: 17,
        requestedIdleEligible: false,
        runId: 'run_exact',
        stageId: 'stage_exact',
        loadoutSnapshotId: 'opaque_snapshot_exact',
        occupancyPredecessor: predecessor,
        mentorChoice: choice,
        blockingStatus: blockingStatus,
      );

      expect(prepared.runAdmission.request, same(request));
      expect(prepared.runAdmission.selection.participantId, 17);
      expect(prepared.runAdmission.run.runId, 'run_exact');
      expect(prepared.runAdmission.run.currentStageId, 'stage_exact');
      expect(
        prepared.runAdmission.run.loadoutSnapshots.single.loadoutSnapshotId,
        'opaque_snapshot_exact',
      );
      expect(prepared.occupancyPredecessor, same(predecessor));
      expect(prepared.occupancyBase, same(base));
      expect(prepared.occupancyMutations, hasLength(1));
      final mutation = prepared.occupancyMutations.single;
      expect(mutation, isA<AcquireMentorInsightStageOccupancy>());
      expect(
        (mutation as AcquireMentorInsightStageOccupancy).choice,
        same(choice),
      );
      expect(mutation.blockingStatus, same(blockingStatus));
      expect(() => prepared.occupancyMutations.clear(), throwsUnsupportedError);
      expect(predecessor.snapshot, same(base));

      final admission = prepared.commit(predecessor);

      expect(admission.runAdmission, same(prepared.runAdmission));
      expect(admission.occupancyRuntime.snapshot, same(prepared.occupancyNext));
      expect(admission.occupancyRuntime.snapshot.revision, 1);
      expect(
        admission.occupancyRuntime.snapshot.companion,
        _companion('stage_exact', 91),
      );
      expect(predecessor.snapshot, same(base));
    });

    test('empty choice is a strict no-op even while blocked and occupied', () {
      final active = _companion('stage_active', 51);
      final predecessor = MentorInsightStageOccupancyRuntime.restore(
        revision: 7,
        companion: active,
      );
      final base = predecessor.snapshot;

      final prepared = _prepare(
        stageId: 'stage_empty',
        occupancyPredecessor: predecessor,
        mentorChoice: _choice('stage_empty'),
        blockingStatus: const MentorInsightBlockingStatus(
          inRetreat: true,
          inExpedition: true,
          inBossGauntlet: true,
          inHealingRecovery: true,
        ),
      );

      expect(prepared.occupancyNext, same(base));
      final admission = prepared.commit(predecessor);
      expect(admission.occupancyRuntime, isNot(same(predecessor)));
      expect(admission.occupancyRuntime.snapshot, same(base));
      expect(admission.occupancyRuntime.snapshot.revision, 7);
      expect(admission.occupancyRuntime.snapshot.companion, same(active));
    });

    test('separate preparations return fresh builder-owned values', () {
      final request = _request();
      final predecessor = MentorInsightStageOccupancyRuntime.empty();
      final choice = _choice('stage_fresh', 61);

      final first = _prepare(
        request: request,
        stageId: 'stage_fresh',
        occupancyPredecessor: predecessor,
        mentorChoice: choice,
      );
      final second = _prepare(
        request: request,
        stageId: 'stage_fresh',
        occupancyPredecessor: predecessor,
        mentorChoice: choice,
      );

      expect(first, isNot(same(second)));
      expect(first.runAdmission, isNot(same(second.runAdmission)));
      expect(first.occupancyNext, isNot(same(second.occupancyNext)));
      expect(first.runAdmission.request, same(request));
      expect(second.runAdmission.request, same(request));
      expect(first.occupancyPredecessor, same(predecessor));
      expect(second.occupancyPredecessor, same(predecessor));
    });
  });

  group('fail-closed preparation order', () {
    test('non-mainline request rejects before R14 and R15', () {
      final predecessor = MentorInsightStageOccupancyRuntime.empty();
      final base = predecessor.snapshot;
      MainlineStageRuntimeAdmissionPrepared? published;

      final error = _captureError(
        () => published = _prepare(
          request: _request(contentKind: ActivityContentKind.tower),
          occupancyPredecessor: predecessor,
        ),
      );

      expect(
        error,
        isA<MainlineParticipationRefusedError>().having(
          (value) => value.message,
          'message',
          'Mainline stage runtime admission covers mainline content only',
        ),
      );
      expect(published, isNull);
      expect(predecessor.snapshot, same(base));
    });

    test('every non-first-clear entry rejects before R14 and R15', () {
      for (final entryKind in [
        ActivityEntryKind.replay,
        ActivityEntryKind.sweep,
        ActivityEntryKind.offlineResume,
      ]) {
        final predecessor = MentorInsightStageOccupancyRuntime.empty();
        final base = predecessor.snapshot;

        final error = _captureError(
          () => _prepare(
            request: _request(entryKind: entryKind),
            occupancyPredecessor: predecessor,
          ),
        );

        expect(
          error,
          isA<MainlineParticipationRefusedError>().having(
            (value) => value.message,
            'message',
            'Mainline stage runtime admission covers first-clear entries only',
          ),
          reason: entryKind.name,
        );
        expect(predecessor.snapshot, same(base));
      }
    });

    test('choice stage compares literally before R14 argument validation', () {
      final predecessor = MentorInsightStageOccupancyRuntime.empty();

      final error = _captureError(
        () => _prepare(
          runId: ' ',
          stageId: ' stage_a ',
          occupancyPredecessor: predecessor,
          mentorChoice: _choice('stage_a', 71),
        ),
      );

      expect(
        error,
        isA<ArgumentError>().having(
          (value) => value.name,
          'name',
          'mentorChoice.stageId',
        ),
      );
      expect(predecessor.snapshot.revision, 0);
    });

    test('R14 policy refusal passes through without preparing occupancy', () {
      final predecessor = MentorInsightStageOccupancyRuntime.empty();
      final active = predecessor.snapshot;

      final error = _captureError(
        () => _prepare(
          request: _request(participation: ActivityParticipationMode.dispatch),
          occupancyPredecessor: predecessor,
        ),
      );

      expect(
        error,
        isA<MainlineParticipationRefusedError>().having(
          (value) => value.message,
          'message',
          'Mainline participation contract covers direct participation only',
        ),
      );
      expect(predecessor.snapshot, same(active));
    });

    test('R14 run validation passes through before R15 validation', () {
      final active = _companion('stage_a', 81);
      final predecessor = MentorInsightStageOccupancyRuntime.restore(
        revision: 4,
        companion: active,
      );
      final base = predecessor.snapshot;

      final error = _captureError(
        () => _prepare(
          runId: ' ',
          occupancyPredecessor: predecessor,
          mentorChoice: _choice('stage_a', 82),
        ),
      );

      expect(error, isA<ArgumentError>());
      expect(predecessor.snapshot, same(base));
    });

    test('each R15 blocker passes through after successful R14 admission', () {
      final blockedStatuses = [
        const MentorInsightBlockingStatus(inRetreat: true),
        const MentorInsightBlockingStatus(inExpedition: true),
        const MentorInsightBlockingStatus(inBossGauntlet: true),
        const MentorInsightBlockingStatus(inHealingRecovery: true),
      ];

      for (final blockingStatus in blockedStatuses) {
        final predecessor = MentorInsightStageOccupancyRuntime.empty();
        final base = predecessor.snapshot;
        final error = _captureError(
          () => _prepare(
            occupancyPredecessor: predecessor,
            blockingStatus: blockingStatus,
          ),
        );

        expect(
          error,
          isA<StateError>().having(
            (value) => value.message,
            'message',
            'Mentor-insight companion is activity blocked',
          ),
        );
        expect(predecessor.snapshot, same(base));
      }
    });

    test('R15 active occupancy conflicts pass through unchanged', () {
      final cases = [
        (_companion('stage_a', 91), _choice('stage_a', 91)),
        (_companion('stage_a', 91), _choice('stage_a', 92)),
        (_companion('stage_other', 91), _choice('stage_a', 91)),
      ];

      for (final (active, choice) in cases) {
        final predecessor = MentorInsightStageOccupancyRuntime.restore(
          revision: 3,
          companion: active,
        );
        final base = predecessor.snapshot;

        expect(
          () =>
              _prepare(occupancyPredecessor: predecessor, mentorChoice: choice),
          throwsStateError,
        );
        expect(predecessor.snapshot, same(base));
      }
    });
  });

  group('owner-bound commit', () {
    test(
      'foreign predecessor rejects without consuming the prepared value',
      () {
        final predecessor = MentorInsightStageOccupancyRuntime.empty();
        final foreign = MentorInsightStageOccupancyRuntime.empty();
        final prepared = _prepare(occupancyPredecessor: predecessor);

        expect(() => prepared.commit(foreign), throwsStateError);

        final admission = prepared.commit(predecessor);
        expect(admission.occupancyRuntime.snapshot.revision, 1);
      },
    );

    test('stale successor rejects without consuming the prepared value', () {
      final predecessor = MentorInsightStageOccupancyRuntime.empty();
      final prepared = _prepare(occupancyPredecessor: predecessor);
      final stale = predecessor.commit(predecessor.prepare(const []));

      expect(() => prepared.commit(stale), throwsStateError);

      final admission = prepared.commit(predecessor);
      expect(admission.occupancyRuntime.snapshot.revision, 1);
    });

    test('double commit is rejected by the R18 single-use guard', () {
      final predecessor = MentorInsightStageOccupancyRuntime.empty();
      final prepared = _prepare(occupancyPredecessor: predecessor);

      prepared.commit(predecessor);
      final error = _captureError(() => prepared.commit(predecessor));

      expect(
        error,
        isA<StateError>().having(
          (value) => value.message,
          'message',
          'Prepared mainline stage runtime admission was already committed',
        ),
      );
    });

    test('sibling commit does not invalidate the exact predecessor branch', () {
      final predecessor = MentorInsightStageOccupancyRuntime.empty();
      final first = _prepare(
        stageId: 'stage_a',
        occupancyPredecessor: predecessor,
        mentorChoice: _choice('stage_a', 101),
      );
      final sibling = _prepare(
        stageId: 'stage_b',
        occupancyPredecessor: predecessor,
        mentorChoice: _choice('stage_b', 102),
      );

      final siblingAdmission = sibling.commit(predecessor);
      final firstAdmission = first.commit(predecessor);

      expect(
        siblingAdmission.occupancyRuntime.snapshot.companion,
        _companion('stage_b', 102),
      );
      expect(
        firstAdmission.occupancyRuntime.snapshot.companion,
        _companion('stage_a', 101),
      );
      expect(predecessor.snapshot.companion, isNull);
    });

    test('matching participant and mentee IDs are not inferred as invalid', () {
      final predecessor = MentorInsightStageOccupancyRuntime.empty();
      final prepared = _prepare(
        request: _request(characterId: 42),
        currentLeaderId: 42,
        occupancyPredecessor: predecessor,
        mentorChoice: _choice('stage_a', 42),
      );

      final admission = prepared.commit(predecessor);

      expect(admission.runAdmission.run.participantId, 42);
      expect(
        admission.occupancyRuntime.snapshot.companion,
        _companion('stage_a', 42),
      );
    });
  });

  test('source is a thin ordered seam without inferred product policy', () {
    const sourcePath =
        'lib/features/mainline/application/'
        'mainline_stage_runtime_admission.dart';
    final source = File(sourcePath).readAsStringSync();
    final contract = DartSourceContract.parse(source, path: sourcePath);
    final imports = RegExp(
      "^import '([^']+)';",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();

    expect(imports, [
      '../../battle/domain/phase0a/activity_participation_request.dart',
      '../domain/mainline_participation_policy.dart',
      '../domain/mentor_insight_policy.dart',
      'mainline_run_admission.dart',
      'mentor_insight_stage_occupancy_runtime.dart',
    ]);
    expect(
      RegExp(
        r'^MainlineStageRuntimeAdmissionPrepared '
        r'prepareMainlineStageRuntimeAdmission\(',
        multiLine: true,
      ).allMatches(source),
      hasLength(1),
    );
    expect(
      RegExp(
        r'MentorInsightStageOccupancyPreparedSuccessor\s+'
        r'(?:get\s+)?(?!_)[A-Za-z]\w*',
      ).allMatches(source),
      isEmpty,
      reason: 'the committable R15 successor must stay library-private',
    );
    expect(
      RegExp(
        r'final\s+MentorInsightStageOccupancyPreparedSuccessor\s+'
        r'_occupancyPreparedSuccessor;',
      ).hasMatch(source),
      isTrue,
    );

    expect(
      contract.memberAccessCount('contentKind', receiverSource: 'request'),
      1,
    );
    expect(
      contract.memberAccessCount('entryKind', receiverSource: 'request'),
      1,
    );
    expect(
      contract.memberAccessCount('stageId', receiverSource: 'mentorChoice'),
      2,
    );
    for (final memberName in const [
      'isBlocked',
      'inRetreat',
      'inExpedition',
      'inBossGauntlet',
      'inHealingRecovery',
    ]) {
      expect(
        contract.memberAccessCount(
          memberName,
          receiverSource: 'blockingStatus',
        ),
        0,
        reason: memberName,
      );
    }

    expect(
      contract.methodCalls(targetSource: '', methodName: 'admitMainlineRun'),
      hasLength(1),
    );
    expect(
      contract.methodCalls(
        targetSource: 'occupancyPredecessor',
        methodName: 'prepare',
      ),
      hasLength(1),
    );
    expect(
      contract.methodCalls(targetSource: 'predecessor', methodName: 'commit'),
      hasLength(1),
    );
    expect(
      source.indexOf('request.contentKind'),
      lessThan(source.indexOf('request.entryKind')),
    );
    expect(
      source.indexOf('request.entryKind'),
      lessThan(source.indexOf('mentorChoice.stageId != stageId')),
    );
    expect(
      source.indexOf('mentorChoice.stageId != stageId'),
      lessThan(source.indexOf('admitMainlineRun(')),
    );
    expect(
      source.indexOf('admitMainlineRun('),
      lessThan(source.indexOf('occupancyPredecessor.prepare(')),
    );

    for (final forbiddenIdentifier in const [
      'MentorInsightClaimPolicy',
      'RewardClaimKey',
      'RewardGrantGuard',
      'MentorInsightGrowthTarget',
      'ActivityOccupancy',
      'CharacterOccupancyService',
      'GameRepository',
      'SaveData',
      'Isar',
      'CurrentLeaderResolver',
      'CharacterAvailability',
    ]) {
      expect(
        contract.identifierCount(forbiddenIdentifier),
        0,
        reason: forbiddenIdentifier,
      );
    }
    expect(
      contract.memberAccessCount(
        'menteeCharacterId',
        receiverSource: 'mentorChoice',
      ),
      0,
    );
    for (final forbiddenText in const [
      'try {',
      'catch',
      'switch',
      'fallback',
      'default',
      'claim',
      'grant',
      'rate',
      'cap',
      'repository',
      'persistence',
      'phase0a_combat_host',
      "'/data/",
      'candidate',
      'tuning',
      'rootBundle',
      'package:isar',
    ]) {
      expect(source, isNot(contains(forbiddenText)), reason: forbiddenText);
    }
  });
}
