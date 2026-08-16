import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

/// Phase 0A 确定性 reducer 红测。
///
/// 语义锚 = 派单 `2026-08-16_phase0a_qoder_reducer_input_event_loop.md` 与
/// 冻结反馈契约 `docs/spec/2026-08-16-phase0a-production-feedback-contract.md`:
/// 玩家与 AI 同一 intent 协议进同一 reducer;事件携带运行时结算结果;
/// 合法未命中不伪造 hit;死亡仅一次;稳定排序/去重保确定性。
/// 所有调优数值由测试显式传入,reducer 无默认值。

/// 固定伤害 resolver:确定性、无随机,按伤害种类固定回值。
class FixedDamageResolver implements Phase0aDamageResolver {
  const FixedDamageResolver({
    required this.basicDamage,
    required this.gatherDamage,
    required this.clearDamage,
    this.basicIsHit = true,
  });

  final int basicDamage;
  final int gatherDamage;
  final int clearDamage;
  final bool basicIsHit;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
  }) {
    switch (kind) {
      case Phase0aDamageKind.basic:
        return Phase0aResolvedHit(
          isHit: basicIsHit,
          isCritical: false,
          damage: basicDamage,
        );
      case Phase0aDamageKind.gather:
        return const Phase0aResolvedHit(
          isHit: true,
          isCritical: false,
          damage: 0,
        );
      case Phase0aDamageKind.clear:
        return Phase0aResolvedHit(
          isHit: true,
          isCritical: false,
          damage: clearDamage,
        );
    }
  }
}

Phase0aActor makePlayer({
  ArenaVector position = const ArenaVector(0, 0),
  ArenaVector facing = const ArenaVector(1, 0),
  int currentHealth = 100,
  int qiCurrent = 100,
  double attackCooldownRemaining = 0,
}) {
  return Phase0aActor(
    id: 'player',
    side: Phase0aSide.player,
    position: position,
    facing: facing,
    maxHealth: 100,
    currentHealth: currentHealth,
    moveSpeed: 100,
    qiCurrent: qiCurrent,
    qiMax: 100,
    attackCooldownRemaining: attackCooldownRemaining,
    defeatKind: Phase0aDefeatKind.normal,
  );
}

Phase0aActor makeEnemy({
  required String id,
  required ArenaVector position,
  int currentHealth = 60,
  double attackCooldownRemaining = 0,
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
    attackCooldownRemaining: attackCooldownRemaining,
    defeatKind: Phase0aDefeatKind.normal,
  );
}

Phase0aSkillSlot makeSlot(
  String slot, {
  double cooldownRemaining = 0,
  int qiCost = 20,
  Phase0aSkillAvailability availability = Phase0aSkillAvailability.ready,
}) {
  return Phase0aSkillSlot(
    slot: slot,
    cooldownRemaining: cooldownRemaining,
    qiCost: qiCost,
    availability: availability,
  );
}

Phase0aArenaState makeState({
  Phase0aActor? player,
  List<Phase0aActor>? enemies,
  List<Phase0aSkillSlot>? skillSlots,
  int tick = 0,
  int nextSeq = 1,
}) {
  return Phase0aArenaState(
    tick: tick,
    nextSeq: nextSeq,
    player: player ?? makePlayer(),
    enemies: enemies ?? const [],
    skillSlots: skillSlots ?? const [],
  );
}

Phase0aAttackIntent playerAttack({
  double range = 120,
  double halfArcRadians = math.pi / 4,
  double cooldownSeconds = 1,
  ArenaVector aimDirection = const ArenaVector(1, 0),
}) {
  return Phase0aAttackIntent(
    actorId: 'player',
    range: range,
    halfArcRadians: halfArcRadians,
    cooldownSeconds: cooldownSeconds,
    moveKind: Phase0aMoveKind.light,
    aimDirection: aimDirection,
  );
}

