import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/tower_floor_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/enemy_combatant_snapshot_assembler.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  test('production route authority keeps tower numerator at zero', () {
    const authority = Phase0aTowerEncounterRouteAuthority.production();
    for (var floorIndex = 1; floorIndex <= 49; floorIndex += 1) {
      expect(
        authority.modeForFloor(floorIndex),
        Phase0aTowerEncounterRouteMode.legacy,
      );
    }
    expect(authority.migratedFloorIndices, isEmpty);

    final candidateFloors = <int>{1};
    final candidate = Phase0aTowerEncounterRouteAuthority.migratedFloors(
      candidateFloors,
    );
    candidateFloors.add(2);
    expect(candidate.migratedFloorIndices, {1});
    expect(
      () => Phase0aTowerEncounterRouteAuthority.migratedFloors({0}),
      throwsArgumentError,
    );
  });

  test('typed foundation binds every source enemy exactly once', () async {
    final repo = await loadTestGameRepository();
    final floor = repo.getTowerFloor(42);
    final session = await _typedSession(
      repo: repo,
      floor: floor,
      cycleIndex: 2,
      seed: 20260905,
    );

    expect(session.routeMode, Phase0aTowerEncounterRouteMode.migrated);
    expect(session.encounterCount, 1);
    expect(session.activeLimit, floor.enemyTeam.length);
    expect(
      session.sourceEnemyDefIdsInEntryOrder,
      floor.enemyTeam.map((enemy) => enemy.id).toList(),
    );
    expect(session.sourceEnemyDefIdByActorId.values.toSet().length, 3);
    expect(
      session.combatants.skip(1).map((binding) => binding.actorId),
      session.sourceEnemyDefIdByActorId.keys,
    );

    session.flow.advance(
      deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
      command: const Phase0aPlayerCommand(),
    );
    final boss = session.flow.state.enemies.singleWhere(
      (enemy) => enemy.isBoss,
    );
    final guardianRuntimeIds = session.sourceEnemyDefIdByActorId.entries
        .where((entry) => entry.value.contains('guard_'))
        .map((entry) => entry.key)
        .toSet();
    expect(boss.guardianDefIds.toSet(), guardianRuntimeIds);
    expect(
      boss.guardianDefIds.any(
        floor.enemyTeam.map((enemy) => enemy.id).toSet().contains,
      ),
      isFalse,
    );
  });

  test('representative floors preserve typed mechanic facts', () async {
    final repo = await loadTestGameRepository();
    for (final floorIndex in const [1, 7, 14, 32, 42, 49]) {
      for (final cycleIndex in const [1, 2]) {
        final floor = repo.getTowerFloor(floorIndex);
        final session = await _typedSession(
          repo: repo,
          floor: floor,
          cycleIndex: cycleIndex,
          seed: 20260905 + floorIndex + cycleIndex,
        );
        final expected = [
          for (var i = 0; i < floor.enemyTeam.length; i += 1)
            EnemyCombatantSnapshotAssembler.assembleOne(
              enemy: floor.enemyTeam[i],
              slotIndex: i,
              cycleIndex: cycleIndex,
              isTower: true,
            ),
        ];
        final actual = session.combatants.skip(1).toList();
        expect(
          actual,
          hasLength(expected.length),
          reason: '$floorIndex/$cycleIndex',
        );
        for (var i = 0; i < expected.length; i += 1) {
          final want = expected[i];
          final got = actual[i].snapshot;
          expect(got.enemyDefId, want.enemyDefId);
          expect(
            got.availableSkills.map((skill) => skill.id),
            want.availableSkills.map((skill) => skill.id),
          );
          expect(_phaseFacts(got.bossPhases), _phaseFacts(want.bossPhases));
          expect(got.chargeSkillId, want.chargeSkillId);
          expect(got.vulnerabilityMult, want.vulnerabilityMult);
          expect(got.guardianWardMult, want.guardianWardMult);
          expect(got.guardInterceptsInterrupt, want.guardInterceptsInterrupt);
          expect(
            got.guardianDefIds.map(
              (runtimeId) => session.sourceEnemyDefIdByActorId[runtimeId],
            ),
            want.guardianDefIds,
          );
        }
      }
    }
  });

  test('representative typed settlements match the legacy mapper', () async {
    final repo = await loadTestGameRepository();
    for (final floorIndex in const [1, 7, 14, 32, 42, 49]) {
      for (final cycleIndex in const [1, 2]) {
        final floor = repo.getTowerFloor(floorIndex);
        final seed = 20260905 + floorIndex * 100 + cycleIndex;
        final legacy = await createFreshPhase0aTowerCombatSession(
          Phase0aTowerCombatSessionBuildRequest(
            contentRef: CombatContentRef.tower('tower_$floorIndex'),
            floor: floor,
            playerSnapshot: _player(),
            numbers: repo.numbers,
            cycleIndex: cycleIndex,
            rng: Random(seed),
          ),
        );
        final typed = await _typedSession(
          repo: repo,
          floor: floor,
          cycleIndex: cycleIndex,
          seed: seed,
        );
        final legacyResult = Phase0aHeadlessRunner.runToEnd(
          flow: legacy.flow,
          bot: Phase0aPlayerBotAdapter(playerAdapter: legacy.playerAdapter),
          deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
          maxTicks: repo.numbers.phase0aArena.maxSimulationTicks,
        );
        final typedResult = Phase0aHeadlessRunner.runToEnd(
          flow: typed.flow,
          bot: Phase0aPlayerBotAdapter(playerAdapter: typed.playerAdapter),
          deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
          maxTicks: repo.numbers.phase0aArena.maxSimulationTicks,
        );
        final legacySettlement = legacy.settle(
          outcome: legacyResult.outcome,
          finalState: legacyResult.finalState,
          events: legacyResult.events,
        );
        final typedSettlement = typed.settle(
          outcome: typedResult.outcome,
          finalState: typedResult.finalState,
          events: typedResult.events,
        );
        _expectSettlementEqual(
          typedSettlement,
          legacySettlement,
          '$floorIndex/$cycleIndex',
        );
      }
    }
  });

  test(
    'typed live and headless consumers stay identical under one seed',
    () async {
      final repo = await loadTestGameRepository();
      for (final floorIndex in const [1, 7, 14, 32, 42, 49]) {
        for (final cycleIndex in const [1, 2]) {
          final floor = repo.getTowerFloor(floorIndex);
          final seed = 20260905 + floorIndex * 10 + cycleIndex;
          final headlessSession = await _typedSession(
            repo: repo,
            floor: floor,
            cycleIndex: cycleIndex,
            seed: seed,
          );
          final headless = Phase0aHeadlessRunner.runToEnd(
            flow: headlessSession.flow,
            bot: Phase0aPlayerBotAdapter(
              playerAdapter: headlessSession.playerAdapter,
            ),
            deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
            maxTicks: repo.numbers.phase0aArena.maxSimulationTicks,
          );

          final liveSession = await _typedSession(
            repo: repo,
            floor: floor,
            cycleIndex: cycleIndex,
            seed: seed,
          );
          final controller = Phase0aBattleController(
            flow: liveSession.flow,
            roster: Phase0aVisualRoster.fromCombatants(
              playerId: liveSession.flow.state.player.id,
              combatants: liveSession.combatants,
            ),
            fixedDeltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
          );
          final bot = Phase0aPlayerBotAdapter(
            playerAdapter: liveSession.playerAdapter,
          );
          var ticks = 0;
          while (controller.outcome == Phase0aBattleOutcome.ongoing &&
              ticks < repo.numbers.phase0aArena.maxSimulationTicks) {
            controller.step(bot.commandFor(controller.state));
            ticks += 1;
          }
          expect(
            controller.outcome,
            headless.outcome,
            reason: '$floorIndex/$cycleIndex',
          );
          expect(
            controller.state,
            headless.finalState,
            reason: '$floorIndex/$cycleIndex',
          );
          expect(
            controller.events,
            headless.events,
            reason: '$floorIndex/$cycleIndex',
          );
          controller.dispose();
        }
      }
    },
  );

  test(
    'migrated route rejects missing definition and runtime sources',
    () async {
      final repo = await loadTestGameRepository();
      final floor = repo.getTowerFloor(1);
      await expectLater(
        createFreshPhase0aTowerCombatSession(
          _request(
            repo: repo,
            floor: floor,
            definitionSource: const _MissingDefinitionSource(),
          ),
        ),
        throwsStateError,
      );
      await expectLater(
        createFreshPhase0aTowerCombatSession(
          _request(
            repo: repo,
            floor: floor,
            runtimeBindingSource: const _MissingRuntimeSource(),
          ),
        ),
        throwsStateError,
      );
    },
  );

  test('source binding rejects wrong order and duplicate ownership', () async {
    final repo = await loadTestGameRepository();
    final floor = repo.getTowerFloor(42);
    await expectLater(
      createFreshPhase0aTowerCombatSession(
        _request(
          repo: repo,
          floor: floor,
          definitionSource: const _ReorderedDefinitionSource(),
        ),
      ),
      throwsStateError,
    );
    await expectLater(
      createFreshPhase0aTowerCombatSession(
        _request(
          repo: repo,
          floor: floor,
          runtimeBindingSource: const _DuplicateRuntimeSource(),
        ),
      ),
      throwsStateError,
    );
  });

  test(
    'guardian translation rejects dangling duplicate and self refs',
    () async {
      final repo = await loadTestGameRepository();
      final floor = repo.getTowerFloor(42);
      for (final mutation in _GuardianMutation.values) {
        await expectLater(
          createFreshPhase0aTowerCombatSession(
            _request(
              repo: repo,
              floor: floor,
              runtimeBindingSource: _GuardianMutationRuntimeSource(mutation),
            ),
          ),
          throwsStateError,
          reason: mutation.name,
        );
      }
    },
  );

  test('three production surfaces forbid direct mapTower bypass', () {
    final visible = File(
      'lib/features/tower/presentation/phase0a_tower_battle_host.dart',
    ).readAsStringSync();
    final headless = File(
      'lib/features/sweep/application/phase0a_sweep_headless_runner.dart',
    ).readAsStringSync();
    final factory = File(
      'lib/features/tower/application/phase0a_tower_encounter_host.dart',
    ).readAsStringSync();

    expect(visible, isNot(contains('Phase0aStageContentMapper.mapTower(')));
    expect(headless, isNot(contains('Phase0aStageContentMapper.mapTower(')));
    expect(
      'Phase0aStageContentMapper.mapTower('.allMatches(factory),
      hasLength(1),
    );
    expect(visible, contains('phase0aTowerCombatSessionFactoryProvider'));
    expect(
      'towerSessionFactory('.allMatches(headless),
      hasLength(2),
      reason: 'instant and durable routes must share one factory',
    );
  });
}

