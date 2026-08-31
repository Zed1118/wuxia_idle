import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import 'durable_activity_combat_run.dart';

String durableActivityLoadoutPlanId({
  required DurableActivityKind kind,
  required String stageId,
  required int characterId,
}) => '${kind.name}:$stageId:character:$characterId';

enum DurableActivityAutomationRejectionReason {
  wrongStageType,
  wrongContentKind,
  wrongContentId,
  wrongLoadoutPlan,
  unsupportedParticipation,
  unsupportedController,
  unsupportedClock,
  unsupportedEntryKind,
  firstClearRequired,
  missingFormation,
  unexpectedFormation,
}

final class DurableActivityAutomationDecision {
  const DurableActivityAutomationDecision.allowed()
    : allowed = true,
      rejectionReason = null;

  const DurableActivityAutomationDecision.rejected(this.rejectionReason)
    : allowed = false;

  final bool allowed;
  final DurableActivityAutomationRejectionReason? rejectionReason;
}

final class DurableActivityAutomationRejectedException extends StateError {
  DurableActivityAutomationRejectedException(this.reason)
    : super('Durable activity automation rejected: ${reason.name}');

  final DurableActivityAutomationRejectionReason reason;
}

/// 已首通轻功/守城的唯一 automation allowlist。
///
/// 差遣、bot、headless 与 offlineResume 必须同时成立；阵型只属于守城且必须由
/// 玩家显式选择。该 policy 不选人、不读存档、不创建 runner。
final class DurableActivityAutomationPolicy {
  const DurableActivityAutomationPolicy._();

  static DurableActivityAutomationDecision evaluate({
    required DurableActivityKind kind,
    required StageDef stage,
    required ActivityParticipationRequest request,
    required bool alreadyCleared,
    required Formation? formation,
  }) {
    final expectedStageType = switch (kind) {
      DurableActivityKind.lightFoot => StageType.lightFoot,
      DurableActivityKind.massBattle => StageType.massBattle,
    };
    final expectedContentKind = switch (kind) {
      DurableActivityKind.lightFoot => ActivityContentKind.lightFoot,
      DurableActivityKind.massBattle => ActivityContentKind.massBattle,
    };
    if (stage.stageType != expectedStageType) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.wrongStageType,
      );
    }
    if (request.contentKind != expectedContentKind) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.wrongContentKind,
      );
    }
    if (request.contentId != stage.id) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.wrongContentId,
      );
    }
    if (request.loadoutPlanId !=
        durableActivityLoadoutPlanId(
          kind: kind,
          stageId: stage.id,
          characterId: request.characterId,
        )) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.wrongLoadoutPlan,
      );
    }
    if (request.participation != ActivityParticipationMode.dispatch) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.unsupportedParticipation,
      );
    }
    if (request.controller != ActivityController.playerBot) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.unsupportedController,
      );
    }
    if (request.clock != ActivityClock.headless) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.unsupportedClock,
      );
    }
    if (request.entryKind != ActivityEntryKind.offlineResume) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.unsupportedEntryKind,
      );
    }
    if (!alreadyCleared) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.firstClearRequired,
      );
    }
    if (kind == DurableActivityKind.massBattle && formation == null) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.missingFormation,
      );
    }
    if (kind == DurableActivityKind.lightFoot && formation != null) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.unexpectedFormation,
      );
    }
    return const DurableActivityAutomationDecision.allowed();
  }

  static void requireAllowed({
    required DurableActivityKind kind,
    required StageDef stage,
    required ActivityParticipationRequest request,
    required bool alreadyCleared,
    required Formation? formation,
  }) {
    final decision = evaluate(
      kind: kind,
      stage: stage,
      request: request,
      alreadyCleared: alreadyCleared,
      formation: formation,
    );
    final reason = decision.rejectionReason;
    if (!decision.allowed && reason != null) {
      throw DurableActivityAutomationRejectedException(reason);
    }
    if (!decision.allowed) {
      throw StateError('Rejected durable activity automation has no reason');
    }
  }
}
