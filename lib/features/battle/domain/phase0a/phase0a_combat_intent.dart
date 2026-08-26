import 'arena_vector.dart';
import '../../../../core/domain/enums.dart';
import '../../../../data/defs/skill_def.dart';
import 'phase0a_damage_kind.dart';
import 'phase0a_combat_model.dart';
import 'defense_resolution.dart';
import 'phase0a_enemy_behavior_profile.dart';
export 'posture.dart' show PostureHitKind;

const _noBreakPower = 0;

/// Phase 0A 统一输入协议:玩家适配器与敌 AI 适配器产生同型 intent,
/// 经同一 reducer 结算,不存在两套结算入口。
///
/// 全部调优数值(范围/角度/环半径/真气消耗/CD)由 intent 显式携带,
/// reducer 不提供默认值。
sealed class Phase0aIntent {
  const Phase0aIntent({required this.actorId});

  /// 出手者语义 id;reducer 按 id 稳定排序处理。
  final String actorId;
}

enum Phase0aDefenseAction { shield, parry, dodge }

/// Typed player defense action. All runtime values are injected by the input
/// adapter from the explicit defense TUNING section; the reducer only checks
/// validity and consumes the action.
final class Phase0aDefenseIntent extends Phase0aIntent {
  const Phase0aDefenseIntent({
    required super.actorId,
    required this.action,
    required this.direction,
    required this.shieldAbsorption,
    required this.shieldDurationTicks,
    required this.parryWindowTicks,
    required this.counterDamage,
    required this.counterUpperBound,
    required this.dodgeIframeTicks,
    required this.dodgeDistance,
    required this.cooldownSeconds,
  });

  final Phase0aDefenseAction action;
  final ArenaVector direction;
  final double shieldAbsorption;
  final int shieldDurationTicks;
  final int parryWindowTicks;
  final double counterDamage;
  final double counterUpperBound;
  final int dodgeIframeTicks;
  final double dodgeDistance;
  final double cooldownSeconds;
}

/// 移动请求:[direction] 为零向量时不改变位置与朝向。
final class Phase0aMoveIntent extends Phase0aIntent {
  const Phase0aMoveIntent({
    required super.actorId,
    required this.direction,
    this.behaviorProfile,
  });

  final ArenaVector direction;
  final Phase0aEnemyBehaviorProfile? behaviorProfile;
}

/// 普攻请求:距离 + 朝向扇区双条件由 reducer 用显式参数判定;
/// [aimDirection] 为出手者本拍瞄准方向(扇区中轴)。
final class Phase0aAttackIntent extends Phase0aIntent {
  const Phase0aAttackIntent({
    required super.actorId,
    required this.range,
    required this.halfArcRadians,
    required this.cooldownSeconds,
    required this.moveKind,
    required this.aimDirection,
    required this.qiDelta,
    required this.postureDamage,
    required this.postureHitKind,
    this.defenseFlags,
    this.behaviorProfile,
  });

  final double range;
  final double halfArcRadians;
  final double cooldownSeconds;
  final Phase0aMoveKind moveKind;
  final ArenaVector aimDirection;

  /// Pre-resolved qi delta for this basic attack. Zero preserves existing
  /// fixtures; production mapping supplies the bound basic skill value.
  final int qiDelta;
  final double postureDamage;
  final PostureHitKind postureHitKind;
  final AttackDefenseFlags? defenseFlags;
  final Phase0aEnemyBehaviorProfile? behaviorProfile;
}

/// Enemy phase-unlocked skill request. Binding and policy are resolved in the
/// application AI adapter; the reducer only validates runtime state and applies
/// the injected skill through the production damage resolver.
final class Phase0aEnemySkillIntent extends Phase0aIntent {
  const Phase0aEnemySkillIntent({
    required super.actorId,
    required this.skill,
    required this.aimDirection,
    required this.range,
    required this.halfArcRadians,
    required this.effectRadius,
    required this.cooldownSeconds,
    required this.actionCooldownSeconds,
    required this.postureDamage,
    required this.postureHitKind,
    this.defenseFlags,
    this.behaviorProfile,
  });

