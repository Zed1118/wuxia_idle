import 'dart:math';

import '../../../data/defs/skill_def.dart';
import '../../../core/domain/enums.dart';
import '../../../data/numbers_config.dart';
import 'battle_ai.dart';
import 'enum_localizations.dart';
import 'battle_state.dart';
import 'damage_calculator.dart';
import 'derived_stats.dart';

/// 战斗引擎（phase1_tasks.md T12.1 §669）。
///
/// **time-based 行动制**（phase1_tasks T12 §655）：每 tick 全员 actionPoint +=
/// speed，累积到 1000 触发行动并归零（保留余数）。比"每回合所有人轮流出手"
/// 更符合速度差直观——速度越快行动越频繁。
///
/// **immutable**：[tick] / [runToEnd] / [requestUltimate] 全部纯函数，输入旧
/// state 输出新 state。
///
/// **顺序锁死**（phase1_tasks T12 §712 防同 actionPoint 测试不稳定）：
/// 1. tick 推进时所有招式 CD -= 1（最低 0），**然后**全员 actionPoint += speed。
///    新写入的 CD 从下个 tick 开始递减（phase1_tasks T12 §714）。
/// 2. 找出 actionPoint ≥ 1000 的活角色，按
///    `(actionPoint desc, speed desc, teamSide asc, slotIndex asc)` 排序。
/// 3. 依次行动；每次行动后立即检查胜负，已结束则提前退出本 tick。
class BattleEngine {
  BattleEngine._();

