import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_stage_runtime_admission.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_stage_occupancy_runtime.dart';
import 'package:wuxia_idle/features/mainline/domain/mentor_insight_policy.dart';

import '../../../support/dart_source_contract.dart';

const _unblocked = MentorInsightBlockingStatus();

ActivityParticipationRequest _request() => ActivityParticipationRequest(
  contentId: 'mainline_1_1',
  contentKind: ActivityContentKind.mainline,
  characterId: 42,
  loadoutPlanId: 'persistent_plan_42',
  participation: ActivityParticipationMode.direct,
  controller: ActivityController.human,
  clock: ActivityClock.realtime,
  entryKind: ActivityEntryKind.firstClear,
);

MentorInsightChoice _choice(String stageId, [int? characterId]) =>
    MentorInsightChoice(stageId: stageId, menteeCharacterId: characterId);

MentorInsightCompanion _companion(String stageId, int characterId) =>
    MentorInsightCompanion(stageId: stageId, characterId: characterId);

MainlineStageRuntimeAdmissionPrepared _prepareAdmission({
  required MentorInsightStageOccupancyRuntime occupancyPredecessor,
  required MentorInsightChoice mentorChoice,
  String stageId = 'stage_a',
  MentorInsightBlockingStatus blockingStatus = _unblocked,
}) => prepareMainlineStageRuntimeAdmission(
  request: _request(),
  currentLeaderId: 7,
  requestedIdleEligible: true,
  runId: 'run_1',
  stageId: stageId,
  loadoutSnapshotId: 'opaque_snapshot_1',
  occupancyPredecessor: occupancyPredecessor,
  mentorChoice: mentorChoice,
  blockingStatus: blockingStatus,
);

MainlineStageRuntimeAdmission _admit({
  required MentorInsightStageOccupancyRuntime occupancyPredecessor,
  required MentorInsightChoice mentorChoice,
  String stageId = 'stage_a',
}) => _prepareAdmission(
  occupancyPredecessor: occupancyPredecessor,
  mentorChoice: mentorChoice,
  stageId: stageId,
).commit(occupancyPredecessor);

Object _captureError(void Function() action) {
  try {
    action();
  } catch (error) {
    return error;
  }
  fail('expected an error');
}

