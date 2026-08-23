// CANDIDATE-ONLY NON-PRODUCTION TEST CONTRACT.
// This matrix proves construction only; it never advances a combat tick and
// does not validate objective execution, balance, performance or host wiring.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/combat_encounter_catalog_loader.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_stage_encounter_route_selector.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_migration_resolver.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_explicit_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_migrated_encounter_plan_builder.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';

import '../../support/combatant_snapshot_fixture.dart';
import '../../support/test_data.dart';

const _candidateFixtureRoot = 'test/fixtures/phase2/combat/ch1_candidate';
const _playerId = 'v01_player';
const _stageIds = [
  'stage_01_01',
  'stage_01_02',
  'stage_01_03',
  'stage_01_04',
  'stage_01_05',
];

const _playerAdapter = Phase0aPlayerInputAdapter(
  playerId: _playerId,
  attackRange: 20,
  attackHalfArcRadians: math.pi / 4,
  attackCooldownSeconds: 0.5,
  attackQiDelta: 0,
  gatherSlot: 'v01_gather',
  gatherRingRadius: 10,
  gatherEffectRadius: 20,
  gatherQiCost: 20,
  gatherCooldownSeconds: 3,
  clearSlot: 'v01_clear',
  clearEffectRadius: 20,
  clearQiCost: 30,
  clearCooldownSeconds: 4,
);

const _enemyAdapter = Phase0aEnemyAiAdapter(
  attackRange: 70,
  attackHalfArcRadians: math.pi / 3,
  attackCooldownSeconds: 0.5,
);

Future<CombatCatalogYamlSource> _candidateSource(String relativePath) async {
  final path = '$_candidateFixtureRoot/$relativePath';
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

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required double x,
}) {
  return Phase0aActor(
    id: id,
    side: side,
    position: ArenaVector(x, 0),
    facing: side == Phase0aSide.player
        ? const ArenaVector(1, 0)
        : const ArenaVector(-1, 0),
    maxHealth: 1000,
    currentHealth: 1000,
    moveSpeed: 100,
    qiCurrent: 100,
    qiMax: 100,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  );
}

Phase0aMigratedEncounterPlan _buildPlan(
  MigratedCombatStageEncounterRoute route, {
  required int stageIndex,
}) {
  final runtimeIdsByEntry = <CombatEncounterSpawnEntry, String>{};
  for (var index = 0; index < route.encounter.spawnEntries.length; index++) {
    runtimeIdsByEntry[route.encounter.spawnEntries[index]] =
        'v01_runtime_${stageIndex}_$index';
  }
  final runtimeIds = runtimeIdsByEntry.values.toList(growable: false);

  return buildPhase0aMigratedEncounterPlan(
    route,
    tickDuration: const Duration(milliseconds: 50),
    resolveEnemyId: (entry) => runtimeIdsByEntry[entry]!,
    playerId: _playerId,
    createActor: (_, enemyId) =>
        _actor(id: enemyId, side: Phase0aSide.enemy, x: 1),
    initialState: Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: _actor(id: _playerId, side: Phase0aSide.player, x: 0),
      enemies: const [],
      skillSlots: const [],
    ),
    combatants: [
      Phase0aCombatantInput(
        actorId: _playerId,
        snapshot: testCombatantSnapshot(characterId: stageIndex * 100 + 1),
      ),
      for (var index = 0; index < runtimeIds.length; index++)
        Phase0aCombatantInput(
          actorId: runtimeIds[index],
          snapshot: testCombatantSnapshot(
            characterId: stageIndex * 100 + index + 2,
          ),
        ),
    ],
    moveBindings: const {
      Phase0aDamageKind.basic: null,
      Phase0aDamageKind.gather: null,
      Phase0aDamageKind.clear: null,
    },
    playerAdapter: _playerAdapter,
    enemyAiAdapter: _enemyAdapter,
  );
}

Map<String, Iterable<Phase0aDefeatObjectiveProjection>>
_explicitEmptyDefeatProjections(Phase0aMigratedEncounterPlan plan) {
  return <String, Iterable<Phase0aDefeatObjectiveProjection>>{
    for (final binding in plan.roster.bindings)
      binding.actorId: const <Phase0aDefeatObjectiveProjection>[],
  };
}

