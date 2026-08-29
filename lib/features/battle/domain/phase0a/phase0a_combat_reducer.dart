import 'dart:math' as math;

import '../../../../core/domain/enums.dart';
import '../../../../data/defs/boss_phase_def.dart';
import '../../../../data/defs/skill_def.dart';
import '../../../boss_gauntlet/domain/qi_drain_effect.dart';
import 'arena_vector.dart';
import 'basic_attack_chain.dart';
import 'basic_attack_geometry_registry.dart';
import 'combat_geometry.dart';
import 'defense_resolution.dart';
import 'phase0a_combat_events.dart';
import 'phase0a_combat_intent.dart';
import 'phase0a_combat_model.dart';
import 'phase0a_damage_kind.dart';
import 'realtime_combat_rules.dart';
import 'posture.dart';
import 'status_effects.dart';

export 'phase0a_damage_kind.dart';

const _noBreakPower = 0;

/// 一次结算的运行时结果:命中与否、暴击与否、伤害值全部由
/// resolver(未来生产接 DamageCalculator)给出,reducer 不写第二套公式。
final class Phase0aResolvedHit {
  const Phase0aResolvedHit({
    required this.isHit,
    required this.isCritical,
    required this.damage,
    this.appliedStatus,
  });

  final bool isHit;
  final bool isCritical;
  final int damage;

  /// Optional typed status already resolved by the production damage adapter.
  /// The reducer owns application/refresh/ticking; it never derives balance.
  final TimedStatusSpec? appliedStatus;
}

/// 显式注入的伤害结算接口。本片测试用固定实现;
/// 未来生产在同一接口上接 `DamageCalculator`,adapter/reducer 禁写公式。
///
/// [defenderStaggered]:守方处于破招踉跄窗口(reducer 运行态事实)。
/// 减防幅度由生产 adapter 读 numbers.combat.bossCharge 应用,reducer 只传
/// 状态不写数值;测试实现可忽略(默认 false 口径)。
///
/// [defenderVulnerable] comes from the authoritative posture state. The
/// production adapter uses it to select the existing vulnerability multiplier.
abstract interface class Phase0aDamageResolver {
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    required double defenderWardMult,
  });
}

/// Optional production extension for enemy skills whose identity cannot be
/// represented by the fixed player hotkey damage kinds.
abstract interface class Phase0aEnemySkillDamageResolver {
  Phase0aResolvedHit resolveEnemySkill({
    required String attackerId,
    required String targetId,
    required SkillDef skill,
    bool defenderStaggered = false,
  });
}

/// 一拍结算输出:新状态 + 本拍事件(已按发射顺序排好,seq 单调)。
final class Phase0aStepResult {
  const Phase0aStepResult({required this.state, required this.events});

  final Phase0aArenaState state;
  final List<Phase0aEvent> events;
}

/// Resolves only the position/facing contribution of a move intent.
///
/// Encounter objective projection reuses this exact function so checkpoint
/// attribution cannot accidentally include attack or defense displacement.
Phase0aActor resolvePhase0aMovement({
  required Phase0aActor actor,
  required ArenaVector direction,
  required double deltaSeconds,
}) {
  if (!(deltaSeconds.isFinite && deltaSeconds >= 0)) {
    throw ArgumentError.value(
      deltaSeconds,
      'deltaSeconds',
      'must be finite and non-negative',
    );
  }
  final step = direction.lengthSquared > 0
      ? direction.normalized()
      : ArenaVector.zero;
  return actor.copyWith(
    position: actor.position + step * (actor.moveSpeed * deltaSeconds),
    facing: step.lengthSquared > 0 ? step : actor.facing,
  );
}

