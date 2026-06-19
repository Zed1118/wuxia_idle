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

    group('破防倾向 — 职责软引导(lineage tendency)', () {
      // 候选：一个高 power 普通技(800) + 一个低 power 破防技(400, defenseBreakPct>0)。
      // 纯 power 降序会选 [high_power, break_skill]（恰好都进，但 break_skill power 低于 high_power）。
      // 若 power 更低，则不会自然排在 m1；这里用一个第三个高 power 普通技把 break_skill 挤出前两名。
      final highA = _skill('high_a', power: 900);
      final highB = _skill('high_b', power: 800);
      const breakSkill = SkillDef(
        id: 'break_skill',
        name: 'break_skill',
        description: '',
        type: SkillType.powerSkill,
        powerMultiplier: 400,
        internalForceCost: 0,
        cooldownTurns: 0,
        requiresManualTrigger: false,
        visualEffect: '',
        canInterrupt: false,
        aiUsePolicy: AiUsePolicy.normal,
        defenseBreakPct: 0.20,
      );
      // 纯 power 降序：[high_a(900), high_b(800), break_skill(400)] → m1=high_a, m2=high_b, break_skill 落选。
      final skills3 = [highA, highB, breakSkill];

      test('senior(大弟子) 获得破防倾向：break_skill 替换 m2', () {
        final r = SkillLoadout.autoFill(
          mainTechniqueSkills: skills3,
          assistTechniqueSkills: const [],
          jointSkill: null,
          realmTier: RealmTier.yiLiu,
          existing: const SkillLoadout(),
          ultimatePowerThreshold: 5000,
          lineageRole: LineageRole.senior,
          isFounder: false,
        );
        // senior 应把 break_skill 塞进某个主修槽
        expect(
          r.mainSkillId1 == 'break_skill' || r.mainSkillId2 == 'break_skill',
          isTrue,
          reason: 'senior 应获得 break_skill 破防倾向',
        );
      });

      test('junior(二弟子) 不获得破防倾向：装配与无身份一致', () {
        final noBias = SkillLoadout.autoFill(
          mainTechniqueSkills: skills3,
          assistTechniqueSkills: const [],
          jointSkill: null,
          realmTier: RealmTier.yiLiu,
          existing: const SkillLoadout(),
          ultimatePowerThreshold: 5000,
        );
        final junior = SkillLoadout.autoFill(
          mainTechniqueSkills: skills3,
          assistTechniqueSkills: const [],
          jointSkill: null,
          realmTier: RealmTier.yiLiu,
          existing: const SkillLoadout(),
          ultimatePowerThreshold: 5000,
          lineageRole: LineageRole.junior,
          isFounder: false,
        );
        // junior 行为与无身份完全一致（power 降序，不插 break_skill）
        expect(junior.mainSkillId1, equals(noBias.mainSkillId1));
        expect(junior.mainSkillId2, equals(noBias.mainSkillId2));
        expect(
          junior.mainSkillId1 == 'break_skill' ||
              junior.mainSkillId2 == 'break_skill',
          isFalse,
          reason: 'junior 不应强插 break_skill',
        );
      });

      test('founder(isFounder=true) 不获得破防倾向', () {
        final founder = SkillLoadout.autoFill(
          mainTechniqueSkills: skills3,
          assistTechniqueSkills: const [],
          jointSkill: null,
          realmTier: RealmTier.yiLiu,
          existing: const SkillLoadout(),
          ultimatePowerThreshold: 5000,
          lineageRole: LineageRole.founder,
          isFounder: true,
        );
        expect(
          founder.mainSkillId1 == 'break_skill' ||
              founder.mainSkillId2 == 'break_skill',
          isFalse,
          reason: 'founder 不应获得破防倾向',
        );
      });

      test('通用 disciple 不再获得破防倾向（行为变更锁定）', () {
        final disciple = SkillLoadout.autoFill(
          mainTechniqueSkills: skills3,
          assistTechniqueSkills: const [],
          jointSkill: null,
          realmTier: RealmTier.yiLiu,
          existing: const SkillLoadout(),
          ultimatePowerThreshold: 5000,
          lineageRole: LineageRole.disciple,
          isFounder: false,
        );
        // 第七阶段批三：破防倾向已从 disciple 收窄到 senior；disciple 行为同无身份
        expect(
          disciple.mainSkillId1 == 'break_skill' ||
              disciple.mainSkillId2 == 'break_skill',
          isFalse,
          reason: '通用 disciple 不应再获得破防倾向（已收窄到 senior）',
        );
      });
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