  /// 推进一个 tick。
  ///
  /// [rng] 用于伤害计算中的闪避 / 暴击 roll；测试传 `Random(seed)` 复现。
  static BattleState tick(
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
  static BattleState runToEnd(
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

  /// 玩家手动请求大招（phase1_tasks T12 §698 / §717）。
  ///
  /// **不打断当前 tick 的行动顺序**——只是把"下次该角色行动用什么招"标记下来。
  /// 如果该角色当时内力或 CD 不满足，[BattleAI] 会跳过这次大招，由 [_resolveAction]
  /// 在该角色行动后从 pendingUltimates 中移除（一次机会，不留到下下次）。
  static BattleState requestUltimate(
    BattleState state,
    int characterId,
    SkillDef ultimate,
  ) {
    if (ultimate.type != SkillType.ultimate) {
      throw ArgumentError.value(
        ultimate,
        'ultimate',
        'requestUltimate 只接受 type=ultimate 的招式',
      );
    }
    final newPending = Map<int, SkillDef>.from(state.pendingUltimates);
    newPending[characterId] = ultimate;
    return state.copyWith(pendingUltimates: Map.unmodifiable(newPending));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 内部：tick 推进的子步骤
  // ─────────────────────────────────────────────────────────────────────────

  /// 单角色 tick 推进：CD -= 1（最低 0）→ actionPoint += speed（仅活角色）。
  static BattleCharacter _advanceTick(BattleCharacter c) {
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
  static int _actorOrder(BattleCharacter a, BattleCharacter b) {
    final ap = b.actionPoint.compareTo(a.actionPoint);
    if (ap != 0) return ap;
    final sp = b.speed.compareTo(a.speed);
    if (sp != 0) return sp;
    final ts = a.teamSide.compareTo(b.teamSide);
    if (ts != 0) return ts;
    return a.slotIndex.compareTo(b.slotIndex);
  }

  /// 在 state 内按 (characterId, teamSide) 找 BattleCharacter 最新快照。
  static BattleCharacter? _findById(BattleState s, int id, int teamSide) {
    final team = teamSide == 0 ? s.leftTeam : s.rightTeam;
    for (final c in team) {
      if (c.characterId == id) return c;
    }
    return null;
  }

  /// 单次行动结算:阴柔内伤 dot 结算(若 actor 有内伤槽)→ AI 选招/目标 →
  /// 伤害计算 → 应用伤害 + 扣内力 + 写 CD → actionPoint -= 1000 → 写 BattleAction
  /// → 死亡 / 胜负判定 → 阴柔克灵巧 refresh internalInjury slot on defender。
  static BattleState _resolveAction(
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

    final (skill, targetId) = BattleAI.decide(preActor, preState, n);
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
    final targetAfter = target.copyWith(
      currentHp: newTargetHp,
      isAlive: newTargetHp > 0,
      internalInjury: newInjury,
    );

    // 攻方扣内力 + 写 CD + actionPoint -= 1000（保留余数）
    final newCd = Map<String, int>.from(preActor.skillCooldowns);
    if (skill.cooldownTurns > 0) {
      newCd[skill.id] = skill.cooldownTurns;
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
      description: _formatAction(actorAfter, targetAfter, skill, result),
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

  static void _replaceById(List<BattleCharacter> team, BattleCharacter c) {
    for (var i = 0; i < team.length; i++) {
      if (team[i].characterId == c.characterId) {
        team[i] = c;
        return;
      }
    }
  }

  /// 战斗内伤害计算（不依赖 Isar 实体，全部读 BattleCharacter 快照字段）。
  ///
  /// 公式与 [DamageCalculator.calculate] 完全一致（GDD §5.3-§5.5），只是字段
  /// 口径不同：内力用 `currentInternalForce`（战斗中扣过）、装备攻击用
  /// `totalEquipmentAttack` 缓存、修炼度从 `mainCultivationLayer` 查表。
  static AttackResult _calculateInBattle({
    required BattleCharacter attacker,
    required BattleCharacter defender,
    required SkillDef skill,
    required NumbersConfig n,
    required Random rng,
    bool forceCritical = false,
  }) {
    final evasion = defender.evasionRate;
    if (rng.nextDouble() < evasion) {
      return AttackResult.dodged(
        evasionRate: evasion,
        breakdown: 'DODGED (evasion=${_fmt(evasion)})',
      );
    }

    final df = n.combat.damageFormula;
    final atkIF = attacker.currentInternalForce;
    final eqAtk = attacker.totalEquipmentAttack;
    final base = atkIF * df.internalForceFactor +
        eqAtk * df.equipmentAttackFactor +
        skill.powerMultiplier;

    final cultMult = n.cultivationMultiplier[attacker.mainCultivationLayer];
    if (cultMult == null) {
      throw StateError(
        'numbers.yaml techniques.cultivation.layers 缺 '
        '${attacker.mainCultivationLayer.name} 的 bonus_multiplier',
      );
    }

    final schoolMult =
        n.schoolCounter.multiplierFor(attacker.school, defender.school);
    final extraEffect =
        n.schoolCounter.extraEffectFor(attacker.school, defender.school);

    final isCritical = forceCritical || rng.nextDouble() < attacker.criticalRate;
    final critMult = isCritical
        ? (attacker.school == TechniqueSchool.lingQiao
            ? n.combat.critical.lingqiaoDamageMultiplier
            : n.combat.critical.baseDamageMultiplier)
        : 1.0;

    // W18-A1.2 改用 defender.defenseRate(BattleCharacter view layer 缓存),
    // 既覆盖 numbers.yaml realm 派生 base 值,也叠加相生 defensePct 注入
    // (StageBattleSetup.applySynergy 加法注入,clamp ≤ 0.95)。
    final defRate = defender.defenseRate;
    final defMult = 1.0 - defRate;

    final atkLevel = RealmUtils.absoluteLevelOf(
      attacker.realmTier,
      attacker.realmLayer,
    );
    final defLevel = RealmUtils.absoluteLevelOf(
      defender.realmTier,
      defender.realmLayer,
    );
    final tierDiff = attacker.realmTier.index - defender.realmTier.index;
    final mods = RealmUtils.realmDiffModifier(
      attacker.realmTier,
      defender.realmTier,
    );
    final realmAttackerMod = mods.$1;
    final realmDefenderMod = mods.$2;
    final double realmMult;
    if (tierDiff > 0) {
      realmMult = realmAttackerMod;
    } else if (tierDiff < 0) {
      realmMult = realmDefenderMod;
    } else {
      realmMult = 1.0;
    }

    final raw =
        base * cultMult * schoolMult * critMult * defMult * realmMult;
    final mainDamage = raw.toInt();

    // 刚猛克阴柔附带震伤(§12.1 #7 v1.4):穿透防御不暴击,与主伤害同 tick 叠加。
    var quakeDamage = 0;
    if (attacker.school == TechniqueSchool.gangMeng &&
        defender.school == TechniqueSchool.yinRou) {
      quakeDamage = n.schoolCounter.gangMengQuake.damage;
    }
    final finalDamage = mainDamage + quakeDamage;

    final effects = <String>[];
    if (extraEffect != null) effects.add(extraEffect);

    final breakdown = '($atkIF*${_fmt(df.internalForceFactor)}'
        ' + $eqAtk + ${skill.powerMultiplier})'
        ' * ${_fmt(cultMult)} * ${_fmt(schoolMult)} * ${_fmt(critMult)}'
        ' * ${_fmt(defMult)} * ${_fmt(realmMult)}'
        ' = $mainDamage'
        '${quakeDamage > 0 ? ' + 震伤 $quakeDamage = $finalDamage' : ''}'
        ' [atkLv=$atkLevel,defLv=$defLevel]';

    return AttackResult(
      finalDamage: finalDamage,
      mainDamage: mainDamage,
      quakeDamage: quakeDamage,
      isCritical: isCritical,
      isDodged: false,
      schoolCounterMultiplier: schoolMult,
      realmDiffAttackerMod: realmAttackerMod,
      realmDiffDefenderMod: realmDefenderMod,
      cultivationMultiplier: cultMult,
      criticalMultiplier: critMult,
      defenseRate: defRate,
      evasionRate: evasion,
      appliedEffects: effects,
      formulaBreakdown: breakdown,
    );
  }

  /// 调试日志描述串（T13 才正式做中文化，本阶段简化）。
  static String _formatAction(
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

  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(1);
    return v.toString();
  }
}
