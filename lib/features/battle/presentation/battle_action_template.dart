import '../../../core/domain/enums.dart';
import '../../../data/defs/skill_def.dart';

/// 战斗表现只收敛为五种动作模板，不为每个招式写独立动画。
enum BattleActionTemplate { melee, projectile, area, control, cinematic }

const _projectileMarkers = <String>[
  'hidden',
  'flying',
  'rain',
  'wave',
  'bolt',
  'qi_',
  'finger',
  'wind_slash',
  'glow_sword',
  'sword_sprout',
];

const _controlMarkers = <String>[
  'seal',
  'freeze',
  'curse',
  'guard',
  'calm',
  'breathing',
  'rest_',
];

BattleActionTemplate battleActionTemplateFor(SkillDef? skill) {
  if (skill == null || skill.type == SkillType.normalAttack) {
    return BattleActionTemplate.melee;
  }
  if (skill.targetType == TargetType.aoe) return BattleActionTemplate.area;

  final effect = skill.visualEffect.toLowerCase();
  if (skill.canInterrupt || _controlMarkers.any(effect.contains)) {
    return BattleActionTemplate.control;
  }
  if (skill.type == SkillType.ultimate || skill.type == SkillType.jointSkill) {
    return BattleActionTemplate.cinematic;
  }
  if (_projectileMarkers.any(effect.contains)) {
    return BattleActionTemplate.projectile;
  }
  return BattleActionTemplate.melee;
}

bool templateMovesToClash(BattleActionTemplate template) =>
    template == BattleActionTemplate.melee;

bool templateUsesProjectile(BattleActionTemplate template) =>
    template == BattleActionTemplate.projectile;
