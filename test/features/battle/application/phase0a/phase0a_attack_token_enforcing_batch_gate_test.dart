import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/attack_token_enforcing_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

final class _CountingDamageResolver implements Phase0aDamageResolver {
  int calls = 0;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1.0,
  }) {
    calls++;
    return const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 15);
  }
}

final class _CapturingObserver implements Phase0aEnemyIntentObserver {
  final List<Phase0aEnemyIntentObservation> observations = [];

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    observations.add(observation);
  }
}

typedef _BatchTransform =
    List<Phase0aIntent> Function(List<Phase0aIntent> enemyIntents);

final class _FunctionalBatchGate implements Phase0aEnemyIntentBatchGate {
  _FunctionalBatchGate(this.transform);

  final _BatchTransform transform;
  int calls = 0;

  @override
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) {
    calls++;
    return transform(enemyIntents);
  }
}

Phase0aAttackIntent _attack(String actorId) => Phase0aAttackIntent(
  actorId: actorId,
  range: 70,
  halfArcRadians: math.pi / 3,
  cooldownSeconds: 1.2,
  moveKind: Phase0aMoveKind.light,
  aimDirection: const ArenaVector(-1, 0),
  qiDelta: 0,
  postureDamage: 0,
  postureHitKind: PostureHitKind.light,
);

Phase0aMoveIntent _move(String actorId) =>
    Phase0aMoveIntent(actorId: actorId, direction: const ArenaVector(-1, 0));

AttackTokenRequest _request(Phase0aIntent intent, {int priority = 0}) =>
    AttackTokenRequest(
      actorId: intent.actorId,
      kind: AttackTokenKind.melee,
      priority: priority,
      isOffscreen: false,
      isHighImpact: false,
      isUnblockableArea: false,
      spawnGraceTicksRemaining: 0,
      telegraphReady: true,
    );

AttackTokenBudgets _budgets({int melee = 1}) =>
    AttackTokenBudgets(melee: melee, ranged: 0, charge: 0, support: 0);

