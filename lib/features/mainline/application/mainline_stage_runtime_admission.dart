import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../domain/mainline_participation_policy.dart';
import '../domain/mentor_insight_policy.dart';
import 'mainline_run_admission.dart';
import 'mentor_insight_stage_occupancy_runtime.dart';

/// A validated admission that has not yet published its occupancy successor.
final class MainlineStageRuntimeAdmissionPrepared {
  MainlineStageRuntimeAdmissionPrepared._(
    this._occupancyPreparedSuccessor, {
    required this.runAdmission,
    required this.occupancyPredecessor,
    required this.admittedCompanion,
  });

  final MainlineRunAdmission runAdmission;
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

    final occupancyRuntime = predecessor.commit(_occupancyPreparedSuccessor);
    _committed = true;
    return MainlineStageRuntimeAdmission._(
      runAdmission: runAdmission,
      occupancyRuntime: occupancyRuntime,
      admittedCompanion: admittedCompanion,
    );
  }
}

/// The exact run and occupancy values published by one successful commit.
final class MainlineStageRuntimeAdmission {
  const MainlineStageRuntimeAdmission._({
    required this.runAdmission,
    required this.occupancyRuntime,
    required this.admittedCompanion,
  });

  final MainlineRunAdmission runAdmission;
  final MentorInsightStageOccupancyRuntime occupancyRuntime;
  final MentorInsightCompanion? admittedCompanion;
}

final class MainlineStageRuntimeReleasePrepared {
  MainlineStageRuntimeReleasePrepared._(
    this._occupancyPreparedSuccessor, {
    required this.admission,
    required this.releaseReason,
    required this.releasePredecessor,
  });

  final MainlineStageRuntimeAdmission admission;
  final MentorInsightReleaseReason releaseReason;
  final MentorInsightStageOccupancyRuntime releasePredecessor;
  final MentorInsightStageOccupancyPreparedSuccessor
  _occupancyPreparedSuccessor;

  MentorInsightStageOccupancySnapshot get occupancyBase =>
      _occupancyPreparedSuccessor.base;

  MentorInsightStageOccupancySnapshot get occupancyNext =>
      _occupancyPreparedSuccessor.next;

  List<MentorInsightStageOccupancyMutation> get occupancyMutations =>
      _occupancyPreparedSuccessor.mutations;

  bool _committed = false;

  MainlineStageRuntimeRelease commit(
    MentorInsightStageOccupancyRuntime exactPredecessor,
  ) {
    if (!identical(exactPredecessor, releasePredecessor)) {
      throw StateError(
        'Prepared mainline stage runtime release has another '
        'occupancy predecessor',
      );
    }
    if (_committed) {
      throw StateError(
        'Prepared mainline stage runtime release was already committed',
      );
    }

    final occupancyRuntime = exactPredecessor.commit(
      _occupancyPreparedSuccessor,
    );
    _committed = true;
    return MainlineStageRuntimeRelease._(
      admission: admission,
      releaseReason: releaseReason,
      occupancyRuntime: occupancyRuntime,
    );
  }
}

final class MainlineStageRuntimeRelease {
  const MainlineStageRuntimeRelease._({
    required this.admission,
    required this.releaseReason,
    required this.occupancyRuntime,
  });

  final MainlineStageRuntimeAdmission admission;
  final MentorInsightReleaseReason releaseReason;
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
    occupancyPreparedSuccessor,
    runAdmission: runAdmission,
    occupancyPredecessor: occupancyPredecessor,
    admittedCompanion: mentorChoice.hasCompanion
        ? occupancyPreparedSuccessor.next.companion
        : null,
  );
}

MainlineStageRuntimeReleasePrepared prepareMainlineStageRuntimeRelease({
  required MainlineStageRuntimeAdmission admission,
  required MentorInsightReleaseReason releaseReason,
}) {
  if (!MentorInsightPolicy.releaseReasons.contains(releaseReason)) {
    throw StateError('Mainline stage runtime release reason is unsupported');
  }

  final releasePredecessor = admission.occupancyRuntime;
  final companion = admission.admittedCompanion;
  final List<MentorInsightStageOccupancyMutation> mutations;
  if (companion == null) {
    mutations = const [];
  } else {
    final active = releasePredecessor.snapshot.companion;
    if (active == null) {
      throw StateError(
        'Mainline stage runtime release has no active companion',
      );
    }
    if (active.stageId != companion.stageId) {
      throw StateError('Mainline stage runtime release stage does not match');
    }
    if (active.characterId != companion.characterId) {
      throw StateError(
        'Mainline stage runtime release character does not match',
      );
    }
    mutations = [
      ReleaseMentorInsightStageOccupancy(
        companion: companion,
        reason: releaseReason,
      ),
    ];
  }

  final occupancyPreparedSuccessor = releasePredecessor.prepare(mutations);
  return MainlineStageRuntimeReleasePrepared._(
    occupancyPreparedSuccessor,
    admission: admission,
    releaseReason: releaseReason,
    releasePredecessor: releasePredecessor,
  );
}
