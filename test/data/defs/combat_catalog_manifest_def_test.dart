// Contract tests for P2-G2-S01 CombatCatalogManifestDef.

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_enemy_archetype_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';

CombatEnemyArchetypeDef banditArchetype() => CombatEnemyArchetypeDef(
  id: 'bandit_swordsman',
  variants: [
    CombatArchetypeVariant(
      roleId: 'melee_brute',
      attackTokenKind: CombatAttackTokenKind.melee,
      hpMultiplier: 1.0,
      attackMultiplier: 1.0,
      defenseMultiplier: 0.5,
      speedMultiplier: 1.0,
      attackSetId: 'attack_set_bandit',
      attackTagIds: const ['attack_tag_melee'],
      postureProfileId: 'posture_bandit',
      dropGroupId: 'drop_bandit',
      sfxGroupId: 'sfx_bandit',
      visualVariantIds: const ['visual_bandit'],
    ),
    CombatArchetypeVariant(
      roleId: 'ranged_archer',
      attackTokenKind: CombatAttackTokenKind.ranged,
      hpMultiplier: 0.8,
      attackMultiplier: 1.4,
      defenseMultiplier: 0.3,
      speedMultiplier: 1.1,
      attackSetId: 'attack_set_bandit',
      attackTagIds: const ['attack_tag_ranged'],
      postureProfileId: 'posture_bandit',
      dropGroupId: 'drop_bandit',
      sfxGroupId: 'sfx_bandit',
      visualVariantIds: const ['visual_bandit'],
    ),
  ],
);

CombatEncounterDef ambushEncounter() => CombatEncounterDef(
  id: 'encounter_blackwind_ambush',
  spawnConfig: CombatEncounterSpawnConfig(
    activeLimit: 8,
    reinforcementThreshold: 2,
    entryWarningTicks: 3,
    attackGraceTicks: 2,
  ),
  tokenBudgets: CombatEncounterTokenBudgets(
    melee: 2,
    ranged: 1,
    charge: 1,
    support: 1,
  ),
  spawnEntries: [
    CombatEncounterSpawnEntry(
      entryId: 'entry_01',
      archetypeId: 'bandit_swordsman',
      roleId: 'melee_brute',
      entranceId: 'entrance_left',
      positionId: 'position_left',
      behaviorId: 'behavior_press',
    ),
  ],
  objectives: CombatObjectiveCompositionRef(
    completionRule: CombatObjectiveCompletionRule.all,
    clauses: [
      CombatObjectiveClauseRef(
        id: 'survive',
        primitive: CombatSurviveDurationRef(requiredTicks: 60),
      ),
    ],
  ),
);

CombatCatalogReferenceIndex referenceIndex() => CombatCatalogReferenceIndex(
  entranceIds: const ['entrance_left'],
  positionIds: const ['position_left'],
  behaviorIds: const ['behavior_press'],
  attackSetIds: const ['attack_set_bandit'],
  attackTagIds: const ['attack_tag_melee', 'attack_tag_ranged'],
  postureProfileIds: const ['posture_bandit'],
  dropGroupIds: const ['drop_bandit'],
  sfxGroupIds: const ['sfx_bandit'],
  visualVariantIds: const ['visual_bandit'],
);

CombatStageEncounterAssignment migratedAssignment({
  String stageId = 'stage_blackwind_ambush',
  String? encounterId = 'encounter_blackwind_ambush',
}) => CombatStageEncounterAssignment(
  stageId: stageId,
  migrationState: CombatEncounterMigrationState.migrated,
  encounterId: encounterId,
);

CombatStageEncounterAssignment legacyAssignment({
  String stageId = 'stage_legacy_forest',
}) => CombatStageEncounterAssignment(
  stageId: stageId,
  migrationState: CombatEncounterMigrationState.legacy,
  encounterId: null,
);

CombatCatalogManifestDef manifest({
  List<CombatEnemyArchetypeDef>? archetypes,
  List<CombatEncounterDef>? encounters,
  List<CombatStageEncounterAssignment>? stageAssignments,
}) => CombatCatalogManifestDef(
  referenceIndex: referenceIndex(),
  archetypes: archetypes ?? const [],
  encounters: encounters ?? const [],
  stageAssignments: stageAssignments ?? const [],
);

