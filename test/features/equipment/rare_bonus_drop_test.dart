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
        // 默认 ng_plus = chance(不区分周目),周目用例另用 cfgNg。
        tiers: tiers
            .map((t) =>
                RareBonusTier(offset: t.$1, chance: t.$2, chanceNgPlus: t.$2))
            .toList(),
      );

  // 周目差异化:(offset, chance一周目, chanceNgPlus二周目起)。
  RareBonusDropConfig cfgNg(List<(int, double, double)> tiers) =>
      RareBonusDropConfig(
        enabled: true,
        tiers: tiers
            .map((t) =>
                RareBonusTier(offset: t.$1, chance: t.$2, chanceNgPlus: t.$3))
            .toList(),
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

  // ── 周目平衡 2026-06-26:cycle≥2 用 chanceNgPlus ──
  group('周目感知 chanceFor / selectRareBonusTier cycle', () {
    test('RareBonusTier.chanceFor:cycle1→chance / cycle≥2→chanceNgPlus', () {
      const t = RareBonusTier(offset: 1, chance: 0.05, chanceNgPlus: 0.08);
      expect(t.chanceFor(1), 0.05);
      expect(t.chanceFor(2), 0.08);
      expect(t.chanceFor(3), 0.08, reason: '三周目仍用 ng_plus(非随周目继续涨)');
    });

    test('fromYaml 缺 chance_ng_plus → 默认 = chance(向后兼容)', () {
      final t = RareBonusTier.fromYaml({'offset': 1, 'chance': 0.05});
      expect(t.chance, 0.05);
      expect(t.chanceNgPlus, 0.05);
    });

    test('一周目 chance=0 不命中 / 二周目 chance_ng_plus=1.0 命中', () {
      // chance 一周目 0(恒不命中)、二周目 1.0(恒命中)→ 验 cycle 切换分支。
      final config = cfgNg([(1, 0.0, 1.0)]);
      expect(
        selectRareBonusTier(EquipmentTier.xunChang, config, DefaultRng(seed: 1),
            cycle: 1),
        isNull,
        reason: '一周目 chance=0 不掉',
      );
      expect(
        selectRareBonusTier(EquipmentTier.xunChang, config, DefaultRng(seed: 1),
            cycle: 2),
        EquipmentTier.xiangYang,
        reason: '二周目 chance_ng_plus=1.0 掉 +1 阶',
      );
    });

    test('cycle 默认 1(不传 = 一周目行为)', () {
      final config = cfgNg([(1, 0.0, 1.0)]);
      expect(
        selectRareBonusTier(EquipmentTier.xunChang, config, DefaultRng(seed: 1)),
        isNull,
        reason: '不传 cycle 默认一周目 chance=0',
      );
    });
  });
}
