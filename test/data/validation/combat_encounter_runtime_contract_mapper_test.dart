import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/validation/combat_encounter_runtime_contract_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';

void main() {
  const tickDuration = Duration(milliseconds: 25);

  CombatEncounterDef encounter({
    CombatObjectiveCompletionRule completionRule =
        CombatObjectiveCompletionRule.all,
    CombatObjectiveCompositionRef? objectives,
  }) => CombatEncounterDef(
    id: 'encounter_contract',
    spawnConfig: CombatEncounterSpawnConfig(
      activeLimit: 7,
      reinforcementThreshold: 3,
      entryWarningTicks: 5,
      attackGraceTicks: 11,
    ),
    tokenBudgets: CombatEncounterTokenBudgets(
      melee: 13,
      ranged: 17,
      charge: 19,
      support: 23,
    ),
    spawnEntries: [
      CombatEncounterSpawnEntry(
        entryId: 'entry_b',
        archetypeId: 'archetype_b',
        roleId: 'role_b',
        entranceId: 'entrance_b',
        positionId: 'position_b',
        behaviorId: 'behavior_b',
      ),
      CombatEncounterSpawnEntry(
        entryId: 'entry_a',
        archetypeId: 'archetype_a',
        roleId: 'role_a',
        entranceId: 'entrance_a',
        positionId: 'position_a',
        behaviorId: 'behavior_a',
      ),
    ],
    objectives:
        objectives ??
        CombatObjectiveCompositionRef(
          completionRule: completionRule,
          clauses: [
            CombatObjectiveClauseRef(
              id: 'clear',
              primitive: CombatDefeatTargetsRef(const ['target']),
            ),
            CombatObjectiveClauseRef(
              id: 'exit',
              primitive: CombatReachCheckpointRef(const ['exit']),
            ),
          ],
        ),
  );

  CombatEncounterRuntimeContractBundle map(
    CombatEncounterDef definition, {
    Map<String, String>? ids,
  }) => mapCombatEncounterRuntimeContract(
    definition,
    tickDuration: tickDuration,
    resolveEnemyId: (entry) =>
        (ids ?? const {'entry_a': 'enemy_a', 'entry_b': 'enemy_b'})[entry
            .entryId] ??
        (throw StateError('unknown enemy instance for ${entry.entryId}')),
  );

  test('maps all spawn config and attack-token budget fields one-to-one', () {
    final bundle = map(encounter());

    expect(bundle.spawnDirector.config.activeLimit, 7);
    expect(bundle.spawnDirector.config.reinforcementThreshold, 3);
    expect(bundle.spawnDirector.config.entryWarningTicks, 5);
    expect(bundle.spawnDirector.config.attackGraceTicks, 11);
    expect(bundle.attackTokenBudgets.melee, 13);
    expect(bundle.attackTokenBudgets.ranged, 17);
    expect(bundle.attackTokenBudgets.charge, 19);
    expect(bundle.attackTokenBudgets.support, 23);
  });

  test('resolves every runtime enemy id in content entry order', () {
    final visited = <String>[];

    final bundle = mapCombatEncounterRuntimeContract(
      encounter(),
      tickDuration: tickDuration,
      resolveEnemyId: (entry) {
        visited.add(entry.entryId);
        return 'enemy_${entry.entryId}';
      },
    );

    expect(visited, ['entry_b', 'entry_a']);
    expect(
      bundle.spawnDirector.state.unitById('entry_b')?.enemyId,
      'enemy_entry_b',
    );
    expect(
      bundle.spawnDirector.state.unitById('entry_a')?.enemyId,
      'enemy_entry_a',
    );
    expect(
      bundle.spawnDirector.state.units.map((unit) => unit.entryId),
      ['entry_a', 'entry_b'],
      reason: 'SpawnDirector keeps its own documented stable ordering',
    );
  });

  test('preserves all and any completion semantics', () {
    for (final rule in CombatObjectiveCompletionRule.values) {
      final bundle = map(encounter(completionRule: rule));
      var progress = bundle.objectiveController.initialProgress;

      progress = bundle.objectiveController.advance(
        progress,
        TargetDefeated('target'),
      );
      expect(progress.completed, rule == CombatObjectiveCompletionRule.any);

      if (rule == CombatObjectiveCompletionRule.all) {
        progress = bundle.objectiveController.advance(
          progress,
          CheckpointReached('exit'),
        );
        expect(progress.completed, isTrue);
      }
    }
  });

  test(
    'reuses the explicit tick duration through the R03 objective mapper',
    () {
      final definition = encounter(
        objectives: CombatObjectiveCompositionRef(
          completionRule: CombatObjectiveCompletionRule.all,
          clauses: [
            CombatObjectiveClauseRef(
              id: 'survive',
              primitive: CombatSurviveDurationRef(requiredTicks: 3),
            ),
          ],
        ),
      );

      final objective =
          map(definition).objectiveController.clauses.single.objective
              as SurviveDurationObjective;
      expect(objective.requiredDuration, const Duration(milliseconds: 75));

      expect(
        () => mapCombatEncounterRuntimeContract(
          definition,
          tickDuration: Duration.zero,
          resolveEnemyId: (entry) => 'enemy_${entry.entryId}',
        ),
        throwsArgumentError,
      );
    },
  );

  test('every mapping creates fresh runtime owners', () {
    final definition = encounter();
    final first = map(definition);
    final second = map(definition);

    expect(first, isNot(same(second)));
    expect(first.spawnDirector, isNot(same(second.spawnDirector)));
    expect(first.attackTokenBudgets, isNot(same(second.attackTokenBudgets)));
    expect(first.objectiveController, isNot(same(second.objectiveController)));
    expect(
      () => second.objectiveController.advance(
        first.objectiveController.initialProgress,
        TargetDefeated('target'),
      ),
      throwsStateError,
    );
  });

  test('snapshots resolved ids and ignores later caller-map mutation', () {
    final ids = <String, String>{'entry_a': 'enemy_a', 'entry_b': 'enemy_b'};
    final bundle = map(encounter(), ids: ids);

    ids
      ..clear()
      ..addAll({'entry_a': 'replacement_a', 'entry_b': 'replacement_b'});

    expect(bundle.spawnDirector.state.unitById('entry_a')?.enemyId, 'enemy_a');
    expect(bundle.spawnDirector.state.unitById('entry_b')?.enemyId, 'enemy_b');
  });

  test('unknown, blank, whitespace and duplicate enemy ids fail closed', () {
    final definition = encounter();

    expect(
      () => map(definition, ids: const {'entry_a': 'enemy_a'}),
      throwsStateError,
    );
    for (final invalid in ['', 'enemy id']) {
      expect(
        () => map(definition, ids: {'entry_a': invalid, 'entry_b': 'enemy_b'}),
        throwsArgumentError,
      );
    }
    expect(
      () => map(
        definition,
        ids: const {'entry_a': 'same_enemy', 'entry_b': 'same_enemy'},
      ),
      throwsArgumentError,
    );
  });

  test('mapper API declares no defaults and imports no production layer', () {
    final source = File(
      'lib/data/validation/combat_encounter_runtime_contract_mapper.dart',
    ).readAsStringSync();
    final imports = RegExp(
      r"^import '([^']+)';$",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)).toList();

    expect(source, contains('required Duration tickDuration'));
    expect(
      source,
      contains('required CombatEnemyInstanceIdResolver resolveEnemyId'),
    );
    expect(source, isNot(contains('Phase0aEncounterMapping')));
    expect(source, isNot(contains('GameRepository')));
    expect(imports, [
      '../../features/battle/domain/phase0a/attack_token_director.dart',
      '../../features/battle/domain/phase0a/objective_controller.dart',
      '../../features/battle/domain/phase0a/spawn_director.dart',
      '../defs/combat_encounter_def.dart',
      'combat_objective_primitive_mapper.dart',
    ]);
  });
}