Future<void> _expectCandidateStageConstructs(int stageIndex) async {
  final manifest = await _loadCandidateCatalog();
  final resolver = Phase0aEncounterMigrationResolver(
    legacyContentIds: const [],
  );
  final stageId = _stageIds[stageIndex];
  final expectedEncounter = manifest.encounterForStage(stageId)!;

  expect(manifest.encounters, hasLength(5));
  expect(manifest.stageAssignments, hasLength(5));

  final selected = selectCombatStageEncounterRoute(
    manifest: manifest,
    stageId: stageId,
    migrationResolver: resolver,
    hasLegacyContent: false,
  );

  expect(selected, isA<MigratedCombatStageEncounterRoute>());
  final route = selected as MigratedCombatStageEncounterRoute;
  expect(route.stageId, stageId);
  expect(route.encounter, same(expectedEncounter));

  final plan = _buildPlan(route, stageIndex: stageIndex);
  final rosterActorIds = {
    for (final binding in plan.roster.bindings) binding.actorId,
  };
  final projections = _explicitEmptyDefeatProjections(plan);

  expect(projections.keys.toSet(), rosterActorIds);
  expect(projections.values, everyElement(isEmpty));

  final objectiveSource = Phase0aExplicitObjectiveEventSource(
    roster: plan.roster,
    defeatProjectionsByActorId: projections,
    externalProjectors: const [],
  );
  final seed = 1501 + stageIndex;
  final rng = math.Random(seed);
  final untouchedRng = math.Random(seed);
  var tokenMapperCalls = 0;
  final flow = Phase0aProductionFlowAssembler.assembleMigratedEncounterPlan(
    plan: plan,
    numbers: GameRepository.instance.numbers,
    rng: rng,
    tokenRequestMapper: (_) {
      tokenMapperCalls += 1;
      return null;
    },
    objectiveEventSource: objectiveSource,
  );

  expect(plan.stageId, stageId);
  expect(plan.encounter, same(expectedEncounter));
  expect(plan.mapping.director, same(plan.runtimeContracts.spawnDirector));
  expect(plan.roster.director, same(plan.runtimeContracts.spawnDirector));
  expect(plan.roster.size, expectedEncounter.spawnEntries.length);
  expect(flow.state.tick, 0);
  expect(flow.state.enemies, isEmpty);
  expect(flow.spawnState.tick, 0);
  expect(flow.outcome, Phase0aBattleOutcome.ongoing);
  expect(flow.lastOrderedEventRecords, isEmpty);
  expect(tokenMapperCalls, 0);
  expect(rng.nextDouble(), untouchedRng.nextDouble());
}

void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  for (var index = 0; index < _stageIds.length; index++) {
    final stageIndex = index;
    final stageId = _stageIds[stageIndex];
    test(
      '$stageId constructs through the typed migrated seam without a tick',
      () => _expectCandidateStageConstructs(stageIndex),
    );
  }

  test(
    'R13 source keeps missing and extra roster coverage fail closed',
    () async {
      final manifest = await _loadCandidateCatalog();
      final selected = selectCombatStageEncounterRoute(
        manifest: manifest,
        stageId: _stageIds.first,
        migrationResolver: Phase0aEncounterMigrationResolver(
          legacyContentIds: const [],
        ),
        hasLegacyContent: false,
      );
      final plan = _buildPlan(
        selected as MigratedCombatStageEncounterRoute,
        stageIndex: 0,
      );
      final exact = _explicitEmptyDefeatProjections(plan);
      final missing =
          Map<String, Iterable<Phase0aDefeatObjectiveProjection>>.of(exact)
            ..remove(plan.roster.bindings.first.actorId);
      final extra = Map<String, Iterable<Phase0aDefeatObjectiveProjection>>.of(
        exact,
      )..['v01_foreign_actor'] = const <Phase0aDefeatObjectiveProjection>[];

      expect(
        () => Phase0aExplicitObjectiveEventSource(
          roster: plan.roster,
          defeatProjectionsByActorId: missing,
          externalProjectors: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => Phase0aExplicitObjectiveEventSource(
          roster: plan.roster,
          defeatProjectionsByActorId: extra,
          externalProjectors: const [],
        ),
        throwsArgumentError,
      );
    },
  );

  test('matrix source cannot infer objective identity or execute runtime', () {
    final source = File(
      'test/data/phase2/ch1_candidate_runtime_construction_matrix_test.dart',
    ).readAsStringSync();
    final forbidden = <String>[
      '.adv'
          'ance(',
      '.events'
          'For(',
      '.role'
          'Id',
      '.defeat'
          'Kind',
      '.starts'
          'With(',
      '.sub'
          'string(',
      '.replace'
          'All(',
      'Phase0aTargetDefeatProjec'
          'tion(',
      'Phase0aCommanderDefeatProjec'
          'tion(',
    ];

    for (final token in forbidden) {
      expect(source, isNot(contains(token)), reason: token);
    }
  });
}
