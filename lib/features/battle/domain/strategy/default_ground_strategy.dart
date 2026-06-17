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
  ///
  /// **半手动 P0 步骤3b 重构**:tick 改为「边界 [stepOne] + 循环 drain 本 tick
  /// 全部 actor」。入参约定为 tick 边界态(`actorQueue` 空,所有整 tick 调用方
  /// 都满足);返回亦回到边界态(队列 drain 空)。语义与重构前逐字节等价
  /// (rng 只在 [_resolveAction] 消费,拆分 actor 循环不改消费顺序),由
  /// `battle_step_one_test` 红线锁死 + 全量战斗测兜底。
  @override
  BattleState tick(
    BattleState state,
    NumbersConfig n, {
    Random? rng,
  }) {
    if (state.isFinished) return state;
    final r = rng ?? Random();
    // 边界步:推进 AP/CD + 排序 + 填队列(tick++,不结算)。
    var s = stepOne(state, n, rng: r);
    // drain:逐 actor 结算直到本 tick 队列空或战斗结束。
    while (s.actorQueue.isNotEmpty && !s.isFinished) {
      s = stepOne(s, n, rng: r);
    }
    return s;
  }

  /// 半手动 P0 步骤3b:推进最小一步(spec §八#3「一步=一 actor」)。
  ///
  /// - **队列空(tick 边界)**:全员 CD -= 1 + actionPoint += speed → 找出
  ///   actionPoint ≥ 1000 的活角色按 [_actorOrder] 排序 → 填入
  ///   [BattleState.actorQueue] + tick++。**不结算任何 actor、不消费 rng**。
  /// - **队列非空**:弹出队首一个 actor 结算。死亡 → 仅出队(不消费 rng);
  ///   对面全灭 → 清空剩余队列提前结束本 tick(不消费 rng);否则
  ///   [_resolveAction] 结算(**唯一消费 rng 处**)后出队。
  ///
  /// 拆分使「自动整 tick(tick)」「手动逐步(notifier.step)」「重放」三条路径
  /// 共用同一 actor 结算逻辑与同一 rng 消费顺序,确定性地基(spec §七)。
  @override
  BattleState stepOne(
    BattleState state,
    NumbersConfig n, {
    Random? rng,
  }) {
    if (state.isFinished) return state;

    // === 队列空 = tick 边界:推进 AP/CD + 排序 + 填队列,不结算 actor ===
    if (state.actorQueue.isEmpty) {
      final left = state.leftTeam.map(_advanceTick).toList();
      final right = state.rightTeam.map(_advanceTick).toList();
      final actors = <BattleCharacter>[];
      for (final c in left) {
        if (c.isAlive && c.actionPoint >= 1000) actors.add(c);
      }
      for (final c in right) {
        if (c.isAlive && c.actionPoint >= 1000) actors.add(c);
      }
      actors.sort(_actorOrder);
      return state.copyWith(
        leftTeam: List.unmodifiable(left),
        rightTeam: List.unmodifiable(right),
        tick: state.tick + 1,
        actorQueue: List.unmodifiable(
          actors.map((c) => (charId: c.characterId, teamSide: c.teamSide)),
        ),
      );
    }

    // === 队列非空:结算队首一个 actor ===
    final head = state.actorQueue.first;
    final rest = List<({int charId, int teamSide})>.unmodifiable(
      state.actorQueue.skip(1),
    );
    // 从最新 state 取该 actor(可能已被前面动作打死)。
    final actor = _findById(state, head.charId, head.teamSide);
    if (actor == null || !actor.isAlive) {
      return state.copyWith(actorQueue: rest);
    }
    // 对面如果已经全死 → 提前结束本 tick（清空剩余队列）。
    final enemyAlive = (actor.teamSide == 0 ? state.rightTeam : state.leftTeam)
        .any((c) => c.isAlive);
    if (!enemyAlive) {
      return state.copyWith(actorQueue: const []);
    }
    final s = _resolveAction(state, actor, n, rng ?? Random());
    return s.copyWith(actorQueue: rest);
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
    SkillDef skill, {
    int? targetId,
  }) {
    // P0:泛化为"玩家手动请求关键技"——接受 powerSkill/ultimate/jointSkill,
    // 拒绝 normalAttack(普攻不需手动)。
    if (skill.type == SkillType.normalAttack) {
      throw ArgumentError.value(
        skill, 'skill', '手动请求不接受 normalAttack',
      );
    }
    final newPending = Map<int, SkillDef>.from(state.pendingUltimates);
    newPending[characterId] = skill;
    // 半手动 P0 步骤3a:指定目标入 pendingTargets;未指定则确保清掉旧条目
    // (同一角色改请求无目标的技时,不残留上次目标)。
    final newTargets = Map<int, int>.from(state.pendingTargets);
    if (targetId != null) {
      newTargets[characterId] = targetId;
    } else {
      newTargets.remove(characterId);
    }
    return state.copyWith(
      pendingUltimates: Map.unmodifiable(newPending),
      pendingTargets: Map.unmodifiable(newTargets),
    );
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
      final remainingStagger = preActor.staggerTicksRemaining - 1;
      final after = preActor.copyWith(
        staggerTicksRemaining: remainingStagger,
        // 踉跄结束清掉减防 override(波A interrupt_power_pct)。
        staggerDefenseDownOverride: remainingStagger > 0
            ? preActor.staggerDefenseDownOverride
            : null,
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
      targetId = BattleAI.decide(preActor, preState, n)
          .$2
          .first; // 复用目标选择(Task1:暂取首个保持单体,aoe loop 后续)
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
      targetId = decided.$2.first; // Task1:暂取首个保持单体,aoe loop 后续
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
    // C2 反震:玩家命中带 'cycle_fanzhen' buff 的敌人 → 将内伤 slot 反弹到攻击者。
    // - 只在 attacker=player(teamSide==0)、defender 含 'cycle_fanzhen' 且非闪避时触发。
    // - 同源刷新(覆盖)：与 yinRou 内伤语义一致，直接覆盖旧 slot 不叠层。
    // - 参数全从 n.cycleEvolution.traits.fanzhen 读取，无硬编码数字。
    InternalInjurySlot? actorFanzhenInjury = preActor.internalInjury;
    if (!result.isDodged &&
        preActor.teamSide == 0 &&
        target.activeBuffs.contains('cycle_fanzhen')) {
      actorFanzhenInjury = InternalInjurySlot(
        remainingTurns: n.cycleEvolution.traits.fanzhen.ticks,
        damagePerTick: n.cycleEvolution.traits.fanzhen.damagePerTick,
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
    // 波A interrupt_power_pct(方向 b):有效减防 = base × (1 + 当阶 power_pct),
    // clamp 到 interruptPowerCap 红线(防御率减伤不破)。
    final staggerDefDown = brokeCharging
        ? (n.combat.bossCharge.staggerDefenseDown *
                (1 +
                    SkillProficiency.interruptPowerPct(skill,
                        preActor.skillUses[skill.id] ?? 0, n.skillProficiency)))
            .clamp(0.0, n.combat.bossCharge.interruptPowerCap)
        : null;
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
      staggerDefenseDownOverride: brokeCharging
          ? staggerDefDown
          : target.staggerDefenseDownOverride,
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
      // C2 反震:命中带 cycle_fanzhen 敌人时，将内伤 slot 写到攻击者自身。
      // actorFanzhenInjury 非 _unset sentinel，始终走显式更新分支;反震未触发时
      // round-trip 回 preActor.internalInjury（值不变，语义等效,不丢已有内伤）。
      internalInjury: actorFanzhenInjury,
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
      interrupted: brokeCharging,
    );

    // 消费 pendingUltimates[actor.characterId]（无论本次是否真用上大招）
    Map<int, SkillDef> newPending = preState.pendingUltimates;
    if (preState.pendingUltimates.containsKey(actorAfter.characterId)) {
      final m = Map<int, SkillDef>.from(preState.pendingUltimates)
        ..remove(actorAfter.characterId);
      newPending = Map.unmodifiable(m);
    }
    // 半手动 P0 步骤3a:指定目标与 pending 同生命周期,行动后一并移除。
    Map<int, int> newTargets = preState.pendingTargets;
    if (preState.pendingTargets.containsKey(actorAfter.characterId)) {
      final m = Map<int, int>.from(preState.pendingTargets)
        ..remove(actorAfter.characterId);
      newTargets = Map.unmodifiable(m);
    }

    final next = preState.copyWith(
      leftTeam: List.unmodifiable(left),
      rightTeam: List.unmodifiable(right),
      actionLog: [...preState.actionLog, action],
      pendingUltimates: newPending,
      pendingTargets: newTargets,
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
    // 波A:override 非 null 时用破招结算时写入的加深值(base × (1+power_pct))。
    var effDefRate = defender.defenseRate;
    if (defender.staggerTicksRemaining > 0) {
      final down = defender.staggerDefenseDownOverride ??
          n.combat.bossCharge.staggerDefenseDown;
      effDefRate = defender.defenseRate * (1 - down);
    }
    // 可玩性 P1a:从攻方进场快照 skillUses 派生该招熟练度综合倍率(敌人空 → 1.0)。
    final uses = attacker.skillUses[skill.id] ?? 0;
    final perSkillPct = skill.proficiency?.damagePctAt(
            SkillProficiency.stageFor(uses, n.skillProficiency).id) ??
        0.0;
    final profMult =
        SkillProficiency.combinedMult(uses, perSkillPct, n.skillProficiency);
    // 凝甲词条(C1):周目≥2 敌人携带 'cycle_ningjia' buff 时暴击增量减半。
    final critDamageTakenMult = defender.activeBuffs.contains('cycle_ningjia')
        ? n.cycleEvolution.traits.ningjia.critDamageTakenMult
        : 1.0;
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
      defenderCritDamageTakenMult: critDamageTakenMult,
      outputMultiplier: attacker.outputMultiplier,
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
