import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_attack_token_lease_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_objective_runtime_tracker.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_lease_runtime.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';

const _idle = Phase0aPlayerCommand();

const _playerAdapter = Phase0aPlayerInputAdapter(
  playerId: 'player',
  attackRange: 100,
  attackHalfArcRadians: 3.14,
  attackCooldownSeconds: 0,
  attackQiDelta: 0,
  gatherSlot: 'gather',
  gatherRingRadius: 1,
  gatherEffectRadius: 1,
  gatherQiCost: 0,
  gatherCooldownSeconds: 0,
  clearSlot: 'clear',
  clearEffectRadius: 1,
  clearQiCost: 0,
  clearCooldownSeconds: 0,
);

const _enemyAdapter = Phase0aEnemyAiAdapter(
  attackRange: 100,
  attackHalfArcRadians: 3.14,
  attackCooldownSeconds: 0,
);

Phase0aActor _actor(String id, Phase0aSide side, double x) => Phase0aActor(
  id: id,
  side: side,
  position: ArenaVector(x, 0),
  facing: side == Phase0aSide.player
      ? const ArenaVector(1, 0)
      : const ArenaVector(-1, 0),
  maxHealth: 1000,
  currentHealth: 1000,
  moveSpeed: 1,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

final class _RandomRecordingResolver implements Phase0aDamageResolver {
  _RandomRecordingResolver({this.failOnCall}) : _random = math.Random(2501);

  final int? failOnCall;
  final math.Random _random;
  final List<int> randomDraws = [];
  int calls = 0;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
    required double defenderWardMult,
  }) {
    calls++;
    randomDraws.add(_random.nextInt(1 << 20));
    if (calls == failOnCall) throw StateError('resolver failed');
    return const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 1);
  }
}

final class _RecordingObserver implements Phase0aEnemyIntentObserver {
  _RecordingObserver({this.failOnCall});

  final int? failOnCall;
  final List<Phase0aEnemyIntentObservation> observations = [];

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    observations.add(observation);
    if (observations.length == failOnCall) {
      throw StateError('observer failed');
    }
  }
}

enum _LeaseFailure { none, planner, validation, output }

final class _RecordingLeaseGate implements Phase0aAttackTokenLeaseBatchGate {
  _RecordingLeaseGate({this.failure = _LeaseFailure.none});

  final _LeaseFailure failure;
  final List<AttackTokenLeaseRuntime> runtimes = [];
  final List<AttackTokenLeaseSnapshot> snapshots = [];
  int calls = 0;

  @override
  Phase0aPreparedAttackTokenLeaseBatch prepare({
    required AttackTokenLeaseRuntime runtime,
    required List<Phase0aIntent> enemyIntents,
  }) {
    calls++;
    runtimes.add(runtime);
    snapshots.add(runtime.snapshot);
    if (calls == 2 && failure == _LeaseFailure.planner) {
      throw StateError('planner failed');
    }

    return Phase0aExplicitAttackTokenLeaseBatchGate(
      planner:
          ({
            required AttackTokenLeaseSnapshot leaseSnapshot,
            required List<Phase0aIntent> enemyIntents,
          }) {
            if (calls == 2 && failure == _LeaseFailure.validation) {
              return Phase0aAttackTokenLeaseBatchPlan(
                enemyIntents: enemyIntents,
                mutations: [
                  ReleaseAttackTokenLease(AttackTokenLeaseId('unknown')),
                ],
              );
            }
            if (calls == 2 && failure == _LeaseFailure.output) {
              return Phase0aAttackTokenLeaseBatchPlan(
                enemyIntents: const [
                  Phase0aMoveIntent(
                    actorId: 'foreign',
                    direction: ArenaVector(1, 0),
                  ),
                ],
                mutations: const [],
              );
            }
            return Phase0aAttackTokenLeaseBatchPlan(
              enemyIntents: enemyIntents,
              mutations: leaseSnapshot.activeLeases.isEmpty
                  ? [AcquireAttackTokenLease(_lease())]
                  : const [],
            );
          },
    ).prepare(runtime: runtime, enemyIntents: enemyIntents);
  }
}

