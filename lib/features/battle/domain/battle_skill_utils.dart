import 'battle_state.dart';
import '../../../data/defs/skill_def.dart';

/// 技能是否可下发：角色存活 + 真气足够 + 无冷却。
bool isSkillReady(BattleCharacter c, SkillDef skill) {
  if (!c.isAlive) return false;
  final cd = c.skillCooldowns[skill.id] ?? 0;
  return c.currentQi >= skill.qiCost && cd <= 0;
}

/// 技能当前能否作为玩家即时干预下发。
///
/// [isSkillReady] 只描述角色与技能资源；即时干预还要求行动条在上次预支归零后
/// 已重新积累为正。不同角色各自判断，不形成全队插队次数锁。
bool canInterveneWithSkill(BattleCharacter c, SkillDef skill) =>
    c.actionPoint > 0 && isSkillReady(c, skill);

int slotKey(int teamSide, int slotIndex) => teamSide * 3 + slotIndex;

BattleCharacter? findCharacter(int characterId, BattleState s) {
  for (final c in s.leftTeam) {
    if (c.characterId == characterId) return c;
  }
  for (final c in s.rightTeam) {
    if (c.characterId == characterId) return c;
  }
  return null;
}

/// 队列内某槽的竖直比例坐标(0..1),按**实际队伍人数** [teamSize] 均分:
///   1 人 → 0.5(居中);2 人 → 0.25 / 0.75(上下对称);3 人 → 1/6,3/6,5/6(原行为)。
///
/// `TeamColumn` 的视觉排布与 `_slotFrac` 的弹道坐标共用此式,保证头像位置与
/// 弹道/特效落点一致(分母从旧的硬编码 3 改为 teamSize 是「1 怪居中 / 2 怪对称」
/// 的唯一改动点)。teamSize ≤ 0 兜底 0.5 防除零。纯函数,单测直接验证。
double slotVerticalFraction(int slotIndex, int teamSize) {
  if (teamSize <= 0) return 0.5;
  return (slotIndex + 0.5) / teamSize;
}
