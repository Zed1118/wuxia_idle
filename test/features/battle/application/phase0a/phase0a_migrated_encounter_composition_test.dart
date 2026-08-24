import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_stage_encounter_route_selector.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/attack_token_enforcing_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_attack_token_lease_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_runtime_observation.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_explicit_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_migrated_encounter_plan_builder.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_objective_runtime_tracker.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_lease_runtime.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

const _basicSkill = SkillDef(
  id: 'batch14_migrated_composition_basic',
  name: 'basic',
  description: 'basic',
  type: SkillType.normalAttack,
  powerMultiplier: 500,
  qiDelta: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
);

const _playerAdapter = Phase0aPlayerInputAdapter(
  playerId: 'player',
  attackRange: 20,
  attackHalfArcRadians: math.pi / 4,
  attackCooldownSeconds: 0.5,
  attackQiDelta: 0,
  gatherSlot: 'gather',
  gatherRingRadius: 10,
  gatherEffectRadius: 20,
  gatherQiCost: 20,
  gatherCooldownSeconds: 3,
  clearSlot: 'clear',
  clearEffectRadius: 20,
  clearQiCost: 30,
  clearCooldownSeconds: 4,
);

const _enemyAdapter = Phase0aEnemyAiAdapter(
  attackRange: 70,
  attackHalfArcRadians: math.pi / 3,
  attackCooldownSeconds: 0.5,
);

final class _RecordingLeaseGate implements Phase0aAttackTokenLeaseBatchGate {
  _RecordingLeaseGate(this.delegate);

  final Phase0aAttackTokenLeaseBatchGate delegate;
  final List<AttackTokenLeaseRuntime> runtimes = [];
  final List<AttackTokenLeaseSnapshot> snapshots = [];

  @override
  Phase0aPreparedAttackTokenLeaseBatch prepare({
    required AttackTokenLeaseRuntime runtime,
    required List<Phase0aIntent> enemyIntents,
  }) {
    runtimes.add(runtime);
    snapshots.add(runtime.snapshot);
    return delegate.prepare(runtime: runtime, enemyIntents: enemyIntents);
  }
}

final class _CountingObjectiveSource
    implements Phase0aEncounterObjectiveEventSource {
  _CountingObjectiveSource(this.delegate);

  final Phase0aEncounterObjectiveEventSource delegate;
  var calls = 0;

  @override
  Iterable<EncounterObjectiveEvent> eventsFor(
    Phase0aEncounterObjectiveFrame frame,
  ) {
    calls++;
    return delegate.eventsFor(frame);
  }
}

final class _ThrowOnceObjectiveSource
    implements Phase0aEncounterObjectiveEventSource {
  _ThrowOnceObjectiveSource(this.delegate);

  final Phase0aEncounterObjectiveEventSource delegate;
  var calls = 0;

  @override
  Iterable<EncounterObjectiveEvent> eventsFor(
    Phase0aEncounterObjectiveFrame frame,
  ) {
    calls++;
    if (calls == 1) throw StateError('objective source failed');
    return delegate.eventsFor(frame);
  }
}

final class _RecordingObserver implements Phase0aEnemyIntentObserver {
  final List<Phase0aEnemyIntentObservation> observations = [];

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    observations.add(observation);
  }
}

CombatEncounterSpawnEntry _entry(String id) => CombatEncounterSpawnEntry(
  entryId: 'entry_$id',
  archetypeId: 'archetype_$id',
  roleId: 'role_$id',
  entranceId: 'entrance_$id',
  positionId: 'position_$id',
  behaviorId: 'behavior_$id',
);

