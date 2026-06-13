import '../../../data/defs/skill_def.dart';
import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';
import 'battle_state.dart';

/// 战斗 AI（phase1_tasks.md T12 §683）。
///
/// **Phase 1 简化策略**（phase1_tasks T12 §695）：
/// - 招式优先级：`pendingUltimates`（玩家手动请求且内力 + CD 满足）＞
///   强力技能（内力够 + CD 0，挑 powerMultiplier 最高）＞ 普攻
/// - 目标选择：对面活角色 currentHp 最低（同 hp 选 slotIndex 小的，前排优先）
///
/// **纯函数无 side effect**：从 [BattleState.pendingUltimates] 移除使用过的
/// 大招由 [BattleEngine] 行动结算后做（无论本次是否真用上，每次行动后都消费
/// 一次 pending，避免"内力够了下下次突然飞大招"迷惑玩家）。
class BattleAI {
  BattleAI._();

  /// 选择本次行动的（招式，目标 characterId）。
  ///
  /// 调用前提：[actor.isAlive] == true，对面至少有一个活角色（否则 Engine
  /// 应已判胜负）。违反前提抛 [StateError]。
  static (SkillDef skill, int targetId) decide(
    BattleCharacter actor,
    BattleState state,
    NumbersConfig n,
  ) {
    if (!actor.isAlive) {
      throw StateError(
        'BattleAI.decide: ${actor.name} 已死亡，不应进入决策',
      );
    }
    final skill = _pickSkill(actor, state);
    final enemyTeam = actor.teamSide == 0 ? state.rightTeam : state.leftTeam;

    // 半手动 P0 步骤3a:玩家对本次手动技(pending)指定的目标优先于一切默认
    // 选目标逻辑——前提是本次确实在用 pending 技、目标仍存活。当前引擎全技
    // 单体,§八#4「群体技自动」为前瞻(AoE 引入后那些技在此忽略指定目标)。
    final pending = state.pendingUltimates[actor.characterId];
    final manualTargetId = state.pendingTargets[actor.characterId];
    if (pending != null &&
        identical(skill, pending) &&
        manualTargetId != null &&
        enemyTeam.any((e) => e.isAlive && e.characterId == manualTargetId)) {
      return (skill, manualTargetId);
    }

    final charging =
        enemyTeam.where((e) => e.isAlive && e.chargingSkill != null);
    final int targetId;
    if (skill.canInterrupt && charging.isNotEmpty) {
      targetId = charging.first.characterId; // P0:破招技锁定蓄力敌人
    } else {
      targetId = _pickTargetId(actor, state);
    }
    return (skill, targetId);
  }

  /// 招式选择。
  static SkillDef _pickSkill(BattleCharacter actor, BattleState state) {
    // 1) 玩家手动请求的大招（优先级最高）
    final pending = state.pendingUltimates[actor.characterId];
    if (pending != null && _canUse(actor, pending)) {
      return pending;
    }

    // P0:对面有敌人蓄力 + 自己有可用 saveForInterrupt 破招技 → 用它(托管保守破招)
    final enemyTeam = actor.teamSide == 0 ? state.rightTeam : state.leftTeam;
    final enemyCharging =
        enemyTeam.any((e) => e.isAlive && e.chargingSkill != null);
    if (enemyCharging) {
      for (final s in actor.availableSkills) {
        if (s.aiUsePolicy != AiUsePolicy.saveForInterrupt) continue;
        if (!_canUse(actor, s)) continue;
        return s;
      }
    }

    // 1.5) P1.1 候选 3-b:共鸣度满级解锁的「人剑合一」(jointSkill)
    // 自动放(稀有招式 = 共鸣度回报体感,介于 pending 和 powerSkill 之间);
    // 多件武器共鸣解锁也只注入一次(fromCharacter 去重),所以 first 即可。
    for (final s in actor.availableSkills) {
      if (s.type != SkillType.jointSkill) continue;
      if (!_canUse(actor, s)) continue;
      return s;
    }

    // 2) 强力技能：内力够 + CD 0，多个挑 powerMultiplier 最高的
    SkillDef? bestPower;
    for (final s in actor.availableSkills) {
      if (s.type != SkillType.powerSkill) continue;
      if (s.aiUsePolicy == AiUsePolicy.saveForInterrupt) continue; // P0:平时不放破招技
      if (!_canUse(actor, s)) continue;
      if (bestPower == null || s.powerMultiplier > bestPower.powerMultiplier) {
        bestPower = s;
      }
    }
    if (bestPower != null) return bestPower;

    // 3) 普攻兜底（cost=0、CD=0，理论上一定可用）
    for (final s in actor.availableSkills) {
      if (s.type == SkillType.normalAttack) return s;
    }

    throw StateError(
      'BattleAI._pickSkill: ${actor.name} (technique 无可用普攻招式)，'
      'availableSkills=${actor.availableSkills.map((s) => s.id).toList()}',
    );
  }

  /// 目标选择：对面活角色 currentHp 最低的；同 hp 选 slotIndex 小的（前排优先）。
  static int _pickTargetId(BattleCharacter actor, BattleState state) {
    final enemyTeam =
        actor.teamSide == 0 ? state.rightTeam : state.leftTeam;
    BattleCharacter? best;
    for (final e in enemyTeam) {
      if (!e.isAlive) continue;
      if (best == null) {
        best = e;
        continue;
      }
      if (e.currentHp < best.currentHp) {
        best = e;
      } else if (e.currentHp == best.currentHp && e.slotIndex < best.slotIndex) {
        best = e;
      }
    }
    if (best == null) {
      throw StateError(
        'BattleAI._pickTargetId: ${actor.name} 对面无活角色，'
        'Engine 应已判胜负',
      );
    }
    return best.characterId;
  }

  /// 内力够 + CD 0 才可用（普攻 cost=0、CD=0 永远 true）。
  static bool _canUse(BattleCharacter actor, SkillDef skill) {
    if (actor.currentInternalForce < skill.internalForceCost) return false;
    final cd = actor.skillCooldowns[skill.id] ?? 0;
    if (cd > 0) return false;
    return true;
  }
}
