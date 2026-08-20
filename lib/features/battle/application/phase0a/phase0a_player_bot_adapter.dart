import 'dart:math' as math;

import '../../domain/phase0a/phase0a_combat_model.dart';
import 'phase0a_player_input_adapter.dart';

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
  const Phase0aPlayerBotAdapter({required this.playerAdapter});

  final Phase0aPlayerInputAdapter playerAdapter;

  Phase0aPlayerCommand commandFor(Phase0aArenaState state) {
    if (!state.player.isAlive || state.enemies.isEmpty) {
      return const Phase0aPlayerCommand();
    }
    final player = state.player;
    final target = _nearestEnemy(state);
    final toTarget = target.position - player.position;
    final distance = toTarget.length;
    final outOfRange = distance > playerAdapter.attackRange;
    final facingOffTarget =
        player.facing.dot(toTarget.normalized()) <
        math.cos(playerAdapter.attackHalfArcRadians);
    return Phase0aPlayerCommand(
      left: (outOfRange || facingOffTarget) && toTarget.x < 0,
      right: (outOfRange || facingOffTarget) && toTarget.x > 0,
      up: (outOfRange || facingOffTarget) && toTarget.y < 0,
      down: (outOfRange || facingOffTarget) && toTarget.y > 0,
      attack: true,
      gather: _slotReady(state, playerAdapter.gatherSlot),
      clear: _slotReady(state, playerAdapter.clearSlot),
      skillHotkey: _firstReadyNumericSkill(state),
    );
  }

  /// 最近存活敌人;等距时按 id 稳定决胜,保证确定性。
  Phase0aActor _nearestEnemy(Phase0aArenaState state) {
    var best = state.enemies.first;
    var bestDistance = (best.position - state.player.position).lengthSquared;
    for (final enemy in state.enemies.skip(1)) {
      final distance = (enemy.position - state.player.position).lengthSquared;
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
