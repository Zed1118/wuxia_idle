import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/attack_token_observe_only_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

/// P2-G2-D04 observe-only 接缝红测:
/// observer 只读、不能影响 reducer 输入;全拒绝时 reducer 仍消费原始
/// enemy intents;default vs observe 完全等价;actorId mismatch 在
/// reducer 前 fail closed;mapper 返回 null = 调用方明确标记非候选。

class CountingDamageResolver implements Phase0aDamageResolver {
  int calls = 0;
  final List<
    ({
      String attackerId,
      String targetId,
      Phase0aDamageKind kind,
      bool defenderStaggered,
      bool defenderCharging,
      double defenderWardMult,
    })
  >
  transcript = [];

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
    transcript.add((
      attackerId: attackerId,
      targetId: targetId,
      kind: kind,
      defenderStaggered: defenderStaggered,
      defenderCharging: defenderCharging,
      defenderWardMult: defenderWardMult,
    ));
    return const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 15);
  }
}

class CapturingObserver implements Phase0aEnemyIntentObserver {
  final List<Phase0aEnemyIntentObservation> observations = [];

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    observations.add(observation);
  }
}

Phase0aActor makePlayer() {
  return const Phase0aActor(
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
}

Phase0aActor makeEnemy({required String id, required ArenaVector position}) {
  return Phase0aActor(
    id: id,
    side: Phase0aSide.enemy,
    position: position,
    facing: const ArenaVector(-1, 0),
    maxHealth: 60,
    currentHealth: 60,
    moveSpeed: 60,
    qiCurrent: 0,
    qiMax: 0,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  );
}

Phase0aArenaState makeState({List<Phase0aActor>? enemies}) {
  return Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: makePlayer(),
    enemies: enemies ?? const [],
    skillSlots: const [
      Phase0aSkillSlot(
        slot: 'gather',
        cooldownRemaining: 0,
        qiCost: 20,
        availability: Phase0aSkillAvailability.ready,
      ),
      Phase0aSkillSlot(
        slot: 'clear',
        cooldownRemaining: 0,
        qiCost: 30,
        availability: Phase0aSkillAvailability.ready,
      ),
    ],
  );
}

Phase0aCombatSession makeSession({
  required Phase0aArenaState initialState,
  CountingDamageResolver? resolver,
  Phase0aEnemyIntentObserver? observer,
}) {
  return Phase0aCombatSession(
    initialState: initialState,
    playerAdapter: const Phase0aPlayerInputAdapter(
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
    ),
    enemyAiAdapter: const Phase0aEnemyAiAdapter(
      attackRange: 70,
      attackHalfArcRadians: math.pi / 3,
      attackCooldownSeconds: 1.2,
    ),
    damageResolver: resolver ?? CountingDamageResolver(),
    enemyIntentObserver: observer,
  );
}

AttackTokenObserveOnlyObserver makeObserveOnlyObserver({
  AttackTokenBudgets? budgets,
  AttackTokenRequest? Function(Phase0aIntent intent)? requestMapper,
}) {
  return AttackTokenObserveOnlyObserver(
    director: const AttackTokenDirector(),
    budgets:
        budgets ??
        AttackTokenBudgets(melee: 0, ranged: 0, charge: 0, support: 0),
    requestMapper:
        requestMapper ??
        ((intent) => intent is Phase0aAttackIntent
            ? AttackTokenRequest(
                actorId: intent.actorId,
                kind: AttackTokenKind.melee,
                priority: 0,
                isOffscreen: false,
                isHighImpact: false,
                isUnblockableArea: false,
                spawnGraceTicksRemaining: 0,
                telegraphReady: true,
              )
            : null),
  );
}

