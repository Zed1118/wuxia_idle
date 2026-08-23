import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_attack_token_lease_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_attack_token_lease_batch_receipt.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_objective_runtime_tracker.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_lease_runtime.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';

final class _DamageResolver implements Phase0aDamageResolver {
  _DamageResolver({this.throwOnResolve = false});

  final bool throwOnResolve;
  int calls = 0;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
    double defenderWardMult = 1.0,
  }) {
    calls++;
    if (throwOnResolve) throw StateError('resolver failed');
    return const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 10);
  }
}

final class _Observer implements Phase0aEnemyIntentObserver {
  _Observer({this.throwOnObserve = false});

  bool throwOnObserve;
  final observations = <Phase0aEnemyIntentObservation>[];

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    observations.add(observation);
    if (throwOnObserve) throw StateError('observer failed');
  }
}

final class _PassBatchGate implements Phase0aEnemyIntentBatchGate {
  @override
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) => enemyIntents;
}

final class _CommitFailOnSecondGate
    implements Phase0aAttackTokenLeaseBatchGate {
  int _calls = 0;

  @override
  Phase0aPreparedAttackTokenLeaseBatch prepare({
    required AttackTokenLeaseRuntime runtime,
    required List<Phase0aIntent> enemyIntents,
  }) {
    _calls++;
    final predecessor = _calls == 1 ? runtime : AttackTokenLeaseRuntime.empty();
    return _acquireGate().prepare(
      runtime: predecessor,
      enemyIntents: enemyIntents,
    );
  }
}

final class _ThrowOnceObjectiveSource
    implements Phase0aEncounterObjectiveEventSource {
  bool shouldThrow = true;

  @override
  Iterable<EncounterObjectiveEvent> eventsFor(
    Phase0aEncounterObjectiveFrame frame,
  ) {
    if (shouldThrow) {
      shouldThrow = false;
      throw StateError('objective source failed');
    }
    return const <EncounterObjectiveEvent>[];
  }
}

const _playerAdapter = Phase0aPlayerInputAdapter(
  playerId: 'player',
  attackRange: 120,
  attackHalfArcRadians: math.pi / 4,
  attackCooldownSeconds: 1,
  attackQiDelta: 0,
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
  attackCooldownSeconds: 1.2,
);

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
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 60,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aArenaState _state() => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: _actor(id: 'player', side: Phase0aSide.player, x: 0),
  enemies: [
    _actor(id: 'e1', side: Phase0aSide.enemy, x: 50),
    _actor(id: 'e2', side: Phase0aSide.enemy, x: 300),
  ],
  skillSlots: const [],
);

AttackTokenLease _lease(String id, String actorId) => AttackTokenLease(
  id: AttackTokenLeaseId(id),
  request: AttackTokenRequest(
    actorId: actorId,
    kind: AttackTokenKind.melee,
    priority: 7,
    isOffscreen: false,
    isHighImpact: true,
    isUnblockableArea: false,
    spawnGraceTicksRemaining: 0,
    telegraphReady: true,
  ),
);

Phase0aExplicitAttackTokenLeaseBatchGate _gate(
  Phase0aAttackTokenLeaseBatchPlanner planner,
) => Phase0aExplicitAttackTokenLeaseBatchGate(planner: planner);

Phase0aExplicitAttackTokenLeaseBatchGate _acquireGate({
  bool releaseWhenActive = false,
}) => _gate(({
  required AttackTokenLeaseSnapshot leaseSnapshot,
  required List<Phase0aIntent> enemyIntents,
}) {
  final mutations = <AttackTokenLeaseMutation>[];
  if (releaseWhenActive && leaseSnapshot.activeLeases.isNotEmpty) {
    mutations.add(
      ReleaseAttackTokenLease(leaseSnapshot.activeLeases.keys.single),
    );
  } else if (leaseSnapshot.activeLeases.isEmpty) {
    mutations.add(AcquireAttackTokenLease(_lease('lease_e1', 'e1')));
  }
  return Phase0aAttackTokenLeaseBatchPlan(
    enemyIntents: enemyIntents,
    mutations: mutations,
  );
});

