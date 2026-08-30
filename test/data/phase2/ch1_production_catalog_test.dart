import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:yaml/yaml.dart';

const _productionRoot = 'data/combat';
const _canonicalRoles = {
  'bandit_blade',
  'bandit_crossbow',
  'bandit_rope_raider',
  'bandit_gong_leader',
};

Future<(String, String)> _source(String relativePath) async {
  final path = '$_productionRoot/$relativePath';
  return (path, await File(path).readAsString());
}

Future<CombatCatalogManifestDef> _loadProductionCatalog() async {
  final repository = await GameRepository.loadAllDefs(
    loader: (path) => File(path).readAsString(),
    assetExists: (path) async => File(path).existsSync(),
  );
  return repository.combatCatalog!;
}

YamlMap _loadRuntimeBinding() =>
    loadYaml(File('data/combat/runtime_bindings.yaml').readAsStringSync())
        as YamlMap;

Set<String> _yamlStringSet(Object? value) =>
    (value as YamlList).map((item) => item as String).toSet();

void main() {
  tearDown(GameRepository.resetForTest);
  test('production catalog migrates all five Chapter 1 stages', () async {
    final manifest = await _loadProductionCatalog();
    const expected = {
      'stage_01_01': 'ch1_encounter_01_roadbreak',
      'stage_01_02': 'ch1_encounter_02_stronghold',
      'stage_01_03': 'ch1_encounter_03_ambush',
      'stage_01_04': 'ch1_encounter_04_commander',
      'stage_01_05': 'ch1_encounter_05_commander',
    };

    expect(
      manifest.encounters
          .map((encounter) => encounter.id)
          .where((id) => id.startsWith('ch1_'))
          .toSet(),
      expected.values.toSet(),
    );
    for (final entry in expected.entries) {
      final assignment = manifest.assignmentForStage(entry.key);
      expect(
        assignment?.migrationState,
        CombatEncounterMigrationState.migrated,
        reason: entry.key,
      );
      expect(assignment?.encounterId, entry.value, reason: entry.key);
    }
  });

  test('stage_01_03 keeps the frozen production composition', () async {
    final manifest = await _loadProductionCatalog();
    final encounter = manifest.encounterForStage('stage_01_03')!;

    expect(encounter.spawnEntries, hasLength(40));
    expect(encounter.spawnConfig.activeLimit, 12);
    expect(encounter.spawnConfig.reinforcementThreshold, 3);
    expect(encounter.spawnConfig.entryWarningTicks, 30);
    expect(encounter.spawnConfig.attackGraceTicks, 15);
    // stage_01_03 的当前攻击令牌预算经生产 YAML 加载。
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
      manifest
          .archetypeById('ch1_bandits')!
          .variants
          .map((variant) => variant.roleId)
          .toSet(),
      _canonicalRoles,
    );
  });

  test('stage_01_03 production token budget stays in its plan bound', () async {
    final manifest = await _loadProductionCatalog();
    final encounter = manifest.encounterForStage('stage_01_03')!;
    final tokenBudgets = encounter.tokenBudgets;
    final totalTokenBudget =
        tokenBudgets.melee +
        tokenBudgets.ranged +
        tokenBudgets.charge +
        tokenBudgets.support;

    expect(
      totalTokenBudget,
      inInclusiveRange(2, 4),
      reason: 'stage_01_03 攻击令牌总预算须符合二阶段优化方案 :1025 的 [2,4]',
    );
  });

  test(
    'content-order 12-entry refill windows have unique in-bounds positions',
    () async {
      final manifest = await _loadProductionCatalog();
      final encounter = manifest.encounterForStage('stage_01_03')!;
      final binding = (_loadRuntimeBinding()['runtime_bindings'] as YamlList)
          .cast<YamlMap>()
          .firstWhere((item) => item['stage_id'] == 'stage_01_03');
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
      'encounters/chapter_01_templates.yaml',
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
      final binding = (runtime['runtime_bindings'] as YamlList)
          .cast<YamlMap>()
          .firstWhere((item) => item['stage_id'] == 'stage_01_03');

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
        manifest
            .archetypeById('ch1_bandits')!
            .variants
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
        manifest
            .archetypeById('ch1_bandits')!
            .variants
            .expand((variant) => variant.visualVariantIds)
            .toSet(),
      );
      for (final visual in visualVariants) {
        expect(File(visual['asset_path'] as String).existsSync(), isTrue);
      }

      final verified = binding['verified_only_references'] as YamlMap;
      final ch1Variants = manifest.archetypeById('ch1_bandits')!.variants;
      expect(verified['host_consumption'], 'none');
      expect(
        _yamlStringSet(verified['posture_profile_ids']),
        ch1Variants.map((variant) => variant.postureProfileId).toSet(),
      );
      expect(
        _yamlStringSet(verified['drop_group_ids']),
        ch1Variants.map((variant) => variant.dropGroupId).toSet(),
      );
      expect(
        _yamlStringSet(verified['sfx_group_ids']),
        ch1Variants.map((variant) => variant.sfxGroupId).toSet(),
      );
    },
  );
}
