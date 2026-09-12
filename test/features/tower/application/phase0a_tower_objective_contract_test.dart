import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repo;
  setUpAll(() async => repo = await loadTestGameRepository());

  for (final kind in [
    'survive',
    'commander',
    'anchors',
    'defend',
    'checkpoint',
    'markers',
    'pursue',
    'subset',
    'foreign',
    'source_ids',
    'any',
    'mixed',
  ]) {
    test('tower rejects $kind objectives before runtime binding', () async {
      var runtimeLoaded = false;
      await expectLater(
        _session(
          repo,
          _Objectives(kind),
          runtime: _RuntimeSpy(() => runtimeLoaded = true),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('tower objective'),
          ),
        ),
      );
      expect(runtimeLoaded, isFalse);
    });
  }

  for (final split in [false, true]) {
    test(
      'complete ${split ? 'split' : 'single'} defeat targets require every live enemy',
      () async {
        final session = await _session(
          repo,
          _Objectives(split ? 'split' : 'valid'),
        );
        final events = <Phase0aEvent>[];
        // Waiting cannot satisfy an authored defeat-all tower objective.
        for (var i = 0; i < 3; i++) {
          events.addAll(
            session.flow.advance(
              deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
              command: const Phase0aPlayerCommand(),
            ),
          );
        }
        expect(session.flow.outcome, Phase0aBattleOutcome.ongoing);
        expect(
          session.flow.state.enemies.where((e) => e.isAlive),
          hasLength(3),
        );
        final bot = Phase0aPlayerBotAdapter(
          playerAdapter: session.playerAdapter,
        );
        var sawPartialDefeat = false;
        while (session.flow.outcome == Phase0aBattleOutcome.ongoing &&
            session.flow.state.tick <
                repo.numbers.phase0aArena.maxSimulationTicks) {
          final alive = session.flow.state.enemies
              .where((e) => e.isAlive)
              .length;
          if (alive > 0 && alive < 3) sawPartialDefeat = true;
          events.addAll(
            session.flow.advance(
              deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
              command: bot.commandFor(session.flow.state),
            ),
          );
          if (session.flow.state.enemies.any((e) => e.isAlive)) {
            expect(session.flow.outcome, isNot(Phase0aBattleOutcome.victory));
          }
        }
        expect(sawPartialDefeat, isTrue);
        expect(session.flow.outcome, Phase0aBattleOutcome.victory);
        expect(session.flow.state.enemies.where((e) => e.isAlive), isEmpty);
        final settlement = session.settle(
          outcome: session.flow.outcome,
          finalState: session.flow.state,
          events: events,
        );
        expect(settlement.result, BattleResult.leftWin);
        expect(settlement.playerCharacterId, 1);
        expect(settlement.totalDamage, greaterThan(0));
      },
    );
  }
}

Future<Phase0aTowerCombatSession> _session(
  GameRepository repo,
  Phase0aTowerEncounterDefinitionSource source, {
  Phase0aTowerEncounterRuntimeBindingSource runtime =
      const Phase0aDerivedTowerEncounterRuntimeBindingSource(),
}) => createFreshPhase0aTowerCombatSession(
  Phase0aTowerCombatSessionBuildRequest(
    contentRef: const CombatContentRef.tower('tower_42'),
    floor: repo.getTowerFloor(42),
    playerSnapshot: testCombatantSnapshot(
      maxHp: 20000,
      realmTier: RealmTier.wuSheng,
      internalForce: 15000,
      mainCultivationLayer: CultivationLayer.yuanMan,
      defenseRate: 0.5,
      totalEquipmentAttack: 2000,
      includeProductionBasicAttack: true,
    ),
    numbers: repo.numbers,
    cycleIndex: 1,
    rng: Random(20260911),
    routeAuthority: Phase0aTowerEncounterRouteAuthority.migratedFloors({42}),
    definitionSource: source,
    runtimeBindingSource: runtime,
  ),
);

final class _Objectives implements Phase0aTowerEncounterDefinitionSource {
  const _Objectives(this.kind);
  final String kind;
  @override
  CombatEncounterDef load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
  }) {
    final original = const Phase0aDerivedTowerEncounterDefinitionSource().load(
      contentRef: contentRef,
      floor: floor,
    );
    final ids = original.spawnEntries.map((e) => e.entryId).toList();
    final CombatObjectivePrimitiveRef primitive = switch (kind) {
      'survive' || 'mixed' => CombatSurviveDurationRef(requiredTicks: 1),
      'commander' => CombatDefeatCommanderRef(commanderId: ids.first),
      'anchors' => CombatDestroyAnchorsRef(ids),
      'defend' => CombatDefendEntityRef(
        entityId: 'cargo',
        positionId: 'position',
        durability: 10,
        damagePerHit: 1,
        requiredTicks: 1,
        attackerIds: ids,
      ),
      'checkpoint' => CombatReachCheckpointRef(['checkpoint']),
      'markers' => CombatTouchMarkersRef(['marker']),
      'pursue' => CombatPursueTargetRef(targetId: ids.first),
      'subset' => CombatDefeatTargetsRef(ids.take(1)),
      'foreign' => CombatDefeatTargetsRef([...ids, 'foreign_entry']),
      'source_ids' => CombatDefeatTargetsRef(floor.enemyTeam.map((e) => e.id)),
      _ => CombatDefeatTargetsRef(ids),
    };
    return CombatEncounterDef(
      id: original.id,
      spawnConfig: original.spawnConfig,
      tokenBudgets: original.tokenBudgets,
      spawnEntries: original.spawnEntries,
      objectives: CombatObjectiveCompositionRef(
        completionRule: kind == 'any' || kind == 'mixed'
            ? CombatObjectiveCompletionRule.any
            : CombatObjectiveCompletionRule.all,
        clauses: kind == 'split'
            ? [
                for (final id in ids.reversed)
                  CombatObjectiveClauseRef(
                    id: 'defeat_$id',
                    primitive: CombatDefeatTargetsRef([id]),
                  ),
              ]
            : [
                CombatObjectiveClauseRef(id: 'objective', primitive: primitive),
                if (kind == 'mixed')
                  CombatObjectiveClauseRef(
                    id: 'defeat_all',
                    primitive: CombatDefeatTargetsRef(ids),
                  ),
              ],
      ),
    );
  }
}

final class _RuntimeSpy implements Phase0aTowerEncounterRuntimeBindingSource {
  const _RuntimeSpy(this.onLoad);
  final void Function() onLoad;
  @override
  Phase0aTowerRuntimeBindingBundle load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
    required CombatEncounterDef encounter,
    required int cycleIndex,
  }) {
    onLoad();
    return const Phase0aDerivedTowerEncounterRuntimeBindingSource().load(
      contentRef: contentRef,
      floor: floor,
      encounter: encounter,
      cycleIndex: cycleIndex,
    );
  }
}