AttackTokenLease _lease() => AttackTokenLease(
  id: AttackTokenLeaseId('lease_enemy'),
  request: AttackTokenRequest(
    actorId: 'enemy',
    kind: AttackTokenKind.melee,
    priority: 1,
    isOffscreen: false,
    isHighImpact: false,
    isUnblockableArea: false,
    spawnGraceTicksRemaining: 0,
    telegraphReady: true,
  ),
);

enum _SourceFailure { none, immediate, lazy }

final class _ProgressSource implements Phase0aEncounterObjectiveEventSource {
  _ProgressSource({
    this.failure = _SourceFailure.none,
    this.markerId = 'progress',
  });

  final _SourceFailure failure;
  final String markerId;
  int calls = 0;

  @override
  Iterable<EncounterObjectiveEvent> eventsFor(
    Phase0aEncounterObjectiveFrame frame,
  ) {
    calls++;
    if (calls == 2 && failure == _SourceFailure.immediate) {
      throw StateError('objective source failed');
    }
    if (calls == 2 && failure == _SourceFailure.lazy) {
      return _lazyFailure();
    }
    return [MarkerTouched(markerId, eventId: 'marker:$markerId')];
  }

  Iterable<EncounterObjectiveEvent> _lazyFailure() sync* {
    yield MarkerTouched('never', eventId: 'would-not-commit');
    throw StateError('lazy objective source failed');
  }
}

Phase0aObjectiveRuntimeTracker _tracker({bool terminalOnProgress = false}) =>
    Phase0aObjectiveRuntimeTracker(
      controller: ObjectiveController(
        completionRule: ObjectiveCompletionRule.all,
        clauses: [
          ObjectiveClause(
            id: 'markers',
            objective: TouchMarkersObjective(
              terminalOnProgress
                  ? const ['progress']
                  : const ['progress', 'never'],
            ),
          ),
        ],
      ),
    );

final class _Harness {
  const _Harness({
    required this.flow,
    required this.tracker,
    required this.source,
    required this.gate,
    required this.observer,
    required this.resolver,
  });

  final Phase0aEncounterFlow flow;
  final Phase0aObjectiveRuntimeTracker? tracker;
  final _ProgressSource? source;
  final _RecordingLeaseGate? gate;
  final _RecordingObserver? observer;
  final _RandomRecordingResolver resolver;
}

_Harness _runtimeHarness({
  bool configureObjective = true,
  bool configureLease = true,
  bool terminalObjective = false,
  _LeaseFailure leaseFailure = _LeaseFailure.none,
  _SourceFailure sourceFailure = _SourceFailure.none,
  int? observerFailOnCall,
  int? resolverFailOnCall,
}) {
  var director = SpawnDirector(
    config: SpawnDirectorConfig(
      activeLimit: 1,
      reinforcementThreshold: 0,
      entryWarningTicks: 0,
      attackGraceTicks: 0,
    ),
    entries: [SpawnEntry(entryId: 'entry', enemyId: 'enemy')],
  );
  director = director.advance().director;
  final enemy = _actor('enemy', Phase0aSide.enemy, 20);
  final roster = Phase0aEncounterRoster(
    director: director,
    playerId: 'player',
    bindings: [Phase0aEncounterRosterBinding(entryId: 'entry', actor: enemy)],
  );
  final tracker = configureObjective
      ? _tracker(terminalOnProgress: terminalObjective)
      : null;
  final source = configureObjective
      ? _ProgressSource(failure: sourceFailure)
      : null;
  final gate = configureLease
      ? _RecordingLeaseGate(failure: leaseFailure)
      : null;
  final observer = _RecordingObserver(failOnCall: observerFailOnCall);
  final resolver = _RandomRecordingResolver(failOnCall: resolverFailOnCall);
  final session = Phase0aCombatSession(
    initialState: Phase0aArenaState(
      tick: director.state.tick,
      nextSeq: 1,
      player: _actor('player', Phase0aSide.player, 0),
      enemies: [enemy],
      skillSlots: const [],
    ),
    playerAdapter: _playerAdapter,
    enemyAiAdapter: _enemyAdapter,
    damageResolver: resolver,
    enemyIntentObserver: observer,
    attackTokenLeaseBatchGate: gate,
    attackTokenLeaseRuntime: configureLease
        ? AttackTokenLeaseRuntime.empty()
        : null,
  );
  return _Harness(
    flow: Phase0aEncounterFlow.runtime(
      session: session,
      director: director,
      roster: roster,
      objectiveTracker: tracker,
      objectiveEventSource: source,
    ),
    tracker: tracker,
    source: source,
    gate: gate,
    observer: observer,
    resolver: resolver,
  );
}

