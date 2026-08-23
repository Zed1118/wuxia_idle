// CANDIDATE-ONLY NON-PRODUCTION TEST CONTRACT.
// Every number exercised here is an unfrozen candidate for review only.
// This test must never be used as a production catalog source.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/combat_encounter_catalog_loader.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/validation/combat_objective_primitive_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';

const candidateFixtureRoot = 'test/fixtures/phase2/combat/ch1_candidate';
const candidateOnlyMarker = 'CANDIDATE-ONLY NON-PRODUCTION';
const candidateIdMarker = 'candidate_ch1_';

const canonicalBanditRoleIds = {
  'bandit_blade',
  'bandit_crossbow',
  'bandit_rope_raider',
  'bandit_gong_leader',
};

Future<CombatCatalogYamlSource> _candidateSource(String relativePath) async {
  final path = '$candidateFixtureRoot/$relativePath';
  return (path, await File(path).readAsString());
}

CombatCatalogReferenceIndex _candidateReferenceIndex() {
  return CombatCatalogReferenceIndex(
    entranceIds: const {
      'candidate_ch1_entrance_s01_road_west',
      'candidate_ch1_entrance_s01_road_ridge',
      'candidate_ch1_entrance_s01_road_exit',
      'candidate_ch1_entrance_s02_gate',
      'candidate_ch1_entrance_s02_roof',
      'candidate_ch1_entrance_s02_yard',
      'candidate_ch1_entrance_s03_front',
      'candidate_ch1_entrance_s03_rear',
      'candidate_ch1_entrance_s03_upper',
      'candidate_ch1_entrance_s04_duel_court',
      'candidate_ch1_entrance_s05_peak_ring',
    },
    positionIds: const {
      'candidate_ch1_position_s01_near',
      'candidate_ch1_position_s01_middle',
      'candidate_ch1_position_s01_far',
      'candidate_ch1_position_s02_gate',
      'candidate_ch1_position_s02_roof',
      'candidate_ch1_position_s02_yard',
      'candidate_ch1_position_s03_front',
      'candidate_ch1_position_s03_rear',
      'candidate_ch1_position_s03_upper',
      'candidate_ch1_position_s04_guard_arc',
      'candidate_ch1_position_s04_commander_center',
      'candidate_ch1_position_s05_guard_arc',
      'candidate_ch1_position_s05_commander_center',
    },
    behaviorIds: const {
      'candidate_ch1_behavior_blade_press',
      'candidate_ch1_behavior_crossbow_offset',
      'candidate_ch1_behavior_rope_flank',
      'candidate_ch1_behavior_gong_command',
    },
    attackSetIds: const {
      'candidate_ch1_attack_set_blade',
      'candidate_ch1_attack_set_crossbow',
      'candidate_ch1_attack_set_rope_raider',
      'candidate_ch1_attack_set_gong_leader',
    },
    attackTagIds: const {
      'candidate_ch1_attack_tag_melee',
      'candidate_ch1_attack_tag_projectile',
      'candidate_ch1_attack_tag_charge',
      'candidate_ch1_attack_tag_support',
    },
    postureProfileIds: const {
      'candidate_ch1_posture_blade',
      'candidate_ch1_posture_crossbow',
      'candidate_ch1_posture_rope_raider',
      'candidate_ch1_posture_gong_leader',
    },
    dropGroupIds: const {'candidate_ch1_drop_group_bandit_encounter'},
    sfxGroupIds: const {
      'candidate_ch1_sfx_blade',
      'candidate_ch1_sfx_crossbow',
      'candidate_ch1_sfx_rope_raider',
      'candidate_ch1_sfx_gong_leader',
    },
    visualVariantIds: const {
      'candidate_ch1_visual_blade_a',
      'candidate_ch1_visual_blade_b',
      'candidate_ch1_visual_crossbow_a',
      'candidate_ch1_visual_crossbow_b',
      'candidate_ch1_visual_rope_raider_a',
      'candidate_ch1_visual_rope_raider_b',
      'candidate_ch1_visual_gong_leader_a',
      'candidate_ch1_visual_gong_leader_b',
    },
    objectiveTargetIds: const {
      'candidate_ch1_s01_blade_01',
      'candidate_ch1_s01_blade_02',
      'candidate_ch1_s01_blade_03',
      'candidate_ch1_s01_blade_04',
      'candidate_ch1_s01_blade_05',
      'candidate_ch1_s01_blade_06',
      'candidate_ch1_s01_blade_07',
      'candidate_ch1_s01_blade_08',
      'candidate_ch1_s01_blade_09',
      'candidate_ch1_s01_blade_10',
      'candidate_ch1_s01_blade_11',
      'candidate_ch1_s01_blade_12',
      'candidate_ch1_s01_blade_13',
      'candidate_ch1_s01_blade_14',
      'candidate_ch1_s01_crossbow_01',
      'candidate_ch1_s01_crossbow_02',
      'candidate_ch1_s01_crossbow_03',
      'candidate_ch1_s01_crossbow_04',
      'candidate_ch1_s01_crossbow_05',
      'candidate_ch1_s01_crossbow_06',
      'candidate_ch1_s01_rope_01',
      'candidate_ch1_s01_rope_02',
      'candidate_ch1_s01_rope_03',
      'candidate_ch1_s01_rope_04',
      'candidate_ch1_s01_rope_05',
      'candidate_ch1_s02_leader_01',
      'candidate_ch1_s03_blade_01',
      'candidate_ch1_s03_blade_02',
      'candidate_ch1_s03_blade_03',
      'candidate_ch1_s03_blade_04',
      'candidate_ch1_s03_blade_05',
      'candidate_ch1_s03_blade_06',
      'candidate_ch1_s03_blade_07',
      'candidate_ch1_s03_blade_08',
      'candidate_ch1_s03_blade_09',
      'candidate_ch1_s03_blade_10',
      'candidate_ch1_s03_blade_11',
      'candidate_ch1_s03_blade_12',
      'candidate_ch1_s03_blade_13',
      'candidate_ch1_s03_blade_14',
      'candidate_ch1_s03_blade_15',
      'candidate_ch1_s03_blade_16',
      'candidate_ch1_s03_blade_17',
      'candidate_ch1_s03_blade_18',
      'candidate_ch1_s03_crossbow_01',
      'candidate_ch1_s03_crossbow_02',
      'candidate_ch1_s03_crossbow_03',
      'candidate_ch1_s03_crossbow_04',
      'candidate_ch1_s03_crossbow_05',
      'candidate_ch1_s03_crossbow_06',
      'candidate_ch1_s03_crossbow_07',
      'candidate_ch1_s03_crossbow_08',
      'candidate_ch1_s03_crossbow_09',
      'candidate_ch1_s03_crossbow_10',
      'candidate_ch1_s03_rope_01',
      'candidate_ch1_s03_rope_02',
      'candidate_ch1_s03_rope_03',
      'candidate_ch1_s03_rope_04',
      'candidate_ch1_s03_rope_05',
      'candidate_ch1_s03_rope_06',
      'candidate_ch1_s03_rope_07',
      'candidate_ch1_s03_rope_08',
      'candidate_ch1_s03_rope_09',
      'candidate_ch1_s03_rope_10',
      'candidate_ch1_s03_leader_01',
      'candidate_ch1_s03_leader_02',
      'candidate_ch1_s04_leader_01',
      'candidate_ch1_s04_blade_01',
      'candidate_ch1_s04_rope_01',
      'candidate_ch1_s05_leader_01',
    },
    objectiveAnchorIds: const {
      'candidate_ch1_s02_anchor_gate',
      'candidate_ch1_s02_anchor_gong_rack',
    },
    objectiveEntityIds: const {},
    objectiveCheckpointIds: const {'candidate_ch1_s01_checkpoint_exit'},
    objectiveMarkerIds: const {},
  );
}

