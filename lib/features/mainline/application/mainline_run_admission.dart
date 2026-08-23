import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../domain/mainline_participation_policy.dart';
import '../domain/mainline_run.dart';

/// Immutable result of resolving one request and beginning its run.
final class MainlineRunAdmission {
  MainlineRunAdmission._({
    required this.request,
    required this.selection,
    required this.run,
  });

  final ActivityParticipationRequest request;
  final MainlineParticipantSelection selection;
  final MainlineRun run;
}

/// Resolves the participant, then begins a run for that exact participant.
MainlineRunAdmission admitMainlineRun({
  required ActivityParticipationRequest request,
  required int currentLeaderId,
  required bool requestedIdleEligible,
  required String runId,
  required String stageId,
  required String loadoutSnapshotId,
}) {
  final selection = MainlineParticipationPolicy.resolveParticipant(
    request: request,
    currentLeaderId: currentLeaderId,
    requestedIdleEligible: requestedIdleEligible,
  );
  final run = MainlineRun.begin(
    runId: runId,
    participantId: selection.participantId,
    stageId: stageId,
    loadoutSnapshotId: loadoutSnapshotId,
  );
  return MainlineRunAdmission._(
    request: request,
    selection: selection,
    run: run,
  );
}