Phase0aWaveBattleFlow _legacyFlow() {
  final player = _actor('player', Phase0aSide.player, 0);
  final enemy = _actor('legacy_enemy', Phase0aSide.enemy, 20);
  return Phase0aWaveBattleFlow(
    session: Phase0aCombatSession(
      initialState: Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: player,
        enemies: [enemy],
        skillSlots: const [],
      ),
      playerAdapter: _playerAdapter,
      enemyAiAdapter: _enemyAdapter,
      damageResolver: _RandomRecordingResolver(),
    ),
    waves: [
      Phase0aWave(enemies: [enemy]),
    ],
  );
}

void _expectOldObservationsPreserved({
  required _Harness harness,
  required Phase0aArenaState state,
  required SpawnDirectorState spawnState,
  required Phase0aBattleOutcome outcome,
  required Object records,
  required ObjectiveControllerProgress progress,
  required Object receipt,
}) {
  expect(harness.flow.state, same(state));
  expect(harness.flow.spawnState.tick, spawnState.tick);
  expect(harness.flow.spawnState.units, spawnState.units);
  expect(harness.flow.outcome, outcome);
  expect(harness.flow.lastOrderedEventRecords, same(records));
  expect(harness.flow.objectiveProgress, same(progress));
  expect(harness.flow.lastAttackTokenLeaseBatchReceipt, same(receipt));
}

