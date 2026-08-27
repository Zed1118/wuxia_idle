import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_attack_token_lease_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_mapping.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_objective_runtime_tracker.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_lease_runtime.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

final class _RecordingLeaseGate implements Phase0aAttackTokenLeaseBatchGate {
  _RecordingLeaseGate(this.delegate);

  final Phase0aAttackTokenLeaseBatchGate delegate;
  final List<AttackTokenLeaseRuntime> runtimes = [];

  @override
  Phase0aPreparedAttackTokenLeaseBatch prepare({
    required AttackTokenLeaseRuntime runtime,
    required List<Phase0aIntent> enemyIntents,
  }) {
    runtimes.add(runtime);
    return delegate.prepare(runtime: runtime, enemyIntents: enemyIntents);
  }
}

final class _PassBatchGate implements Phase0aEnemyIntentBatchGate {
  @override
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) => enemyIntents;
}

final class _ThrowOnceObserver implements Phase0aEnemyIntentObserver {
  var calls = 0;

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    calls++;
    if (calls == 1) throw StateError('observer failed');
  }
}

final class _ThrowOnceObjectiveSource
    implements Phase0aEncounterObjectiveEventSource {
  var calls = 0;

  @override
  Iterable<EncounterObjectiveEvent> eventsFor(
    Phase0aEncounterObjectiveFrame frame,
  ) {
    calls++;
    if (calls == 1) throw StateError('objective source failed');
    return const <EncounterObjectiveEvent>[];
  }
}

const _basicSkill = SkillDef(
  id: 'phase0a_production_lease_wiring_basic',
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
  attackRange: 120,
  attackHalfArcRadians: math.pi / 4,
  attackCooldownSeconds: 0.5,
  attackQiDelta: 0,
  postureBasicPowerMultiplier: 1,
  attackPowerMultiplier: 1,
  gatherPowerMultiplier: 1,
  clearPowerMultiplier: 1,
  gatherSlot: 'gather',
  gatherRingRadius: 90,
  gatherEffectRadius: 500,
  gatherQiCost: 20,
  gatherCooldownSeconds: 3,
  clearSlot: 'clear',
  clearEffectRadius: 500,
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

final class _EncounterFixture {
  const _EncounterFixture({
    required this.initialState,
    required this.director,
    required this.roster,
    required this.combatants,
    required this.moveBindings,
  });

  final Phase0aArenaState initialState;
  final SpawnDirector director;
  final Phase0aEncounterRoster roster;
  final List<Phase0aCombatantInput> combatants;
  final Map<Phase0aDamageKind, SkillDef?> moveBindings;

  Phase0aEncounterMapping mapping() => Phase0aEncounterMapping(
    initialState: initialState,
    director: director,
    roster: roster,
    combatants: combatants,
    moveBindings: moveBindings,
    playerAdapter: _playerAdapter,
    enemyAiAdapter: _enemyAdapter,
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
  maxHealth: 100000,
  currentHealth: 100000,
  moveSpeed: 100,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

CombatantSnapshot _snapshot({
  required int characterId,
  required TechniqueSchool school,
}) => testCombatantSnapshot(
  characterId: characterId,
  name: 'c$characterId',
  realmTier: RealmTier.xueTu,
  realmLayer: RealmLayer.ruMen,
  school: school,
  maxHp: 1000,
  internalForce: characterId == 1 ? 600 : 400,
  maxQi: 100,
  speed: 100,
  criticalRate: 0,
  evasionRate: 0,
  defenseRate: 0,
  totalEquipmentAttack: characterId == 1 ? 130 : 90,
);

_EncounterFixture _fixture() {
  final director = SpawnDirector(
    config: SpawnDirectorConfig(
      activeLimit: 1,
      reinforcementThreshold: 0,
      entryWarningTicks: 0,
      attackGraceTicks: 0,
    ),
    entries: [SpawnEntry(entryId: 'entry_e1', enemyId: 'e1')],
  );
  return _EncounterFixture(
    initialState: Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: _actor(id: 'player', side: Phase0aSide.player, x: 0),
      enemies: const [],
      skillSlots: const [],
    ),
    director: director,
    roster: Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        Phase0aEncounterRosterBinding(
          entryId: 'entry_e1',
          actor: _actor(id: 'e1', side: Phase0aSide.enemy, x: 50),
        ),
      ],
    ),
    combatants: [
      Phase0aCombatantInput(
        actorId: 'player',
        snapshot: _snapshot(characterId: 1, school: TechniqueSchool.gangMeng),
      ),
      Phase0aCombatantInput(
        actorId: 'e1',
        snapshot: _snapshot(characterId: 2, school: TechniqueSchool.yinRou),
      ),
    ],
    moveBindings: const {
      Phase0aDamageKind.basic: _basicSkill,
      Phase0aDamageKind.gather: null,
      Phase0aDamageKind.clear: null,
    },
  );
}

