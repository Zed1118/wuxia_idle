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
}