void main() {
  test('compatibility and unconfigured runtime observations stay null', () {
    final compatibility = Phase0aEncounterFlow.compatibility(
      legacy: _legacyFlow(),
    );
    expect(compatibility.objectiveProgress, isNull);
    expect(compatibility.lastAttackTokenLeaseBatchReceipt, isNull);
    compatibility.advance(deltaSeconds: 1, command: _idle);
    expect(compatibility.objectiveProgress, isNull);
    expect(compatibility.lastAttackTokenLeaseBatchReceipt, isNull);

    final runtime = _runtimeHarness(
      configureObjective: false,
      configureLease: false,
    ).flow;
    expect(runtime.objectiveProgress, isNull);
    expect(runtime.lastAttackTokenLeaseBatchReceipt, isNull);
    runtime.advance(deltaSeconds: 1, command: _idle);
    expect(runtime.objectiveProgress, isNull);
    expect(runtime.lastAttackTokenLeaseBatchReceipt, isNull);
  });

  test('fresh and committed objective progress retain exact identity', () {
    final harness = _runtimeHarness(configureLease: false);
    final initial = harness.tracker!.progress;

    expect(harness.flow.objectiveProgress, same(initial));
    harness.flow.advance(deltaSeconds: 1, command: _idle);

    final committed = harness.tracker!.progress;
    expect(committed, isNot(same(initial)));
    expect(harness.flow.objectiveProgress, same(committed));
    expect(committed.completed, isFalse);
    expect(committed.clauses.single.progress.satisfied, {'progress'});
    expect(() => committed.clauses.clear(), throwsUnsupportedError);
  });

  test('successful and no-op lease receipts expose exact snapshot lineage', () {
    final harness = _runtimeHarness(configureObjective: false);
    final gate = harness.gate!;

    harness.flow.advance(deltaSeconds: 1, command: _idle);
    final acquired = harness.flow.lastAttackTokenLeaseBatchReceipt!;
    expect(harness.flow.lastAttackTokenLeaseBatchReceipt, same(acquired));
    expect(acquired.before, same(gate.snapshots[0]));
    expect(acquired.after.revision, 1);
    expect(acquired.mutations, hasLength(1));
    expect(() => acquired.mutations.clear(), throwsUnsupportedError);

    harness.flow.advance(deltaSeconds: 1, command: _idle);
    final noOp = harness.flow.lastAttackTokenLeaseBatchReceipt!;
    expect(noOp, isNot(same(acquired)));
    expect(gate.snapshots[1], same(acquired.after));
    expect(noOp.before, same(gate.snapshots[1]));
    expect(noOp.after, same(gate.snapshots[1]));
    expect(noOp.mutations, isEmpty);
  });

  for (final failure in _LeaseFailure.values.where(
    (value) => value != _LeaseFailure.none,
  )) {
    test('${failure.name} failure preserves old progress and receipt', () {
      final harness = _runtimeHarness(leaseFailure: failure);
      harness.flow.advance(deltaSeconds: 1, command: _idle);
      final state = harness.flow.state;
      final spawnState = harness.flow.spawnState;
      final outcome = harness.flow.outcome;
      final records = harness.flow.lastOrderedEventRecords;
      final progress = harness.flow.objectiveProgress!;
      final receipt = harness.flow.lastAttackTokenLeaseBatchReceipt!;

      expect(
        () => harness.flow.advance(deltaSeconds: 1, command: _idle),
        throwsStateError,
      );

      _expectOldObservationsPreserved(
        harness: harness,
        state: state,
        spawnState: spawnState,
        outcome: outcome,
        records: records,
        progress: progress,
        receipt: receipt,
      );
      expect(harness.gate!.calls, 2);
    });
  }

  test('observer failure preserves old progress and receipt', () {
    final harness = _runtimeHarness(observerFailOnCall: 2);
    harness.flow.advance(deltaSeconds: 1, command: _idle);
    final state = harness.flow.state;
    final spawnState = harness.flow.spawnState;
    final outcome = harness.flow.outcome;
    final records = harness.flow.lastOrderedEventRecords;
    final progress = harness.flow.objectiveProgress!;
    final receipt = harness.flow.lastAttackTokenLeaseBatchReceipt!;

    expect(
      () => harness.flow.advance(deltaSeconds: 1, command: _idle),
      throwsStateError,
    );

    _expectOldObservationsPreserved(
      harness: harness,
      state: state,
      spawnState: spawnState,
      outcome: outcome,
      records: records,
      progress: progress,
      receipt: receipt,
    );
    expect(harness.observer!.observations, hasLength(2));
  });

  test(
    'resolver failure preserves observations but not caller RNG effects',
    () {
      final harness = _runtimeHarness(resolverFailOnCall: 2);
      harness.flow.advance(deltaSeconds: 1, command: _idle);
      final state = harness.flow.state;
      final spawnState = harness.flow.spawnState;
      final outcome = harness.flow.outcome;
      final records = harness.flow.lastOrderedEventRecords;
      final progress = harness.flow.objectiveProgress!;
      final receipt = harness.flow.lastAttackTokenLeaseBatchReceipt!;

      expect(
        () => harness.flow.advance(deltaSeconds: 1, command: _idle),
        throwsStateError,
      );

      _expectOldObservationsPreserved(
        harness: harness,
        state: state,
        spawnState: spawnState,
        outcome: outcome,
        records: records,
        progress: progress,
        receipt: receipt,
      );
      expect(harness.resolver.calls, 2);
      expect(harness.resolver.randomDraws, hasLength(2));
      expect(harness.observer!.observations, hasLength(2));
    },
  );

  for (final failure in [_SourceFailure.immediate, _SourceFailure.lazy]) {
    test('${failure.name} objective source failure preserves observations', () {
      final harness = _runtimeHarness(sourceFailure: failure);
      harness.flow.advance(deltaSeconds: 1, command: _idle);
      final state = harness.flow.state;
      final spawnState = harness.flow.spawnState;
      final outcome = harness.flow.outcome;
      final records = harness.flow.lastOrderedEventRecords;
      final progress = harness.flow.objectiveProgress!;
      final receipt = harness.flow.lastAttackTokenLeaseBatchReceipt!;

      expect(
        () => harness.flow.advance(deltaSeconds: 1, command: _idle),
        throwsStateError,
      );

      _expectOldObservationsPreserved(
        harness: harness,
        state: state,
        spawnState: spawnState,
        outcome: outcome,
        records: records,
        progress: progress,
        receipt: receipt,
      );
      expect(harness.source!.calls, 2);
      expect(harness.resolver.randomDraws, hasLength(2));
    });
  }

  test('terminal advance keeps exact progress and receipt observations', () {
    final harness = _runtimeHarness(terminalObjective: true);
    final terminalEvents = harness.flow.advance(
      deltaSeconds: 1,
      command: _idle,
    );
    final progress = harness.flow.objectiveProgress!;
    final receipt = harness.flow.lastAttackTokenLeaseBatchReceipt!;
    expect(progress.completed, isTrue);
    expect(harness.flow.outcome, Phase0aBattleOutcome.victory);
    expect(terminalEvents.last, isA<Phase0aBattleVictory>());
    expect(harness.flow.lastOrderedEventRecords, isNotEmpty);

    for (var replay = 0; replay < 2; replay++) {
      expect(harness.flow.advance(deltaSeconds: 1, command: _idle), isEmpty);
      expect(harness.flow.objectiveProgress, same(progress));
      expect(harness.flow.lastAttackTokenLeaseBatchReceipt, same(receipt));
      expect(harness.flow.lastOrderedEventRecords, isEmpty);
    }
    expect(harness.gate!.calls, 1);
  });

  test('source exposes values only and keeps order before publication', () {
    final source = File(
      'lib/features/battle/application/phase0a/phase0a_encounter_flow.dart',
    ).readAsStringSync();
    final battleFlow = File(
      'lib/features/battle/application/phase0a/phase0a_battle_flow.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("import '../../domain/phase0a/objective_controller.dart';"),
    );
    expect(
      source,
      contains("import 'phase0a_attack_token_lease_batch_receipt.dart';"),
    );
    expect(
      RegExp(
        r'ObjectiveControllerProgress\? get objectiveProgress\s*=>\s*'
        r'_objectiveTracker\?\.progress;',
      ).hasMatch(source),
      isTrue,
    );
    expect(
      RegExp(
        r'Phase0aAttackTokenLeaseBatchReceipt\?\s*get '
        r'lastAttackTokenLeaseBatchReceipt\s*=>\s*'
        r'_session\?\.lastAttackTokenLeaseBatchReceipt;',
      ).hasMatch(source),
      isTrue,
    );
    expect(battleFlow, isNot(contains('objectiveProgress')));
    expect(battleFlow, isNot(contains('lastAttackTokenLeaseBatchReceipt')));

    final orderProjection = source.indexOf(
      'final nextRecords = Phase0aEventOrderAdapter.project(events);',
    );
    final objectiveCommit = source.indexOf(
      'objectiveTracker!.commit(objectiveTransition);',
    );
    final sessionPublication = source.indexOf('_session = nextSession;');
    expect(orderProjection, greaterThan(0));
    expect(objectiveCommit, greaterThan(orderProjection));
    expect(sessionPublication, greaterThan(objectiveCommit));

    for (final forbidden in const [
      'AttackTokenLeaseRuntime',
      'Phase0aPreparedAttackTokenLeaseBatch',
      'Phase0aPreparedObjectiveTransition get',
      'Phase0aCombatSession get',
      'Phase0aObjectiveRuntimeTracker get',
      'ActionTimeline',
      'GameRepository',
      'SaveData',
      'Isar',
      'outbox',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
