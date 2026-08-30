import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/combat_enemy_archetype_def.dart';
import 'package:wuxia_idle/data/validation/combat_stage_encounter_route_selector.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_migration_resolver.dart';

void main() {
  CombatEnemyArchetypeDef archetype() => CombatEnemyArchetypeDef(
    id: 'archetype_bandit',
    variants: [
      CombatArchetypeVariant(
        roleId: 'role_blade',
        displayName: '刀手',
        attackTokenKind: CombatAttackTokenKind.melee,
        hpMultiplier: 1,
        attackMultiplier: 1,
        defenseMultiplier: 1,
        speedMultiplier: 1,
        attackSetId: 'attack_set_blade',
        attackTagIds: const ['attack_tag_melee'],
        postureProfileId: 'posture_bandit',
        dropGroupId: 'drop_group_bandit',
        sfxGroupId: 'sfx_group_bandit',
        visualVariantIds: const ['visual_bandit'],
      ),
    ],
  );

  CombatCatalogReferenceIndex referenceIndex() => CombatCatalogReferenceIndex(
    entranceIds: const ['entrance_left'],
    positionIds: const ['position_left'],
    behaviorIds: const ['behavior_press'],
    attackSetIds: const ['attack_set_blade'],
    attackTagIds: const ['attack_tag_melee'],
    postureProfileIds: const ['posture_bandit'],
    dropGroupIds: const ['drop_group_bandit'],
    sfxGroupIds: const ['sfx_group_bandit'],
    visualVariantIds: const ['visual_bandit'],
    objectiveTargetIds: const ['target_bandit'],
    objectiveAnchorIds: const [],
    objectiveEntityIds: const [],
    objectiveCheckpointIds: const [],
    objectiveMarkerIds: const [],
  );

  CombatEncounterDef encounter({String id = 'encounter_migrated'}) =>
      CombatEncounterDef(
        id: id,
        spawnConfig: CombatEncounterSpawnConfig(
          activeLimit: 1,
          reinforcementThreshold: 0,
          entryWarningTicks: 0,
          attackGraceTicks: 0,
        ),
        tokenBudgets: CombatEncounterTokenBudgets(
          melee: 1,
          ranged: 0,
          charge: 0,
          support: 0,
        ),
        spawnEntries: [
          CombatEncounterSpawnEntry(
            entryId: 'entry_$id',
            archetypeId: 'archetype_bandit',
            roleId: 'role_blade',
            entranceId: 'entrance_left',
            positionId: 'position_left',
            behaviorId: 'behavior_press',
          ),
        ],
        objectives: CombatObjectiveCompositionRef(
          completionRule: CombatObjectiveCompletionRule.all,
          clauses: [
            CombatObjectiveClauseRef(
              id: 'objective_$id',
              primitive: CombatDefeatTargetsRef(const ['target_bandit']),
            ),
          ],
        ),
      );

  CombatCatalogManifestDef manifest() => CombatCatalogManifestDef(
    referenceIndex: referenceIndex(),
    archetypes: [archetype()],
    encounters: [encounter()],
    stageAssignments: [
      CombatStageEncounterAssignment(
        stageId: 'stage_legacy',
        migrationState: CombatEncounterMigrationState.legacy,
      ),
      CombatStageEncounterAssignment(
        stageId: 'stage_migrated',
        migrationState: CombatEncounterMigrationState.migrated,
        encounterId: 'encounter_migrated',
      ),
    ],
  );

  Phase0aEncounterMigrationResolver resolver({
    Iterable<String> legacyContentIds = const ['stage_legacy'],
  }) => Phase0aEncounterMigrationResolver(legacyContentIds: legacyContentIds);

  group('selectCombatStageEncounterRoute', () {
    test('returns the valid legacy route', () {
      final route = selectCombatStageEncounterRoute(
        manifest: manifest(),
        stageId: 'stage_legacy',
        migrationResolver: resolver(),
        hasLegacyContent: true,
      );

      expect(route, isA<LegacyCombatStageEncounterRoute>());
      expect(route.stageId, 'stage_legacy');
    });

    test('returns migrated route with exact manifest encounter identity', () {
      final sourceManifest = manifest();
      final expectedEncounter = sourceManifest.encounterForStage(
        'stage_migrated',
      );

      final route = selectCombatStageEncounterRoute(
        manifest: sourceManifest,
        stageId: 'stage_migrated',
        migrationResolver: resolver(),
        hasLegacyContent: false,
      );

      expect(route, isA<MigratedCombatStageEncounterRoute>());
      expect(
        identical(
          (route as MigratedCombatStageEncounterRoute).encounter,
          expectedEncounter,
        ),
        isTrue,
      );
    });

    test('unknown stage fails closed', () {
      expect(
        () => selectCombatStageEncounterRoute(
          manifest: manifest(),
          stageId: 'stage_unknown',
          migrationResolver: resolver(),
          hasLegacyContent: false,
        ),
        throwsArgumentError,
      );
    });

    test('state and allowlist mismatches fail closed in both directions', () {
      expect(
        () => selectCombatStageEncounterRoute(
          manifest: manifest(),
          stageId: 'stage_legacy',
          migrationResolver: resolver(legacyContentIds: const []),
          hasLegacyContent: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => selectCombatStageEncounterRoute(
          manifest: manifest(),
          stageId: 'stage_migrated',
          migrationResolver: resolver(
            legacyContentIds: const ['stage_legacy', 'stage_migrated'],
          ),
          hasLegacyContent: false,
        ),
        throwsArgumentError,
      );
    });

    test('legacy stage without legacy content fails closed', () {
      expect(
        () => selectCombatStageEncounterRoute(
          manifest: manifest(),
          stageId: 'stage_legacy',
          migrationResolver: resolver(),
          hasLegacyContent: false,
        ),
        throwsArgumentError,
      );
    });

    test('migrated stage with legacy content never falls back to legacy', () {
      CombatStageEncounterRoute? route;

      expect(
        () => route = selectCombatStageEncounterRoute(
          manifest: manifest(),
          stageId: 'stage_migrated',
          migrationResolver: resolver(),
          hasLegacyContent: true,
        ),
        throwsArgumentError,
      );
      expect(route, isNull);
    });

    test(
      'typed manifest rejects missing migrated encounter before selection',
      () {
        expect(
          () => CombatCatalogManifestDef(
            referenceIndex: referenceIndex(),
            archetypes: const [],
            encounters: const [],
            stageAssignments: [
              CombatStageEncounterAssignment(
                stageId: 'stage_missing',
                migrationState: CombatEncounterMigrationState.migrated,
                encounterId: 'encounter_missing',
              ),
            ],
          ),
          throwsArgumentError,
        );
      },
    );

    test('typed manifest rejects multiple assignments for one stage', () {
      expect(
        () => CombatCatalogManifestDef(
          referenceIndex: referenceIndex(),
          archetypes: [archetype()],
          encounters: [
            encounter(id: 'encounter_a'),
            encounter(id: 'encounter_b'),
          ],
          stageAssignments: [
            CombatStageEncounterAssignment(
              stageId: 'stage_multi',
              migrationState: CombatEncounterMigrationState.migrated,
              encounterId: 'encounter_a',
            ),
            CombatStageEncounterAssignment(
              stageId: 'stage_multi',
              migrationState: CombatEncounterMigrationState.migrated,
              encounterId: 'encounter_b',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('selection is deterministic and returns fresh immutable routes', () {
      final sourceManifest = manifest();
      final sourceResolver = resolver();

      final first = selectCombatStageEncounterRoute(
        manifest: sourceManifest,
        stageId: 'stage_migrated',
        migrationResolver: sourceResolver,
        hasLegacyContent: false,
      );
      final second = selectCombatStageEncounterRoute(
        manifest: sourceManifest,
        stageId: 'stage_migrated',
        migrationResolver: sourceResolver,
        hasLegacyContent: false,
      );

      expect(first, isNot(same(second)));
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.stageId, second.stageId);
      expect(
        identical(
          (first as MigratedCombatStageEncounterRoute).encounter,
          (second as MigratedCombatStageEncounterRoute).encounter,
        ),
        isTrue,
      );
    });

    test('source stays host-neutral and does not duplicate coverage gate', () {
      final source = File(
        'lib/data/validation/combat_stage_encounter_route_selector.dart',
      ).readAsStringSync();
      final imports = RegExp(
        r"^import '([^']+)';$",
        multiLine: true,
      ).allMatches(source).map((match) => match.group(1)).toList();

      expect(imports, [
        '../../features/battle/application/phase0a/phase0a_encounter_migration_resolver.dart',
        '../defs/combat_catalog_manifest_def.dart',
        '../defs/combat_encounter_def.dart',
      ]);
      for (final forbidden in <String>[
        'dart:io',
        'rootBundle',
        'GameRepository',
        'combat_catalog_migration_gate',
        'validateCombatCatalogMigrationCoverage',
        'candidate_ch1_',
      ]) {
        expect(source, isNot(contains(forbidden)));
      }
      expect(source, isNot(contains('catch (')));
    });
  });
}
