import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_damage_kind.dart';
import '../../domain/phase0a/realtime_combat_rules.dart';
import 'phase0a_numeric_skill_binding.dart';

/// 玩家一拍输入快照:四向按键 + 动作请求(语义按键,非数值)。
final class Phase0aPlayerCommand {
  const Phase0aPlayerCommand({
    this.left = false,
    this.right = false,
    this.up = false,
    this.down = false,
    this.attack = false,
    this.attackAimDirection,
    this.skillHotkey,
    this.skillAimDirection,
    this.gather = false,
    this.clear = false,
  });

  final bool left;
  final bool right;
  final bool up;
  final bool down;

  /// 普攻请求。
  final bool attack;

  /// 鼠标普攻的世界空间瞄准方向；null = 键盘兼容路径沿用当前朝向。
  final ArenaVector? attackAimDirection;

  /// 数字 1–6 的真实技能槽请求；空槽由 input Adapter fail-closed。
  final int? skillHotkey;
  final ArenaVector? skillAimDirection;

  /// Q 聚怪请求。
  final bool gather;

  /// R 清场请求。
  final bool clear;
}

/// 玩家输入适配器:按键/动作请求 → 统一 intent。
///
/// 移动经 [normalizeMovementInput] 归一(对角单位长度);普攻瞄准方向取
/// 玩家当前朝向;全部调优数值(范围/角度/环半径/真气/CD)由构造方显式注入,
/// 本层不复制任何结算规则。
final class Phase0aPlayerInputAdapter {
  const Phase0aPlayerInputAdapter({
    required this.playerId,
    required this.attackRange,
    required this.attackHalfArcRadians,
    required this.attackCooldownSeconds,
    required this.gatherSlot,
    required this.gatherRingRadius,
    required this.gatherEffectRadius,
    required this.gatherQiCost,
    required this.gatherCooldownSeconds,
    required this.clearSlot,
    required this.clearEffectRadius,
    required this.clearQiCost,
    required this.clearCooldownSeconds,
    this.numericSkillBindings = const Phase0aNumericSkillBindings.empty(),
  });

  final String playerId;
  final double attackRange;
  final double attackHalfArcRadians;
  final double attackCooldownSeconds;
  final String gatherSlot;
  final double gatherRingRadius;

  /// Q 聚怪作用半径:仅距玩家 ≤ 该值的敌对单位进入结算(闭区间)。
  final double gatherEffectRadius;
  final int gatherQiCost;
  final double gatherCooldownSeconds;
  final String clearSlot;

  /// R 清场作用半径:仅距玩家 ≤ 该值的敌对单位进入结算(闭区间)。
  final double clearEffectRadius;
  final int clearQiCost;
  final double clearCooldownSeconds;
  final Phase0aNumericSkillBindings numericSkillBindings;

  List<Phase0aIntent> intentsFor({
    required Phase0aArenaState state,
    required Phase0aPlayerCommand command,
  }) {
    final intents = <Phase0aIntent>[];
    final direction = normalizeMovementInput(
      left: command.left,
      right: command.right,
      up: command.up,
      down: command.down,
    );
    if (direction.lengthSquared > 0) {
      intents.add(Phase0aMoveIntent(actorId: playerId, direction: direction));
    }
    if (command.attack) {
      intents.add(
        Phase0aAttackIntent(
          actorId: playerId,
          range: attackRange,
          halfArcRadians: attackHalfArcRadians,
          cooldownSeconds: attackCooldownSeconds,
          moveKind: Phase0aMoveKind.light,
          aimDirection: command.attackAimDirection ?? state.player.facing,
        ),
      );
    }
    if (command.gather) {
      intents.add(
        Phase0aGatherIntent(
          actorId: playerId,
          slot: gatherSlot,
          ringRadius: gatherRingRadius,
          effectRadius: gatherEffectRadius,
          qiCost: gatherQiCost,
          cooldownSeconds: gatherCooldownSeconds,
        ),
      );
    }
    if (command.clear) {
      intents.add(
        Phase0aClearIntent(
          actorId: playerId,
          slot: clearSlot,
          effectRadius: clearEffectRadius,
          qiCost: clearQiCost,
          cooldownSeconds: clearCooldownSeconds,
        ),
      );
    }
    final hotkey = command.skillHotkey;
    if (hotkey != null) {
      final binding = numericSkillBindings.bindingFor(hotkey);
      if (binding != null) {
        intents.add(
          Phase0aSkillIntent(
            actorId: playerId,
            kind: Phase0aDamageKindX.forSkillHotkey(hotkey),
            slot: binding.slotId,
            skillId: binding.skill.id,
            targetType: binding.targetType,
            aimDirection: command.skillAimDirection ?? state.player.facing,
            range: binding.attackRange,
            halfArcRadians: binding.halfArc,
            effectRadius: binding.effectRadius,
            qiDelta: binding.qiDelta,
            cooldownSeconds: binding.cooldownSeconds,
          ),
        );
      }
    }
    return intents;
  }
}
