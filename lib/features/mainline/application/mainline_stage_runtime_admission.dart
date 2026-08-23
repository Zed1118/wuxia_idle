import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../domain/mainline_participation_policy.dart';
import '../domain/mentor_insight_policy.dart';
import 'mainline_run_admission.dart';
import 'mentor_insight_stage_occupancy_runtime.dart';

/// A validated admission that has not yet published its occupancy successor.
final class MainlineStageRuntimeAdmissionPrepared {
  MainlineStageRuntimeAdmissionPrepared._({
    required this.runAdmission,
    required this.occupancyPredecessor,
    required this.occupancyPreparedSuccessor,
  });

  final MainlineRunAdmission runAdmission;
  final MentorInsightStageOccupancyRuntime occupancyPredecessor;
  final MentorInsightStageOccupancyPreparedSuccessor occupancyPreparedSuccessor;

  bool _committed = false;

  MainlineStageRuntimeAdmission commit(
    MentorInsightStageOccupancyRuntime predecessor,
  ) {
    if (!identical(predecessor, occupancyPredecessor)) {
      throw StateError(
        'Prepared mainline stage runtime admission has another '
        'occupancy predecessor',
      );
    }
    if (_committed) {
      throw StateError(
        'Prepared mainline stage runtime admission was already committed',
      );
    }

    final occupancyRuntime = predecessor.commit(occupancyPreparedSuccessor);
    _committed = true;
    return MainlineStageRuntimeAdmission._(
      runAdmission: runAdmission,
      occupancyRuntime: occupancyRuntime,
    );
  }
}

/// The exact run and occupancy values published by one successful commit.
final class MainlineStageRuntimeAdmission {
  const MainlineStageRuntimeAdmission._({
    required this.runAdmission,
    required this.occupancyRuntime,
  });

  final MainlineRunAdmission runAdmission;
  final MentorInsightStageOccupancyRuntime occupancyRuntime;
}

/// Validates and prepares one mainline first-clear stage admission.
MainlineStageRuntimeAdmissionPrepared prepareMainlineStageRuntimeAdmission({
  required ActivityParticipationRequest request,
  required int currentLeaderId,
  required bool requestedIdleEligible,
  required String runId,
  required String stageId,
  required String loadoutSnapshotId,
  required MentorInsightStageOccupancyRuntime occupancyPredecessor,
  required MentorInsightChoice mentorChoice,
  required MentorInsightBlockingStatus blockingStatus,
}) {
  if (request.contentKind != ActivityContentKind.mainline) {
    throw const MainlineParticipationRefusedError(
      'Mainline stage runtime admission covers mainline content only',
    );
  }
  if (request.entryKind != ActivityEntryKind.firstClear) {
    throw const MainlineParticipationRefusedError(
      'Mainline stage runtime admission covers first-clear entries only',
    );
  }
  if (mentorChoice.stageId != stageId) {
    throw ArgumentError.value(
      mentorChoice.stageId,
      'mentorChoice.stageId',
      'must exactly match stageId "$stageId"',
    );
  }

  final runAdmission = admitMainlineRun(
    request: request,
    currentLeaderId: currentLeaderId,
    requestedIdleEligible: requestedIdleEligible,
    runId: runId,
    stageId: stageId,
    loadoutSnapshotId: loadoutSnapshotId,
  );
  final occupancyPreparedSuccessor = occupancyPredecessor.prepare([
    AcquireMentorInsightStageOccupancy(
      choice: mentorChoice,
      blockingStatus: blockingStatus,
    ),
  ]);
  return MainlineStageRuntimeAdmissionPrepared._(
    runAdmission: runAdmission,
    occupancyPredecessor: occupancyPredecessor,
    occupancyPreparedSuccessor: occupancyPreparedSuccessor,
  );
}