Future<CombatCatalogManifestDef> _loadCandidateCatalog() async {
  return loadCombatCatalogManifest(
    archetypeSources: [await _candidateSource('archetypes/bandits.yaml')],
    encounterSources: [await _candidateSource('encounters/chapter_01.yaml')],
    manifestSource: await _candidateSource('manifest/stage_assignments.yaml'),
    referenceIndex: _candidateReferenceIndex(),
  );
}

void _enforceCanonicalBanditRoles(Iterable<String> roleIds) {
  final actual = roleIds.toSet();
  if (actual.length != roleIds.length ||
      !actual.containsAll(canonicalBanditRoleIds) ||
      !canonicalBanditRoleIds.containsAll(actual)) {
    throw StateError('candidate canonical bandit role ids drifted: $actual');
  }
}

void _enforceStage0103CandidateBounds({
  required int totalEnemies,
  required int activeLimit,
}) {
  if (totalEnemies < 35 || totalEnemies > 45) {
    throw StateError(
      'candidate stage_01_03 totalEnemies must stay in [35, 45]',
    );
  }
  if (activeLimit < 8 || activeLimit > 16) {
    throw StateError('candidate stage_01_03 activeLimit must stay in [8, 16]');
  }
}

int _totalTokenBudget(CombatEncounterDef encounter) {
  final budget = encounter.tokenBudgets;
  return budget.melee + budget.ranged + budget.charge + budget.support;
}

