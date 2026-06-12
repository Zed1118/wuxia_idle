import '../../../core/domain/enums.dart';
import '../../../data/defs/skill_def.dart';
import 'skill_loadout_resolver.dart';
import 'skill_loadout_service.dart';

/// 槽 → 候选招的单一真相源（藏经阁换招 picker + 武学库直接装配 T6 共用）。
///
/// 语义与原 `_SlotTile._candidatesFor` 一致：
/// - main1/main2/ultimate → 主修心法招 + 已解锁本流派真解/残页(dropSkills)
/// - assist → 辅修心法招
/// - resonance → joint 共鸣招(解锁则单元素)
/// - key → 本流派破招技(style == school，与 service gate 一致)
List<SkillDef> candidatesForSlot(
  SkillSlot slot,
  ResolvedLoadoutSources sources,
  TechniqueSchool? school,
) {
  return switch (slot) {
    SkillSlot.main1 || SkillSlot.main2 || SkillSlot.ultimate => [
      ...sources.mainTechniqueSkills,
      ...sources.dropSkills,
    ],
    SkillSlot.assist => sources.assistTechniqueSkills,
    SkillSlot.resonance => [
      if (sources.jointSkill != null) sources.jointSkill!,
    ],
    SkillSlot.key =>
      sources.interruptSkills
          .where((s) => s.style != null && s.style == school)
          .toList(),
  };
}

/// 招 → 合法槽(武学库直接装配 T6):反查该招出现在哪些槽的候选里。
/// 与 [candidatesForSlot] 对称，保证「能从槽选到的招」恰好「能装回该槽」。
List<SkillSlot> legalSlotsForSkill(
  String skillId,
  ResolvedLoadoutSources sources,
  TechniqueSchool? school,
) {
  return SkillSlot.values
      .where(
        (slot) => candidatesForSlot(
          slot,
          sources,
          school,
        ).any((s) => s.id == skillId),
      )
      .toList();
}