/// Phase 0A 确定性结算核:单角色玩家对多敌,同一入口消费玩家与 AI
/// 的同型 intent。给定相同初态与相同输入序列必得相等状态与事件序列。
///
/// 时序:① 拍号 +1,普攻冷却与技能冷却扣减(clamp 零)、可用态迁移事件;
/// ② intent 按 actorId 稳定排序逐一结算(移动/普攻/Q/R);
/// ③ 被击败敌方单位当拍移除,其后事件不再引用。
Phase0aStepResult reducePhase0aTick({
  required Phase0aArenaState state,
  required List<Phase0aIntent> intents,
  required double deltaSeconds,
  required Phase0aDamageResolver damageResolver,
  Phase0aEnemySkillDamageResolver? enemySkillDamageResolver,
}) {
  // 拍长必须有限且非负:负值会让冷却反增/位移反向,NaN 会绕过一切比较。
  if (!(deltaSeconds.isFinite && deltaSeconds >= 0)) {
    throw ArgumentError.value(
      deltaSeconds,
      'deltaSeconds',
      'must be finite and non-negative',
    );
  }
  final tick = state.tick + 1;
  var seq = state.nextSeq;
  final events = <Phase0aEvent>[];

  var player = state.player.copyWith(
    attackCooldownRemaining: _cooldownAfter(
      state.player.attackCooldownRemaining,
      deltaSeconds,
    ),
    defenseCooldownRemaining: _cooldownAfter(
      state.player.defenseCooldownRemaining,
      deltaSeconds,
    ),
    shieldTicksRemaining: state.player.shieldTicksRemaining > 0
        ? state.player.shieldTicksRemaining - 1
        : 0,
    shieldRemaining: state.player.shieldTicksRemaining > 1
        ? state.player.shieldRemaining
        : 0,
    parryTicksRemaining: state.player.parryTicksRemaining > 0
        ? state.player.parryTicksRemaining - 1
        : 0,
    parryCounterBudgetRemaining: state.player.parryTicksRemaining > 1
        ? state.player.parryCounterBudgetRemaining
        : 0,
    dodgeTicksRemaining: state.player.dodgeTicksRemaining > 0
        ? state.player.dodgeTicksRemaining - 1
        : 0,
  );

  final enemiesById = <String, Phase0aActor>{
    for (final enemy in state.enemies)
      enemy.id: enemy.copyWith(
        attackCooldownRemaining: _cooldownAfter(
          enemy.attackCooldownRemaining,
          deltaSeconds,
        ),
        enemySkillCooldowns: _cooldownsAfter(
          enemy.enemySkillCooldowns,
          deltaSeconds,
        ),
      ),
  };

  void emitPostureTransition({
    required String actorId,
    required Phase0aActor target,
    required PostureTransition transition,
    PostureHitKind? hitKind,
  }) {
    for (final postureEvent in transition.events) {
      events.add(
        Phase0aPostureChanged(
          seq: seq++,
          tick: tick,
          actor: actorId,
          target: target.id,
          eventType: postureEvent.type,
          amount: postureEvent.amount,
          accumulated: transition.state.accumulated,
          capacity: transition.state.config.capacity,
          vulnerabilityTicksRemaining:
              transition.state.vulnerabilityTicksRemaining,
          hitKind: hitKind,
          targetPosition: target.position,
        ),
      );
    }
  }

  ({Phase0aActor actor, bool vulnerabilityEntered}) applyPostureDamage({
    required String actorId,
    required Phase0aActor target,
    required double postureDamage,
    required PostureHitKind hitKind,
    required int breakPower,
    required bool isHit,
  }) {
    final posture = target.posture;
    if (!isHit || !target.isAlive || posture == null) {
      return (actor: target, vulnerabilityEntered: false);
    }
    var totalDamage = postureDamage;
    if (target.isBoss &&
        target.chargingCast != null &&
        hitKind == PostureHitKind.bossControl &&
        breakPower > 0) {
      totalDamage += bossControlToPostureDamage(
        breakPower.toDouble(),
        conversionFactor: posture.config.bossControlConversionFactor,
      );
    }
    final transition = posture.apply(totalDamage, hitKind: hitKind);
    emitPostureTransition(
      actorId: actorId,
      target: target,
      transition: transition,
      hitKind: hitKind,
    );
    final vulnerabilityEntered = transition.events.any(
      (event) => event.type == PostureEventType.vulnerabilityEntered,
    );
    var updated = target.copyWith(posture: transition.state);
    if (!vulnerabilityEntered) {
      return (actor: updated, vulnerabilityEntered: false);
    }
    final cast = updated.chargingCast;
    if (cast == null) {
      return (
        actor: updated.copyWith(
          staggerTicksRemaining: updated.staggerTicksTotal,
        ),
        vulnerabilityEntered: true,
      );
    }
    final cooldowns = Map<String, double>.from(updated.enemySkillCooldowns);
    final cooldownSeconds = cast.cooldownSeconds > 0
        ? cast.cooldownSeconds
        : cast.actionCooldownSeconds;
    if (cooldownSeconds > 0) {
      cooldowns[cast.skill.id] = cooldownSeconds;
    }
    updated = updated.copyWith(
      clearChargingCast: true,
      chargeTicksRemaining: _noChargeTicksRemaining,
      staggerTicksRemaining: updated.staggerTicksTotal,
      enemySkillCooldowns: Map.unmodifiable(cooldowns),
    );
    return (actor: updated, vulnerabilityEntered: true);
  }

  for (final enemy in state.enemies) {
    final current = enemiesById[enemy.id]!;
    final posture = current.posture;
    if (posture == null) continue;
    final transition = posture.advance(1);
    if (transition.state != posture) {
      enemiesById[enemy.id] = current.copyWith(posture: transition.state);
    }
    emitPostureTransition(
      actorId: enemy.id,
      target: current,
      transition: transition,
    );
  }

  double defenderWardMultFor(
    Phase0aActor target,
    Map<String, Phase0aActor> defenderState,
  ) {
    final wardMult = target.guardianWardMult;
    if (wardMult == null || target.guardianDefIds.isEmpty) return 1.0;
    final guardianAlive = target.guardianDefIds.any(
      (guardianId) => defenderState.values.any(
        (candidate) =>
            candidate.isAlive &&
            (candidate.id == guardianId ||
                candidate.id.startsWith('${guardianId}_w')),
      ),
    );
    return guardianAlive ? wardMult : 1.0;
  }

  // 蓄力/踉跄 pre-step(对齐旧引擎「踉跄判定必须先于蓄力」序):
  // 踉跄中 → 本拍压制并递减(蓄力冻结);否则蓄力中 → 本拍压制并递减,
  // 归零者登记拍尾释放招牌技。压制 = 移动/普攻/技能 intent 全拒收。
  // [staggeredActorIds] 记录拍初踉跄事实(递减在先,伤害结算在后,
  // 减防窗口必须与压制窗口同拍界)。
  final suppressedActorIds = <String>{};
  final staggeredActorIds = <String>{};
  final chargeFireActorIds = <String>[];
  for (final enemy in state.enemies) {
    final current = enemiesById[enemy.id]!;
    if (current.staggerTicksRemaining > 0) {
      suppressedActorIds.add(enemy.id);
      staggeredActorIds.add(enemy.id);
      enemiesById[enemy.id] = current.copyWith(
        staggerTicksRemaining: current.staggerTicksRemaining - 1,
      );
    } else if (current.chargeTicksRemaining > 0) {
      suppressedActorIds.add(enemy.id);
      final remaining = current.chargeTicksRemaining - 1;
      enemiesById[enemy.id] = current.copyWith(chargeTicksRemaining: remaining);
      if (remaining == 0) chargeFireActorIds.add(enemy.id);
    }
  }

  final slots = <Phase0aSkillSlot>[];
  for (final slot in state.skillSlots) {
    final cooldownRemaining = _cooldownAfter(
      slot.cooldownRemaining,
      deltaSeconds,
    );
    final availability = availabilityOf(
      cooldownRemaining: cooldownRemaining,
      qiCurrent: player.qiCurrent,
      qiCost: slot.qiCost,
    );
    slots.add(
      slot.copyWith(
        cooldownRemaining: cooldownRemaining,
        availability: availability,
      ),
    );
    if (availability != slot.availability) {
      events.add(
        Phase0aSkillAvailabilityChanged(
          seq: seq++,
          tick: tick,
          slot: slot.slot,
          availability: availability,
          cooldownRemaining: availability == Phase0aSkillAvailability.cooldown
              ? cooldownRemaining
              : null,
          qiCurrent: player.qiCurrent,
          qiRequired: slot.qiCost,
        ),
      );
    }
  }

  /// 唯一入站攻击消费点。它先走主动闪避/化解/护盾，再落账 HP，最后
  /// 直接写入标准化反击；反击不再调用本函数，故不会递归。
  void settleInbound({
    required Phase0aActor attacker,
    required Phase0aActor target,
    required Phase0aResolvedHit resolved,
    required AttackDefenseFlags? defenseFlags,
    required String attackId,
    required Phase0aMoveKind moveKind,
    required bool isUltimate,
    required double postureDamage,
    required PostureHitKind postureHitKind,
    required int breakPower,
    BasicAttackSegment? basicAttackSegment,
  }) {
    if (!resolved.isHit) return;
    DefenseResult? defense;
    if (target.side == Phase0aSide.player && defenseFlags != null) {
      final currentPlayer = player;
      defense = resolveDefense(
        DefenseInput(
          flags: defenseFlags,
          incomingHpDamage: _checkedDamage(resolved).toDouble(),
          incomingPostureDamage: 0,
          dodgeSucceeded: currentPlayer.dodgeTicksRemaining > 0,
          parrySucceeded: currentPlayer.parryTicksRemaining > 0,
          redirectSucceeded: false,
          blockSucceeded: false,
          shieldAbsorption: currentPlayer.shieldRemaining,
          blockDamageMultiplier: 1,
          baseMitigationFraction: 0,
          counterDamage: currentPlayer.parryCounterDamage,
          counterUpperBound: currentPlayer.parryCounterBudgetRemaining,
        ),
      );
      final nextShield = defense.branch == DefenseBranch.blockOrShield
          ? defense.shieldRemaining
          : currentPlayer.shieldRemaining;
      final nextBudget = defense.branch == DefenseBranch.parry
          ? (currentPlayer.parryCounterBudgetRemaining - defense.counterDamage)
                .clamp(0.0, double.infinity)
                .toDouble()
          : currentPlayer.parryCounterBudgetRemaining;
      player = currentPlayer.copyWith(
        shieldRemaining: nextShield,
        shieldTicksRemaining: nextShield > 0
            ? currentPlayer.shieldTicksRemaining
            : 0,
        parryCounterBudgetRemaining: nextBudget,
      );
      final counter = _checkedCounter(defense.counterDamage);
      if (counter > 0 && attacker.side == Phase0aSide.enemy) {
        final counterRemaining = math.max(0, attacker.currentHealth - counter);
        final counterUpdated = attacker.copyWith(
          currentHealth: counterRemaining,
        );
        if (counterUpdated.isAlive) {
          enemiesById[attacker.id] = counterUpdated;
        } else {
          enemiesById.remove(attacker.id);
          events.add(
            Phase0aEnemyDefeated(
              seq: seq++,
              tick: tick,
              target: attacker.id,
              defeatKind: attacker.defeatKind,
              targetPosition: attacker.position,
            ),
          );
        }
      }
      events.add(
        Phase0aDefenseResolved(
          seq: seq++,
          tick: tick,
          attackId: attackId,
          attacker: attacker.id,
          target: target.id,
          branch: defense.branch,
          incomingDamage: defense.incomingHpDamage.round(),
          counterDamage: counter,
          shieldRemaining: nextShield.round(),
          nonRecursive: defense.nonRecursive,
          targetPosition: target.position,
        ),
      );
    }
    // An active dodge is a resolved attack outcome, so emit HitLanded with
    // zero final damage for the canonical attack timeline. A passive miss
    // returned above without this event and remains semantically distinct.
    final damage = defense == null
        ? _checkedDamage(resolved)
        : defense.incomingHpDamage.round();
    final remaining = math.max(0, target.currentHealth - damage);
    events.add(
      Phase0aHitLanded(
        seq: seq++,
        tick: tick,
        actor: attacker.id,
        target: target.id,
        moveKind: moveKind,
        isCritical: defense == null && resolved.isCritical,
        isUltimate: isUltimate,
        resolvedDamage: damage,
        remainingHealth: remaining,
        actorPosition: attacker.position,
        targetPosition: target.position,
        basicAttackSegment: basicAttackSegment,
      ),
    );
    var updated = target.copyWith(currentHealth: remaining);
    updated = applyPostureDamage(
      actorId: attacker.id,
      target: updated,
      postureDamage: postureDamage,
      hitKind: postureHitKind,
      breakPower: breakPower,
      isHit: resolved.isHit,
    ).actor;
    final appliedStatus = resolved.appliedStatus;
    final statusFollowsHit =
        appliedStatus != null && defense?.branch != DefenseBranch.dodge;
    Phase0aActor applyStatus(Phase0aActor actor) {
      if (!statusFollowsHit || !actor.isAlive) return actor;
      if (appliedStatus.sourceId != attacker.id ||
          (appliedStatus.type != TimedStatusType.internalInjury &&
              appliedStatus.type != TimedStatusType.poison) ||
          appliedStatus.damagePerTick == null) {
        throw StateError('Phase0a received an invalid resolved damage status');
      }
      final ledger = TimedStatusLedger.fromSnapshot(actor.statusLedger)
        ..apply(appliedStatus);
      return actor.copyWith(statusLedger: ledger.snapshot);
    }

    if (target.side == Phase0aSide.enemy) {
      updated = applyStatus(updated);
      if (!updated.isAlive) {
        enemiesById.remove(target.id);
        events.add(
          Phase0aEnemyDefeated(
            seq: seq++,
            tick: tick,
            target: target.id,
            defeatKind: target.defeatKind,
            targetPosition: updated.position,
          ),
        );
      } else {
        final advanced = _advanceBossPhases(
          actor: updated,
          tick: tick,
          seq: seq,
          events: events,
        );
        enemiesById[target.id] = advanced.actor;
        seq = advanced.nextSeq;
      }
    } else {
      player = applyStatus(player.copyWith(currentHealth: remaining));
    }
  }

  final statusActors = <Phase0aActor>[player, ...enemiesById.values]
    ..sort((left, right) => left.id.compareTo(right.id));
  for (final actorSnapshot in statusActors) {
    final current = actorSnapshot.side == Phase0aSide.player
        ? player
        : enemiesById[actorSnapshot.id];
    if (current == null || !current.isAlive) continue;
    if (current.statusLedger.instances.isEmpty) continue;
    final ledger = TimedStatusLedger.fromSnapshot(current.statusLedger);
    final advance = ledger.advance(1);
    var updated = current.copyWith(statusLedger: ledger.snapshot);
    for (final damage in advance.damages) {
      if (damage.amount <= 0) continue;
      if (damage.type != TimedStatusType.internalInjury &&
          damage.type != TimedStatusType.poison) {
        throw StateError(
          'Phase0a reducer received damage from non-damage status '
          '${damage.type.name}',
        );
      }
      final remaining = math.max(0, updated.currentHealth - damage.amount);
      events.add(
        Phase0aStatusDamageApplied(
          seq: seq++,
          tick: tick,
          source: damage.sourceId,
          target: updated.id,
          statusType: damage.type,
          resolvedDamage: damage.amount,
          remainingHealth: remaining,
          targetPosition: updated.position,
        ),
      );
      updated = updated.copyWith(currentHealth: remaining);
      if (!updated.isAlive) break;
    }
    if (updated.side == Phase0aSide.player) {
      player = updated;
    } else if (updated.isAlive) {
      enemiesById[updated.id] = updated;
    } else {
      enemiesById.remove(updated.id);
      events.add(
        Phase0aEnemyDefeated(
          seq: seq++,
          tick: tick,
          target: updated.id,
          defeatKind: updated.defeatKind,
          targetPosition: updated.position,
        ),
      );
    }
  }

  final ordered = _stableOrderByActor(intents);
  final attackIntentsByActor = <String, Phase0aAttackIntent>{};
  for (final intent in ordered) {
    if (intent is Phase0aAttackIntent) {
      attackIntentsByActor.putIfAbsent(intent.actorId, () => intent);
    }
  }
  var defenseConsumed = false;
  for (final intent in ordered) {
    if (intent is! Phase0aDefenseIntent ||
        intent.actorId != player.id ||
        defenseConsumed ||
        player.defenseCooldownRemaining > 0 ||
        !_validDefenseIntent(intent)) {
      continue;
    }
    final direction = intent.direction.lengthSquared > 0
        ? intent.direction.normalized()
        : player.facing;
    final from = player.position;
    switch (intent.action) {
      case Phase0aDefenseAction.shield:
        if (intent.shieldAbsorption <= 0 || intent.shieldDurationTicks <= 0) {
          continue;
        }
        player = player.copyWith(
          shieldRemaining: intent.shieldAbsorption,
          shieldTicksRemaining: intent.shieldDurationTicks,
          parryTicksRemaining: 0,
          dodgeTicksRemaining: 0,
          parryCounterDamage: 0,
          parryCounterBudgetRemaining: 0,
          defenseCooldownRemaining: intent.cooldownSeconds,
        );
      case Phase0aDefenseAction.parry:
        if (intent.parryWindowTicks <= 0 ||
            intent.counterDamage <= 0 ||
            intent.counterUpperBound <= 0) {
          continue;
        }
        player = player.copyWith(
          shieldRemaining: 0,
          shieldTicksRemaining: 0,
          parryTicksRemaining: intent.parryWindowTicks,
          dodgeTicksRemaining: 0,
          parryCounterDamage: intent.counterDamage,
          parryCounterBudgetRemaining: intent.counterUpperBound,
          defenseCooldownRemaining: intent.cooldownSeconds,
        );
      case Phase0aDefenseAction.dodge:
        if (intent.dodgeIframeTicks <= 0 || intent.dodgeDistance <= 0) {
          continue;
        }
        player = player.copyWith(
          position: from + direction * intent.dodgeDistance,
          facing: direction,
          shieldRemaining: 0,
          shieldTicksRemaining: 0,
          parryTicksRemaining: 0,
          dodgeTicksRemaining: intent.dodgeIframeTicks,
          parryCounterDamage: 0,
          parryCounterBudgetRemaining: 0,
          defenseCooldownRemaining: intent.cooldownSeconds,
        );
    }
    defenseConsumed = true;
    final windowTicks = switch (intent.action) {
      Phase0aDefenseAction.shield => intent.shieldDurationTicks,
      Phase0aDefenseAction.parry => intent.parryWindowTicks,
      Phase0aDefenseAction.dodge => intent.dodgeIframeTicks,
    };
    events.add(
      Phase0aDefenseStarted(
        seq: seq++,
        tick: tick,
        actor: player.id,
        action: intent.action,
        fromPosition: from,
        toPosition: player.position,
        windowTicks: windowTicks,
        shieldAbsorption: player.shieldRemaining,
      ),
    );
  }
  final consumedIntentActorIds = <String>{};
  for (final intent in ordered) {
    final actorId = intent.actorId;
    if (consumedIntentActorIds.contains(actorId)) continue;
    final isPlayer = actorId == player.id;
    final actor = isPlayer ? player : enemiesById[actorId];
    if (actor == null || !actor.isAlive) continue;
    // A committed active defense owns the player's action budget for this
    // tick. Movement remains allowed so dodge direction is deterministic;
    // attacks and skills in the same command are rejected fail-closed.
    if (isPlayer &&
        defenseConsumed &&
        intent is! Phase0aDefenseIntent &&
        intent is! Phase0aMoveIntent) {
      continue;
    }
    // 蓄力/踉跄压制(reducer 权威:AI 停发之外的第二道闸,禁绕状态行动)。
    if (suppressedActorIds.contains(actorId)) continue;
    // 同一 intent 的多目标结算共享行动前敌方快照：目标顺序不得让先阵亡的
    // 护法在同一招内提前解除 Boss ward/破招拦截（对齐旧引擎 AOE 口径）。
    final preIntentEnemies = Map<String, Phase0aActor>.unmodifiable(
      Map.of(enemiesById),
    );

    switch (intent) {
      case Phase0aDefenseIntent():
        continue;
      case Phase0aMoveIntent(:final direction):
        final pairedAttack = attackIntentsByActor[actorId];
        if (isPlayer &&
            !defenseConsumed &&
            pairedAttack != null &&
            _willCommitBasicAttackAdvance(actor: actor, intent: pairedAttack)) {
          continue;
        }
        final moved = resolvePhase0aMovement(
          actor: actor,
          direction: direction,
          deltaSeconds: deltaSeconds,
        );
        if (isPlayer) {
          player = moved;
        } else {
          enemiesById[actorId] = moved;
        }
      case Phase0aAttackIntent():
        // 非法数值(负/NaN/Infinity)静默拒绝:平方会掩盖负射程,
        // 负冷却等价无冷却。
        if (!_isUsableNumber(intent.range) ||
            !_isUsableNumber(intent.halfArcRadians) ||
            !_isUsableNumber(intent.cooldownSeconds) ||
            !_isUsableNumber(intent.postureDamage)) {
          continue;
        }
        if (actor.attackCooldownRemaining > 0) continue;
        final basicAttackChain = isPlayer ? intent.basicAttackChain : null;
        final basicAttackSegment = basicAttackChain?.segmentAt(
          actor.basicAttackSegmentIndex % basicAttackChain.segments.length,
        );
        final geometryRegistry = intent.basicAttackGeometryRegistry;
        BasicAttackGeometryTuning? segmentTuning;
        List<CombatGeometryTarget> selectedGeometryTargets = const [];
        var resolvedAimDirection = intent.aimDirection;
        var attackActor = actor;
        if (basicAttackSegment != null) {
          if (geometryRegistry == null) {
            throw StateError('basic attack chain requires a geometry registry');
          }
          segmentTuning = geometryRegistry.tuningFor(basicAttackSegment);
          resolvedAimDirection = geometryRegistry.resolveAimDirection(
            segment: basicAttackSegment,
            origin: actor.position,
            inputDirection: intent.aimDirection,
            candidates: [
              for (final target in _opposingTargets(
                casterSide: actor.side,
                player: player,
                enemiesById: enemiesById,
              ))
                if (!_isGuardedBoss(target, enemiesById))
                  BasicAttackAimCandidate(target.id, target.position),
            ],
          );
          final geometryCandidates = [
            for (final target in _opposingTargets(
              casterSide: actor.side,
              player: player,
              enemiesById: enemiesById,
            ))
              if (!_isGuardedBoss(target, enemiesById))
                CombatGeometryTarget(target.id, target.position),
          ];
          selectedGeometryTargets = geometryRegistry
              .scopeFor(
                segment: basicAttackSegment,
                origin: actor.position,
                direction: resolvedAimDirection,
              )
              .hitTargets(geometryCandidates);
          if (segmentTuning.advanceDistance > 0) {
            final bounds = intent.basicAttackArenaBounds;
            if (bounds == null) {
              throw StateError('advancing basic attack requires arena bounds');
            }
            attackActor = actor.copyWith(
              position: resolveBasicAttackAdvance(
                origin: actor.position,
                direction: resolvedAimDirection,
                distance: segmentTuning.advanceDistance,
                stopTarget: selectedGeometryTargets.isEmpty
                    ? null
                    : selectedGeometryTargets.first,
                bounds: bounds,
              ),
            );
            if (isPlayer) {
              player = attackActor;
            } else {
              enemiesById[actorId] = attackActor;
            }
          }
        }
        final coop = _guardianCoopContext(
          actor: actor,
          enemiesById: enemiesById,
          attackIntentsByActor: attackIntentsByActor,
          player: player,
          suppressedActorIds: suppressedActorIds,
        );
        if (coop != null) {
          final mainIntent = attackIntentsByActor[actor.id]!;
          final partnerIntent = attackIntentsByActor[coop.partner.id]!;
          final mainHit = damageResolver.resolve(
            attackerId: actor.id,
            targetId: player.id,
            kind: Phase0aDamageKind.basic,
            defenderVulnerable: player.posture?.isVulnerable ?? false,
            defenderWardMult: 1.0,
          );
          final partnerHit = damageResolver.resolve(
            attackerId: coop.partner.id,
            targetId: player.id,
            kind: Phase0aDamageKind.basic,
            defenderVulnerable: player.posture?.isVulnerable ?? false,
            defenderWardMult: 1.0,
          );
          final mainDamage = mainHit.isHit ? _checkedDamage(mainHit) : 0;
          final partnerDamage = partnerHit.isHit
              ? _checkedDamage(partnerHit)
              : 0;
          final rawTotalDamage = mainDamage + partnerDamage;
          final defenseFlags =
              mainIntent.defenseFlags ?? partnerIntent.defenseFlags;
          var totalDamage = rawTotalDamage;
          if (defenseFlags != null && rawTotalDamage > 0) {
            final healthBeforeDefense = player.currentHealth;
            settleInbound(
              attacker: actor,
              target: player,
              resolved: Phase0aResolvedHit(
                isHit: true,
                isCritical: mainHit.isCritical || partnerHit.isCritical,
                damage: rawTotalDamage,
              ),
              defenseFlags: defenseFlags,
              attackId: '${actor.id}:$tick:${player.id}:guardian_coop',
              moveKind: Phase0aMoveKind.light,
              isUltimate: false,
              postureDamage:
                  mainIntent.postureDamage + partnerIntent.postureDamage,
              postureHitKind: PostureHitKind.light,
              breakPower: _noBreakPower,
            );
            totalDamage = healthBeforeDefense - player.currentHealth;
          } else {
            player = player.copyWith(
              currentHealth: math.max(0, player.currentHealth - rawTotalDamage),
            );
          }
          events.add(
            Phase0aGuardianCoopStrike(
              seq: seq++,
              tick: tick,
              mainGuardian: actor.id,
              partner: coop.partner.id,
              boss: coop.boss.id,
              target: player.id,
              mainGuardianDamage: mainDamage,
              mainGuardianCritical: mainHit.isHit && mainHit.isCritical,
              totalDamage: totalDamage,
              mainGuardianPosition: actor.position,
              partnerPosition: coop.partner.position,
              bossPosition: coop.boss.position,
              targetPosition: player.position,
            ),
          );
          final currentMain = enemiesById[actor.id];
          if (currentMain != null) {
            enemiesById[actor.id] = currentMain.copyWith(
              attackCooldownRemaining: mainIntent.cooldownSeconds,
              facing: mainIntent.aimDirection.lengthSquared > 0
                  ? mainIntent.aimDirection.normalized()
                  : currentMain.facing,
              qiCurrent: (currentMain.qiCurrent + mainIntent.qiDelta).clamp(
                0,
                currentMain.qiMax,
              ),
            );
          }
          final currentPartner = enemiesById[coop.partner.id];
          if (currentPartner != null) {
            enemiesById[coop.partner.id] = currentPartner.copyWith(
              attackCooldownRemaining: partnerIntent.cooldownSeconds,
              facing: partnerIntent.aimDirection.lengthSquared > 0
                  ? partnerIntent.aimDirection.normalized()
                  : currentPartner.facing,
              qiCurrent: (currentPartner.qiCurrent + partnerIntent.qiDelta)
                  .clamp(0, currentPartner.qiMax),
            );
          }
          enemiesById[coop.boss.id] = coop.boss.copyWith(
            guardianCoopUsedInCharge: true,
          );
          consumedIntentActorIds.add(coop.partner.id);
          continue;
        }
        events.add(
          Phase0aAttackStarted(
            seq: seq++,
            tick: tick,
            actor: actorId,
            moveKind: intent.moveKind,
            basicAttackSegment: basicAttackSegment,
          ),
        );
        final targets = basicAttackSegment == null
            ? [
                ?_selectStrikeTarget(
                  attacker: attackActor,
                  player: player,
                  enemiesById: enemiesById,
                  aimDirection: resolvedAimDirection,
                  range: intent.range,
                  halfArcRadians: intent.halfArcRadians,
                ),
              ]
            : selectedGeometryTargets
                  .map(
                    (match) => attackActor.side == Phase0aSide.player
                        ? enemiesById[match.id]!
                        : player,
                  )
                  .toList(growable: false);
        for (final target in targets) {
          final resolved = damageResolver.resolve(
            attackerId: actorId,
            targetId: target.id,
            kind: Phase0aDamageKind.basic,
            defenderStaggered:
                staggeredActorIds.contains(target.id) ||
                target.staggerTicksRemaining > 0,
            defenderVulnerable: target.posture?.isVulnerable ?? false,
            defenderWardMult: defenderWardMultFor(target, preIntentEnemies),
          );
          settleInbound(
            attacker: attackActor,
            target: target,
            resolved: resolved,
            defenseFlags: intent.defenseFlags,
            attackId: '$actorId:$tick:${target.id}',
            moveKind: intent.moveKind,
            isUltimate: false,
            postureDamage: intent.postureDamage,
            postureHitKind: intent.postureHitKind,
            breakPower: _noBreakPower,
            basicAttackSegment: basicAttackSegment,
          );
        }
        final aimDirection = resolvedAimDirection.lengthSquared > 0
            ? resolvedAimDirection.normalized()
            : attackActor.facing;
        final currentAttacker = isPlayer ? player : enemiesById[actorId];
        if (currentAttacker == null) continue;
        final recharged = currentAttacker.copyWith(
          attackCooldownRemaining: intent.cooldownSeconds,
          facing: aimDirection,
          qiCurrent: (attackActor.qiCurrent + intent.qiDelta).clamp(
            0,
            attackActor.qiMax,
          ),
          basicAttackSegmentIndex: basicAttackChain == null
              ? currentAttacker.basicAttackSegmentIndex
              : (actor.basicAttackSegmentIndex + 1) %
                    basicAttackChain.segments.length,
        );
        if (isPlayer) {
          player = recharged;
        } else {
          enemiesById[actorId] = recharged;
        }
      case Phase0aEnemySkillIntent():
        if (actor.side != Phase0aSide.enemy ||
            enemySkillDamageResolver == null ||
            intent.skill.id.isEmpty) {
          continue;
        }
        // 起手蓄力入口(顶层 chargeSkillId):AI 选中招牌技时不直接释放,
        // 改为进入蓄力态——本拍无伤害、不上 CD、不耗真气(真气在倒计时
        // 归零释放时结算,对齐旧引擎)。charge profile 即闸门,故此分支
        // 旁路 unlockedEnemySkillIds 门。
        final topChargeCast = actor.chargeCast;
        if (topChargeCast != null &&
            intent.skill.id == topChargeCast.skill.id) {
          if (actor.chargingCast != null ||
              !_isUsableNumber(intent.range) ||
              !_isUsableNumber(intent.halfArcRadians) ||
              !_isUsableNumber(intent.effectRadius) ||
              !_isUsableNumber(intent.cooldownSeconds) ||
              !_isUsableNumber(intent.actionCooldownSeconds) ||
              !_isUsableNumber(intent.postureDamage) ||
              actor.attackCooldownRemaining > 0 ||
              (actor.enemySkillCooldowns[intent.skill.id] ?? 0) > 0 ||
              actor.qiCurrent < intent.skill.qiCost) {
            continue;
          }
          enemiesById[actorId] = actor.copyWith(
            chargingCast: topChargeCast,
            chargingDefenseFlags: intent.defenseFlags,
            chargeTicksRemaining: topChargeCast.chargeTicks,
            guardianCoopUsedInCharge: false,
          );
          events.add(
            Phase0aBossChargeStarted(
              seq: seq++,
              tick: tick,
              actor: actorId,
              skillId: topChargeCast.skill.id,
              chargeTicks: topChargeCast.chargeTicks,
            ),
          );
          continue;
        }
        if (!actor.unlockedEnemySkillIds.contains(intent.skill.id) ||
            !_isUsableNumber(intent.range) ||
            !_isUsableNumber(intent.halfArcRadians) ||
            !_isUsableNumber(intent.effectRadius) ||
            !_isUsableNumber(intent.cooldownSeconds) ||
            !_isUsableNumber(intent.actionCooldownSeconds) ||
            !_isUsableNumber(intent.postureDamage) ||
            actor.attackCooldownRemaining > 0 ||
            (actor.enemySkillCooldowns[intent.skill.id] ?? 0) > 0 ||
            actor.qiCurrent < intent.skill.qiCost) {
          continue;
        }
        final targets = switch (intent.skill.targetType) {
          TargetType.single => [
            ?_selectStrikeTarget(
              attacker: actor,
              player: player,
              enemiesById: enemiesById,
              aimDirection: intent.aimDirection,
              range: intent.range,
              halfArcRadians: intent.halfArcRadians,
            ),
          ],
          TargetType.aoe =>
            _opposingTargets(
                  casterSide: actor.side,
                  player: player,
                  enemiesById: enemiesById,
                )
                .where(
                  (target) => _withinEffectRadius(
                    origin: actor.position,
                    position: target.position,
                    effectRadius: intent.effectRadius,
                  ),
                )
                .toList(),
        };
        if (targets.isEmpty) continue;
        events.add(
          Phase0aEnemySkillStarted(
            seq: seq++,
            tick: tick,
            actor: actorId,
            skillId: intent.skill.id,
          ),
        );
        var hitAny = false;
        for (final target in targets) {
          final resolved = enemySkillDamageResolver.resolveEnemySkill(
            attackerId: actorId,
            targetId: target.id,
            skill: intent.skill,
          );
          if (!resolved.isHit) continue;
          hitAny = true;
          settleInbound(
            attacker: actor,
            target: target,
            resolved: resolved,
            defenseFlags: intent.defenseFlags,
            attackId: '$actorId:$tick:${target.id}:${intent.skill.id}',
            moveKind: Phase0aMoveKind.heavy,
            isUltimate: intent.skill.type == SkillType.ultimate,
            postureDamage: intent.postureDamage,
            postureHitKind: intent.postureHitKind,
            breakPower: _noBreakPower,
          );
        }
        final currentAttacker = enemiesById[actorId];
        if (currentAttacker == null) continue;
        final cooldowns = Map<String, double>.from(
          currentAttacker.enemySkillCooldowns,
        );
        if (intent.cooldownSeconds > 0) {
          cooldowns[intent.skill.id] = intent.cooldownSeconds;
        } else {
          cooldowns.remove(intent.skill.id);
        }
        enemiesById[actorId] = currentAttacker.copyWith(
          facing: intent.aimDirection.lengthSquared > 0
              ? intent.aimDirection.normalized()
              : currentAttacker.facing,
          qiCurrent: (currentAttacker.qiCurrent + intent.skill.qiDelta).clamp(
            0,
            currentAttacker.qiMax,
          ),
          enemySkillCooldowns: Map.unmodifiable(cooldowns),
          attackCooldownRemaining: hitAny ? intent.actionCooldownSeconds : 0,
        );
      case Phase0aGatherIntent():
        // player-only 契约:技能印/真气循环是玩家全局态,敌方注入
        // gather/clear 一律拒绝,禁止静默污染玩家 skillSlots 与 HUD。
        if (actor.side != Phase0aSide.player) continue;
        // 非法参数:负/NaN/Infinity 数值或负真气消耗静默拒绝;
        // 落点环不得超出作用半径,否则会把目标从作用区内推出去。
        if (!_isUsableNumber(intent.ringRadius) ||
            !_isUsableNumber(intent.effectRadius) ||
            !_isUsableNumber(intent.cooldownSeconds) ||
            !_isUsableNumber(intent.postureDamage) ||
            intent.qiCost < 0 ||
            intent.ringRadius > intent.effectRadius) {
          continue;
        }
        final cast = _tryCastSkill(
          actor: actor,
          slotId: intent.slot,
          qiDelta: -intent.qiCost,
          cooldownSeconds: intent.cooldownSeconds,
          slots: slots,
        );
        if (cast == null) continue;
        events.add(
          Phase0aGatherStarted(
            seq: seq++,
            tick: tick,
            actor: actorId,
            skillId: intent.skillId,
            actorPosition: actor.position,
          ),
        );
        final targets =
            _opposingTargets(
                  casterSide: actor.side,
                  player: player,
                  enemiesById: enemiesById,
                )
                .where(
                  (target) => _withinEffectRadius(
                    origin: actor.position,
                    position: target.position,
                    effectRadius: intent.effectRadius,
                  ),
                )
                .where((target) => !_isGuardedBoss(target, enemiesById))
                .toList();
        final outcomes = <Phase0aSkillOutcome>[];
        final deaths = <Phase0aActor>[];
        for (final target in targets) {
          final destination = gatherRingDestination(
            playerCenter: actor.position,
            enemyPosition: target.position,
            ringRadius: intent.ringRadius,
          );
          final pulled = destination != target.position;
          final resolved = damageResolver.resolve(
            attackerId: actorId,
            targetId: target.id,
            kind: Phase0aDamageKind.gather,
            defenderStaggered:
                staggeredActorIds.contains(target.id) ||
                target.staggerTicksRemaining > 0,
            defenderVulnerable: target.posture?.isVulnerable ?? false,
            defenderWardMult: defenderWardMultFor(target, preIntentEnemies),
          );
          final damage = resolved.isHit ? _checkedDamage(resolved) : 0;
          final remaining = math.max(0, target.currentHealth - damage);
          var updated = target.copyWith(
            position: destination,
            currentHealth: remaining,
          );
          updated = applyPostureDamage(
            actorId: actorId,
            target: updated,
            postureDamage: intent.postureDamage,
            hitKind: intent.postureHitKind,
            breakPower: 0,
            isHit: resolved.isHit,
          ).actor;
          outcomes.add(
            Phase0aSkillOutcome(
              target: target.id,
              resolvedDamage: damage,
              isCritical: resolved.isHit && resolved.isCritical,
              defeated: !updated.isAlive,
              statusApplied: pulled
                  ? Phase0aSkillStatus.pulled
                  : Phase0aSkillStatus.none,
              sourcePosition: target.position,
              targetPosition: destination,
            ),
          );
          if (target.side == Phase0aSide.enemy) {
            if (!updated.isAlive) {
              enemiesById.remove(target.id);
              // 死亡列表保留 updated 的最终位置(拉后环点),
              // 不能丢回原 target 的拉前位置。
              deaths.add(updated);
            } else {
              final advanced = _advanceBossPhases(
                actor: updated,
                tick: tick,
                seq: seq,
                events: events,
              );
              enemiesById[target.id] = advanced.actor;
              seq = advanced.nextSeq;
            }
          } else {
            player = updated;
          }
        }
        events.add(
          Phase0aGatherApplied(
            seq: seq++,
            tick: tick,
            actor: actorId,
            outcomes: List.unmodifiable(outcomes),
          ),
        );
        seq = _emitDefeats(events, seq, tick, deaths);
        seq = _emitCastAvailability(
          events: events,
          seq: seq,
          tick: tick,
          cast: cast,
          slots: slots,
        );
        if (isPlayer) {
          player = cast.casterAfterQi;
        } else {
          enemiesById[actorId] = cast.casterAfterQi;
        }
      case Phase0aClearIntent():
        // player-only 契约与数值边界:同 gather 分支。
        if (actor.side != Phase0aSide.player) continue;
        if (!_isUsableNumber(intent.effectRadius) ||
            !_isUsableNumber(intent.cooldownSeconds) ||
            !_isUsableNumber(intent.postureDamage) ||
            intent.qiCost < 0) {
          continue;
        }
        final cast = _tryCastSkill(
          actor: actor,
          slotId: intent.slot,
          qiDelta: -intent.qiCost,
          cooldownSeconds: intent.cooldownSeconds,
          slots: slots,
        );
        if (cast == null) continue;
        events.add(
          Phase0aClearStarted(
            seq: seq++,
            tick: tick,
            actor: actorId,
            skillId: intent.skillId,
            actorPosition: actor.position,
          ),
        );
        final rawTargets =
            _opposingTargets(
                  casterSide: actor.side,
                  player: player,
                  enemiesById: enemiesById,
                )
                .where(
                  (target) => _withinEffectRadius(
                    origin: actor.position,
                    position: target.position,
                    effectRadius: intent.effectRadius,
                  ),
                )
                .where(
                  (target) =>
                      intent.breakPower > 0 ||
                      !_isGuardedBoss(target, enemiesById),
                )
                .toList();
        final targets = _dedupeGuardInterceptTargets(
          targets: rawTargets,
          enemiesById: preIntentEnemies,
          breakPower: intent.breakPower,
        );
        final outcomes = <Phase0aSkillOutcome>[];
        final deaths = <Phase0aActor>[];
        for (final target in targets) {
          final intercepted = _guardInterceptTarget(
            target: target,
            enemiesById: preIntentEnemies,
            breakPower: intent.breakPower,
          );
          final hitTarget = intercepted ?? target;
          final resolved = damageResolver.resolve(
            attackerId: actorId,
            targetId: hitTarget.id,
            kind: Phase0aDamageKind.clear,
            defenderStaggered:
                staggeredActorIds.contains(hitTarget.id) ||
                hitTarget.staggerTicksRemaining > 0,
            defenderVulnerable: hitTarget.posture?.isVulnerable ?? false,
            defenderWardMult: defenderWardMultFor(hitTarget, preIntentEnemies),
          );
          final damage = resolved.isHit ? _checkedDamage(resolved) : 0;
          final remaining = math.max(0, hitTarget.currentHealth - damage);
          var updated = hitTarget.copyWith(currentHealth: remaining);
          if (intercepted != null) {
            events.add(
              Phase0aGuardIntercepted(
                seq: seq++,
                tick: tick,
                actor: actorId,
                boss: target.id,
                guardian: hitTarget.id,
                skillId: intent.skillId,
                resolvedDamage: damage,
                bossPosition: target.position,
                guardianPosition: hitTarget.position,
              ),
            );
          }
          final postureResult = applyPostureDamage(
            actorId: actorId,
            target: updated,
            postureDamage: intent.postureDamage,
            hitKind: intent.postureHitKind,
            breakPower: intent.breakPower,
            isHit: resolved.isHit,
          );
          updated = postureResult.actor;
          outcomes.add(
            Phase0aSkillOutcome(
              target: hitTarget.id,
              resolvedDamage: damage,
              isCritical: resolved.isHit && resolved.isCritical,
              defeated: !updated.isAlive,
              statusApplied: postureResult.vulnerabilityEntered
                  ? Phase0aSkillStatus.staggered
                  : Phase0aSkillStatus.none,
              sourcePosition: actor.position,
              targetPosition: hitTarget.position,
            ),
          );
          if (hitTarget.side == Phase0aSide.enemy) {
            if (!updated.isAlive) {
              enemiesById.remove(hitTarget.id);
              // 死亡列表保留 updated 的最终位置(移除前坐标)。
              deaths.add(updated);
            } else {
              final advanced = _advanceBossPhases(
                actor: updated,
                tick: tick,
                seq: seq,
                events: events,
              );
              enemiesById[hitTarget.id] = advanced.actor;
              seq = advanced.nextSeq;
            }
          } else {
            player = updated;
          }
        }
        events.add(
          Phase0aClearApplied(
            seq: seq++,
            tick: tick,
            actor: actorId,
            outcomes: List.unmodifiable(outcomes),
          ),
        );
        seq = _emitDefeats(events, seq, tick, deaths);
        seq = _emitCastAvailability(
          events: events,
          seq: seq,
          tick: tick,
          cast: cast,
          slots: slots,
        );
        if (isPlayer) {
          player = cast.casterAfterQi;
        } else {
          enemiesById[actorId] = cast.casterAfterQi;
        }
      case Phase0aSkillIntent():
        final hotkey = phase0aSkillHotkeyOf(intent.kind);
        if (actor.side != Phase0aSide.player ||
            hotkey == null ||
            intent.skillId.isEmpty ||
            !_isUsableNumber(intent.range) ||
            !_isUsableNumber(intent.halfArcRadians) ||
            !_isUsableNumber(intent.effectRadius) ||
            !_isUsableNumber(intent.cooldownSeconds) ||
            !_isUsableNumber(intent.postureDamage)) {
          continue;
        }
        final cast = _tryCastSkill(
          actor: actor,
          slotId: intent.slot,
          qiDelta: intent.qiDelta,
          cooldownSeconds: intent.cooldownSeconds,
          slots: slots,
        );
        if (cast == null) continue;
        events.add(
          Phase0aSkillStarted(
            seq: seq++,
            tick: tick,
            actor: actorId,
            hotkey: hotkey,
            skillId: intent.skillId,
          ),
        );
        final targets = switch (intent.targetType) {
          TargetType.single => [
            ?_selectStrikeTarget(
              attacker: actor,
              player: player,
              enemiesById: enemiesById,
              aimDirection: intent.aimDirection,
              range: intent.range,
              halfArcRadians: intent.halfArcRadians,
              allowGuardedBoss: intent.breakPower > 0,
            ),
          ],
          TargetType.aoe =>
            _opposingTargets(
                  casterSide: actor.side,
                  player: player,
                  enemiesById: enemiesById,
                )
                .where(
                  (target) => _withinEffectRadius(
                    origin: actor.position,
                    position: target.position,
                    effectRadius: intent.effectRadius,
                  ),
                )
                .where(
                  (target) =>
                      intent.breakPower > 0 ||
                      !_isGuardedBoss(target, enemiesById),
                )
                .toList(),
        };
        final effectiveTargets = _dedupeGuardInterceptTargets(
          targets: targets,
          enemiesById: preIntentEnemies,
          breakPower: intent.breakPower,
        );
        final outcomes = <Phase0aSkillOutcome>[];
        final deaths = <Phase0aActor>[];
        for (final target in effectiveTargets) {
          final intercepted = _guardInterceptTarget(
            target: target,
            enemiesById: preIntentEnemies,
            breakPower: intent.breakPower,
          );
          final hitTarget = intercepted ?? target;
          final resolved = damageResolver.resolve(
            attackerId: actorId,
            targetId: hitTarget.id,
            kind: intent.kind,
            defenderStaggered:
                staggeredActorIds.contains(hitTarget.id) ||
                hitTarget.staggerTicksRemaining > 0,
            defenderVulnerable: hitTarget.posture?.isVulnerable ?? false,
            defenderWardMult: defenderWardMultFor(hitTarget, preIntentEnemies),
          );
          final damage = resolved.isHit ? _checkedDamage(resolved) : 0;
          final remaining = math.max(0, hitTarget.currentHealth - damage);
          var updated = hitTarget.copyWith(currentHealth: remaining);
          if (intercepted != null) {
            events.add(
              Phase0aGuardIntercepted(
                seq: seq++,
                tick: tick,
                actor: actorId,
                boss: target.id,
                guardian: hitTarget.id,
                skillId: intent.skillId,
                resolvedDamage: damage,
                bossPosition: target.position,
                guardianPosition: hitTarget.position,
              ),
            );
          }
          final postureResult = applyPostureDamage(
            actorId: actorId,
            target: updated,
            postureDamage: intent.postureDamage,
            hitKind: intent.postureHitKind,
            breakPower: intent.breakPower,
            isHit: resolved.isHit,
          );
          updated = postureResult.actor;
          outcomes.add(
            Phase0aSkillOutcome(
              target: hitTarget.id,
              resolvedDamage: damage,
              isCritical: resolved.isHit && resolved.isCritical,
              defeated: !updated.isAlive,
              statusApplied: postureResult.vulnerabilityEntered
                  ? Phase0aSkillStatus.staggered
                  : Phase0aSkillStatus.none,
              sourcePosition: actor.position,
              targetPosition: hitTarget.position,
            ),
          );
          if (hitTarget.side == Phase0aSide.enemy) {
            if (!updated.isAlive) {
              enemiesById.remove(hitTarget.id);
              // 死亡列表保留 updated 的最终位置(移除前坐标)。
              deaths.add(updated);
            } else {
              final advanced = _advanceBossPhases(
                actor: updated,
                tick: tick,
                seq: seq,
                events: events,
              );
              enemiesById[hitTarget.id] = advanced.actor;
              seq = advanced.nextSeq;
            }
          } else {
            player = updated;
          }
        }
        events.add(
          Phase0aSkillApplied(
            seq: seq++,
            tick: tick,
            actor: actorId,
            hotkey: hotkey,
            skillId: intent.skillId,
            outcomes: List.unmodifiable(outcomes),
          ),
        );
        seq = _emitDefeats(events, seq, tick, deaths);
        seq = _emitCastAvailability(
          events: events,
          seq: seq,
          tick: tick,
          cast: cast,
          slots: slots,
        );
        final aimDirection = intent.aimDirection.lengthSquared > 0
            ? intent.aimDirection.normalized()
            : actor.facing;
        player = cast.casterAfterQi.copyWith(facing: aimDirection);
    }
  }

  // 蓄力拍尾释放(稳定敌序):pre-step 倒计时归零者在此走既有 enemy skill
  // 结算路径(DamageCalculator 唯一真相源)。本拍 intent 阶段被破招/击败者
  // chargingCast 已清/单位已移除,自动跳过——「完成仅一次」由状态保证。
  for (final enemy in state.enemies) {
    if (!chargeFireActorIds.contains(enemy.id)) continue;
    final actor = enemiesById[enemy.id];
    if (actor == null || !actor.isAlive) continue;
    final cast = actor.chargingCast;
    if (cast == null) continue;
    if (enemySkillDamageResolver == null) {
      // 防御性:无伤害 resolver 无法释放,清蓄力态避免永久压制死锁。
      enemiesById[enemy.id] = actor.copyWith(clearChargingCast: true);
      continue;
    }
    final toPlayer = player.position - actor.position;
    final aimDirection = toPlayer.lengthSquared > 0
        ? toPlayer.normalized()
        : actor.facing;
    final targets = switch (cast.skill.targetType) {
      TargetType.single => [
        ?_selectStrikeTarget(
          attacker: actor,
          player: player,
          enemiesById: enemiesById,
          aimDirection: aimDirection,
          range: cast.attackRange,
          halfArcRadians: cast.halfArcRadians,
        ),
      ],
      TargetType.aoe =>
        _opposingTargets(
              casterSide: actor.side,
              player: player,
              enemiesById: enemiesById,
            )
            .where(
              (target) => _withinEffectRadius(
                origin: actor.position,
                position: target.position,
                effectRadius: cast.effectRadius,
              ),
            )
            .toList(),
    };
    if (targets.isEmpty) {
      // 蓄力散逸(无合法目标):清蓄力态,无事件无 CD(对齐 intent 分支
      // targets.isEmpty 口径)。
      enemiesById[enemy.id] = actor.copyWith(clearChargingCast: true);
      continue;
    }
    events.add(
      Phase0aEnemySkillStarted(
        seq: seq++,
        tick: tick,
        actor: enemy.id,
        skillId: cast.skill.id,
      ),
    );
    var hitAny = false;
    final defenseFlags = actor.chargingDefenseFlags ?? cast.defenseFlags;
    for (final target in targets) {
      final resolved = enemySkillDamageResolver.resolveEnemySkill(
        attackerId: enemy.id,
        targetId: target.id,
        skill: cast.skill,
      );
      if (!resolved.isHit) continue;
      hitAny = true;
      settleInbound(
        attacker: actor,
        target: target,
        resolved: resolved,
        defenseFlags: defenseFlags,
        attackId: '${enemy.id}:$tick:${target.id}:${cast.skill.id}',
        moveKind: Phase0aMoveKind.heavy,
        isUltimate: cast.skill.type == SkillType.ultimate,
        postureDamage: cast.postureDamage,
        postureHitKind: cast.postureHitKind,
        breakPower: _noBreakPower,
      );
    }
    // 断魂庄锁脉针：蓄力完整结束且未被破招即夺取玩家最大真气的一定比例。
    // 与 legacy forcedSkill 路一致，不以本次伤害是否命中为额外门槛。
    if (cast.skill.qiDrainPct > 0 && player.isAlive) {
      player = player.copyWith(
        qiCurrent: QiDrainEffect(
          pct: cast.skill.qiDrainPct,
        ).applyTo(currentQi: player.qiCurrent, maxQi: player.qiMax),
      );
    }
    final currentAttacker = enemiesById[enemy.id];
    if (currentAttacker == null) continue;
    final cooldowns = Map<String, double>.from(
      currentAttacker.enemySkillCooldowns,
    );
    if (cast.cooldownSeconds > 0) {
      cooldowns[cast.skill.id] = cast.cooldownSeconds;
    } else {
      cooldowns.remove(cast.skill.id);
    }
    enemiesById[enemy.id] = currentAttacker.copyWith(
      clearChargingCast: true,
      facing: aimDirection,
      qiCurrent: (actor.qiCurrent + cast.skill.qiDelta).clamp(0, actor.qiMax),
      enemySkillCooldowns: Map.unmodifiable(cooldowns),
      attackCooldownRemaining: hitAny ? cast.actionCooldownSeconds : 0,
    );
  }

  return Phase0aStepResult(
    state: Phase0aArenaState(
      tick: tick,
      nextSeq: seq,
      player: player,
      enemies: List.unmodifiable(enemiesById.values.toList()),
      skillSlots: List.unmodifiable(slots),
      winCondition: state.winCondition,
    ),
    events: List.unmodifiable(events),
  );
}

