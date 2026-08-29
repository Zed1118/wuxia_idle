// CANDIDATE-ONLY NON-PRODUCTION TEST CONTRACT.
// This matrix executes only frozen Target/Commander defeat-objective seams. It
// does not promote fixtures, advance combat flow, or invent checkpoint/anchor
// events. Every declaration below is explicit caller policy.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/combat_encounter_catalog_loader.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/validation/combat_encounter_defeat_projection_mapper.dart';
import 'package:wuxia_idle/data/validation/combat_stage_encounter_route_selector.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_migration_resolver.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_explicit_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_migrated_encounter_plan_builder.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_objective_runtime_tracker.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';

import '../../support/ch1_candidate_defeat_projection_declarations.dart';
import '../../support/combatant_snapshot_fixture.dart';

const _candidateFixtureRoot = 'test/fixtures/phase2/combat/ch1_candidate';
const _playerId = 'v02a_player';
const _stageIds = [
  'stage_01_01',
  'stage_01_02',
  'stage_01_03',
  'stage_01_04',
  'stage_01_05',
];

typedef _Declaration =
    MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>;

enum _ExpectedEventKind { target, commander }

typedef _ExpectedEvent = ({_ExpectedEventKind kind, String payload});

// BEGIN INDEPENDENT EXPECTED EVENTS.
const _expectedEventsByStageId = <String, List<_ExpectedEvent>>{
  'stage_01_01': [
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_01'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_02'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_03'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_04'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_05'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_06'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_07'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_08'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_09'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_10'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_11'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_12'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_13'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_blade_14'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_crossbow_01'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_crossbow_02'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_crossbow_03'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_crossbow_04'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_crossbow_05'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_crossbow_06'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_rope_01'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_rope_02'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_rope_03'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_rope_04'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s01_rope_05'),
  ],
  'stage_01_02': [
    (
      kind: _ExpectedEventKind.commander,
      payload: 'candidate_ch1_s02_leader_01',
    ),
  ],
  'stage_01_03': [
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_01'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_02'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_03'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_04'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_05'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_06'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_07'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_08'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_09'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_10'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_11'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_12'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_13'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_14'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_15'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_16'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_17'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_blade_18'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_01'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_02'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_03'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_04'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_05'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_06'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_07'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_08'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_09'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_crossbow_10'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_01'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_02'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_03'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_04'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_05'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_06'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_07'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_08'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_09'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_rope_10'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_leader_01'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s03_leader_02'),
  ],
  'stage_01_04': [
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s04_blade_01'),
    (kind: _ExpectedEventKind.target, payload: 'candidate_ch1_s04_rope_01'),
    (
      kind: _ExpectedEventKind.commander,
      payload: 'candidate_ch1_s04_leader_01',
    ),
  ],
  'stage_01_05': [
    (
      kind: _ExpectedEventKind.commander,
      payload: 'candidate_ch1_s05_leader_01',
    ),
  ],
};
// END INDEPENDENT EXPECTED EVENTS.

const _expectedClauseCompletion = <String, List<bool>>{
  'stage_01_01': [true, false],
  'stage_01_02': [false, true],
  'stage_01_03': [true],
  'stage_01_04': [true, true],
  'stage_01_05': [true],
};

const _expectedAggregateCompletion = <String, bool>{
  'stage_01_01': false,
  'stage_01_02': true,
  'stage_01_03': true,
  'stage_01_04': true,
  'stage_01_05': true,
};

const _playerAdapter = Phase0aPlayerInputAdapter(
  playerId: _playerId,
  attackRange: 20,
  attackHalfArcRadians: math.pi / 4,
  attackCooldownSeconds: 0.5,
  attackQiDelta: 0,
  postureBasicPowerMultiplier: 1,
  attackPowerMultiplier: 1,
  gatherPowerMultiplier: 1,
  clearPowerMultiplier: 1,
  gatherSlot: 'v02a_gather',
  gatherRingRadius: 10,
  gatherEffectRadius: 20,
  gatherQiCost: 20,
  gatherCooldownSeconds: 3,
  clearSlot: 'v02a_clear',
  clearEffectRadius: 20,
  clearQiCost: 30,
  clearCooldownSeconds: 4,
);

