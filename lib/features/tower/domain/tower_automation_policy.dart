library;

import '../../battle/domain/phase0a/activity_participation_request.dart';

String towerAutomationContentId(int floorIndex) => 'tower_$floorIndex';

String towerAutomationLoadoutPlanId({
  required int floorIndex,
  required int characterId,
}) => 'tower:$floorIndex:character:$characterId';

enum TowerAutomationRejectionReason {
  wrongContentKind,
  wrongContentId,
  wrongLoadoutPlan,
  unsupportedParticipation,
  unsupportedController,
  visibleRealtimePlayerBot,
  unsupportedClock,
  unsupportedEntryKind,
  firstClearRequired,
}

final class TowerAutomationDecision {
  const TowerAutomationDecision._({
    required this.allowed,
    this.rejectionReason,
  });

  const TowerAutomationDecision.allowed() : this._(allowed: true);

  const TowerAutomationDecision.rejected(TowerAutomationRejectionReason reason)
    : this._(allowed: false, rejectionReason: reason);

  final bool allowed;
  final TowerAutomationRejectionReason? rejectionReason;
}

final class TowerAutomationRejectedException extends StateError {
  TowerAutomationRejectedException(this.reason)
    : super('Tower automation rejected: ${reason.name}');

  final TowerAutomationRejectionReason reason;
}

/// Frozen allowlist for the existing player-reachable tower sweep runner.
///
/// This policy creates no runner and chooses no character. It only admits the
/// exact direct + playerBot + headless + sweep tuple for a floor that current
/// persisted tower progress already marks cleared.
final class TowerAutomationPolicy {
  const TowerAutomationPolicy._();

  static TowerAutomationDecision evaluate({
    required ActivityParticipationRequest request,
    required int floorIndex,
    required int highestClearedFloor,
  }) {
    if (request.contentKind != ActivityContentKind.tower) {
      return const TowerAutomationDecision.rejected(
        TowerAutomationRejectionReason.wrongContentKind,
      );
    }
    if (request.contentId != towerAutomationContentId(floorIndex)) {
      return const TowerAutomationDecision.rejected(
        TowerAutomationRejectionReason.wrongContentId,
      );
    }
    if (request.loadoutPlanId !=
        towerAutomationLoadoutPlanId(
          floorIndex: floorIndex,
          characterId: request.characterId,
        )) {
      return const TowerAutomationDecision.rejected(
        TowerAutomationRejectionReason.wrongLoadoutPlan,
      );
    }
    if (request.participation != ActivityParticipationMode.direct) {
      return const TowerAutomationDecision.rejected(
        TowerAutomationRejectionReason.unsupportedParticipation,
      );
    }
    if (request.controller == ActivityController.playerBot &&
        request.clock == ActivityClock.realtime) {
      return const TowerAutomationDecision.rejected(
        TowerAutomationRejectionReason.visibleRealtimePlayerBot,
      );
    }
    if (request.controller != ActivityController.playerBot) {
      return const TowerAutomationDecision.rejected(
        TowerAutomationRejectionReason.unsupportedController,
      );
    }
    if (request.clock != ActivityClock.headless) {
      return const TowerAutomationDecision.rejected(
        TowerAutomationRejectionReason.unsupportedClock,
      );
    }
    if (request.entryKind != ActivityEntryKind.sweep) {
      return const TowerAutomationDecision.rejected(
        TowerAutomationRejectionReason.unsupportedEntryKind,
      );
    }
    if (floorIndex < 1 || highestClearedFloor < floorIndex) {
      return const TowerAutomationDecision.rejected(
        TowerAutomationRejectionReason.firstClearRequired,
      );
    }
    return const TowerAutomationDecision.allowed();
  }

  static void requireAllowed({
    required ActivityParticipationRequest request,
    required int floorIndex,
    required int highestClearedFloor,
  }) {
    final decision = evaluate(
      request: request,
      floorIndex: floorIndex,
      highestClearedFloor: highestClearedFloor,
    );
    final reason = decision.rejectionReason;
    if (!decision.allowed && reason != null) {
      throw TowerAutomationRejectedException(reason);
    }
    if (!decision.allowed) {
      throw StateError('Rejected tower automation has no reason');
    }
  }
}
