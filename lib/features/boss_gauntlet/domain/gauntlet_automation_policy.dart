library;

import '../../battle/domain/phase0a/activity_participation_request.dart';

/// Machine-readable reasons why an automation request is not admissible.
enum GauntletAutomationRejectionReason {
  wrongContentKind,
  wrongContentId,
  wrongLoadoutPlan,
  unsupportedParticipation,
  unsupportedController,
  visibleRealtimePlayerBot,
  unsupportedClock,
  unsupportedEntryKind,
  fullClearRequired,
}

String gauntletAutomationLoadoutPlanId(int characterId) {
  if (characterId <= 0) {
    throw ArgumentError.value(characterId, 'characterId', 'must be > 0');
  }
  return 'gauntlet-plan-$characterId';
}

ActivityParticipationRequest gauntletHeadlessReplayRequest({
  required int characterId,
}) => ActivityParticipationRequest(
  contentId: GauntletAutomationPolicy.gauntletId,
  contentKind: ActivityContentKind.gauntlet,
  characterId: characterId,
  loadoutPlanId: gauntletAutomationLoadoutPlanId(characterId),
  participation: ActivityParticipationMode.direct,
  controller: ActivityController.playerBot,
  clock: ActivityClock.headless,
  entryKind: ActivityEntryKind.replay,
);

ActivityParticipationRequest gauntletDurableDispatchRequest({
  required int characterId,
}) => ActivityParticipationRequest(
  contentId: GauntletAutomationPolicy.gauntletId,
  contentKind: ActivityContentKind.gauntlet,
  characterId: characterId,
  loadoutPlanId: gauntletAutomationLoadoutPlanId(characterId),
  participation: ActivityParticipationMode.dispatch,
  controller: ActivityController.playerBot,
  clock: ActivityClock.headless,
  entryKind: ActivityEntryKind.offlineResume,
);

String gauntletDurableStageId(int gauntletRunId) {
  if (gauntletRunId <= 0) {
    throw ArgumentError.value(gauntletRunId, 'gauntletRunId', 'must be > 0');
  }
  return 'gauntlet_run_$gauntletRunId';
}

int gauntletRunIdFromDurableStageId(String stageId) {
  const prefix = 'gauntlet_run_';
  if (!stageId.startsWith(prefix)) {
    throw StateError('Gauntlet durable stage identity is invalid');
  }
  final runId = int.tryParse(stageId.substring(prefix.length));
  if (runId == null || runId <= 0) {
    throw StateError('Gauntlet durable run identity is invalid');
  }
  return runId;
}

/// Pure policy result. Application code must fail closed on every rejection.
final class GauntletAutomationDecision {
  const GauntletAutomationDecision._({
    required this.allowed,
    this.rejectionReason,
  });

  const GauntletAutomationDecision.allowed() : this._(allowed: true);

  const GauntletAutomationDecision.rejected(
    GauntletAutomationRejectionReason reason,
  ) : this._(allowed: false, rejectionReason: reason);

  final bool allowed;
  final GauntletAutomationRejectionReason? rejectionReason;
}

/// A rejected request carries a stable reason and never falls back.
final class GauntletAutomationRejectedException extends StateError {
  GauntletAutomationRejectedException(this.reason)
    : super('Gauntlet automation rejected: ${reason.name}');

  final GauntletAutomationRejectionReason reason;
}

/// Pure domain policy for the currently admitted gauntlet automation shape.
///
/// This is intentionally a two-tuple allowlist: immediate replay and persisted
/// dispatch. It does not infer a controller, participant, entry kind, or content
/// identity from any other field.
final class GauntletAutomationPolicy {
  const GauntletAutomationPolicy._();

  /// Canonical identity used by `SaveData.clearedGauntletIds`.
  static const String gauntletId = 'duanhunzhuang';

  static GauntletAutomationDecision evaluate({
    required ActivityParticipationRequest request,
    required Set<String> clearedGauntletIds,
  }) {
    if (request.contentKind != ActivityContentKind.gauntlet) {
      return const GauntletAutomationDecision.rejected(
        GauntletAutomationRejectionReason.wrongContentKind,
      );
    }
    if (request.contentId != gauntletId) {
      return const GauntletAutomationDecision.rejected(
        GauntletAutomationRejectionReason.wrongContentId,
      );
    }
    if (request.loadoutPlanId !=
        gauntletAutomationLoadoutPlanId(request.characterId)) {
      return const GauntletAutomationDecision.rejected(
        GauntletAutomationRejectionReason.wrongLoadoutPlan,
      );
    }
    if (request.controller == ActivityController.playerBot &&
        request.clock == ActivityClock.realtime) {
      return const GauntletAutomationDecision.rejected(
        GauntletAutomationRejectionReason.visibleRealtimePlayerBot,
      );
    }
    if (request.controller != ActivityController.playerBot) {
      return const GauntletAutomationDecision.rejected(
        GauntletAutomationRejectionReason.unsupportedController,
      );
    }
    if (request.clock != ActivityClock.headless) {
      return const GauntletAutomationDecision.rejected(
        GauntletAutomationRejectionReason.unsupportedClock,
      );
    }
    switch (request.participation) {
      case ActivityParticipationMode.direct:
        if (request.entryKind != ActivityEntryKind.replay) {
          return const GauntletAutomationDecision.rejected(
            GauntletAutomationRejectionReason.unsupportedEntryKind,
          );
        }
      case ActivityParticipationMode.dispatch:
        if (request.entryKind != ActivityEntryKind.offlineResume) {
          return const GauntletAutomationDecision.rejected(
            GauntletAutomationRejectionReason.unsupportedEntryKind,
          );
        }
    }
    if (!clearedGauntletIds.contains(gauntletId)) {
      return const GauntletAutomationDecision.rejected(
        GauntletAutomationRejectionReason.fullClearRequired,
      );
    }
    return const GauntletAutomationDecision.allowed();
  }

  static void requireAllowed({
    required ActivityParticipationRequest request,
    required Set<String> clearedGauntletIds,
  }) {
    final decision = evaluate(
      request: request,
      clearedGauntletIds: clearedGauntletIds,
    );
    final reason = decision.rejectionReason;
    if (!decision.allowed && reason != null) {
      throw GauntletAutomationRejectedException(reason);
    }
    if (!decision.allowed) {
      throw StateError('Rejected gauntlet automation has no reason');
    }
  }
}