void main() {
  final hitResolver = FixedDamageResolver(
    basicDamage: 25,
    gatherDamage: 0,
    clearDamage: 40,
  );

  group('确定性回放', () {
    test('同初态同输入序列重复回放得到相等状态与事件序列', () {
      Phase0aArenaState state = makeState(
        enemies: [
          makeEnemy(id: 'e1', position: const ArenaVector(80, 0)),
          makeEnemy(id: 'e2', position: const ArenaVector(60, 30)),
        ],
        skillSlots: [makeSlot('gather'), makeSlot('clear')],
      );
      final intentScript = <List<Phase0aIntent>>[
        [
          const Phase0aMoveIntent(
            actorId: 'player',
            direction: ArenaVector(1, 1),
          ),
        ],
        [playerAttack()],
        [
          const Phase0aGatherIntent(
            actorId: 'player',
            slot: 'gather',
            ringRadius: 90,
            qiCost: 20,
            cooldownSeconds: 3,
          ),
        ],
        [
          const Phase0aClearIntent(
            actorId: 'player',
            slot: 'clear',
            qiCost: 30,
            cooldownSeconds: 4,
          ),
        ],
      ];

      Phase0aStepResult runScript() {
        var current = state;
        final allEvents = <Phase0aEvent>[];
        for (final intents in intentScript) {
          final result = reducePhase0aTick(
            state: current,
            intents: intents,
            deltaSeconds: 0.1,
            damageResolver: hitResolver,
          );
          current = result.state;
          allEvents.addAll(result.events);
        }
        return Phase0aStepResult(state: current, events: allEvents);
      }

      final first = runScript();
      final second = runScript();
      expect(second.state, first.state);
      expect(second.events, first.events);
    });

    test('事件 seq 单调递增且 tick 随拍推进', () {
      var state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(60, 0))],
        skillSlots: [makeSlot('gather')],
      );
      final events = <Phase0aEvent>[];
      for (var i = 0; i < 3; i++) {
        final result = reducePhase0aTick(
          state: state,
          intents: [playerAttack(cooldownSeconds: 0)],
          deltaSeconds: 0.1,
          damageResolver: hitResolver,
        );
        state = result.state;
        events.addAll(result.events);
      }
      expect(events, isNotEmpty);
      for (var i = 1; i < events.length; i++) {
        expect(events[i].seq, greaterThan(events[i - 1].seq));
      }
      expect(events.map((e) => e.tick), everyElement(greaterThan(0)));
      expect(state.tick, 3);
    });
  });

  group('统一输入协议与移动', () {
    test('对角移动按单位长度归一,位移等于速度乘时间', () {
      final result = reducePhase0aTick(
        state: makeState(),
        intents: const [
          Phase0aMoveIntent(actorId: 'player', direction: ArenaVector(1, 1)),
        ],
        deltaSeconds: 0.5,
        damageResolver: hitResolver,
      );
      final player = result.state.player;
      expect(player.position.x, closeTo(100 * math.sqrt1_2 * 0.5, 0.0001));
      expect(player.position.y, closeTo(100 * math.sqrt1_2 * 0.5, 0.0001));
      expect(player.facing.length, closeTo(1, 0.0001));
    });

    test('零方向移动不改变位置与朝向', () {
      final initial = makeState(facing: const ArenaVector(0, -1));
      final result = reducePhase0aTick(
        state: initial,
        intents: const [
          Phase0aMoveIntent(actorId: 'player', direction: ArenaVector.zero),
        ],
        deltaSeconds: 0.5,
        damageResolver: hitResolver,
      );
      expect(result.state.player.position, initial.player.position);
      expect(result.state.player.facing, const ArenaVector(0, -1));
    });

    test('敌人 intent 与玩家 intent 走同一 reducer 结算', () {
      final result = reducePhase0aTick(
        state: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(50, 0))],
        ),
        intents: const [
          Phase0aAttackIntent(
            actorId: 'e1',
            range: 80,
            halfArcRadians: 1.0,
            cooldownSeconds: 1,
            moveKind: Phase0aMoveKind.light,
            aimDirection: ArenaVector(-1, 0),
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      final hit = result.events.whereType<Phase0aHitLanded>().single;
      expect(hit.actor, 'e1');
      expect(hit.target, 'player');
      expect(hit.resolvedDamage, 25);
      expect(hit.remainingHealth, 75);
      expect(result.state.player.currentHealth, 75);
      expect(result.state.enemies.single.attackCooldownRemaining, 1);
    });
  });

  group('普攻目标选择与命中', () {
    test('最近目标命中并携带结算伤害与剩余血量', () {
      final result = reducePhase0aTick(
        state: makeState(
          enemies: [
            makeEnemy(id: 'far', position: const ArenaVector(200, 0)),
            makeEnemy(id: 'near', position: const ArenaVector(60, 10)),
          ],
        ),
        intents: [playerAttack()],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      final attack = result.events.whereType<Phase0aAttackStarted>().single;
      expect(attack.actor, 'player');
      expect(attack.moveKind, Phase0aMoveKind.light);
      final hit = result.events.whereType<Phase0aHitLanded>().single;
      expect(hit.target, 'near');
      expect(hit.resolvedDamage, 25);
      expect(hit.remainingHealth, 35);
      expect(result.state.enemies.singleWhere((e) => e.id == 'near')
          .currentHealth, 35);
    });

    test('同距目标按 id 稳定决胜且与输入顺序无关', () {
      final enemiesA = [
        makeEnemy(id: 'e_b', position: const ArenaVector(70, 0)),
        makeEnemy(id: 'e_a', position: const ArenaVector(-70, 0)),
      ];
      final enemiesB = [enemiesA[1], enemiesA[0]];
      String? hitTarget(List<Phase0aActor> enemies) {
        final result = reducePhase0aTick(
          state: makeState(enemies: enemies),
          intents: [
            playerAttack(halfArcRadians: math.pi, aimDirection: ArenaVector.zero),
          ],
          deltaSeconds: 0.1,
          damageResolver: hitResolver,
        );
        return result.events.whereType<Phase0aHitLanded>().single.target;
      }

      expect(hitTarget(enemiesA), 'e_a');
      expect(hitTarget(enemiesB), 'e_a');
    });

    test('resolver 判未命中时只有 attack_started,不伪造 hit', () {
      const missResolver = FixedDamageResolver(
        basicDamage: 25,
        gatherDamage: 0,
        clearDamage: 40,
        basicIsHit: false,
      );
      final result = reducePhase0aTick(
        state: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(60, 0))],
        ),
        intents: [playerAttack()],
        deltaSeconds: 0.1,
        damageResolver: missResolver,
      );
      expect(result.events.whereType<Phase0aAttackStarted>(), hasLength(1));
      expect(result.events.whereType<Phase0aHitLanded>(), isEmpty);
      expect(result.state.enemies.single.currentHealth, 60);
    });

    test('扇区与距离内无目标时只发 attack_started 且不进冷却外结算', () {
      final result = reducePhase0aTick(
        state: makeState(
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(-60, 0))],
        ),
        intents: [playerAttack()],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.events.whereType<Phase0aAttackStarted>(), hasLength(1));
      expect(result.events.whereType<Phase0aHitLanded>(), isEmpty);
      expect(result.state.enemies.single.currentHealth, 60);
      expect(result.state.player.attackCooldownRemaining, 1);
    });

    test('普攻冷却未转好被拒绝,无任何事件', () {
      final result = reducePhase0aTick(
        state: makeState(
          player: makePlayer(attackCooldownRemaining: 0.4),
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(60, 0))],
        ),
        intents: [playerAttack()],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.events, isEmpty);
      expect(result.state.enemies.single.currentHealth, 60);
      expect(result.state.player.attackCooldownRemaining, closeTo(0.3, 0.0001));
    });
  });

  group('死亡与移除', () {
    test('死亡仅一次且其后不再出现该单位相关事件', () {
      var state = makeState(
        enemies: [
          makeEnemy(id: 'e1', position: const ArenaVector(60, 0), currentHealth: 20),
        ],
      );
      final first = reducePhase0aTick(
        state: state,
        intents: [playerAttack()],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      final defeated = first.events.whereType<Phase0aEnemyDefeated>().single;
      expect(defeated.target, 'e1');
      expect(defeated.defeatKind, Phase0aDefeatKind.normal);
      final firstHit = first.events.whereType<Phase0aHitLanded>().single;
      expect(firstHit.remainingHealth, 0);
      expect(first.state.enemies, isEmpty);

      state = first.state;
      final second = reducePhase0aTick(
        state: state,
        intents: [playerAttack()],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(
        second.events.where((e) =>
            e is Phase0aEnemyDefeated ||
            (e is Phase0aHitLanded && e.target == 'e1')),
        isEmpty,
      );
    });

    test('过量伤害不产生重复死亡事件', () {
      final result = reducePhase0aTick(
        state: makeState(
          enemies: [
            makeEnemy(id: 'e1', position: const ArenaVector(60, 0), currentHealth: 5),
          ],
        ),
        intents: [playerAttack()],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.events.whereType<Phase0aEnemyDefeated>(), hasLength(1));
    });
  });

  group('Q 聚怪', () {
    Phase0aGatherIntent gatherIntent({
      double ringRadius = 80,
      int qiCost = 20,
      double cooldownSeconds = 3,
    }) {
      return Phase0aGatherIntent(
        actorId: 'player',
        slot: 'gather',
        ringRadius: ringRadius,
        qiCost: qiCost,
        cooldownSeconds: cooldownSeconds,
      );
    }

    test('环内不推、环外沿来向投影到环上,逐目标 outcomes 稳定有序', () {
      final result = reducePhase0aTick(
        state: makeState(
          enemies: [
            makeEnemy(id: 'e2', position: const ArenaVector(300, 400)),
            makeEnemy(id: 'e1', position: const ArenaVector(30, 40)),
          ],
          skillSlots: [makeSlot('gather')],
        ),
        intents: [gatherIntent(ringRadius: 100)],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.events.whereType<Phase0aGatherStarted>().single.actor,
          'player');
      final applied = result.events.whereType<Phase0aGatherApplied>().single;
      expect(applied.actor, 'player');
      expect(applied.outcomes.map((o) => o.target).toList(), ['e1', 'e2']);
      expect(applied.outcomes[0].statusApplied, Phase0aSkillStatus.none);
      expect(applied.outcomes[1].statusApplied, Phase0aSkillStatus.pulled);
      expect(applied.outcomes.every((o) => !o.defeated), isTrue);

      final byId = {for (final e in result.state.enemies) e.id: e};
      expect(byId['e1']!.position, const ArenaVector(30, 40));
      expect(byId['e2']!.position.x, closeTo(60, 0.0001));
      expect(byId['e2']!.position.y, closeTo(80, 0.0001));
      expect(result.state.player.qiCurrent, 80);
    });

    test('聚怪击杀携带结算伤害与 defeated,死亡事件仅一次', () {
      final resolver = FixedDamageResolver(
        basicDamage: 25,
        gatherDamage: 0,
        clearDamage: 40,
      );
      final gatherResolver = _GatherDamageResolver(inner: resolver, damage: 30);
      final result = reducePhase0aTick(
        state: makeState(
          enemies: [
            makeEnemy(id: 'e1', position: const ArenaVector(200, 0), currentHealth: 20),
          ],
          skillSlots: [makeSlot('gather')],
        ),
        intents: [gatherIntent()],
        deltaSeconds: 0.1,
        damageResolver: gatherResolver,
      );
      final applied = result.events.whereType<Phase0aGatherApplied>().single;
      expect(applied.outcomes.single.resolvedDamage, 30);
      expect(applied.outcomes.single.defeated, isTrue);
      expect(result.events.whereType<Phase0aEnemyDefeated>(), hasLength(1));
      expect(result.state.enemies, isEmpty);
    });

    test('冷却中释放被拒绝:无事件、不耗真气、不重置冷却', () {
      final result = reducePhase0aTick(
        state: makeState(
          skillSlots: [
            makeSlot('gather',
                cooldownRemaining: 1.2,
                availability: Phase0aSkillAvailability.cooldown),
          ],
        ),
        intents: [gatherIntent()],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.events.whereType<Phase0aGatherStarted>(), isEmpty);
      expect(result.events.whereType<Phase0aGatherApplied>(), isEmpty);
      expect(result.state.player.qiCurrent, 100);
      expect(result.state.skillSlots.single.cooldownRemaining,
          closeTo(1.1, 0.0001));
    });

    test('真气不足被拒绝:无事件、不进入冷却', () {
      final result = reducePhase0aTick(
        state: makeState(
          player: makePlayer(qiCurrent: 10),
          skillSlots: [makeSlot('gather')],
        ),
        intents: [gatherIntent(qiCost: 20)],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.events.whereType<Phase0aGatherStarted>(), isEmpty);
      expect(result.state.player.qiCurrent, 10);
      expect(result.state.skillSlots.single.cooldownRemaining, 0);
    });

    test('释放后发 cooldown 可用态事件并携带冷却剩余快照', () {
      final result = reducePhase0aTick(
        state: makeState(skillSlots: [makeSlot('gather')]),
        intents: [gatherIntent(cooldownSeconds: 3)],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      final changed = result.events
          .whereType<Phase0aSkillAvailabilityChanged>()
          .single;
      expect(changed.slot, 'gather');
      expect(changed.availability, Phase0aSkillAvailability.cooldown);
      expect(changed.cooldownRemaining, 3);
      expect(changed.qiCurrent, 80);
      expect(changed.qiRequired, 20);
    });
  });

  group('R 清场', () {
    test('全体存活敌人按 id 稳定顺序结算,真气与冷却正确扣减', () {
      final result = reducePhase0aTick(
        state: makeState(
          enemies: [
            makeEnemy(id: 'e3', position: const ArenaVector(300, 0)),
            makeEnemy(id: 'e1', position: const ArenaVector(100, 0)),
            makeEnemy(id: 'e2', position: const ArenaVector(-200, 50)),
          ],
          skillSlots: [makeSlot('clear', qiCost: 30)],
        ),
        intents: const [
          Phase0aClearIntent(
            actorId: 'player',
            slot: 'clear',
            qiCost: 30,
            cooldownSeconds: 4,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.events.whereType<Phase0aClearStarted>().single.actor,
          'player');
      final applied = result.events.whereType<Phase0aClearApplied>().single;
      expect(applied.outcomes.map((o) => o.target).toList(),
          ['e1', 'e2', 'e3']);
      expect(applied.outcomes.map((o) => o.resolvedDamage).toList(),
          [40, 40, 40]);
      expect(
        applied.outcomes.map((o) => o.statusApplied).toSet(),
        {Phase0aSkillStatus.staggered},
      );
      expect(result.state.player.qiCurrent, 70);
      expect(result.state.skillSlots.single.cooldownRemaining, 4);
    });

    test('清场真气不足被拒绝', () {
      final result = reducePhase0aTick(
        state: makeState(
          player: makePlayer(qiCurrent: 10),
          enemies: [makeEnemy(id: 'e1', position: const ArenaVector(100, 0))],
          skillSlots: [makeSlot('clear', qiCost: 30)],
        ),
        intents: const [
          Phase0aClearIntent(
            actorId: 'player',
            slot: 'clear',
            qiCost: 30,
            cooldownSeconds: 4,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.events.whereType<Phase0aClearStarted>(), isEmpty);
      expect(result.state.enemies.single.currentHealth, 60);
      expect(result.state.player.qiCurrent, 10);
    });
  });

  group('技能可用态运行态字段', () {
    test('冷却倒数到边界归零并发 ready 事件,携带真气快照', () {
      var state = makeState(
        skillSlots: [
          makeSlot('gather',
              cooldownRemaining: 0.1,
              availability: Phase0aSkillAvailability.cooldown),
        ],
      );
      final result = reducePhase0aTick(
        state: state,
        intents: const [],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.state.skillSlots.single.cooldownRemaining, 0);
      final changed = result.events
          .whereType<Phase0aSkillAvailabilityChanged>()
          .single;
      expect(changed.slot, 'gather');
      expect(changed.availability, Phase0aSkillAvailability.ready);
      expect(changed.qiCurrent, 100);
      expect(changed.qiRequired, 20);
    });

    test('冷却转好但真气不足时进入 qi 态', () {
      final result = reducePhase0aTick(
        state: makeState(
          player: makePlayer(qiCurrent: 5),
          skillSlots: [
            makeSlot('gather',
                cooldownRemaining: 0.05,
                availability: Phase0aSkillAvailability.cooldown),
          ],
        ),
        intents: const [],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      final changed = result.events
          .whereType<Phase0aSkillAvailabilityChanged>()
          .single;
      expect(changed.availability, Phase0aSkillAvailability.qi);
      expect(changed.qiCurrent, 5);
      expect(changed.qiRequired, 20);
    });

    test('可用态未变化不重发事件', () {
      final result = reducePhase0aTick(
        state: makeState(
          skillSlots: [
            makeSlot('gather',
                cooldownRemaining: 2,
                availability: Phase0aSkillAvailability.cooldown),
          ],
        ),
        intents: const [],
        deltaSeconds: 0.1,
        damageResolver: hitResolver,
      );
      expect(result.events.whereType<Phase0aSkillAvailabilityChanged>(),
          isEmpty);
    });
  });
}

/// 聚怪固定伤害包装:仅对 gather 种类覆盖伤害值,其余透传。
class _GatherDamageResolver implements Phase0aDamageResolver {
  const _GatherDamageResolver({required this.inner, required this.damage});

  final Phase0aDamageResolver inner;
  final int damage;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
  }) {
    if (kind != Phase0aDamageKind.gather) {
      return inner.resolve(
        attackerId: attackerId,
        targetId: targetId,
        kind: kind,
      );
    }
    return Phase0aResolvedHit(
      isHit: true,
      isCritical: false,
      damage: damage,
    );
  }
}
