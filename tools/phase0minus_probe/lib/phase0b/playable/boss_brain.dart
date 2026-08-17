import 'dart:math' as math;

import 'package:flame/components.dart';

import 'draft_tuning.dart';

/// Single-boss draft for the Phase 0B playable draft.
///
/// At most two phases, readable fixed-duration danger windows, and no
/// numeric inflation: phase two only tightens cadence and adds one attack
/// shape; health/damage magnitudes stay flat. No relay charging with other
/// units (rejected direction) — the boss acts alone.
enum DraftBossPhase { one, two }

enum DraftBossState {
  advancing,
  phaseShift,
  telegraphSlam,
  slamming,
  telegraphSweep,
  sweeping,
  exhausted,
  defeated,
}

enum DraftBossDangerShape { none, circle, arc }

enum DraftBossEventKind { slamResolved, sweepResolved, phaseChanged }

final class DraftBossDangerZone {
  const DraftBossDangerZone({
    required this.shape,
    required this.center,
    required this.radius,
    this.halfArcRadians = 0,
    this.direction,
  });

  final DraftBossDangerShape shape;
  final Vector2 center;
  final double radius;
  final double halfArcRadians;
  final Vector2? direction;

  bool contains(Vector2 point) {
    final delta = point - center;
    if (delta.length > radius) return false;
    if (shape == DraftBossDangerShape.circle) return true;
    final aim = direction;
    if (aim == null) return false;
    if (delta.length2 == 0) return true;
    final dot = aim
        .normalized()
        .dot(delta.normalized())
        .clamp(-1.0, 1.0);
    return math.acos(dot) <= halfArcRadians;
  }
}

final class DraftBossEvent {
  const DraftBossEvent({
    required this.kind,
    this.hitPlayer = false,
    this.damage = 0,
  });

  final DraftBossEventKind kind;
  final bool hitPlayer;
  final double damage;
}

final class DraftBossBrain {
  DraftBossBrain({required Vector2 spawn}) : position = spawn.clone();

  Vector2 position;
  double health = PlayableDraftTuning.bossMaxHealth;
  DraftBossPhase phase = DraftBossPhase.one;
  bool phaseSwitched = false;
  DraftBossState state = DraftBossState.advancing;
  double stateRemaining = 0;
  double attackCooldown = PlayableDraftTuning.bossAttackCooldownPhaseOne * 0.6;
  DraftBossDangerZone? activeZone;
  int attackCounter = 0;
  bool _pendingPhaseEvent = false;

  bool get defeated => state == DraftBossState.defeated;

  double get incomingDamageMultiplier =>
      state == DraftBossState.exhausted
          ? PlayableDraftTuning.bossExhaustedDamageMultiplier
          : 1.0;