CombatEncounterDef _encounter() => CombatEncounterDef(
  id: 'batch14_migrated_encounter',
  spawnConfig: CombatEncounterSpawnConfig(
    activeLimit: 3,
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
  spawnEntries: [_entry('e1'), _entry('e2'), _entry('e3')],
  objectives: CombatObjectiveCompositionRef(
    completionRule: CombatObjectiveCompletionRule.all,
    clauses: [
      CombatObjectiveClauseRef(
        id: 'defeat_exact_target',
        primitive: CombatDefeatTargetsRef(const ['objective_e1']),
      ),
    ],
  ),
);

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required int health,
  required double x,
}) => Phase0aActor(
  id: id,
  side: side,
  position: ArenaVector(x, 0),
  facing: side == Phase0aSide.player
      ? const ArenaVector(1, 0)
      : const ArenaVector(-1, 0),
  maxHealth: side == Phase0aSide.player ? 100000 : health,
  currentHealth: health,
  moveSpeed: 100,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

CombatantSnapshot _snapshot({required int characterId, required bool player}) =>
    testCombatantSnapshot(
      characterId: characterId,
      name: 'c$characterId',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.ruMen,
      school: player ? TechniqueSchool.gangMeng : TechniqueSchool.yinRou,
      maxHp: 1000,
      internalForce: player ? 600 : 300,
      maxQi: 100,
      speed: 100,
      criticalRate: 0,
      evasionRate: 0,
      defenseRate: 0,
      totalEquipmentAttack: player ? 130 : 60,
    );

Phase0aAttackTokenEnforcementRequestMapper _requestMapper({
  String? forcedActorId,
}) => (intent) {
  if (intent is! Phase0aAttackIntent) return null;
  final priority = switch (intent.actorId) {
    'e3' => 30,
    'e1' => 20,
    'e2' => 10,
    _ => 0,
  };
  return AttackTokenRequest(
    actorId: forcedActorId ?? intent.actorId,
    kind: AttackTokenKind.melee,
    priority: priority,
    isOffscreen: false,
    isHighImpact: false,
    isUnblockableArea: false,
    spawnGraceTicksRemaining: 0,
    telegraphReady: true,
  );
};

({
  Phase0aEncounterFlow flow,
  math.Random rng,
  Phase0aMigratedEncounterPlan plan,
})
_buildFlow({
  required int seed,
  Phase0aAttackTokenEnforcementRequestMapper? tokenRequestMapper,
}) {
  final plan = _buildPlan();
  final objectiveSource = _objectiveSource(plan);
  final rng = math.Random(seed);
  final flow = Phase0aProductionFlowAssembler.assembleMigratedEncounterPlan(
    plan: plan,
    numbers: GameRepository.instance.numbers,
    rng: rng,
    tokenRequestMapper: tokenRequestMapper ?? _requestMapper(),
    objectiveEventSource: objectiveSource,
  );
  return (flow: flow, rng: rng, plan: plan);
}

Phase0aMigratedEncounterPlan _buildPlan({String? omittedCombatantId}) {
  final route = MigratedCombatStageEncounterRoute(
    'batch14_stage',
    _encounter(),
  );
  final enemyPositions = {'e1': 10.0, 'e2': 50.0, 'e3': 60.0};
  final enemyHealth = {'e1': 1, 'e2': 10000, 'e3': 10000};
  final plan = buildPhase0aMigratedEncounterPlan(
    route,
    tickDuration: const Duration(milliseconds: 500),
    resolveEnemyId: (entry) => entry.entryId.substring('entry_'.length),
    playerId: 'player',
    createActor: (entry, enemyId) => _actor(
      id: enemyId,
      side: Phase0aSide.enemy,
      health: enemyHealth[enemyId]!,
      x: enemyPositions[enemyId]!,
    ),
    initialState: Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: _actor(
        id: 'player',
        side: Phase0aSide.player,
        health: 100000,
        x: 0,
      ),
      enemies: const [],
      skillSlots: const [],
    ),
    combatants: [
      if (omittedCombatantId != 'player')
        Phase0aCombatantInput(
          actorId: 'player',
          snapshot: _snapshot(characterId: 1, player: true),
        ),
      for (var index = 1; index <= 3; index += 1)
        if (omittedCombatantId != 'e$index')
          Phase0aCombatantInput(
            actorId: 'e$index',
            snapshot: _snapshot(characterId: index + 1, player: false),
          ),
    ],
    moveBindings: const {
      Phase0aDamageKind.basic: _basicSkill,
      Phase0aDamageKind.gather: null,
      Phase0aDamageKind.clear: null,
    },
    playerAdapter: _playerAdapter,
    enemyAiAdapter: _enemyAdapter,
  );
  return plan;
}

Phase0aEncounterObjectiveEventSource _objectiveSource(
  Phase0aMigratedEncounterPlan plan,
) => Phase0aExplicitObjectiveEventSource(
  roster: plan.roster,
  defeatProjectionsByActorId: const {
    'e1': [Phase0aTargetDefeatProjection('objective_e1')],
    'e2': [],
    'e3': [],
  },
  externalProjectors: const [],
);

