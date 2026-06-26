import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';

void main() {
  const cfg = PassiveIdleConfig(
    baseMojianshiPerHour: 0.25,
    baseExpPerHour: 25.0,
    realmScalePerTier: 1.3,
    capHours: 72,
    minRecapHours: 1.0,
  );

  test('0h → 全 0', () {
    final y = OfflinePassiveService.compute(
      awayHours: 0,
      realmTier: RealmTier.xueTu,
      config: cfg,
    );
    expect(y.mojianshi, 0);
    expect(y.experience, 0);
    expect(y.settledHours, 0);
    expect(y.isCapped, isFalse);
  });

  test('10h 学徒 → floor(base×10×1.0)', () {
    final y = OfflinePassiveService.compute(
      awayHours: 10,
      realmTier: RealmTier.xueTu,
      config: cfg,
    );
    expect(y.mojianshi, 2); // floor(0.25×10×1.0)=2
    expect(y.experience, 250); // floor(25×10×1.0)=250
    expect(y.awayHours, 10);
    expect(y.settledHours, 10);
    expect(y.isCapped, isFalse);
  });

  test('超 cap 按 cap 截断(100h→72h)', () {
    final y = OfflinePassiveService.compute(
      awayHours: 100,
      realmTier: RealmTier.xueTu,
      config: cfg,
    );
    expect(y.experience, (25.0 * 72).floor()); // 1800
    expect(y.awayHours, 100);
    expect(y.settledHours, 72);
    expect(y.isCapped, isTrue);
  });

  test('境界 scale 生效(三流 ×1.3)', () {
    final y = OfflinePassiveService.compute(
      awayHours: 10,
      realmTier: RealmTier.sanLiu,
      config: cfg,
    );
    expect(y.experience, (25.0 * 10 * 1.3).floor()); // 325
  });
}
