import 'dart:math' as math;

import '../../domain/phase0a/phase0a_combat_model.dart';
import 'phase0a_bot_tactic.dart';
import 'phase0a_player_input_adapter.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';

typedef Phase0aObjectiveContinuationCommandBuilder =
    Phase0aPlayerCommand Function(Phase0aArenaState state);

/// Phase 0A 玩家 bot(headless 内核批,路线 C 子项①落地):每拍从状态
/// 生成与真人同型的语义指令,经同一 [Phase0aPlayerInputAdapter] → reducer
/// 结算,不另开第二套结算入口。
///
/// 策略(灰盒基线,可调优数值一律取自 [playerAdapter],本层零数值复制):
/// - 锁定最近存活敌人(id 决胜);无存活敌人返回空指令。
/// - 超出普攻射程或朝向不在普攻扇区内时,朝目标四向移动(移动同时校正
///   朝向);否则站定输出。
/// - 普攻常按:冷却/射程/扇区判定全部由 reducer 结算。
/// - 技能印 availability 为 ready 即按(真气/冷却已合成在可用态,bot 不重算)。
final class Phase0aPlayerBotAdapter {
  const Phase0aPlayerBotAdapter({
    required this.playerAdapter,
    this.policy = const Phase0aBotTacticPolicy.production(),
    this.objectiveContinuationCommandBuilder,
  });

  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aBotTacticPolicy policy;
  final Phase0aObjectiveContinuationCommandBuilder?
  objectiveContinuationCommandBuilder;

  Phase0aPlayerCommand commandFor(Phase0aArenaState state) {
    if (!state.player.isAlive) {
      return const Phase0aPlayerCommand();
    }
    if (state.enemies.isEmpty) {
      return objectiveContinuationCommandBuilder?.call(state) ??
          const Phase0aPlayerCommand();
    }
    final player = state.player;
    final target = _targetFor(state);
    final toTarget = target.position - player.position;
    final distance = toTarget.length;
    final outOfRange = distance > playerAdapter.attackRange;
    final facingOffTarget =
        player.facing.dot(toTarget.normalized()) <
        math.cos(playerAdapter.attackHalfArcRadians);
    final gatherReady = _slotReady(state, playerAdapter.gatherSlot);
    final clearReady = _slotReady(state, playerAdapter.clearSlot);
    final numericSkill = _firstReadyNumericSkill(state);
    final tactical = _tacticalCommands(
      burstWindow: _isBurstWindow(target),
      gatherReady: gatherReady,
      clearReady: clearReady,
      numericSkill: numericSkill,
      target: target,
      player: player,
    );
    return Phase0aPlayerCommand(
      left: (outOfRange || facingOffTarget) && toTarget.x < 0,
      right: (outOfRange || facingOffTarget) && toTarget.x > 0,
      up: (outOfRange || facingOffTarget) && toTarget.y < 0,
      down: (outOfRange || facingOffTarget) && toTarget.y > 0,
      attack: true,
      gather: tactical.gather,
      clear: tactical.clear,
      skillHotkey: tactical.skillHotkey,
      defenseAction: tactical.defenseAction,
      defenseDirection: toTarget.lengthSquared > 0
          ? toTarget.normalized()
          : player.facing,
    );
  }

