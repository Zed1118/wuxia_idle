import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/encounter/encounter_events.dart';
import 'package:phase0minus_probe/phase0b/encounter/encounter_orchestrator.dart';
import 'package:phase0minus_probe/phase0b/playable/style_profiles.dart';

EncounterOrchestrator _enemyScenario() => EncounterOrchestrator(
  seed: 7,
  style: DraftStyleKind.surgeCurrent,
  heroStart: Vector2(1600, 500),
  groups: const [
    EncounterGroupSetup(id: 0, count: 4, seed: 7, cameraLeft: 1400),
  ],
  commands: const [
    EncounterCommand(at: 2.5, kind: EncounterCommandKind.castGather),
    EncounterCommand(at: 9.1, kind: EncounterCommandKind.castGather),
    EncounterCommand(at: 15.8, kind: EncounterCommandKind.castGather),
    EncounterCommand(at: 22.4, kind: EncounterCommandKind.castClear),
  ],
);

// The boss spawns 150px east of the hero, inside the east-facing basic arc,
// so basics land continuously: they fund qi for the scripted clears and push
// the boss through phase 1 → phase 2 → defeat.
EncounterOrchestrator _bossScenario() => EncounterOrchestrator(
  seed: 11,
  style: DraftStyleKind.surgeCurrent,
  heroStart: Vector2(1600, 500),
  bossSpawn: Vector2(1750, 500),
  commands: const [
    EncounterCommand(at: 4.0, kind: EncounterCommandKind.castClear),
    EncounterCommand(at: 8.0, kind: EncounterCommandKind.castClear),
    EncounterCommand(at: 12.0, kind: EncounterCommandKind.castClear),
    EncounterCommand(at: 16.0, kind: EncounterCommandKind.castClear),
  ],
);

void main() {
  const dt = 1.0 / 60.0;

  group('enemy encounter', () {
    test('enter → telegraph → strike → retreat chain and full clear', () {
      final orchestrator = _enemyScenario();
      orchestrator.runSeconds(40, dt: dt);
      final events = orchestrator.events;

      final entered = events.whereType<EnemyEntered>().toList();
      final telegraphs = events.whereType<EnemyTelegraphStarted>().toList();
      final strikes = events.whereType<EnemyStrikeResolved>().toList();
      final retreats = events.whereType<EnemyRetreated>().toList();
      final defeats = events
          .whereType<EnemyDamaged>()
          .where((event) => event.defeated)
          .toList();

      expect(entered.length, 4);
      expect(telegraphs, isNotEmpty);
      expect(strikes, isNotEmpty);
      expect(retreats, isNotEmpty);
      expect(defeats.length, 4);
      expect(events.whereType<GroupCleared>().length, 1);

      // Per-enemy ordering: enter before first telegraph before first strike
      // before first retreat.
      for (final enter in entered) {
        final enemyTelegraphs = telegraphs
            .where((event) => event.enemyId == enter.enemyId)
            .toList();
        final enemyStrikes = strikes
            .where((event) => event.enemyId == enter.enemyId)
            .toList();
        final enemyRetreats = retreats
            .where((event) => event.enemyId == enter.enemyId)
            .toList();
        expect(enemyTelegraphs, isNotEmpty);
        expect(enemyStrikes, isNotEmpty);
        expect(enemyRetreats, isNotEmpty);
        expect(enter.time, lessThanOrEqualTo(enemyTelegraphs.first.time));
        expect(enemyTelegraphs.first.time, lessThan(enemyStrikes.first.time));
        expect(enemyStrikes.first.time, lessThan(enemyRetreats.first.time));
      }

      final concluded = events.whereType<BattleConcluded>().toList();
      expect(concluded, hasLength(1));
      expect(concluded.single.outcome, EncounterOutcome.victory);
      // After conclusion, advance is a no-op.
      final countBefore = events.length;
      orchestrator.advance(dt);
      expect(orchestrator.events.length, countBefore);
    });

    test('is deterministic for fixed seed + dt and diverges across seeds', () {
      final first = _enemyScenario().runSeconds(40, dt: dt);
      final second = _enemyScenario().runSeconds(40, dt: dt);
      expect(
        first.events.map((event) => event.signature),
        equals(second.events.map((event) => event.signature)),
      );
      expect(
        first.events.map((event) => event.time),
        equals(second.events.map((event) => event.time)),
      );

      final otherSeed = EncounterOrchestrator(
        seed: 7,
        style: DraftStyleKind.surgeCurrent,
        heroStart: Vector2(1600, 500),
        groups: const [
          EncounterGroupSetup(id: 0, count: 4, seed: 99, cameraLeft: 1400),
        ],
      ).runSeconds(40, dt: dt);
      expect(
        otherSeed.events.map((event) => event.signature),
        isNot(equals(first.events.map((event) => event.signature))),
      );
    });
  });

  group('boss encounter', () {
    test('phase 1 → phase 2 → defeat chain', () {
      final orchestrator = _bossScenario();
      orchestrator.runSeconds(50, dt: dt);
      final events = orchestrator.events;

      final telegraphs = events.whereType<BossTelegraphStarted>().toList();
      final phaseChanges = events.whereType<BossPhaseChanged>().toList();
      final exhausted = events.whereType<BossExhaustedStarted>().toList();
      final damages = events.whereType<BossDamaged>().toList();
      final defeats = events.whereType<BossDefeated>().toList();
      final loot = events.whereType<LootRequested>().toList();

      expect(telegraphs, isNotEmpty);
      expect(telegraphs.first.shape, EncounterDangerShape.circle);
      expect(exhausted, isNotEmpty);
      expect(damages, isNotEmpty);
      expect(phaseChanges, hasLength(1));
      expect(phaseChanges.single.phase, 2);
      expect(phaseChanges.single.total, 2);
      expect(defeats, hasLength(1));
      expect(loot, hasLength(1));
      expect(loot.single.sourceId, isNotEmpty);

      final firstDamage = damages.first.time;
      final phaseAt = phaseChanges.single.time;
      final defeatAt = defeats.single.time;
      expect(firstDamage, lessThan(phaseAt));
      expect(phaseAt, lessThan(defeatAt));

      final concluded = events.whereType<BattleConcluded>().single;
      expect(concluded.outcome, EncounterOutcome.victory);
      expect(concluded.time, greaterThanOrEqualTo(defeatAt));
    });

    test('is deterministic for fixed seed + dt', () {
      final first = _bossScenario().runSeconds(50, dt: dt);
      final second = _bossScenario().runSeconds(50, dt: dt);
      expect(
        first.events.map((event) => event.signature),
        equals(second.events.map((event) => event.signature)),
      );
      expect(
        first.events.map((event) => event.time),
        equals(second.events.map((event) => event.time)),
      );
    });
  });
}
