import 'defense_resolution.dart';

/// Phase 0A 防御纵切的显式 TUNING 输入。
///
/// 生产值来自 `data/numbers.yaml`；领域层不提供生产默认值。测试必须显式
/// 构造本对象，避免把数值藏进 reducer 或技能名称推导。
final class Phase0aDefenseTuning {
  const Phase0aDefenseTuning({
    required this.shieldAbsorption,
    required this.shieldDurationTicks,
    required this.parryWindowTicks,
    required this.counterDamage,
    required this.counterUpperBound,
    required this.dodgeIframeTicks,
    required this.dodgeDistance,
    required this.defenseCooldownSeconds,
    required this.basicAttackFlags,
    required this.skillAttackFlags,
  });

  final double shieldAbsorption;
  final int shieldDurationTicks;
  final int parryWindowTicks;
  final double counterDamage;
  final double counterUpperBound;
  final int dodgeIframeTicks;
  final double dodgeDistance;
  final double defenseCooldownSeconds;
  final AttackDefenseFlags basicAttackFlags;
  final AttackDefenseFlags skillAttackFlags;

  bool get isEnabled =>
      shieldAbsorption > 0 || parryWindowTicks > 0 || dodgeIframeTicks > 0;
}
