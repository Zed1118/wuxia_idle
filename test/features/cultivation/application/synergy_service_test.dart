import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/synergy_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/features/cultivation/application/synergy_service.dart';

/// W18-A1 · SynergyService.detectActive 单元测试。
///
/// 覆盖:5 组合各命中场景 + 优先级 schoolPair > sameSchool > sameTier +
/// null 兜底(无 main / 无 assist / 找不到 tech / 找不到 def)。
void main() {
  // ── fixtures ─────────────────────────────────────────────────────────────

  const synergies = [
    // schoolPair × 3
    SynergyDef(
      id: 'synergy_yin_yang_he_xie',
      name: '阴阳调和',
      description: '',
      requirementType: SynergyRequirementType.schoolPair,
      mainSchool: TechniqueSchool.gangMeng,
      assistSchool: TechniqueSchool.yinRou,
      multipliers: SynergyMultipliers(attackPct: 0.10),
    ),
    SynergyDef(
      id: 'synergy_gang_rou_bing_ji',
      name: '刚柔并济',
      description: '',
      requirementType: SynergyRequirementType.schoolPair,
      mainSchool: TechniqueSchool.gangMeng,
      assistSchool: TechniqueSchool.lingQiao,
      multipliers: SynergyMultipliers(speedPct: 0.25),
    ),
    SynergyDef(
      id: 'synergy_yin_ying_xun_jie',
      name: '阴影迅捷',
      description: '',
      requirementType: SynergyRequirementType.schoolPair,
      mainSchool: TechniqueSchool.yinRou,
      assistSchool: TechniqueSchool.lingQiao,
      multipliers: SynergyMultipliers(attackPct: 0.15, speedPct: 0.15),
    ),
    // sameSchool
    SynergyDef(
      id: 'synergy_tong_pai_jing_jin',
      name: '同流派精进',
      description: '',
      requirementType: SynergyRequirementType.sameSchool,
      multipliers: SynergyMultipliers(attackPct: 0.20),
    ),
    // sameTier
    SynergyDef(
      id: 'synergy_tong_bei_hu_bu',
      name: '同辈互补',
      description: '',
      requirementType: SynergyRequirementType.sameTier,
      multipliers: SynergyMultipliers(internalForceMaxPct: 0.25),
    ),
  ];

  TechniqueDef mkTechDef({
    required String id,
    required TechniqueTier tier,
    required TechniqueSchool school,
  }) =>
      TechniqueDef(
        id: id,
        name: id,
        tier: tier,
        school: school,
        description: '',
        skillIds: const [],
        internalForceGrowthBonus: 1.0,
        speedBonus: 0,
        acquireSourceTags: const [],
      );

  Technique mkTech({
    required int id,
    required String defId,
    required TechniqueTier tier,
    required TechniqueSchool school,
    TechniqueRole role = TechniqueRole.main,
  }) {
    final t = Technique.create(
      defId: defId,
      ownerCharacterId: 1,
      tier: tier,
      school: school,
      role: role,
      learnedAt: DateTime(2026),
    );
    t.id = id;
    return t;
  }

  Character mkChar({
    int? mainTechId,
    List<int>? assistIds,
  }) =>
      Character.create(
        name: '测试',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.disciple,
        createdAt: DateTime(2026),
        mainTechniqueId: mainTechId,
        assistTechniqueIds: assistIds,
      );

  TechniqueDef? Function(String) lookupOf(Map<String, TechniqueDef> defs) =>
      (defId) => defs[defId];

  // ── tests ────────────────────────────────────────────────────────────────

  group('5 组合命中', () {
    test('阴阳调和:gangMeng 主 + yinRou 辅', () {
      final defs = {
        'tech_a': mkTechDef(
            id: 'tech_a',
            tier: TechniqueTier.ruMenGong,
            school: TechniqueSchool.gangMeng),
        'tech_b': mkTechDef(
            id: 'tech_b',
            tier: TechniqueTier.changLianGong,
            school: TechniqueSchool.yinRou),
      };
      final result = SynergyService.detectActive(
        character: mkChar(mainTechId: 1, assistIds: [2]),
        ownedTechniques: [
          mkTech(
              id: 1,
              defId: 'tech_a',
              tier: TechniqueTier.ruMenGong,
              school: TechniqueSchool.gangMeng),
          mkTech(
              id: 2,
              defId: 'tech_b',
              tier: TechniqueTier.changLianGong,
              school: TechniqueSchool.yinRou,
              role: TechniqueRole.assist),
        ],
        techDefLookup: lookupOf(defs),
        synergies: synergies,
      );
      expect(result?.id, equals('synergy_yin_yang_he_xie'));
    });

    test('刚柔并济:gangMeng 主 + lingQiao 辅', () {
      final defs = {
        'a': mkTechDef(
            id: 'a',
            tier: TechniqueTier.ruMenGong,
            school: TechniqueSchool.gangMeng),
        'b': mkTechDef(
            id: 'b',
            tier: TechniqueTier.changLianGong,
            school: TechniqueSchool.lingQiao),
      };
      final result = SynergyService.detectActive(
        character: mkChar(mainTechId: 1, assistIds: [2]),
        ownedTechniques: [
          mkTech(
              id: 1,
              defId: 'a',
              tier: TechniqueTier.ruMenGong,
              school: TechniqueSchool.gangMeng),
          mkTech(
              id: 2,
              defId: 'b',
              tier: TechniqueTier.changLianGong,
              school: TechniqueSchool.lingQiao),
        ],
        techDefLookup: lookupOf(defs),
        synergies: synergies,
      );
      expect(result?.id, equals('synergy_gang_rou_bing_ji'));
    });

    test('阴影迅捷:yinRou 主 + lingQiao 辅', () {
      final defs = {
        'a': mkTechDef(
            id: 'a',
            tier: TechniqueTier.ruMenGong,
            school: TechniqueSchool.yinRou),
        'b': mkTechDef(
            id: 'b',
            tier: TechniqueTier.ruMenGong,
            school: TechniqueSchool.lingQiao),
      };
      final result = SynergyService.detectActive(
        character: mkChar(mainTechId: 1, assistIds: [2]),
        ownedTechniques: [
          mkTech(
              id: 1,
              defId: 'a',
              tier: TechniqueTier.ruMenGong,
              school: TechniqueSchool.yinRou),
          mkTech(
              id: 2,
              defId: 'b',
              tier: TechniqueTier.ruMenGong,
              school: TechniqueSchool.lingQiao),
        ],
        techDefLookup: lookupOf(defs),
        synergies: synergies,
      );
      expect(result?.id, equals('synergy_yin_ying_xun_jie'));
    });

    test('同流派精进:主辅同 yinRou + tier 不同 → 命中(优先 sameSchool)', () {
      final defs = {
        'a': mkTechDef(
            id: 'a',
            tier: TechniqueTier.ruMenGong,
            school: TechniqueSchool.yinRou),
        'b': mkTechDef(
            id: 'b',
            tier: TechniqueTier.changLianGong,
            school: TechniqueSchool.yinRou),
      };
      final result = SynergyService.detectActive(
        character: mkChar(mainTechId: 1, assistIds: [2]),
        ownedTechniques: [
          mkTech(
              id: 1,
              defId: 'a',
              tier: TechniqueTier.ruMenGong,
              school: TechniqueSchool.yinRou),
          mkTech(
              id: 2,
              defId: 'b',
              tier: TechniqueTier.changLianGong,
              school: TechniqueSchool.yinRou),
        ],
        techDefLookup: lookupOf(defs),
        synergies: synergies,
      );
      expect(result?.id, equals('synergy_tong_pai_jing_jin'));
    });

    test('同辈互补:gangMeng + lingQiao 但 tier 相同 → 命中 schoolPair(优先级靠前)', () {
      // 主 gangMeng + 辅 lingQiao,两者都 ruMenGong → 同时满足 schoolPair
      // (刚柔并济)与 sameTier(同辈互补)。schoolPair 优先级更高 → 命中刚柔并济
      final defs = {
        'a': mkTechDef(
            id: 'a',
            tier: TechniqueTier.ruMenGong,
            school: TechniqueSchool.gangMeng),
        'b': mkTechDef(
            id: 'b',
            tier: TechniqueTier.ruMenGong,
            school: TechniqueSchool.lingQiao),
      };
      final result = SynergyService.detectActive(
        character: mkChar(mainTechId: 1, assistIds: [2]),
        ownedTechniques: [
          mkTech(
              id: 1,
              defId: 'a',
              tier: TechniqueTier.ruMenGong,
              school: TechniqueSchool.gangMeng),
          mkTech(
              id: 2,
              defId: 'b',
              tier: TechniqueTier.ruMenGong,
              school: TechniqueSchool.lingQiao),
        ],
        techDefLookup: lookupOf(defs),
        synergies: synergies,
      );
      expect(result?.id, equals('synergy_gang_rou_bing_ji'),
          reason: 'schoolPair 优先级高于 sameTier');
    });

    test('同辈互补:lingQiao 主 + gangMeng 辅(没 schoolPair lingQiao→gangMeng) tier 同 → sameTier 命中',
        () {
      // schoolPair 中无 (lingQiao, gangMeng) 配置,且 sameSchool 需同流派(不符);
      // 但 tier 相同 → sameTier 命中
      final defs = {
        'a': mkTechDef(
            id: 'a',
            tier: TechniqueTier.menPaiJueXue,
            school: TechniqueSchool.lingQiao),
        'b': mkTechDef(
            id: 'b',
            tier: TechniqueTier.menPaiJueXue,
            school: TechniqueSchool.gangMeng),
      };
      final result = SynergyService.detectActive(
        character: mkChar(mainTechId: 1, assistIds: [2]),
        ownedTechniques: [
          mkTech(
              id: 1,
              defId: 'a',
              tier: TechniqueTier.menPaiJueXue,
              school: TechniqueSchool.lingQiao),
          mkTech(
              id: 2,
              defId: 'b',
              tier: TechniqueTier.menPaiJueXue,
              school: TechniqueSchool.gangMeng),
        ],
        techDefLookup: lookupOf(defs),
        synergies: synergies,
      );
      expect(result?.id, equals('synergy_tong_bei_hu_bu'));
    });
  });

  group('null 兜底', () {
    test('mainTechniqueId 为 null → null', () {
      expect(
        SynergyService.detectActive(
          character: mkChar(mainTechId: null, assistIds: [2]),
          ownedTechniques: const [],
          techDefLookup: (_) => null,
          synergies: synergies,
        ),
        isNull,
      );
    });

    test('assistTechniqueIds 为空 → null', () {
      expect(
        SynergyService.detectActive(
          character: mkChar(mainTechId: 1, assistIds: const []),
          ownedTechniques: const [],
          techDefLookup: (_) => null,
          synergies: synergies,
        ),
        isNull,
      );
    });

    test('ownedTechniques 找不到 mainTech → null', () {
      expect(
        SynergyService.detectActive(
          character: mkChar(mainTechId: 999, assistIds: [2]),
          ownedTechniques: [
            mkTech(
                id: 2,
                defId: 'b',
                tier: TechniqueTier.ruMenGong,
                school: TechniqueSchool.gangMeng),
          ],
          techDefLookup: (_) => null,
          synergies: synergies,
        ),
        isNull,
      );
    });

    test('techDefLookup 返 null → null', () {
      expect(
        SynergyService.detectActive(
          character: mkChar(mainTechId: 1, assistIds: [2]),
          ownedTechniques: [
            mkTech(
                id: 1,
                defId: 'a',
                tier: TechniqueTier.ruMenGong,
                school: TechniqueSchool.gangMeng),
            mkTech(
                id: 2,
                defId: 'b',
                tier: TechniqueTier.ruMenGong,
                school: TechniqueSchool.yinRou),
          ],
          techDefLookup: (_) => null,
          synergies: synergies,
        ),
        isNull,
      );
    });

    test('synergies 为空 list → null', () {
      expect(
        SynergyService.detectActive(
          character: mkChar(mainTechId: 1, assistIds: [2]),
          ownedTechniques: const [],
          techDefLookup: (_) => null,
          synergies: const [],
        ),
        isNull,
      );
    });

    test('schoolPair 无任何命中 + sameSchool/sameTier 也不命中 → null', () {
      // gangMeng tier1 主 + lingQiao tier3 辅:
      // schoolPair gangMeng→lingQiao 存在 → 命中刚柔并济
      // 我们用一个相反配置:lingQiao 主 + yinRou 辅,schoolPair 列表无
      // (lingQiao→yinRou),sameSchool 不符,tier 不同 → null
      final defs = {
        'a': mkTechDef(
            id: 'a',
            tier: TechniqueTier.ruMenGong,
            school: TechniqueSchool.lingQiao),
        'b': mkTechDef(
            id: 'b',
            tier: TechniqueTier.changLianGong,
            school: TechniqueSchool.yinRou),
      };
      final result = SynergyService.detectActive(
        character: mkChar(mainTechId: 1, assistIds: [2]),
        ownedTechniques: [
          mkTech(
              id: 1,
              defId: 'a',
              tier: TechniqueTier.ruMenGong,
              school: TechniqueSchool.lingQiao),
          mkTech(
              id: 2,
              defId: 'b',
              tier: TechniqueTier.changLianGong,
              school: TechniqueSchool.yinRou),
        ],
        techDefLookup: lookupOf(defs),
        synergies: synergies,
      );
      expect(result, isNull);
    });
  });
}
