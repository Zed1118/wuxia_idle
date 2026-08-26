import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/playable/draft_tuning.dart';
import 'package:phase0minus_probe/phase0b/playable/enemy_brain.dart';

Vector2 _scriptedHero(double t) =>
    Vector2(640 + 140 * math.sin(t * 0.5), 500 + 60 * math.sin(t * 0.23));

({List<Vector2> finalPositions, List<DraftEnemyStrikeEvent> strikes}) _runSim({
  required int seed,
  required int count,
  required double seconds,
  double dt = 1 / 30,
}) {
  final sim = DraftEnemyGroupSim(count: count, seed: seed);
  sim.activate(cameraLeft: 0);
  final strikes = <DraftEnemyStrikeEvent>[];
  var t = 0.0;
  while (t < seconds) {
    strikes.addAll(sim.advance(dt, _scriptedHero(t)));
    t += dt;
  }
  return (
    finalPositions: sim.enemies.map((enemy) => enemy.position.clone()).toList(),
    strikes: strikes,
  );
}

void main() {
  test('spawns enter from outside the 1280px viewport, in batches', () {
    final sim = DraftEnemyGroupSim(count: 20, seed: 7);
    sim.activate(cameraLeft: 0);
    expect(sim.enemies, hasLength(20));
    for (final enemy in sim.enemies) {
      final outside =
          enemy.spawnPosition.x < -100 ||
          enemy.spawnPosition.x > PlayableDraftTuning.viewWidth + 100;
      expect(outside, isTrue, reason: 'enemy ${enemy.id} spawned on-screen');
      expect(
        enemy.spawnPosition.y,
        inInclusiveRange(
          PlayableDraftTuning.combatTop,
          PlayableDraftTuning.combatBottom,
        ),
      );
    }
    expect(sim.enemies.first.spawnDelay, 0);
    expect(sim.enemies.last.spawnDelay, greaterThan(1.5));
  });

  test('no enemy ever penetrates the hero readability pocket', () {
    final sim = DraftEnemyGroupSim(count: 20, seed: 11);
    sim.activate(cameraLeft: 0);
    var t = 0.0;
    const dt = 1 / 30;
    while (t < 45) {
      final hero = _scriptedHero(t);
      sim.advance(dt, hero);
      for (final enemy in sim.enemies) {
        if (!enemy.alive || !enemy.hasEntered) continue;
        expect(
          enemy.position.distanceTo(hero),
          greaterThanOrEqualTo(PlayableDraftTuning.pocketRadius - 0.001),
          reason: 'enemy ${enemy.id} inside pocket at t=$t',
        );
      }
      t += dt;
    }
  });

  test(
    'attack telegraphs stay bounded and strikes are followed by retreat',
    () {
      final sim = DraftEnemyGroupSim(count: 20, seed: 13);
      sim.activate(cameraLeft: 0);
      var observedRetreat = false;
      var maxConcurrentTelegraphs = 0;
      var t = 0.0;
      const dt = 1 / 30;
      while (t < 40) {
        final hero = _scriptedHero(t);
        sim.advance(dt, hero);
        final telegraphing = sim.enemies
            .where((enemy) => enemy.state == DraftEnemyState.telegraphing)
            .length;
        maxConcurrentTelegraphs = maxConcurrentTelegraphs > telegraphing
            ? maxConcurrentTelegraphs
            : telegraphing;
        observedRetreat =
            observedRetreat ||
            sim.enemies.any(
              (enemy) => enemy.state == DraftEnemyState.retreating,
            );
        t += dt;
      }
      expect(
        maxConcurrentTelegraphs,
        lessThanOrEqualTo(PlayableDraftTuning.attackTokenLimit),
      );
      expect(maxConcurrentTelegraphs, greaterThan(0));
      expect(observedRetreat, isTrue);
    },
  );

  test('same seed and hero script replay identical trajectories', () {
    final first = _runSim(seed: 21, count: 12, seconds: 12);
    final second = _runSim(seed: 21, count: 12, seconds: 12);
    final third = _runSim(seed: 22, count: 12, seconds: 12);
    expect(first.strikes.length, second.strikes.length);
    for (var index = 0; index < first.strikes.length; index++) {
      expect(first.strikes[index].enemyId, second.strikes[index].enemyId);
      expect(first.strikes[index].position, second.strikes[index].position);
    }
    expect(first.finalPositions, second.finalPositions);
    // A different seed must produce a different layout, not a no-op.
    expect(third.finalPositions, isNot(first.finalPositions));
  });

  test(
    'slow field reduces closing speed without changing target selection',
    () {
      final baseline = DraftEnemyGroupSim(count: 1, seed: 5);
      final slowed = DraftEnemyGroupSim(count: 1, seed: 5);
      baseline.activate(cameraLeft: 0);
      slowed.activate(cameraLeft: 0);
      final hero = Vector2(700, 500);
      const dt = 1 / 30;
      for (var tick = 0; tick < 90; tick++) {
        baseline.advance(dt, hero);
        slowed.advance(dt, hero);
        if (tick == 30) {
          slowed.applySlowField(center: hero, radius: 900, duration: 10);
        }
      }
      final baselineEnemy = baseline.enemies.single;
      final slowedEnemy = slowed.enemies.single;
      expect(
        slowedEnemy.position.distanceTo(hero),
        greaterThan(baselineEnemy.position.distanceTo(hero)),
      );
    },
  );

  test('pull gathers enemies toward the cast point', () {
    final sim = DraftEnemyGroupSim(count: 6, seed: 9);
    sim.activate(cameraLeft: 0);
    final hero = Vector2(640, 500);
    for (var tick = 0; tick < 240; tick++) {
      sim.advance(1 / 30, hero);
    }
    final center = hero + Vector2(260, 0);
    final before = sim.enemies
        .where((enemy) => enemy.alive && enemy.hasEntered)
        .map((enemy) => enemy.position.distanceTo(center))
        .reduce((a, b) => a + b);
    final pulled = sim.applyPull(
      center: center,
      radius: 300,
      targetRadius: 100,
      maxDistance: 220,
    );
    final after = sim.enemies
        .where((enemy) => enemy.alive && enemy.hasEntered)
        .map((enemy) => enemy.position.distanceTo(center))
        .reduce((a, b) => a + b);
    expect(pulled, greaterThan(0));
    expect(after, lessThan(before));
  });

  test('defeating a telegraphing enemy frees its attack token', () {
    final sim = DraftEnemyGroupSim(count: 12, seed: 31);
    sim.activate(cameraLeft: 0);
    final hero = Vector2(640, 500);
    DraftEnemy? caught;
    for (var tick = 0; tick < 900 && caught == null; tick++) {
      sim.advance(1 / 30, hero);
      for (final enemy in sim.enemies) {
        if (enemy.state == DraftEnemyState.telegraphing) {
          caught = enemy;
          break;
        }
      }
    }
    final victim = caught;
    expect(victim, isNotNull);
    final tokensBefore = sim.tokensInUse;
    sim.applyHit(victim!.id, 999);
    expect(sim.tokensInUse, tokensBefore - 1);
    expect(victim.state, DraftEnemyState.defeated);
  });
}
