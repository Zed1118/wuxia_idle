import '../../../shared/battle_shared/reward_claim_key.dart';
import '../domain/mentor_insight_policy.dart';
import 'mainline_stage_runtime_admission.dart';
import 'mentor_insight_claim_policy.dart';

final class MentorInsightDurableClaimObservation {
  const MentorInsightDurableClaimObservation({
    required this.claimKey,
    required this.durablyClaimed,
  });

  final RewardClaimKey claimKey;
  final bool durablyClaimed;
}

final class MentorInsightStageClaimCandidate {
  const MentorInsightStageClaimCandidate._({
    required this.companion,
    required this.claimKey,
  });

  final MentorInsightCompanion companion;
  final RewardClaimKey claimKey;
}

final class MentorInsightStageClaimDecision {
  const MentorInsightStageClaimDecision._({
    required this.companion,
    required this.claimKey,
    required this.outcome,
  });

  final MentorInsightCompanion companion;
  final RewardClaimKey claimKey;
  final MentorInsightClaimOutcome outcome;
}

MentorInsightStageClaimCandidate? prepareMentorInsightStageClaimCandidate({
  required MainlineStageRuntimeAdmission admission,
}) {
  final companion = admission.admittedCompanion;
  if (companion == null) {
    return null;
  }

  final currentStageId = admission.runAdmission.run.currentStageId;
  if (companion.stageId != currentStageId) {
    throw StateError('Mentor-insight claim stage does not match admission');
  }
  final claimKey = RewardClaimKey.mentorInsight(
    stageId: currentStageId,
    characterId: companion.characterId,
  );
  return MentorInsightStageClaimCandidate._(
    companion: companion,
    claimKey: claimKey,
  );
}

MentorInsightStageClaimDecision decideMentorInsightStageClaim({
  required MentorInsightStageClaimCandidate candidate,
  required bool isSuccessfulSettlement,
  MentorInsightDurableClaimObservation? durableObservation,
}) {
  final observationMatches = durableObservation?.claimKey == candidate.claimKey;
  if (isSuccessfulSettlement && !observationMatches) {
    return MentorInsightStageClaimDecision._(
      companion: candidate.companion,
      claimKey: candidate.claimKey,
      outcome: MentorInsightClaimOutcome.failClosed,
    );
  }

  final outcome = MentorInsightClaimPolicy.decide(
    isFirstClear: isSuccessfulSettlement,
    externallyDurablyClaimed:
        observationMatches && durableObservation!.durablyClaimed,
  );
  return MentorInsightStageClaimDecision._(
    companion: candidate.companion,
    claimKey: candidate.claimKey,
    outcome: outcome,
  );
}
