import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/synergy_def.dart';

/// W18-A1 · SynergyDef.matches() + SynergyMultipliers 单元测试。
void main() {
  group('SynergyMultipliers', () {
    test('summary 跳过零值字段', () {
      const m = SynergyMultipliers(attackPct: 0.10, speedPct: 0.20);
      expect(m.summary(), equals('攻 +10% · 速 +20%'));
    });

    test('summary 全零字段返空 String', () {
      const m = SynergyMultipliers();
      expect(m.summary(), equals(''));
    });

    test('isWithinRedLine:各项 ≤ 0.30 通过', () {
      const m = SynergyMultipliers(
        attackPct: 0.30,
        defensePct: 0.30,
        speedPct: 0.30,
        hpPct: 0.30,
        internalForceMaxPct: 0.30,
        internalForceGrowthPct: 0.30,
      );
      expect(m.isWithinRedLine, isTrue);
    });

    test('isWithinRedLine:任意项 > 0.30 失败', () {
      const m = SynergyMultipliers(attackPct: 0.31);
      expect(m.isWithinRedLine, isFalse);
    });

    test('isWithinRedLine:负值失败', () {
      const m = SynergyMultipliers(attackPct: -0.10);
      expect(m.isWithinRedLine, isFalse);
    });

    test('fromYaml 缺省全 0', () {
      final m = SynergyMultipliers.fromYaml(null);
      expect(m.attackPct, equals(0));
      expect(m.hpPct, equals(0));
    });

    test('fromYaml 解析所有字段', () {
      final m = SynergyMultipliers.fromYaml({
        'attackPct': 0.10,
        'speedPct': 0.25,
        'internalForceMaxPct': 0.25,
      });
      expect(m.attackPct, equals(0.10));
      expect(m.speedPct, equals(0.25));
      expect(m.internalForceMaxPct, equals(0.25));
      expect(m.defensePct, equals(0));
    });
  });

  group('SynergyDef.matches', () {
    const schoolPairGangYin = SynergyDef(
      id: 'synergy_test_pair',
      name: '阴阳调和',
      description: '',
      requirementType: SynergyRequirementType.schoolPair,
      mainSchool: TechniqueSchool.gangMeng,
      assistSchool: TechniqueSchool.yinRou,
      multipliers: SynergyMultipliers(attackPct: 0.10),
    );

    const sameSchool = SynergyDef(
      id: 'synergy_test_same_school',
      name: '同流派精进',
      description: '',
      requirementType: SynergyRequirementType.sameSchool,
      multipliers: SynergyMultipliers(attackPct: 0.20),
    );

    const sameTier = SynergyDef(
      id: 'synergy_test_same_tier',
      name: '同辈互补',
      description: '',
      requirementType: SynergyRequirementType.sameTier,
      multipliers: SynergyMultipliers(internalForceMaxPct: 0.25),
    );

    test('schoolPair 严格匹配:gangMeng+yinRou → 命中', () {
      expect(
        schoolPairGangYin.matches(
          mainSchool: TechniqueSchool.gangMeng,
          assistSchool: TechniqueSchool.yinRou,
          mainTier: TechniqueTier.ruMenGong,
          assistTier: TechniqueTier.changLianGong,
        ),
        isTrue,
      );
    });

    test('schoolPair 严格匹配:顺序倒(yinRou+gangMeng) → 不命中', () {
      expect(
        schoolPairGangYin.matches(
          mainSchool: TechniqueSchool.yinRou,
          assistSchool: TechniqueSchool.gangMeng,
          mainTier: TechniqueTier.ruMenGong,
          assistTier: TechniqueTier.ruMenGong,
        ),
        isFalse,
      );
    });

    test('schoolPair:其他流派组合不命中', () {
      expect(
        schoolPairGangYin.matches(
          mainSchool: TechniqueSchool.gangMeng,
          assistSchool: TechniqueSchool.lingQiao,
          mainTier: TechniqueTier.ruMenGong,
          assistTier: TechniqueTier.ruMenGong,
        ),
        isFalse,
      );
    });

    test('sameSchool 命中:main+assist 同流派,tier 任意', () {
      expect(
        sameSchool.matches(
          mainSchool: TechniqueSchool.lingQiao,
          assistSchool: TechniqueSchool.lingQiao,
          mainTier: TechniqueTier.ruMenGong,
          assistTier: TechniqueTier.chuanShuoShenGong,
        ),
        isTrue,
      );
    });

    test('sameSchool 不命中:不同流派', () {
      expect(
        sameSchool.matches(
          mainSchool: TechniqueSchool.gangMeng,
          assistSchool: TechniqueSchool.yinRou,
          mainTier: TechniqueTier.ruMenGong,
          assistTier: TechniqueTier.ruMenGong,
        ),
        isFalse,
      );
    });

    test('sameTier 命中:tier 相同,流派任意', () {
      expect(
        sameTier.matches(
          mainSchool: TechniqueSchool.gangMeng,
          assistSchool: TechniqueSchool.yinRou,
          mainTier: TechniqueTier.menPaiJueXue,
          assistTier: TechniqueTier.menPaiJueXue,
        ),
        isTrue,
      );
    });

    test('sameTier 不命中:tier 不同', () {
      expect(
        sameTier.matches(
          mainSchool: TechniqueSchool.gangMeng,
          assistSchool: TechniqueSchool.gangMeng,
          mainTier: TechniqueTier.ruMenGong,
          assistTier: TechniqueTier.changLianGong,
        ),
        isFalse,
      );
    });
  });

  group('SynergyDef.fromYaml', () {
    test('schoolPair 类型完整字段', () {
      final s = SynergyDef.fromYaml({
        'id': 'synergy_yin_yang_he_xie',
        'name': '阴阳调和',
        'description': '刚阳与阴柔相济',
        'requirement': {
          'type': 'schoolPair',
          'mainSchool': 'gangMeng',
          'assistSchool': 'yinRou',
        },
        'multipliers': {
          'attackPct': 0.10,
          'hpPct': 0.10,
        },
      });
      expect(s.id, equals('synergy_yin_yang_he_xie'));
      expect(s.requirementType, equals(SynergyRequirementType.schoolPair));
      expect(s.mainSchool, equals(TechniqueSchool.gangMeng));
      expect(s.assistSchool, equals(TechniqueSchool.yinRou));
      expect(s.multipliers.attackPct, equals(0.10));
      expect(s.multipliers.hpPct, equals(0.10));
    });

    test('sameTier 类型可省 mainSchool/assistSchool', () {
      final s = SynergyDef.fromYaml({
        'id': 'synergy_tong_bei',
        'name': '同辈互补',
        'description': '',
        'requirement': {'type': 'sameTier'},
        'multipliers': {'internalForceMaxPct': 0.25},
      });
      expect(s.requirementType, equals(SynergyRequirementType.sameTier));
      expect(s.mainSchool, isNull);
      expect(s.assistSchool, isNull);
    });

    test('缺 requirement 抛 StateError', () {
      expect(
        () => SynergyDef.fromYaml({
          'id': 'synergy_bad',
          'name': '坏',
          'description': '',
          'multipliers': {},
        }),
        throwsStateError,
      );
    });
  });
}
