import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_loadout.dart';

SkillDef _skill(String id, {int power = 500, int? tier}) => SkillDef(
      id: id,
      name: id,
      description: '',
      type: SkillType.powerSkill,
      powerMultiplier: power,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      parentTechniqueDefId: tier == null ? 'tech_a' : null,
      visualEffect: '',
      tier: tier,
      narrativeInsightId: null,
      imagePath: null,
      canInterrupt: false,
      aiUsePolicy: AiUsePolicy.normal,
      proficiency: null,
    );

void main() {
  group('SkillLoadout.autoFill', () {
    test('空槽：主修招按 power 降序填 main1/main2，大招进 ultimate', () {
      final main = [
        _skill('a', power: 800),
        _skill('ult', power: 6000),
        _skill('b', power: 1200),
      ];
      final r = SkillLoadout.autoFill(
        mainTechniqueSkills: main,
        assistTechniqueSkills: const [],
        jointSkill: null,
        realmTier: RealmTier.yiLiu,
        existing: const SkillLoadout(),
        ultimatePowerThreshold: 5000,
      );
      expect(r.ultimateSkillId, 'ult');
      expect(r.mainSkillId1, 'b');
      expect(r.mainSkillId2, 'a');
    });
    test('境界 gate：高 tier 招不填', () {
      final assist = [_skill('hi', tier: 7)];
      final r = SkillLoadout.autoFill(
        mainTechniqueSkills: const [],
        assistTechniqueSkills: assist,
        jointSkill: null,
        realmTier: RealmTier.xueTu,
        existing: const SkillLoadout(),
        ultimatePowerThreshold: 5000,
      );
      expect(r.assistSkillId, isNull);
    });
    test('非空槽不被覆盖', () {
      final main = [_skill('a', power: 800)];
      final r = SkillLoadout.autoFill(
        mainTechniqueSkills: main,
        assistTechniqueSkills: const [],
        jointSkill: null,
        realmTier: RealmTier.yiLiu,
        existing: const SkillLoadout(mainSkillId1: 'keep'),
        ultimatePowerThreshold: 5000,
      );
      expect(r.mainSkillId1, 'keep');
      expect(r.mainSkillId2, 'a');
    });
    test('joint null → resonance 空', () {
      final r = SkillLoadout.autoFill(
        mainTechniqueSkills: const [],
        assistTechniqueSkills: const [],
        jointSkill: null,
        realmTier: RealmTier.yiLiu,
        existing: const SkillLoadout(),
        ultimatePowerThreshold: 5000,
      );
      expect(r.resonanceSkillId, isNull);
    });

    group('破招槽(波A build gate)', () {
      final interrupts = [
        _interrupt('po_shi', TechniqueSchool.gangMeng),
        _interrupt('jie_ying', TechniqueSchool.lingQiao),
      ];

      test('school 匹配 → 自动填本流派破招技', () {
        final r = SkillLoadout.autoFill(
          mainTechniqueSkills: const [],
          assistTechniqueSkills: const [],
          jointSkill: null,
          realmTier: RealmTier.xueTu,
          existing: const SkillLoadout(),
          ultimatePowerThreshold: 5000,
          interruptSkills: interrupts,
          school: TechniqueSchool.lingQiao,
        );
        expect(r.keySkillId, 'jie_ying');
      });

      test('school null → 不填破招槽', () {
        final r = SkillLoadout.autoFill(
          mainTechniqueSkills: const [],
          assistTechniqueSkills: const [],
          jointSkill: null,
          realmTier: RealmTier.xueTu,
          existing: const SkillLoadout(),
          ultimatePowerThreshold: 5000,
          interruptSkills: interrupts,
        );
        expect(r.keySkillId, isNull);
      });

      test('非空破招槽不被覆盖', () {
        final r = SkillLoadout.autoFill(
          mainTechniqueSkills: const [],
          assistTechniqueSkills: const [],
          jointSkill: null,
          realmTier: RealmTier.xueTu,
          existing: const SkillLoadout(keySkillId: 'keep_key'),
          ultimatePowerThreshold: 5000,
          interruptSkills: interrupts,
          school: TechniqueSchool.gangMeng,
        );
        expect(r.keySkillId, 'keep_key');
      });
    });
  });
}

SkillDef _interrupt(String id, TechniqueSchool style) => SkillDef(
      id: id,
      name: id,
      description: '',
      type: SkillType.powerSkill,
      powerMultiplier: 800,
      internalForceCost: 100,
      cooldownTurns: 3,
      requiresManualTrigger: false,
      visualEffect: '',
      canInterrupt: true,
      aiUsePolicy: AiUsePolicy.saveForInterrupt,
      style: style,
    );
