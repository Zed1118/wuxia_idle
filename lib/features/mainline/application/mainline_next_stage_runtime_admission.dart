import '../domain/mainline_run.dart';
import '../domain/mentor_insight_policy.dart';
import 'mainline_stage_runtime_admission.dart';
import 'mentor_insight_stage_occupancy_runtime.dart';

final class MainlineNextStageRuntimeAdmissionPrepared {
  MainlineNextStageRuntimeAdmissionPrepared._(
    this._occupancyPreparedSuccessor, {
    required this.previousRelease,
    required this.run,
    required this.occupancyPredecessor,
    required this.admittedCompanion,
  });

  final MainlineStageRuntimeRelease previousRelease;
  final MainlineRun run;
  final MentorInsightStageOccupancyRuntime occupancyPredecessor;
  final MentorInsightCompanion? admittedCompanion;
  final MentorInsightStageOccupancyPreparedSuccessor
  _occupancyPreparedSuccessor;

  MentorInsightStageOccupancySnapshot get occupancyBase =>
      _occupancyPreparedSuccessor.base;

  MentorInsightStageOccupancySnapshot get occupancyNext =>
      _occupancyPreparedSuccessor.next;

  List<MentorInsightStageOccupancyMutation> get occupancyMutations =>
      _occupancyPreparedSuccessor.mutations;

  bool _committed = false;

  MainlineNextStageRuntimeAdmission commit(
    MentorInsightStageOccupancyRuntime exactPredecessor,
  ) {
    if (!identical(exactPredecessor, occupancyPredecessor)) {
      throw StateError(
        'Prepared mainline next-stage runtime admission has another '
        'occupancy predecessor',
      );
    }
    if (_committed) {
      throw StateError(
        'Prepared mainline next-stage runtime admission was already committed',
      );
    }

    final occupancyRuntime = exactPredecessor.commit(
      _occupancyPreparedSuccessor,
    );
    _committed = true;
    return MainlineNextStageRuntimeAdmission._(
      previousRelease: previousRelease,
      run: run,
      occupancyRuntime: occupancyRuntime,
      admittedCompanion: admittedCompanion,
    );
  }
}

final class MainlineNextStageRuntimeAdmission {
  const MainlineNextStageRuntimeAdmission._({
    required this.previousRelease,
    required this.run,
    required this.occupancyRuntime,
    required this.admittedCompanion,
  });

  final MainlineStageRuntimeRelease previousRelease;
  final MainlineRun run;
  final MentorInsightStageOccupancyRuntime occupancyRuntime;
  final MentorInsightCompanion? admittedCompanion;
}

MainlineNextStageRuntimeAdmissionPrepared
prepareNextMainlineStageRuntimeAdmission({
  required MainlineStageRuntimeRelease previousRelease,
  required String nextStageId,
  required String loadoutSnapshotId,
  required bool participantBattleEligibleForNextStage,
  required MentorInsightChoice mentorChoice,
  required MentorInsightBlockingStatus blockingStatus,
}) {
  if (mentorChoice.stageId != nextStageId) {
    throw ArgumentError.value(
      mentorChoice.stageId,
      'mentorChoice.stageId',
      'must exactly match nextStageId "$nextStageId"',
    );
  }

  final previousRun = previousRelease.admission.runAdmission.run;
  final run = previousRun.proceedToNext(
    stageId: nextStageId,
    loadoutSnapshotId: loadoutSnapshotId,
    participantBattleEligibleForNextStage:
        participantBattleEligibleForNextStage,
  );
  final occupancyPredecessor = previousRelease.occupancyRuntime;
  final occupancyPreparedSuccessor = occupancyPredecessor.prepare([
    AcquireMentorInsightStageOccupancy(
      choice: mentorChoice,
      blockingStatus: blockingStatus,
    ),
  ]);
  return MainlineNextStageRuntimeAdmissionPrepared._(
    occupancyPreparedSuccessor,
    previousRelease: previousRelease,
    run: run,
    occupancyPredecessor: occupancyPredecessor,
    admittedCompanion: mentorChoice.hasCompanion
        ? occupancyPreparedSuccessor.next.companion
        : null,
  );
}
