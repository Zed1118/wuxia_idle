import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/injury/domain/injury_config.dart';

void main() {
  test('InjuryConfig.fromYaml 解析全字段 + 缺省默认', () {
    final c = InjuryConfig.fromYaml({
      'light_injury': {'speed_penalty_per_stack': 3, 'max_stacks': 5},
      'heavy_injury': {
        'recovery_hours': 8.0,
        'internal_force_max_penalty_pct': 0.15,
        'attack_output_multiplier': 0.85,
        'heavy_win_hp_threshold_pct': 0.25,
      },
    });
    expect(c.lightSpeedPenaltyPerStack, 3);
    expect(c.lightMaxStacks, 5);
    expect(c.heavyRecoveryHours, 8.0);
    expect(c.heavyInternalForceMaxPenaltyPct, 0.15);
    expect(c.heavyAttackOutputMultiplier, 0.85);
    expect(c.heavyWinHpThresholdPct, 0.25);
    final d = InjuryConfig.fromYaml(const {});
    expect(d.lightMaxStacks, 5);
  });
}
