import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repo;
  setUpAll(() async => repo = await loadTestGameRepository());

  test('production routes exactly the first seven authored floors', () async {
    const authority = Phase0aTowerEncounterRouteAuthority.production();
    expect(repo.towerFloors, hasLength(49));
    expect(authority.migratedFloorIndices, {1, 2, 3, 4, 5, 6, 7});
    for (final floor in repo.towerFloors) {
      final session = await _session(repo, floor.floorIndex, 1);
      expect(
        session.routeMode,
        floor.floorIndex <= 7
            ? Phase0aTowerEncounterRouteMode.migrated
            : Phase0aTowerEncounterRouteMode.legacy,
        reason: 'production route for floor ${floor.floorIndex}',
      );
      expect(
        session.sourceEnemyDefIdsInEntryOrder,
        floor.enemyTeam.map((enemy) => enemy.id),
      );
      expect(session.encounterCount, 1);
      expect(session.activeLimit, floor.enemyTeam.length);
    }
  });

  for (var floor = 1; floor <= 7; floor++) {
    for (final cycle in [1, 2]) {
      test(
        'production floor $floor cycle $cycle retains combat and settlement',
        () async {
          final production = await _session(repo, floor, cycle);
          final legacy = await _session(repo, floor, cycle, legacy: true);
          expect(production.routeMode, Phase0aTowerEncounterRouteMode.migrated);
          expect(legacy.routeMode, Phase0aTowerEncounterRouteMode.legacy);
          final actual = _run(repo, production);
          final expected = _run(repo, legacy);
          expect(actual.outcome, Phase0aBattleOutcome.victory);
          expect(actual.outcome, expected.outcome);
          // Wave lifecycle records consume sequence numbers only on legacy.
          expect(actual.finalState.tick, expected.finalState.tick);
          expect(actual.finalState.player, expected.finalState.player);
          expect(actual.finalState.enemies, expected.finalState.enemies);
          expect(actual.finalState.skillSlots, expected.finalState.skillSlots);
          expect(actual.events.whereType<Phase0aWaveStarted>(), isEmpty);
          expect(expected.events.whereType<Phase0aWaveStarted>(), isNotEmpty);

          final actualSettlement = production.settle(
            outcome: actual.outcome,
            finalState: actual.finalState,
            events: actual.events,
          );
          final expectedSettlement = legacy.settle(
            outcome: expected.outcome,
            finalState: expected.finalState,
            events: expected.events,
          );
          expect(actualSettlement.result, expectedSettlement.result);
          expect(actualSettlement.totalTicks, expectedSettlement.totalTicks);
          expect(actualSettlement.totalDamage, expectedSettlement.totalDamage);
          expect(
            actualSettlement.criticalCount,
            expectedSettlement.criticalCount,
          );
          expect(
            actualSettlement.damageByCharacterId,
            expectedSettlement.damageByCharacterId,
          );
          expect(
            actualSettlement.playerCharacterId,
            expectedSettlement.playerCharacterId,
          );
          expect(actualSettlement.hadActions, expectedSettlement.hadActions);
          expect(
            actualSettlement.participants.map(
              (p) => [p.characterId, p.currentHp, p.maxHp],
            ),
            expectedSettlement.participants.map(
              (p) => [p.characterId, p.currentHp, p.maxHp],
            ),
          );
          expect(
            actualSettlement.skillCasts.map(
              (s) => [s.tick, s.characterId, s.skillId],
            ),
            expectedSettlement.skillCasts.map(
              (s) => [s.tick, s.characterId, s.skillId],
            ),
          );
        },
      );
    }
  }

  for (final floor in [1, 7]) {
    test(
      'production floor $floor never falls back on missing definitions',
      () async {
        final source = _MissingDefinition();
        await expectLater(
          _session(repo, floor, 1, definition: source),
          throwsStateError,
        );
        expect(source.calls, 1);
      },
    );
    test(
      'production floor $floor never falls back on missing runtime',
      () async {
        final source = _MissingRuntime();
        await expectLater(
          _session(repo, floor, 1, runtime: source),
          throwsStateError,
        );
        expect(source.calls, 1);
      },
    );
  }

  test(
    'floor eight retains compatibility without consulting typed sources',
    () async {
      final definition = _MissingDefinition();
      final runtime = _MissingRuntime();
      final session = await _session(
        repo,
        8,
        1,
        definition: definition,
        runtime: runtime,
      );
      expect(session.routeMode, Phase0aTowerEncounterRouteMode.legacy);
      expect(definition.calls, 0);
      expect(runtime.calls, 0);
    },
  );
}

Future<Phase0aTowerCombatSession> _session(
  GameRepository repo,
  int floor,
  int cycle, {
  bool legacy = false,
  Phase0aTowerEncounterDefinitionSource definition =
      const Phase0aDerivedTowerEncounterDefinitionSource(),
  Phase0aTowerEncounterRuntimeBindingSource runtime =
      const Phase0aDerivedTowerEncounterRuntimeBindingSource(),
}) => createFreshPhase0aTowerCombatSession(
  Phase0aTowerCombatSessionBuildRequest(
    contentRef: CombatContentRef.tower('tower_$floor'),
    floor: repo.getTowerFloor(floor),
    // Endurance fixture verifies routing equivalence, not floor difficulty.
    playerSnapshot: testCombatantSnapshot(
      realmTier: RealmTier.wuSheng,
      maxHp: 20000,
      internalForce: 15000,
      totalEquipmentAttack: 2000,
      includeProductionBasicAttack: true,
    ),
    numbers: repo.numbers,
    cycleIndex: cycle,
    rng: Random(20260912 + floor * 10 + cycle),
    routeAuthority: legacy
        ? Phase0aTowerEncounterRouteAuthority.migratedFloors({})
        : const Phase0aTowerEncounterRouteAuthority.production(),
    definitionSource: definition,
    runtimeBindingSource: runtime,
  ),
);

Phase0aHeadlessResult _run(
  GameRepository repo,
  Phase0aTowerCombatSession session,
) => Phase0aHeadlessRunner.runToEnd(
  flow: session.flow,
  bot: Phase0aPlayerBotAdapter(playerAdapter: session.playerAdapter),
  deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
  maxTicks: repo.numbers.phase0aArena.maxSimulationTicks,
);

class _MissingDefinition implements Phase0aTowerEncounterDefinitionSource {
  int calls = 0;
  @override
  CombatEncounterDef? load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
  }) {
    calls++;
    return null;
  }
}

class _MissingRuntime implements Phase0aTowerEncounterRuntimeBindingSource {
  int calls = 0;
  @override
  Phase0aTowerRuntimeBindingBundle? load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
    required CombatEncounterDef encounter,
    required int cycleIndex,
  }) {
    calls++;
    return null;
  }
}