Phase0aExplicitAttackTokenLeaseBatchGate _explicitLeaseGate(
  Phase0aAttackTokenLeaseBatchPlanner planner,
) => Phase0aExplicitAttackTokenLeaseBatchGate(planner: planner);

Phase0aExplicitAttackTokenLeaseBatchGate _noOpLeaseGate() =>
    _explicitLeaseGate(({
      required AttackTokenLeaseSnapshot leaseSnapshot,
      required List<Phase0aIntent> enemyIntents,
    }) {
      return Phase0aAttackTokenLeaseBatchPlan(
        enemyIntents: enemyIntents,
        mutations: const [],
      );
    });

Phase0aEncounterFlow _assembleLeasePlan({
  required Phase0aMigratedEncounterPlan plan,
  required math.Random rng,
  required Phase0aAttackTokenLeaseBatchGate gate,
  required AttackTokenLeaseRuntime runtime,
  required Phase0aEncounterObjectiveEventSource objectiveSource,
  Phase0aEnemyIntentObserver? observer,
}) =>
    Phase0aProductionFlowAssembler.assembleMigratedEncounterPlanWithAttackTokenLease(
      plan: plan,
      numbers: GameRepository.instance.numbers,
      rng: rng,
      attackTokenLeaseBatchGate: gate,
      attackTokenLeaseRuntime: runtime,
      objectiveEventSource: objectiveSource,
      enemyIntentObserver: observer,
    );

void _expectFlowUnchanged({
  required Phase0aEncounterFlow flow,
  required Phase0aArenaState state,
  required SpawnDirectorState spawnState,
  required Phase0aBattleOutcome outcome,
  required Object records,
}) {
  expect(flow.state, same(state));
  expect(flow.spawnState.tick, spawnState.tick);
  expect(flow.spawnState.units, spawnState.units);
  expect(flow.outcome, outcome);
  expect(flow.lastOrderedEventRecords, same(records));
}

