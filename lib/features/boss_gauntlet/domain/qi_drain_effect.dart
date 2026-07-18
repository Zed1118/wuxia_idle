/// 敌方真气扣减通用效果（断魂庄 design §5.2）。
///
/// 现行真气规则只有自产/自耗（CLAUDE v1.34），敌方剥夺玩家真气是引擎新维度。
/// 实装为敌方招式的通用配置字段（`qi_drain_pct`），schema 硬界：比例 ∈ (0, 0.5]、
/// 扣减基于**最大真气**、只降至零不为负。苏无咎「锁脉针」为首个实例，未来 Boss 可
/// 复用。属「资源剥夺」方向机制，不膨胀伤害数字（守 CLAUDE §5.4）。
class QiDrainEffect {
  QiDrainEffect({required this.pct}) {
    if (pct <= 0.0 || pct > 0.5) {
      throw ArgumentError('qi_drain pct 须 ∈ (0, 0.5]，got $pct');
    }
  }

  /// 扣减比例，作用于**最大真气**（design §5.2 锁脉针 = 30% 最大真气）。
  final double pct;

  /// 对一名角色施加：从 [currentQi] 扣 `round(pct * maxQi)`，下限 0（不为负）。
  int applyTo({required int currentQi, required int maxQi}) {
    final drained = currentQi - (pct * maxQi).round();
    return drained < 0 ? 0 : drained;
  }
}