void main() {
  group('CombatStageEncounterAssignment', () {
    test('migrated requires exactly one encounterId', () {
      expect(migratedAssignment().encounterId, 'encounter_blackwind_ambush');
      expect(() => migratedAssignment(encounterId: null), throwsArgumentError);
    });

    test('legacy must not carry an encounterId', () {
      expect(legacyAssignment().encounterId, isNull);
      expect(
        () => CombatStageEncounterAssignment(
          stageId: 'stage_legacy_forest',
          migrationState: CombatEncounterMigrationState.legacy,
          encounterId: 'encounter_blackwind_ambush',
        ),
        throwsArgumentError,
      );
    });

    test('blank or whitespace ids fail closed', () {
      expect(() => migratedAssignment(stageId: ''), throwsArgumentError);
      expect(() => migratedAssignment(stageId: 'stage 1'), throwsArgumentError);
      expect(() => migratedAssignment(encounterId: '  '), throwsArgumentError);
      expect(() => legacyAssignment(stageId: 'stage\nx'), throwsArgumentError);
    });
  });

  group('CombatCatalogManifestDef', () {
    test('constructs and resolves lookups', () {
      final def = manifest(
        archetypes: [banditArchetype()],
        encounters: [ambushEncounter()],
        stageAssignments: [migratedAssignment()],
      );
      expect(def.archetypeById('bandit_swordsman'), isNotNull);
      expect(def.archetypeById('unknown'), isNull);
      expect(def.encounterById('encounter_blackwind_ambush'), isNotNull);
      expect(def.encounterById('unknown'), isNull);
      final assignment = def.assignmentForStage('stage_blackwind_ambush');
      expect(assignment, isNotNull);
      expect(
        assignment!.migrationState,
        CombatEncounterMigrationState.migrated,
      );
      expect(
        def.encounterForStage('stage_blackwind_ambush')!.id,
        'encounter_blackwind_ambush',
      );
      expect(def.encounterForStage('unknown_stage'), isNull);
    });

    test('legacy stage resolves to no encounter', () {
      final def = manifest(
        archetypes: [banditArchetype()],
        encounters: [ambushEncounter()],
        stageAssignments: [legacyAssignment(), migratedAssignment()],
      );
      expect(
        def.assignmentForStage('stage_legacy_forest')!.migrationState,
        CombatEncounterMigrationState.legacy,
      );
      expect(def.encounterForStage('stage_legacy_forest'), isNull);
    });

    test('duplicate archetype ids fail closed', () {
      expect(
        () => manifest(
          archetypes: [banditArchetype(), banditArchetype()],
          encounters: [ambushEncounter()],
          stageAssignments: [migratedAssignment()],
        ),
        throwsArgumentError,
      );
    });

    test('duplicate encounter ids fail closed', () {
      expect(
        () => manifest(
          archetypes: [banditArchetype()],
          encounters: [ambushEncounter(), ambushEncounter()],
          stageAssignments: [migratedAssignment()],
        ),
        throwsArgumentError,
      );
    });

    test('duplicate stageIds fail closed', () {
      expect(
        () => manifest(
          archetypes: [banditArchetype()],
          encounters: [
            ambushEncounter(),
            CombatEncounterDef(
              id: 'encounter_other',
              spawnConfig: ambushEncounter().spawnConfig,
              tokenBudgets: ambushEncounter().tokenBudgets,
              spawnEntries: ambushEncounter().spawnEntries,
              objectives: ambushEncounter().objectives,
            ),
          ],
          stageAssignments: [
            migratedAssignment(),
            migratedAssignment(
              stageId: 'stage_blackwind_ambush',
              encounterId: 'encounter_other',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('an encounter assigned to two stages fails closed', () {
      expect(
        () => manifest(
          archetypes: [banditArchetype()],
          encounters: [ambushEncounter()],
          stageAssignments: [
            migratedAssignment(stageId: 'stage_a'),
            migratedAssignment(stageId: 'stage_b'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('unreferenced catalog encounter fails closed', () {
      expect(
        () => manifest(
          archetypes: [banditArchetype()],
          encounters: [ambushEncounter()],
          stageAssignments: [legacyAssignment()],
        ),
        throwsArgumentError,
      );
    });

    test('assignment referencing an unknown encounter fails closed', () {
      expect(
        () => manifest(
          archetypes: [banditArchetype()],
          encounters: [ambushEncounter()],
          stageAssignments: [
            migratedAssignment(encounterId: 'encounter_ghost'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('spawn entry referencing an unknown archetype fails closed', () {
      final broken = CombatEncounterDef(
        id: 'encounter_broken',
        spawnConfig: ambushEncounter().spawnConfig,
        tokenBudgets: ambushEncounter().tokenBudgets,
        spawnEntries: [
          CombatEncounterSpawnEntry(
            entryId: 'entry_01',
            archetypeId: 'ghost_archetype',
            roleId: 'melee_brute',
            entranceId: 'entrance_left',
            positionId: 'position_left',
            behaviorId: 'behavior_press',
          ),
        ],
        objectives: ambushEncounter().objectives,
      );
      expect(
        () => manifest(
          archetypes: [banditArchetype()],
          encounters: [broken],
          stageAssignments: [
            migratedAssignment(encounterId: 'encounter_broken'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('spawn entry referencing an unknown variant role fails closed', () {
      final broken = CombatEncounterDef(
        id: 'encounter_broken',
        spawnConfig: ambushEncounter().spawnConfig,
        tokenBudgets: ambushEncounter().tokenBudgets,
        spawnEntries: [
          CombatEncounterSpawnEntry(
            entryId: 'entry_01',
            archetypeId: 'bandit_swordsman',
            roleId: 'ghost_role',
            entranceId: 'entrance_left',
            positionId: 'position_left',
            behaviorId: 'behavior_press',
          ),
        ],
        objectives: ambushEncounter().objectives,
      );
      expect(
        () => manifest(
          archetypes: [banditArchetype()],
          encounters: [broken],
          stageAssignments: [
            migratedAssignment(encounterId: 'encounter_broken'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('mutating caller input lists after construction is a no-op', () {
      final archetypes = <CombatEnemyArchetypeDef>[banditArchetype()];
      final encounters = <CombatEncounterDef>[ambushEncounter()];
      final assignments = <CombatStageEncounterAssignment>[
        migratedAssignment(),
      ];
      final def = manifest(
        archetypes: archetypes,
        encounters: encounters,
        stageAssignments: assignments,
      );
      archetypes.clear();
      encounters.clear();
      assignments.clear();
      expect(def.archetypes, hasLength(1));
      expect(def.encounters, hasLength(1));
      expect(def.stageAssignments, hasLength(1));
      expect(def.encounterForStage('stage_blackwind_ambush'), isNotNull);
    });

    test('exposed collections are unmodifiable', () {
      final def = manifest(
        archetypes: [banditArchetype()],
        encounters: [ambushEncounter()],
        stageAssignments: [migratedAssignment()],
      );
      expect(() => def.archetypes.clear(), throwsUnsupportedError);
      expect(() => def.encounters.clear(), throwsUnsupportedError);
      expect(() => def.stageAssignments.clear(), throwsUnsupportedError);
    });
  });
}
