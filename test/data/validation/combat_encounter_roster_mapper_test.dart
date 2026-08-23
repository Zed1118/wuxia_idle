import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/validation/combat_encounter_roster_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';

void main() {
  CombatEncounterSpawnEntry contentEntry(String entryId) =>
      CombatEncounterSpawnEntry(
        entryId: entryId,
        archetypeId: 'archetype_$entryId',
        roleId: 'role_$entryId',
        entranceId: 'entrance_$entryId',
        positionId: 'position_$entryId',
        behaviorId: 'behavior_$entryId',
      );

  CombatEncounterDef definition({
    List<String> entryIds = const ['entry_b', 'entry_a'],
  }) => CombatEncounterDef(
    id: 'encounter_roster',
    spawnConfig: CombatEncounterSpawnConfig(
      activeLimit: 2,
      reinforcementThreshold: 0,
      entryWarningTicks: 1,
      attackGraceTicks: 1,
    ),
    tokenBudgets: CombatEncounterTokenBudgets(
      melee: 1,
      ranged: 1,
      charge: 1,
      support: 1,
    ),
    spawnEntries: entryIds.map(contentEntry),
    objectives: CombatObjectiveCompositionRef(
      completionRule: CombatObjectiveCompletionRule.all,
      clauses: [
        CombatObjectiveClauseRef(
          id: 'clear',
          primitive: CombatDefeatTargetsRef(const ['target']),
        ),
      ],
    ),
  );

  SpawnDirector director({
    Map<String, String> entries = const {
      'entry_a': 'runtime_enemy_a',
      'entry_b': 'runtime_enemy_b',
    },
  }) => SpawnDirector(
    config: SpawnDirectorConfig(
      activeLimit: entries.isEmpty ? 1 : entries.length,
      reinforcementThreshold: 0,
      entryWarningTicks: 1,
      attackGraceTicks: 1,
    ),
    entries: [
      for (final entry in entries.entries)
        SpawnEntry(entryId: entry.key, enemyId: entry.value),
    ],
  );

  Phase0aActor actor(
    String id, {
    Phase0aSide side = Phase0aSide.enemy,
    int currentHealth = 100,
  }) => Phase0aActor(
    id: id,
    side: side,
    position: const ArenaVector(3, 4),
    facing: const ArenaVector(-1, 0),
    maxHealth: 100,
    currentHealth: currentHealth,
    moveSpeed: 1,
    qiCurrent: 0,
    qiMax: 100,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  );

  test('maps exact director ids once per entry in stable content order', () {
    final sourceDefinition = definition();
    final sourceDirector = director();
    final calls = <String>[];

    final roster = mapCombatEncounterRoster(
      sourceDefinition,
      sourceDirector,
      playerId: 'player',
      createActor: (entry, enemyId) {
        calls.add('${entry.entryId}:$enemyId');
        return actor(enemyId);
      },
    );

    expect(calls, ['entry_b:runtime_enemy_b', 'entry_a:runtime_enemy_a']);
    expect(roster.director, same(sourceDirector));
    expect(roster.size, 2);
    expect(roster.bindingByEntryId('entry_a')?.actorId, 'runtime_enemy_a');
    expect(roster.bindingByEntryId('entry_b')?.actorId, 'runtime_enemy_b');
    expect(
      roster.bindings.map((binding) => binding.entryId),
      ['entry_a', 'entry_b'],
      reason: 'The roster owns its documented entry-id ordering',
    );
  });

  test('definition/director entry drift fails before any factory call', () {
    final cases = <Map<String, String>>[
      const {'entry_a': 'runtime_enemy_a'},
      const {
        'entry_a': 'runtime_enemy_a',
        'entry_b': 'runtime_enemy_b',
        'entry_c': 'runtime_enemy_c',
      },
      const {'entry_a': 'runtime_enemy_a', 'entry_c': 'runtime_enemy_c'},
    ];

    for (final directorEntries in cases) {
      var factoryCalls = 0;
      expect(
        () => mapCombatEncounterRoster(
          definition(),
          director(entries: directorEntries),
          playerId: 'player',
          createActor: (entry, enemyId) {
            factoryCalls++;
            return actor(enemyId);
          },
        ),
        throwsArgumentError,
      );
      expect(factoryCalls, 0);
    }
  });

  test('factory failures propagate unchanged in stable content order', () {
    final failure = StateError('actor construction failed');
    var calls = 0;

    expect(
      () => mapCombatEncounterRoster(
        definition(),
        director(),
        playerId: 'player',
        createActor: (entry, enemyId) {
          calls++;
          if (entry.entryId == 'entry_a') throw failure;
          return actor(enemyId);
        },
      ),
      throwsA(same(failure)),
    );
    expect(calls, 2, reason: 'Factory order remains the content order');
  });

  test('roster rejects actor id, side and liveness violations', () {
    final invalidFactories = <CombatEncounterActorFactory>[
      (entry, enemyId) => actor('${enemyId}_wrong'),
      (entry, enemyId) => actor(enemyId, side: Phase0aSide.player),
      (entry, enemyId) => actor(enemyId, currentHealth: 0),
    ];

    for (final createActor in invalidFactories) {
      expect(
        () => mapCombatEncounterRoster(
          definition(),
          director(),
          playerId: 'player',
          createActor: createActor,
        ),
        throwsArgumentError,
      );
    }
  });

  test('roster rejects an actor id that matches the player id', () {
    expect(
      () => mapCombatEncounterRoster(
        definition(entryIds: const ['entry_a']),
        director(entries: const {'entry_a': 'player'}),
        playerId: 'player',
        createActor: (entry, enemyId) => actor(enemyId),
      ),
      throwsArgumentError,
    );
  });

  test('each mapping returns a fresh immutable roster owner', () {
    final sourceDefinition = definition();
    final sourceDirector = director();
    var calls = 0;
    Phase0aActor create(CombatEncounterSpawnEntry entry, String enemyId) {
      calls++;
      return actor(enemyId);
    }

    final first = mapCombatEncounterRoster(
      sourceDefinition,
      sourceDirector,
      playerId: 'player',
      createActor: create,
    );
    final second = mapCombatEncounterRoster(
      sourceDefinition,
      sourceDirector,
      playerId: 'player',
      createActor: create,
    );

    expect(first, isNot(same(second)));
    expect(first.bindings, isNot(same(second.bindings)));
    expect(() => first.bindings.clear(), throwsUnsupportedError);
    expect(calls, 4);
  });

  test('mapping does not advance or replace definition/director inputs', () {
    final sourceDefinition = definition();
    final sourceDirector = director();
    final beforeState = sourceDirector.state;
    final beforeEntries = List<CombatEncounterSpawnEntry>.of(
      sourceDefinition.spawnEntries,
    );

    mapCombatEncounterRoster(
      sourceDefinition,
      sourceDirector,
      playerId: 'player',
      createActor: (entry, enemyId) => actor(enemyId),
    );

    final afterState = sourceDirector.state;
    expect(afterState.tick, beforeState.tick);
    expect(afterState.activeCount, beforeState.activeCount);
    expect(afterState.warningCount, beforeState.warningCount);
    expect(afterState.pendingCount, beforeState.pendingCount);
    expect(afterState.removedCount, beforeState.removedCount);
    expect(afterState.units, beforeState.units);
    expect(sourceDefinition.spawnEntries, orderedEquals(beforeEntries));
  });

  test('mapper stays thin, explicit and isolated from production hosts', () {
    final source = File(
      'lib/data/validation/combat_encounter_roster_mapper.dart',
    ).readAsStringSync();
    final imports = RegExp(
      r"^import '([^']+)';$",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();

    expect(
      source,
      contains('required CombatEncounterActorFactory createActor'),
    );
    expect(source, isNot(contains('entry.enemyId')));
    expect(source, isNot(contains('GameRepository')));
    expect(source, isNot(contains('Phase0aEncounterMapping')));
    expect(imports, [
      '../../features/battle/domain/phase0a/encounter_enemy_roster.dart',
      '../../features/battle/domain/phase0a/phase0a_combat_model.dart',
      '../../features/battle/domain/phase0a/spawn_director.dart',
      '../defs/combat_encounter_def.dart',
    ]);
  });
}
