// Contract tests for P2-G2-S01 CombatEncounterDef.

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';

CombatEncounterSpawnConfig spawnConfig({
  int activeLimit = 8,
  int threshold = 2,
  int warning = 3,
  int grace = 2,
}) => CombatEncounterSpawnConfig(
  activeLimit: activeLimit,
  reinforcementThreshold: threshold,
  entryWarningTicks: warning,
  attackGraceTicks: grace,
);

CombatEncounterTokenBudgets tokenBudgets({
  int melee = 2,
  int ranged = 1,
  int charge = 1,
  int support = 1,
}) => CombatEncounterTokenBudgets(
  melee: melee,
  ranged: ranged,
  charge: charge,
  support: support,
);

CombatEncounterSpawnEntry spawnEntry({
  String entryId = 'entry_01',
  String archetypeId = 'bandit_swordsman',
  String roleId = 'melee_brute',
  String entranceId = 'entrance_left',
  String positionId = 'position_left_low',
  String behaviorId = 'behavior_press',
}) => CombatEncounterSpawnEntry(
  entryId: entryId,
  archetypeId: archetypeId,
  roleId: roleId,
  entranceId: entranceId,
  positionId: positionId,
  behaviorId: behaviorId,
);

CombatEncounterDef encounter({
  String id = 'encounter_blackwind_ambush',
  CombatEncounterSpawnConfig? config,
  CombatEncounterTokenBudgets? budgets,
  List<CombatEncounterSpawnEntry>? entries,
  CombatObjectiveCompositionRef? objectives,
}) => CombatEncounterDef(
  id: id,
  spawnConfig: config ?? spawnConfig(),
  tokenBudgets: budgets ?? tokenBudgets(),
  spawnEntries: entries ?? [spawnEntry()],
  objectives:
      objectives ??
      CombatObjectiveCompositionRef(
        completionRule: CombatObjectiveCompletionRule.all,
        clauses: [
          CombatObjectiveClauseRef(
            id: 'survive',
            primitive: CombatSurviveDurationRef(requiredTicks: 60),
          ),
        ],
      ),
);

