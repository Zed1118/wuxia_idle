import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/combat_catalog_repository.dart';
import 'package:wuxia_idle/data/validation/combat_encounter_runtime_contract_mapper.dart';
import 'package:wuxia_idle/data/validation/combat_stage_encounter_route_selector.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_migration_resolver.dart';

const root = 'test/fixtures/phase2/combat/catalog_loader';

Future<String> fixtureLoader(String path) async {
  if (path == 'data/combat/manifest.yaml') {
    final assignments = await File(
      '$root/manifest/stage_assignments.yaml',
    ).readAsString();
    return '''
archetype_sources:
  - $root/archetypes/bandit.yaml
  - $root/archetypes/wolf.yaml
  - $root/archetypes/totem.yaml
  - $root/archetypes/commander.yaml
encounter_sources:
  - $root/encounters/enc_defeat_targets.yaml
  - $root/encounters/enc_destroy_anchors.yaml
  - $root/encounters/enc_defend_entity.yaml
  - $root/encounters/enc_survive_duration.yaml
  - $root/encounters/enc_reach_checkpoint.yaml
  - $root/encounters/enc_touch_markers.yaml
  - $root/encounters/enc_pursue_target.yaml
  - $root/encounters/enc_defeat_commander.yaml
reference_index:
  entrance_ids: [entrance_fixture]
  position_ids: [position_fixture]
  behavior_ids: [behavior_fixture]
  attack_set_ids: [attack_set_fixture]
  attack_tag_ids: [attack_tag_fixture]
  posture_profile_ids: [posture_fixture]
  drop_group_ids: [drop_fixture]
  sfx_group_ids: [sfx_fixture]
  visual_variant_ids: [visual_fixture]
  objective_target_ids: [bandit_brute, bandit_scout, fleeing_alpha, commander_chief, totem_alpha]
  objective_anchor_ids: [totem_alpha, totem_beta]
  objective_entity_ids: [escorted_cart]
  objective_checkpoint_ids: [checkpoint_exit, checkpoint_gate, checkpoint_bridge]
  objective_marker_ids: [marker_east, marker_west, marker_north]
$assignments''';
  }
  return File(path).readAsString();
}

void main() {
  test(
    'loads explicit production manifest and exposes typed stage lookup',
    () async {
      final catalog = await loadProductionCombatCatalogIfPresent(fixtureLoader);
      expect(catalog, isNotNull);
      expect(
        catalog!.assignmentForStage('cl_stage_01')!.encounterId,
        'cl_enc_defeat_targets',
      );
      expect(
        catalog.encounterForStage('cl_stage_01')!.id,
        'cl_enc_defeat_targets',
      );
      expect(catalog.archetypeById('arch_bandit')!.id, 'arch_bandit');
    },
  );

  test(
    'missing production manifest is the only absent-data fallback',
    () async {
      final catalog = await loadProductionCombatCatalogIfPresent((path) async {
        throw FileSystemException('missing', path);
      }, isMissingAssetError: (error) => error is FileSystemException);
      expect(catalog, isNull);
    },
  );

  test('non-missing manifest read failure is classified and not swallowed', () {
    expect(
      loadProductionCombatCatalogIfPresent((path) async {
        throw StateError('permission denied');
      }),
      throwsA(
        isA<CombatCatalogLoadException>().having(
          (error) => error.kind,
          'kind',
          CombatCatalogLoadFailureKind.manifestRead,
        ),
      ),
    );
  });

  test('manifest with a missing referenced source fails closed', () async {
    expect(
      loadProductionCombatCatalogIfPresent((path) async {
        if (path == 'data/combat/manifest.yaml') {
          return '''archetype_sources: [missing.yaml]
encounter_sources: [missing.yaml]
reference_index:
  entrance_ids: [fixture]
  position_ids: [fixture]
  behavior_ids: [fixture]
  attack_set_ids: [fixture]
  attack_tag_ids: [fixture]
  posture_profile_ids: [fixture]
  drop_group_ids: [fixture]
  sfx_group_ids: [fixture]
  visual_variant_ids: [fixture]
  objective_target_ids: [fixture]
  objective_anchor_ids: [fixture]
  objective_entity_ids: [fixture]
  objective_checkpoint_ids: [fixture]
  objective_marker_ids: [fixture]
stage_assignments:
  - stage_id: legacy
    migration_state: legacy''';
        }
        throw FileSystemException('missing', path);
      }),
      throwsA(
        isA<CombatCatalogLoadException>()
            .having(
              (error) => error.kind,
              'kind',
              CombatCatalogLoadFailureKind.sourceMissing,
            )
            .having(
              (error) => error.message,
              'message',
              contains('missing.yaml'),
            ),
      ),
    );
  });

  test('production stage_01_03 binds a migrated route and runtime contract', () async {
    final catalog = await loadProductionCombatCatalogIfPresent(
      (path) => File(path).readAsString(),
    );
    expect(catalog, isNotNull);
    expect(
      catalog!.encounterForStage('stage_01_03')!.id,
      'ch1_encounter_03_ambush',
    );
    expect(catalog.archetypeById('ch1_bandits')!.id, 'ch1_bandits');
    final resolver = Phase0aEncounterMigrationResolver(
      legacyContentIds: const [
        'stage_01_01',
        'stage_01_02',
        'stage_01_04',
        'stage_01_05',
      ],
    );
    final route = selectCombatStageEncounterRoute(
      manifest: catalog,
      stageId: 'stage_01_03',
      migrationResolver: resolver,
      hasLegacyContent: false,
    );
    expect(route, isA<MigratedCombatStageEncounterRoute>());
    final encounter = (route as MigratedCombatStageEncounterRoute).encounter;
    final contract = mapCombatEncounterRuntimeContract(
      encounter,
      tickDuration: const Duration(milliseconds: 100),
      resolveEnemyId: (entry) => 'runtime_${entry.entryId}',
    );
    expect(contract.spawnDirector.config.activeLimit, 12);
    expect(contract.spawnDirector.state.units, hasLength(40));
    expect(contract.attackTokenBudgets.melee, 1);
    expect(contract.attackTokenBudgets.ranged, 1);
    expect(contract.attackTokenBudgets.charge, 1);
    expect(contract.attackTokenBudgets.support, 1);
  });

  test('production Ch1 stages other than stage_01_03 remain legacy', () async {
    final catalog = (await loadProductionCombatCatalogIfPresent(
      (path) => File(path).readAsString(),
    ))!;
    final resolver = Phase0aEncounterMigrationResolver(
      legacyContentIds: const [
        'stage_01_01',
        'stage_01_02',
        'stage_01_04',
        'stage_01_05',
      ],
    );
    for (final stageId in const [
      'stage_01_01',
      'stage_01_02',
      'stage_01_04',
      'stage_01_05',
    ]) {
      final route = selectCombatStageEncounterRoute(
        manifest: catalog,
        stageId: stageId,
        migrationResolver: resolver,
        hasLegacyContent: true,
      );
      expect(route, isA<LegacyCombatStageEncounterRoute>());
      expect(catalog.encounterForStage(stageId), isNull);
    }
  });
}