List<Object?>? _phaseFacts(List<BossPhaseDef>? phases) => phases == null
    ? null
    : [
        for (final phase in phases)
          (
            phase.hpThresholdPct,
            phase.unlockSkillIds.join(','),
            phase.aiMode.name,
            phase.onEnterMechanic?.name,
            phase.titleKey,
          ),
      ];

void _expectSettlementEqual(
  CombatSettlementSnapshot actual,
  CombatSettlementSnapshot expected,
  String reason,
) {
  Map<String, Object?> facts(CombatSettlementSnapshot value) => {
    'result': value.result,
    'totalTicks': value.totalTicks,
    'hadActions': value.hadActions,
    'playerCharacterId': value.playerCharacterId,
    'totalDamage': value.totalDamage,
    'criticalCount': value.criticalCount,
    'participants': [
      for (final participant in value.participants)
        (participant.characterId, participant.currentHp, participant.maxHp),
    ],
    'skillCasts': [
      for (final cast in value.skillCasts)
        (cast.tick, cast.characterId, cast.skillId),
    ],
    'damageByCharacterId': value.damageByCharacterId,
  };
  expect(facts(actual), facts(expected), reason: reason);
}

CombatantSnapshot _player() => testCombatantSnapshot(
  maxHp: 20000,
  totalEquipmentAttack: 2000,
  includeProductionBasicAttack: true,
);