void main() {
  group('CombatEncounterSpawnConfig', () {
    test('constructs with explicit caller values', () {
      final config = spawnConfig();
      expect(config.activeLimit, 8);
      expect(config.reinforcementThreshold, 2);
      expect(config.entryWarningTicks, 3);
      expect(config.attackGraceTicks, 2);
    });

    test('activeLimit must be positive', () {
      expect(() => spawnConfig(activeLimit: 0), throwsArgumentError);
      expect(() => spawnConfig(activeLimit: -3), throwsArgumentError);
    });

    test('reinforcementThreshold must be in [0, activeLimit)', () {
      expect(() => spawnConfig(threshold: -1), throwsArgumentError);
      expect(
        () => spawnConfig(threshold: 8, activeLimit: 8),
        throwsArgumentError,
      );
      expect(
        () => spawnConfig(threshold: 9, activeLimit: 8),
        throwsArgumentError,
      );
    });

    test('warning and grace ticks must not be negative', () {
      expect(() => spawnConfig(warning: -1), throwsArgumentError);
      expect(() => spawnConfig(grace: -1), throwsArgumentError);
    });

    test('zero warning and zero grace are allowed', () {
      final config = spawnConfig(warning: 0, grace: 0);
      expect(config.entryWarningTicks, 0);
      expect(config.attackGraceTicks, 0);
    });
  });

  group('CombatEncounterTokenBudgets', () {
    test('constructs with explicit caller values', () {
      final budgets = tokenBudgets(melee: 3, ranged: 2, charge: 0, support: 1);
      expect(budgets.melee, 3);
      expect(budgets.ranged, 2);
      expect(budgets.charge, 0);
      expect(budgets.support, 1);
    });

    test('negative budgets fail closed', () {
      expect(() => tokenBudgets(melee: -1), throwsArgumentError);
      expect(() => tokenBudgets(ranged: -1), throwsArgumentError);
      expect(() => tokenBudgets(charge: -1), throwsArgumentError);
      expect(() => tokenBudgets(support: -1), throwsArgumentError);
    });
  });

  group('CombatEncounterSpawnEntry', () {
    test('constructs with archetype variant role reference', () {
      final entry = spawnEntry();
      expect(entry.entryId, 'entry_01');
      expect(entry.archetypeId, 'bandit_swordsman');
      expect(entry.roleId, 'melee_brute');
      expect(entry.entranceId, 'entrance_left');
      expect(entry.positionId, 'position_left_low');
      expect(entry.behaviorId, 'behavior_press');
    });

    test('blank or whitespace ids fail closed', () {
      expect(() => spawnEntry(entryId: ''), throwsArgumentError);
      expect(() => spawnEntry(entryId: 'entry 01'), throwsArgumentError);
      expect(() => spawnEntry(archetypeId: '  '), throwsArgumentError);
      expect(() => spawnEntry(roleId: ''), throwsArgumentError);
      expect(() => spawnEntry(entranceId: 'bad id'), throwsArgumentError);
      expect(() => spawnEntry(positionId: ''), throwsArgumentError);
      expect(() => spawnEntry(behaviorId: '  '), throwsArgumentError);
    });
  });

  group('CombatObjectivePrimitiveRef kinds', () {
    test('survive-duration reference requires positive ticks', () {
      expect(CombatSurviveDurationRef(requiredTicks: 60).requiredTicks, 60);
      expect(
        () => CombatSurviveDurationRef(requiredTicks: 0),
        throwsArgumentError,
      );
      expect(
        () => CombatSurviveDurationRef(requiredTicks: -1),
        throwsArgumentError,
      );
    });

    test('defend-entity reference validates its complete runtime contract', () {
      expect(
        CombatDefendEntityRef(
          entityId: 'npc_guardsman',
          positionId: 'ward_position',
          durability: 100,
          damagePerHit: 5,
          requiredTicks: 30,
          attackerIds: const ['attacker'],
        ).entityId,
        'npc_guardsman',
      );
      expect(
        () => CombatDefendEntityRef(
          entityId: '',
          positionId: 'ward_position',
          durability: 100,
          damagePerHit: 5,
          requiredTicks: 30,
          attackerIds: const ['attacker'],
        ),
        throwsArgumentError,
      );
      expect(
        () => CombatDefendEntityRef(
          entityId: 'npc',
          positionId: 'ward_position',
          durability: 100,
          damagePerHit: 5,
          requiredTicks: 0,
          attackerIds: const ['attacker'],
        ),
        throwsArgumentError,
      );
      expect(
        () => CombatDefendEntityRef(
          entityId: 'npc',
          positionId: 'ward_position',
          durability: 0,
          damagePerHit: 5,
          requiredTicks: 30,
          attackerIds: const ['attacker'],
        ),
        throwsArgumentError,
      );
      expect(
        () => CombatDefendEntityRef(
          entityId: 'npc',
          positionId: 'ward_position',
          durability: 100,
          damagePerHit: 0,
          requiredTicks: 30,
          attackerIds: const ['attacker'],
        ),
        throwsArgumentError,
      );
      expect(
        () => CombatDefendEntityRef(
          entityId: 'npc',
          positionId: 'ward_position',
          durability: 100,
          damagePerHit: 5,
          requiredTicks: 30,
          attackerIds: const [],
        ),
        throwsArgumentError,
      );
    });

    test('single-target references validate their id', () {
      expect(
        CombatPursueTargetRef(targetId: 'bandit_leader').targetId,
        'bandit_leader',
      );
      expect(
        CombatDefeatCommanderRef(commanderId: 'bandit_commander').commanderId,
        'bandit_commander',
      );
      expect(() => CombatPursueTargetRef(targetId: ''), throwsArgumentError);
      expect(
        () => CombatDefeatCommanderRef(commanderId: 'a b'),
        throwsArgumentError,
      );
    });

    test('set-based references require non-empty unique clean ids', () {
      expect(CombatDefeatTargetsRef(['t1', 't2']).targetIds, {'t1', 't2'});
      expect(() => CombatDefeatTargetsRef([]), throwsArgumentError);
      expect(() => CombatDefeatTargetsRef(['t1', 't1']), throwsArgumentError);
      expect(() => CombatDestroyAnchorsRef(['a1', '']), throwsArgumentError);
      expect(() => CombatReachCheckpointRef(['cp 1']), throwsArgumentError);
      expect(
        () => CombatTouchMarkersRef(['m1', 'm1', 'm2']),
        throwsArgumentError,
      );
    });
  });

  group('CombatEncounterDef', () {
    test('defend attackers must be local encounter spawn entries', () {
      expect(
        () => encounter(
          objectives: CombatObjectiveCompositionRef(
            completionRule: CombatObjectiveCompletionRule.all,
            clauses: [
              CombatObjectiveClauseRef(
                id: 'defend',
                primitive: CombatDefendEntityRef(
                  entityId: 'ward',
                  positionId: 'ward_position',
                  durability: 100,
                  damagePerHit: 5,
                  requiredTicks: 30,
                  attackerIds: const ['foreign_attacker'],
                ),
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('constructs with explicit caller values', () {
      final def = encounter();
      expect(def.id, 'encounter_blackwind_ambush');
      expect(def.spawnConfig.activeLimit, 8);
      expect(def.tokenBudgets.melee, 2);
      expect(def.spawnEntries, hasLength(1));
      expect(def.objectives.completionRule, CombatObjectiveCompletionRule.all);
      expect(
        def.objectives.clauses.single.primitive,
        isA<CombatSurviveDurationRef>(),
      );
    });

    test('blank or whitespace id fails closed', () {
      expect(() => encounter(id: ''), throwsArgumentError);
      expect(() => encounter(id: '  '), throwsArgumentError);
      expect(() => encounter(id: 'encounter one'), throwsArgumentError);
    });

    test('empty spawn entries fail closed', () {
      expect(() => encounter(entries: []), throwsArgumentError);
    });

    test('duplicate entryIds fail closed', () {
      expect(
        () => encounter(
          entries: [
            spawnEntry(entryId: 'e1'),
            spawnEntry(entryId: 'e1'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('mutating the caller input list after construction is a no-op', () {
      final input = [spawnEntry()];
      final def = CombatEncounterDef(
        id: 'enc_1',
        spawnConfig: spawnConfig(),
        tokenBudgets: tokenBudgets(),
        spawnEntries: input,
        objectives: encounter().objectives,
      );
      input.clear();
      input.add(spawnEntry(entryId: 'entry_99'));
      expect(def.spawnEntries, hasLength(1));
      expect(def.spawnEntries.first.entryId, 'entry_01');
    });

    test('exposed spawnEntries list is unmodifiable', () {
      final def = encounter();
      expect(
        () => def.spawnEntries.add(spawnEntry(entryId: 'entry_99')),
        throwsUnsupportedError,
      );
    });

    test('migration state enum is explicit with no default route', () {
      expect(CombatEncounterMigrationState.values, [
        CombatEncounterMigrationState.legacy,
        CombatEncounterMigrationState.migrated,
      ]);
    });
  });
}