Set<String> _usedEntranceIds(CombatCatalogManifestDef manifest) => manifest
    .encounters
    .expand((encounter) => encounter.spawnEntries)
    .map((entry) => entry.entranceId)
    .toSet();

Set<String> _usedPositionIds(CombatCatalogManifestDef manifest) => manifest
    .encounters
    .expand((encounter) => encounter.spawnEntries)
    .map((entry) => entry.positionId)
    .toSet();

Set<String> _usedBehaviorIds(CombatCatalogManifestDef manifest) => manifest
    .encounters
    .expand((encounter) => encounter.spawnEntries)
    .map((entry) => entry.behaviorId)
    .toSet();

Set<String> _usedObjectiveTargetIds(CombatCatalogManifestDef manifest) {
  final ids = <String>{};
  for (final clause in manifest.encounters.expand(
    (encounter) => encounter.objectives.clauses,
  )) {
    final primitive = clause.primitive;
    if (primitive is CombatDefeatTargetsRef) {
      ids.addAll(primitive.targetIds);
    } else if (primitive is CombatPursueTargetRef) {
      ids.add(primitive.targetId);
    } else if (primitive is CombatDefeatCommanderRef) {
      ids.add(primitive.commanderId);
    }
  }
  return ids;
}

Set<String> _usedObjectiveAnchorIds(CombatCatalogManifestDef manifest) {
  return manifest.encounters
      .expand((encounter) => encounter.objectives.clauses)
      .map((clause) => clause.primitive)
      .whereType<CombatDestroyAnchorsRef>()
      .expand((primitive) => primitive.anchorIds)
      .toSet();
}

Set<String> _usedObjectiveEntityIds(CombatCatalogManifestDef manifest) {
  return manifest.encounters
      .expand((encounter) => encounter.objectives.clauses)
      .map((clause) => clause.primitive)
      .whereType<CombatDefendEntityRef>()
      .map((primitive) => primitive.entityId)
      .toSet();
}

Set<String> _usedObjectiveCheckpointIds(CombatCatalogManifestDef manifest) {
  return manifest.encounters
      .expand((encounter) => encounter.objectives.clauses)
      .map((clause) => clause.primitive)
      .whereType<CombatReachCheckpointRef>()
      .expand((primitive) => primitive.checkpointIds)
      .toSet();
}

Set<String> _usedObjectiveMarkerIds(CombatCatalogManifestDef manifest) {
  return manifest.encounters
      .expand((encounter) => encounter.objectives.clauses)
      .map((clause) => clause.primitive)
      .whereType<CombatTouchMarkersRef>()
      .expand((primitive) => primitive.markerIds)
      .toSet();
}