  final SkillDef skill;
  final ArenaVector aimDirection;
  final double range;
  final double halfArcRadians;
  final double effectRadius;
  final double cooldownSeconds;
  final double actionCooldownSeconds;
  final double postureDamage;
  final PostureHitKind postureHitKind;
  final AttackDefenseFlags? defenseFlags;
  final Phase0aEnemyBehaviorProfile? behaviorProfile;
}

/// Q 聚怪请求:作用半径内目标逐目标结算 outcomes;
/// [ringRadius] 只决定目标落点环,不得冒充作用半径,
/// `ringRadius > effectRadius` 为非法参数(reducer 拒绝释放)。
///
/// player-only 契约:技能印/真气循环是玩家全局态,reducer 拒绝非玩家
/// actor 的 gather intent(不结算、不耗气、不动冷却、不发事件);
/// 数值参数(半径/冷却/真气)要求有限且非负,非法同样拒绝。
final class Phase0aGatherIntent extends Phase0aIntent {
  const Phase0aGatherIntent({
    required super.actorId,
    required this.slot,
    required this.ringRadius,
    required this.effectRadius,
    required this.qiCost,
    required this.cooldownSeconds,
    required this.postureDamage,
    required this.postureHitKind,
    this.skillId = '',
  });

  /// Production mappings carry the real data-defined tactical skill id.
  /// Empty is reserved for isolated legacy fixtures.
  final String skillId;
  final String slot;
  final double ringRadius;

  /// 作用半径:仅距 caster ≤ 该值的存活敌对单位进入结算(闭区间)。
  final double effectRadius;

  final int qiCost;
  final double cooldownSeconds;
  final double postureDamage;
  final PostureHitKind postureHitKind;
}

/// R 清场请求:作用半径内存活敌方单位逐目标稳定顺序结算。
///
/// player-only 契约与数值边界:同 [Phase0aGatherIntent]。
final class Phase0aClearIntent extends Phase0aIntent {
  const Phase0aClearIntent({
    required super.actorId,
    required this.slot,
    required this.effectRadius,
    required this.qiCost,
    required this.cooldownSeconds,
    required this.postureDamage,
    required this.postureHitKind,
    this.skillId = '',
    this.breakPower = _noBreakPower,
  });

  /// Production mappings carry the real data-defined tactical skill id.
  /// Empty is reserved for isolated legacy fixtures.
  final String skillId;
  final String slot;

  /// 作用半径:仅距 caster ≤ 该值的存活敌对单位进入结算(闭区间)。
  final double effectRadius;

  final int qiCost;
  final double cooldownSeconds;
  final double postureDamage;
  final PostureHitKind postureHitKind;

  /// typed break 契约载荷(skill behavior `break.points`):>0 时仅对
  /// 正在蓄力的 Boss 追加姿态折算;0 = 无额外破招效力。
  final int breakPower;
}

/// 数字 1–6 真实技能请求。所有运行参数均由 application binding Adapter
/// 预解析后显式携带；reducer 不回查仓库、不猜范围或冷却。
final class Phase0aSkillIntent extends Phase0aIntent {
  const Phase0aSkillIntent({
    required super.actorId,
    required this.kind,
    required this.slot,
    required this.skillId,
    required this.targetType,
    required this.aimDirection,
    required this.range,
    required this.halfArcRadians,
    required this.effectRadius,
    required this.qiDelta,
    required this.cooldownSeconds,
    required this.postureDamage,
    required this.postureHitKind,
    this.defenseFlags,
    this.breakPower = _noBreakPower,
  });

  final Phase0aDamageKind kind;
  final String slot;
  final String skillId;
  final TargetType targetType;
  final ArenaVector aimDirection;
  final double range;
  final double halfArcRadians;
  final double effectRadius;
  final int qiDelta;
  final double cooldownSeconds;
  final double postureDamage;
  final PostureHitKind postureHitKind;
  final AttackDefenseFlags? defenseFlags;

  /// typed break 契约载荷(数字技能 binding 的 `break.points`):语义同
  /// [Phase0aClearIntent.breakPower]。
  final int breakPower;
}
