import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/basic_attack_chain.dart';
import '../../domain/phase0a/basic_attack_geometry_registry.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_damage_kind.dart';
import '../../domain/phase0a/phase0a_defense_tuning.dart';
import '../../domain/phase0a/realtime_combat_rules.dart';
import '../../domain/phase0a/posture.dart';
import 'phase0a_numeric_skill_binding.dart';
import 'phase0a_tactical_skill_binding.dart';

const _noBreakPower = 0;

/// 玩家一拍输入快照:四向按键 + 动作请求(语义按键,非数值)。
final class Phase0aPlayerCommand {
  const Phase0aPlayerCommand({
    this.left = false,
    this.right = false,
    this.up = false,
    this.down = false,
    this.moveDirection,
    this.attack = false,
    this.attackAimDirection,
    this.attackTargetId,
    this.skillHotkey,
    this.skillAimDirection,
    this.gather = false,
    this.gatherTargetPoint,
    this.clear = false,
    this.defenseAction,
    this.defenseDirection,
  });

  final bool left;
  final bool right;
  final bool up;
  final bool down;

  /// Mouse/context movement in world space. When present it takes precedence
  /// over the four keyboard directions for this fixed-tick command.
  final ArenaVector? moveDirection;

  /// 普攻请求。
  final bool attack;

  /// 鼠标普攻的世界空间瞄准方向；null = 键盘兼容路径沿用当前朝向。
  final ArenaVector? attackAimDirection;

  /// Context-click preferred target. The reducer still validates side,
  /// survival, range, arc, and guardian rules before honoring it.
  final String? attackTargetId;

  /// 数字 1–6 的真实技能槽请求；空槽由 input Adapter fail-closed。
  final int? skillHotkey;
  final ArenaVector? skillAimDirection;

  /// Q 聚怪请求。
  final bool gather;

  /// 地面定点聚怪中心；null 保留自动/旧调用的施放者中心兼容语义。
  final ArenaVector? gatherTargetPoint;

  /// R 清场请求。
  final bool clear;

