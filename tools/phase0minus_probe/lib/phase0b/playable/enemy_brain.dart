import 'dart:math' as math;

import 'package:flame/components.dart';

import 'draft_tuning.dart';

/// Draft enemy AI for the Phase 0B playable draft.
///
/// Deliberate non-goals, per `docs/spec/rejected_task_registry.md`:
/// - no enemy relay/chain telegraph windows (multi-unit hand-off charging);
///   token grants depend only on token availability and each enemy's own
///   cooldown, never on another enemy's telegraph ending;
/// - no focus-fire symmetry (target selection never reads target state);
///   every enemy simply closes on the hero's current position.
enum DraftEnemyState {
  waiting,
  entering,
  ringing,
  telegraphing,
  striking,
  retreating,
  defeated,
}

final class DraftEnemyStrikeEvent {
  const DraftEnemyStrikeEvent({
    required this.enemyId,
    required this.position,
    required this.damage,
  });

  final int enemyId;
  final Vector2 position;
  final double damage;
}

final class DraftEnemy {
  DraftEnemy._({
    required this.id,
    required this.spawnPosition,
    required this.spawnDelay,
    required this.slotAngle,
  }) : position = spawnPosition.clone();

  final int id;
  final Vector2 spawnPosition;
  final double spawnDelay;
  final double slotAngle;
  Vector2 position;
  DraftEnemyState state = DraftEnemyState.waiting;
  double stateRemaining = 0;
  double attackCooldown = PlayableDraftTuning.attackCooldownBase;
  double slowRemaining = 0;
  double health = PlayableDraftTuning.enemyHealth;
  Vector2 retreatDirection = Vector2(1, 0);

  bool get alive => state != DraftEnemyState.defeated && health > 0;
  bool get hasEntered => state != DraftEnemyState.waiting;
}

final class DraftEnemyGroupSim {
  DraftEnemyGroupSim({required int count, required int seed})
    : _count = count,
      _random = math.Random(seed);

  final int _count;
  final math.Random _random;
  final List<DraftEnemy> enemies = [];
  bool activated = false;
  double activationElapsed = 0;
  int tokensInUse = 0;

  int get aliveCount => enemies.where((enemy) => enemy.alive).length;

  void activate({required double cameraLeft}) {
    if (activated) return;
    activated = true;
    for (var id = 0; id < _count; id++) {
      final fromLeft = id % 3 == 0;
      final spreadX = 40.0 + _random.nextInt(180);
      final x = fromLeft
          ? cameraLeft - PlayableDraftTuning.spawnOffscreenMargin - spreadX
          : cameraLeft +
                PlayableDraftTuning.viewWidth +
                PlayableDraftTuning.spawnOffscreenMargin +
                spreadX;
      final y =
          PlayableDraftTuning.combatTop +
          24 +
          _random.nextDouble() *
              (PlayableDraftTuning.combatBottom -
                  PlayableDraftTuning.combatTop -
                  48);
      final slotAngle =
          id * 2 * math.pi / _count + (_random.nextDouble() - 0.5) * 0.25;
      enemies.add(
        DraftEnemy._(
          id: id,
          spawnPosition: Vector2(x, y),
          spawnDelay: id * PlayableDraftTuning.spawnBatchInterval,
          slotAngle: slotAngle,
        ),
      );
    }
  }

  List<DraftEnemyStrikeEvent> advance(double dt, Vector2 playerPosition) {
    final events = <DraftEnemyStrikeEvent>[];
    if (!activated) return events;
    activationElapsed += dt;
    for (final enemy in enemies) {
      if (!enemy.alive) continue;
      enemy.slowRemaining = math.max(0, enemy.slowRemaining - dt);
      final speedFactor = enemy.slowRemaining > 0
          ? PlayableDraftTuning.slowFieldSpeedFactor
          : 1.0;
      switch (enemy.state) {
        case DraftEnemyState.waiting:
          if (activationElapsed >= enemy.spawnDelay) {
            enemy.state = DraftEnemyState.entering;
          }
        case DraftEnemyState.entering:
        case DraftEnemyState.ringing:
          final anchor = _ringAnchor(enemy, playerPosition);
          final delta = anchor - enemy.position;
          final distance = delta.length;
          if (distance > PlayableDraftTuning.enterCompletionDistance) {
            final step = math.min(
              distance,
              PlayableDraftTuning.enemyApproachSpeed * speedFactor * dt,
            );
            enemy.position += delta / distance * step;
          }
          if (enemy.state == DraftEnemyState.entering &&
              (distance <= PlayableDraftTuning.enterCompletionDistance ||
                  enemy.position.distanceTo(playerPosition) <=
                      PlayableDraftTuning.ringRadius + 24)) {
            enemy.state = DraftEnemyState.ringing;
          }
          enemy.attackCooldown = math.max(0, enemy.attackCooldown - dt);
        case DraftEnemyState.telegraphing:
          enemy.stateRemaining -= dt;
          if (enemy.stateRemaining <= 0) {
            enemy.state = DraftEnemyState.striking;
            enemy.stateRemaining = PlayableDraftTuning.strikeSeconds;
            if (enemy.position.distanceTo(playerPosition) <=
                PlayableDraftTuning.strikeRange) {
              events.add(
                DraftEnemyStrikeEvent(
                  enemyId: enemy.id,
                  position: enemy.position.clone(),
                  damage: PlayableDraftTuning.strikeDamage,
                ),
              );
            }
          }
        case DraftEnemyState.striking:
          enemy.stateRemaining -= dt;
          if (enemy.stateRemaining <= 0) {
            enemy.state = DraftEnemyState.retreating;
            enemy.stateRemaining = PlayableDraftTuning.retreatSeconds;
            final away = enemy.position - playerPosition;
            enemy.retreatDirection = away.length2 > 0.01
                ? away.normalized()
                : Vector2(math.cos(enemy.slotAngle), math.sin(enemy.slotAngle));
            tokensInUse = math.max(0, tokensInUse - 1);
          }
        case DraftEnemyState.retreating:
          enemy.stateRemaining -= dt;
          enemy.position +=
              enemy.retreatDirection *
              PlayableDraftTuning.enemyRetreatSpeed *
              speedFactor *
              dt;
          if (enemy.stateRemaining <= 0) {
            enemy.state = DraftEnemyState.ringing;
            enemy.attackCooldown =
                PlayableDraftTuning.attackCooldownBase +
                (enemy.id % 5) * PlayableDraftTuning.attackCooldownIdSpread;
          }
        case DraftEnemyState.defeated:
          break;
      }
      if (enemy.hasEntered && enemy.alive) {
        _clampToCombatBand(enemy);
        _enforcePocket(enemy, playerPosition);
      }
    }
    _grantAttackTokens(playerPosition);
    return events;
  }

