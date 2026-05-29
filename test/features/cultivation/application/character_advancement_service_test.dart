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

  // ===========================================================================
  // Batch 2.2.A R1:心魔 unlock hook 集成(1.0 P2.2 §12.1)
  // spec: docs/handoff/p2_x_inner_demon_spec_2026-05-22.md §三
  // ===========================================================================
  group('Batch 2.2.A R1 · isLayerLocked hook', () {
    test('R1.1 isLayerLocked=null(default)→ 行为同原 applyExperience', () {
      final ch = _mkChar(experienceToNextLayer: 50);
      final r = CharacterAdvancementService.applyExperience(
        ch,
        400, // 50+80+120 升到 jingTong,剩 150
        realmLookup: _lookup,
      );
      expect(r.layersGained, 3);
      expect(ch.realmLayer, RealmLayer.jingTong);
      expect(ch.experience, 150);
    });

    test('R1.2 hook 始终 true → 任何升层都被拦,EXP 不消费(GDD §5.1)', () {
      final ch = _mkChar(experienceToNextLayer: 50);
      final r = CharacterAdvancementService.applyExperience(
        ch,
        400,
        realmLookup: _lookup,
        isLayerLocked: (_, _) => true,
      );
      expect(r.layersGained, 0);
      expect(r.didAdvance, isFalse);
      expect(ch.realmLayer, RealmLayer.qiMeng);
      expect(ch.experience, 400, reason: 'EXP 留账,玩家挂机攒着等过关后消费');
      expect(ch.experienceToNextLayer, 50, reason: '阈值不动');
    });

    test('R1.3 hook 选择性拦:sanLiu·ruMen 拦 → 跨 tier 升后停', () {
      // 起 xueTu·dengFeng,跨 tier 升 sanLiu·qiMeng(不拦,模拟 wuSheng·qiMeng
      // 起步层),想再升 ruMen 被拦。注:生产 InnerDemonService 仅对 wuSheng tier
      // 工作,本 test 用 fixture 已配的 xueTu/sanLiu 验通用 hook integration。
      // xueTu.dengFeng exp_to_next=400 / sanLiu.qiMeng=500
      final ch = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.dengFeng,
        experienceToNextLayer: 400,
        internalForceMax: 1100,
      );
      final r = CharacterAdvancementService.applyExperience(
        ch,
        1500, // 升 2 层有余
        realmLookup: _lookup,
        isLayerLocked: (tier, layer) =>
            tier == RealmTier.sanLiu && layer == RealmLayer.ruMen,
      );
      // 应升 1 层(xueTu.dengFeng → sanLiu.qiMeng),不再升 ruMen
      expect(r.layersGained, 1);
      expect(ch.realmTier, RealmTier.sanLiu);
      expect(ch.realmLayer, RealmLayer.qiMeng);
      // EXP 剩 = 1500 - 400 = 1100(sanLiu.qiMeng EXP 留账)
      expect(ch.experience, 1100);
    });

    test('R1.4 hook 信任完全:即便拦跨 tier 起步层也确实拦', () {
      // hook 配置:对 (sanLiu, qiMeng) 跨 tier 起步层返 true — 验证 advancement
      // 完全信任 hook(不做"qiMeng 跨 tier 自动放行"的额外语义)。生产
      // InnerDemonService.isLayerLocked 自身 short-circuit qiMeng=false。
      final ch = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.dengFeng,
        experienceToNextLayer: 400,
        internalForceMax: 1100,
      );
      final r = CharacterAdvancementService.applyExperience(
        ch,
        1000,
        realmLookup: _lookup,
        isLayerLocked: (tier, layer) =>
            tier == RealmTier.sanLiu && layer == RealmLayer.qiMeng,
      );
      // hook 拦 → 0 升层,EXP 留账
      expect(r.layersGained, 0);
      expect(ch.experience, 1000);
      expect(ch.realmTier, RealmTier.xueTu);
      expect(ch.realmLayer, RealmLayer.dengFeng);
    });

    test('R1.5 hook 阶梯锁:升 3 层后卡(模拟通 3 关后停)', () {
      // 模拟玩家可升 ruMen/shuLian/jingTong,卡 yuanShu。起 sanLiu·qiMeng
      // EXP=0,给巨量 EXP。
      // sanLiu layer exp_to_next: qiMeng=500 / ruMen=700 / shuLian=950 /
      //                            jingTong=1250 / yuanShu=1600
      final ch = _mkChar(
        tier: RealmTier.sanLiu,
        layer: RealmLayer.qiMeng,
        experience: 0,
        experienceToNextLayer: 500,
        internalForceMax: 1200,
      );
      final r = CharacterAdvancementService.applyExperience(
        ch,
        10000,
        realmLookup: _lookup,
        isLayerLocked: (tier, layer) {
          if (tier != RealmTier.sanLiu) return false;
          const blocked = {
            RealmLayer.yuanShu,
            RealmLayer.huaJing,
            RealmLayer.dengFeng,
          };
          return blocked.contains(layer);
        },
      );
      // 升 3 层 ruMen / shuLian / jingTong,卡 yuanShu
      expect(r.layersGained, 3);
      expect(ch.realmLayer, RealmLayer.jingTong);
      // EXP 消费 = 500 + 700 + 950 = 2150,剩 7850 留账
      expect(ch.experience, 7850);
      expect(ch.experienceToNextLayer, 1250);
    });

    test('R1.6 拦截时 internalForceMax / experienceToNextLayer 不动', () {
      final ch = _mkChar(
        experience: 0,
        experienceToNextLayer: 50,
        internalForce: 100,
        internalForceMax: 500,
      );
      CharacterAdvancementService.applyExperience(
        ch,
        500,
        realmLookup: _lookup,
        isLayerLocked: (_, _) => true,
      );
      expect(ch.internalForce, 100, reason: '不回血');
      expect(ch.internalForceMax, 500, reason: '不动 cap');
      expect(ch.experienceToNextLayer, 50, reason: '阈值不动');
      expect(ch.realmTier, RealmTier.xueTu);
      expect(ch.realmLayer, RealmLayer.qiMeng);
    });
  });

  // H2 小套餐 C2:大境界突破(crossedTier)概念 — UI 据此走全屏庆祝,
  // 区别于普通小层升级(此前 7 次大突破与 42 次小升级共用同一小 banner)。
  group('crossedTier · 大境界突破判定', () {
    test('跨 tier(xueTu.dengFeng → sanLiu.qiMeng)→ crossedTier=true', () {
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
      expect(r.crossedTier, isTrue);
      expect(r.didAdvance, isTrue);
    });

    test('同 tier 内升层(qiMeng → ruMen)→ crossedTier=false', () {
      final ch = _mkChar(
        tier: RealmTier.xueTu,
        layer: RealmLayer.qiMeng,
        experienceToNextLayer: 50,
      );
      final r = CharacterAdvancementService.applyExperience(
        ch,
        50,
        realmLookup: _lookup,
      );
      expect(r.layersGained, greaterThan(0));
      expect(r.tierAfter, RealmTier.xueTu);
      expect(r.crossedTier, isFalse, reason: '同境界内小层升级不算大突破');
    });

    test('未升层(delta=0)→ crossedTier=false', () {
      final ch = _mkChar(tier: RealmTier.xueTu, layer: RealmLayer.qiMeng);
      final r = CharacterAdvancementService.applyExperience(
        ch,
        0,
        realmLookup: _lookup,
      );
      expect(r.didAdvance, isFalse);
      expect(r.crossedTier, isFalse);
    });
  });
}
