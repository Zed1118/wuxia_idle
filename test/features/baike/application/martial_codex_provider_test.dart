import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/features/baike/application/martial_codex_provider.dart';

class _FakeTechDef {
  _FakeTechDef({
    required this.name,
    required this.tier,
    required this.school,
    required this.skillIds,
  });
  final String name;
  final TechniqueTier tier;
  final TechniqueSchool school;
  final List<String> skillIds;
}

SkillDef _skill(
  String id,
  SkillSource? source, {
  bool canInterrupt = false,
  TechniqueSchool? style,
}) => SkillDef(
  id: id,
  name: id,
  description: 'd',
  type: SkillType.powerSkill,
  powerMultiplier: 1000,
  internalForceCost: 10,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: 'none',
  source: source,
  canInterrupt: canInterrupt,
  style: style,
);

TechniqueDef _tech(
  String id,
  TechniqueTier tier,
  TechniqueSchool school,
  List<String> skillIds, {
  List<String> acquireSourceTags = const ['starter'],
}) => TechniqueDef(
  id: id,
  name: id,
  tier: tier,
  school: school,
  description: 'd',
  skillIds: skillIds,
  internalForceGrowthBonus: 1,
  speedBonus: 0,
  acquireSourceTags: acquireSourceTags,
);

void main() {
  group('isMartialCodexSkill', () {
    test('心法/真解/残页/奇遇收录', () {
      expect(isMartialCodexSkill(_skill('a', SkillSource.technique)), isTrue);
      expect(
        isMartialCodexSkill(_skill('b', SkillSource.mainlineDrop)),
        isTrue,
      );
      expect(isMartialCodexSkill(_skill('c', SkillSource.fragment)), isTrue);
      expect(isMartialCodexSkill(_skill('d', SkillSource.encounter)), isTrue);
    });
    test('破招(special∩canInterrupt)收录,轻功/joint(special非破招)不收', () {
      expect(
        isMartialCodexSkill(
          _skill('po', SkillSource.special, canInterrupt: true),
        ),
        isTrue,
      );
      expect(isMartialCodexSkill(_skill('lf', SkillSource.special)), isFalse);
    });
    test('source==null 不收', () {
      expect(isMartialCodexSkill(_skill('x', null)), isFalse);
    });
  });

  group('martialSourceKindOf', () {
    test('破招优先于 special 兜底', () {
      expect(
        martialSourceKindOf(
          _skill('po', SkillSource.special, canInterrupt: true),
        ),
        MartialGroupKind.interrupt,
      );
    });
    test('5 类映射', () {
      expect(
        martialSourceKindOf(_skill('a', SkillSource.technique)),
        MartialGroupKind.heartArt,
      );
      expect(
        martialSourceKindOf(_skill('b', SkillSource.mainlineDrop)),
        MartialGroupKind.trueSolution,
      );
      expect(
        martialSourceKindOf(_skill('c', SkillSource.fragment)),
        MartialGroupKind.fragment,
      );
      expect(
        martialSourceKindOf(_skill('d', SkillSource.encounter)),
        MartialGroupKind.encounter,
      );
    });
  });

  group('litSkillIds 三套口径', () {
    final pool = [
      _skill('ha', SkillSource.technique), // 心法招
      _skill('rare', SkillSource.mainlineDrop), // 稀有招
      _skill('enc', SkillSource.encounter), // 稀有招
      _skill(
        'po',
        SkillSource.special,
        canInterrupt: true,
        style: TechniqueSchool.gangMeng,
      ), // 破招·刚猛
    ];
    test('心法招走 learned 集', () {
      final lit = litSkillIds(
        pool: pool,
        unlockedIds: const {},
        learnedHeartArtSkillIds: const {'ha'},
        activeSchools: const {},
      );
      expect(lit, contains('ha'));
      expect(lit, isNot(contains('rare')));
    });
    test('稀有招走 unlockedIds', () {
      final lit = litSkillIds(
        pool: pool,
        unlockedIds: const {'rare', 'enc'},
        learnedHeartArtSkillIds: const {},
        activeSchools: const {},
      );
      expect(lit, containsAll(['rare', 'enc']));
      expect(lit, isNot(contains('po')));
    });
    test('破招走 activeSchools 含该 style', () {
      final lit = litSkillIds(
        pool: pool,
        unlockedIds: const {},
        learnedHeartArtSkillIds: const {},
        activeSchools: const {TechniqueSchool.gangMeng},
      );
      expect(lit, contains('po'));
    });
    test('破招 style 不在 activeSchools 则不点亮', () {
      final lit = litSkillIds(
        pool: pool,
        unlockedIds: const {},
        learnedHeartArtSkillIds: const {},
        activeSchools: const {TechniqueSchool.yinRou},
      );
      expect(lit, isNot(contains('po')));
    });
  });

  group('groupMartialSkills', () {
    test('空段不产出 + 计数 + 剪影 maxStage 为 null', () {
      final pool = [
        _skill('rare1', SkillSource.mainlineDrop),
        _skill('rare2', SkillSource.mainlineDrop),
        _skill('enc1', SkillSource.encounter),
      ];
      final groups = groupMartialSkills(
        pool: pool,
        litIds: const {'rare1'},
        stageById: const {},
        techDefsById: const {},
      );
      expect(
        groups.map((g) => g.kind),
        containsAll([
          MartialGroupKind.trueSolution,
          MartialGroupKind.encounter,
        ]),
      );
      expect(groups.any((g) => g.kind == MartialGroupKind.fragment), isFalse);
      final trueSol = groups.firstWhere(
        (g) => g.kind == MartialGroupKind.trueSolution,
      );
      expect(trueSol.litCount, 1);
      expect(trueSol.totalCount, 2);
      final allEntries = trueSol.subGroups.expand((s) => s.entries).toList();
      expect(allEntries.firstWhere((e) => e.def.id == 'rare2').isLit, isFalse);
    });

    test('组顺序固定:心法→真解→残页→破招→奇遇', () {
      final pool = [
        _skill('enc', SkillSource.encounter),
        _skill('po', SkillSource.special, canInterrupt: true),
        _skill('rare', SkillSource.mainlineDrop),
      ];
      final groups = groupMartialSkills(
        pool: pool,
        litIds: const {},
        stageById: const {},
        techDefsById: const {},
      );
      expect(groups.map((g) => g.kind).toList(), [
        MartialGroupKind.trueSolution,
        MartialGroupKind.interrupt,
        MartialGroupKind.encounter,
      ]);
    });

    test('心法绝学按所属心法分小节,标题含心法名/tier/流派', () {
      final pool = [
        _skill('s1', SkillSource.technique),
        _skill('s2', SkillSource.technique),
      ];
      final fake = _FakeTechDef(
        name: '太祖长拳',
        tier: TechniqueTier.ruMenGong,
        school: TechniqueSchool.gangMeng,
        skillIds: const ['s1', 's2'],
      );
      final groups = groupMartialSkills(
        pool: pool,
        litIds: const {'s1'},
        stageById: const {},
        techDefsById: {'t1': fake},
      );
      final heart = groups.firstWhere(
        (g) => g.kind == MartialGroupKind.heartArt,
      );
      expect(heart.subGroups.first.label, contains('太祖长拳'));
      expect(heart.subGroups.first.entries.length, 2);
      expect(heart.litCount, 1); // s1 点亮,s2 剪影
    });
  });

  group('technique codex', () {
    test('心法品阶映射到同序境界要求', () {
      expect(
        requiredRealmForTechniqueTier(TechniqueTier.ruMenGong),
        RealmTier.xueTu,
      );
      expect(
        requiredRealmForTechniqueTier(TechniqueTier.mingJiaGong),
        RealmTier.erLiu,
      );
      expect(
        requiredRealmForTechniqueTier(TechniqueTier.chuanShuoShenGong),
        RealmTier.wuSheng,
      );
    });

    test('从 TechniqueDef + SkillDef 构建条目,带对应招式与修炼境界', () {
      final skills = {
        's1': _skill('s1', SkillSource.technique),
        's2': _skill('s2', SkillSource.technique),
      };
      final entries = buildTechniqueCodexEntries(
        techniques: [
          _tech('t2', TechniqueTier.changLianGong, TechniqueSchool.yinRou, [
            's2',
          ]),
          _tech('t1', TechniqueTier.ruMenGong, TechniqueSchool.gangMeng, [
            's1',
            'missing',
          ]),
        ],
        skillDefsById: skills,
      );
      expect(entries.map((e) => e.def.id), ['t1', 't2']);
      expect(entries.first.requiredRealmTier, RealmTier.xueTu);
      expect(entries.first.skills.map((s) => s.id), ['s1']);
    });

    test('按心法品阶分组并支持筛选', () {
      final entries = buildTechniqueCodexEntries(
        techniques: [
          _tech('basic', TechniqueTier.ruMenGong, TechniqueSchool.gangMeng, []),
          _tech(
            'secret',
            TechniqueTier.jiangHuMiChuan,
            TechniqueSchool.lingQiao,
            [],
          ),
        ],
        skillDefsById: const {},
      );
      final all = groupTechniqueCodex(entries: entries);
      expect(all.map((g) => g.tier), [
        TechniqueTier.ruMenGong,
        TechniqueTier.jiangHuMiChuan,
      ]);

      final filtered = groupTechniqueCodex(
        entries: entries,
        tierFilter: TechniqueTier.jiangHuMiChuan,
      );
      expect(filtered, hasLength(1));
      expect(filtered.single.entries.single.def.id, 'secret');
    });
  });
}
