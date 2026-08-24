import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/combat_encounter_catalog_loader.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/validation/combat_catalog_migration_gate.dart';
import 'package:yaml/yaml.dart';

const _productionRoot = 'data/combat';
const _canonicalRoles = {
  'bandit_blade',
  'bandit_crossbow',
  'bandit_rope_raider',
  'bandit_gong_leader',
};

Future<CombatCatalogYamlSource> _source(String relativePath) async {
  final path = '$_productionRoot/$relativePath';
  return (path, await File(path).readAsString());
}

CombatCatalogReferenceIndex _referenceIndex() => CombatCatalogReferenceIndex(
  entranceIds: const {
    'ch1_entrance_s03_front',
    'ch1_entrance_s03_rear',
    'ch1_entrance_s03_upper',
  },
  positionIds: const {
    'ch1_position_s03_slot_01',
    'ch1_position_s03_slot_02',
    'ch1_position_s03_slot_03',
    'ch1_position_s03_slot_04',
    'ch1_position_s03_slot_05',
    'ch1_position_s03_slot_06',
    'ch1_position_s03_slot_07',
    'ch1_position_s03_slot_08',
    'ch1_position_s03_slot_09',
    'ch1_position_s03_slot_10',
    'ch1_position_s03_slot_11',
    'ch1_position_s03_slot_12',
  },
  behaviorIds: const {
    'ch1_behavior_blade_press',
    'ch1_behavior_crossbow_offset',
    'ch1_behavior_rope_flank',
    'ch1_behavior_gong_command',
  },
  attackSetIds: const {
    'ch1_attack_set_blade',
    'ch1_attack_set_crossbow',
    'ch1_attack_set_rope_raider',
    'ch1_attack_set_gong_leader',
  },
  attackTagIds: const {
    'ch1_attack_tag_melee',
    'ch1_attack_tag_projectile',
    'ch1_attack_tag_charge',
    'ch1_attack_tag_support',
  },
  postureProfileIds: const {
    'ch1_posture_blade',
    'ch1_posture_crossbow',
    'ch1_posture_rope_raider',
    'ch1_posture_gong_leader',
  },
  dropGroupIds: const {'ch1_drop_group_bandit_encounter'},
  sfxGroupIds: const {
    'ch1_sfx_blade',
    'ch1_sfx_crossbow',
    'ch1_sfx_rope_raider',
    'ch1_sfx_gong_leader',
  },
  visualVariantIds: const {
    'ch1_visual_blade_a',
    'ch1_visual_blade_b',
    'ch1_visual_crossbow_a',
    'ch1_visual_crossbow_b',
    'ch1_visual_rope_raider_a',
    'ch1_visual_rope_raider_b',
    'ch1_visual_gong_leader_a',
    'ch1_visual_gong_leader_b',
  },
  objectiveTargetIds: {
    for (final prefix in const ['blade', 'crossbow', 'rope'])
      for (var index = 1; index <= (prefix == 'blade' ? 18 : 10); index++)
        'ch1_s03_${prefix}_${index.toString().padLeft(2, '0')}',
    'ch1_s03_leader_01',
    'ch1_s03_leader_02',
  },
  objectiveAnchorIds: const [],
  objectiveEntityIds: const [],
  objectiveCheckpointIds: const [],
  objectiveMarkerIds: const [],
);

Future<CombatCatalogManifestDef> _loadProductionCatalog() async {
  return loadCombatCatalogManifest(
    archetypeSources: [await _source('archetypes/bandits.yaml')],
    encounterSources: [await _source('encounters/black_wind_ridge.yaml')],
    manifestSource: await _source('manifest/stage_assignments.yaml'),
    referenceIndex: _referenceIndex(),
  );
}

YamlMap _loadRuntimeBinding() =>
    loadYaml(File('data/combat/runtime_bindings.yaml').readAsStringSync())
        as YamlMap;

Set<String> _yamlStringSet(Object? value) =>
    (value as YamlList).map((item) => item as String).toSet();