Phase0aCombatSession _session({
  Phase0aArenaState? initialState,
  _DamageResolver? resolver,
  _Observer? observer,
  Phase0aEnemyIntentBatchGate? statelessGate,
  Phase0aAttackTokenLeaseBatchGate? leaseGate,
  AttackTokenLeaseRuntime? leaseRuntime,
}) => Phase0aCombatSession(
  initialState: initialState ?? _state(),
  playerAdapter: _playerAdapter,
  enemyAiAdapter: _enemyAdapter,
  damageResolver: resolver ?? _DamageResolver(),
  enemyIntentObserver: observer,
  enemyIntentBatchGate: statelessGate,
  attackTokenLeaseBatchGate: leaseGate,
  attackTokenLeaseRuntime: leaseRuntime,
);

Iterable<AttackTokenLeaseMutation> _throwingMutations() sync* {
  yield AcquireAttackTokenLease(_lease('lease_e1', 'e1'));
  throw StateError('lazy mutations failed');
}

void main() {
  group('lease batch receipt value', () {
    test('freezes caller mutations while retaining exact snapshots', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final before = runtime.snapshot;
      final mutation = AcquireAttackTokenLease(_lease('lease_e1', 'e1'));
      final mutations = <AttackTokenLeaseMutation>[mutation];
      final after = runtime.commit(runtime.prepare(mutations)).snapshot;

      final receipt = Phase0aAttackTokenLeaseBatchReceipt(
        before: before,
        mutations: mutations,
        after: after,
      );
      mutations.clear();

      expect(receipt.before, same(before));
      expect(receipt.mutations.single, same(mutation));
      expect(receipt.after, same(after));
      expect(() => receipt.mutations.clear(), throwsUnsupportedError);
    });
  });

  group('lease batch value and prepared successor', () {
    test('plan freezes caller lists and materializes lazy failures', () {
      const intent = Phase0aMoveIntent(
        actorId: 'e1',
        direction: ArenaVector(-1, 0),
      );
      final intents = <Phase0aIntent>[intent];
      final mutations = <AttackTokenLeaseMutation>[
        AcquireAttackTokenLease(_lease('lease_e1', 'e1')),
      ];
      final plan = Phase0aAttackTokenLeaseBatchPlan(
        enemyIntents: intents,
        mutations: mutations,
      );
      intents.clear();
      mutations.clear();

      expect(plan.enemyIntents.single, same(intent));
      expect(plan.mutations, hasLength(1));
      expect(() => plan.enemyIntents.clear(), throwsUnsupportedError);
      expect(() => plan.mutations.clear(), throwsUnsupportedError);
      expect(
        () => Phase0aAttackTokenLeaseBatchPlan(
          enemyIntents: const <Phase0aIntent>[],
          mutations: _throwingMutations(),
        ),
        throwsStateError,
      );
    });

    test('prepared successor binds predecessor and commits once', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final gate = _acquireGate();
      final prepared = gate.prepare(runtime: runtime, enemyIntents: const []);

      expect(
        () => prepared.commit(AttackTokenLeaseRuntime.empty()),
        throwsStateError,
      );
      final successor = prepared.commit(runtime);
      expect(successor.snapshot.revision, 1);
      expect(successor.snapshot.activeLeases.values.single.request.priority, 7);
      expect(() => prepared.commit(runtime), throwsStateError);
      expect(runtime.snapshot.revision, 0);
    });

    test('empty mutations return exact predecessor without revision churn', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final gate = _gate(
        ({
          required AttackTokenLeaseSnapshot leaseSnapshot,
          required List<Phase0aIntent> enemyIntents,
        }) => Phase0aAttackTokenLeaseBatchPlan(
          enemyIntents: enemyIntents,
          mutations: const [],
        ),
      );
      final prepared = gate.prepare(runtime: runtime, enemyIntents: const []);

      expect(prepared.commit(runtime), same(runtime));
      expect(runtime.snapshot.revision, 0);
      expect(() => prepared.commit(runtime), throwsStateError);
    });
  });

  group('session transactional wiring', () {
    test('constructor requires a pair and rejects a second batch gate', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final gate = _acquireGate();

      expect(() => _session(leaseGate: gate), throwsArgumentError);
      expect(() => _session(leaseRuntime: runtime), throwsArgumentError);
      expect(
        () => _session(
          leaseGate: gate,
          leaseRuntime: runtime,
          statelessGate: _PassBatchGate(),
        ),
        throwsArgumentError,
      );
    });

    test('explicit acquire and release publish with arena and diagnostic', () {
      final observer = _Observer();
      final runtime = AttackTokenLeaseRuntime.empty();
      final initialSnapshot = runtime.snapshot;
      final session = _session(
        observer: observer,
        leaseGate: _acquireGate(releaseWhenActive: true),
        leaseRuntime: runtime,
      );

      session.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());
      final acquired = session.attackTokenLeaseSnapshot!;
      final acquireReceipt = session.lastAttackTokenLeaseBatchReceipt!;
      expect(session.state.tick, 1);
      expect(acquired.revision, 1);
      expect(acquireReceipt.before, same(initialSnapshot));
      expect(acquireReceipt.after, same(acquired));
      expect(acquireReceipt.mutations, hasLength(1));
      final acquire = acquireReceipt.mutations.single;
      expect(acquire, isA<AcquireAttackTokenLease>());
      expect((acquire as AcquireAttackTokenLease).lease.request.actorId, 'e1');
      final request = acquired.activeLeases.values.single.request;
      expect(request.actorId, 'e1');
      expect(request.kind, AttackTokenKind.melee);
      expect(request.priority, 7);
      expect(request.isHighImpact, isTrue);
      expect(session.lastEnemyIntentObservation, isNotNull);

      session.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());
      final released = session.attackTokenLeaseSnapshot!;
      final releaseReceipt = session.lastAttackTokenLeaseBatchReceipt!;
      expect(session.state.tick, 2);
      expect(released.revision, 2);
      expect(released.activeLeases, isEmpty);
      expect(releaseReceipt, isNot(same(acquireReceipt)));
      expect(releaseReceipt.before, same(acquired));
      expect(releaseReceipt.after, same(released));
      expect(releaseReceipt.mutations.single, isA<ReleaseAttackTokenLease>());
      expect(observer.observations, hasLength(2));
    });

    test('empty mutation batch preserves runtime and snapshot identity', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final beforeSnapshot = runtime.snapshot;
      final session = _session(
        leaseGate: _gate(
          ({
            required AttackTokenLeaseSnapshot leaseSnapshot,
            required List<Phase0aIntent> enemyIntents,
          }) => Phase0aAttackTokenLeaseBatchPlan(
            enemyIntents: enemyIntents,
            mutations: const [],
          ),
        ),
        leaseRuntime: runtime,
      );

      session.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());

      expect(session.attackTokenLeaseSnapshot, same(beforeSnapshot));
      expect(session.attackTokenLeaseSnapshot!.revision, 0);
      final firstReceipt = session.lastAttackTokenLeaseBatchReceipt!;
      expect(firstReceipt.before, same(beforeSnapshot));
      expect(firstReceipt.after, same(beforeSnapshot));
      expect(firstReceipt.mutations, isEmpty);

      session.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());
      final secondReceipt = session.lastAttackTokenLeaseBatchReceipt!;
      expect(secondReceipt, isNot(same(firstReceipt)));
      expect(secondReceipt.before, same(beforeSnapshot));
      expect(secondReceipt.after, same(beforeSnapshot));
      expect(session.attackTokenLeaseSnapshot, same(beforeSnapshot));
    });

    test('fork preserves immutable runtime while isolating publication', () {
      final runtime = AttackTokenLeaseRuntime.empty();
      final gate = _acquireGate();
      final original = _session(leaseGate: gate, leaseRuntime: runtime);
      final candidate = original.forkWithState(_state());

      expect(candidate.attackTokenLeaseBatchGate, same(gate));
      expect(candidate.attackTokenLeaseSnapshot, same(runtime.snapshot));
      expect(candidate.lastAttackTokenLeaseBatchReceipt, isNull);
      candidate.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(),
      );

      expect(original.state.tick, 0);
      expect(original.attackTokenLeaseSnapshot!.revision, 0);
      expect(original.lastAttackTokenLeaseBatchReceipt, isNull);
      expect(candidate.state.tick, 1);
      expect(candidate.attackTokenLeaseSnapshot!.revision, 1);
      final candidateReceipt = candidate.lastAttackTokenLeaseBatchReceipt!;
      final secondFork = candidate.forkWithState(_state());
      expect(
        secondFork.lastAttackTokenLeaseBatchReceipt,
        same(candidateReceipt),
      );

      secondFork.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(),
      );
      expect(
        secondFork.lastAttackTokenLeaseBatchReceipt,
        isNot(same(candidateReceipt)),
      );
      expect(
        candidate.lastAttackTokenLeaseBatchReceipt,
        same(candidateReceipt),
      );
    });

    test('planner receives immutable input and failure publishes nothing', () {
      final initial = _state();
      final runtime = AttackTokenLeaseRuntime.empty();
      final resolver = _DamageResolver();
      final observer = _Observer();
      final session = _session(
        initialState: initial,
        resolver: resolver,
        observer: observer,
        leaseGate: _gate(({
          required AttackTokenLeaseSnapshot leaseSnapshot,
          required List<Phase0aIntent> enemyIntents,
        }) {
          enemyIntents.clear();
          throw StateError('unreachable');
        }),
        leaseRuntime: runtime,
      );

      expect(
        () => session.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(),
        ),
        throwsUnsupportedError,
      );
      expect(session.state, same(initial));
      expect(session.attackTokenLeaseSnapshot, same(runtime.snapshot));
      expect(session.lastEnemyIntentObservation, isNull);
      expect(session.lastAttackTokenLeaseBatchReceipt, isNull);
      expect(observer.observations, isEmpty);
      expect(resolver.calls, 0);
    });

    test('R12a validation failure publishes nothing', () {
      final initial = _state();
      final runtime = AttackTokenLeaseRuntime.empty();
      final session = _session(
        initialState: initial,
        leaseGate: _gate(
          ({
            required AttackTokenLeaseSnapshot leaseSnapshot,
            required List<Phase0aIntent> enemyIntents,
          }) => Phase0aAttackTokenLeaseBatchPlan(
            enemyIntents: enemyIntents,
            mutations: [ReleaseAttackTokenLease(AttackTokenLeaseId('unknown'))],
          ),
        ),
        leaseRuntime: runtime,
      );

      expect(
        () => session.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(),
        ),
        throwsStateError,
      );
      expect(session.state, same(initial));
      expect(session.attackTokenLeaseSnapshot, same(runtime.snapshot));
      expect(session.lastAttackTokenLeaseBatchReceipt, isNull);
    });

    test(
      'injected duplicated and reordered intents fail before publication',
      () {
        final transforms = <List<Phase0aIntent> Function(List<Phase0aIntent>)>[
          (input) => [
            ...input,
            const Phase0aMoveIntent(
              actorId: 'injected',
              direction: ArenaVector(-1, 0),
            ),
          ],
          (input) => [input.first, input.first],
          (input) => input.reversed.toList(),
        ];

        for (final transform in transforms) {
          final initial = _state();
          final runtime = AttackTokenLeaseRuntime.empty();
          final observer = _Observer();
          final resolver = _DamageResolver();
          final session = _session(
            initialState: initial,
            resolver: resolver,
            observer: observer,
            leaseGate: _gate(
              ({
                required AttackTokenLeaseSnapshot leaseSnapshot,
                required List<Phase0aIntent> enemyIntents,
              }) => Phase0aAttackTokenLeaseBatchPlan(
                enemyIntents: transform(enemyIntents),
                mutations: [AcquireAttackTokenLease(_lease('lease_e1', 'e1'))],
              ),
            ),
            leaseRuntime: runtime,
          );

          expect(
            () => session.advance(
              deltaSeconds: 0.1,
              command: const Phase0aPlayerCommand(),
            ),
            throwsStateError,
          );
          expect(session.state, same(initial));
          expect(session.attackTokenLeaseSnapshot, same(runtime.snapshot));
          expect(session.lastEnemyIntentObservation, isNull);
          expect(session.lastAttackTokenLeaseBatchReceipt, isNull);
          expect(observer.observations, isEmpty);
          expect(resolver.calls, 0);
        }
      },
    );

    test('observer failure keeps all session-owned fields unpublished', () {
      final initial = _state();
      final runtime = AttackTokenLeaseRuntime.empty();
      final observer = _Observer(throwOnObserve: true);
      final resolver = _DamageResolver();
      final session = _session(
        initialState: initial,
        resolver: resolver,
        observer: observer,
        leaseGate: _acquireGate(),
        leaseRuntime: runtime,
      );

      expect(
        () => session.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(),
        ),
        throwsStateError,
      );
      expect(session.state, same(initial));
      expect(session.attackTokenLeaseSnapshot, same(runtime.snapshot));
      expect(session.lastEnemyIntentObservation, isNull);
      expect(session.lastAttackTokenLeaseBatchReceipt, isNull);
      expect(observer.observations, hasLength(1));
      expect(resolver.calls, 0);
    });

    test('reducer failure keeps arena lease and diagnostic unpublished', () {
      final initial = _state();
      final runtime = AttackTokenLeaseRuntime.empty();
      final observer = _Observer();
      final resolver = _DamageResolver(throwOnResolve: true);
      final session = _session(
        initialState: initial,
        resolver: resolver,
        observer: observer,
        leaseGate: _acquireGate(),
        leaseRuntime: runtime,
      );

      expect(
        () => session.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(),
        ),
        throwsStateError,
      );
      expect(session.state, same(initial));
      expect(session.attackTokenLeaseSnapshot, same(runtime.snapshot));
      expect(session.lastEnemyIntentObservation, isNull);
      expect(session.lastAttackTokenLeaseBatchReceipt, isNull);
      expect(observer.observations, hasLength(1));
      expect(resolver.calls, 1);
    });

    test(
      'every late failure preserves an exact previously published receipt',
      () {
        void verifySecondFailure({
          required Phase0aCombatSession session,
          void Function()? armFailure,
          double secondDeltaSeconds = 0.1,
          Matcher errorMatcher = const TypeMatcher<StateError>(),
        }) {
          session.advance(
            deltaSeconds: 0.1,
            command: const Phase0aPlayerCommand(),
          );
          final oldState = session.state;
          final oldSnapshot = session.attackTokenLeaseSnapshot!;
          final oldObservation = session.lastEnemyIntentObservation;
          final oldReceipt = session.lastAttackTokenLeaseBatchReceipt!;
          armFailure?.call();

          expect(
            () => session.advance(
              deltaSeconds: secondDeltaSeconds,
              command: const Phase0aPlayerCommand(),
            ),
            throwsA(errorMatcher),
          );
          expect(session.state, same(oldState));
          expect(session.attackTokenLeaseSnapshot, same(oldSnapshot));
          expect(session.lastEnemyIntentObservation, same(oldObservation));
          expect(session.lastAttackTokenLeaseBatchReceipt, same(oldReceipt));
        }

        var plannerCalls = 0;
        verifySecondFailure(
          session: _session(
            observer: _Observer(),
            leaseGate: _gate(({
              required AttackTokenLeaseSnapshot leaseSnapshot,
              required List<Phase0aIntent> enemyIntents,
            }) {
              plannerCalls++;
              if (plannerCalls > 1) throw StateError('planner failed');
              return Phase0aAttackTokenLeaseBatchPlan(
                enemyIntents: enemyIntents,
                mutations: [AcquireAttackTokenLease(_lease('lease_e1', 'e1'))],
              );
            }),
            leaseRuntime: AttackTokenLeaseRuntime.empty(),
          ),
        );

        var lazyCalls = 0;
        verifySecondFailure(
          session: _session(
            observer: _Observer(),
            leaseGate: _gate(({
              required AttackTokenLeaseSnapshot leaseSnapshot,
              required List<Phase0aIntent> enemyIntents,
            }) {
              lazyCalls++;
              return Phase0aAttackTokenLeaseBatchPlan(
                enemyIntents: enemyIntents,
                mutations: lazyCalls == 1
                    ? [AcquireAttackTokenLease(_lease('lease_e1', 'e1'))]
                    : _throwingMutations(),
              );
            }),
            leaseRuntime: AttackTokenLeaseRuntime.empty(),
          ),
        );

        verifySecondFailure(
          session: _session(
            observer: _Observer(),
            leaseGate: _gate(
              ({
                required AttackTokenLeaseSnapshot leaseSnapshot,
                required List<Phase0aIntent> enemyIntents,
              }) => Phase0aAttackTokenLeaseBatchPlan(
                enemyIntents: enemyIntents,
                mutations: leaseSnapshot.activeLeases.isEmpty
                    ? [AcquireAttackTokenLease(_lease('lease_e1', 'e1'))]
                    : [
                        ReleaseAttackTokenLease(
                          AttackTokenLeaseId('unknown_lease'),
                        ),
                      ],
              ),
            ),
            leaseRuntime: AttackTokenLeaseRuntime.empty(),
          ),
        );

        var outputCalls = 0;
        verifySecondFailure(
          session: _session(
            observer: _Observer(),
            leaseGate: _gate(({
              required AttackTokenLeaseSnapshot leaseSnapshot,
              required List<Phase0aIntent> enemyIntents,
            }) {
              outputCalls++;
              return Phase0aAttackTokenLeaseBatchPlan(
                enemyIntents: outputCalls == 1
                    ? enemyIntents
                    : [
                        ...enemyIntents,
                        const Phase0aMoveIntent(
                          actorId: 'injected',
                          direction: ArenaVector(-1, 0),
                        ),
                      ],
                mutations: leaseSnapshot.activeLeases.isEmpty
                    ? [AcquireAttackTokenLease(_lease('lease_e1', 'e1'))]
                    : [
                        ReleaseAttackTokenLease(
                          leaseSnapshot.activeLeases.keys.single,
                        ),
                      ],
              );
            }),
            leaseRuntime: AttackTokenLeaseRuntime.empty(),
          ),
        );

        final throwingObserver = _Observer();
        verifySecondFailure(
          session: _session(
            observer: throwingObserver,
            leaseGate: _acquireGate(releaseWhenActive: true),
            leaseRuntime: AttackTokenLeaseRuntime.empty(),
          ),
          armFailure: () => throwingObserver.throwOnObserve = true,
        );

        verifySecondFailure(
          session: _session(
            observer: _Observer(),
            leaseGate: _acquireGate(releaseWhenActive: true),
            leaseRuntime: AttackTokenLeaseRuntime.empty(),
          ),
          secondDeltaSeconds: -1,
          errorMatcher: isA<ArgumentError>(),
        );

        verifySecondFailure(
          session: _session(
            observer: _Observer(),
            leaseGate: _CommitFailOnSecondGate(),
            leaseRuntime: AttackTokenLeaseRuntime.empty(),
          ),
        );
      },
    );

    test('null legacy path remains lease-free', () {
      final session = _session();

      session.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());

      expect(session.attackTokenLeaseBatchGate, isNull);
      expect(session.attackTokenLeaseSnapshot, isNull);
      expect(session.lastAttackTokenLeaseBatchReceipt, isNull);
      expect(session.state.tick, 1);
    });
  });

  test('encounter outer rollback discards candidate lease publication', () {
    final seenSnapshots = <AttackTokenLeaseSnapshot>[];
    final gate = _gate(({
      required AttackTokenLeaseSnapshot leaseSnapshot,
      required List<Phase0aIntent> enemyIntents,
    }) {
      seenSnapshots.add(leaseSnapshot);
      return Phase0aAttackTokenLeaseBatchPlan(
        enemyIntents: enemyIntents,
        mutations: leaseSnapshot.activeLeases.isEmpty
            ? [AcquireAttackTokenLease(_lease('lease_e1', 'e1'))]
            : const [],
      );
    });
    final director = SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: 1,
        reinforcementThreshold: 0,
        entryWarningTicks: 0,
        attackGraceTicks: 0,
      ),
      entries: [SpawnEntry(entryId: 'entry_e1', enemyId: 'e1')],
    );
    final roster = Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        Phase0aEncounterRosterBinding(
          entryId: 'entry_e1',
          actor: _actor(id: 'e1', side: Phase0aSide.enemy, x: 50),
        ),
      ],
    );
    final source = _ThrowOnceObjectiveSource();
    final flow = Phase0aEncounterFlow.runtime(
      session: _session(
        initialState: Phase0aArenaState(
          tick: 0,
          nextSeq: 1,
          player: _actor(id: 'player', side: Phase0aSide.player, x: 0),
          enemies: const [],
          skillSlots: const [],
        ),
        leaseGate: gate,
        leaseRuntime: AttackTokenLeaseRuntime.empty(),
      ),
      director: director,
      roster: roster,
      objectiveTracker: Phase0aObjectiveRuntimeTracker(
        controller: ObjectiveController(
          completionRule: ObjectiveCompletionRule.all,
          clauses: [
            ObjectiveClause(
              id: 'never_complete',
              objective: DefeatTargetsObjective(const {'never'}),
            ),
          ],
        ),
      ),
      objectiveEventSource: source,
    );

    expect(
      () => flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(),
      ),
      throwsStateError,
    );
    expect(flow.state.tick, 0);
    expect(flow.spawnState.tick, 0);
    expect(flow.outcome, Phase0aBattleOutcome.ongoing);

    flow.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());
    flow.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());

    expect(seenSnapshots.map((snapshot) => snapshot.revision), [0, 0, 1]);
    expect(seenSnapshots.map((snapshot) => snapshot.activeLeases.length), [
      0,
      0,
      1,
    ]);
    expect(flow.state.tick, 2);
    expect(flow.spawnState.tick, 2);
  });

  test('source guard keeps lifecycle inference and production wiring out', () {
    final receiptSource = File(
      'lib/features/battle/application/phase0a/'
      'phase0a_attack_token_lease_batch_receipt.dart',
    ).readAsStringSync();
    final gateSource = File(
      'lib/features/battle/application/phase0a/'
      'phase0a_attack_token_lease_batch_gate.dart',
    ).readAsStringSync();
    final sessionSource = File(
      'lib/features/battle/application/phase0a/phase0a_combat_session.dart',
    ).readAsStringSync();
    final addedSessionSlice = sessionSource.substring(
      sessionSource.indexOf('attackTokenLeaseBatchGate'),
    );

    expect(
      RegExp(
        r"^import '../../domain/phase0a/attack_token_lease_runtime.dart';$",
        multiLine: true,
      ).allMatches(receiptSource),
      hasLength(1),
    );
    expect(
      RegExp(r'^import ', multiLine: true).allMatches(receiptSource),
      hasLength(1),
    );
    expect(
      sessionSource,
      contains("import 'phase0a_attack_token_lease_batch_receipt.dart';"),
    );
    expect(
      RegExp(
        r'final class Phase0aAttackTokenLeaseBatchReceipt',
      ).allMatches(receiptSource),
      hasLength(1),
    );

    final commitIndex = sessionSource.indexOf('preparedLeaseBatch?.commit(');
    final receiptConstructionIndex = sessionSource.indexOf(
      'Phase0aAttackTokenLeaseBatchReceipt(',
    );
    final statePublicationIndex = sessionSource.indexOf(
      '_state = result.state;',
    );
    final runtimePublicationIndex = sessionSource.indexOf(
      '_attackTokenLeaseRuntime = nextLeaseRuntime;',
    );
    final diagnosticPublicationIndex = sessionSource.indexOf(
      '_lastEnemyIntentObservation = nextObservation;',
    );
    final receiptPublicationIndex = sessionSource.indexOf(
      '_lastAttackTokenLeaseBatchReceipt = nextLeaseReceipt;',
    );
    for (final index in [
      commitIndex,
      receiptConstructionIndex,
      statePublicationIndex,
      runtimePublicationIndex,
      diagnosticPublicationIndex,
      receiptPublicationIndex,
    ]) {
      expect(index, greaterThanOrEqualTo(0));
    }
    expect(commitIndex, lessThan(receiptConstructionIndex));
    expect(receiptConstructionIndex, lessThan(statePublicationIndex));
    expect(statePublicationIndex, lessThan(runtimePublicationIndex));
    expect(runtimePublicationIndex, lessThan(diagnosticPublicationIndex));
    expect(diagnosticPublicationIndex, lessThan(receiptPublicationIndex));
    expect(
      sessionSource,
      contains(
        'lastAttackTokenLeaseBatchReceipt: '
        '_lastAttackTokenLeaseBatchReceipt',
      ),
    );

    for (final source in [receiptSource, gateSource, addedSessionSlice]) {
      for (final forbidden in const [
        'ActionTimeline',
        'rootBundle',
        'GameRepository',
        'tuning',
        'capacity',
        'budget',
        'default',
        'durable',
        'outbox',
        'persist',
        'repository',
        'package:isar',
        'SaveData',
        '@collection',
        'schema',
        'CAS',
        ' UI',
        'host',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
      }
    }
    for (final forbidden in const [
      'Phase0aHitLanded',
      'Phase0aEnemyDefeated',
      'cooldown marker',
      'actor disappearance',
    ]) {
      expect(gateSource, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
