import 'battle_state.dart';
import 'battle_ai.dart';
import 'qi_cycle.dart';
import '../../../data/defs/skill_def.dart';

/// 角色在当前战斗快照中施放招式的实际耗气。
int effectiveSkillQiCost(BattleCharacter c, SkillDef skill) =>
    QiCycle.effectiveCostFromSnapshot(
      baseCost: skill.qiCost,
      costReductionPct: c.qiCostReductionPct,
    );

/// 技能是否可下发：角色存活 + 真气足够 + 无冷却。
bool isSkillReady(BattleCharacter c, SkillDef skill) {
  if (!c.isAlive) return false;
  final cd = c.skillCooldowns[skill.id] ?? 0;
  return c.currentQi >= effectiveSkillQiCost(c, skill) && cd <= 0;
}

/// 技能当前能否作为玩家即时干预下发。
///
/// [isSkillReady] 只描述角色与技能资源；即时干预还要求行动条在上次预支归零后
/// 已重新积累为正，且角色未处于蓄力或踉跄。不同角色各自判断，不形成全队
/// 插队次数锁。
bool canInterveneWithSkill(BattleCharacter c, SkillDef skill) =>
    c.actionPoint > 0 &&
    c.chargingSkill == null &&
    c.staggerTicksRemaining <= 0 &&
    isSkillReady(c, skill);

/// 当前战斗快照是否允许把技能作为即时干预下发。
///
/// 除角色资源/控制态外，还要求停在完整 tick 边界；单步模式留下的拍内
/// [BattleState.actorQueue] 必须先结算完，避免同一角色在该拍二次行动。
bool canInterveneNow(
  BattleState state,
  BattleCharacter character,
  SkillDef skill,
) =>
    !state.isFinished &&
    state.actorQueue.isEmpty &&
    canInterveneWithSkill(character, skill);

/// 手动单体技能否把 [enemy] 作为指定目标。
///
/// 常规口径与自动选敌一致：护法存活时受保护 Boss 不进入目标池。唯一例外是
/// 破招技面对正在蓄力的 Boss，保持自动破招路径既有的防御优先级。
bool canManuallyTargetEnemy(
  BattleCharacter enemy,
  BattleState state,
  SkillDef skill,
) {
  if (!enemy.isAlive) return false;
  if (!BattleAI.isGuardedBoss(enemy, state)) return true;
  return skill.canInterrupt && enemy.chargingSkill != null;
}

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
