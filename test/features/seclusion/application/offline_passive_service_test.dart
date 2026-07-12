import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';

void main() {
  const cfg = PassiveIdleConfig(
    baseMojianshiPerHour: 0.25,
    baseExpPerHour: 50.0,
    realmScalePerTier: 1.6,
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
    expect(y.experience, 500); // floor(50×10×1.0)=500
    expect(y.awayHours, 10);
    expect(y.settledHours, 10);
    expect(y.isCapped, isFalse);
  });

  test('超过旧 72h 上限后仍线性累积', () {
    final y = OfflinePassiveService.compute(
      awayHours: 100,
      realmTier: RealmTier.xueTu,
      config: cfg,
    );
    expect(y.experience, 5000);
    expect(y.awayHours, 100);
    expect(y.settledHours, 100);
    expect(y.isCapped, isFalse);
  });

  test('超长挂机不被单次 999999 截断', () {
    final y = OfflinePassiveService.compute(
      awayHours: 24000,
      realmTier: RealmTier.xueTu,
      config: cfg,
    );

    expect(y.experience, 1200000);
    expect(y.settledHours, 24000);
    expect(y.isCapped, isFalse);
  });

  test('境界 scale 生效(三流 ×1.6)', () {
    final y = OfflinePassiveService.compute(
      awayHours: 10,
      realmTier: RealmTier.sanLiu,
      config: cfg,
    );
    expect(y.experience, (50.0 * 10 * 1.6).floor()); // 800
  });

  test('武圣 8h 被动经验不再是千分级收益', () {
    final y = OfflinePassiveService.compute(
      awayHours: 8,
      realmTier: RealmTier.wuSheng,
      config: cfg,
    );
    expect(y.experience, (50.0 * 8 * 16.777216).floor()); // 6710
  });
}
