import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/domain/rare_bonus_drop.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

/// 第八阶段 E·稀有彩头阶选择纯逻辑 TDD。
///
/// 全局机制:每场战斗除本关固定掉落外,小概率额外掉「高于本关 1-2 阶」的装备,
/// 概率随阶差递减但不为零(用户拍板·守 §5.3 可拿不可装由境界锁兜底)。
void main() {
  // chance=1.0 → nextDouble()∈[0,1) 恒 <1.0 命中;chance=0.0 → 恒不命中。
  final rng = DefaultRng(seed: 1);

  RareBonusDropConfig cfg(List<(int, double)> tiers, {bool enabled = true}) =>
      RareBonusDropConfig(
        enabled: enabled,
        tiers: tiers.map((t) => RareBonusTier(offset: t.$1, chance: t.$2)).toList(),
      );

  test('+1 阶 chance=1.0 → 返回本阶 +1', () {
    final t = selectRareBonusTier(
        EquipmentTier.xunChang, cfg([(1, 1.0)]), rng);
    expect(t, EquipmentTier.xiangYang); // 寻常货 +1 = 像样货
  });

  test('全 chance=0 → null(不掉)', () {
    final t = selectRareBonusTier(
        EquipmentTier.xunChang, cfg([(1, 0.0), (2, 0.0)]), rng);
    expect(t, isNull);
  });

  test('+1 与 +2 都命中 → 取最高(+2)', () {
    final t = selectRareBonusTier(
        EquipmentTier.xunChang, cfg([(1, 1.0), (2, 1.0)]), rng);
    expect(t, EquipmentTier.haoJiaHuo); // 寻常货 +2 = 好家伙(更稀有优先)
  });

  test('封顶:神物 +1/+2 越界 → null(终局不超神物)', () {
    final t = selectRareBonusTier(
        EquipmentTier.shenWu, cfg([(1, 1.0), (2, 1.0)]), rng);
    expect(t, isNull);
  });

  test('近顶:宝物 +1=神物命中 / +2 越界 → 神物', () {
    final t = selectRareBonusTier(
        EquipmentTier.baoWu, cfg([(1, 1.0), (2, 1.0)]), rng);
    expect(t, EquipmentTier.shenWu);
  });

  test('disabled → null', () {
    final t = selectRareBonusTier(
        EquipmentTier.xunChang, cfg([(1, 1.0)], enabled: false), rng);
    expect(t, isNull);
  });
}
