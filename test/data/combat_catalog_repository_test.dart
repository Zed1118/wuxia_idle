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
        throw FileSystemException('missing', path, const OSError('missing', 2));
      });
      expect(catalog, isNull);
    },
  );

  test(
    'FileSystemException without an explicit missing code is not fallback',
    () async {
      await expectLater(
        loadProductionCombatCatalogIfPresent((path) async {
          throw FileSystemException('unknown filesystem failure', path);
        }),
        throwsA(
          isA<CombatCatalogLoadException>().having(
            (error) => error.kind,
            'kind',
            CombatCatalogLoadFailureKind.manifestRead,
          ),
        ),
      );
    },
  );

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
        throw FileSystemException('missing', path, const OSError('missing', 2));
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

  test('manifest parse failure is classified as manifestInvalid', () async {
    await expectLater(
      loadProductionCombatCatalogIfPresent((path) async {
        if (path == 'data/combat/manifest.yaml') return 'reference_index: []';
        throw FileSystemException('missing', path, const OSError('missing', 2));
      }),
      throwsA(
        isA<CombatCatalogLoadException>().having(
          (error) => error.kind,
          'kind',
          CombatCatalogLoadFailureKind.manifestInvalid,
        ),
      ),
    );
  });

  test('non-missing source read failure is classified as sourceRead', () async {
    await expectLater(
      loadProductionCombatCatalogIfPresent((path) async {
        if (path == 'data/combat/manifest.yaml') {
          return '''archetype_sources: [fixture.yaml]
encounter_sources: [fixture.yaml]
reference_index:
  entrance_ids: []
  position_ids: []
  behavior_ids: []
  attack_set_ids: []
  attack_tag_ids: []
  posture_profile_ids: []
  drop_group_ids: []
  sfx_group_ids: []
  visual_variant_ids: []
  objective_target_ids: []
  objective_anchor_ids: []
  objective_entity_ids: []
  objective_checkpoint_ids: []
  objective_marker_ids: []
stage_assignments:
  - stage_id: legacy
    migration_state: legacy''';
        }
        throw StateError('permission denied');
      }),
      throwsA(
        isA<CombatCatalogLoadException>().having(
          (error) => error.kind,
          'kind',
          CombatCatalogLoadFailureKind.sourceRead,
        ),
      ),
    );
  });

  test('catalog content failure is classified as catalogInvalid', () async {
    await expectLater(
      loadProductionCombatCatalogIfPresent((path) async {
        if (path == 'data/combat/manifest.yaml') {
          return '''archetype_sources: [bad.yaml]
encounter_sources: [bad.yaml]
reference_index:
  entrance_ids: []
  position_ids: []
  behavior_ids: []
  attack_set_ids: []
  attack_tag_ids: []
  posture_profile_ids: []
  drop_group_ids: []
  sfx_group_ids: []
  visual_variant_ids: []
  objective_target_ids: []
  objective_anchor_ids: []
  objective_entity_ids: []
  objective_checkpoint_ids: []
  objective_marker_ids: []
stage_assignments:
  - stage_id: legacy
    migration_state: legacy''';
        }
        if (path == 'bad.yaml') return 'archetypes: [{}]';
        throw StateError('unexpected source');
      }),
      throwsA(
        isA<CombatCatalogLoadException>().having(
          (error) => error.kind,
          'kind',
          CombatCatalogLoadFailureKind.catalogInvalid,
        ),
      ),
    );
  });
}
