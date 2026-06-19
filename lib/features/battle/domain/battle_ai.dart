import '../../../data/defs/boss_phase_def.dart';
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

  /// 选择本次行动的（招式，目标 characterId 列表）。
  ///
  /// 返回 [targetIds]：single 技为单元素 list（沿用单体选目标逻辑）；aoe 技
  /// 为全体存活敌人 charId，按 slotIndex 升序（前排先）。callsite 暂取
  /// `targetIds.first` 保持单体结算，aoe 真 loop 由后续 task 接入。
  ///
  /// 调用前提：[actor.isAlive] == true，对面至少有一个活角色（否则 Engine
  /// 应已判胜负）。违反前提抛 [StateError]。
  static (SkillDef skill, List<int> targetIds) decide(
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

    // 群体技自动打全体存活敌人(按 slotIndex 升序),不走单体选目标 / 手动指定 /
    // 破招锁定——aoe 本就含蓄力敌,且 pendingTargets 对 aoe 技不写,优先于
    // pending manualTargetId 单体逻辑。
    if (skill.targetType == TargetType.aoe) {
      final targets = enemyTeam.where((e) => e.isAlive).toList()
        ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
      return (skill, targets.map((e) => e.characterId).toList());
    }

    // 半手动 P0 步骤3a:玩家对本次手动技(pending)指定的目标优先于一切默认
    // 选目标逻辑——前提是本次确实在用 pending 技、目标仍存活。
    final pending = state.pendingUltimates[actor.characterId];
    final manualTargetId = state.pendingTargets[actor.characterId];
    if (pending != null &&
        identical(skill, pending) &&
        manualTargetId != null &&
        enemyTeam.any((e) => e.isAlive && e.characterId == manualTargetId)) {
      return (skill, [manualTargetId]);
    }

    final charging =
        enemyTeam.where((e) => e.isAlive && e.chargingSkill != null);
    final int targetId;
    if (skill.canInterrupt && charging.isNotEmpty) {
      // 破招锁定优先于集火(破招窗口比泛破绽更紧急)
      targetId = charging.first.characterId; // P0:破招技锁定蓄力敌人
    } else if (_currentBossAiMode(actor) == BossAiMode.focus) {
      // Task 4-C:focus 阶段恒打血最低(击杀压制),不偏好破绽窗口目标。
      targetId = _pickTargetId(actor, state);
    } else {
      // 第六阶段:破绽窗口内敌优先集火(链路爆发);无破绽敌回落血最低。
      targetId = _pickFocusTargetId(actor, state) ?? _pickTargetId(actor, state);
    }
    return (skill, [targetId]);
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

    // Task 4-B:aggressive 阶段 → 优先放本阶段解锁招里 powerMultiplier 最高的可用招
    // (新解锁阶段招立即反扑,不被默认排序埋没)。仅在本阶段招都不可用时回落下方
    // 默认优先级。纯招式选择无属性 buff(§5.4)。
    if (_currentBossAiMode(actor) == BossAiMode.aggressive) {
      final phaseSkills = actor.bossPhaseUnlockSkills != null &&
              actor.bossPhaseIndex < actor.bossPhaseUnlockSkills!.length
          ? actor.bossPhaseUnlockSkills![actor.bossPhaseIndex]
          : const <SkillDef>[];
      final phaseIds = phaseSkills.map((s) => s.id).toSet();
      SkillDef? bestPhase;
      for (final s in actor.availableSkills) {
        if (!phaseIds.contains(s.id)) continue;
        if (s.aiUsePolicy == AiUsePolicy.saveForInterrupt) continue; // 与默认强力技 loop 一致:破招技平时不放(防阶段招混入破招技时被即放,破坏留招语义)
        if (!_canUse(actor, s)) continue;
        if (bestPhase == null ||
            s.powerMultiplier > bestPhase.powerMultiplier) {
          bestPhase = s;
        }
      }
      if (bestPhase != null) return bestPhase;
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

  /// 第六阶段集火:对面处于破绽窗口(staggerTicksRemaining>0)的活角色中血最低、
  /// 同 hp 取 slotIndex 小;无破绽敌返回 null(回落 _pickTargetId)。纯函数无 side effect。
  static int? _pickFocusTargetId(BattleCharacter actor, BattleState state) {
    final enemyTeam = actor.teamSide == 0 ? state.rightTeam : state.leftTeam;
    BattleCharacter? best;
    for (final e in enemyTeam) {
      if (!e.isAlive || e.staggerTicksRemaining <= 0) continue;
      if (best == null ||
          e.currentHp < best.currentHp ||
          (e.currentHp == best.currentHp && e.slotIndex < best.slotIndex)) {
        best = e;
      }
    }
    return best?.characterId;
  }

  /// Task 4:当前所处 Boss 阶段的 [BossAiMode]。非 Boss(bossPhases==null)或
  /// index 越界 → [BossAiMode.normal](默认行为,零回归)。
  static BossAiMode _currentBossAiMode(BattleCharacter actor) {
    final phases = actor.bossPhases;
    if (phases == null ||
        actor.bossPhaseIndex < 0 ||
        actor.bossPhaseIndex >= phases.length) {
      return BossAiMode.normal;
    }
    return phases[actor.bossPhaseIndex].aiMode;
  }

  /// 内力够 + CD 0 才可用（普攻 cost=0、CD=0 永远 true）。
  static bool _canUse(BattleCharacter actor, SkillDef skill) {
    if (actor.currentInternalForce < skill.internalForceCost) return false;
    final cd = actor.skillCooldowns[skill.id] ?? 0;
    if (cd > 0) return false;
    return true;
  }
}