Future<Phase0aTowerCombatSession> _typedSession({
  required GameRepository repo,
  required TowerFloorDef floor,
  required int cycleIndex,
  required int seed,
}) => createFreshPhase0aTowerCombatSession(
  _request(repo: repo, floor: floor, cycleIndex: cycleIndex, seed: seed),
);

Phase0aTowerCombatSessionBuildRequest _request({
  required GameRepository repo,
  required TowerFloorDef floor,
  int cycleIndex = 1,
  int seed = 20260905,
  Phase0aTowerEncounterDefinitionSource definitionSource =
      const Phase0aDerivedTowerEncounterDefinitionSource(),
  Phase0aTowerEncounterRuntimeBindingSource runtimeBindingSource =
      const Phase0aDerivedTowerEncounterRuntimeBindingSource(),
}) => Phase0aTowerCombatSessionBuildRequest(
  contentRef: CombatContentRef.tower('tower_${floor.floorIndex}'),
  floor: floor,
  playerSnapshot: _player(),
  numbers: repo.numbers,
  cycleIndex: cycleIndex,
  rng: Random(seed),
  routeAuthority: Phase0aTowerEncounterRouteAuthority.migratedFloors({
    floor.floorIndex,
  }),
  definitionSource: definitionSource,
  runtimeBindingSource: runtimeBindingSource,
);

