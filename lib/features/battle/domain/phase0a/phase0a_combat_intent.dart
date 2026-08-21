import 'arena_vector.dart';
import '../../../../core/domain/enums.dart';
import '../../../../data/defs/skill_def.dart';
import 'phase0a_damage_kind.dart';
import 'phase0a_combat_model.dart';

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

/// 移动请求:[direction] 为零向量时不改变位置与朝向。
final class Phase0aMoveIntent extends Phase0aIntent {
  const Phase0aMoveIntent({required super.actorId, required this.direction});

  final ArenaVector direction;
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
  });

  final double range;
  final double halfArcRadians;
  final double cooldownSeconds;
  final Phase0aMoveKind moveKind;
  final ArenaVector aimDirection;

  /// Pre-resolved qi delta for this basic attack. Zero preserves existing
  /// fixtures; production mapping supplies the bound basic skill value.
  final int qiDelta;
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
  });

  final SkillDef skill;
  final ArenaVector aimDirection;
  final double range;
  final double halfArcRadians;
  final double effectRadius;
  final double cooldownSeconds;
  final double actionCooldownSeconds;
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
  });

  final String slot;
  final double ringRadius;

  /// 作用半径:仅距 caster ≤ 该值的存活敌对单位进入结算(闭区间)。
  final double effectRadius;

  final int qiCost;
  final double cooldownSeconds;
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
  });

  final String slot;

  /// 作用半径:仅距 caster ≤ 该值的存活敌对单位进入结算(闭区间)。
  final double effectRadius;

  final int qiCost;
  final double cooldownSeconds;
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
}