const _noChargeTicksRemaining = 0;

Map<String, double> _cooldownsAfter(
  Map<String, double> cooldowns,
  double deltaSeconds,
) {
  if (cooldowns.isEmpty) return cooldowns;
  final next = <String, double>{};
  cooldowns.forEach((id, remaining) {
    final value = _cooldownAfter(remaining, deltaSeconds);
    if (value > 0) next[id] = value;
  });
  return Map.unmodifiable(next);
}

({Phase0aActor boss, Phase0aActor partner})? _guardianCoopContext({
  required Phase0aActor actor,
  required Map<String, Phase0aActor> enemiesById,
  required Map<String, Phase0aAttackIntent> attackIntentsByActor,
  required Phase0aActor player,
  required Set<String> suppressedActorIds,
}) {
  if (!player.isAlive || actor.side != Phase0aSide.enemy) return null;
  final bosses = enemiesById.values.where((candidate) {
    if (!candidate.isAlive ||
        !candidate.guardInterceptsInterrupt ||
        candidate.chargingCast == null ||
        candidate.guardianCoopUsedInCharge ||
        candidate.guardianDefIds.length != 2) {
      return false;
    }
    return candidate.guardianDefIds.every(
      (guardianId) => enemiesById.values.any(
        (guardian) =>
            guardian.isAlive &&
            (guardian.id == guardianId ||
                guardian.id.startsWith('${guardianId}_w')),
      ),
    );
  }).toList()..sort((a, b) => a.id.compareTo(b.id));

  for (final boss in bosses) {
    final guardians = enemiesById.values.where((guardian) {
      final registered = boss.guardianDefIds.any(
        (guardianId) =>
            guardian.id == guardianId ||
            guardian.id.startsWith('${guardianId}_w'),
      );
      final basic = attackIntentsByActor[guardian.id];
      final target = basic == null
          ? null
          : _selectStrikeTarget(
              attacker: guardian,
              player: player,
              enemiesById: enemiesById,
              aimDirection: basic.aimDirection,
              range: basic.range,
              halfArcRadians: basic.halfArcRadians,
            );
      return registered &&
          guardian.isAlive &&
          guardian.chargingCast == null &&
          guardian.chargeTicksRemaining == 0 &&
          !suppressedActorIds.contains(guardian.id) &&
          guardian.staggerTicksRemaining == 0 &&
          guardian.attackCooldownRemaining <= 0 &&
          basic != null &&
          _isUsableNumber(basic.range) &&
          _isUsableNumber(basic.halfArcRadians) &&
          _isUsableNumber(basic.cooldownSeconds) &&
          target?.id == player.id;
    }).toList()..sort((a, b) => a.id.compareTo(b.id));
    if (guardians.length != 2 || guardians.first.id != actor.id) continue;
    return (boss: boss, partner: guardians[1]);
  }
  return null;
}