void main() {
  group('observe-only 接缝只读边界', () {
    test('observer 收到的是不可修改副本,且不能返回替换 intents', () {
      final capturing = CapturingObserver();
      final session = makeSession(
        initialState: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
        observer: capturing,
      );
      session.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      final observation = capturing.observations.single;
      expect(observation.tick, 0);
      expect(observation.enemyIntents, hasLength(1));
      expect(observation.enemyIntents.single.actorId, 'e1');
      expect(observation.enemyIntents.single, isA<Phase0aAttackIntent>());
      expect(
        () => observation.enemyIntents.add(
          const Phase0aMoveIntent(actorId: 'e1', direction: ArenaVector(1, 0)),
        ),
        throwsUnsupportedError,
      );
      expect(session.lastEnemyIntentObservation, same(observation));
    });

    test('allocation 全拒绝时 reducer 仍消费原始双方 intents', () {
      final observer = makeObserveOnlyObserver();
      final session = makeSession(
        initialState: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
        observer: observer,
      );
      final events = session.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      final allocation = observer.lastAllocation;
      expect(allocation, isNotNull);
      expect(allocation!.grantedCount, 0);
      expect(
        allocation.decisions.single.denial,
        AttackTokenDenial.budgetExhausted,
      );

      final hits = events.whereType<Phase0aHitLanded>().toList();
      expect(hits.map((h) => h.actor).toSet(), {'player', 'e1'});
      expect(session.state.player.currentHealth, 85);
    });

    test('default vs observe 同初态同命令:state/events/nextSeq/resolver 调用相等', () {
      Phase0aArenaState initial() => makeState(
        enemies: [
          makeEnemy(id: 'e1', position: const ArenaVector(60, 20)),
          makeEnemy(id: 'e2', position: const ArenaVector(240, -40)),
        ],
      );
      const commands = [
        Phase0aPlayerCommand(right: true),
        Phase0aPlayerCommand(right: true, attack: true),
        Phase0aPlayerCommand(attack: true),
        Phase0aPlayerCommand(gather: true),
        Phase0aPlayerCommand(),
        Phase0aPlayerCommand(clear: true),
      ];
      final resolverA = CountingDamageResolver();
      final resolverB = CountingDamageResolver();
      final observer = makeObserveOnlyObserver();
      final sessionA = makeSession(
        initialState: initial(),
        resolver: resolverA,
      );
      final sessionB = makeSession(
        initialState: initial(),
        resolver: resolverB,
        observer: observer,
      );

      List<Phase0aEvent> run(Phase0aCombatSession session) {
        final all = <Phase0aEvent>[];
        for (final command in commands) {
          all.addAll(session.advance(deltaSeconds: 0.2, command: command));
        }
        return all;
      }

      final eventsA = run(sessionA);
      final eventsB = run(sessionB);
      expect(observer.lastAllocation, isNotNull);
      expect(eventsB, eventsA);
      expect(eventsA, isNotEmpty);
      expect(sessionB.state, sessionA.state);
      expect(sessionB.state.nextSeq, sessionA.state.nextSeq);
      expect(resolverB.calls, resolverA.calls);
      expect(resolverB.transcript, resolverA.transcript);
    });

    test('request actorId 与 intent.actorId 不一致时 reducer 前 fail closed', () {
      final resolver = CountingDamageResolver();
      final observer = makeObserveOnlyObserver(
        requestMapper: (intent) => AttackTokenRequest(
          actorId: 'wrong-actor',
          kind: AttackTokenKind.melee,
          priority: 0,
          isOffscreen: false,
          isHighImpact: false,
          isUnblockableArea: false,
          spawnGraceTicksRemaining: 0,
          telegraphReady: true,
        ),
      );
      final initial = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
      );
      final session = makeSession(
        initialState: initial,
        resolver: resolver,
        observer: observer,
      );
      expect(
        () => session.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(attack: true),
        ),
        throwsArgumentError,
      );
      expect(resolver.calls, 0);
      expect(observer.lastAllocation, isNull);
      expect(session.lastEnemyIntentObservation, isNull);
      expect(session.state, initial);
      expect(session.state, same(initial));
    });

    test('成功后的下一拍观察失败不污染已提交诊断', () {
      var fail = false;
      final observer = makeObserveOnlyObserver(
        requestMapper: (intent) => AttackTokenRequest(
          actorId: fail ? 'wrong-actor' : intent.actorId,
          kind: AttackTokenKind.melee,
          priority: 0,
          isOffscreen: false,
          isHighImpact: false,
          isUnblockableArea: false,
          spawnGraceTicksRemaining: 0,
          telegraphReady: true,
        ),
      );
      final session = makeSession(
        initialState: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
        observer: observer,
      );
      session.advance(deltaSeconds: 0.1, command: const Phase0aPlayerCommand());
      final committedState = session.state;
      final committedObservation = session.lastEnemyIntentObservation;
      final committedAllocation = observer.lastAllocation;

      fail = true;
      expect(
        () => session.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(),
        ),
        throwsArgumentError,
      );
      expect(session.state, same(committedState));
      expect(session.lastEnemyIntentObservation, same(committedObservation));
      expect(observer.lastAllocation, same(committedAllocation));
    });

    test('mapper 返回 null = 调用方明确标记非候选,不报错也不进批', () {
      final observer = makeObserveOnlyObserver(requestMapper: (intent) => null);
      final session = makeSession(
        initialState: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
        observer: observer,
      );
      final events = session.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(observer.lastAllocation, isNotNull);
      expect(observer.lastAllocation!.decisions, isEmpty);
      expect(events.whereType<Phase0aHitLanded>(), isNotEmpty);
    });

    test('observer 为 null 时不构造 observation/budget/request,不调 director', () {
      final session = makeSession(
        initialState: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
      );
      session.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(session.lastEnemyIntentObservation, isNull);
    });
  });

  group('session 源码合同', () {
    test('session 只接显式 lease 合同且不引用 director 或推断事实', () {
      final source = File(
        'lib/features/battle/application/phase0a/phase0a_combat_session.dart',
      ).readAsStringSync();
      expect(source, contains('Phase0aAttackTokenLeaseBatchGate'));
      expect(source.contains('AttackTokenDirector'), isFalse);
      expect(source.contains('attack_token_director.dart'), isFalse);
      expect(source.contains('offscreen'), isFalse);
      expect(source.contains('telegraph'), isFalse);
    });
  });
}
