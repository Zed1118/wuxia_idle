import '../../../core/domain/enums.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/defs/technique_def.dart';

/// 心法自带三招的成长门槛。
///
/// techniques.yaml 中每本心法固定 3 个 skillIds：基础招 / 进阶招 / 大招。
/// 解锁按心法修炼层推进，不新增存档字段：第 1 招初窥可用，第 2 招小成可用，
/// 第 3 招大成可用。后续若出现第 4 招，沿大成门槛兜底。
CultivationLayer requiredLayerForTechniqueSkill({
  required TechniqueDef techniqueDef,
  required String skillId,
}) {
  final index = techniqueDef.skillIds.indexOf(skillId);
  return switch (index) {
    0 => CultivationLayer.chuKui,
    1 => CultivationLayer.xiaoCheng,
    _ => CultivationLayer.daCheng,
  };
}

bool isTechniqueSkillUnlockedByGrowth({
  required Technique technique,
  required TechniqueDef techniqueDef,
  required SkillDef skill,
}) {
  if (skill.parentTechniqueDefId != techniqueDef.id) return true;
  final required = requiredLayerForTechniqueSkill(
    techniqueDef: techniqueDef,
    skillId: skill.id,
  );
  return technique.cultivationLayer.index >= required.index;
}
