import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';

/// P2-G2-D05 session 安全接缝红测:
/// ① forkWithState 依赖 identity 逐项保留、state 精确替换、零副作用;
/// ② 无 gate 路径与基线完全一致(observer 观察原始 intents);
/// ③ grace gate 冻结语义:集合内放行、集合外仅 move 放行其余 fail closed、
///   防御性复制、不改原列表、输出不可修改、到期恢复全部原 intent;
/// ④ observer 只观察 gate 筛选后最终交给 reducer 的列表;
/// ⑤ wave 换波前后 observer 持续观察且 gate 全程生效(回归修复)。

class CountingDamageResolver implements Phase0aDamageResolver {
  CountingDamageResolver({this.damage = 15});

  final int damage;
  int calls = 0;
  final List<
    ({
      String attackerId,
      String targetId,
      Phase0aDamageKind kind,
      bool defenderStaggered,
      bool defenderVulnerable,
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
    bool defenderVulnerable = false,
    double defenderWardMult = 1.0,
  }) {
    calls++;
    transcript.add((
      attackerId: attackerId,
      targetId: targetId,
      kind: kind,
      defenderStaggered: defenderStaggered,
      defenderVulnerable: defenderVulnerable,
      defenderWardMult: defenderWardMult,
    ));
    return Phase0aResolvedHit(isHit: true, isCritical: false, damage: damage);
  }
}

class FixedEnemySkillResolver implements Phase0aEnemySkillDamageResolver {
  @override
  Phase0aResolvedHit resolveEnemySkill({
    required String attackerId,
    required String targetId,
    required SkillDef skill,
    bool defenderStaggered = false,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 15);
}

class CapturingObserver implements Phase0aEnemyIntentObserver {
  final List<Phase0aEnemyIntentObservation> observations = [];

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    observations.add(observation);
  }
}

class PassThroughBatchGate implements Phase0aEnemyIntentBatchGate {
  int calls = 0;

  @override
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) {
    calls++;
    return enemyIntents;
  }
}

const basicSkill = SkillDef(
  id: 'phase0a_test_basic',
  name: 'basic',
  description: 'basic',
  type: SkillType.normalAttack,
  powerMultiplier: 500,
  qiDelta: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
);

const attackE1 = Phase0aAttackIntent(
  actorId: 'e1',
  range: 70,
  halfArcRadians: math.pi / 3,
  cooldownSeconds: 1.2,
  moveKind: Phase0aMoveKind.light,
  aimDirection: ArenaVector(-1, 0),
  qiDelta: 0,
  postureDamage: 0,
  postureHitKind: PostureHitKind.light,
);

const moveE2 = Phase0aMoveIntent(actorId: 'e2', direction: ArenaVector(-1, 0));

const attackE2 = Phase0aAttackIntent(
  actorId: 'e2',
  range: 70,
  halfArcRadians: math.pi / 3,
  cooldownSeconds: 1.2,
  moveKind: Phase0aMoveKind.light,
  aimDirection: ArenaVector(-1, 0),
  qiDelta: 0,
  postureDamage: 0,
  postureHitKind: PostureHitKind.light,
);

const enemySkillE2 = Phase0aEnemySkillIntent(
  actorId: 'e2',
  skill: basicSkill,
  aimDirection: ArenaVector(-1, 0),
  range: 70,
  halfArcRadians: math.pi / 3,
  effectRadius: 60,
  cooldownSeconds: 2,
  actionCooldownSeconds: 1.2,
  postureDamage: 0,
  postureHitKind: PostureHitKind.heavy,
);

Phase0aActor makePlayer({int currentHealth = 100}) {
  return Phase0aActor(
    id: 'player',
    side: Phase0aSide.player,
    position: const ArenaVector(0, 0),
    facing: const ArenaVector(1, 0),
    maxHealth: 100,
    currentHealth: currentHealth,
    moveSpeed: 100,
    qiCurrent: 100,
    qiMax: 100,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  );
}