const _enemyAdapter = Phase0aEnemyAiAdapter(
  attackRange: 70,
  attackHalfArcRadians: math.pi / 3,
  attackCooldownSeconds: 0.5,
  postureBasicPowerMultiplier: 1,
  uniformBasicPowerMultiplier: 1,
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
        'v02a_runtime_stage_${stageIndex + 1}_enemy_${index + 1}';
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

Phase0aMigratedEncounterPlan _planForStage(
  CombatCatalogManifestDef manifest,
  String stageId,
) {
  final stageIndex = _stageIds.indexOf(stageId);
  final selected = selectCombatStageEncounterRoute(
    manifest: manifest,
    stageId: stageId,
    migrationResolver: Phase0aEncounterMigrationResolver(
      legacyContentIds: const [],
    ),
    hasLegacyContent: false,
  );
  expect(selected, isA<MigratedCombatStageEncounterRoute>());
  return _buildPlan(
    selected as MigratedCombatStageEncounterRoute,
    stageIndex: stageIndex,
  );
}

Phase0aEncounterObjectiveFrame _defeatFrame(
  Phase0aMigratedEncounterPlan plan, {
  required int stageIndex,
}) {
  final combatEvents = <Phase0aEvent>[];
  for (var index = 0; index < plan.encounter.spawnEntries.length; index++) {
    final contentEntry = plan.encounter.spawnEntries[index];
    final binding = plan.roster.bindingByEntryId(contentEntry.entryId)!;
    combatEvents.add(
      Phase0aEnemyDefeated(
        seq: index + 1,
        tick: stageIndex + 1,
        target: binding.actorId,
        defeatKind: Phase0aDefeatKind.normal,
      ),
    );
  }
  return Phase0aEncounterObjectiveFrame(
    beforeArena: plan.mapping.initialState,
    afterArena: plan.mapping.initialState,
    beforeSpawn: plan.runtimeContracts.spawnDirector.state,
    afterSpawn: plan.runtimeContracts.spawnDirector.state,
    directorEvents: const [],
    spawnEvents: const [],
    combatEvents: combatEvents,
    deltaSeconds: 1,
    playerMovementDelta: ArenaVector.zero,
  );
}

void _expectEventBatch(
  List<EncounterObjectiveEvent> actual,
  List<_ExpectedEvent> expected,
) {
  expect(actual, hasLength(expected.length));
  for (var index = 0; index < expected.length; index++) {
    final event = actual[index];
    final expectedEvent = expected[index];
    switch (expectedEvent.kind) {
      case _ExpectedEventKind.target:
        expect(event, isA<TargetDefeated>(), reason: 'event index $index');
        expect(
          (event as TargetDefeated).targetId,
          expectedEvent.payload,
          reason: 'event index $index',
        );
      case _ExpectedEventKind.commander:
        expect(event, isA<CommanderDefeated>(), reason: 'event index $index');
        expect(
          (event as CommanderDefeated).commanderId,
          expectedEvent.payload,
          reason: 'event index $index',
        );
    }
  }
}

void _expectStageExecution(CombatCatalogManifestDef manifest, String stageId) {
  final stageIndex = _stageIds.indexOf(stageId);
  final plan = _planForStage(manifest, stageId);
  final declarations = ch1CandidateDefeatProjectionEntriesByStageId[stageId]!;
  expect(declarations, hasLength(plan.encounter.spawnEntries.length));
  for (final binding in plan.roster.bindings) {
    expect(binding.actorId, isNot(binding.entryId));
    expect(binding.actorId, startsWith('v02a_runtime_stage_'));
    expect(binding.actorId, isNot(contains('candidate_ch1_')));
  }

  final source = mapCombatEncounterDefeatObjectiveEventSource(
    plan.encounter,
    plan.roster,
    defeatProjectionEntries: declarations,
  );
  final events = source.eventsFor(_defeatFrame(plan, stageIndex: stageIndex));
  _expectEventBatch(events, _expectedEventsByStageId[stageId]!);

  final tracker = Phase0aObjectiveRuntimeTracker(
    controller: plan.runtimeContracts.objectiveController,
  );
  final initial = tracker.progress;
  final prepared = tracker.prepareExternalEvents(events);
  expect(prepared.base, same(initial));
  expect(tracker.progress, same(initial));
  final progress = tracker.commit(prepared);

  expect(
    progress.clauses.map((clause) => clause.completed).toList(),
    _expectedClauseCompletion[stageId],
  );
  expect(progress.completed, _expectedAggregateCompletion[stageId]);
}

void main() {
  late CombatCatalogManifestDef manifest;

  setUpAll(() async {
    manifest = await _loadCandidateCatalog();
  });

  test('hard-coded declaration inventory is exactly 95/67/3/25 and 70', () {
    final declarations = ch1CandidateDefeatProjectionEntriesByStageId.values
        .expand((value) => value);
    var targetCount = 0;
    var commanderCount = 0;
    var emptyCount = 0;
    for (final declaration in declarations) {
      final projections = declaration.value.toList(growable: false);
      if (projections.isEmpty) emptyCount += 1;
      for (final projection in projections) {
        switch (projection) {
          case Phase0aTargetDefeatProjection():
            targetCount += 1;
          case Phase0aCommanderDefeatProjection():
            commanderCount += 1;
        }
      }
    }

    expect(declarations, hasLength(95));
    expect(targetCount, 67);
    expect(commanderCount, 3);
    expect(emptyCount, 25);
    expect(
      _expectedEventsByStageId.values.fold<int>(
        0,
        (count, events) => count + events.length,
      ),
      70,
    );
  });

  for (final stageId in _stageIds) {
    test(
      '$stageId executes only its explicit defeat-objective upper bound',
      () {
        _expectStageExecution(manifest, stageId);
      },
    );
  }

  test(
    'real Ch1 plan rejects missing foreign wrong-kind and duplicate declarations',
    () {
      final plan = _planForStage(manifest, 'stage_01_04');
      final exact =
          ch1CandidateDefeatProjectionEntriesByStageId['stage_01_04']!;
      final missing = List<_Declaration>.of(exact)..removeAt(0);
      final foreign = List<_Declaration>.of(exact)
        ..add(const MapEntry('v02a_foreign_entry', []));
      final wrongKind = List<_Declaration>.of(exact)
        ..[2] = const MapEntry('candidate_ch1_s04_leader_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s04_leader_01'),
        ]);
      final duplicateEntry = List<_Declaration>.of(exact)..add(exact.first);
      final duplicatePayload = List<_Declaration>.of(exact)
        ..[0] = const MapEntry('candidate_ch1_s04_blade_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s04_blade_01'),
          Phase0aTargetDefeatProjection('candidate_ch1_s04_blade_01'),
        ]);

      for (final invalid in [
        missing,
        foreign,
        wrongKind,
        duplicateEntry,
        duplicatePayload,
      ]) {
        expect(
          () => mapCombatEncounterDefeatObjectiveEventSource(
            plan.encounter,
            plan.roster,
            defeatProjectionEntries: invalid,
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test('source guard keeps candidate execution explicit and upper-bounded', () {
    final source = File(
      'test/data/phase2/ch1_candidate_defeat_objective_execution_matrix_test.dart',
    ).readAsStringSync();
    final declarationFileSource = File(
      'test/support/ch1_candidate_defeat_projection_declarations.dart',
    ).readAsStringSync();
    const declarationBeginMarker =
        '// BEGIN EXPLICIT DEFEAT '
        'DECLARATIONS.';
    const declarationEndMarker =
        '// END EXPLICIT DEFEAT '
        'DECLARATIONS.';
    const expectedBeginMarker =
        '// BEGIN INDEPENDENT EXPECTED '
        'EVENTS.';
    const expectedEndMarker =
        '// END INDEPENDENT EXPECTED '
        'EVENTS.';
    final declarationStart = declarationFileSource.indexOf(
      declarationBeginMarker,
    );
    final declarationEnd = declarationFileSource.indexOf(declarationEndMarker);
    final declarationSource = declarationFileSource.substring(
      declarationStart,
      declarationEnd,
    );
    final expectedStart = source.indexOf(expectedBeginMarker);
    final expectedEnd = source.indexOf(expectedEndMarker);
    final expectedSource = source.substring(expectedStart, expectedEnd);

    expect(declarationFileSource.split(declarationBeginMarker).length - 1, 1);
    expect(
      RegExp(r'\bMapEntry\(').allMatches(declarationSource),
      hasLength(95),
    );
    expect(
      RegExp('Phase0aTargetDefeatProjection\\(').allMatches(declarationSource),
      hasLength(67),
    );
    expect(
      RegExp(
        'Phase0aCommanderDefeatProjection\\(',
      ).allMatches(declarationSource),
      hasLength(3),
    );
    expect(source.split(expectedBeginMarker).length - 1, 1);
    expect(
      RegExp('_ExpectedEventKind\\.target').allMatches(expectedSource),
      hasLength(67),
    );
    expect(
      RegExp('_ExpectedEventKind\\.commander').allMatches(expectedSource),
      hasLength(3),
    );
    expect(
      expectedSource,
      isNot(contains('ch1CandidateDefeatProjectionEntriesByStageId')),
    );
    expect(expectedSource, isNot(contains('Phase0aDefeatObjectiveProjection')));

    for (final forbidden in [
      'for (',
      '.m'
          'ap(',
      '.exp'
          'and(',
      '.entry'
          'Id',
      '.actor'
          'Id',
      '.role'
          'Id',
      '.position'
          'Id',
      '.archetype'
          'Id',
      '.behavior'
          'Id',
      'CombatDefeatTargets'
          'Ref',
      'CombatDefeatCommander'
          'Ref',
    ]) {
      expect(declarationSource, isNot(contains(forbidden)), reason: forbidden);
    }
    for (final forbidden in [
      'Phase0aProductionFlow'
          'Assembler',
      '.adv'
          'ance(',
      'Checkpoint'
          'Reached(',
      'Anchor'
          'Destroyed(',
      '.writeAs'
          'String(',
      '.writeAs'
          'StringSync(',
      'FileMode.'
          'write',
      '.copy'
          'Sync(',
      'data/stages'
          '.yaml',
      'data/numbers'
          '.yaml',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