  _TacticalCommands _tacticalCommands({
    required bool burstWindow,
    required bool gatherReady,
    required bool clearReady,
    required int? numericSkill,
    required Phase0aActor target,
    required Phase0aActor player,
  }) {
    if (policy.requiresBurstWindow && !burstWindow) {
      // steadyGuard's defensive action is itself the safe response outside a
      // burst window. Do not let the policy gate make shield/parry unreachable;
      // other tactical actions remain held until the configured window.
      if (!policy.allows(Phase0aBotAction.defense)) {
        return const _TacticalCommands();
      }
      final tuning = playerAdapter.defenseTuning;
      if (tuning != null &&
          player.defenseCooldownRemaining <= 0 &&
          target.chargingCast != null) {
        return const _TacticalCommands(
          defenseAction: Phase0aDefenseAction.dodge,
        );
      }
      if (tuning != null &&
          player.defenseCooldownRemaining <= 0 &&
          player.shieldRemaining <= 0 &&
          tuning.shieldAbsorption > 0) {
        return const _TacticalCommands(
          defenseAction: Phase0aDefenseAction.shield,
        );
      }
      if (tuning != null &&
          player.defenseCooldownRemaining <= 0 &&
          tuning.parryWindowTicks > 0) {
        return const _TacticalCommands(
          defenseAction: Phase0aDefenseAction.parry,
        );
      }
      return const _TacticalCommands();
    }
    if (policy.parallelTacticalActions) {
      return _TacticalCommands(
        gather: policy.allows(Phase0aBotAction.gather) && gatherReady,
        clear: policy.allows(Phase0aBotAction.clear) && clearReady,
        skillHotkey: policy.allows(Phase0aBotAction.numericSkill)
            ? numericSkill
            : null,
      );
    }
    for (final action in policy.actionPriority) {
      switch (action) {
        case Phase0aBotAction.defense:
          final tuning = playerAdapter.defenseTuning;
          if (tuning != null &&
              player.defenseCooldownRemaining <= 0 &&
              target.chargingCast != null) {
            return const _TacticalCommands(
              defenseAction: Phase0aDefenseAction.dodge,
            );
          }
          if (tuning != null &&
              player.defenseCooldownRemaining <= 0 &&
              player.shieldRemaining <= 0 &&
              tuning.shieldAbsorption > 0) {
            return const _TacticalCommands(
              defenseAction: Phase0aDefenseAction.shield,
            );
          }
          if (tuning != null &&
              player.defenseCooldownRemaining <= 0 &&
              tuning.parryWindowTicks > 0) {
            return const _TacticalCommands(
              defenseAction: Phase0aDefenseAction.parry,
            );
          }
        case Phase0aBotAction.gather:
          if (policy.allows(action) && gatherReady) {
            return const _TacticalCommands(gather: true);
          }
        case Phase0aBotAction.clear:
          if (policy.allows(action) && clearReady) {
            return const _TacticalCommands(clear: true);
          }
        case Phase0aBotAction.numericSkill:
          if (policy.allows(action) && numericSkill != null) {
            return _TacticalCommands(skillHotkey: numericSkill);
          }
      }
    }
    return const _TacticalCommands();
  }

  /// 最近存活敌人;等距时按 id 稳定决胜,保证确定性。
  Phase0aActor _targetFor(Phase0aArenaState state) {
    if (policy.prioritizeBurstWindowTarget) {
      final windowTargets = state.enemies.where(_isBurstWindow);
      if (windowTargets.isNotEmpty) {
        return _nearestEnemy(state, candidates: windowTargets);
      }
    }
    return _nearestEnemy(state);
  }

  bool _isBurstWindow(Phase0aActor enemy) =>
      enemy.posture?.isVulnerable ?? false;

  Phase0aActor _nearestEnemy(
    Phase0aArenaState state, {
    Iterable<Phase0aActor>? candidates,
  }) {
    return _nearestEnemyFrom(candidates ?? state.enemies, state.player);
  }

  Phase0aActor _nearestEnemyFrom(
    Iterable<Phase0aActor> enemies,
    Phase0aActor player,
  ) {
    final first = enemies.first;
    var best = first;
    var bestDistance = (best.position - player.position).lengthSquared;
    for (final enemy in enemies.skip(1)) {
      final distance = (enemy.position - player.position).lengthSquared;
      if (distance < bestDistance ||
          (distance == bestDistance && enemy.id.compareTo(best.id) < 0)) {
        best = enemy;
        bestDistance = distance;
      }
    }
    return best;
  }

  bool _slotReady(Phase0aArenaState state, String slot) {
    for (final skillSlot in state.skillSlots) {
      if (skillSlot.slot == slot) {
        return skillSlot.availability == Phase0aSkillAvailability.ready;
      }
    }
    return false;
  }

  int? _firstReadyNumericSkill(Phase0aArenaState state) {
    for (final binding in playerAdapter.numericSkillBindings.equipped) {
      if (_slotReady(state, binding.slotId)) return binding.hotkey;
    }
    return null;
  }
}

final class _TacticalCommands {
  const _TacticalCommands({
    this.gather = false,
    this.clear = false,
    this.skillHotkey,
    this.defenseAction,
  });

  final bool gather;
  final bool clear;
  final int? skillHotkey;
  final Phase0aDefenseAction? defenseAction;
}
