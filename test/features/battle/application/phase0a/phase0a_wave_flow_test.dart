import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import '../../../../support/test_data.dart';

/// Phase 0A 波次与唯一终局状态机红测(第四批派单 §红测与证伪):
/// ① 首波/清波/换波/胜负事件严格 seq 顺序(waveIndex 1-based 拍板);
/// ② 玩家死亡优先 defeat,禁双终局;
/// ③ 换波保留玩家 HP/真气/CD/技能槽/tick/seq,只换敌人;
/// ④ 终局后 advance 完全幂等(以含终局事件的 state 为基准)且计数
///   resolver 零调用;
/// ⑤ 波次/敌人列表防御性副本,非法配置构造期 fail-fast;
/// ⑥ flow.advance 穿透 Phase0aCombatSession → adapters → reducer →
///   真实 Phase0aDamageCalculatorAdapter,不只测 fake helper。

/// 计数 resolver:证明终局后 advance 对下游零调用。
class CountingDamageResolver implements Phase0aDamageResolver {
  CountingDamageResolver({required this.damage});

  final int damage;
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
    return Phase0aResolvedHit(isHit: true, isCritical: false, damage: damage);
  }
}

Phase0aActor makePlayer({int currentHealth = 100, int qiCurrent = 100}) {
  return Phase0aActor(
    id: 'player',
    side: Phase0aSide.player,
    position: const ArenaVector(0, 0),
    facing: const ArenaVector(1, 0),
    maxHealth: 100,
    currentHealth: currentHealth,
    moveSpeed: 100,
    qiCurrent: qiCurrent,
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

const defaultSkillSlots = [
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
];

Phase0aArenaState makeState({
  Phase0aActor? player,
  List<Phase0aActor>? enemies,
  List<Phase0aSkillSlot>? skillSlots,
  Phase0aWinCondition? winCondition,
}) {
  return Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: player ?? makePlayer(),
    enemies: enemies ?? const [],
    skillSlots: skillSlots ?? defaultSkillSlots,
    winCondition: winCondition,
  );
}

Phase0aPlayerInputAdapter makePlayerAdapter() {
  return const Phase0aPlayerInputAdapter(
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
}

Phase0aEnemyAiAdapter makeEnemyAdapter() {
  return const Phase0aEnemyAiAdapter(
    attackRange: 70,
    attackHalfArcRadians: math.pi / 3,
    attackCooldownSeconds: 1.2,
  );
}

Phase0aWaveBattleFlow makeFlow({
  required Phase0aArenaState initialState,
  required List<Phase0aWave> waves,
  Phase0aDamageResolver? damageResolver,
  Phase0aWaveTransitionPolicy? waveTransitionPolicy,
}) {
  return Phase0aWaveBattleFlow(
    session: Phase0aCombatSession(
      initialState: initialState,
      playerAdapter: makePlayerAdapter(),
      enemyAiAdapter: makeEnemyAdapter(),
      damageResolver: damageResolver ?? CountingDamageResolver(damage: 15),
    ),
    waves: waves,
    waveTransitionPolicy: waveTransitionPolicy,
  );
}

/// 全场事件 seq 严格连续递增且首事件 seq = 初态 nextSeq。
void expectSeqContiguous(List<Phase0aEvent> events, int firstSeq) {
  for (var i = 0; i < events.length; i++) {
    expect(events[i].seq, firstSeq + i, reason: '第 $i 个事件 seq 断档');
  }
}

void main() {
  group('单波胜利与终局唯一', () {
    test('surviveTicks 达阈值且敌人仍存活 → victory,不发 wave_cleared', () {
      final enemy = makeEnemy(
        id: 'e1',
        position: const ArenaVector(50, 0),
        currentHealth: 1000,
      );
      final flow = makeFlow(
        initialState: makeState(
          enemies: [enemy],
          winCondition: const Phase0aWinCondition.surviveTicks(1),
        ),
        waves: [
          Phase0aWave(enemies: [enemy]),
        ],
      );
      expect(flow.state.winCondition?.surviveTicksRequired, 1);

      final events = flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(),
      );
      expect(flow.outcome, Phase0aBattleOutcome.victory);
      expect(flow.state.enemies, isNotEmpty);
      expect(flow.state.tick, 1);
      expect(flow.state.surviveTicksRemaining, 0);
      expect(events.whereType<Phase0aWaveCleared>(), isEmpty);
      expect(events.last, isA<Phase0aBattleVictory>());
    });

    test('surviveTicks 同拍玩家死亡优先 → defeat', () {
      final enemy = makeEnemy(
        id: 'e1',
        position: const ArenaVector(50, 0),
        currentHealth: 1000,
      );
      final flow = makeFlow(
        initialState: makeState(
          player: makePlayer(currentHealth: 10),
          enemies: [enemy],
          winCondition: const Phase0aWinCondition.surviveTicks(1),
        ),
        waves: [
          Phase0aWave(enemies: [enemy]),
        ],
      );

      final events = flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(),
      );

      expect(flow.outcome, Phase0aBattleOutcome.defeat);
      expect(events.last, isA<Phase0aBattleDefeat>());
      expect(events.whereType<Phase0aBattleVictory>(), isEmpty);
    });

    test('首个 advance 以 wave_started 开头,末敌死亡拍 cleared→victory seq 连续', () {
      final flow = makeFlow(
        initialState: makeState(
          enemies: [
            makeEnemy(
              id: 'e1',
              position: const ArenaVector(50, 0),
              currentHealth: 15,
            ),
          ],
        ),
        waves: [
          Phase0aWave(
            enemies: [
              makeEnemy(
                id: 'e1',
                position: const ArenaVector(50, 0),
                currentHealth: 15,
              ),
            ],
          ),
        ],
      );
      final events = flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );

      // 首波 wave_started 全场一次,排在首个战斗事件前;waveIndex 1-based。
      final first = events.first;
      expect(first, isA<Phase0aWaveStarted>());
      expect((first as Phase0aWaveStarted).waveIndex, 1);
      expect(first.waveTotal, 1);
      expect(first.tick, 1);
      expect(first.seq, 1);

      // 击杀末敌固定序:enemy_defeated → wave_cleared → battle_victory,
      // 同拍(实际边界拍)且 seq 严格连续。
      expect(events[events.length - 3], isA<Phase0aEnemyDefeated>());
      final cleared = events[events.length - 2];
      expect(cleared, isA<Phase0aWaveCleared>());
      expect((cleared as Phase0aWaveCleared).waveIndex, 1);
      final victory = events.last;
      expect(victory, isA<Phase0aBattleVictory>());
      final defeatTick = events[events.length - 3].tick;
      expect(cleared.tick, defeatTick);
      expect(victory.tick, defeatTick);
      expectSeqContiguous(events, 1);

      // 终局唯一且 seq 已持久化回 state(拍板Ⓑ)。
      expect(flow.outcome, Phase0aBattleOutcome.victory);
      expect(flow.state.enemies, isEmpty);
      expect(flow.state.tick, 1);
      expect(flow.state.nextSeq, events.length + 1);
    });

    test('终局后两次 advance 完全幂等且计数 resolver 零调用', () {
      final resolver = CountingDamageResolver(damage: 15);
      final flow = makeFlow(
        initialState: makeState(
          enemies: [
            makeEnemy(
              id: 'e1',
              position: const ArenaVector(50, 0),
              currentHealth: 15,
            ),
          ],
        ),
        waves: [
          Phase0aWave(
            enemies: [
              makeEnemy(
                id: 'e1',
                position: const ArenaVector(50, 0),
                currentHealth: 15,
              ),
            ],
          ),
        ],
        damageResolver: resolver,
      );
      flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(flow.outcome, Phase0aBattleOutcome.victory);
      final terminalState = flow.state;
      final callsAtTerminal = resolver.calls;

      // 幂等基准 = 已含终局事件的 state(拍板Ⓑ)。
      for (var i = 0; i < 2; i++) {
        final events = flow.advance(
          deltaSeconds: 0.1,
          command: const Phase0aPlayerCommand(attack: true, gather: true),
        );
        expect(events, isEmpty);
      }
      expect(flow.state, terminalState);
      expect(flow.state.tick, terminalState.tick);
      expect(flow.state.nextSeq, terminalState.nextSeq);
      expect(flow.outcome, Phase0aBattleOutcome.victory);
      expect(resolver.calls, callsAtTerminal, reason: '终局后 resolver 零调用');
    });
  });

  group('战败:玩家死亡优先,禁双终局', () {
    test('命中/伤害事件之后 battle_defeat,同拍不得有 cleared/victory', () {
      final resolver = CountingDamageResolver(damage: 15);
      final waveEnemies = [
        makeEnemy(id: 'e1', position: const ArenaVector(50, 0)),
        makeEnemy(id: 'e2', position: const ArenaVector(60, 0)),
      ];
      final flow = makeFlow(
        initialState: makeState(
          player: makePlayer(currentHealth: 10),
          enemies: waveEnemies,
        ),
        waves: [Phase0aWave(enemies: waveEnemies)],
        damageResolver: resolver,
      );
      final events = flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );

      // e1 先行动把玩家 10 → 0;玩家当拍 intent 被跳过;e2 无合法目标。
      final hits = events.whereType<Phase0aHitLanded>().toList();
      expect(hits, hasLength(1));
      expect(hits.single.actor, 'e1');
      expect(hits.single.target, 'player');
      expect(hits.single.remainingHealth, 0);
      expect(events.last, isA<Phase0aBattleDefeat>());
      expect(events.whereType<Phase0aWaveCleared>(), isEmpty);
      expect(events.whereType<Phase0aBattleVictory>(), isEmpty);
      // defeat 排在全部命中/伤害事件之后。
      expect(events.last.seq, greaterThan(hits.single.seq));
      expectSeqContiguous(events, 1);
      expect(flow.outcome, Phase0aBattleOutcome.defeat);

      // 终局幂等:再 advance 两次零事件、state 不变、resolver 零新增调用。
      final terminalState = flow.state;
      final callsAtTerminal = resolver.calls;
      for (var i = 0; i < 2; i++) {
        expect(
          flow.advance(
            deltaSeconds: 0.1,
            command: const Phase0aPlayerCommand(attack: true),
          ),
          isEmpty,
        );
      }
      expect(flow.state, terminalState);
      expect(flow.outcome, Phase0aBattleOutcome.defeat);
      expect(resolver.calls, callsAtTerminal);
    });

    test('玩家构造期已死亡:首拍直接 defeat 且不产 cleared/victory', () {
      final waveEnemies = [
        makeEnemy(id: 'e1', position: const ArenaVector(50, 0)),
      ];
      final flow = makeFlow(
        initialState: makeState(
          player: makePlayer(currentHealth: 0),
          enemies: waveEnemies,
        ),
        waves: [Phase0aWave(enemies: waveEnemies)],
      );
      final events = flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(events.last, isA<Phase0aBattleDefeat>());
      expect(events.whereType<Phase0aWaveCleared>(), isEmpty);
      expect(events.whereType<Phase0aBattleVictory>(), isEmpty);
      expect(flow.outcome, Phase0aBattleOutcome.defeat);
    });
  });

  group('双波切换:状态连续,只换敌人', () {
    Phase0aWaveBattleFlow makeTwoWaveFlow() {
      final wave1 = [
        makeEnemy(
          id: 'e1',
          position: const ArenaVector(50, 0),
          currentHealth: 30,
        ),
      ];
      final wave2 = [
        makeEnemy(
          id: 'e2',
          position: const ArenaVector(50, 0),
          currentHealth: 15,
        ),
        makeEnemy(
          id: 'e3',
          position: const ArenaVector(60, 0),
          currentHealth: 15,
        ),
      ];
      return makeFlow(
        initialState: makeState(enemies: wave1),
        waves: [
          Phase0aWave(enemies: wave1),
          Phase0aWave(enemies: wave2),
        ],
      );
    }

    test('cleared→下一波 started 同拍 seq 连续,玩家 HP/真气/CD/技能槽/tick 保留', () {
      final flow = makeTwoWaveFlow();

      // tick1:聚怪把 e1 拉上环并打进 15 血,gather 槽进冷却、真气 100→80;
      // e1 先手命中玩家 100→85。
      flow.advance(
        deltaSeconds: 0.5,
        command: const Phase0aPlayerCommand(gather: true),
      );
      // tick2:e1 环上距离 90 超出 AI 射程只能逼近;玩家普攻收掉 e1。
      final switchEvents = flow.advance(
        deltaSeconds: 0.5,
        command: const Phase0aPlayerCommand(attack: true),
      );

      // 固定序:enemy_defeated → wave_cleared(1) → wave_started(2/2),同拍。
      final defeatedIndex = switchEvents.indexWhere(
        (e) => e is Phase0aEnemyDefeated,
      );
      expect(defeatedIndex, greaterThanOrEqualTo(0));
      final cleared = switchEvents[defeatedIndex + 1];
      expect(cleared, isA<Phase0aWaveCleared>());
      expect((cleared as Phase0aWaveCleared).waveIndex, 1);
      final started = switchEvents[defeatedIndex + 2];
      expect(started, isA<Phase0aWaveStarted>());
      expect((started as Phase0aWaveStarted).waveIndex, 2);
      expect(started.waveTotal, 2);
      expect(cleared.tick, switchEvents[defeatedIndex].tick);
      expect(started.tick, cleared.tick);
      expect(cleared.seq, switchEvents[defeatedIndex].seq + 1);
      expect(started.seq, cleared.seq + 1);

      // 换波不消耗额外拍:state.tick 即末敌死亡拍;seq 连续持久化。
      final state = flow.state;
      expect(state.tick, cleared.tick);
      expect(state.nextSeq, started.seq + 1);

      // 只换敌人:下一波满血原站位;玩家运行态逐项连续。
      expect(state.enemies.map((e) => e.id), ['e2', 'e3']);
      expect(state.enemies.map((e) => e.currentHealth), [15, 15]);
      expect(state.enemies[0].position, const ArenaVector(50, 0));
      expect(state.player.currentHealth, 85);
      expect(state.player.qiCurrent, 80);
      expect(state.player.attackCooldownRemaining, 1);
      final gather = state.skillSlots.singleWhere((s) => s.slot == 'gather');
      expect(gather.cooldownRemaining, closeTo(2.5, 0.0001));
      expect(gather.availability, Phase0aSkillAvailability.cooldown);
      final clear = state.skillSlots.singleWhere((s) => s.slot == 'clear');
      expect(clear.cooldownRemaining, 0);
      expect(clear.availability, Phase0aSkillAvailability.ready);
    });

    test('群战 policy 换波满血、追加 25% 真气并重置普攻/技能冷却', () {
      final wave1 = [
        makeEnemy(
          id: 'e1',
          position: const ArenaVector(50, 0),
          currentHealth: 15,
        ),
      ];
      final wave2 = [
        makeEnemy(
          id: 'e2',
          position: const ArenaVector(50, 0),
          currentHealth: 15,
        ),
      ];
      final flow = makeFlow(
        initialState: makeState(
          player: makePlayer(currentHealth: 40, qiCurrent: 20),
          enemies: wave1,
          skillSlots: const [
            Phase0aSkillSlot(
              slot: 'gather',
              cooldownRemaining: 2,
              qiCost: 20,
              availability: Phase0aSkillAvailability.cooldown,
            ),
          ],
        ),
        waves: [
          Phase0aWave(enemies: wave1),
          Phase0aWave(enemies: wave2),
        ],
        waveTransitionPolicy: const Phase0aWaveTransitionPolicy(
          healPlayerToFull: true,
          qiRecoveryPct: 0.25,
          resetAttackCooldown: true,
          resetSkillCooldowns: true,
        ),
      );

      flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );

      expect(flow.state.enemies.single.id, 'e2');
      expect(flow.state.player.currentHealth, 100);
      expect(flow.state.player.qiCurrent, 45);
      expect(flow.state.player.attackCooldownRemaining, 0);
      expect(flow.state.skillSlots.single.cooldownRemaining, 0);
      expect(
        flow.state.skillSlots.single.availability,
        Phase0aSkillAvailability.ready,
      );
    });

    test('第二波清空后 battle_victory,全场 wave/outcome 事件序完整可测', () {
      final flow = makeTwoWaveFlow();
      final all = <Phase0aEvent>[];
      all.addAll(
        flow.advance(
          deltaSeconds: 0.5,
          command: const Phase0aPlayerCommand(gather: true),
        ),
      );
      var guard = 0;
      while (flow.outcome == Phase0aBattleOutcome.ongoing && guard < 20) {
        all.addAll(
          flow.advance(
            deltaSeconds: 0.5,
            command: const Phase0aPlayerCommand(attack: true),
          ),
        );
        guard++;
      }

      expect(flow.outcome, Phase0aBattleOutcome.victory);
      final startedEvents = all.whereType<Phase0aWaveStarted>().toList();
      expect(startedEvents.map((e) => e.waveIndex), [1, 2]);
      expect(startedEvents.every((e) => e.waveTotal == 2), isTrue);
      final clearedEvents = all.whereType<Phase0aWaveCleared>().toList();
      expect(clearedEvents.map((e) => e.waveIndex), [1, 2]);
      // 终局全场至多一条,且为最后一个事件。
      expect(all.whereType<Phase0aBattleVictory>(), hasLength(1));
      expect(all.whereType<Phase0aBattleDefeat>(), isEmpty);
      expect(all.last, isA<Phase0aBattleVictory>());
      // 最后一波 cleared → victory 同拍紧邻。
      final lastCleared = clearedEvents.last;
      expect(all.last.tick, lastCleared.tick);
      expect(all.last.seq, lastCleared.seq + 1);
      expectSeqContiguous(all, 1);
    });
  });

  group('确定性回放', () {
    test('同初态同命令序列两实例事件/state/outcome 全等', () {
      List<Phase0aWave> waves() {
        final wave1 = [
          makeEnemy(
            id: 'e1',
            position: const ArenaVector(50, 0),
            currentHealth: 30,
          ),
        ];
        final wave2 = [
          makeEnemy(
            id: 'e2',
            position: const ArenaVector(50, 0),
            currentHealth: 15,
          ),
        ];
        return [Phase0aWave(enemies: wave1), Phase0aWave(enemies: wave2)];
      }

      Phase0aArenaState initial() => makeState(
        enemies: [
          makeEnemy(
            id: 'e1',
            position: const ArenaVector(50, 0),
            currentHealth: 30,
          ),
        ],
      );

      const commands = [
        Phase0aPlayerCommand(gather: true),
        Phase0aPlayerCommand(attack: true),
        Phase0aPlayerCommand(),
        Phase0aPlayerCommand(attack: true),
        Phase0aPlayerCommand(attack: true),
        Phase0aPlayerCommand(attack: true),
        Phase0aPlayerCommand(attack: true),
      ];

      (List<Phase0aEvent>, Phase0aWaveBattleFlow) run() {
        final flow = makeFlow(initialState: initial(), waves: waves());
        final events = <Phase0aEvent>[];
        for (final command in commands) {
          events.addAll(flow.advance(deltaSeconds: 0.5, command: command));
        }
        return (events, flow);
      }

      final (eventsA, flowA) = run();
      final (eventsB, flowB) = run();
      expect(eventsA, isNotEmpty);
      expect(eventsB, eventsA);
      expect(flowB.state, flowA.state);
      expect(flowB.outcome, flowA.outcome);
    });
  });

  group('构造期 fail-fast 与防御性副本', () {
    test('空波敌人列表 fail-fast', () {
      expect(() => Phase0aWave(enemies: const []), throwsArgumentError);
    });

    test('波内非 enemy side actor fail-fast', () {
      expect(() => Phase0aWave(enemies: [makePlayer()]), throwsArgumentError);
    });

    test('空波次列表 fail-fast', () {
      expect(
        () => makeFlow(initialState: makeState(), waves: const []),
        throwsArgumentError,
      );
    });

    test('全场重复 actor id fail-fast(跨波与撞玩家 id)', () {
      final wave1 = [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))];
      final dupAcrossWaves = [
        makeEnemy(id: 'e1', position: const ArenaVector(80, 0)),
      ];
      expect(
        () => makeFlow(
          initialState: makeState(enemies: wave1),
          waves: [
            Phase0aWave(enemies: wave1),
            Phase0aWave(enemies: dupAcrossWaves),
          ],
        ),
        throwsArgumentError,
      );

      final playerIdClash = [
        makeEnemy(id: 'player', position: const ArenaVector(50, 0)),
      ];
      expect(
        () => makeFlow(
          initialState: makeState(enemies: playerIdClash),
          waves: [Phase0aWave(enemies: playerIdClash)],
        ),
        throwsArgumentError,
      );
    });

    test('首态 enemies 与首波不一致 fail-fast', () {
      final stateEnemies = [
        makeEnemy(
          id: 'e1',
          position: const ArenaVector(50, 0),
          currentHealth: 30,
        ),
      ];
      final waveEnemies = [
        makeEnemy(
          id: 'e1',
          position: const ArenaVector(50, 0),
          currentHealth: 31,
        ),
      ];
      expect(
        () => makeFlow(
          initialState: makeState(enemies: stateEnemies),
          waves: [Phase0aWave(enemies: waveEnemies)],
        ),
        throwsArgumentError,
      );
    });

    test('首态玩家非 player side fail-fast', () {
      final waveEnemies = [
        makeEnemy(id: 'e1', position: const ArenaVector(50, 0)),
      ];
      const roguePlayer = Phase0aActor(
        id: 'player',
        side: Phase0aSide.enemy,
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
      expect(
        () => makeFlow(
          initialState: makeState(player: roguePlayer, enemies: waveEnemies),
          waves: [Phase0aWave(enemies: waveEnemies)],
        ),
        throwsArgumentError,
      );
    });

    test('外部 list 构造后 mutation 不影响 flow,暴露集合不可写', () {
      final waveEnemies = [
        makeEnemy(
          id: 'e1',
          position: const ArenaVector(50, 0),
          currentHealth: 15,
        ),
      ];
      final wave = Phase0aWave(enemies: waveEnemies);
      final waves = [wave];
      final flow = makeFlow(
        initialState: makeState(enemies: waveEnemies),
        waves: waves,
      );

      // 构造后污染外部 list。
      waveEnemies.add(makeEnemy(id: 'e9', position: const ArenaVector(999, 0)));
      waves.add(
        Phase0aWave(
          enemies: [makeEnemy(id: 'e8', position: const ArenaVector(888, 0))],
        ),
      );
      expect(wave.enemies, hasLength(1));
      expect(flow.waves, hasLength(1));
      expect(
        () => wave.enemies.add(
          makeEnemy(id: 'e7', position: const ArenaVector(0, 0)),
        ),
        throwsUnsupportedError,
      );
      expect(() => flow.waves.add(wave), throwsUnsupportedError);

      // 运行行为不受外部 mutation 影响:waveTotal 仍为 1,直取胜利。
      final events = flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect((events.first as Phase0aWaveStarted).waveTotal, 1);
      expect(flow.outcome, Phase0aBattleOutcome.victory);
    });
  });

  group('穿透真实 Phase0aDamageCalculatorAdapter', () {
    setUp(() async {
      await loadTestGameRepository();
    });

    tearDown(GameRepository.resetForTest);

    NumbersConfig numbers() => GameRepository.instance.numbers;

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

    Phase0aDamageSnapshot playerSnapshot() {
      return Phase0aDamageSnapshot(
        internalForce: 600,
        equipmentAttack: 130,
        cultivationLayer: CultivationLayer.chuKui,
        school: TechniqueSchool.gangMeng,
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.ruMen,
        defenseRate: 0.05,
        evasionRate: 0.0,
        criticalRate: 0.0,
        attackPowerMultiplier: 1.0,
        proficiencyDamageMults: const {},
        outputMultiplier: 1.0,
        schoolDamageTakenMults: const {},
        wardMult: 1.0,
        vulnerabilityOutMult: null,
        piercePct: 0.0,
        lifestealPct: 0.0,
        critDamageTakenMult: 1.0,
      );
    }

    Phase0aDamageSnapshot enemySnapshot() {
      return Phase0aDamageSnapshot(
        internalForce: 400,
        equipmentAttack: 90,
        cultivationLayer: CultivationLayer.chuKui,
        school: TechniqueSchool.yinRou,
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        defenseRate: 0.05,
        evasionRate: 0.0,
        criticalRate: 0.0,
        attackPowerMultiplier: 1.0,
        proficiencyDamageMults: const {},
        outputMultiplier: 1.0,
        schoolDamageTakenMults: const {},
        wardMult: 1.0,
        vulnerabilityOutMult: null,
        piercePct: 0.0,
        lifestealPct: 0.0,
        critDamageTakenMult: 1.0,
      );
    }

    Phase0aActor productionActor({
      required String id,
      required Phase0aSide side,
      required ArenaVector position,
      int currentHealth = 100000,
    }) {
      return Phase0aActor(
        id: id,
        side: side,
        position: position,
        facing: side == Phase0aSide.player
            ? const ArenaVector(1, 0)
            : const ArenaVector(-1, 0),
        maxHealth: 100000,
        currentHealth: currentHealth,
        moveSpeed: 100,
        qiCurrent: 100,
        qiMax: 100,
        attackCooldownRemaining: 0,
        defeatKind: Phase0aDefeatKind.normal,
      );
    }

    /// 真实链路:flow → Phase0aCombatSession → adapters → reducer →
    /// Phase0aDamageCalculatorAdapter(真实 numbers fixture)。
    Phase0aWaveBattleFlow makeProductionFlow({required int seed}) {
      final waveEnemies = [
        productionActor(
          id: 'e1',
          side: Phase0aSide.enemy,
          position: const ArenaVector(50, 0),
          currentHealth: 1,
        ),
      ];
      return Phase0aWaveBattleFlow(
        session: Phase0aCombatSession(
          initialState: Phase0aArenaState(
            tick: 0,
            nextSeq: 1,
            player: productionActor(
              id: 'player',
              side: Phase0aSide.player,
              position: const ArenaVector(0, 0),
            ),
            enemies: waveEnemies,
            skillSlots: const [],
          ),
          playerAdapter: makePlayerAdapter(),
          enemyAiAdapter: makeEnemyAdapter(),
          damageResolver: Phase0aDamageCalculatorAdapter(
            combatants: {'player': playerSnapshot(), 'e1': enemySnapshot()},
            moveBindings: const {Phase0aDamageKind.basic: basicSkill},
            numbers: numbers(),
            rng: math.Random(seed),
          ),
        ),
        waves: [Phase0aWave(enemies: waveEnemies)],
      );
    }

    test('单拍穿透:wave/outcome 序冻结,命中数值与 direct 逐拍一致', () {
      const seed = 5;
      final flow = makeProductionFlow(seed: seed);
      final events = flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );

      final first = events.first;
      expect(first, isA<Phase0aWaveStarted>());
      expect((first as Phase0aWaveStarted).waveIndex, 1);
      expect(first.waveTotal, 1);
      expect(events[events.length - 3], isA<Phase0aEnemyDefeated>());
      expect(events[events.length - 2], isA<Phase0aWaveCleared>());
      expect(events.last, isA<Phase0aBattleVictory>());
      expectSeqContiguous(events, 1);

      // direct 对照:reducer intent 按 actorId 稳定排序,'e1' 先 'player' 后,
      // 同 seed 同顺序复算锁死穿透链路无第二套公式。
      final directRng = math.Random(seed);
      final enemyDirect = DamageCalculator.calculateResolved(
        attackerInternalForce: 400,
        attackerEquipmentAttack: 90,
        attackerCultivationLayer: CultivationLayer.chuKui,
        attackerSchool: TechniqueSchool.yinRou,
        defenderSchool: TechniqueSchool.gangMeng,
        attackerRealmTier: RealmTier.xueTu,
        attackerRealmLayer: RealmLayer.qiMeng,
        defenderRealmTier: RealmTier.xueTu,
        defenderRealmLayer: RealmLayer.ruMen,
        defenderDefenseRate: 0.05,
        defenderEvasionRate: 0.0,
        attackerCriticalRate: 0.0,
        attackPowerMultiplier: 1.0,
        skill: basicSkill,
        n: numbers(),
        rng: directRng,
        proficiencyDamageMult: 1.0,
        defenderCritDamageTakenMult: 1.0,
        outputMultiplier: 1.0,
        defenderSchoolDamageMult: 1.0,
        defenderWardMult: 1.0,
        attackerPiercePct: 0.0,
        attackerLifestealPct: 0.0,
      );
      final playerDirect = DamageCalculator.calculateResolved(
        attackerInternalForce: 600,
        attackerEquipmentAttack: 130,
        attackerCultivationLayer: CultivationLayer.chuKui,
        attackerSchool: TechniqueSchool.gangMeng,
        defenderSchool: TechniqueSchool.yinRou,
        attackerRealmTier: RealmTier.xueTu,
        attackerRealmLayer: RealmLayer.ruMen,
        defenderRealmTier: RealmTier.xueTu,
        defenderRealmLayer: RealmLayer.qiMeng,
        defenderDefenseRate: 0.05,
        defenderEvasionRate: 0.0,
        attackerCriticalRate: 0.0,
        attackPowerMultiplier: 1.0,
        skill: basicSkill,
        n: numbers(),
        rng: directRng,
        proficiencyDamageMult: 1.0,
        defenderCritDamageTakenMult: 1.0,
        outputMultiplier: 1.0,
        defenderSchoolDamageMult: 1.0,
        defenderWardMult: 1.0,
        attackerPiercePct: 0.0,
        attackerLifestealPct: 0.0,
      );

      final hits = events.whereType<Phase0aHitLanded>().toList();
      final enemyHit = hits.singleWhere((h) => h.actor == 'e1');
      expect(enemyHit.resolvedDamage, enemyDirect.finalDamage);
      final playerHit = hits.singleWhere((h) => h.actor == 'player');
      expect(playerHit.resolvedDamage, playerDirect.finalDamage);
      expect(flow.state.player.currentHealth, 100000 - enemyDirect.finalDamage);
      expect(flow.outcome, Phase0aBattleOutcome.victory);
    });

    test('同 seed 两 flow 实例回放:事件/state/outcome 全等', () {
      (List<Phase0aEvent>, Phase0aWaveBattleFlow) run() {
        final flow = makeProductionFlow(seed: 11);
        final events = <Phase0aEvent>[];
        for (var i = 0; i < 3; i++) {
          events.addAll(
            flow.advance(
              deltaSeconds: 0.1,
              command: const Phase0aPlayerCommand(attack: true),
            ),
          );
        }
        return (events, flow);
      }

      final (eventsA, flowA) = run();
      final (eventsB, flowB) = run();
      expect(eventsA, isNotEmpty);
      expect(eventsB, eventsA);
      expect(flowB.state, flowA.state);
      expect(flowB.outcome, flowA.outcome);
    });
  });
}