void main() {
  group('Ch1 candidate-only non-production combat catalog', () {
    test(
      'candidate-only non-production loads 4 roles 5 encounters 5 assignments and maps objectives',
      () async {
        final manifest = await _loadCandidateCatalog();

        expect(manifest.archetypes, hasLength(1));
        expect(manifest.archetypes.single.variants, hasLength(4));
        expect(manifest.encounters, hasLength(5));
        expect(manifest.stageAssignments, hasLength(5));
        expect(
          manifest.stageAssignments.map((assignment) => assignment.stageId),
          const [
            'stage_01_01',
            'stage_01_02',
            'stage_01_03',
            'stage_01_04',
            'stage_01_05',
          ],
        );

        for (final encounter in manifest.encounters) {
          final controller = mapCombatObjectiveComposition(
            encounter.objectives,
            tickDuration: const Duration(milliseconds: 50),
          );
          expect(controller.clauses, isNotEmpty);
          expect(
            controller.completionRule,
            anyOf(ObjectiveCompletionRule.all, ObjectiveCompletionRule.any),
          );
        }
      },
    );

    test(
      'candidate-only non-production keeps the four canonical bandit role ids exact',
      () async {
        final manifest = await _loadCandidateCatalog();
        final roleIds = manifest.archetypes.single.variants
            .map((variant) => variant.roleId)
            .toList(growable: false);

        _enforceCanonicalBanditRoles(roleIds);
        expect(roleIds.toSet(), canonicalBanditRoleIds);
      },
    );

    test(
      'candidate-only non-production preserves roadbreak stronghold ambush commander commander order',
      () async {
        final manifest = await _loadCandidateCatalog();
        final encounters = [
          for (final stageId in const [
            'stage_01_01',
            'stage_01_02',
            'stage_01_03',
            'stage_01_04',
            'stage_01_05',
          ])
            manifest.encounterForStage(stageId)!,
        ];

        expect(
          encounters[0].objectives.completionRule,
          CombatObjectiveCompletionRule.all,
        );
        expect(encounters[0].objectives.clauses.map((c) => c.primitive), [
          isA<CombatDefeatTargetsRef>(),
          isA<CombatReachCheckpointRef>(),
        ]);
        expect(
          encounters[1].objectives.completionRule,
          CombatObjectiveCompletionRule.any,
        );
        expect(encounters[1].objectives.clauses.map((c) => c.primitive), [
          isA<CombatDestroyAnchorsRef>(),
          isA<CombatDefeatCommanderRef>(),
        ]);
        expect(encounters[2].objectives.clauses.map((c) => c.primitive), [
          isA<CombatDefeatTargetsRef>(),
        ]);
        for (final index in const [3, 4]) {
          expect(
            encounters[index].objectives.clauses.first.primitive,
            isA<CombatDefeatCommanderRef>(),
          );
        }
      },
    );

    test(
      'candidate-only non-production stage_01_03 stays at 40 total 12 active with conservative 2-4 total tokens',
      () async {
        final manifest = await _loadCandidateCatalog();
        final encounter = manifest.encounterForStage('stage_01_03')!;

        _enforceStage0103CandidateBounds(
          totalEnemies: encounter.spawnEntries.length,
          activeLimit: encounter.spawnConfig.activeLimit,
        );
        expect(encounter.spawnEntries, hasLength(40));
        expect(encounter.spawnConfig.activeLimit, 12);
        expect(_totalTokenBudget(encounter), inInclusiveRange(2, 4));
        expect([
          encounter.tokenBudgets.melee,
          encounter.tokenBudgets.ranged,
          encounter.tokenBudgets.charge,
          encounter.tokenBudgets.support,
        ], everyElement(inInclusiveRange(0, 4)));
      },
    );

    test(
      'candidate-only non-production keeps every encounter token total in 2-4 without freezing balance',
      () async {
        final manifest = await _loadCandidateCatalog();
        for (final encounter in manifest.encounters) {
          expect(
            _totalTokenBudget(encounter),
            inInclusiveRange(2, 4),
            reason: '${encounter.id} is an unfrozen candidate only',
          );
        }
      },
    );

    test(
      'candidate-only non-production explicit reference index exactly closes all fourteen namespaces',
      () async {
        final manifest = await _loadCandidateCatalog();
        final index = manifest.referenceIndex;
        final variants = manifest.archetypes.expand((a) => a.variants);

        expect(_usedEntranceIds(manifest), index.entranceIds);
        expect(_usedPositionIds(manifest), index.positionIds);
        expect(_usedBehaviorIds(manifest), index.behaviorIds);
        expect(variants.map((v) => v.attackSetId).toSet(), index.attackSetIds);
        expect(
          variants.expand((v) => v.attackTagIds).toSet(),
          index.attackTagIds,
        );
        expect(
          variants.map((v) => v.postureProfileId).toSet(),
          index.postureProfileIds,
        );
        expect(variants.map((v) => v.dropGroupId).toSet(), index.dropGroupIds);
        expect(variants.map((v) => v.sfxGroupId).toSet(), index.sfxGroupIds);
        expect(
          variants.expand((v) => v.visualVariantIds).toSet(),
          index.visualVariantIds,
        );
        expect(_usedObjectiveTargetIds(manifest), index.objectiveTargetIds);
        expect(_usedObjectiveAnchorIds(manifest), index.objectiveAnchorIds);
        expect(_usedObjectiveEntityIds(manifest), index.objectiveEntityIds);
        expect(
          _usedObjectiveCheckpointIds(manifest),
          index.objectiveCheckpointIds,
        );
        expect(_usedObjectiveMarkerIds(manifest), index.objectiveMarkerIds);

        final spawnEntryIds = manifest.encounters
            .expand((encounter) => encounter.spawnEntries)
            .map((entry) => entry.entryId)
            .toSet();
        expect(
          spawnEntryIds.containsAll(_usedObjectiveTargetIds(manifest)),
          isTrue,
          reason:
              'this candidate fixture uses only spawned units as objective targets',
        );
      },
    );

    test(
      'candidate-only non-production negative guard rejects stage_01_03 quantity and active-limit drift',
      () {
        expect(
          () => _enforceStage0103CandidateBounds(
            totalEnemies: 34,
            activeLimit: 12,
          ),
          throwsStateError,
        );
        expect(
          () => _enforceStage0103CandidateBounds(
            totalEnemies: 46,
            activeLimit: 12,
          ),
          throwsStateError,
        );
        expect(
          () => _enforceStage0103CandidateBounds(
            totalEnemies: 40,
            activeLimit: 7,
          ),
          throwsStateError,
        );
        expect(
          () => _enforceStage0103CandidateBounds(
            totalEnemies: 40,
            activeLimit: 17,
          ),
          throwsStateError,
        );
      },
    );

    test(
      'candidate-only non-production negative guard rejects canonical role id drift',
      () {
        expect(
          () => _enforceCanonicalBanditRoles(const [
            'bandit_blade',
            'bandit_crossbow',
            'bandit_rope_raider',
            'bandit_leader_drifted',
          ]),
          throwsStateError,
        );
        expect(
          () => _enforceCanonicalBanditRoles(const [
            ...canonicalBanditRoleIds,
            'bandit_extra',
          ]),
          throwsStateError,
        );
      },
    );

    test(
      'candidate-only non-production fixture headers and path cannot masquerade as production data',
      () async {
        expect(candidateFixtureRoot, startsWith('test/fixtures/'));
        expect(candidateFixtureRoot, isNot(startsWith('data/')));
        expect(
          await File('pubspec.yaml').readAsString(),
          isNot(contains(candidateFixtureRoot)),
        );

        final fixtureFiles = await Directory(candidateFixtureRoot)
            .list(recursive: true)
            .where((entity) => entity is File && entity.path.endsWith('.yaml'))
            .cast<File>()
            .toList();
        expect(fixtureFiles, hasLength(3));
        for (final file in fixtureFiles) {
          final content = await file.readAsString();
          expect(content, startsWith('# $candidateOnlyMarker'));
          expect(content, contains('not frozen'));
        }

        final productionFiles = await Directory('data')
            .list(recursive: true)
            .where(
              (entity) =>
                  entity is File &&
                  (entity.path.endsWith('.yaml') ||
                      entity.path.endsWith('.yml') ||
                      entity.path.endsWith('.json')),
            )
            .cast<File>()
            .toList();
        for (final file in productionFiles) {
          final content = await file.readAsString();
          expect(content, isNot(contains(candidateIdMarker)));
          expect(content, isNot(contains(candidateOnlyMarker)));
        }
      },
    );
  });
}
