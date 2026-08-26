import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/playable/boss_brain.dart';
import 'package:phase0minus_probe/phase0b/playable/draft_tuning.dart';

List<DraftBossEvent> _advanceUntil(
  DraftBossBrain boss,
  Vector2 player, {
  required bool Function(DraftBossBrain) condition,
  double maxSeconds = 30,
}) {
  final events = <DraftBossEvent>[];
  var t = 0.0;
  while (t < maxSeconds && !condition(boss)) {
    events.addAll(boss.advance(1 / 60, player));
    t += 1 / 60;
  }
  return events;
}

void main() {
  test(
    'phase one only uses the readable slam, hitting only inside the zone',
    () {
      final boss = DraftBossBrain(spawn: Vector2(2000, 500));
      // Close enough to be inside slam radius once the boss holds range.
      final player = Vector2(2120, 500);
      final events = <DraftBossEvent>[];
      var t = 0.0;
      while (t < 20 && events.length < 3) {
        events.addAll(boss.advance(1 / 60, player));
        t += 1 / 60;
      }
      final resolved = events
          .where((event) => event.kind != DraftBossEventKind.phaseChanged)
          .toList();
      expect(resolved, isNotEmpty);
      for (final event in resolved) {
        expect(event.kind, DraftBossEventKind.slamResolved);
      }
      expect(resolved.any((event) => event.hitPlayer), isTrue);
      expect(
        resolved.firstWhere((event) => event.hitPlayer).damage,
        PlayableDraftTuning.bossSlamDamage,
      );
    },
  );

  test('a player holding just outside slam range is never hit', () {
    final boss = DraftBossBrain(spawn: Vector2(2000, 500));
    // Boss stops at preferred range 235, slam radius is 150: always safe.
    final player = Vector2(2235, 500);
    final events = <DraftBossEvent>[];
    var t = 0.0;
    while (t < 25) {
      events.addAll(boss.advance(1 / 60, player));
      t += 1 / 60;
    }
    final resolved = events
        .where((event) => event.kind != DraftBossEventKind.phaseChanged)
        .toList();
    expect(resolved, isNotEmpty);
    for (final event in resolved) {
      expect(event.hitPlayer, isFalse);
    }
  });

  test('phase switch fires exactly once at the health threshold', () {
    final boss = DraftBossBrain(spawn: Vector2(2000, 500));
    boss.takeDamage(300);
    expect(boss.phase, DraftBossPhase.one);
    expect(boss.phaseSwitched, isFalse);
    boss.takeDamage(100);
    expect(boss.phase, DraftBossPhase.two);
    expect(boss.state, DraftBossState.phaseShift);
    final events = _advanceUntil(
      boss,
      Vector2(2200, 500),
      condition: (brain) => brain.state == DraftBossState.advancing,
    );
    expect(
      events.where((event) => event.kind == DraftBossEventKind.phaseChanged),
      hasLength(1),
    );
    boss.takeDamage(50);
    expect(boss.phase, DraftBossPhase.two);
    final moreEvents = boss.advance(1 / 60, Vector2(2200, 500));
    expect(
      moreEvents.where(
        (event) => event.kind == DraftBossEventKind.phaseChanged,
      ),
      isEmpty,
    );
  });

  test('phase two adds the sweep shape and a tighter cadence', () {
    final boss = DraftBossBrain(spawn: Vector2(2000, 500));
    final player = Vector2(2150, 500);
    _advanceUntil(
      boss,
      player,
      condition: (brain) => brain.state == DraftBossState.advancing,
      maxSeconds: 5,
    );
    boss.takeDamage(PlayableDraftTuning.bossMaxHealth * 0.6);
    final events = <DraftBossEvent>[];
    var t = 0.0;
    var sawSweep = false;
    while (t < 40 && !sawSweep) {
      events.addAll(boss.advance(1 / 60, player));
      sawSweep = events.any(
        (event) => event.kind == DraftBossEventKind.sweepResolved,
      );
      t += 1 / 60;
    }
    expect(sawSweep, isTrue);
    final sweep = events.firstWhere(
      (event) => event.kind == DraftBossEventKind.sweepResolved,
    );
    expect(sweep.damage, PlayableDraftTuning.bossSweepDamage);
  });

  test('exhaustion after each strike is the vulnerable punish window', () {
    final boss = DraftBossBrain(spawn: Vector2(2000, 500));
    final player = Vector2(2120, 500);
    _advanceUntil(
      boss,
      player,
      condition: (brain) => brain.state == DraftBossState.exhausted,
    );
    expect(boss.state, DraftBossState.exhausted);
    expect(
      boss.incomingDamageMultiplier,
      PlayableDraftTuning.bossExhaustedDamageMultiplier,
    );
    final healthBefore = boss.health;
    boss.takeDamage(10);
    expect(
      healthBefore - boss.health,
      closeTo(10 * PlayableDraftTuning.bossExhaustedDamageMultiplier, 1e-9),
    );
    _advanceUntil(
      boss,
      player,
      condition: (brain) => brain.state != DraftBossState.exhausted,
    );
    expect(boss.incomingDamageMultiplier, 1.0);
  });

  test('danger zones expose fixed readable shapes during telegraphs', () {
    final slamZone = DraftBossDangerZone(
      shape: DraftBossDangerShape.circle,
      center: Vector2(100, 100),
      radius: 150,
    );
    expect(slamZone.contains(Vector2(200, 100)), isTrue);
    expect(slamZone.contains(Vector2(260, 100)), isFalse);
    final sweepZone = DraftBossDangerZone(
      shape: DraftBossDangerShape.arc,
      center: Vector2(0, 0),
      radius: 210,
      halfArcRadians: 0.9,
      direction: Vector2(1, 0),
    );
    expect(sweepZone.contains(Vector2(180, 0)), isTrue);
    expect(sweepZone.contains(Vector2(0, 180)), isFalse);
    expect(sweepZone.contains(Vector2(300, 0)), isFalse);
  });

  test('defeat is terminal and emits nothing further', () {
    final boss = DraftBossBrain(spawn: Vector2(2000, 500));
    boss.takeDamage(99999);
    expect(boss.defeated, isTrue);
    expect(boss.health, 0);
    for (var tick = 0; tick < 240; tick++) {
      expect(boss.advance(1 / 60, Vector2(2100, 500)), isEmpty);
    }
    boss.takeDamage(50);
    expect(boss.defeated, isTrue);
  });
}