  List<DraftBossEvent> advance(double dt, Vector2 playerPosition) {
    final events = <DraftBossEvent>[];
    if (_pendingPhaseEvent) {
      _pendingPhaseEvent = false;
      events.add(const DraftBossEvent(kind: DraftBossEventKind.phaseChanged));
    }
    if (defeated) return events;
    switch (state) {
      case DraftBossState.advancing:
        attackCooldown = math.max(0, attackCooldown - dt);
        final delta = playerPosition - position;
        final distance = delta.length;
        if (distance > PlayableDraftTuning.bossPreferredRange) {
          final speed = phase == DraftBossPhase.one
              ? PlayableDraftTuning.bossAdvanceSpeedPhaseOne
              : PlayableDraftTuning.bossAdvanceSpeedPhaseTwo;
          position += delta / distance * math.min(distance, speed * dt);
        } else if (attackCooldown <= 0) {
          _startNextAttack(playerPosition);
        }
      case DraftBossState.phaseShift:
        stateRemaining -= dt;
        if (stateRemaining <= 0) {
          state = DraftBossState.advancing;
          attackCooldown =
              PlayableDraftTuning.bossAttackCooldownPhaseTwo * 0.5;
        }
      case DraftBossState.telegraphSlam:
        stateRemaining -= dt;
        if (stateRemaining <= 0) {
          state = DraftBossState.slamming;
          stateRemaining = PlayableDraftTuning.bossSlamSeconds;
          events.add(_resolveStrike(playerPosition, isSlam: true));
        }
      case DraftBossState.slamming:
        stateRemaining -= dt;
        if (stateRemaining <= 0) {
          state = DraftBossState.exhausted;
          stateRemaining = PlayableDraftTuning.bossExhaustedSeconds;
          activeZone = null;
        }
      case DraftBossState.telegraphSweep:
        stateRemaining -= dt;
        if (stateRemaining <= 0) {
          state = DraftBossState.sweeping;
          stateRemaining = PlayableDraftTuning.bossSweepSeconds;
          events.add(_resolveStrike(playerPosition, isSlam: false));
        }
      case DraftBossState.sweeping:
        stateRemaining -= dt;
        if (stateRemaining <= 0) {
          state = DraftBossState.exhausted;
          stateRemaining = PlayableDraftTuning.bossExhaustedSeconds;
          activeZone = null;
        }
      case DraftBossState.exhausted:
        stateRemaining -= dt;
        if (stateRemaining <= 0) {
          state = DraftBossState.advancing;
          attackCooldown = phase == DraftBossPhase.one
              ? PlayableDraftTuning.bossAttackCooldownPhaseOne
              : PlayableDraftTuning.bossAttackCooldownPhaseTwo;
        }
      case DraftBossState.defeated:
        break;
    }
    return events;
  }

  void takeDamage(double amount) {
    if (defeated) return;
    health -= amount * incomingDamageMultiplier;
    if (health <= 0) {
      health = 0;
      state = DraftBossState.defeated;
      activeZone = null;
      return;
    }
    final threshold =
        PlayableDraftTuning.bossMaxHealth *
        PlayableDraftTuning.bossPhaseTwoFraction;
    if (!phaseSwitched && health <= threshold) {
      phaseSwitched = true;
      phase = DraftBossPhase.two;
      state = DraftBossState.phaseShift;
      stateRemaining = PlayableDraftTuning.bossPhaseShiftSeconds;
      activeZone = null;
      _pendingPhaseEvent = true;
    }
  }

  void _startNextAttack(Vector2 playerPosition) {
    final useSweep = phase == DraftBossPhase.two && attackCounter.isOdd;
    attackCounter++;
    if (useSweep) {
      final delta = playerPosition - position;
      final direction = delta.length2 > 0.01
          ? delta.normalized()
          : Vector2(1, 0);
      activeZone = DraftBossDangerZone(
        shape: DraftBossDangerShape.arc,
        center: position.clone(),
        radius: PlayableDraftTuning.bossSweepRadius,
        halfArcRadians: PlayableDraftTuning.bossSweepHalfArc,
        direction: direction,
      );
      state = DraftBossState.telegraphSweep;
      stateRemaining = PlayableDraftTuning.bossSweepTelegraphSeconds;
    } else {
      activeZone = DraftBossDangerZone(
        shape: DraftBossDangerShape.circle,
        center: position.clone(),
        radius: PlayableDraftTuning.bossSlamRadius,
      );
      state = DraftBossState.telegraphSlam;
      stateRemaining = PlayableDraftTuning.bossSlamTelegraphSeconds;
    }
  }

  DraftBossEvent _resolveStrike(Vector2 playerPosition, {required bool isSlam}) {
    final zone = activeZone;
    final hit = zone != null && zone.contains(playerPosition);
    return DraftBossEvent(
      kind: isSlam
          ? DraftBossEventKind.slamResolved
          : DraftBossEventKind.sweepResolved,
      hitPlayer: hit,
      damage: isSlam
          ? PlayableDraftTuning.bossSlamDamage
          : PlayableDraftTuning.bossSweepDamage,
    );
  }
}