Phase0aEncounterFlow _assemble({
  required math.Random rng,
  bool fromMapping = false,
  Phase0aEnemyIntentObserver? observer,
  Phase0aEnemyIntentBatchGate? statelessGate,
  Phase0aAttackTokenLeaseBatchGate? leaseGate,
  AttackTokenLeaseRuntime? leaseRuntime,
  Phase0aObjectiveRuntimeTracker? objectiveTracker,
  Phase0aEncounterObjectiveEventSource? objectiveEventSource,
}) {
  final fixture = _fixture();
  if (fromMapping) {
    return Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
      mapping: fixture.mapping(),
      numbers: GameRepository.instance.numbers,
      rng: rng,
      enemyIntentObserver: observer,
      enemyIntentBatchGate: statelessGate,
      attackTokenLeaseBatchGate: leaseGate,
      attackTokenLeaseRuntime: leaseRuntime,
      objectiveTracker: objectiveTracker,
      objectiveEventSource: objectiveEventSource,
    );
  }
  return Phase0aProductionFlowAssembler.assembleEncounter(
    initialState: fixture.initialState,
    director: fixture.director,
    roster: fixture.roster,
    combatants: fixture.combatants,
    moveBindings: fixture.moveBindings,
    numbers: GameRepository.instance.numbers,
    rng: rng,
    playerAdapter: _playerAdapter,
    enemyAiAdapter: _enemyAdapter,
    enemyIntentObserver: observer,
    enemyIntentBatchGate: statelessGate,
    attackTokenLeaseBatchGate: leaseGate,
    attackTokenLeaseRuntime: leaseRuntime,
    objectiveTracker: objectiveTracker,
    objectiveEventSource: objectiveEventSource,
  );
}

AttackTokenLease _lease() => AttackTokenLease(
  id: AttackTokenLeaseId('lease_e1'),
  request: AttackTokenRequest(
    actorId: 'e1',
    kind: AttackTokenKind.melee,
    priority: 7,
    isOffscreen: false,
    isHighImpact: true,
    isUnblockableArea: false,
    spawnGraceTicksRemaining: 0,
    telegraphReady: true,
  ),
);

Phase0aExplicitAttackTokenLeaseBatchGate _explicitGate(
  Phase0aAttackTokenLeaseBatchPlanner planner,
) => Phase0aExplicitAttackTokenLeaseBatchGate(planner: planner);

Phase0aExplicitAttackTokenLeaseBatchGate _noOpGate(
  List<AttackTokenLeaseSnapshot> seenSnapshots,
) => _explicitGate(({
  required AttackTokenLeaseSnapshot leaseSnapshot,
  required List<Phase0aIntent> enemyIntents,
}) {
  seenSnapshots.add(leaseSnapshot);
  return Phase0aAttackTokenLeaseBatchPlan(
    enemyIntents: enemyIntents,
    mutations: const [],
  );
});

Phase0aExplicitAttackTokenLeaseBatchGate _acquireOnceGate(
  List<AttackTokenLeaseSnapshot> seenSnapshots,
) => _explicitGate(({
  required AttackTokenLeaseSnapshot leaseSnapshot,
  required List<Phase0aIntent> enemyIntents,
}) {
  seenSnapshots.add(leaseSnapshot);
  return Phase0aAttackTokenLeaseBatchPlan(
    enemyIntents: enemyIntents,
    mutations: leaseSnapshot.activeLeases.isEmpty
        ? [AcquireAttackTokenLease(_lease())]
        : const [],
  );
});

Phase0aObjectiveRuntimeTracker _neverCompletingTracker() =>
    Phase0aObjectiveRuntimeTracker(
      controller: ObjectiveController(
        completionRule: ObjectiveCompletionRule.all,
        clauses: [
          ObjectiveClause(
            id: 'never_complete',
            objective: DefeatTargetsObjective(const {'never'}),
          ),
        ],
      ),
    );

