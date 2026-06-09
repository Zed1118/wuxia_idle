import 'dart:math';

import '../../../../data/defs/skill_def.dart';
import '../../../../core/domain/enums.dart';
import '../../../../data/numbers_config.dart';
import '../battle_ai.dart';
import '../enum_localizations.dart';
import '../battle_state.dart';
import '../damage_calculator.dart';
import '../../../cultivation/domain/skill_proficiency.dart';
import 'battle_strategy.dart';

/// 地面 3v3 半横版战斗 strategy(Demo 阶段唯一实装)。
///
/// 1.0 路线图 P0 抽 strategy 层重构(详 `docs/handoff/p0_battle_strategy_spec.md`)
/// 前是 `BattleEngine` static 类,11 method 整体搬迁到本类 + static→instance。
/// 公式语义零变化(GDD §5.3-§5.6 + §12.1 #7 v1.4 阴柔内伤 / 刚猛震伤)。
///
/// **time-based 行动制**(phase1_tasks T12 §655):每 tick 全员 actionPoint +=
/// speed,累积到 1000 触发行动并归零(保留余数)。比"每回合所有人轮流出手"
/// 更符合速度差直观——速度越快行动越频繁。
///
/// **immutable**:[tick] / [runToEnd] / [requestUltimate] 全部纯函数,输入旧
/// state 输出新 state。**本 strategy 不持任何 mutable instance state**,所有
/// method 接 [BattleState] 入参输出新 state,与原 static 行为完全等价
/// (memory `feedback_layered_bugs` R3 风险条对策)。
///
/// **顺序锁死**(phase1_tasks T12 §712 防同 actionPoint 测试不稳定):
/// 1. tick 推进时所有招式 CD -= 1(最低 0),**然后**全员 actionPoint += speed。
///    新写入的 CD 从下个 tick 开始递减(phase1_tasks T12 §714)。
/// 2. 找出 actionPoint ≥ 1000 的活角色,按
///    `(actionPoint desc, speed desc, teamSide asc, slotIndex asc)` 排序。
/// 3. 依次行动;每次行动后立即检查胜负,已结束则提前退出本 tick。
class DefaultGroundStrategy implements BattleStrategy {
  const DefaultGroundStrategy();

  /// 推进一个 tick。
  ///
  /// [rng] 用于伤害计算中的闪避 / 暴击 roll；测试传 `Random(seed)` 复现。
  @override
  BattleState tick(
    BattleState state,
    NumbersConfig n, {
    Random? rng,
  }) {
    if (state.isFinished) return state;

    // 1) 全员 CD -= 1（最低 0），再 actionPoint += speed。
    final left = state.leftTeam.map(_advanceTick).toList();
    final right = state.rightTeam.map(_advanceTick).toList();

    // 2) 找出 actionPoint ≥ 1000 的活角色，按破平局规则排序。
    final actors = <BattleCharacter>[];
    for (final c in left) {
      if (c.isAlive && c.actionPoint >= 1000) actors.add(c);
    }
    for (final c in right) {
      if (c.isAlive && c.actionPoint >= 1000) actors.add(c);
    }
    actors.sort(_actorOrder);

    // 3) 依次行动。每次行动产生新 state，下一个行动者从新 state 取最新快照
    //    （前面行动者可能改了死亡 / HP）。
    var s = state.copyWith(
      leftTeam: List.unmodifiable(left),
      rightTeam: List.unmodifiable(right),
      tick: state.tick + 1,
    );
    for (final initial in actors) {
      // 从最新 state 取该 actor（可能已被前面动作打死）
      final actor = _findById(s, initial.characterId, initial.teamSide);
      if (actor == null || !actor.isAlive) continue;
      // 对面如果已经全死 → 提前结束
      final enemyAlive = (actor.teamSide == 0 ? s.rightTeam : s.leftTeam)
          .any((c) => c.isAlive);
      if (!enemyAlive) break;
      s = _resolveAction(s, actor, n, rng ?? Random());
      if (s.isFinished) return s;
    }

    return s;
  }

  /// 跑完整场战斗。
  ///
  /// [maxTicks] 兜底防死循环（phase1_tasks T12 §716）：境界差太大双方都基本
  /// 免疫时会一直打不死，触发上限 → [BattleResult.draw]。
  @override
  BattleState runToEnd(
    BattleState initial,
    NumbersConfig n, {
    int maxTicks = 1000,
    Random? rng,
  }) {
    var s = initial;
    final r = rng ?? Random();
    var i = 0;
    while (!s.isFinished && i < maxTicks) {
      s = tick(s, n, rng: r);
      i++;
    }
    if (!s.isFinished) {
      s = s.copyWith(result: BattleResult.draw);
    }
    return s;
  }