  final Phase0aDefenseAction? defenseAction;
  final ArenaVector? defenseDirection;
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
    required this.attackQiDelta,
    required this.postureBasicPowerMultiplier,
    required this.attackPowerMultiplier,
    required this.gatherPowerMultiplier,
    required this.clearPowerMultiplier,
    required this.gatherSlot,
    required this.gatherRingRadius,
    required this.gatherEffectRadius,
    required this.gatherQiCost,
    required this.gatherCooldownSeconds,
    required this.clearSlot,
    required this.clearEffectRadius,
    required this.clearQiCost,
    required this.clearCooldownSeconds,
    this.gatherSkillBinding,
    this.clearSkillBinding,
    this.numericSkillBindings = const Phase0aNumericSkillBindings.empty(),
    this.defenseTuning,
    this.basicAttackChain,
    this.basicAttackGeometryRegistry,
    this.basicAttackArenaBounds,
  });

  final String playerId;
  final double attackRange;
  final double attackHalfArcRadians;
  final double attackCooldownSeconds;
  final int attackQiDelta;
  final int postureBasicPowerMultiplier;
  final int attackPowerMultiplier;
  final int gatherPowerMultiplier;
  final int clearPowerMultiplier;
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
  final Phase0aTacticalSkillBinding? gatherSkillBinding;
  final Phase0aTacticalSkillBinding? clearSkillBinding;
  final Phase0aNumericSkillBindings numericSkillBindings;
  final Phase0aDefenseTuning? defenseTuning;
  final BasicAttackChain? basicAttackChain;
  final BasicAttackGeometryRegistry? basicAttackGeometryRegistry;
  final BasicAttackArenaBounds? basicAttackArenaBounds;

  ArenaVector movementDirectionFor(Phase0aPlayerCommand command) =>
      command.moveDirection?.normalized() ??
      normalizeMovementInput(
        left: command.left,
        right: command.right,
        up: command.up,
        down: command.down,
      );

  List<Phase0aIntent> intentsFor({
    required Phase0aArenaState state,
    required Phase0aPlayerCommand command,
  }) {
    final intents = <Phase0aIntent>[];
    final direction = movementDirectionFor(command);
    if (direction.lengthSquared > 0) {
      intents.add(Phase0aMoveIntent(actorId: playerId, direction: direction));
    }
    final defense = command.defenseAction;
    final defenseTuning = this.defenseTuning;
    if (defense != null && defenseTuning != null && defenseTuning.isEnabled) {
      final direction = command.defenseDirection ?? state.player.facing;
      intents.add(
        Phase0aDefenseIntent(
          actorId: playerId,
          action: defense,
          direction: direction,
          shieldAbsorption: defenseTuning.shieldAbsorption,
          shieldDurationTicks: defenseTuning.shieldDurationTicks,
          parryWindowTicks: defenseTuning.parryWindowTicks,
          counterDamage: defenseTuning.counterDamage,
          counterUpperBound: defenseTuning.counterUpperBound,
          dodgeIframeTicks: defenseTuning.dodgeIframeTicks,
          dodgeDistance: defenseTuning.dodgeDistance,
          cooldownSeconds: defenseTuning.defenseCooldownSeconds,
        ),
      );
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
          preferredTargetId: command.attackTargetId,
          qiDelta: attackQiDelta,
          postureDamage: powerMultiplierToPostureDamage(
            attackPowerMultiplier,
            basicPowerMultiplier: postureBasicPowerMultiplier,
          ),
          postureHitKind: PostureHitKind.light,
          defenseFlags: defenseTuning?.basicAttackFlags,
          basicAttackChain: basicAttackChain,
          basicAttackGeometryRegistry: basicAttackGeometryRegistry,
          basicAttackArenaBounds: basicAttackArenaBounds,
        ),
      );
    }
    if (command.gather) {
      final binding = gatherSkillBinding;
      intents.add(
        Phase0aGatherIntent(
          actorId: playerId,
          skillId: binding?.skill.id ?? '',
          slot: binding?.slot ?? gatherSlot,
          ringRadius: binding?.destinationRadius ?? gatherRingRadius,
          controlTicks: binding?.controlTicks ?? 0,
          effectRadius: binding?.effectRadius ?? gatherEffectRadius,
          qiCost: binding?.qiCost ?? gatherQiCost,
          cooldownSeconds: binding?.cooldownSeconds ?? gatherCooldownSeconds,
          targetPoint: command.gatherTargetPoint,
          postureDamage: binding == null
              ? powerMultiplierToPostureDamage(
                  gatherPowerMultiplier,
                  basicPowerMultiplier: postureBasicPowerMultiplier,
                )
              : addDefenseBreakPostureDamage(
                  powerMultiplierToPostureDamage(
                    binding.skill.powerMultiplier,
                    basicPowerMultiplier: postureBasicPowerMultiplier,
                  ),
                  defenseBreakPct: binding.skill.defenseBreakPct,
                ),
          postureHitKind: PostureHitKind.heavy,
        ),
      );
    }
    if (command.clear) {
      final binding = clearSkillBinding;
      intents.add(
        Phase0aClearIntent(
          actorId: playerId,
          skillId: binding?.skill.id ?? '',
          slot: binding?.slot ?? clearSlot,
          effectRadius: binding?.effectRadius ?? clearEffectRadius,
          qiCost: binding?.qiCost ?? clearQiCost,
          cooldownSeconds: binding?.cooldownSeconds ?? clearCooldownSeconds,
          postureDamage: binding == null
              ? powerMultiplierToPostureDamage(
                  clearPowerMultiplier,
                  basicPowerMultiplier: postureBasicPowerMultiplier,
                )
              : addDefenseBreakPostureDamage(
                  powerMultiplierToPostureDamage(
                    binding.skill.powerMultiplier,
                    basicPowerMultiplier: postureBasicPowerMultiplier,
                  ),
                  defenseBreakPct: binding.skill.defenseBreakPct,
                ),
          postureHitKind: (binding?.breakPower ?? _noBreakPower) > 0
              ? PostureHitKind.bossControl
              : PostureHitKind.heavy,
          breakPower: binding?.breakPower ?? _noBreakPower,
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
            kind: phase0aDamageKindForSkillHotkey(hotkey),
            slot: binding.slotId,
            skillId: binding.skill.id,
            targetType: binding.targetType,
            aimDirection: command.skillAimDirection ?? state.player.facing,
            range: binding.attackRange,
            halfArcRadians: binding.halfArc,
            effectRadius: binding.effectRadius,
            qiDelta: binding.qiDelta,
            cooldownSeconds: binding.cooldownSeconds,
            postureDamage: binding.postureDamageFor(
              basicPowerMultiplier: postureBasicPowerMultiplier,
            ),
            postureHitKind: binding.breakPower > 0
                ? PostureHitKind.bossControl
                : PostureHitKind.heavy,
            breakPower: binding.breakPower,
            defenseFlags: defenseTuning?.skillAttackFlags,
          ),
        );
      }
    }
    return intents;
  }
}