  /// Returns true when the hit defeats the enemy.
  bool applyHit(int id, double damage) {
    DraftEnemy? target;
    for (final enemy in enemies) {
      if (enemy.id == id) {
        target = enemy;
        break;
      }
    }
    final victim = target;
    if (victim == null || !victim.alive) return false;
    victim.health -= damage;
    if (victim.health > 0) return false;
    victim.health = 0;
    if (victim.state == DraftEnemyState.telegraphing ||
        victim.state == DraftEnemyState.striking) {
      tokensInUse = math.max(0, tokensInUse - 1);
    }
    victim.state = DraftEnemyState.defeated;
    return true;
  }

  int applyPull({
    required Vector2 center,
    required double radius,
    required double targetRadius,
    required double maxDistance,
  }) {
    var pulled = 0;
    for (final enemy in enemies) {
      if (!enemy.alive || !enemy.hasEntered) continue;
      if (enemy.position.distanceTo(center) > radius) continue;
      final delta = enemy.position - center;
      if (delta.length <= targetRadius) continue;
      final destination = center + delta.normalized() * targetRadius;
      final move = destination - enemy.position;
      enemy.position += move.normalized() * math.min(maxDistance, move.length);
      pulled++;
    }
    return pulled;
  }

  int applySlowField({
    required Vector2 center,
    required double radius,
    required double duration,
  }) {
    var slowed = 0;
    for (final enemy in enemies) {
      if (!enemy.alive || !enemy.hasEntered) continue;
      if (enemy.position.distanceTo(center) > radius) continue;
      enemy.slowRemaining = math.max(enemy.slowRemaining, duration);
      slowed++;
    }
    return slowed;
  }

  Vector2 _ringAnchor(DraftEnemy enemy, Vector2 playerPosition) {
    final anchor = Vector2(
      playerPosition.x +
          math.cos(enemy.slotAngle) * PlayableDraftTuning.ringRadius,
      playerPosition.y +
          math.sin(enemy.slotAngle) * PlayableDraftTuning.ringRadius,
    );
    anchor.y = anchor.y.clamp(
      PlayableDraftTuning.combatTop + 20,
      PlayableDraftTuning.combatBottom - 20,
    );
    return anchor;
  }

  void _clampToCombatBand(DraftEnemy enemy) {
    enemy.position
      ..x = enemy.position.x.clamp(24, PlayableDraftTuning.worldWidth - 24)
      ..y = enemy.position.y.clamp(
        PlayableDraftTuning.combatTop + 12,
        PlayableDraftTuning.combatBottom - 12,
      );
  }

  void _enforcePocket(DraftEnemy enemy, Vector2 playerPosition) {
    final delta = enemy.position - playerPosition;
    final distance = delta.length;
    if (distance >= PlayableDraftTuning.pocketRadius) return;
    final outward = distance > 0.001
        ? delta / distance
        : Vector2(math.cos(enemy.slotAngle), math.sin(enemy.slotAngle));
    enemy.position =
        playerPosition + outward * PlayableDraftTuning.pocketRadius;
  }

  void _grantAttackTokens(Vector2 playerPosition) {
    for (final enemy in enemies) {
      if (tokensInUse >= PlayableDraftTuning.attackTokenLimit) break;
      if (!enemy.alive ||
          enemy.state != DraftEnemyState.ringing ||
          enemy.attackCooldown > 0) {
        continue;
      }
      if (enemy.position.distanceTo(playerPosition) >
          PlayableDraftTuning.ringRadius + 60) {
        continue;
      }
      enemy.state = DraftEnemyState.telegraphing;
      enemy.stateRemaining = PlayableDraftTuning.telegraphSeconds;
      tokensInUse++;
    }
  }
}