Phase0aActor _player() => const Phase0aActor(
  id: 'player',
  side: Phase0aSide.player,
  position: ArenaVector(0, 0),
  facing: ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 100,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aActor _enemy(String id, double x) => Phase0aActor(
  id: id,
  side: Phase0aSide.enemy,
  position: ArenaVector(x, 0),
  facing: const ArenaVector(-1, 0),
  maxHealth: 60,
  currentHealth: 60,
  moveSpeed: 60,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aArenaState _state() => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: _player(),
  enemies: [_enemy('e1', 50), _enemy('e2', 300)],
  skillSlots: const [],
);

Phase0aCombatSession _session({
  required Phase0aArenaState initialState,
  required _CountingDamageResolver resolver,
  Phase0aEnemyIntentGate? perIntentGate,
  Phase0aEnemyIntentBatchGate? batchGate,
  Phase0aEnemyIntentObserver? observer,
}) => Phase0aCombatSession(
  initialState: initialState,
  playerAdapter: const Phase0aPlayerInputAdapter(
    playerId: 'player',
    attackRange: 120,
    attackHalfArcRadians: math.pi / 4,
    attackCooldownSeconds: 1,
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
  ),
  enemyAiAdapter: const Phase0aEnemyAiAdapter(
    attackRange: 70,
    attackHalfArcRadians: math.pi / 3,
    attackCooldownSeconds: 1.2,
    postureBasicPowerMultiplier: 1,
    uniformBasicPowerMultiplier: 1,
  ),
  damageResolver: resolver,
  enemyIntentGate: perIntentGate,
  enemyIntentBatchGate: batchGate,
  enemyIntentObserver: observer,
);

void main() {
  group('AttackTokenEnforcingBatchGate', () {
    test('denied token 过滤,granted 与非 token 保持原 identity 顺序', () {
      final denied = _attack('e1');
      final movement = _move('e3');
      final granted = _attack('e2');
      final gate = AttackTokenEnforcingBatchGate(
        director: const AttackTokenDirector(),
        budgets: _budgets(),
        requestMapper: (intent) => switch (intent.actorId) {
          'e1' => _request(intent, priority: 1),
          'e2' => _request(intent, priority: 2),
          _ => null,
        },
      );

      final output = gate.gateEnemyIntents(
        enemyIntents: [denied, movement, granted],
      );

      expect(output, hasLength(2));
      expect(output[0], same(movement));
      expect(output[1], same(granted));
      expect(output, isNot(contains(same(denied))));
      expect(() => output.add(_move('e9')), throwsUnsupportedError);
    });

    test('mapper null 的移动原样放行,同 actor 被拒攻击被过滤', () {
      final movement = _move('e1');
      final attack = _attack('e1');
      final gate = AttackTokenEnforcingBatchGate(
        director: const AttackTokenDirector(),
        budgets: _budgets(melee: 0),
        requestMapper: (intent) =>
            intent is Phase0aAttackIntent ? _request(intent) : null,
      );

      final output = gate.gateEnemyIntents(enemyIntents: [movement, attack]);

      expect(output, hasLength(1));
      expect(output.single, same(movement));
    });

    test('request actorId mismatch 在 director 前 fail closed', () {
      final gate = AttackTokenEnforcingBatchGate(
        director: const AttackTokenDirector(),
        budgets: _budgets(),
        requestMapper: (intent) => AttackTokenRequest(
          actorId: 'wrong',
          kind: AttackTokenKind.melee,
          priority: 0,
          isOffscreen: false,
          isHighImpact: false,
          isUnblockableArea: false,
          spawnGraceTicksRemaining: 0,
          telegraphReady: true,
        ),
      );

      expect(
        () => gate.gateEnemyIntents(enemyIntents: [_attack('e1')]),
        throwsArgumentError,
      );
    });

    test('同 actor 的重复 token request 由 director fail closed', () {
      final gate = AttackTokenEnforcingBatchGate(
        director: const AttackTokenDirector(),
        budgets: _budgets(),
        requestMapper: _request,
      );

      expect(
        () =>
            gate.gateEnemyIntents(enemyIntents: [_attack('e1'), _attack('e1')]),
        throwsArgumentError,
      );
    });

    test('mapper 异常原样传播且不产生部分输出', () {
      final gate = AttackTokenEnforcingBatchGate(
        director: const AttackTokenDirector(),
        budgets: _budgets(),
        requestMapper: (intent) => throw StateError('mapper failed'),
      );

      expect(
        () => gate.gateEnemyIntents(enemyIntents: [_attack('e1')]),
        throwsStateError,
      );
    });
  });

  group('CombatSession batch gate 合同', () {
    test('null batch gate 与基线 state/events/resolver 完全一致', () {
      final resolverA = _CountingDamageResolver();
      final resolverB = _CountingDamageResolver();
      final baseline = _session(initialState: _state(), resolver: resolverA);
      final explicitNull = _session(
        initialState: _state(),
        resolver: resolverB,
        batchGate: null,
      );

      final eventsA = baseline.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      final eventsB = explicitNull.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );

      expect(eventsB, eventsA);
      expect(explicitNull.state, baseline.state);
      expect(resolverB.calls, resolverA.calls);
    });

    test('逐 intent gate 先于 batch gate,observer 只观察最终执行列表', () {
      final observer = _CapturingObserver();
      final batchInputs = <List<Phase0aIntent>>[];
      final batchGate = _FunctionalBatchGate((enemyIntents) {
        batchInputs.add(enemyIntents);
        return <Phase0aIntent>[...enemyIntents.whereType<Phase0aMoveIntent>()];
      });
      final session = _session(
        initialState: _state(),
        resolver: _CountingDamageResolver(),
        perIntentGate: Phase0aSpawnGraceIntentGate(canAttackActorIds: const {}),
        batchGate: batchGate,
        observer: observer,
      );

      session.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());

      expect(batchInputs.single, hasLength(1));
      expect(batchInputs.single.single, isA<Phase0aMoveIntent>());
      expect(observer.observations.single.enemyIntents, hasLength(1));
      expect(
        observer.observations.single.enemyIntents.single,
        same(batchInputs.single.single),
      );
      expect(session.state.player.currentHealth, 100);
    });

    test('AttackToken 真实执行 gate 拦下攻击,observer 仅见放行移动', () {
      final observer = _CapturingObserver();
      final resolver = _CountingDamageResolver();
      final session = _session(
        initialState: _state(),
        resolver: resolver,
        batchGate: AttackTokenEnforcingBatchGate(
          director: const AttackTokenDirector(),
          budgets: _budgets(melee: 0),
          requestMapper: (intent) =>
              intent is Phase0aAttackIntent ? _request(intent) : null,
        ),
        observer: observer,
      );

      session.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());

      expect(session.state.player.currentHealth, 100);
      expect(resolver.calls, 0);
      final observed = observer.observations.single.enemyIntents;
      expect(observed, hasLength(1));
      expect(observed.single.actorId, 'e2');
      expect(observed.single, isA<Phase0aMoveIntent>());
      expect(session.state.enemies.last.position.x, lessThan(300));
    });

    test('batch gate 收到不可修改的单次物化输入', () {
      final gate = _FunctionalBatchGate((enemyIntents) {
        enemyIntents.add(_move('injected'));
        return enemyIntents;
      });
      final initial = _state();
      final resolver = _CountingDamageResolver();
      final session = _session(
        initialState: initial,
        resolver: resolver,
        batchGate: gate,
      );

      expect(
        () => session.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(),
        ),
        throwsUnsupportedError,
      );
      expect(session.state, same(initial));
      expect(resolver.calls, 0);
    });

    test('batch gate 异常不调 observer/reducer,不推进 state/diagnostic', () {
      final gate = _FunctionalBatchGate(
        (enemyIntents) => throw StateError('gate failed'),
      );
      final initial = _state();
      final resolver = _CountingDamageResolver();
      final observer = _CapturingObserver();
      final session = _session(
        initialState: initial,
        resolver: resolver,
        batchGate: gate,
        observer: observer,
      );

      expect(
        () => session.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(attack: true),
        ),
        throwsStateError,
      );
      expect(session.state, same(initial));
      expect(session.lastEnemyIntentObservation, isNull);
      expect(observer.observations, isEmpty);
      expect(resolver.calls, 0);
    });

    test('成功后下一拍非法输出不污染已提交 diagnostic/state', () {
      var fail = false;
      final gate = _FunctionalBatchGate((enemyIntents) {
        if (!fail) return enemyIntents;
        return [_move('injected')];
      });
      final observer = _CapturingObserver();
      final session = _session(
        initialState: _state(),
        resolver: _CountingDamageResolver(),
        batchGate: gate,
        observer: observer,
      );
      session.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());
      final committedState = session.state;
      final committedObservation = session.lastEnemyIntentObservation;

      fail = true;
      expect(
        () => session.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(),
        ),
        throwsStateError,
      );
      expect(session.state, same(committedState));
      expect(session.lastEnemyIntentObservation, same(committedObservation));
      expect(observer.observations, hasLength(1));
    });

    test('禁止注入、替换、重复与重排', () {
      final cases = <String, _BatchTransform>{
        'inject': (input) => [...input, _move('injected')],
        'replace': (input) => [_move(input.first.actorId), ...input.skip(1)],
        'duplicate': (input) => [input.first, input.first],
        'reorder': (input) => input.reversed.toList(),
      };

      for (final entry in cases.entries) {
        final initial = _state();
        final resolver = _CountingDamageResolver();
        final observer = _CapturingObserver();
        final session = _session(
          initialState: initial,
          resolver: resolver,
          batchGate: _FunctionalBatchGate(entry.value),
          observer: observer,
        );

        expect(
          () => session.advance(
            deltaSeconds: 0.1,
            command: const Phase0aPlayerCommand(),
          ),
          throwsStateError,
          reason: entry.key,
        );
        expect(session.state, same(initial), reason: entry.key);
        expect(observer.observations, isEmpty, reason: entry.key);
        expect(resolver.calls, 0, reason: entry.key);
      }
    });
  });
}