final class _MissingDefinitionSource
    implements Phase0aTowerEncounterDefinitionSource {
  const _MissingDefinitionSource();

  @override
  CombatEncounterDef? load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
  }) => null;
}

final class _MissingRuntimeSource
    implements Phase0aTowerEncounterRuntimeBindingSource {
  const _MissingRuntimeSource();

  @override
  Phase0aTowerRuntimeBindingBundle? load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
    required CombatEncounterDef encounter,
    required int cycleIndex,
  }) => null;
}

final class _ReorderedDefinitionSource
    implements Phase0aTowerEncounterDefinitionSource {
  const _ReorderedDefinitionSource();

  @override
  CombatEncounterDef load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
  }) {
    final original = const Phase0aDerivedTowerEncounterDefinitionSource().load(
      contentRef: contentRef,
      floor: floor,
    );
    return CombatEncounterDef(
      id: original.id,
      spawnConfig: original.spawnConfig,
      tokenBudgets: original.tokenBudgets,
      spawnEntries: original.spawnEntries.reversed,
      objectives: original.objectives,
    );
  }
}

final class _DuplicateRuntimeSource
    implements Phase0aTowerEncounterRuntimeBindingSource {
  const _DuplicateRuntimeSource();

  @override
  Phase0aTowerRuntimeBindingBundle load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
    required CombatEncounterDef encounter,
    required int cycleIndex,
  }) {
    final original = const Phase0aDerivedTowerEncounterRuntimeBindingSource()
        .load(
          contentRef: contentRef,
          floor: floor,
          encounter: encounter,
          cycleIndex: cycleIndex,
        );
    final bindings = original.actorBindings.toList();
    bindings[1] = Phase0aTowerActorRuntimeBinding(
      entryId: bindings[1].entryId,
      sourceEnemyDefId: bindings.first.sourceEnemyDefId,
      combatant: bindings.first.combatant,
    );
    return Phase0aTowerRuntimeBindingBundle(
      contentId: original.contentId,
      encounterId: original.encounterId,
      actorBindings: bindings,
    );
  }
}

enum _GuardianMutation { dangling, duplicate, selfReference }

final class _GuardianMutationRuntimeSource
    implements Phase0aTowerEncounterRuntimeBindingSource {
  const _GuardianMutationRuntimeSource(this.mutation);

  final _GuardianMutation mutation;

  @override
  Phase0aTowerRuntimeBindingBundle load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
    required CombatEncounterDef encounter,
    required int cycleIndex,
  }) {
    final original = const Phase0aDerivedTowerEncounterRuntimeBindingSource()
        .load(
          contentRef: contentRef,
          floor: floor,
          encounter: encounter,
          cycleIndex: cycleIndex,
        );
    final bindings = original.actorBindings.toList();
    final boss = bindings.first;
    final guardians = switch (mutation) {
      _GuardianMutation.dangling => const ['missing_guardian'],
      _GuardianMutation.duplicate => [
        bindings[1].sourceEnemyDefId,
        bindings[1].sourceEnemyDefId,
      ],
      _GuardianMutation.selfReference => [boss.sourceEnemyDefId],
    };
    bindings[0] = Phase0aTowerActorRuntimeBinding(
      entryId: boss.entryId,
      sourceEnemyDefId: boss.sourceEnemyDefId,
      combatant: boss.combatant.copyWith(guardianDefIds: guardians),
    );
    return Phase0aTowerRuntimeBindingBundle(
      contentId: original.contentId,
      encounterId: original.encounterId,
      actorBindings: bindings,
    );
  }
}