({Phase0aActor actor, int nextSeq}) _advanceBossPhases({
  required Phase0aActor actor,
  required int tick,
  required int seq,
  required List<Phase0aEvent> events,
}) {
  final phases = actor.bossPhases;
  if (phases == null ||
      phases.isEmpty ||
      !actor.isAlive ||
      actor.maxHealth <= 0) {
    return (actor: actor, nextSeq: seq);
  }
  var current = actor;
  var nextSeq = seq;
  while (current.bossPhaseIndex < phases.length - 1) {
    final nextIndex = current.bossPhaseIndex + 1;
    if (current.currentHealth / current.maxHealth >
        phases[nextIndex].hpThresholdPct) {
      break;
    }
    final unlocked = List<String>.of(current.unlockedEnemySkillIds);
    final newlyUnlocked = <String>[];
    for (final id in phases[nextIndex].unlockSkillIds) {
      if (!unlocked.contains(id)) {
        unlocked.add(id);
        newlyUnlocked.add(id);
      }
    }
    current = current.copyWith(
      bossPhaseIndex: nextIndex,
      unlockedEnemySkillIds: List.unmodifiable(unlocked),
    );
    events.add(
      Phase0aBossPhaseChanged(
        seq: nextSeq++,
        tick: tick,
        actor: actor.id,
        phaseIndex: nextIndex,
        unlockedSkillIds: List.unmodifiable(newlyUnlocked),
      ),
    );
    // 阶段蓄力入口:onEnterMechanic == chargeCounter → 进阶即把 Boss 推入
    // 蓄力态(招牌 = application 预解析的该阶段最高倍率解锁招;未预解析 =
    // 解锁招为空 no-op,对齐旧引擎)。已有蓄力则覆盖(一击跨多阈值以最后
    // 阶段为准,对齐旧引擎 _advancePhases 覆写语义)。
    if (phases[nextIndex].onEnterMechanic == BossPhaseMechanic.chargeCounter) {
      final phaseCast = nextIndex < current.phaseChargeCasts.length
          ? current.phaseChargeCasts[nextIndex]
          : null;
      if (phaseCast != null) {
        current = current.copyWith(
          chargingCast: phaseCast,
          chargingDefenseFlags: phaseCast.defenseFlags,
          chargeTicksRemaining: phaseCast.chargeTicks,
          guardianCoopUsedInCharge: false,
        );
        events.add(
          Phase0aBossChargeStarted(
            seq: nextSeq++,
            tick: tick,
            actor: actor.id,
            skillId: phaseCast.skill.id,
            chargeTicks: phaseCast.chargeTicks,
          ),
        );
      }
    }
  }
  return (actor: current, nextSeq: nextSeq);
}

