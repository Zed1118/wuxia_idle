import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/baike/application/martial_codex_provider.dart';

SkillDef _skill(String id, SkillSource? source,
        {bool canInterrupt = false, TechniqueSchool? style}) =>
    SkillDef(
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

void main() {
  group('isMartialCodexSkill', () {
    test('心法/真解/残页/奇遇收录', () {
      expect(isMartialCodexSkill(_skill('a', SkillSource.technique)), isTrue);
      expect(isMartialCodexSkill(_skill('b', SkillSource.mainlineDrop)), isTrue);
      expect(isMartialCodexSkill(_skill('c', SkillSource.fragment)), isTrue);
      expect(isMartialCodexSkill(_skill('d', SkillSource.encounter)), isTrue);
    });
    test('破招(special∩canInterrupt)收录,轻功/joint(special非破招)不收', () {
      expect(
          isMartialCodexSkill(
              _skill('po', SkillSource.special, canInterrupt: true)),
          isTrue);
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
              _skill('po', SkillSource.special, canInterrupt: true)),
          MartialGroupKind.interrupt);
    });
    test('5 类映射', () {
      expect(martialSourceKindOf(_skill('a', SkillSource.technique)),
          MartialGroupKind.heartArt);
      expect(martialSourceKindOf(_skill('b', SkillSource.mainlineDrop)),
          MartialGroupKind.trueSolution);
      expect(martialSourceKindOf(_skill('c', SkillSource.fragment)),
          MartialGroupKind.fragment);
      expect(martialSourceKindOf(_skill('d', SkillSource.encounter)),
          MartialGroupKind.encounter);
    });
  });

  group('litSkillIds 三套口径', () {
    final pool = [
      _skill('ha', SkillSource.technique),           // 心法招
      _skill('rare', SkillSource.mainlineDrop),      // 稀有招
      _skill('enc', SkillSource.encounter),          // 稀有招
      _skill('po', SkillSource.special,
          canInterrupt: true, style: TechniqueSchool.gangMeng), // 破招·刚猛
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
}