Phase0aActor makeEnemy({
  required String id,
  required ArenaVector position,
  int currentHealth = 60,
}) {
  return Phase0aActor(
    id: id,
    side: Phase0aSide.enemy,
    position: position,
    facing: const ArenaVector(-1, 0),
    maxHealth: 60,
    currentHealth: currentHealth,
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

Phase0aPlayerInputAdapter makePlayerAdapter() {
  return const Phase0aPlayerInputAdapter(
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
  );
}

Phase0aEnemyAiAdapter makeEnemyAdapter() {
  return const Phase0aEnemyAiAdapter(
    attackRange: 70,
    attackHalfArcRadians: math.pi / 3,
    attackCooldownSeconds: 1.2,
    postureBasicPowerMultiplier: 1,
    uniformBasicPowerMultiplier: 1,
  );
}

Phase0aCombatSession makeSession({
  Phase0aArenaState? initialState,
  CountingDamageResolver? resolver,
  Phase0aEnemySkillDamageResolver? skillResolver,
  CapturingObserver? observer,
  Phase0aEnemyIntentGate? gate,
  Phase0aEnemyIntentBatchGate? batchGate,
}) {
  return Phase0aCombatSession(
    initialState: initialState ?? makeState(),
    playerAdapter: makePlayerAdapter(),
    enemyAiAdapter: makeEnemyAdapter(),
    damageResolver: resolver ?? CountingDamageResolver(),
    enemySkillDamageResolver: skillResolver,
    enemyIntentObserver: observer,
    enemyIntentGate: gate,
    enemyIntentBatchGate: batchGate,
  );
}

Phase0aWaveBattleFlow makeFlow({
  required Phase0aArenaState initialState,
  required List<Phase0aWave> waves,
  CountingDamageResolver? resolver,
  CapturingObserver? observer,
  Phase0aEnemyIntentGate? gate,
  Phase0aEnemyIntentBatchGate? batchGate,
}) {
  return Phase0aWaveBattleFlow(
    session: Phase0aCombatSession(
      initialState: initialState,
      playerAdapter: makePlayerAdapter(),
      enemyAiAdapter: makeEnemyAdapter(),
      damageResolver: resolver ?? CountingDamageResolver(),
      enemyIntentObserver: observer,
      enemyIntentGate: gate,
      enemyIntentBatchGate: batchGate,
    ),
    waves: waves,
  );
}

void main() {
  group('forkWithState 安全接缝', () {
    test('依赖 identity 逐项保留,state 精确等于 nextState,零副作用', () {
      final playerAdapter = makePlayerAdapter();
      final enemyAdapter = makeEnemyAdapter();
      final resolver = CountingDamageResolver();
      final skillResolver = FixedEnemySkillResolver();
      final observer = CapturingObserver();
      final gate = Phase0aSpawnGraceIntentGate(canAttackActorIds: const {});
      final batchGate = PassThroughBatchGate();
      final originalState = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
      );
      final session = makeSession(
        initialState: originalState,
        resolver: resolver,
        skillResolver: skillResolver,
        observer: observer,
        gate: gate,
        batchGate: batchGate,
      );

      final nextState = makeState(
        enemies: [makeEnemy(id: 'e9', position: const ArenaVector(300, 0))],
      );
      final forked = session.forkWithState(nextState);

      expect(identical(forked.playerAdapter, playerAdapter), isTrue);
      expect(identical(forked.enemyAiAdapter, enemyAdapter), isTrue);
      expect(identical(forked.damageResolver, resolver), isTrue);
      expect(identical(forked.enemySkillDamageResolver, skillResolver), isTrue);
      expect(identical(forked.enemyIntentObserver, observer), isTrue);
      expect(identical(forked.enemyIntentGate, gate), isTrue);
      expect(identical(forked.enemyIntentBatchGate, batchGate), isTrue);
      expect(forked.state, nextState);
      expect(forked.state.tick, nextState.tick);
      expect(forked.state.nextSeq, nextState.nextSeq);
      expect(forked.lastEnemyIntentObservation, isNull);

      // fork 零副作用:原会话 state 不变、无事件、观察器未收到调用。
      expect(session.state, originalState);
      expect(observer.observations, isEmpty);

      // fork 出的候选会话可正常推进。
      final events = forked.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(events, isNotEmpty);
      expect(forked.state.tick, nextState.tick + 1);
      expect(observer.observations, hasLength(1));
    });

    test('可原子替换每拍 gate 且保留其他依赖 identity', () {
      final resolver = CountingDamageResolver();
      final observer = CapturingObserver();
      final initialGate = Phase0aSpawnGraceIntentGate(
        canAttackActorIds: const {},
      );
      final nextGate = Phase0aSpawnGraceIntentGate(
        canAttackActorIds: const {'e1'},
      );
      final batchGate = PassThroughBatchGate();
      final session = makeSession(
        resolver: resolver,
        observer: observer,
        gate: initialGate,
        batchGate: batchGate,
      );
      final forked = session.forkWithStateAndEnemyIntentGate(
        makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
        enemyIntentGate: nextGate,
      );

      expect(identical(forked.playerAdapter, session.playerAdapter), isTrue);
      expect(identical(forked.enemyAiAdapter, session.enemyAiAdapter), isTrue);
      expect(identical(forked.damageResolver, resolver), isTrue);
      expect(identical(forked.enemyIntentObserver, observer), isTrue);
      expect(identical(forked.enemyIntentGate, nextGate), isTrue);
      expect(identical(forked.enemyIntentBatchGate, batchGate), isTrue);
      expect(identical(session.enemyIntentGate, initialGate), isTrue);
      expect(identical(session.enemyIntentBatchGate, batchGate), isTrue);
    });
  });

  group('无 gate 路径与基线一致', () {
    test(
      'gate 为 null 时 observer 观察原始 intents,state/events/transcript 与基线一致',
      () {
        Phase0aArenaState initial() => makeState(
          enemies: [
            makeEnemy(id: 'e1', position: const ArenaVector(50, 0)),
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
        final baselineResolver = CountingDamageResolver();
        final observedResolver = CountingDamageResolver();
        final observer = CapturingObserver();
        final baseline = makeSession(
          initialState: initial(),
          resolver: baselineResolver,
        );
        final observed = makeSession(
          initialState: initial(),
          resolver: observedResolver,
          observer: observer,
        );

        List<Phase0aEvent> run(Phase0aCombatSession session) {
          final all = <Phase0aEvent>[];
          for (final command in commands) {
            all.addAll(session.advance(deltaSeconds: 0.2, command: command));
          }
          return all;
        }

        final baselineEvents = run(baseline);
        final observedEvents = run(observed);
        expect(observedEvents, isNotEmpty);
        expect(observedEvents, baselineEvents);
        expect(observed.state, baseline.state);
        expect(observed.state.nextSeq, baseline.state.nextSeq);
        expect(observedResolver.calls, baselineResolver.calls);
        expect(observedResolver.transcript, baselineResolver.transcript);
        // 无 gate 时观察的是 adapter 原始 intents(普攻未被过滤)。
        final e1Attacks = observer.observations
            .expand((o) => o.enemyIntents)
            .whereType<Phase0aAttackIntent>()
            .toList();
        expect(e1Attacks, isNotEmpty);
      },
    );
  });

  group('Phase0aSpawnGraceIntentGate 冻结语义', () {
    test('集合内 actor 允许原始 intent(移动/普攻/技能全量通过)', () {
      final gate = Phase0aSpawnGraceIntentGate(
        canAttackActorIds: const {'e1', 'e2'},
      );
      final gated = gate.gateEnemyIntents(
        enemyIntents: [attackE1, moveE2, enemySkillE2],
      );
      expect(gated, hasLength(3));
      expect(gated, [attackE1, moveE2, enemySkillE2]);
    });

    test('集合外 actor 仅 move 放行,普攻与 enemy skill fail closed', () {
      final gate = Phase0aSpawnGraceIntentGate(canAttackActorIds: const {'e1'});
      final gated = gate.gateEnemyIntents(
        enemyIntents: [attackE1, moveE2, enemySkillE2],
      );
      expect(gated, hasLength(2));
      expect(gated[0], same(attackE1));
      expect(gated[1], same(moveE2));
      expect(gated.whereType<Phase0aEnemySkillIntent>(), isEmpty);
    });

    test('空集合:攻击/技能全过滤,移动保留', () {
      final gate = Phase0aSpawnGraceIntentGate(canAttackActorIds: const {});
      final gated = gate.gateEnemyIntents(
        enemyIntents: [attackE1, moveE2, enemySkillE2],
      );
      expect(gated, hasLength(1));
      expect(gated.single, same(moveE2));
    });

    test('不改原列表,输出不可修改', () {
      final gate = Phase0aSpawnGraceIntentGate(canAttackActorIds: const {'e1'});
      final original = <Phase0aIntent>[attackE1, moveE2, enemySkillE2];
      final gated = gate.gateEnemyIntents(enemyIntents: original);

      // 原列表内容与元素身份不被修改。
      expect(original, hasLength(3));
      expect(identical(original[0], attackE1), isTrue);
      expect(identical(original[1], moveE2), isTrue);
      expect(identical(original[2], enemySkillE2), isTrue);
      // 输出不可修改。
      expect(
        () => gated.add(
          const Phase0aMoveIntent(actorId: 'e9', direction: ArenaVector(1, 0)),
        ),
        throwsUnsupportedError,
      );
    });

    test('输入集合防御性复制:外部后续 mutation 不影响 gate', () {
      final allowed = <String>{'e1'};
      final gate = Phase0aSpawnGraceIntentGate(canAttackActorIds: allowed);
      allowed.add('e2');
      final gated = gate.gateEnemyIntents(enemyIntents: [attackE2]);
      expect(gated, isEmpty);
    });

    test('宽限到期:包含该 actor 的新 gate 恢复全部原始 intent', () {
      final graceGate = Phase0aSpawnGraceIntentGate(
        canAttackActorIds: const {},
      );
      expect(
        graceGate.gateEnemyIntents(enemyIntents: [attackE1, enemySkillE2]),
        isEmpty,
      );
      final expiredGate = Phase0aSpawnGraceIntentGate(
        canAttackActorIds: const {'e1', 'e2'},
      );
      final gated = expiredGate.gateEnemyIntents(
        enemyIntents: [attackE1, enemySkillE2],
      );
      expect(gated, [attackE1, enemySkillE2]);
    });
  });

  group('会话穿透:宽限敌人可移动、不可攻击', () {
    test('射程内敌人攻击 intent 被过滤:玩家不掉血、敌人原地不动', () {
      final resolver = CountingDamageResolver();
      final session = makeSession(
        initialState: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
        resolver: resolver,
        gate: Phase0aSpawnGraceIntentGate(canAttackActorIds: const {}),
      );
      session.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(resolver.transcript.where((r) => r.attackerId == 'e1'), isEmpty);
      expect(session.state.player.currentHealth, 100);
      expect(session.state.enemies.single.position, const ArenaVector(50, 0));
    });

    test('射程外敌人移动 intent 放行:位置向玩家逼近', () {
      final session = makeSession(
        initialState: makeState(
          enemies: [makeEnemy(id: 'e2', position: const ArenaVector(300, 0))],
        ),
        gate: Phase0aSpawnGraceIntentGate(canAttackActorIds: const {}),
      );
      session.advance(deltaSeconds: 1.0, command: const Phase0aPlayerCommand());
      expect(session.state.enemies.single.position.x, lessThan(300));
      expect(session.state.enemies.single.position.x, 240);
      expect(session.state.player.currentHealth, 100);
    });

    test('宽限到期后恢复进攻:同一依赖新 gate 会话,敌人照常攻击', () {
      final resolver = CountingDamageResolver();
      final grace = makeSession(
        initialState: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
        resolver: resolver,
        gate: Phase0aSpawnGraceIntentGate(canAttackActorIds: const {}),
      );
      grace.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(resolver.transcript.where((r) => r.attackerId == 'e1'), isEmpty);

      final expired = makeSession(
        initialState: grace.state,
        resolver: resolver,
        gate: Phase0aSpawnGraceIntentGate(canAttackActorIds: const {'e1'}),
      );
      expired.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(
        resolver.transcript.where((r) => r.attackerId == 'e1'),
        hasLength(1),
      );
      expect(expired.state.player.currentHealth, 85);
    });
  });

  group('observer 观察 gated intents', () {
    test('observer 只观察 gate 筛选后的最终列表,且不可回写', () {
      final observer = CapturingObserver();
      final resolver = CountingDamageResolver();
      final session = makeSession(
        initialState: makeState(
          enemies: [
            makeEnemy(id: 'e1', position: const ArenaVector(50, 0)),
            makeEnemy(id: 'e2', position: const ArenaVector(300, 0)),
          ],
        ),
        resolver: resolver,
        observer: observer,
        gate: Phase0aSpawnGraceIntentGate(canAttackActorIds: const {}),
      );
      session.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );

      // e1 的普攻被过滤,只观察最终交给 reducer 的 e2 移动。
      final observation = observer.observations.single;
      expect(observation.tick, 0);
      expect(observation.enemyIntents, hasLength(1));
      expect(observation.enemyIntents.single.actorId, 'e2');
      expect(observation.enemyIntents.single, isA<Phase0aMoveIntent>());
      expect(
        observation.enemyIntents.whereType<Phase0aAttackIntent>(),
        isEmpty,
      );
      expect(
        () => observation.enemyIntents.add(
          const Phase0aMoveIntent(actorId: 'e9', direction: ArenaVector(1, 0)),
        ),
        throwsUnsupportedError,
      );
      expect(session.lastEnemyIntentObservation, same(observation));
      // reducer 确实只消费筛选后列表:e1 未攻击。
      expect(resolver.transcript.where((r) => r.attackerId == 'e1'), isEmpty);
    });
  });

  group('wave 换波接缝(回归修复)', () {
    test('换波前后 observer 持续观察,gate 全程生效', () {
      final observer = CapturingObserver();
      final resolver = CountingDamageResolver();
      final wave1 = [
        makeEnemy(
          id: 'e1',
          position: const ArenaVector(50, 0),
          currentHealth: 15,
        ),
      ];
      final wave2 = [makeEnemy(id: 'e2', position: const ArenaVector(300, 0))];
      final flow = makeFlow(
        initialState: makeState(enemies: wave1),
        waves: [
          Phase0aWave(enemies: wave1),
          Phase0aWave(enemies: wave2),
        ],
        resolver: resolver,
        observer: observer,
        gate: Phase0aSpawnGraceIntentGate(canAttackActorIds: const {}),
      );

      // tick1:玩家收掉 e1 → cleared → wave2 started(换波)。
      flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(flow.state.enemies.single.id, 'e2');
      // tick2:换波后 e2 在射程外 → 移动 intent 放行并持续被观察。
      flow.advance(deltaSeconds: 1.0, command: const Phase0aPlayerCommand());

      // 换波前后每次 advance 观察器都收到调用。
      expect(observer.observations, hasLength(2));
      // tick1:e1 的普攻被 gate 过滤 → 观察列表为空。
      expect(observer.observations[0].enemyIntents, isEmpty);
      // tick2:观察的是换波后的新敌人 e2(最终交给 reducer 的移动)。
      final second = observer.observations[1].enemyIntents;
      expect(second, hasLength(1));
      expect(second.single.actorId, 'e2');
      expect(second.single, isA<Phase0aMoveIntent>());
      // gate 全程生效:若换波丢 gate,e1/e2 的攻击会让玩家掉血。
      expect(flow.state.player.currentHealth, 100);
      expect(
        resolver.transcript.where((r) => r.attackerId != 'player'),
        isEmpty,
      );
      expect(flow.state.enemies.single.position.x, lessThan(300));
    });

    test('换波前后保留同一 batch gate 并每拍执行', () {
      final batchGate = PassThroughBatchGate();
      final wave1 = [
        makeEnemy(
          id: 'e1',
          position: const ArenaVector(50, 0),
          currentHealth: 15,
        ),
      ];
      final wave2 = [makeEnemy(id: 'e2', position: const ArenaVector(300, 0))];
      final flow = makeFlow(
        initialState: makeState(enemies: wave1),
        waves: [
          Phase0aWave(enemies: wave1),
          Phase0aWave(enemies: wave2),
        ],
        batchGate: batchGate,
      );

      flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      flow.advance(deltaSeconds: 1.0, command: const Phase0aPlayerCommand());

      expect(flow.state.enemies.single.id, 'e2');
      expect(batchGate.calls, 2);
    });
  });
}
