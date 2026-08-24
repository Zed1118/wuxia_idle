// CANDIDATE-ONLY NON-PRODUCTION TEST CONTRACT.
// This matrix composes only one idle, drop-all, no-mutation runtime tick. It
// does not execute defeat objectives or validate gameplay policy.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/combat_encounter_catalog_loader.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_manifest_def.dart';
import 'package:wuxia_idle/data/defs/combat_catalog_reference_index.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_encounter_defeat_projection_mapper.dart';
import 'package:wuxia_idle/data/validation/combat_stage_encounter_route_selector.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_attack_token_lease_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_migration_resolver.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_migrated_encounter_plan_builder.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_lease_runtime.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';

import '../../support/ch1_candidate_defeat_projection_declarations.dart';
import '../../support/combatant_snapshot_fixture.dart';
import '../../support/test_data.dart';

const _candidateFixtureRoot = 'test/fixtures/phase2/combat/ch1_candidate';
const _playerId = 'v02b_player';
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
  gatherSlot: 'v02b_gather',
  gatherRingRadius: 10,
  gatherEffectRadius: 20,
  gatherQiCost: 20,
  gatherCooldownSeconds: 3,
  clearSlot: 'v02b_clear',
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
}) => Phase0aActor(
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

Phase0aMigratedEncounterPlan _buildPlan(
  MigratedCombatStageEncounterRoute route, {
  required int stageIndex,
}) {
  final runtimeIdsByEntry = <CombatEncounterSpawnEntry, String>{};
  for (var index = 0; index < route.encounter.spawnEntries.length; index++) {
    runtimeIdsByEntry[route.encounter.spawnEntries[index]] =
        'v02b_runtime_stage_${stageIndex + 1}_enemy_${index + 1}';
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
  final route = selectCombatStageEncounterRoute(
    manifest: manifest,
    stageId: stageId,
    migrationResolver: Phase0aEncounterMigrationResolver(
      legacyContentIds: const [],
    ),
    hasLegacyContent: false,
  );
  expect(route, isA<MigratedCombatStageEncounterRoute>());
  return _buildPlan(
    route as MigratedCombatStageEncounterRoute,
    stageIndex: stageIndex,
  );
}

final class _DropAllLeasePlanner {
  var calls = 0;
  var fail = false;

  Phase0aAttackTokenLeaseBatchPlan call({
    required AttackTokenLeaseSnapshot leaseSnapshot,
    required List<Phase0aIntent> enemyIntents,
  }) {
    calls++;
    if (fail) throw StateError('candidate planner failed');
    return Phase0aAttackTokenLeaseBatchPlan(
      enemyIntents: const <Phase0aIntent>[],
      mutations: const <AttackTokenLeaseMutation>[],
    );
  }
}

typedef _CandidateFlow = ({
  Phase0aEncounterFlow flow,
  AttackTokenLeaseRuntime leaseRuntime,
  _DropAllLeasePlanner planner,
});

_CandidateFlow _assembleCandidateFlow(
  Phase0aMigratedEncounterPlan plan, {
  required int seed,
}) {
  final source = mapCombatEncounterDefeatObjectiveEventSource(
    plan.encounter,
    plan.roster,
    defeatProjectionEntries:
        ch1CandidateDefeatProjectionEntriesByStageId[plan.stageId]!,
  );
  final planner = _DropAllLeasePlanner();
  final leaseRuntime = AttackTokenLeaseRuntime.empty();
  final flow =
      Phase0aProductionFlowAssembler.assembleMigratedEncounterPlanWithAttackTokenLease(
        plan: plan,
        numbers: GameRepository.instance.numbers,
        rng: math.Random(seed),
        attackTokenLeaseBatchGate: Phase0aExplicitAttackTokenLeaseBatchGate(
          planner: planner.call,
        ),
        attackTokenLeaseRuntime: leaseRuntime,
        objectiveEventSource: source,
      );
  return (flow: flow, leaseRuntime: leaseRuntime, planner: planner);
}

void _advanceOneIdleTick(Phase0aEncounterFlow flow) {
  flow.advance(deltaSeconds: 0.05, command: const Phase0aPlayerCommand());
}

void _expectStageComposition(
  CombatCatalogManifestDef manifest,
  String stageId,
) {
  final stageIndex = _stageIds.indexOf(stageId);
  final plan = _planForStage(manifest, stageId);
  final first = _assembleCandidateFlow(plan, seed: 2601 + stageIndex);
  final sibling = _assembleCandidateFlow(plan, seed: 2701 + stageIndex);
  final initialProgress = first.flow.objectiveProgress;
  final siblingProgress = sibling.flow.objectiveProgress;
  final predecessorSnapshot = first.leaseRuntime.snapshot;

  expect(initialProgress, isNotNull);
  expect(siblingProgress, isNotNull);
  expect(siblingProgress, isNot(same(initialProgress)));
  expect(first.flow.lastAttackTokenLeaseBatchReceipt, isNull);
  expect(sibling.flow.lastAttackTokenLeaseBatchReceipt, isNull);
  expect(initialProgress!.completed, isFalse);
  expect(
    initialProgress.clauses.map((clause) => clause.completed),
    everyElement(isFalse),
  );

  _advanceOneIdleTick(first.flow);

  final receipt = first.flow.lastAttackTokenLeaseBatchReceipt;
  expect(first.planner.calls, 1);
  expect(receipt, isNotNull);
  expect(receipt!.mutations, isEmpty);
  expect(receipt.before, same(predecessorSnapshot));
  expect(receipt.after, same(predecessorSnapshot));
  expect(first.flow.objectiveProgress, same(initialProgress));
  expect(first.flow.objectiveProgress!.completed, isFalse);
  expect(
    first.flow.objectiveProgress!.clauses.map((clause) => clause.completed),
    everyElement(isFalse),
  );
  expect(first.flow.outcome, Phase0aBattleOutcome.ongoing);
  expect(sibling.flow.objectiveProgress, same(siblingProgress));
  expect(sibling.flow.lastAttackTokenLeaseBatchReceipt, isNull);
  expect(sibling.planner.calls, 0);
}

void main() {
  late CombatCatalogManifestDef manifest;

  setUpAll(() async {
    manifest = await _loadCandidateCatalog();
  });
  setUp(() async {
    await loadTestGameRepository();
  });
  tearDown(GameRepository.resetForTest);

  for (final stageId in _stageIds) {
    test(
      '$stageId composes one idle transactional observation tick',
      () => _expectStageComposition(manifest, stageId),
    );
  }

  test('planner failure preserves exact candidate flow observations', () {
    final plan = _planForStage(manifest, 'stage_01_04');
    final built = _assembleCandidateFlow(plan, seed: 2801);
    _advanceOneIdleTick(built.flow);

    final state = built.flow.state;
    final spawn = built.flow.spawnState;
    final outcome = built.flow.outcome;
    final records = built.flow.lastOrderedEventRecords;
    final progress = built.flow.objectiveProgress;
    final receipt = built.flow.lastAttackTokenLeaseBatchReceipt;
    built.planner.fail = true;

    expect(() => _advanceOneIdleTick(built.flow), throwsStateError);

    expect(built.flow.state, same(state));
    final currentSpawn = built.flow.spawnState;
    expect(currentSpawn.tick, spawn.tick);
    expect(currentSpawn.totalCount, spawn.totalCount);
    expect(currentSpawn.activeCount, spawn.activeCount);
    expect(currentSpawn.warningCount, spawn.warningCount);
    expect(currentSpawn.pendingCount, spawn.pendingCount);
    expect(currentSpawn.removedCount, spawn.removedCount);
    expect(currentSpawn.units, spawn.units);
    expect(built.flow.outcome, same(outcome));
    expect(built.flow.lastOrderedEventRecords, same(records));
    expect(built.flow.objectiveProgress, same(progress));
    expect(built.flow.lastAttackTokenLeaseBatchReceipt, same(receipt));
    expect(built.planner.calls, 2);
  });

  test('source guard keeps the candidate composition structural', () {
    final source = File(
      'test/data/phase2/'
      'ch1_candidate_observable_transactional_composition_matrix_test.dart',
    ).readAsStringSync();

    expect(RegExp(r'\.advance\(').allMatches(source), hasLength(1));
    expect(source, contains('ch1CandidateDefeatProjectionEntriesByStageId'));
    for (final forbidden in [
      'Phase0aEnemyDefeated'
          '(',
      'Phase0aTargetDefeatProjec'
          'tion(',
      'Phase0aCommanderDefeatProjec'
          'tion(',
      'Checkpoint'
          'Reached(',
      'Anchor'
          'Destroyed(',
      'Acquire'
          'AttackTokenLease(',
      'Release'
          'AttackTokenLease(',
      'Action'
          'Timeline',
      '.writeAs'
          'String(',
      '.writeAs'
          'StringSync(',
      'FileMode.'
          'write',
      'root'
          'Bundle',
      'data/stages'
          '.yaml',
      'data/numbers'
          '.yaml',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