void main() {
  group('admission provenance', () {
    test('non-empty choice retains the exact newly admitted companion', () {
      final occupancyPredecessor = MentorInsightStageOccupancyRuntime.empty();
      final prepared = _prepareAdmission(
        occupancyPredecessor: occupancyPredecessor,
        mentorChoice: _choice('stage_a', 91),
      );

      expect(prepared.admittedCompanion, isNotNull);
      expect(
        prepared.admittedCompanion,
        same(prepared.occupancyNext.companion),
      );

      final admission = prepared.commit(occupancyPredecessor);
      expect(admission.admittedCompanion, same(prepared.admittedCompanion));
      expect(
        admission.admittedCompanion,
        same(admission.occupancyRuntime.snapshot.companion),
      );
      expect(admission.admittedCompanion, _companion('stage_a', 91));
    });

    test('empty choice stays null over an occupied predecessor', () {
      final oldCompanion = _companion('stage_old', 51);
      final occupancyPredecessor = MentorInsightStageOccupancyRuntime.restore(
        revision: 7,
        companion: oldCompanion,
      );
      final oldSnapshot = occupancyPredecessor.snapshot;
      final prepared = _prepareAdmission(
        occupancyPredecessor: occupancyPredecessor,
        mentorChoice: _choice('stage_a'),
        blockingStatus: const MentorInsightBlockingStatus(
          inRetreat: true,
          inExpedition: true,
          inBossGauntlet: true,
          inHealingRecovery: true,
        ),
      );

      expect(prepared.admittedCompanion, isNull);
      expect(prepared.occupancyNext, same(oldSnapshot));

      final admission = prepared.commit(occupancyPredecessor);
      expect(admission.admittedCompanion, isNull);
      expect(admission.occupancyRuntime.snapshot, same(oldSnapshot));
      expect(admission.occupancyRuntime.snapshot.revision, 7);
      expect(admission.occupancyRuntime.snapshot.companion, same(oldCompanion));
    });
  });

  group('prepared mainline stage release', () {
    test('all four reasons prepare and publish one exact release', () {
      expect(MentorInsightReleaseReason.values, [
        MentorInsightReleaseReason.successSettlement,
        MentorInsightReleaseReason.failureSettlement,
        MentorInsightReleaseReason.explicitExit,
        MentorInsightReleaseReason.idempotentRecoverySettlement,
      ]);

      for (final releaseReason in MentorInsightReleaseReason.values) {
        final admission = _admit(
          occupancyPredecessor: MentorInsightStageOccupancyRuntime.empty(),
          mentorChoice: _choice('stage_a', 91),
        );
        final releasePredecessor = admission.occupancyRuntime;
        final base = releasePredecessor.snapshot;

        final prepared = prepareMainlineStageRuntimeRelease(
          admission: admission,
          releaseReason: releaseReason,
        );

        expect(prepared.admission, same(admission));
        expect(prepared.releaseReason, same(releaseReason));
        expect(prepared.releasePredecessor, same(releasePredecessor));
        expect(prepared.occupancyBase, same(base));
        expect(prepared.occupancyNext.revision, base.revision + 1);
        expect(prepared.occupancyNext.companion, isNull);
        expect(prepared.occupancyMutations, hasLength(1));
        final mutation = prepared.occupancyMutations.single;
        expect(mutation, isA<ReleaseMentorInsightStageOccupancy>());
        final release = mutation as ReleaseMentorInsightStageOccupancy;
        expect(release.companion, same(admission.admittedCompanion));
        expect(release.reason, same(releaseReason));
        expect(
          () => prepared.occupancyMutations.clear(),
          throwsUnsupportedError,
        );
        expect(releasePredecessor.snapshot, same(base));

        final result = prepared.commit(releasePredecessor);

        expect(result.admission, same(admission));
        expect(result.releaseReason, same(releaseReason));
        expect(result.occupancyRuntime.snapshot, same(prepared.occupancyNext));
        expect(result.occupancyRuntime.snapshot.companion, isNull);
        expect(releasePredecessor.snapshot, same(base));
      }
    });

    test('null provenance is a strict no-op over old occupancy', () {
      final oldCompanion = _companion('stage_old', 61);
      final admission = _admit(
        occupancyPredecessor: MentorInsightStageOccupancyRuntime.restore(
          revision: 11,
          companion: oldCompanion,
        ),
        mentorChoice: _choice('stage_a'),
      );
      final releasePredecessor = admission.occupancyRuntime;
      final oldSnapshot = releasePredecessor.snapshot;

      final prepared = prepareMainlineStageRuntimeRelease(
        admission: admission,
        releaseReason: MentorInsightReleaseReason.explicitExit,
      );

      expect(prepared.admission, same(admission));
      expect(prepared.releaseReason, MentorInsightReleaseReason.explicitExit);
      expect(prepared.releasePredecessor, same(releasePredecessor));
      expect(prepared.occupancyBase, same(oldSnapshot));
      expect(prepared.occupancyNext, same(oldSnapshot));
      expect(prepared.occupancyMutations, isEmpty);

      final result = prepared.commit(releasePredecessor);
      expect(result.occupancyRuntime, isNot(same(releasePredecessor)));
      expect(result.occupancyRuntime.snapshot, same(oldSnapshot));
      expect(result.occupancyRuntime.snapshot.revision, 11);
      expect(result.occupancyRuntime.snapshot.companion, same(oldCompanion));
    });

    test('foreign predecessor rejects without consuming the release', () {
      final admission = _admit(
        occupancyPredecessor: MentorInsightStageOccupancyRuntime.empty(),
        mentorChoice: _choice('stage_a', 71),
      );
      final releasePredecessor = admission.occupancyRuntime;
      final prepared = prepareMainlineStageRuntimeRelease(
        admission: admission,
        releaseReason: MentorInsightReleaseReason.failureSettlement,
      );

      expect(
        () => prepared.commit(MentorInsightStageOccupancyRuntime.empty()),
        throwsStateError,
      );

      final result = prepared.commit(releasePredecessor);
      expect(result.occupancyRuntime.snapshot.companion, isNull);
    });

    test('stale predecessor rejects without consuming the release', () {
      final admission = _admit(
        occupancyPredecessor: MentorInsightStageOccupancyRuntime.empty(),
        mentorChoice: _choice('stage_a', 81),
      );
      final releasePredecessor = admission.occupancyRuntime;
      final prepared = prepareMainlineStageRuntimeRelease(
        admission: admission,
        releaseReason: MentorInsightReleaseReason.successSettlement,
      );
      final stale = releasePredecessor.commit(
        releasePredecessor.prepare(const []),
      );

      expect(() => prepared.commit(stale), throwsStateError);

      final result = prepared.commit(releasePredecessor);
      expect(result.occupancyRuntime.snapshot.companion, isNull);
    });

    test('double commit is rejected by the release single-use guard', () {
      final admission = _admit(
        occupancyPredecessor: MentorInsightStageOccupancyRuntime.empty(),
        mentorChoice: _choice('stage_a', 91),
      );
      final releasePredecessor = admission.occupancyRuntime;
      final prepared = prepareMainlineStageRuntimeRelease(
        admission: admission,
        releaseReason: MentorInsightReleaseReason.successSettlement,
      );

      prepared.commit(releasePredecessor);
      final error = _captureError(() => prepared.commit(releasePredecessor));

      expect(
        error,
        isA<StateError>().having(
          (value) => value.message,
          'message',
          'Prepared mainline stage runtime release was already committed',
        ),
      );
    });

    test('sibling releases can commit from the exact predecessor', () {
      final admission = _admit(
        occupancyPredecessor: MentorInsightStageOccupancyRuntime.empty(),
        mentorChoice: _choice('stage_a', 101),
      );
      final releasePredecessor = admission.occupancyRuntime;
      final first = prepareMainlineStageRuntimeRelease(
        admission: admission,
        releaseReason: MentorInsightReleaseReason.successSettlement,
      );
      final sibling = prepareMainlineStageRuntimeRelease(
        admission: admission,
        releaseReason: MentorInsightReleaseReason.explicitExit,
      );

      final firstResult = first.commit(releasePredecessor);
      final siblingResult = sibling.commit(releasePredecessor);

      expect(firstResult.occupancyRuntime.snapshot.companion, isNull);
      expect(siblingResult.occupancyRuntime.snapshot.companion, isNull);
      expect(
        firstResult.occupancyRuntime.snapshot,
        isNot(same(siblingResult.occupancyRuntime.snapshot)),
      );
      expect(
        firstResult.occupancyRuntime.snapshot.revision,
        siblingResult.occupancyRuntime.snapshot.revision,
      );
    });

    test('R15 stage and character mismatches publish no successor', () {
      final admission = _admit(
        occupancyPredecessor: MentorInsightStageOccupancyRuntime.empty(),
        mentorChoice: _choice('stage_a', 111),
      );
      final releasePredecessor = admission.occupancyRuntime;
      final base = releasePredecessor.snapshot;
      final mismatches = [
        _companion('stage_other', 111),
        _companion('stage_a', 112),
      ];

      for (final mismatch in mismatches) {
        expect(
          () => releasePredecessor.prepare([
            ReleaseMentorInsightStageOccupancy(
              companion: mismatch,
              reason: MentorInsightReleaseReason.failureSettlement,
            ),
          ]),
          throwsStateError,
        );
        expect(releasePredecessor.snapshot, same(base));
        expect(releasePredecessor.snapshot.companion, same(base.companion));
      }
    });

    test('R15 admission failures still pass through unchanged', () {
      final occupancyPredecessor = MentorInsightStageOccupancyRuntime.empty();
      final error = _captureError(
        () => _prepareAdmission(
          occupancyPredecessor: occupancyPredecessor,
          mentorChoice: _choice('stage_a', 121),
          blockingStatus: const MentorInsightBlockingStatus(inRetreat: true),
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
      expect(occupancyPredecessor.snapshot.revision, 0);
      expect(occupancyPredecessor.snapshot.companion, isNull);
    });
  });

  test('source keeps release publication private and policy-neutral', () {
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
        r'^MainlineStageRuntimeReleasePrepared '
        r'prepareMainlineStageRuntimeRelease\(',
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
      reason: 'every committable R15 successor must stay library-private',
    );
    expect(
      RegExp(
        r'final\s+MentorInsightStageOccupancyPreparedSuccessor\s+'
        r'_occupancyPreparedSuccessor;',
      ).allMatches(source),
      hasLength(2),
    );

    expect(
      contract.memberAccessCount(
        'hasCompanion',
        receiverSource: 'mentorChoice',
      ),
      1,
    );
    expect(
      contract.memberAccessCount(
        'companion',
        receiverSource: 'occupancyPreparedSuccessor.next',
      ),
      1,
    );
    expect(
      contract.memberAccessCount(
        'occupancyRuntime',
        receiverSource: 'admission',
      ),
      1,
    );
    expect(
      contract.methodCalls(
        targetSource: 'releasePredecessor',
        methodName: 'prepare',
      ),
      hasLength(1),
    );
    expect(
      contract.methodCalls(
        targetSource: 'exactPredecessor',
        methodName: 'commit',
      ),
      hasLength(1),
    );
    expect(contract.memberAccessCount('stageId', receiverSource: 'active'), 1);
    expect(
      contract.memberAccessCount('characterId', receiverSource: 'active'),
      1,
    );

    for (final forbiddenIdentifier in const [
      'MentorInsightClaimPolicy',
      'RewardClaimKey',
      'RewardGrantGuard',
      'MentorInsightGrowthTarget',
      'BattleSettlement',
      'BattleResult',
      'ActivityOccupancy',
      'CharacterOccupancyService',
      'GameRepository',
      'SaveData',
      'Isar',
    ]) {
      expect(
        contract.identifierCount(forbiddenIdentifier),
        0,
        reason: forbiddenIdentifier,
      );
    }
    for (final forbiddenMember in const [
      'settlement',
      'result',
      'exit',
      'claim',
      'reward',
      'grant',
    ]) {
      expect(
        contract.memberAccessCount(forbiddenMember),
        0,
        reason: forbiddenMember,
      );
    }
    for (final forbiddenText in const [
      'try {',
      'catch',
      'switch',
      'fallback',
      'default',
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