/// 可用态推导:冷却中优先,其次真气门槛,再次 ready。
Phase0aSkillAvailability availabilityOf({
  required double cooldownRemaining,
  required int qiCurrent,
  required int qiCost,
}) {
  if (cooldownRemaining > 0) return Phase0aSkillAvailability.cooldown;
  if (qiCurrent < qiCost) return Phase0aSkillAvailability.qi;
  return Phase0aSkillAvailability.ready;
}

double _cooldownAfter(double remaining, double deltaSeconds) {
  final next = remaining - deltaSeconds;
  return next > 0 ? next : 0;
}

/// intent 外部 double 参数合法性:必须有限且非负。
/// 负值经平方(射程/半径)或减法(冷却/真气)会被悄悄合法化,NaN 比较
/// 恒 false 会绕过一切边界检查,两者都必须在结算前拒绝。
bool _isUsableNumber(double value) => value.isFinite && value >= 0;

/// resolver 返回的结算伤害必须非负:负伤害经 `hp - damage` 会变成治疗,
/// clamp 成 0 会掩盖 resolver/公式错误,故 fail-fast。
int _checkedDamage(Phase0aResolvedHit resolved) {
  if (resolved.damage < 0) {
    throw StateError(
      'Phase0aDamageResolver returned negative damage: ${resolved.damage}',
    );
  }
  return resolved.damage;
}

