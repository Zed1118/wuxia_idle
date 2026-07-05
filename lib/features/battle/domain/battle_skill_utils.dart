import 'battle_state.dart';
import '../../../data/defs/skill_def.dart';

/// 技能是否可下发：角色存活 + 内力足够 + 无冷却。纯函数，无 Flutter 依赖，便于单测。
bool isSkillReady(BattleCharacter c, SkillDef skill) {
  if (!c.isAlive) return false;
  final cd = c.skillCooldowns[skill.id] ?? 0;
  return c.currentInternalForce >= skill.internalForceCost && cd <= 0;
}
