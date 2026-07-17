/// 双层伤势系统配置（numbers.yaml `injury` 段）。
///
/// 轻伤（light_injury）：战斗中叠层，每层扣出手速度，最多 [lightMaxStacks] 层。
/// 重伤（heavy_injury）：战斗结束惨胜（存活队员 endHp < [heavyWinHpThresholdPct]*maxHp）
/// 或被动离线结算时触发，需疗养 [heavyRecoveryHours] 小时。
///
/// 设计 spec：第八阶段（双层伤势 · 2026-06-25）。
class InjuryConfig {
  /// 每层轻伤扣减的出手速度（base 100+，轻微扣减）。
  final int lightSpeedPenaltyPerStack;

  /// 轻伤最大叠层数（超出不再叠加）。
  final int lightMaxStacks;

  /// 重伤疗养时长（小时，同心魔余毒先例）。
  final double heavyRecoveryHours;

  /// 重伤期间内力上限扣减比例（0.0 ~ 1.0）。
  final double heavyInternalForceMaxPenaltyPct;

  /// 重伤期间攻击输出乘数（< 1.0）。
  final double heavyAttackOutputMultiplier;

  /// 惨胜判定阈值：存活角色 endHp / maxHp < 此值时触发重伤。
  final double heavyWinHpThresholdPct;

  const InjuryConfig({
    required this.lightSpeedPenaltyPerStack,
    required this.lightMaxStacks,
    required this.heavyRecoveryHours,
    required this.heavyInternalForceMaxPenaltyPct,
    required this.heavyAttackOutputMultiplier,
    required this.heavyWinHpThresholdPct,
  });

  factory InjuryConfig.fromYaml(Map<String, dynamic> y) {
    final l = (y['light_injury'] as Map?) ?? const {};
    final h = (y['heavy_injury'] as Map?) ?? const {};
    return InjuryConfig(
      lightSpeedPenaltyPerStack:
          (l['speed_penalty_per_stack'] as num?)?.toInt() ?? 3,
      lightMaxStacks: (l['max_stacks'] as num?)?.toInt() ?? 5,
      heavyRecoveryHours: (h['recovery_hours'] as num?)?.toDouble() ?? 8.0,
      heavyInternalForceMaxPenaltyPct:
          (h['internal_force_max_penalty_pct'] as num?)?.toDouble() ?? 0.15,
      heavyAttackOutputMultiplier:
          (h['attack_output_multiplier'] as num?)?.toDouble() ?? 0.85,
      heavyWinHpThresholdPct:
          (h['heavy_win_hp_threshold_pct'] as num?)?.toDouble() ?? 0.25,
    );
  }
}
