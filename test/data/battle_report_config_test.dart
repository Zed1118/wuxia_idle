import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  test('BattleReportConfig.fromYaml 解析 4 阈值', () {
    final cfg = BattleReportConfig.fromYaml(const {
      'internal_wound_pct': 0.30,
      'minion_damage_pct': 0.35,
      'frontline_death_phase_pct': 0.5,
      'survivor_hp_pct': 0.5,
    });
    expect(cfg.internalWoundPct, 0.30);
    expect(cfg.minionDamagePct, 0.35);
    expect(cfg.frontlineDeathPhasePct, 0.5);
    expect(cfg.survivorHpPct, 0.5);
  });

  test('BattleReportConfig.fromYaml 越界(>1 或 <=0)抛错', () {
    expect(
      () => BattleReportConfig.fromYaml(const {
        'internal_wound_pct': 1.5,
        'minion_damage_pct': 0.35,
        'frontline_death_phase_pct': 0.5,
        'survivor_hp_pct': 0.5,
      }),
      throwsArgumentError,
    );
    expect(
      () => BattleReportConfig.fromYaml(const {
        'internal_wound_pct': 0.30,
        'minion_damage_pct': 0.0,
        'frontline_death_phase_pct': 0.5,
        'survivor_hp_pct': 0.5,
      }),
      throwsArgumentError,
    );
  });
}