void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  test(
    'typed plan composes exact budgets and objective source in one flow',
    () {
      final first = _buildFlow(seed: 211);
      final second = _buildFlow(seed: 211);
      const command = Phase0aPlayerCommand(
        attack: true,
        attackAimDirection: ArenaVector(1, 0),
      );

      final firstEvents = first.flow.advance(
        deltaSeconds: 0.5,
        command: command,
      );
      final secondEvents = second.flow.advance(
        deltaSeconds: 0.5,
        command: command,
      );

      expect(first.plan.stageId, 'batch14_stage');
      expect(
        first.plan.mapping.director,
        same(first.plan.runtimeContracts.spawnDirector),
      );
      final enemyHits = firstEvents
          .whereType<Phase0aHitLanded>()
          .where((event) => event.target == 'player')
          .toList();
      expect(enemyHits.map((event) => event.actor), ['e3']);
      expect(
        first.flow.state.enemies
            .where((enemy) => enemy.isAlive)
            .map((enemy) => enemy.id),
        containsAll(['e2', 'e3']),
      );
      expect(first.flow.outcome, Phase0aBattleOutcome.victory);
      expect(firstEvents.last, isA<Phase0aBattleVictory>());
      expect(secondEvents, firstEvents);
      expect(second.flow.state, first.flow.state);
      expect(second.flow.outcome, first.flow.outcome);
      expect(second.rng.nextDouble(), first.rng.nextDouble());
    },
  );

  test('caller token mapper mismatch fails before publishing a tick', () {
    final built = _buildFlow(
      seed: 223,
      tokenRequestMapper: _requestMapper(forcedActorId: 'foreign_actor'),
    );
    final beforeState = built.flow.state;
    final beforeSpawn = built.flow.spawnState;

    expect(
      () => built.flow.advance(
        deltaSeconds: 0.5,
        command: const Phase0aPlayerCommand(),
      ),
      throwsArgumentError,
    );

    expect(built.flow.state, same(beforeState));
    expect(built.flow.spawnState.tick, beforeSpawn.tick);
    expect(built.flow.spawnState.units, beforeSpawn.units);
    expect(built.flow.outcome, Phase0aBattleOutcome.ongoing);
  });

  test(
    'lease bridge forwards exact dependencies without assembly mutation',
    () {
      final plan = _buildPlan();
      final runtime = AttackTokenLeaseRuntime.empty();
      final seedSnapshot = runtime.snapshot;
      final gate = _RecordingLeaseGate(_noOpLeaseGate());
      final observer = _RecordingObserver();
      final source = _CountingObjectiveSource(_objectiveSource(plan));
      final bridgeRng = math.Random(227);
      final directRng = math.Random(227);
      final flow = _assembleLeasePlan(
        plan: plan,
        rng: bridgeRng,
        gate: gate,
        runtime: runtime,
        objectiveSource: source,
        observer: observer,
      );
      final directFlow =
          Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
            mapping: plan.mapping,
            numbers: GameRepository.instance.numbers,
            rng: directRng,
            attackTokenLeaseBatchGate: _noOpLeaseGate(),
            attackTokenLeaseRuntime: AttackTokenLeaseRuntime.empty(),
            objectiveTracker: Phase0aObjectiveRuntimeTracker(
              controller: plan.runtimeContracts.objectiveController,
            ),
            objectiveEventSource: _objectiveSource(plan),
          );

      expect(gate.runtimes, isEmpty);
      expect(runtime.snapshot, same(seedSnapshot));
      expect(runtime.snapshot.revision, 0);
      expect(runtime.snapshot.activeLeases, isEmpty);
      expect(bridgeRng.nextDouble(), directRng.nextDouble());

      const command = Phase0aPlayerCommand(
        attack: true,
        attackAimDirection: ArenaVector(1, 0),
      );
      final bridgeEvents = flow.advance(deltaSeconds: 0.5, command: command);
      final directEvents = directFlow.advance(
        deltaSeconds: 0.5,
        command: command,
      );

      expect(gate.runtimes.single, same(runtime));
      expect(gate.snapshots.single, same(seedSnapshot));
      expect(observer.observations, hasLength(1));
      expect(source.calls, 1);
      expect(bridgeEvents, directEvents);
      expect(flow.state, directFlow.state);
      expect(flow.outcome, directFlow.outcome);
      expect(bridgeRng.nextDouble(), directRng.nextDouble());
    },
  );

  test('two lease bridge calls start fresh objective lineage', () {
    final plan = _buildPlan();
    final firstSource = _CountingObjectiveSource(_objectiveSource(plan));
    final secondSource = _CountingObjectiveSource(_objectiveSource(plan));
    final first = _assembleLeasePlan(
      plan: plan,
      rng: math.Random(229),
      gate: _noOpLeaseGate(),
      runtime: AttackTokenLeaseRuntime.empty(),
      objectiveSource: firstSource,
    );
    final second = _assembleLeasePlan(
      plan: plan,
      rng: math.Random(229),
      gate: _noOpLeaseGate(),
      runtime: AttackTokenLeaseRuntime.empty(),
      objectiveSource: secondSource,
    );
    const command = Phase0aPlayerCommand(
      attack: true,
      attackAimDirection: ArenaVector(1, 0),
    );

    first.advance(deltaSeconds: 0.5, command: command);
    expect(first.outcome, Phase0aBattleOutcome.victory);
    expect(firstSource.calls, 1);
    expect(second.outcome, Phase0aBattleOutcome.ongoing);
    expect(secondSource.calls, 0);

    second.advance(deltaSeconds: 0.5, command: command);
    expect(second.outcome, Phase0aBattleOutcome.victory);
    expect(secondSource.calls, 1);
  });

  for (final failure in ['planner', 'lease validation']) {
    test('$failure failure publishes nothing and retries predecessor', () {
      final plan = _buildPlan();
      var first = true;
      final gate = _RecordingLeaseGate(
        _explicitLeaseGate(({
          required AttackTokenLeaseSnapshot leaseSnapshot,
          required List<Phase0aIntent> enemyIntents,
        }) {
          if (first) {
            first = false;
            if (failure == 'planner') throw StateError('planner failed');
            return Phase0aAttackTokenLeaseBatchPlan(
              enemyIntents: enemyIntents,
              mutations: [
                ReleaseAttackTokenLease(AttackTokenLeaseId('unknown')),
              ],
            );
          }
          return Phase0aAttackTokenLeaseBatchPlan(
            enemyIntents: enemyIntents,
            mutations: const [],
          );
        }),
      );
      final flow = _assembleLeasePlan(
        plan: plan,
        rng: math.Random(233),
        gate: gate,
        runtime: AttackTokenLeaseRuntime.empty(),
        objectiveSource: _objectiveSource(plan),
      );
      final beforeState = flow.state;
      final beforeSpawn = flow.spawnState;
      final beforeOutcome = flow.outcome;
      final beforeRecords = flow.lastOrderedEventRecords;

      expect(
        () => flow.advance(
          deltaSeconds: 0.5,
          command: const Phase0aPlayerCommand(),
        ),
        throwsStateError,
      );
      _expectFlowUnchanged(
        flow: flow,
        state: beforeState,
        spawnState: beforeSpawn,
        outcome: beforeOutcome,
        records: beforeRecords,
      );

      flow.advance(deltaSeconds: 0.5, command: const Phase0aPlayerCommand());
      expect(gate.snapshots.map((snapshot) => snapshot.revision), [0, 0]);
    });
  }

  test(
    'objective source failure publishes nothing and retries predecessor',
    () {
      final plan = _buildPlan();
      final gate = _RecordingLeaseGate(_noOpLeaseGate());
      final source = _ThrowOnceObjectiveSource(_objectiveSource(plan));
      final flow = _assembleLeasePlan(
        plan: plan,
        rng: math.Random(239),
        gate: gate,
        runtime: AttackTokenLeaseRuntime.empty(),
        objectiveSource: source,
      );
      final beforeState = flow.state;
      final beforeSpawn = flow.spawnState;
      final beforeOutcome = flow.outcome;
      final beforeRecords = flow.lastOrderedEventRecords;

      expect(
        () => flow.advance(
          deltaSeconds: 0.5,
          command: const Phase0aPlayerCommand(),
        ),
        throwsStateError,
      );
      _expectFlowUnchanged(
        flow: flow,
        state: beforeState,
        spawnState: beforeSpawn,
        outcome: beforeOutcome,
        records: beforeRecords,
      );

      flow.advance(deltaSeconds: 0.5, command: const Phase0aPlayerCommand());
      expect(source.calls, 2);
      expect(gate.snapshots.map((snapshot) => snapshot.revision), [0, 0]);
    },
  );

  test('actor coverage failure precedes planner runtime and RNG', () {
    final plan = _buildPlan(omittedCombatantId: 'e3');
    final runtime = AttackTokenLeaseRuntime.empty();
    final seedSnapshot = runtime.snapshot;
    final gate = _RecordingLeaseGate(_noOpLeaseGate());
    final rng = math.Random(241);
    final control = math.Random(241);

    expect(
      () => _assembleLeasePlan(
        plan: plan,
        rng: rng,
        gate: gate,
        runtime: runtime,
        objectiveSource: _objectiveSource(plan),
      ),
      throwsArgumentError,
    );

    expect(gate.runtimes, isEmpty);
    expect(runtime.snapshot, same(seedSnapshot));
    expect(rng.nextDouble(), control.nextDouble());
  });

  test('migrated bridge remains explicit and does not wire lease runtime', () {
    final source = File(
      'lib/features/battle/application/phase0a/'
      'phase0a_production_flow_assembler.dart',
    ).readAsStringSync();
    final method = source.substring(
      source.indexOf(
        'static Phase0aEncounterFlow assembleMigratedEncounterPlan({',
      ),
      source.indexOf('  /// 全场 actor 精确覆盖'),
    );

    expect(method, contains('required Phase0aMigratedEncounterPlan plan'));
    expect(method, contains('contracts.attackTokenBudgets'));
    expect(method, contains('controller: contracts.objectiveController'));
    expect(method, contains('required Random rng'));
    expect(method, contains('required Phase0aEncounterObjectiveEventSource'));
    for (final forbidden in const [
      'AttackTokenLeaseRuntime',
      'ActionTimeline',
      'GameRepository',
      'rootBundle',
      'LegacyCombatStageEncounterRoute',
    ]) {
      expect(method, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('lease bridge source stays a pure explicit mapping delegate', () {
    final source = File(
      'lib/features/battle/application/phase0a/'
      'phase0a_production_flow_assembler.dart',
    ).readAsStringSync();
    final method = source.substring(
      source.indexOf('assembleMigratedEncounterPlanWithAttackTokenLease({'),
    );

    expect(method, contains('mapping: plan.mapping'));
    expect(method, contains('controller: plan.runtimeContracts.'));
    expect(method, contains('objectiveController'));
    expect(method, contains('attackTokenLeaseBatchGate:'));
    expect(method, contains('attackTokenLeaseRuntime:'));
    expect(method, contains('objectiveEventSource:'));
    for (final forbidden in const [
      'enemyIntentBatchGate:',
      'AttackTokenEnforcingBatchGate',
      'tokenRequestMapper',
      'attackTokenBudgets',
      'AttackTokenLeaseRuntime.empty(',
      'Phase0aExplicitAttackTokenLeaseBatchGate(',
      'ActionTimeline',
      'GameRepository',
      'rootBundle',
    ]) {
      expect(method, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('lease bridge concrete flow exposes the narrow typed source', () {
    final plan = _buildPlan();
    final flow = _assembleLeasePlan(
      plan: plan,
      rng: math.Random(251),
      gate: _noOpLeaseGate(),
      runtime: AttackTokenLeaseRuntime.empty(),
      objectiveSource: _objectiveSource(plan),
    );
    final Phase0aEncounterRuntimeObservationSource source = flow;
    final before = source.runtimeObservation;
    final beforeSecond = source.runtimeObservation;
    expect(beforeSecond, isNot(same(before)));
    expect(before.objectiveProgress, same(flow.objectiveProgress));
    expect(before.lastAttackTokenLeaseBatchReceipt, isNull);
    expect(beforeSecond.objectiveProgress, same(before.objectiveProgress));

    flow.advance(
      deltaSeconds: 0.5,
      command: const Phase0aPlayerCommand(
        attack: true,
        attackAimDirection: ArenaVector(1, 0),
      ),
    );

    final after = source.runtimeObservation;
    expect(after, isNot(same(beforeSecond)));
    expect(after.objectiveProgress, same(flow.objectiveProgress));
    expect(
      after.lastAttackTokenLeaseBatchReceipt,
      same(flow.lastAttackTokenLeaseBatchReceipt),
    );
    expect(after.lastAttackTokenLeaseBatchReceipt, isNotNull);
    expect(before.objectiveProgress, isNot(same(after.objectiveProgress)));
    expect(before.lastAttackTokenLeaseBatchReceipt, isNull);
  });

  for (final failure in ['planner', 'lease validation', 'objective source']) {
    test('lease bridge $failure keeps old typed members in fresh value', () {
      final plan = _buildPlan();
      var first = true;
      final gate = _RecordingLeaseGate(
        _explicitLeaseGate(({
          required AttackTokenLeaseSnapshot leaseSnapshot,
          required List<Phase0aIntent> enemyIntents,
        }) {
          if (first && failure != 'objective source') {
            first = false;
            if (failure == 'planner') throw StateError('planner failed');
            return Phase0aAttackTokenLeaseBatchPlan(
              enemyIntents: enemyIntents,
              mutations: [
                ReleaseAttackTokenLease(AttackTokenLeaseId('unknown')),
              ],
            );
          }
          return Phase0aAttackTokenLeaseBatchPlan(
            enemyIntents: enemyIntents,
            mutations: const [],
          );
        }),
      );
      final objectiveSource = failure == 'objective source'
          ? _ThrowOnceObjectiveSource(_objectiveSource(plan))
          : _CountingObjectiveSource(_objectiveSource(plan));
      final flow = _assembleLeasePlan(
        plan: plan,
        rng: math.Random(257),
        gate: gate,
        runtime: AttackTokenLeaseRuntime.empty(),
        objectiveSource: objectiveSource,
      );
      final Phase0aEncounterRuntimeObservationSource source = flow;
      final before = source.runtimeObservation;

      expect(
        () => flow.advance(
          deltaSeconds: 0.5,
          command: const Phase0aPlayerCommand(),
        ),
        throwsStateError,
      );

      final after = source.runtimeObservation;
      expect(after, isNot(same(before)));
      expect(after.objectiveProgress, same(before.objectiveProgress));
      expect(
        after.lastAttackTokenLeaseBatchReceipt,
        same(before.lastAttackTokenLeaseBatchReceipt),
      );
      expect(after.objectiveProgress, same(flow.objectiveProgress));
      expect(
        after.lastAttackTokenLeaseBatchReceipt,
        same(flow.lastAttackTokenLeaseBatchReceipt),
      );
    });
  }
}