void main() {
  test(
    'production catalog binds only stage_01_03 and preserves Ch1 legacy',
    () async {
      final manifest = await _loadProductionCatalog();

      expect(manifest.encounters.map((encounter) => encounter.id), [
        'ch1_encounter_03_ambush',
      ]);
      expect(
        manifest.assignmentForStage('stage_01_03')?.migrationState,
        CombatEncounterMigrationState.migrated,
      );
      expect(
        manifest.assignmentForStage('stage_01_03')?.encounterId,
        'ch1_encounter_03_ambush',
      );
      for (final stageId in const [
        'stage_01_01',
        'stage_01_02',
        'stage_01_04',
        'stage_01_05',
      ]) {
        final assignment = manifest.assignmentForStage(stageId);
        expect(
          assignment?.migrationState,
          CombatEncounterMigrationState.legacy,
        );
        expect(assignment?.encounterId, isNull);
      }

      final report = validateCombatCatalogMigrationCoverage(
        knownStageIds: const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_03',
          'stage_01_04',
          'stage_01_05',
        ],
        legacyAllowlist: const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_04',
          'stage_01_05',
        ],
        legacyContentStageIds: const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_04',
          'stage_01_05',
        ],
        manifest: manifest,
      );
      expect(report.migratedStageIds, ['stage_01_03']);
      expect(report.legacyStageIds, [
        'stage_01_01',
        'stage_01_02',
        'stage_01_04',
        'stage_01_05',
      ]);
    },
  );

  test('stage_01_03 keeps the G2 TUNING candidate composition', () async {
    final manifest = await _loadProductionCatalog();
    final encounter = manifest.encounterForStage('stage_01_03')!;

    expect(encounter.spawnEntries, hasLength(40));
    expect(encounter.spawnConfig.activeLimit, 12);
    expect(encounter.spawnConfig.reinforcementThreshold, 3);
    expect(encounter.spawnConfig.entryWarningTicks, 30);
    expect(encounter.spawnConfig.attackGraceTicks, 15);
    expect(encounter.tokenBudgets.melee, 1);
    expect(encounter.tokenBudgets.ranged, 1);
    expect(encounter.tokenBudgets.charge, 1);
    expect(encounter.tokenBudgets.support, 1);

    final roleCounts = <String, int>{};
    for (final entry in encounter.spawnEntries) {
      roleCounts.update(entry.roleId, (count) => count + 1, ifAbsent: () => 1);
    }
    expect(roleCounts, {
      'bandit_blade': 18,
      'bandit_crossbow': 10,
      'bandit_rope_raider': 10,
      'bandit_gong_leader': 2,
    });
    expect(
      manifest.archetypes.single.variants
          .map((variant) => variant.roleId)
          .toSet(),
      _canonicalRoles,
    );
  });

  test(
    'content-order 12-entry refill windows have unique in-bounds positions',
    () async {
      final manifest = await _loadProductionCatalog();
      final encounter = manifest.encounterForStage('stage_01_03')!;
      final binding =
          (_loadRuntimeBinding()['runtime_bindings'] as YamlList).single
              as YamlMap;
      final positionBindings = {
        for (final item in binding['positions'] as YamlList)
          (item as YamlMap)['id'] as String:
              (item['world_position'] as YamlMap),
      };

      expect(positionBindings, hasLength(12));
      final coordinates = <String, String>{};
      for (final entry in positionBindings.entries) {
        final x = (entry.value['x'] as num).toDouble();
        final y = (entry.value['y'] as num).toDouble();
        expect(x, inInclusiveRange(-640, 640), reason: entry.key);
        expect(y, inInclusiveRange(-260, 260), reason: entry.key);
        coordinates[entry.key] = '$x,$y';
      }
      expect(coordinates.values.toSet(), hasLength(12));

      final orderedEntries = encounter.spawnEntries;
      expect(
        orderedEntries.take(12).map((entry) => entry.positionId).toSet(),
        hasLength(12),
      );
      expect(
        orderedEntries.take(12).map((entry) => entry.entryId).toSet(),
        hasLength(12),
      );

      for (var start = 0; start <= orderedEntries.length - 12; start++) {
        final window = orderedEntries.sublist(start, start + 12);
        final windowCoordinates = window
            .map((entry) => coordinates[entry.positionId])
            .toSet();
        expect(
          windowCoordinates,
          hasLength(12),
          reason:
              'content-order refill window start=$start contains stacked positions',
        );
      }
    },
  );

  test('production sources contain no candidate namespace or marker', () async {
    final paths = [
      'archetypes/bandits.yaml',
      'encounters/black_wind_ridge.yaml',
      'manifest/stage_assignments.yaml',
    ];
    for (final path in paths) {
      final content = (await _source(path)).$2;
      expect(content, isNot(contains('candidate_')), reason: path);
      expect(content, isNot(contains('CANDIDATE-ONLY')), reason: path);
      expect(content, isNot(contains('FROZEN')), reason: path);
    }
  });

  test(
    'runtime bindings close deterministic spawn, AI, skill and visual refs',
    () async {
      final manifest = await _loadProductionCatalog();
      final encounter = manifest.encounterForStage('stage_01_03')!;
      final runtime = _loadRuntimeBinding();
      final binding =
          (runtime['runtime_bindings'] as YamlList).single as YamlMap;

      expect(binding['stage_id'], 'stage_01_03');
      expect(binding['encounter_id'], encounter.id);

      final entrances = (binding['entrances'] as YamlList)
          .map((item) => item as YamlMap)
          .toList();
      final positions = (binding['positions'] as YamlList)
          .map((item) => item as YamlMap)
          .toList();
      expect(
        entrances.map((item) => item['id']).toSet(),
        encounter.spawnEntries.map((entry) => entry.entranceId).toSet(),
      );
      expect(
        positions.map((item) => item['id']).toSet(),
        encounter.spawnEntries.map((entry) => entry.positionId).toSet(),
      );
      for (final item in [...entrances, ...positions]) {
        final point = (item.values.last as YamlMap);
        expect(point['x'], isA<num>());
        expect(point['y'], isA<num>());
      }

      final behaviors = (binding['behaviors'] as YamlList)
          .map((item) => item as YamlMap)
          .toList();
      expect(
        behaviors.map((item) => item['id']).toSet(),
        encounter.spawnEntries.map((entry) => entry.behaviorId).toSet(),
      );
      expect(
        behaviors.map((item) => item['ai_profile_id']).toSet(),
        (binding['ai_profiles'] as YamlList)
            .map((item) => (item as YamlMap)['id'] as String)
            .toSet(),
      );

      final skillSource = File('data/skills.yaml').readAsStringSync();
      final attackSets = (binding['attack_sets'] as YamlList)
          .map((item) => item as YamlMap)
          .toList();
      expect(
        attackSets.map((item) => item['id']).toSet(),
        manifest.archetypes.single.variants
            .map((variant) => variant.attackSetId)
            .toSet(),
      );
      for (final attackSet in attackSets) {
        for (final skillId in attackSet['skill_ids'] as YamlList) {
          expect(skillSource, contains('  - id: $skillId'));
        }
      }

      final visualVariants = (binding['visual_variants'] as YamlList)
          .map((item) => item as YamlMap)
          .toList();
      expect(
        visualVariants.map((item) => item['id']).toSet(),
        manifest.archetypes.single.variants
            .expand((variant) => variant.visualVariantIds)
            .toSet(),
      );
      for (final visual in visualVariants) {
        expect(File(visual['asset_path'] as String).existsSync(), isTrue);
      }

      final verified = binding['verified_only_references'] as YamlMap;
      expect(verified['host_consumption'], 'none');
      expect(
        _yamlStringSet(verified['posture_profile_ids']),
        _referenceIndex().postureProfileIds,
      );
      expect(
        _yamlStringSet(verified['drop_group_ids']),
        _referenceIndex().dropGroupIds,
      );
      expect(
        _yamlStringSet(verified['sfx_group_ids']),
        _referenceIndex().sfxGroupIds,
      );
    },
  );
}
