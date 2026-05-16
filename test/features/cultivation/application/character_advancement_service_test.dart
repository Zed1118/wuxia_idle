import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/realm_def.dart';
import 'package:wuxia_idle/features/cultivation/application/character_advancement_service.dart';

/// 49 层固定 fixture:覆盖 7 tier × 7 layer 完整链。
///
/// 数值与 `numbers.yaml realms.tiers[].layers[]` 同步(W15 #30 P3 实测;若
/// yaml 改曲线,本 fixture 同步)。internalForceMax + experienceToNext 是
/// applyExperience 升层后写回 Character 的双字段;equipmentTierCap /
/// techniqueTierCap 在 advancement service 内不用但 RealmDef 必填。
final _realmTable = <RealmTier, Map<RealmLayer, RealmDef>>{
  RealmTier.xueTu: _layers(RealmTier.xueTu, [
    (RealmLayer.qiMeng, 1, 500, 50),
    (RealmLayer.ruMen, 2, 600, 80),
    (RealmLayer.shuLian, 3, 700, 120),
    (RealmLayer.jingTong, 4, 800, 170),
    (RealmLayer.yuanShu, 5, 900, 230),
    (RealmLayer.huaJing, 6, 1000, 300),
    (RealmLayer.dengFeng, 7, 1100, 400),
  ]),
  RealmTier.sanLiu: _layers(RealmTier.sanLiu, [
    (RealmLayer.qiMeng, 8, 1200, 500),
    (RealmLayer.ruMen, 9, 1330, 700),
    (RealmLayer.shuLian, 10, 1460, 950),
    (RealmLayer.jingTong, 11, 1600, 1250),
    (RealmLayer.yuanShu, 12, 1740, 1600),
    (RealmLayer.huaJing, 13, 1870, 2000),
    (RealmLayer.dengFeng, 14, 2000, 2500),
  ]),
  RealmTier.wuSheng: _layers(RealmTier.wuSheng, [
    (RealmLayer.dengFeng, 49, 15000, 0), // 满级
  ]),
};

Map<RealmLayer, RealmDef> _layers(
  RealmTier tier,
  List<(RealmLayer, int, int, int)> rows,
) =>
    {
      for (final r in rows)
        r.$1: RealmDef(
          tier: tier,
          layer: r.$1,
          absoluteLevel: r.$2,
          internalForceMax: r.$3,
          experienceToNext: r.$4,
          equipmentTierCap: EquipmentTier.xunChang,
          techniqueTierCap: TechniqueTier.ruMenGong,
        ),
    };

RealmDef _lookup(RealmTier tier, RealmLayer layer) {
  final t = _realmTable[tier];
  if (t == null) throw StateError('test fixture 未配 tier=${tier.name}');
  final d = t[layer];
  if (d == null) throw StateError('test fixture 未配 ${tier.name}/${layer.name}');
  return d;
}

Character _mkChar({
  RealmTier tier = RealmTier.xueTu,
  RealmLayer layer = RealmLayer.qiMeng,
  int experience = 0,
  int experienceToNextLayer = 50,
  int internalForce = 500,
  int internalForceMax = 500,
}) =>
    Character.create(
      name: 'test',
      realmTier: tier,
      realmLayer: layer,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 1, 1),
      internalForce: internalForce,
    )
      ..experience = experience
      ..experienceToNextLayer = experienceToNextLayer
      ..internalForceMax = internalForceMax;

