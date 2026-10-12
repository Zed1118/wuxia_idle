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
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/legacy_tower_session_reference.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repo;
  setUpAll(() async => repo = await loadTestGameRepository());

  test('production routes all 49 authored floors', () async {
    const authority = Phase0aTowerEncounterRouteAuthority.production();
    expect(repo.towerFloors, hasLength(49));
    expect(authority.migratedFloorIndices, {
      for (var floor = 1; floor <= 49; floor++) floor,
    });
    for (final floor in repo.towerFloors) {
      final session = await _session(repo, floor.floorIndex, 1);
      expect(
        session.routeMode,
        Phase0aTowerEncounterRouteMode.migrated,
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

  for (var floor = 1; floor <= 49; floor++) {
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
          expect(actual.outcome, expected.outcome);
          // Wave lifecycle records consume sequence numbers only on legacy.
          expect(actual.finalState.tick, expected.finalState.tick);
          expect(actual.finalState.player, expected.finalState.player);
          expect(
            actual.finalState.enemies.map(
              (actor) => _canonicalActor(actor, production),
            ),
            expected.finalState.enemies.map(
              (actor) => _canonicalActor(actor, legacy),
            ),
          );
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
          if (floor <= 7) {
            expect(actual.outcome, Phase0aBattleOutcome.victory);
          }
          expect(actual.outcome, isNot(Phase0aBattleOutcome.ongoing));
        },
      );
    }
  }

  for (final floor in [1, 7, 8, 14, 15, 21, 22, 28, 29, 35, 36, 42, 43, 49]) {
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

  for (final floor in [1, 8, 49]) {
    test('production rejects legacy authority for floor $floor', () async {
      final definition = _MissingDefinition();
      final runtime = _MissingRuntime();
      await expectLater(
        _session(
          repo,
          floor,
          1,
          authority: Phase0aTowerEncounterRouteAuthority.migratedFloors({}),
          definition: definition,
          runtime: runtime,
        ),
        throwsStateError,
      );
      expect(definition.calls, 0);
      expect(runtime.calls, 0);
    });
  }

  for (final floor in [0, 50]) {
    test('production rejects unauthored floor $floor', () async {
      final source = repo.getTowerFloor(1);
      final definition = _MissingDefinition();
      final runtime = _MissingRuntime();
      await expectLater(
        _session(
          repo,
          floor,
          1,
          floorDefinition: TowerFloorDef(
            floorIndex: floor,
            requiredRealm: source.requiredRealm,
            enemyTeam: source.enemyTeam,
          ),
          definition: definition,
          runtime: runtime,
        ),
        throwsArgumentError,
      );
      expect(definition.calls, 0);
      expect(runtime.calls, 0);
    });
  }
}

Future<Phase0aTowerCombatSession> _session(
  GameRepository repo,
  int floor,
  int cycle, {
  bool legacy = false,
  TowerFloorDef? floorDefinition,
  Phase0aTowerEncounterRouteAuthority authority =
      const Phase0aTowerEncounterRouteAuthority.production(),
  Phase0aTowerEncounterDefinitionSource definition =
      const Phase0aDerivedTowerEncounterDefinitionSource(),
  Phase0aTowerEncounterRuntimeBindingSource runtime =
      const Phase0aDerivedTowerEncounterRuntimeBindingSource(),
}) {
  final request = Phase0aTowerCombatSessionBuildRequest(
    contentRef: CombatContentRef.tower('tower_$floor'),
    floor: floorDefinition ?? repo.getTowerFloor(floor),
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
    routeAuthority: authority,
    definitionSource: definition,
    runtimeBindingSource: runtime,
  );
  return legacy
      ? createLegacyTowerSessionForReference(request)
      : createFreshPhase0aTowerCombatSession(request);
}

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

// Legacy stores authored guardian ids and typed encounters store runtime
// actor ids. Resolve that identity representation only; preserve every actor
// field in the equality assertion, including all runtime combat state.
List<String> _guardianIds(
  List<String> ids,
  Phase0aTowerCombatSession session,
) => [
  for (final id in ids)
    session.sourceEnemyDefIdByActorId.containsKey(id)
        ? id
        : session.sourceEnemyDefIdByActorId.entries
              .singleWhere((e) => e.value == id)
              .key,
];
Phase0aActor _canonicalActor(
  Phase0aActor a,
  Phase0aTowerCombatSession session,
) => Phase0aActor(
  id: a.id,
  side: a.side,
  position: a.position,
  facing: a.facing,
  maxHealth: a.maxHealth,
  currentHealth: a.currentHealth,
  moveSpeed: a.moveSpeed,
  qiCurrent: a.qiCurrent,
  qiMax: a.qiMax,
  attackCooldownRemaining: a.attackCooldownRemaining,
  defeatKind: a.defeatKind,
  isBoss: a.isBoss,
  autoUltimate: a.autoUltimate,
  bossPhases: a.bossPhases,
  bossPhaseIndex: a.bossPhaseIndex,
  unlockedEnemySkillIds: a.unlockedEnemySkillIds,
  enemySkillCooldowns: a.enemySkillCooldowns,
  chargeCast: a.chargeCast,
  phaseChargeCasts: a.phaseChargeCasts,
  staggerTicksTotal: a.staggerTicksTotal,
  guardianDefIds: _guardianIds(a.guardianDefIds, session),
  guardianWardMult: a.guardianWardMult,
  guardInterceptsInterrupt: a.guardInterceptsInterrupt,
  guardianCoopUsedInCharge: a.guardianCoopUsedInCharge,
  vulnerabilityMult: a.vulnerabilityMult,
  chargingCast: a.chargingCast,
  chargingDefenseFlags: a.chargingDefenseFlags,
  chargeTicksRemaining: a.chargeTicksRemaining,
  staggerTicksRemaining: a.staggerTicksRemaining,
  gatherControlTicksRemaining: a.gatherControlTicksRemaining,
  posture: a.posture,
  shieldRemaining: a.shieldRemaining,
  shieldTicksRemaining: a.shieldTicksRemaining,
  parryTicksRemaining: a.parryTicksRemaining,
  dodgeTicksRemaining: a.dodgeTicksRemaining,
  defenseCooldownRemaining: a.defenseCooldownRemaining,
  parryCounterDamage: a.parryCounterDamage,
  parryCounterBudgetRemaining: a.parryCounterBudgetRemaining,
  statusLedger: a.statusLedger,
  basicAttackSegmentIndex: a.basicAttackSegmentIndex,
  basicAction: a.basicAction,
  qiLedger: a.qiLedger,
  killQiGain: a.killQiGain,
  killQiWindowCap: a.killQiWindowCap,
  qiWindowSerial: a.qiWindowSerial,
);