/// intent 稳定排序:actorId 升序,同 actor 保持输入顺序
/// (List.sort 非稳定,显式带原序索引决胜)。
List<Phase0aIntent> _stableOrderByActor(List<Phase0aIntent> intents) {
  final indexed = <MapEntry<int, Phase0aIntent>>[
    for (var i = 0; i < intents.length; i++) MapEntry(i, intents[i]),
  ];
  indexed.sort((a, b) {
    final byActor = a.value.actorId.compareTo(b.value.actorId);
    return byActor != 0 ? byActor : a.key.compareTo(b.key);
  });
  return [for (final entry in indexed) entry.value];
}

bool _willCommitBasicAttackAdvance({
  required Phase0aActor actor,
  required Phase0aAttackIntent intent,
}) {
  if (actor.attackCooldownRemaining > 0 ||
      intent.aimDirection.lengthSquared == 0 ||
      !_isUsableNumber(intent.range) ||
      !_isUsableNumber(intent.halfArcRadians) ||
      !_isUsableNumber(intent.cooldownSeconds) ||
      !_isUsableNumber(intent.postureDamage)) {
    return false;
  }
  final chain = intent.basicAttackChain;
  if (chain == null) return false;
  final registry = intent.basicAttackGeometryRegistry;
  if (registry == null) {
    throw StateError('basic attack chain requires a geometry registry');
  }
  final segment = chain.segmentAt(
    actor.basicAttackSegmentIndex % chain.segments.length,
  );
  return registry.tuningFor(segment).advanceDistance > 0;
}

