import 'dart:math' as math;

import 'arena_vector.dart';
import 'phase0a_combat_events.dart';
import 'phase0a_combat_intent.dart';
import 'phase0a_combat_model.dart';
import 'realtime_combat_rules.dart';

/// 伤害结算种类(reducer → resolver 的语义入参)。
enum Phase0aDamageKind { basic, gather, clear }

/// 一次结算的运行时结果:命中与否、暴击与否、伤害值全部由
/// resolver(未来生产接 DamageCalculator)给出,reducer 不写第二套公式。
final class Phase0aResolvedHit {
  const Phase0aResolvedHit({
    required this.isHit,
    required this.isCritical,
    required this.damage,
  });

  final bool isHit;
  final bool isCritical;
  final int damage;
}

/// 显式注入的伤害结算接口。本片测试用固定实现;
/// 未来生产在同一接口上接 `DamageCalculator`,adapter/reducer 禁写公式。
abstract interface class Phase0aDamageResolver {
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
  });
}

/// 一拍结算输出:新状态 + 本拍事件(已按发射顺序排好,seq 单调)。
final class Phase0aStepResult {
  const Phase0aStepResult({required this.state, required this.events});

  final Phase0aArenaState state;
  final List<Phase0aEvent> events;
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
}) {
  final tick = state.tick + 1;
  var seq = state.nextSeq;
  final events = <Phase0aEvent>[];

  var player = state.player.copyWith(
    attackCooldownRemaining:
        _cooldownAfter(state.player.attackCooldownRemaining, deltaSeconds),
  );

  final enemiesById = <String, Phase0aActor>{
    for (final enemy in state.enemies)
      enemy.id: enemy.copyWith(
        attackCooldownRemaining:
            _cooldownAfter(enemy.attackCooldownRemaining, deltaSeconds),
      ),
  };

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
          cooldownRemaining:
              availability == Phase0aSkillAvailability.cooldown
                  ? cooldownRemaining
                  : null,
          qiCurrent: player.qiCurrent,
          qiRequired: slot.qiCost,
        ),
      );
    }
  }

  final ordered = _stableOrderByActor(intents);
  for (final intent in ordered) {
    final actorId = intent.actorId;
    final isPlayer = actorId == player.id;
    final actor = isPlayer ? player : enemiesById[actorId];
    if (actor == null || !actor.isAlive) continue;

    switch (intent) {
      case Phase0aMoveIntent(:final direction):
        final step = direction.lengthSquared > 0
            ? direction.normalized()
            : ArenaVector.zero;
        final moved = actor.copyWith(
          position: actor.position + step * (actor.moveSpeed * deltaSeconds),
          facing: step.lengthSquared > 0 ? step : actor.facing,
        );
        if (isPlayer) {
          player = moved;
        } else {
          enemiesById[actorId] = moved;
        }
      case Phase0aAttackIntent():
        if (actor.attackCooldownRemaining > 0) continue;
        events.add(
          Phase0aAttackStarted(
            seq: seq++,
            tick: tick,
            actor: actorId,
            moveKind: intent.moveKind,
          ),
        );
        final target = _selectStrikeTarget(
          attacker: actor,
          player: player,
          enemiesById: enemiesById,
          aimDirection: intent.aimDirection,
          range: intent.range,
          halfArcRadians: intent.halfArcRadians,
        );
        if (target != null) {
          final resolved = damageResolver.resolve(
            attackerId: actorId,
            targetId: target.id,
            kind: Phase0aDamageKind.basic,
          );
          if (resolved.isHit) {
            final remaining = math.max(0, target.currentHealth - resolved.damage);
            events.add(
              Phase0aHitLanded(
                seq: seq++,
                tick: tick,
                actor: actorId,
                target: target.id,
                moveKind: intent.moveKind,
                isCritical: resolved.isCritical,
                isUltimate: false,
                resolvedDamage: resolved.damage,
                remainingHealth: remaining,
              ),
            );
            final updated = target.copyWith(currentHealth: remaining);
            if (target.side == Phase0aSide.enemy) {
              if (!updated.isAlive) {
                enemiesById.remove(target.id);
                events.add(
                  Phase0aEnemyDefeated(
                    seq: seq++,
                    tick: tick,
                    target: target.id,
                    defeatKind: target.defeatKind,
                  ),
                );
              } else {
                enemiesById[target.id] = updated;
              }
            } else {
              player = updated;
            }
          }
        }
        final recharged = actor.copyWith(
          attackCooldownRemaining: intent.cooldownSeconds,
        );
        if (isPlayer) {
          player = recharged;
        } else {
          enemiesById[actorId] = recharged;
        }
      case Phase0aGatherIntent():
        final cast = _tryCastSkill(
          actor: actor,
          slotId: intent.slot,
          qiCost: intent.qiCost,
          cooldownSeconds: intent.cooldownSeconds,
          slots: slots,
        );
        if (cast == null) continue;
        events.add(
          Phase0aGatherStarted(seq: seq++, tick: tick, actor: actorId),
        );
        final targets = _opposingTargets(
          casterSide: actor.side,
          player: player,
          enemiesById: enemiesById,
        );
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
          );
          final damage = resolved.isHit ? resolved.damage : 0;
          final remaining = math.max(0, target.currentHealth - damage);
          final updated = target.copyWith(
            position: destination,
            currentHealth: remaining,
          );
          outcomes.add(
            Phase0aSkillOutcome(
              target: target.id,
              resolvedDamage: damage,
              defeated: !updated.isAlive,
              statusApplied:
                  pulled ? Phase0aSkillStatus.pulled : Phase0aSkillStatus.none,
            ),
          );
          if (target.side == Phase0aSide.enemy) {
            if (!updated.isAlive) {
              enemiesById.remove(target.id);
              deaths.add(target);
            } else {
              enemiesById[target.id] = updated;
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
        );
        if (isPlayer) {
          player = cast.casterAfterQi;
        } else {
          enemiesById[actorId] = cast.casterAfterQi;
        }
      case Phase0aClearIntent():
        final cast = _tryCastSkill(
          actor: actor,
          slotId: intent.slot,
          qiCost: intent.qiCost,
          cooldownSeconds: intent.cooldownSeconds,
          slots: slots,
        );
        if (cast == null) continue;
        events.add(
          Phase0aClearStarted(seq: seq++, tick: tick, actor: actorId),
        );
        final targets = _opposingTargets(
          casterSide: actor.side,
          player: player,
          enemiesById: enemiesById,
        );
        final outcomes = <Phase0aSkillOutcome>[];
        final deaths = <Phase0aActor>[];
        for (final target in targets) {
          final resolved = damageResolver.resolve(
            attackerId: actorId,
            targetId: target.id,
            kind: Phase0aDamageKind.clear,
          );
          final damage = resolved.isHit ? resolved.damage : 0;
          final remaining = math.max(0, target.currentHealth - damage);
          final updated = target.copyWith(currentHealth: remaining);
          outcomes.add(
            Phase0aSkillOutcome(
              target: target.id,
              resolvedDamage: damage,
              defeated: !updated.isAlive,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
          );
          if (target.side == Phase0aSide.enemy) {
            if (!updated.isAlive) {
              enemiesById.remove(target.id);
              deaths.add(target);
            } else {
              enemiesById[target.id] = updated;
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
        );
        if (isPlayer) {
          player = cast.casterAfterQi;
        } else {
          enemiesById[actorId] = cast.casterAfterQi;
        }
    }
  }

  return Phase0aStepResult(
    state: Phase0aArenaState(
      tick: tick,
      nextSeq: seq,
      player: player,
      enemies: List.unmodifiable(enemiesById.values.toList()),
      skillSlots: List.unmodifiable(slots),
    ),
    events: List.unmodifiable(events),
  );
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

Phase0aActor? _selectStrikeTarget({
  required Phase0aActor attacker,
  required Phase0aActor player,
  required Map<String, Phase0aActor> enemiesById,
  required ArenaVector aimDirection,
  required double range,
  required double halfArcRadians,
}) {
  final candidates = attacker.side == Phase0aSide.player
      ? enemiesById.values.where((enemy) => enemy.isAlive).toList()
      : (player.isAlive ? <Phase0aActor>[player] : <Phase0aActor>[]);
  final inArc = candidates
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
  required int qiCost,
  required double cooldownSeconds,
  required List<Phase0aSkillSlot> slots,
}) {
  final index = slots.indexWhere((slot) => slot.slot == slotId);
  if (index < 0) return null;
  final slot = slots[index];
  if (slot.cooldownRemaining > 0 || actor.qiCurrent < qiCost) return null;
  final slotAfterCast = slot.copyWith(
    cooldownRemaining: cooldownSeconds,
    qiCost: qiCost,
    availability: Phase0aSkillAvailability.cooldown,
  );
  slots[index] = slotAfterCast;
  return _SkillCast(
    slot: slotId,
    casterAfterQi: actor.copyWith(qiCurrent: actor.qiCurrent - qiCost),
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
      ),
    );
  }
  return nextSeq;
}

int _emitCastAvailability({
  required List<Phase0aEvent> events,
  required int seq,
  required int tick,
  required _SkillCast cast,
}) {
  events.add(
    Phase0aSkillAvailabilityChanged(
      seq: seq++,
      tick: tick,
      slot: cast.slot,
      availability: Phase0aSkillAvailability.cooldown,
      cooldownRemaining: cast.slotAfterCast.cooldownRemaining,
      qiCurrent: cast.casterAfterQi.qiCurrent,
      qiRequired: cast.slotAfterCast.qiCost,
    ),
  );
  return seq;
}
