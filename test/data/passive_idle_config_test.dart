import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('PassiveIdleConfig.fromYaml 解析字段 + realmScaleFor pow(1.3, index)', () {
    final cfg = PassiveIdleConfig.fromYaml(const {
      'base_mojianshi_per_hour': 0.25,
      'base_exp_per_hour': 25.0,
      'realm_scale_per_tier': 1.3,
      'cap_hours': 72,
      'min_recap_hours': 1.0,
    });
    expect(cfg.baseMojianshiPerHour, 0.25);
    expect(cfg.baseExpPerHour, 25.0);
    expect(cfg.capHours, 72);
    expect(cfg.minRecapHours, 1.0);
    expect(cfg.realmScaleFor(RealmTier.xueTu), 1.0); // index 0 → 1.3^0
    expect(cfg.realmScaleFor(RealmTier.sanLiu), closeTo(1.3, 1e-9)); // index 1
  });
}