Phase0aActor? _selectStrikeTarget({
  required Phase0aActor attacker,
  required Phase0aActor player,
  required Map<String, Phase0aActor> enemiesById,
  required ArenaVector aimDirection,
  required double range,
  required double halfArcRadians,
  bool allowGuardedBoss = false,
}) {
  final candidates = attacker.side == Phase0aSide.player
      ? enemiesById.values.where((enemy) => enemy.isAlive).toList()
      : (player.isAlive ? <Phase0aActor>[player] : <Phase0aActor>[]);
  final inArc = candidates
      .where(
        (target) => allowGuardedBoss || !_isGuardedBoss(target, enemiesById),
      )
      .where(
        (target) => isTargetInsideStrikeArc(
          origin: attacker.position,
          aimDirection: aimDirection,
          target: target.position,
          range: range,
          halfArcRadians: halfArcRadians,
        ),
      )
      .toList();
  if (inArc.isEmpty) return null;
  inArc.sort((a, b) {
    final distanceA = (a.position - attacker.position).lengthSquared;
    final distanceB = (b.position - attacker.position).lengthSquared;
    final byDistance = distanceA.compareTo(distanceB);
    return byDistance != 0 ? byDistance : a.id.compareTo(b.id);
  });
  return inArc.first;
}

bool _isGuardedBoss(
  Phase0aActor candidate,
  Map<String, Phase0aActor> enemiesById,
) {
  if (candidate.side != Phase0aSide.enemy ||
      candidate.guardianWardMult == null ||
      candidate.guardianDefIds.isEmpty) {
    return false;
  }
  return candidate.guardianDefIds.any(
    (guardianId) => enemiesById.values.any(
      (guardian) =>
          guardian.isAlive &&
          (guardian.id == guardianId ||
              guardian.id.startsWith('${guardianId}_w')),
    ),
  );
}

