import '../../battle/domain/phase0a/activity_participation_request.dart';

String innerDemonLoadoutPlanId({
  required String stageId,
  required int characterId,
}) => 'inner_demon:$stageId:character:$characterId';

enum InnerDemonParticipationRejectionReason {
  wrongContentKind,
  wrongContentId,
  wrongCharacter,
  wrongLoadoutPlan,
  unsupportedParticipation,
  unsupportedController,
  unsupportedClock,
  unsupportedEntryKind,
}

final class InnerDemonParticipationDecision {
  const InnerDemonParticipationDecision.allowed()
    : allowed = true,
      rejectionReason = null;

  const InnerDemonParticipationDecision.rejected(this.rejectionReason)
    : allowed = false;

  final bool allowed;
  final InnerDemonParticipationRejectionReason? rejectionReason;
}

/// The heart-demon challenge is a visible, manual battle for the exact person
/// whose breakthrough is blocked. Every automation or substitution tuple is
/// rejected before any participant snapshot is assembled.
final class InnerDemonParticipationPolicy {
  const InnerDemonParticipationPolicy._();

  static InnerDemonParticipationDecision evaluate({
    required ActivityParticipationRequest request,
    required String expectedStageId,
    required int expectedCharacterId,
  }) {
    if (request.contentKind != ActivityContentKind.innerDemon) {
      return const InnerDemonParticipationDecision.rejected(
        InnerDemonParticipationRejectionReason.wrongContentKind,
      );
    }
    if (request.contentId != expectedStageId) {
      return const InnerDemonParticipationDecision.rejected(
        InnerDemonParticipationRejectionReason.wrongContentId,
      );
    }
    if (request.characterId != expectedCharacterId) {
      return const InnerDemonParticipationDecision.rejected(
        InnerDemonParticipationRejectionReason.wrongCharacter,
      );
    }
    if (request.loadoutPlanId !=
        innerDemonLoadoutPlanId(
          stageId: expectedStageId,
          characterId: expectedCharacterId,
        )) {
      return const InnerDemonParticipationDecision.rejected(
        InnerDemonParticipationRejectionReason.wrongLoadoutPlan,
      );
    }
    if (request.participation != ActivityParticipationMode.direct) {
      return const InnerDemonParticipationDecision.rejected(
        InnerDemonParticipationRejectionReason.unsupportedParticipation,
      );
    }
    if (request.controller != ActivityController.human) {
      return const InnerDemonParticipationDecision.rejected(
        InnerDemonParticipationRejectionReason.unsupportedController,
      );
    }
    if (request.clock != ActivityClock.realtime) {
      return const InnerDemonParticipationDecision.rejected(
        InnerDemonParticipationRejectionReason.unsupportedClock,
      );
    }
    if (request.entryKind != ActivityEntryKind.firstClear &&
        request.entryKind != ActivityEntryKind.replay) {
      return const InnerDemonParticipationDecision.rejected(
        InnerDemonParticipationRejectionReason.unsupportedEntryKind,
      );
    }
    return const InnerDemonParticipationDecision.allowed();
  }
}
