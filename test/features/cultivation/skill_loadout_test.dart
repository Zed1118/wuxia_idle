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
  });
}
