import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_next_stage_runtime_admission.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_stage_runtime_admission.dart';
import 'package:wuxia_idle/features/mainline/application/mentor_insight_stage_occupancy_runtime.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_run.dart';
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

MainlineStageRuntimeRelease _previousRelease({
  MentorInsightStageOccupancyRuntime? occupancyPredecessor,
  int? admittedCharacterId = 91,
}) {
  final predecessor =
      occupancyPredecessor ?? MentorInsightStageOccupancyRuntime.empty();
  final admission = prepareMainlineStageRuntimeAdmission(
    request: _request(),
    currentLeaderId: 7,
    requestedIdleEligible: true,
    runId: 'run_1',
    stageId: 'stage_a',
    loadoutSnapshotId: 'snapshot_1',
    occupancyPredecessor: predecessor,
    mentorChoice: _choice('stage_a', admittedCharacterId),
    blockingStatus: _unblocked,
  ).commit(predecessor);
  final prepared = prepareMainlineStageRuntimeRelease(
    admission: admission,
    releaseReason: MentorInsightReleaseReason.successSettlement,
  );
  return prepared.commit(admission.occupancyRuntime);
}

MainlineNextStageRuntimeAdmissionPrepared _prepare({
  required MainlineStageRuntimeRelease previousRelease,
  String nextStageId = 'stage_b',
  String loadoutSnapshotId = 'snapshot_2',
  bool participantBattleEligibleForNextStage = true,
  int? mentorCharacterId = 92,
  MentorInsightBlockingStatus blockingStatus = _unblocked,
}) => prepareNextMainlineStageRuntimeAdmission(
  previousRelease: previousRelease,
  nextStageId: nextStageId,
  loadoutSnapshotId: loadoutSnapshotId,
  participantBattleEligibleForNextStage: participantBattleEligibleForNextStage,
  mentorChoice: _choice(nextStageId, mentorCharacterId),
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
  test('advances the exact run and publishes one optional occupancy', () {
    final previousRelease = _previousRelease();
    final previousRun = previousRelease.admission.runAdmission.run;
    final predecessor = previousRelease.occupancyRuntime;
    final base = predecessor.snapshot;

    final prepared = _prepare(previousRelease: previousRelease);

    expect(prepared.previousRelease, same(previousRelease));
    expect(prepared.occupancyPredecessor, same(predecessor));
    expect(prepared.run.runId, previousRun.runId);
    expect(prepared.run.participantId, previousRun.participantId);
    expect(prepared.run.currentStageId, 'stage_b');
    expect(prepared.run.currentLoadoutVersion, 2);
    expect(
      prepared.run.loadoutSnapshots.first,
      previousRun.loadoutSnapshots.first,
    );
    expect(prepared.run.loadoutSnapshots.last.loadoutSnapshotId, 'snapshot_2');
    expect(prepared.occupancyBase, same(base));
    expect(prepared.occupancyNext.revision, base.revision + 1);
    expect(prepared.occupancyMutations, hasLength(1));
    expect(
      prepared.occupancyMutations.single,
      isA<AcquireMentorInsightStageOccupancy>(),
    );
    expect(prepared.admittedCompanion, same(prepared.occupancyNext.companion));
    expect(prepared.admittedCompanion?.stageId, 'stage_b');
    expect(prepared.admittedCompanion?.characterId, 92);
    expect(previousRun.currentStageId, 'stage_a');
    expect(previousRun.currentLoadoutVersion, 1);
    expect(predecessor.snapshot, same(base));

    final result = prepared.commit(predecessor);

    expect(result.previousRelease, same(previousRelease));
    expect(result.run, same(prepared.run));
    expect(result.admittedCompanion, same(prepared.admittedCompanion));
    expect(result.occupancyRuntime.snapshot, same(prepared.occupancyNext));
    expect(predecessor.snapshot, same(base));
  });

  test('empty choice stays null and preserves the released empty snapshot', () {
    final previousRelease = _previousRelease();
    final predecessor = previousRelease.occupancyRuntime;
    final base = predecessor.snapshot;
    final prepared = _prepare(
      previousRelease: previousRelease,
      mentorCharacterId: null,
    );

    expect(prepared.admittedCompanion, isNull);
    expect(prepared.occupancyMutations, hasLength(1));
    expect(prepared.occupancyNext, same(base));

    final result = prepared.commit(predecessor);
    expect(result.admittedCompanion, isNull);
    expect(result.occupancyRuntime.snapshot, same(base));
  });

  test('empty choice never adopts occupancy retained by a no-op release', () {
    final oldCompanion = MentorInsightCompanion(
      stageId: 'stage_old',
      characterId: 77,
    );
    final previousRelease = _previousRelease(
      occupancyPredecessor: MentorInsightStageOccupancyRuntime.restore(
        revision: 8,
        companion: oldCompanion,
      ),
      admittedCharacterId: null,
    );
    final predecessor = previousRelease.occupancyRuntime;
    final prepared = _prepare(
      previousRelease: previousRelease,
      mentorCharacterId: null,
    );

    expect(prepared.admittedCompanion, isNull);
    expect(prepared.occupancyNext, same(predecessor.snapshot));
    expect(prepared.occupancyNext.companion, same(oldCompanion));
    expect(prepared.occupancyNext.revision, 8);
  });

  test('stage mismatch is rejected before an ineligible run transition', () {
    final previousRelease = _previousRelease();

    final error = _captureError(
      () => prepareNextMainlineStageRuntimeAdmission(
        previousRelease: previousRelease,
        nextStageId: 'stage_b',
        loadoutSnapshotId: 'snapshot_2',
        participantBattleEligibleForNextStage: false,
        mentorChoice: _choice('stage_c', 92),
        blockingStatus: _unblocked,
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
  });

  test('ineligible participant preserves run and occupancy inputs', () {
    final previousRelease = _previousRelease();
    final run = previousRelease.admission.runAdmission.run;
    final predecessor = previousRelease.occupancyRuntime;
    final snapshot = predecessor.snapshot;

    final error = _captureError(
      () => _prepare(
        previousRelease: previousRelease,
        participantBattleEligibleForNextStage: false,
      ),
    );

    expect(
      error,
      isA<MainlineRunTransitionRefusedError>().having(
        (value) => value.reason,
        'reason',
        MainlineRunStopReason.participantNotBattleEligibleForNextStage,
      ),
    );
    expect(run.currentStageId, 'stage_a');
    expect(run.currentLoadoutVersion, 1);
    expect(predecessor.snapshot, same(snapshot));
  });

  test('invalid loadout snapshot ID is passed through without publication', () {
    final previousRelease = _previousRelease();
    final predecessor = previousRelease.occupancyRuntime;
    final snapshot = predecessor.snapshot;

    expect(
      () => _prepare(previousRelease: previousRelease, loadoutSnapshotId: '  '),
      throwsArgumentError,
    );
    expect(predecessor.snapshot, same(snapshot));
  });

  test('R15 blocking and occupied conflicts pass through without mutation', () {
    for (final status in const [
      MentorInsightBlockingStatus(inRetreat: true),
      MentorInsightBlockingStatus(inExpedition: true),
      MentorInsightBlockingStatus(inBossGauntlet: true),
      MentorInsightBlockingStatus(inHealingRecovery: true),
    ]) {
      final previousRelease = _previousRelease();
      final predecessor = previousRelease.occupancyRuntime;
      final snapshot = predecessor.snapshot;
      expect(
        () =>
            _prepare(previousRelease: previousRelease, blockingStatus: status),
        throwsStateError,
      );
      expect(predecessor.snapshot, same(snapshot));
    }

    final occupiedRelease = _previousRelease(
      occupancyPredecessor: MentorInsightStageOccupancyRuntime.restore(
        revision: 5,
        companion: MentorInsightCompanion(
          stageId: 'stage_old',
          characterId: 70,
        ),
      ),
      admittedCharacterId: null,
    );
    expect(() => _prepare(previousRelease: occupiedRelease), throwsStateError);
    expect(occupiedRelease.occupancyRuntime.snapshot.revision, 5);
  });

  test('foreign and stale predecessors reject without consuming commit', () {
    final previousRelease = _previousRelease();
    final predecessor = previousRelease.occupancyRuntime;
    final prepared = _prepare(previousRelease: previousRelease);

    expect(
      () => prepared.commit(MentorInsightStageOccupancyRuntime.empty()),
      throwsStateError,
    );
    final stale = predecessor.commit(predecessor.prepare(const []));
    expect(() => prepared.commit(stale), throwsStateError);

    final result = prepared.commit(predecessor);
    expect(result.occupancyRuntime.snapshot.companion?.characterId, 92);
  });

  test('double commit is rejected with the exact single-use error', () {
    final previousRelease = _previousRelease();
    final predecessor = previousRelease.occupancyRuntime;
    final prepared = _prepare(previousRelease: previousRelease);
    prepared.commit(predecessor);

    final error = _captureError(() => prepared.commit(predecessor));
    expect(
      error,
      isA<StateError>().having(
        (value) => value.message,
        'message',
        'Prepared mainline next-stage runtime admission was already committed',
      ),
    );
  });

  test('sibling prepared values may commit from the immutable predecessor', () {
    final previousRelease = _previousRelease();
    final predecessor = previousRelease.occupancyRuntime;
    final first = _prepare(previousRelease: previousRelease);
    final sibling = _prepare(
      previousRelease: previousRelease,
      nextStageId: 'stage_c',
      loadoutSnapshotId: 'snapshot_sibling',
      mentorCharacterId: 93,
    );

    final firstResult = first.commit(predecessor);
    final siblingResult = sibling.commit(predecessor);

    expect(firstResult.run.currentStageId, 'stage_b');
    expect(siblingResult.run.currentStageId, 'stage_c');
    expect(firstResult.occupancyRuntime.snapshot.companion?.characterId, 92);
    expect(siblingResult.occupancyRuntime.snapshot.companion?.characterId, 93);
    expect(predecessor.snapshot.companion, isNull);
  });

  test('source keeps the composition private and policy neutral', () {
    const sourcePath =
        'lib/features/mainline/application/'
        'mainline_next_stage_runtime_admission.dart';
    final source = File(sourcePath).readAsStringSync();
    final contract = DartSourceContract.parse(source, path: sourcePath);
    final imports = RegExp(
      "^import '([^']+)';",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();

    expect(imports, [
      '../domain/mainline_run.dart',
      '../domain/mentor_insight_policy.dart',
      'mainline_stage_runtime_admission.dart',
      'mentor_insight_stage_occupancy_runtime.dart',
    ]);
    expect(
      RegExp(
        r'MentorInsightStageOccupancyPreparedSuccessor\s+'
        r'(?:get\s+)?(?!_)[A-Za-z]\w*',
      ).allMatches(source),
      isEmpty,
    );
    expect(
      contract.methodCalls(
        targetSource: 'previousRun',
        methodName: 'proceedToNext',
      ),
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
      contract.methodCalls(
        targetSource: 'exactPredecessor',
        methodName: 'commit',
      ),
      hasLength(1),
    );
    expect(contract.identifierCount('admitMainlineRun'), 0);
    expect(contract.identifierCount('MainlineRunAdmission'), 0);
    expect(contract.identifierCount('ReleaseMentorInsightStageOccupancy'), 0);
    expect(contract.identifierCount('releaseReason'), 0);

    for (final forbidden in const [
      'RewardClaimKey',
      'MentorInsightClaimPolicy',
      'RewardGrantGuard',
      'ActivityOccupancy',
      'Isar',
      'settlement',
      'outbox',
      'production',
      'candidate',
      'tuning',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
    expect(source, isNot(contains('try {')));
    expect(source, isNot(contains('part ')));
    expect(source, isNot(contains('part of')));
  });
}