void main() {
  group('CharacterAdvancementService.nextLayer', () {
    test('layer 非 dengFeng → 同 tier 下一 layer', () {
      final n = CharacterAdvancementService.nextLayer(
        RealmTier.xueTu,
        RealmLayer.qiMeng,
      );
      expect(n, isNotNull);
      expect(n!.tier, RealmTier.xueTu);
      expect(n.layer, RealmLayer.ruMen);
    });

    test('dengFeng → 下一 tier qiMeng', () {
      final n = CharacterAdvancementService.nextLayer(
        RealmTier.xueTu,
        RealmLayer.dengFeng,
      );
      expect(n, isNotNull);
      expect(n!.tier, RealmTier.sanLiu);
      expect(n.layer, RealmLayer.qiMeng);
    });

    test('wuSheng.dengFeng → null(满级)', () {
      final n = CharacterAdvancementService.nextLayer(
        RealmTier.wuSheng,
        RealmLayer.dengFeng,
      );
      expect(n, isNull);
    });
  });

  group('CharacterAdvancementService.applyExperience', () {
    test('delta=0 → no-op,didAdvance=false', () {
      final ch = _mkChar(experience: 100);
      final r = CharacterAdvancementService.applyExperience(
        ch,
        0,
        realmLookup: _lookup,
      );
      expect(r.didAdvance, isFalse);
      expect(r.layersGained, 0);
      expect(ch.experience, 100);
      expect(ch.realmTier, RealmTier.xueTu);
      expect(ch.realmLayer, RealmLayer.qiMeng);
      expect(r.tierBefore, r.tierAfter);
      expect(r.layerBefore, r.layerAfter);
    });

    test('delta<0 → no-op(防误用)', () {
      final ch = _mkChar(experience: 100);
      final r = CharacterAdvancementService.applyExperience(
        ch,
        -50,
        realmLookup: _lookup,
      );
      expect(r.didAdvance, isFalse);
      expect(ch.experience, 100);
    });

    test('EXP 不足 → 累加但不升层', () {
      final ch = _mkChar(experienceToNextLayer: 50);
      final r = CharacterAdvancementService.applyExperience(
        ch,
        30,
        realmLookup: _lookup,
      );
      expect(r.didAdvance, isFalse);
      expect(ch.experience, 30);
      expect(ch.experienceToNextLayer, 50);
      expect(ch.realmLayer, RealmLayer.qiMeng);
    });

    test('EXP 恰好升 1 层 → 写回 max + 阈值 + 剩余 0', () {
      final ch = _mkChar(experienceToNextLayer: 50);
      final r = CharacterAdvancementService.applyExperience(
        ch,
        50,
        realmLookup: _lookup,
      );
      expect(r.didAdvance, isTrue);
      expect(r.layersGained, 1);
      expect(ch.realmLayer, RealmLayer.ruMen);
      expect(ch.experience, 0);
      expect(ch.experienceToNextLayer, 80); // xueTu.ruMen.experienceToNext
      expect(ch.internalForceMax, 600); // xueTu.ruMen.internalForceMax
      expect(r.internalForceMaxBefore, 500);
      expect(r.internalForceMaxAfter, 600);
    });

    test('EXP 多余 → while 多升,剩余 < 下一档阈值停', () {
      // 50+80+120=250 用完到 jingTong;jingTong 阈值 170,剩 150 < 170 停
      final ch = _mkChar(experienceToNextLayer: 50);
      final r = CharacterAdvancementService.applyExperience(
        ch,
        400,
        realmLookup: _lookup,
      );
      expect(r.layersGained, 3);
      expect(ch.realmLayer, RealmLayer.jingTong);
      expect(ch.experience, 150); // 400 - 50 - 80 - 120
      expect(ch.experienceToNextLayer, 170);
      expect(ch.internalForceMax, 800);
    });

    test('跨 tier(dengFeng → 下一 tier qiMeng)', () {
      // 起 xueTu.dengFeng(level 7),experienceToNext=400;给 500 EXP
      // 升 1 层到 sanLiu.qiMeng(level 8),剩 100;sanLiu.qiMeng.exp_to_next=500
      final ch = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.dengFeng,
        experienceToNextLayer: 400,
        internalForceMax: 1100,
      );
      final r = CharacterAdvancementService.applyExperience(
        ch,
        500,
        realmLookup: _lookup,
      );
      expect(r.layersGained, 1);
      expect(r.tierBefore, RealmTier.xueTu);
      expect(r.layerBefore, RealmLayer.dengFeng);
      expect(r.tierAfter, RealmTier.sanLiu);
      expect(r.layerAfter, RealmLayer.qiMeng);
      expect(ch.experience, 100);
      expect(ch.experienceToNextLayer, 500);
      expect(ch.internalForceMax, 1200);
    });

    test('wuSheng.dengFeng experienceToNext=0 → EXP 累加无升层', () {
      final ch = _mkChar(
        tier: RealmTier.wuSheng,
        layer: RealmLayer.dengFeng,
        experience: 0,
        experienceToNextLayer: 0,
        internalForceMax: 15000,
      );
      final r = CharacterAdvancementService.applyExperience(
        ch,
        1000000,
        realmLookup: _lookup,
      );
      expect(r.didAdvance, isFalse);
      expect(r.layersGained, 0);
      // EXP 仍累加(数据无破坏)但不触发升层
      expect(ch.experience, 1000000);
      expect(ch.realmTier, RealmTier.wuSheng);
      expect(ch.realmLayer, RealmLayer.dengFeng);
      expect(ch.internalForceMax, 15000);
    });

    test('不动 attributes / 不回血 internalForce', () {
      final ch = _mkChar(
        experience: 0,
        experienceToNextLayer: 50,
        internalForce: 200,
        internalForceMax: 500,
      );
      final attrsBefore = ch.attributes;
      final ifBefore = ch.internalForce;

      CharacterAdvancementService.applyExperience(
        ch,
        100, // 升 1 层到 ruMen,max=600
        realmLookup: _lookup,
      );

      expect(ch.attributes, attrsBefore);
      expect(ch.internalForce, ifBefore, reason: '升层不回血,只升 cap');
      expect(ch.internalForceMax, 600);
    });
  });
}
