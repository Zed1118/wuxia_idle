import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import 'durable_activity_combat_run.dart';

String durableActivityLoadoutPlanId({
  required DurableActivityKind kind,
  required String stageId,
  required int characterId,
}) {
  if (kind == DurableActivityKind.tower) {
    throw ArgumentError.value(
      kind,
      'kind',
      'tower uses towerAutomationLoadoutPlanId',
    );
  }
  return '${kind.name}:$stageId:character:$characterId';
}

enum DurableActivityAutomationMode { visibleReplay, headlessReplay, dispatch }

ActivityParticipationRequest durableActivityAutomationRequest({
  required DurableActivityKind kind,
  required String stageId,
  required int characterId,
  required DurableActivityAutomationMode mode,
}) => ActivityParticipationRequest(
  contentId: stageId,
  contentKind: switch (kind) {
    DurableActivityKind.tower => throw ArgumentError.value(
      kind,
      'kind',
      'tower uses towerDurableDispatchRequest',
    ),
    DurableActivityKind.lightFoot => ActivityContentKind.lightFoot,
    DurableActivityKind.massBattle => ActivityContentKind.massBattle,
  },
  characterId: characterId,
  loadoutPlanId: durableActivityLoadoutPlanId(
    kind: kind,
    stageId: stageId,
    characterId: characterId,
  ),
  participation: mode == DurableActivityAutomationMode.dispatch
      ? ActivityParticipationMode.dispatch
      : ActivityParticipationMode.direct,
  controller: ActivityController.playerBot,
  clock: mode == DurableActivityAutomationMode.visibleReplay
      ? ActivityClock.realtime
      : ActivityClock.headless,
  entryKind: mode == DurableActivityAutomationMode.dispatch
      ? ActivityEntryKind.offlineResume
      : ActivityEntryKind.replay,
);

enum DurableActivityAutomationRejectionReason {
  unsupportedKind,
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

/// 已首通轻功/守城的 automation allowlist。
///
/// 精确允许三条生产通道：前台 bot 重打、快速 headless 重打与 durable 差遣。
/// 阵型只属于守城；无画面通道必须在开跑前持有玩家选择的阵型，前台通道由
/// battle host 继续呈现原阵型选择。该 policy 不选人、不读存档、不创建 runner。
final class DurableActivityAutomationPolicy {
  const DurableActivityAutomationPolicy._();

  static DurableActivityAutomationDecision evaluate({
    required DurableActivityKind kind,
    required StageDef stage,
    required ActivityParticipationRequest request,
    required bool alreadyCleared,
    required Formation? formation,
  }) {
    if (kind == DurableActivityKind.tower) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.unsupportedKind,
      );
    }
    final expectedStageType = switch (kind) {
      DurableActivityKind.tower => throw StateError(
        'tower must use TowerAutomationPolicy',
      ),
      DurableActivityKind.lightFoot => StageType.lightFoot,
      DurableActivityKind.massBattle => StageType.massBattle,
    };
    final expectedContentKind = switch (kind) {
      DurableActivityKind.tower => throw StateError(
        'tower must use TowerAutomationPolicy',
      ),
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
    if (request.controller != ActivityController.playerBot) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.unsupportedController,
      );
    }
    switch (request.participation) {
      case ActivityParticipationMode.direct:
        if (request.entryKind != ActivityEntryKind.replay) {
          return const DurableActivityAutomationDecision.rejected(
            DurableActivityAutomationRejectionReason.unsupportedEntryKind,
          );
        }
        break;
      case ActivityParticipationMode.dispatch:
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
        break;
    }
    if (!alreadyCleared) {
      return const DurableActivityAutomationDecision.rejected(
        DurableActivityAutomationRejectionReason.firstClearRequired,
      );
    }
    if (kind == DurableActivityKind.massBattle &&
        request.clock == ActivityClock.headless &&
        formation == null) {
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