List<Phase0aEvent> _advanceTicks(Phase0aEncounterFlow flow, int ticks) {
  final events = <Phase0aEvent>[];
  for (var index = 0; index < ticks; index++) {
    events.addAll(
      flow.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand()),
    );
  }
  return events;
}

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

  group('production attack-token lease assembler seam', () {
    test('direct assembler forwards exact runtime and publishes acquire', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final snapshots = <AttackTokenLeaseSnapshot>[];
      final gate = _RecordingLeaseGate(_acquireOnceGate(snapshots));
      final flow = _assemble(
        rng: math.Random(201),
        leaseGate: gate,
        leaseRuntime: runtime,
      );

      _advanceTicks(flow, 2);

      expect(gate.runtimes, hasLength(2));
      expect(gate.runtimes.first, same(runtime));
      expect(gate.runtimes.last, isNot(same(runtime)));
      expect(snapshots.map((snapshot) => snapshot.revision), [0, 1]);
      expect(snapshots.map((snapshot) => snapshot.activeLeases.length), [0, 1]);
      expect(runtime.snapshot.revision, 0);
      expect(runtime.snapshot.activeLeases, isEmpty);
      expect(flow.state.tick, 2);
    });

    test('mapping bridge forwards exact pair and empty plan is no-op', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final seedSnapshot = runtime.snapshot;
      final snapshots = <AttackTokenLeaseSnapshot>[];
      final gate = _RecordingLeaseGate(_noOpGate(snapshots));
      final flow = _assemble(
        rng: math.Random(203),
        fromMapping: true,
        leaseGate: gate,
        leaseRuntime: runtime,
      );

      _advanceTicks(flow, 2);

      expect(gate.runtimes, everyElement(same(runtime)));
      expect(snapshots, everyElement(same(seedSnapshot)));
      expect(snapshots.map((snapshot) => snapshot.revision), [0, 0]);
      expect(flow.state.tick, 2);
    });

    test('pair and batch-gate conflicts fail closed without consuming RNG', () {
      for (final fromMapping in [false, true]) {
        void expectRejected({
          required Phase0aAttackTokenLeaseBatchGate? gate,
          required AttackTokenLeaseRuntime? runtime,
          Phase0aEnemyIntentBatchGate? statelessGate,
        }) {
          final rng = math.Random(211);
          final control = math.Random(211);
          expect(
            () => _assemble(
              rng: rng,
              fromMapping: fromMapping,
              leaseGate: gate,
              leaseRuntime: runtime,
              statelessGate: statelessGate,
            ),
            throwsArgumentError,
          );
          expect(rng.nextDouble(), control.nextDouble());
        }

        final gate = _RecordingLeaseGate(_noOpGate([]));
        expectRejected(gate: gate, runtime: null);
        expectRejected(gate: null, runtime: AttackTokenLeaseRuntime.empty());
        expectRejected(
          gate: gate,
          runtime: AttackTokenLeaseRuntime.empty(),
          statelessGate: _PassBatchGate(),
        );
        expect(gate.runtimes, isEmpty);
      }
    });

    test('no-op lease and null paths are replay and RNG equivalent', () {
      final baselineRng = math.Random(223);
      final leaseRng = math.Random(223);
      final baseline = _assemble(rng: baselineRng);
      final snapshots = <AttackTokenLeaseSnapshot>[];
      final leaseFlow = _assemble(
        rng: leaseRng,
        leaseGate: _RecordingLeaseGate(_noOpGate(snapshots)),
        leaseRuntime: AttackTokenLeaseRuntime.empty(),
      );

      final baselineEvents = _advanceTicks(baseline, 3);
      final leaseEvents = _advanceTicks(leaseFlow, 3);

      expect(leaseEvents, baselineEvents);
      expect(leaseFlow.state, baseline.state);
      expect(leaseFlow.outcome, baseline.outcome);
      expect(
        leaseFlow.lastOrderedEventRecords,
        baseline.lastOrderedEventRecords,
      );
      expect(leaseRng.nextDouble(), baselineRng.nextDouble());
      expect(snapshots.map((snapshot) => snapshot.revision), [0, 0, 0]);
    });

    for (final failure in ['planner', 'lease validation']) {
      test('$failure failure publishes nothing and retries predecessor', () {
        final snapshots = <AttackTokenLeaseSnapshot>[];
        var first = true;
        final gate = _RecordingLeaseGate(
          _explicitGate(({
            required AttackTokenLeaseSnapshot leaseSnapshot,
            required List<Phase0aIntent> enemyIntents,
          }) {
            snapshots.add(leaseSnapshot);
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
              mutations: leaseSnapshot.activeLeases.isEmpty
                  ? [AcquireAttackTokenLease(_lease())]
                  : const [],
            );
          }),
        );
        final flow = _assemble(
          rng: math.Random(227),
          leaseGate: gate,
          leaseRuntime: AttackTokenLeaseRuntime.empty(),
        );
        final beforeState = flow.state;
        final beforeSpawn = flow.spawnState;
        final beforeOutcome = flow.outcome;
        final beforeRecords = flow.lastOrderedEventRecords;

        expect(() => _advanceTicks(flow, 1), throwsStateError, reason: failure);
        _expectFlowUnchanged(
          flow: flow,
          state: beforeState,
          spawnState: beforeSpawn,
          outcome: beforeOutcome,
          records: beforeRecords,
        );

        _advanceTicks(flow, 2);
        expect(snapshots.map((snapshot) => snapshot.revision), [0, 0, 1]);
        expect(flow.state.tick, 2);
      });
    }

    test('observer failure publishes nothing and retries predecessor', () {
      final snapshots = <AttackTokenLeaseSnapshot>[];
      final observer = _ThrowOnceObserver();
      final flow = _assemble(
        rng: math.Random(229),
        observer: observer,
        leaseGate: _RecordingLeaseGate(_acquireOnceGate(snapshots)),
        leaseRuntime: AttackTokenLeaseRuntime.empty(),
      );
      final beforeState = flow.state;
      final beforeSpawn = flow.spawnState;
      final beforeOutcome = flow.outcome;
      final beforeRecords = flow.lastOrderedEventRecords;

      expect(() => _advanceTicks(flow, 1), throwsStateError);
      _expectFlowUnchanged(
        flow: flow,
        state: beforeState,
        spawnState: beforeSpawn,
        outcome: beforeOutcome,
        records: beforeRecords,
      );

      _advanceTicks(flow, 2);
      expect(snapshots.map((snapshot) => snapshot.revision), [0, 0, 1]);
      expect(observer.calls, 3);
    });

    test('reducer failure publishes nothing and retries predecessor', () {
      final snapshots = <AttackTokenLeaseSnapshot>[];
      final flow = _assemble(
        rng: math.Random(233),
        leaseGate: _RecordingLeaseGate(_acquireOnceGate(snapshots)),
        leaseRuntime: AttackTokenLeaseRuntime.empty(),
      );
      final beforeState = flow.state;
      final beforeSpawn = flow.spawnState;
      final beforeOutcome = flow.outcome;
      final beforeRecords = flow.lastOrderedEventRecords;

      expect(
        () => flow.advance(
          deltaSeconds: double.nan,
          command: const Phase0aPlayerCommand(),
        ),
        throwsArgumentError,
      );
      _expectFlowUnchanged(
        flow: flow,
        state: beforeState,
        spawnState: beforeSpawn,
        outcome: beforeOutcome,
        records: beforeRecords,
      );

      _advanceTicks(flow, 2);
      expect(snapshots.map((snapshot) => snapshot.revision), [0, 0, 1]);
    });

    test('objective failure rolls back candidate lease before retry', () {
      final snapshots = <AttackTokenLeaseSnapshot>[];
      final source = _ThrowOnceObjectiveSource();
      final flow = _assemble(
        rng: math.Random(239),
        leaseGate: _RecordingLeaseGate(_acquireOnceGate(snapshots)),
        leaseRuntime: AttackTokenLeaseRuntime.empty(),
        objectiveTracker: _neverCompletingTracker(),
        objectiveEventSource: source,
      );
      final beforeState = flow.state;
      final beforeSpawn = flow.spawnState;
      final beforeOutcome = flow.outcome;
      final beforeRecords = flow.lastOrderedEventRecords;

      expect(() => _advanceTicks(flow, 1), throwsStateError);
      _expectFlowUnchanged(
        flow: flow,
        state: beforeState,
        spawnState: beforeSpawn,
        outcome: beforeOutcome,
        records: beforeRecords,
      );

      _advanceTicks(flow, 2);
      expect(snapshots.map((snapshot) => snapshot.revision), [0, 0, 1]);
      expect(source.calls, 3);
      expect(flow.state.tick, 2);
    });

    test('source guard keeps defaults lifecycle and migrated path out', () {
      final source = File(
        'lib/features/battle/application/phase0a/'
        'phase0a_production_flow_assembler.dart',
      ).readAsStringSync();
      final encounterStart = source.indexOf(
        'static Phase0aEncounterFlow assembleEncounter({',
      );
      final mappingStart = source.indexOf(
        'static Phase0aEncounterFlow assembleEncounterFromMapping({',
      );
      final migratedStart = source.indexOf(
        'static Phase0aEncounterFlow assembleMigratedEncounterPlan({',
      );
      final waveSlice = source.substring(
        source.indexOf('static Phase0aWaveBattleFlow assemble({'),
        encounterStart,
      );
      final migratedSlice = source.substring(
        migratedStart,
        source.indexOf('static void _checkActorCoverage'),
      );

      expect(encounterStart, greaterThan(0));
      expect(mappingStart, greaterThan(encounterStart));
      expect(migratedStart, greaterThan(mappingStart));
      for (final unchangedSlice in [waveSlice, migratedSlice]) {
        expect(unchangedSlice, isNot(contains('attackTokenLeaseBatchGate')));
        expect(unchangedSlice, isNot(contains('attackTokenLeaseRuntime')));
      }
      for (final forbidden in const [
        'ActionTimeline',
        'AttackTokenLeaseRuntime.empty(',
        'AttackTokenLeaseRuntime.restore(',
        'Phase0aExplicitAttackTokenLeaseBatchGate(',
        'Phase0aHitLanded',
        'Phase0aEnemyDefeated',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
      }
    });
  });
}
