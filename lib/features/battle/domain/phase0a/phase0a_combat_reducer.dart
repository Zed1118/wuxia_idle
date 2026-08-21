import 'dart:math' as math;

import '../../../../core/domain/enums.dart';
import '../../../../data/defs/skill_def.dart';
import 'arena_vector.dart';
import 'phase0a_combat_events.dart';
import 'phase0a_combat_intent.dart';
import 'phase0a_combat_model.dart';
import 'phase0a_damage_kind.dart';
import 'realtime_combat_rules.dart';

export 'phase0a_damage_kind.dart';

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

/// Optional production extension for enemy skills whose identity cannot be
/// represented by the fixed player hotkey damage kinds.
abstract interface class Phase0aEnemySkillDamageResolver {
  Phase0aResolvedHit resolveEnemySkill({
    required String attackerId,
    required String targetId,
    required SkillDef skill,
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
        // 非法数值(负/NaN/Infinity)静默拒绝:平方会掩盖负射程,
        // 负冷却等价无冷却。
        if (!_isUsableNumber(intent.range) ||
            !_isUsableNumber(intent.halfArcRadians) ||
            !_isUsableNumber(intent.cooldownSeconds)) {
          continue;
        }
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
            final damage = _checkedDamage(resolved);
            final remaining = math.max(0, target.currentHealth - damage);
            events.add(
              Phase0aHitLanded(
                seq: seq++,
                tick: tick,
                actor: actorId,
                target: target.id,
                moveKind: intent.moveKind,
                isCritical: resolved.isCritical,
                isUltimate: false,
                resolvedDamage: damage,
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
        }
        final aimDirection = intent.aimDirection.lengthSquared > 0
            ? intent.aimDirection.normalized()
            : actor.facing;
        final recharged = actor.copyWith(
          attackCooldownRemaining: intent.cooldownSeconds,
          facing: aimDirection,
          qiCurrent: (actor.qiCurrent + intent.qiDelta).clamp(0, actor.qiMax),
        );
        if (isPlayer) {
          player = recharged;
        } else {
          enemiesById[actorId] = recharged;
        }
      case Phase0aEnemySkillIntent():
        if (actor.side != Phase0aSide.enemy ||
            enemySkillDamageResolver == null ||
            intent.skill.id.isEmpty ||
            !actor.unlockedEnemySkillIds.contains(intent.skill.id) ||
            !_isUsableNumber(intent.range) ||
            !_isUsableNumber(intent.halfArcRadians) ||
            !_isUsableNumber(intent.effectRadius) ||
            !_isUsableNumber(intent.cooldownSeconds) ||
            !_isUsableNumber(intent.actionCooldownSeconds) ||
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
          final damage = _checkedDamage(resolved);
          final remaining = math.max(0, target.currentHealth - damage);
          events.add(
            Phase0aHitLanded(
              seq: seq++,
              tick: tick,
              actor: actorId,
              target: target.id,
              moveKind: Phase0aMoveKind.heavy,
              isCritical: resolved.isCritical,
              isUltimate: intent.skill.type == SkillType.ultimate,
              resolvedDamage: damage,
              remainingHealth: remaining,
            ),
          );
          if (target.side == Phase0aSide.player) {
            player = target.copyWith(currentHealth: remaining);
          }
        }
        final cooldowns = Map<String, double>.from(actor.enemySkillCooldowns);
        if (intent.cooldownSeconds > 0) {
          cooldowns[intent.skill.id] = intent.cooldownSeconds;
        } else {
          cooldowns.remove(intent.skill.id);
        }
        enemiesById[actorId] = actor.copyWith(
          facing: intent.aimDirection.lengthSquared > 0
              ? intent.aimDirection.normalized()
              : actor.facing,
          qiCurrent: (actor.qiCurrent + intent.skill.qiDelta).clamp(
            0,
            actor.qiMax,
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
          Phase0aGatherStarted(seq: seq++, tick: tick, actor: actorId),
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
          );
          final damage = resolved.isHit ? _checkedDamage(resolved) : 0;
          final remaining = math.max(0, target.currentHealth - damage);
          final updated = target.copyWith(
            position: destination,
            currentHealth: remaining,
          );
          outcomes.add(
            Phase0aSkillOutcome(
              target: target.id,
              resolvedDamage: damage,
              isCritical: resolved.isHit && resolved.isCritical,
              defeated: !updated.isAlive,
              statusApplied: pulled
                  ? Phase0aSkillStatus.pulled
                  : Phase0aSkillStatus.none,
            ),
          );
          if (target.side == Phase0aSide.enemy) {
            if (!updated.isAlive) {
              enemiesById.remove(target.id);
              deaths.add(target);
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
        events.add(Phase0aClearStarted(seq: seq++, tick: tick, actor: actorId));
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
                .toList();
        final outcomes = <Phase0aSkillOutcome>[];
        final deaths = <Phase0aActor>[];
        for (final target in targets) {
          final resolved = damageResolver.resolve(
            attackerId: actorId,
            targetId: target.id,
            kind: Phase0aDamageKind.clear,
          );
          final damage = resolved.isHit ? _checkedDamage(resolved) : 0;
          final remaining = math.max(0, target.currentHealth - damage);
          final updated = target.copyWith(currentHealth: remaining);
          outcomes.add(
            Phase0aSkillOutcome(
              target: target.id,
              resolvedDamage: damage,
              isCritical: resolved.isHit && resolved.isCritical,
              defeated: !updated.isAlive,
              statusApplied: Phase0aSkillStatus.staggered,
            ),
          );
          if (target.side == Phase0aSide.enemy) {
            if (!updated.isAlive) {
              enemiesById.remove(target.id);
              deaths.add(target);
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
            !_isUsableNumber(intent.cooldownSeconds)) {
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
        final outcomes = <Phase0aSkillOutcome>[];
        final deaths = <Phase0aActor>[];
        for (final target in targets) {
          final resolved = damageResolver.resolve(
            attackerId: actorId,
            targetId: target.id,
            kind: intent.kind,
          );
          final damage = resolved.isHit ? _checkedDamage(resolved) : 0;
          final remaining = math.max(0, target.currentHealth - damage);
          final updated = target.copyWith(currentHealth: remaining);
          outcomes.add(
            Phase0aSkillOutcome(
              target: target.id,
              resolvedDamage: damage,
              isCritical: resolved.isHit && resolved.isCritical,
              defeated: !updated.isAlive,
              statusApplied: Phase0aSkillStatus.none,
            ),
          );
          if (target.side == Phase0aSide.enemy) {
            if (!updated.isAlive) {
              enemiesById.remove(target.id);
              deaths.add(target);
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