/// Typed break exception to the ordinary target gate. The resolver still
/// settles the exact same damage once, but against the stable lowest-health
/// live guardian; the boss remains charging and the guardian is staggered.
Phase0aActor? _guardInterceptTarget({
  required Phase0aActor target,
  required Map<String, Phase0aActor> enemiesById,
  required int breakPower,
}) {
  if (breakPower <= 0 ||
      !target.isAlive ||
      target.chargingCast == null ||
      !target.guardInterceptsInterrupt ||
      !_isGuardedBoss(target, enemiesById)) {
    return null;
  }
  final guardians =
      [
        for (final guardian in enemiesById.values)
          if (guardian.isAlive &&
              target.guardianDefIds.any(
                (guardianId) =>
                    guardian.id == guardianId ||
                    guardian.id.startsWith('${guardianId}_w'),
              ))
            guardian,
      ]..sort((a, b) {
        final byHealth = a.currentHealth.compareTo(b.currentHealth);
        return byHealth != 0 ? byHealth : a.id.compareTo(b.id);
      });
  return guardians.isEmpty ? null : guardians.first;
}

/// A break-capable AOE may contain both the guarded Boss and the guardian that
/// will intercept the Boss hit. Keep the redirected hit and drop the guardian's
/// duplicate direct entry so one action never emits two outcomes for one actor
/// or silently overwrites damage while applying the action snapshot.
List<Phase0aActor> _dedupeGuardInterceptTargets({
  required List<Phase0aActor> targets,
  required Map<String, Phase0aActor> enemiesById,
  required int breakPower,
}) {
  if (breakPower <= 0 || targets.length < 2) return targets;
  final interceptedGuardianIds = <String>{
    for (final target in targets)
      ?_guardInterceptTarget(
        target: target,
        enemiesById: enemiesById,
        breakPower: breakPower,
      )?.id,
  };
  if (interceptedGuardianIds.isEmpty) return targets;
  return [
    for (final target in targets)
      if (!interceptedGuardianIds.contains(target.id) ||
          _guardInterceptTarget(
                target: target,
                enemiesById: enemiesById,
                breakPower: breakPower,
              ) !=
              null)
        target,
  ];
}

/// 对方阵营存活单位,按 id 升序(outcomes 稳定顺序)。
List<Phase0aActor> _opposingTargets({
  required Phase0aSide casterSide,
  required Phase0aActor player,
  required Map<String, Phase0aActor> enemiesById,
}) {
  if (casterSide == Phase0aSide.player) {
    final enemies = enemiesById.values.where((enemy) => enemy.isAlive).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return enemies;
  }
  return player.isAlive ? <Phase0aActor>[player] : <Phase0aActor>[];
}

final class _SkillCast {
  const _SkillCast({
    required this.slot,
    required this.casterAfterQi,
    required this.slotAfterCast,
  });

  final String slot;
  final Phase0aActor casterAfterQi;
  final Phase0aSkillSlot slotAfterCast;
}

/// 技能释放门槛:slot 存在、冷却归零、真气足够;任一不满足返回 null(拒绝,
/// 无事件、不耗真气、不动冷却)。
_SkillCast? _tryCastSkill({
  required Phase0aActor actor,
  required String slotId,
  required int qiDelta,
  required double cooldownSeconds,
  required List<Phase0aSkillSlot> slots,
}) {
  final qiCost = qiDelta < 0 ? -qiDelta : 0;
  final index = slots.indexWhere((slot) => slot.slot == slotId);
  if (index < 0) return null;
  final slot = slots[index];
  if (slot.cooldownRemaining > 0 || actor.qiCurrent < qiCost) return null;
  // availability 不在此处预置:施放后由全槽同拍重算按槽序发出真实迁移。
  final slotAfterCast = slot.copyWith(
    cooldownRemaining: cooldownSeconds,
    qiCost: qiCost,
  );
  slots[index] = slotAfterCast;
  return _SkillCast(
    slot: slotId,
    casterAfterQi: actor.copyWith(
      qiCurrent: (actor.qiCurrent + qiDelta).clamp(0, actor.qiMax),
    ),
    slotAfterCast: slotAfterCast,
  );
}

int _emitDefeats(
  List<Phase0aEvent> events,
  int seq,
  int tick,
  List<Phase0aActor> deaths,
) {
  var nextSeq = seq;
  for (final death in deaths) {
    events.add(
      Phase0aEnemyDefeated(
        seq: nextSeq++,
        tick: tick,
        target: death.id,
        defeatKind: death.defeatKind,
        // death 即调用方保留的 updated 最终位置(移除前坐标)。
        targetPosition: death.position,
      ),
    );
  }
  return nextSeq;
}

/// 技能施放(caster 真气已变)后同拍刷新全部技能槽可用态:
/// 按槽稳定顺序只发真实迁移;施放槽进 cooldown,其余槽若余气不足
/// 同拍进 qi,不等下一拍。payload 直接驱动 HUD。
int _emitCastAvailability({
  required List<Phase0aEvent> events,
  required int seq,
  required int tick,
  required _SkillCast cast,
  required List<Phase0aSkillSlot> slots,
}) {
  var nextSeq = seq;
  final qiCurrent = cast.casterAfterQi.qiCurrent;
  for (var i = 0; i < slots.length; i++) {
    final slot = slots[i];
    final availability = availabilityOf(
      cooldownRemaining: slot.cooldownRemaining,
      qiCurrent: qiCurrent,
      qiCost: slot.qiCost,
    );
    if (availability == slot.availability) continue;
    slots[i] = slot.copyWith(availability: availability);
    events.add(
      Phase0aSkillAvailabilityChanged(
        seq: nextSeq++,
        tick: tick,
        slot: slot.slot,
        availability: availability,
        cooldownRemaining: availability == Phase0aSkillAvailability.cooldown
            ? slot.cooldownRemaining
            : null,
        qiCurrent: qiCurrent,
        qiRequired: slot.qiCost,
      ),
    );
  }
  return nextSeq;
}

/// 目标是否在以 origin 为圆心的作用半径内(闭区间)。
bool _withinEffectRadius({
  required ArenaVector origin,
  required ArenaVector position,
  required double effectRadius,
}) {
  return (position - origin).lengthSquared <= effectRadius * effectRadius;
}

bool _validDefenseIntent(Phase0aDefenseIntent intent) {
  final numbers = <double>[
    intent.shieldAbsorption,
    intent.counterDamage,
    intent.counterUpperBound,
    intent.dodgeDistance,
    intent.cooldownSeconds,
  ];
  return numbers.every((value) => value.isFinite && value >= 0) &&
      intent.direction.x.isFinite &&
      intent.direction.y.isFinite &&
      intent.shieldDurationTicks >= 0 &&
      intent.parryWindowTicks >= 0 &&
      intent.dodgeIframeTicks >= 0 &&
      intent.counterDamage <= intent.counterUpperBound;
}

int _checkedCounter(double value) {
  if (!value.isFinite || value < 0 || value > 0x7fffffff) {
    throw StateError('Phase0A counter damage out of range: $value');
  }
  return value.round();
}