  /// 玩家手动请求关键技（P0 泛化:破招技/大招/人剑合一）。
  ///
  /// **不打断当前 tick 的行动顺序**——只是把"下次该角色行动用什么招"标记下来。
  /// 如果该角色当时内力或 CD 不满足，[BattleAI] 会跳过这次大招，由 [_resolveAction]
  /// 在该角色行动后从 pendingUltimates 中移除（一次机会，不留到下下次）。
  @override
  BattleState requestUltimate(
    BattleState state,
    int characterId,
    SkillDef skill,
  ) {
    // P0:泛化为"玩家手动请求关键技"——接受 powerSkill/ultimate/jointSkill,
    // 拒绝 normalAttack(普攻不需手动)。
    if (skill.type == SkillType.normalAttack) {
      throw ArgumentError.value(
        skill, 'skill', '手动请求不接受 normalAttack',
      );
    }
    final newPending = Map<int, SkillDef>.from(state.pendingUltimates);
    newPending[characterId] = skill;
    return state.copyWith(pendingUltimates: Map.unmodifiable(newPending));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 内部：tick 推进的子步骤
  // ─────────────────────────────────────────────────────────────────────────

  /// 单角色 tick 推进：CD -= 1（最低 0）→ actionPoint += speed（仅活角色）。
  BattleCharacter _advanceTick(BattleCharacter c) {
    if (!c.isAlive) return c;
    final newCd = <String, int>{};
    c.skillCooldowns.forEach((id, cd) {
      final v = cd - 1;
      if (v > 0) newCd[id] = v;
      // v ≤ 0 直接从 map 中移除（清晰干净）
    });
    return c.copyWith(
      skillCooldowns: Map.unmodifiable(newCd),
      actionPoint: c.actionPoint + c.speed,
    );
  }

  /// 排序破平局（phase1_tasks T12 §712）：
  /// `actionPoint desc → speed desc → teamSide asc → slotIndex asc`。
  int _actorOrder(BattleCharacter a, BattleCharacter b) {
    final ap = b.actionPoint.compareTo(a.actionPoint);
    if (ap != 0) return ap;
    final sp = b.speed.compareTo(a.speed);
    if (sp != 0) return sp;
    final ts = a.teamSide.compareTo(b.teamSide);
    if (ts != 0) return ts;
    return a.slotIndex.compareTo(b.slotIndex);
  }

  /// 在 state 内按 (characterId, teamSide) 找 BattleCharacter 最新快照。
  BattleCharacter? _findById(BattleState s, int id, int teamSide) {
    final team = teamSide == 0 ? s.leftTeam : s.rightTeam;
    for (final c in team) {
      if (c.characterId == id) return c;
    }
    return null;
  }

  /// 单次行动结算:阴柔内伤 dot 结算(若 actor 有内伤槽)→ AI 选招/目标 →
  /// 伤害计算 → 应用伤害 + 扣内力 + 写 CD → actionPoint -= 1000 → 写 BattleAction
  /// → 死亡 / 胜负判定 → 阴柔克灵巧 refresh internalInjury slot on defender。
  BattleState _resolveAction(
    BattleState state,
    BattleCharacter actor,
    NumbersConfig n,
    Random rng,
  ) {
    // === 0. 阴柔内伤 dot 结算(§12.1 #7 v1.4)===
    // actor 出手前若有内伤槽 + remainingTurns > 0,先承受 1 次 dot:
    //   - 穿透防御直接扣 damagePerTick
    //   - turns -= 1,用尽则清空 slot
    //   - 致死则写 BattleAction 内伤崩裂 + 胜负判定 + return,跳过本次行动
    var preActor = actor;
    var preState = state;
    final inj = actor.internalInjury;
    if (inj != null && inj.remainingTurns > 0) {
      final hpAfterDot = (actor.currentHp - inj.damagePerTick).clamp(0, actor.maxHp);
      final remaining = inj.remainingTurns - 1;
      preActor = actor.copyWith(
        currentHp: hpAfterDot,
        isAlive: hpAfterDot > 0,
        internalInjury: remaining > 0
            ? InternalInjurySlot(
                remainingTurns: remaining,
                damagePerTick: inj.damagePerTick,
              )
            : null,
      );
      final leftDot = preState.leftTeam.toList();
      final rightDot = preState.rightTeam.toList();
      _replaceById(actor.teamSide == 0 ? leftDot : rightDot, preActor);
      final dotAction = BattleAction(
        tick: preState.tick,
        actorId: actor.characterId,
        description: preActor.isAlive
            ? EnumL10n.internalInjuryTick(actor.name, inj.damagePerTick)
            : EnumL10n.internalInjuryFatal(actor.name),
      );
      preState = preState.copyWith(
        leftTeam: List.unmodifiable(leftDot),
        rightTeam: List.unmodifiable(rightDot),
        actionLog: [...preState.actionLog, dotAction],
      );
      // 致死 → 胜负判定 + return(跳过本次行动)
      if (!preActor.isAlive) {
        final leftAliveDot = preState.leftTeam.any((c) => c.isAlive);
        final rightAliveDot = preState.rightTeam.any((c) => c.isAlive);
        if (!leftAliveDot && !rightAliveDot) {
          return preState.copyWith(result: BattleResult.draw);
        }
        if (!leftAliveDot) {
          return preState.copyWith(result: BattleResult.rightWin);
        }
        if (!rightAliveDot) {
          return preState.copyWith(result: BattleResult.leftWin);
        }
        return preState;
      }
    }

    // === P0 踉跄 pre-step(Task 8 · 必须在蓄力判定之前)===
    // (a) 踉跄中:跳过本次行动,递减 stagger(踉跄的单位本就不该继续蓄力推进)。
    if (preActor.staggerTicksRemaining > 0) {
      final after = preActor.copyWith(
        staggerTicksRemaining: preActor.staggerTicksRemaining - 1,
        actionPoint: preActor.actionPoint - 1000,
      );
      final lt = preState.leftTeam.toList();
      final rt = preState.rightTeam.toList();
      _replaceById(after.teamSide == 0 ? lt : rt, after);
      return preState.copyWith(
        leftTeam: List.unmodifiable(lt),
        rightTeam: List.unmodifiable(rt),
        actionLog: [
          ...preState.actionLog,
          BattleAction(
            tick: preState.tick,
            actorId: after.characterId,
            description: EnumL10n.staggered(after.name),
          ),
        ],
      );
    }

    // === P0 蓄力 pre-step(Task 7)===
    // (b) 蓄力中:递减;未满写"蓄力中"跳过本次;满则本次放 chargingSkill。
    SkillDef? forcedSkill;
    if (preActor.chargingSkill != null) {
      final remaining = preActor.chargeTicksRemaining - 1;
      if (remaining > 0) {
        final after = preActor.copyWith(
          chargeTicksRemaining: remaining,
          actionPoint: preActor.actionPoint - 1000,
        );
        final lt = preState.leftTeam.toList();
        final rt = preState.rightTeam.toList();
        _replaceById(after.teamSide == 0 ? lt : rt, after);
        return preState.copyWith(
          leftTeam: List.unmodifiable(lt),
          rightTeam: List.unmodifiable(rt),
          actionLog: [
            ...preState.actionLog,
            BattleAction(
              tick: preState.tick,
              actorId: after.characterId,
              description: EnumL10n.charging(after.name),
            ),
          ],
        );
      } else {
        forcedSkill = preActor.chargingSkill;
        preActor = preActor.copyWith(
          chargingSkill: null,
          chargeTicksRemaining: 0,
        );
      }
    }

    final SkillDef skill;
    final int targetId;
    if (forcedSkill != null) {
      skill = forcedSkill;
      targetId = BattleAI.decide(preActor, preState, n).$2; // 复用目标选择
    } else {
      final decided = BattleAI.decide(preActor, preState, n);
      // (c) 起手蓄力:选中自己的 chargeSkillId 且未蓄力 → 开始蓄力,本 tick 不出伤。
      if (preActor.chargeSkillId != null &&
          decided.$1.id == preActor.chargeSkillId) {
        final after = preActor.copyWith(
          chargingSkill: decided.$1,
          chargeTicksRemaining: n.combat.bossCharge.defaultChargeTicks,
          actionPoint: preActor.actionPoint - 1000,
        );
        final lt = preState.leftTeam.toList();
        final rt = preState.rightTeam.toList();
        _replaceById(after.teamSide == 0 ? lt : rt, after);
        return preState.copyWith(
          leftTeam: List.unmodifiable(lt),
          rightTeam: List.unmodifiable(rt),
          actionLog: [
            ...preState.actionLog,
            BattleAction(
              tick: preState.tick,
              actorId: after.characterId,
              description: EnumL10n.chargeStart(after.name, decided.$1.name),
            ),
          ],
        );
      }
      skill = decided.$1;
      targetId = decided.$2;
    }
    final target = _findById(
      preState,
      targetId,
      preActor.teamSide == 0 ? 1 : 0,
    );
    if (target == null) {
      throw StateError(
        'BattleEngine._resolveAction: 找不到 targetId=$targetId',
      );
    }

    final result = _calculateInBattle(
      attacker: preActor,
      defender: target,
      skill: skill,
      n: n,
      rng: rng,
    );

    // 应用伤害到目标
    final newTargetHp = (target.currentHp - result.finalDamage).clamp(
      0,
      target.maxHp,
    );
    // 阴柔 → 灵巧 命中 → refresh/施加内伤槽(§12.1 #7 v1.4):
    // 同源刷新(覆盖)语义 = 直接覆盖原 slot 不叠层。
    InternalInjurySlot? newInjury = target.internalInjury;
    if (!result.isDodged &&
        preActor.school == TechniqueSchool.yinRou &&
        target.school == TechniqueSchool.lingQiao) {
      newInjury = InternalInjurySlot(
        remainingTurns: n.schoolCounter.yinRouInternalInjury.turnsPersist,
        damagePerTick: n.schoolCounter.yinRouInternalInjury.damagePerTick,
      );
    }
    // P0 破招:canInterrupt 技命中正在蓄力的目标 → 打断 + 踉跄 + 招牌技上 CD。
    final targetCd = Map<String, int>.from(target.skillCooldowns);
    var brokeCharging = false;
    if (skill.canInterrupt &&
        !result.isDodged &&
        target.chargingSkill != null) {
      brokeCharging = true;
      final cs = target.chargingSkill!;
      targetCd[cs.id] = cs.cooldownTurns > 0 ? cs.cooldownTurns : 1;
    }
    final targetAfter = target.copyWith(
      currentHp: newTargetHp,
      isAlive: newTargetHp > 0,
      internalInjury: newInjury,
      skillCooldowns: Map.unmodifiable(targetCd),
      chargingSkill: brokeCharging ? null : target.chargingSkill,
      chargeTicksRemaining:
          brokeCharging ? 0 : target.chargeTicksRemaining,
      staggerTicksRemaining: brokeCharging
          ? n.combat.bossCharge.defaultStaggerTicks +
              SkillProficiency.interruptWindowBonus(skill,
                  preActor.skillUses[skill.id] ?? 0, n.skillProficiency)
          : target.staggerTicksRemaining,
    );

    // 攻方扣内力 + 写 CD + actionPoint -= 1000（保留余数）
    final newCd = Map<String, int>.from(preActor.skillCooldowns);
    // 可玩性 P1a:per-skill 熟练度 cooldown_delta 缩短有效 CD(下限 0)。
    final effCd = SkillProficiency.effectiveCooldown(
        skill, preActor.skillUses[skill.id] ?? 0, n.skillProficiency);
    if (effCd > 0) {
      newCd[skill.id] = effCd;
    }
    final actorAfter = preActor.copyWith(
      currentInternalForce:
          preActor.currentInternalForce - skill.internalForceCost,
      skillCooldowns: Map.unmodifiable(newCd),
      actionPoint: preActor.actionPoint - 1000,
    );

    // 写回队伍
    final left = preState.leftTeam.toList();
    final right = preState.rightTeam.toList();
    _replaceById(actorAfter.teamSide == 0 ? left : right, actorAfter);
    _replaceById(targetAfter.teamSide == 0 ? left : right, targetAfter);

    // 写 BattleAction
    final action = BattleAction(
      tick: preState.tick,
      actorId: actorAfter.characterId,
      targetId: target.characterId,
      skill: skill,
      attackResult: result,
      description: brokeCharging
          ? EnumL10n.interrupted(actorAfter.name, targetAfter.name)
          : _formatAction(actorAfter, targetAfter, skill, result),
    );

    // 消费 pendingUltimates[actor.characterId]（无论本次是否真用上大招）
    Map<int, SkillDef> newPending = preState.pendingUltimates;
    if (preState.pendingUltimates.containsKey(actorAfter.characterId)) {
      final m = Map<int, SkillDef>.from(preState.pendingUltimates)
        ..remove(actorAfter.characterId);
      newPending = Map.unmodifiable(m);
    }

    final next = preState.copyWith(
      leftTeam: List.unmodifiable(left),
      rightTeam: List.unmodifiable(right),
      actionLog: [...preState.actionLog, action],
      pendingUltimates: newPending,
    );

    // 胜负判定
    final leftAlive = next.leftTeam.any((c) => c.isAlive);
    final rightAlive = next.rightTeam.any((c) => c.isAlive);
    if (!leftAlive && !rightAlive) {
      return next.copyWith(result: BattleResult.draw);
    }
    if (!leftAlive) return next.copyWith(result: BattleResult.rightWin);
    if (!rightAlive) return next.copyWith(result: BattleResult.leftWin);
    return next;
  }

  void _replaceById(List<BattleCharacter> team, BattleCharacter c) {
    for (var i = 0; i < team.length; i++) {
      if (team[i].characterId == c.characterId) {
        team[i] = c;
        return;
      }
    }
  }

  /// 战斗内伤害计算 adapter(BattleCharacter 路径)。
  ///
  /// P2-c 收敛(2026-05-29):公式数学已抽到 [DamageCalculator.calculateResolved]
  /// 单一真相源 —— 本方法只做 BattleCharacter 快照字段解析 → 调它。字段口径:
  /// 内力用 `currentInternalForce`(战斗中扣过)· 装备攻击用 `totalEquipmentAttack`
  /// 缓存 · 修炼度从 `mainCultivationLayer` · 防御率用 `defenseRate` 缓存(含相生
  /// defensePct 注入 · W18-A1.2)· attackPowerMultiplier 用烘焙值(轻功/群战/恩怨 ·
  /// P3.1.B · 双方对等 · default 1.0)。
  AttackResult _calculateInBattle({
    required BattleCharacter attacker,
    required BattleCharacter defender,
    required SkillDef skill,
    required NumbersConfig n,
    required Random rng,
    bool forceCritical = false,
  }) {
    // P0 踉跄减防:踉跄期间防御率乘 (1 - staggerDefenseDown) → 增伤。
    var effDefRate = defender.defenseRate;
    if (defender.staggerTicksRemaining > 0) {
      effDefRate =
          defender.defenseRate * (1 - n.combat.bossCharge.staggerDefenseDown);
    }
    // 可玩性 P1a:从攻方进场快照 skillUses 派生该招熟练度综合倍率(敌人空 → 1.0)。
    final uses = attacker.skillUses[skill.id] ?? 0;
    final perSkillPct = skill.proficiency?.damagePctAt(
            SkillProficiency.stageFor(uses, n.skillProficiency).id) ??
        0.0;
    final profMult =
        SkillProficiency.combinedMult(uses, perSkillPct, n.skillProficiency);
    return DamageCalculator.calculateResolved(
      attackerInternalForce: attacker.currentInternalForce,
      attackerEquipmentAttack: attacker.totalEquipmentAttack,
      attackerCultivationLayer: attacker.mainCultivationLayer,
      attackerSchool: attacker.school,
      defenderSchool: defender.school,
      attackerRealmTier: attacker.realmTier,
      attackerRealmLayer: attacker.realmLayer,
      defenderRealmTier: defender.realmTier,
      defenderRealmLayer: defender.realmLayer,
      defenderDefenseRate: effDefRate,
      defenderEvasionRate: defender.evasionRate,
      attackerCriticalRate: attacker.criticalRate,
      attackPowerMultiplier: attacker.attackPowerMultiplier,
      skill: skill,
      n: n,
      rng: rng,
      forceCritical: forceCritical,
      proficiencyDamageMult: profMult,
    );
  }

  /// 调试日志描述串（T13 才正式做中文化，本阶段简化）。
  String _formatAction(
    BattleCharacter actor,
    BattleCharacter targetAfter,
    SkillDef skill,
    AttackResult r,
  ) {
    if (r.isDodged) {
      return '${actor.name} 对 ${targetAfter.name} 使用 ${skill.name}，被闪避';
    }
    final crit = r.isCritical ? '【暴击】' : '';
    return '${actor.name} 对 ${targetAfter.name} 使用 ${skill.name}'
        '$crit，造成 ${r.finalDamage} 伤害'
        '${targetAfter.isAlive ? "" : "（击杀）"}';
  }
}
