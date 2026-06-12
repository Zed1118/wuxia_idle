import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/cultivation/application/loadout_slot_candidates.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_resolver.dart';
import 'package:wuxia_idle/features/cultivation/application/skill_loadout_service.dart';

/// 槽↔招映射单一真相源测试（T6 武学库直接装配）。
///
/// legalSlotsForSkill 反查必须与 candidatesForSlot 对称（同一份语义）。
void main() {
  SkillDef mk(
    String id, {
    SkillType type = SkillType.powerSkill,
    bool canInterrupt = false,
    TechniqueSchool? style,
    SkillSource? source,
  }) =>
      SkillDef(
        id: id,
        name: id,
        description: '',
        type: type,
        powerMultiplier: 100,
        internalForceCost: 0,
        cooldownTurns: 0,
        requiresManualTrigger: false,
        visualEffect: 'none',
        canInterrupt: canInterrupt,
        style: style,
        source: source,
      );

  final mainSkill = mk('m1');
  final assistSkill = mk('a1');
  final jointSkill = mk('joint', type: SkillType.jointSkill);
  final dropSkill = mk('d1',
      source: SkillSource.mainlineDrop, style: TechniqueSchool.gangMeng);
  final interruptSkill =
      mk('k1', canInterrupt: true, style: TechniqueSchool.gangMeng);

  final sources = ResolvedLoadoutSources(
    mainTechniqueSkills: [mainSkill],
    assistTechniqueSkills: [assistSkill],
    jointSkill: jointSkill,
    interruptSkills: [interruptSkill],
    dropSkills: [dropSkill],
  );

  const school = TechniqueSchool.gangMeng;

  test('主修招 → 可装 main1/main2/ultimate', () {
    expect(
      legalSlotsForSkill('m1', sources, school),
      containsAll([SkillSlot.main1, SkillSlot.main2, SkillSlot.ultimate]),
    );
  });

  test('辅修招 → 只可装 assist', () {
    expect(legalSlotsForSkill('a1', sources, school), [SkillSlot.assist]);
  });

  test('共鸣招 → 只可装 resonance', () {
    expect(legalSlotsForSkill('joint', sources, school), [SkillSlot.resonance]);
  });

  test('破招技(本流派) → 只可装 key', () {
    expect(legalSlotsForSkill('k1', sources, school), [SkillSlot.key]);
  });

  test('已解锁本流派 drop 招 → 可装 main1/main2/ultimate', () {
    expect(
      legalSlotsForSkill('d1', sources, school),
      containsAll([SkillSlot.main1, SkillSlot.main2, SkillSlot.ultimate]),
    );
  });

  test('破招技流派不合 → 不可装 key（合法槽空）', () {
    expect(
      legalSlotsForSkill('k1', sources, TechniqueSchool.yinRou),
      isEmpty,
    );
  });

  test('未知招 → 合法槽空', () {
    expect(legalSlotsForSkill('nope', sources, school), isEmpty);
  });
}
