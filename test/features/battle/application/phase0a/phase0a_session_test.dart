import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';

/// Phase 0A 会话/适配层红测(§8.2 生产接线证据):
/// 全部从会话入口 `Phase0aCombatSession.advance` 或适配器契约断言,
/// 穿透 adapter → resolver → reducer 真实链路,不只测 fixture helper。

class FixedDamageResolver implements Phase0aDamageResolver {
  const FixedDamageResolver({required this.basicDamage});

  final int basicDamage;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
  }) {
    return Phase0aResolvedHit(
      isHit: true,
      isCritical: false,
      damage: basicDamage,
    );
  }
}

Phase0aActor makePlayer({
  ArenaVector position = const ArenaVector(0, 0),
  int currentHealth = 100,
  int qiCurrent = 100,
}) {
  return Phase0aActor(
    id: 'player',
    side: Phase0aSide.player,
    position: position,
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

Phase0aArenaState makeState({
  Phase0aActor? player,
  List<Phase0aActor>? enemies,
  List<Phase0aSkillSlot>? skillSlots,
}) {
  return Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: player ?? makePlayer(),
    enemies: enemies ?? const [],
    skillSlots:
        skillSlots ??
        const [
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
    gatherSlot: 'gather',
    gatherRingRadius: 90,
    gatherQiCost: 20,
    gatherCooldownSeconds: 3,
    clearSlot: 'clear',
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

Phase0aCombatSession makeSession({Phase0aArenaState? initialState}) {
  return Phase0aCombatSession(
    initialState:
        initialState ??
        makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(300, 0))],
        ),
    playerAdapter: makePlayerAdapter(),
    enemyAiAdapter: makeEnemyAdapter(),
    damageResolver: const FixedDamageResolver(basicDamage: 15),
  );
}

void main() {
  group('玩家输入适配器契约', () {
    test('按键转移动 intent 且对角输入已归一', () {
      final intents = makePlayerAdapter().intentsFor(
        state: makeState(),
        command: const Phase0aPlayerCommand(right: true, up: true),
      );
      final move = intents.whereType<Phase0aMoveIntent>().single;
      expect(move.actorId, 'player');
      expect(move.direction.length, closeTo(1, 0.0001));
      expect(move.direction.x, closeTo(math.sqrt1_2, 0.0001));
      expect(move.direction.y, closeTo(-math.sqrt1_2, 0.0001));
    });

    test('无按键无动作请求时不产 intent', () {
      final intents = makePlayerAdapter().intentsFor(
        state: makeState(),
        command: const Phase0aPlayerCommand(),
      );
      expect(intents, isEmpty);
    });

    test('动作请求转普攻/Q/R intent 并携带调用方显式参数', () {
      final intents = makePlayerAdapter().intentsFor(
        state: makeState(),
        command: const Phase0aPlayerCommand(
          attack: true,
          gather: true,
          clear: true,
        ),
      );
      final attack = intents.whereType<Phase0aAttackIntent>().single;
      expect(attack.range, 120);
      expect(attack.cooldownSeconds, 1);
      expect(attack.aimDirection, const ArenaVector(1, 0));
      final gather = intents.whereType<Phase0aGatherIntent>().single;
      expect(gather.slot, 'gather');
      expect(gather.ringRadius, 90);
      expect(gather.qiCost, 20);
      final clear = intents.whereType<Phase0aClearIntent>().single;
      expect(clear.slot, 'clear');
      expect(clear.qiCost, 30);
    });
  });

  group('敌方 AI 适配器契约', () {
    test('射程外朝玩家移动,方向为单位向量', () {
      final intents = makeEnemyAdapter().intentsFor(
        state: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(300, 0))],
        ),
      );
      final move = intents.whereType<Phase0aMoveIntent>().single;
      expect(move.actorId, 'e1');
      expect(move.direction, const ArenaVector(-1, 0));
    });

    test('射程内发起普攻且朝向锁定玩家', () {
      final intents = makeEnemyAdapter().intentsFor(
        state: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
      );
      final attack = intents.whereType<Phase0aAttackIntent>().single;
      expect(attack.actorId, 'e1');
      expect(attack.aimDirection, const ArenaVector(-1, 0));
      expect(attack.range, 70);
    });

    test('玩家已倒下时不产生任何 intent', () {
      final intents = makeEnemyAdapter().intentsFor(
        state: makeState(
          player: makePlayer(currentHealth: 0),
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
      );
      expect(intents, isEmpty);
    });
  });

  group('会话入口穿透 adapter → resolver → reducer', () {
    test('玩家与 AI 同一拍经同一 reducer 结算,事件携带运行时结果', () {
      final session = makeSession(
        initialState: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
      );
      final events = session.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      final hits = events.whereType<Phase0aHitLanded>().toList();
      expect(hits.map((h) => h.actor).toSet(), {'player', 'e1'});
      final playerHit = hits.singleWhere((h) => h.actor == 'player');
      expect(playerHit.target, 'e1');
      expect(playerHit.resolvedDamage, 15);
      expect(playerHit.remainingHealth, 45);
      final enemyHit = hits.singleWhere((h) => h.actor == 'e1');
      expect(enemyHit.target, 'player');
      expect(session.state.player.currentHealth, 85);
    });

    test('多拍推进:AI 先逼近后攻击,玩家击杀后事件不再引用死者', () {
      final session = makeSession(
        initialState: makeState(
          enemies: [
            makeEnemy(
              id: 'e1',
              position: const ArenaVector(150, 0),
              currentHealth: 15,
            ),
          ],
        ),
      );
      final allEvents = <Phase0aEvent>[];
      for (var i = 0; i < 6; i++) {
        allEvents.addAll(
          session.advance(
            deltaSeconds: 0.5,
            command: const Phase0aPlayerCommand(attack: true),
          ),
        );
      }
      expect(allEvents.whereType<Phase0aEnemyDefeated>(), hasLength(1));
      final defeatSeq = allEvents.indexWhere(
        (e) => e is Phase0aEnemyDefeated && e.target == 'e1',
      );
      for (var i = defeatSeq + 1; i < allEvents.length; i++) {
        final e = allEvents[i];
        if (e is Phase0aHitLanded) {
          expect(e.target, isNot('e1'));
          expect(e.actor, isNot('e1'));
        }
        expect(e is Phase0aEnemyDefeated && e.target == 'e1', isFalse);
      }
      expect(session.state.enemies, isEmpty);
    });

    test('同初态同指令序列的两个会话得到相等状态与事件序列', () {
      Phase0aArenaState initial() => makeState(
        enemies: [
          makeEnemy(id: 'e1', position: const ArenaVector(260, 40)),
          makeEnemy(id: 'e2', position: const ArenaVector(200, -80)),
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

      List<Phase0aEvent> run(Phase0aCombatSession session) {
        final all = <Phase0aEvent>[];
        for (final command in commands) {
          all.addAll(session.advance(deltaSeconds: 0.2, command: command));
        }
        return all;
      }

      final sessionA = makeSession(initialState: initial());
      final sessionB = makeSession(initialState: initial());
      final eventsA = run(sessionA);
      final eventsB = run(sessionB);
      expect(sessionB.state, sessionA.state);
      expect(eventsB, eventsA);
      expect(eventsA, isNotEmpty);
    });
  });
}
