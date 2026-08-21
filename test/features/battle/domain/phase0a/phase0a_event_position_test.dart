import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

/// Phase 0A 事件坐标快照批 · reducer 侧验收(组 A + 组 D 回放部分)。
///
/// 根因语义:表现层在 advance 前同步 actors(pre-tick),本拍
/// 移动/拉拽/死亡后再按 id 反查会拿到旧位置;故事件必须携带
/// 结算时坐标快照,生产 reducer 全填,不得依赖表现层回退。

class _Resolver
    implements Phase0aDamageResolver, Phase0aEnemySkillDamageResolver {
  const _Resolver({
    this.basicDamage = 25,
    this.gatherDamage = 0,
    this.clearDamage = 40,
  });

  final int basicDamage;
  final int gatherDamage;
  final int clearDamage;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
  }) {
    final damage = switch (kind) {
      Phase0aDamageKind.basic => basicDamage,
      Phase0aDamageKind.gather => gatherDamage,
      Phase0aDamageKind.clear => clearDamage,
      _ => clearDamage,
    };
    return Phase0aResolvedHit(isHit: true, isCritical: false, damage: damage);
  }

  @override
  Phase0aResolvedHit resolveEnemySkill({
    required String attackerId,
    required String targetId,
    required SkillDef skill,
    bool defenderStaggered = false,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 17);
}

Phase0aActor _player({
  ArenaVector position = const ArenaVector(0, 0),
  int currentHealth = 100,
  int qiCurrent = 100,
}) => Phase0aActor(
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

Phase0aActor _enemy({
  String id = 'e1',
  ArenaVector position = const ArenaVector(60, 0),
  int currentHealth = 60,
  List<String> unlockedEnemySkillIds = const [],
  Phase0aChargeCast? chargeCast,
  Phase0aChargeCast? chargingCast,
  int chargeTicksRemaining = 0,
}) => Phase0aActor(
  id: id,
  side: Phase0aSide.enemy,
  position: position,
  facing: const ArenaVector(-1, 0),
  maxHealth: 60,
  currentHealth: currentHealth,
  moveSpeed: 60,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
  unlockedEnemySkillIds: unlockedEnemySkillIds,
  chargeCast: chargeCast,
  chargingCast: chargingCast,
  chargeTicksRemaining: chargeTicksRemaining,
);

Phase0aArenaState _state({
  Phase0aActor? player,
  List<Phase0aActor> enemies = const [],
  List<Phase0aSkillSlot> skillSlots = const [],
}) => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: player ?? _player(),
  enemies: enemies,
  skillSlots: skillSlots,
);

Phase0aAttackIntent _attack(String actorId, {double range = 120}) =>
    Phase0aAttackIntent(
      actorId: actorId,
      range: range,
      halfArcRadians: math.pi / 4,
      cooldownSeconds: 1,
      qiDelta: 0,
      moveKind: Phase0aMoveKind.light,
      aimDirection: const ArenaVector(1, 0),
    );

const _enemySkill = SkillDef(
  id: 'enemy_skill',
  name: 'enemy_skill',
  description: 'enemy_skill',
  type: SkillType.powerSkill,
  powerMultiplier: 1500,
  qiDelta: 0,
  cooldownTurns: 3,
  requiresManualTrigger: false,
  visualEffect: '',
);

const _chargeSignature = SkillDef(
  id: 'charge_signature',
  name: 'charge_signature',
  description: 'charge_signature',
  type: SkillType.powerSkill,
  powerMultiplier: 2000,
  qiDelta: 0,
  cooldownTurns: 4,
  requiresManualTrigger: false,
  visualEffect: '',
);

Phase0aChargeCast _cast() => Phase0aChargeCast(
  skill: _chargeSignature,
  chargeTicks: 3,
  attackRange: 10,
  halfArcRadians: 1,
  effectRadius: 10,
  cooldownSeconds: 4,
  actionCooldownSeconds: 1,
);

const _gatherSlot = Phase0aSkillSlot(
  slot: 'gather',
  cooldownRemaining: 0,
  qiCost: 20,
  availability: Phase0aSkillAvailability.ready,
);

const _clearSlot = Phase0aSkillSlot(
  slot: 'clear',
  cooldownRemaining: 0,
  qiCost: 20,
  availability: Phase0aSkillAvailability.ready,
);

const _skill1Slot = Phase0aSkillSlot(
  slot: 'skill1',
  cooldownRemaining: 0,
  qiCost: 0,
  availability: Phase0aSkillAvailability.ready,
);

void main() {
  group('A · 普攻/敌技/蓄力 HitLanded 结算时坐标', () {
    test('同拍 move+attack:HitLanded 携带移动后出手点与目标位置', () {
      final result = reducePhase0aTick(
        state: _state(enemies: [_enemy(position: const ArenaVector(60, 0))]),
        intents: [
          const Phase0aMoveIntent(
            actorId: 'player',
            direction: ArenaVector(1, 0),
          ),
          _attack('player'),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(),
      );
      final hit = result.events.whereType<Phase0aHitLanded>().single;
      // 同批内移动先于攻击结算(移速 100 × 0.1 = 10):
      // 出手点必须是本拍移动后坐标,不是拍初位置。
      expect(hit.actorPosition, const ArenaVector(10, 0));
      expect(hit.actorPosition, isNot(const ArenaVector(0, 0)));
      expect(hit.targetPosition, const ArenaVector(60, 0));
    });

    test('敌方同拍 move+attack 也携带双坐标', () {
      final result = reducePhase0aTick(
        state: _state(
          enemies: [_enemy(position: const ArenaVector(-60, 0))],
        ),
        intents: [
          const Phase0aMoveIntent(
            actorId: 'e1',
            direction: ArenaVector(1, 0),
          ),
          _attack('e1'),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(),
      );
      final hit = result.events.whereType<Phase0aHitLanded>().single;
      // e1 移速 60 × 0.1 = 6,从 -60 移动到 -54 后出手。
      expect(hit.actorPosition, const ArenaVector(-54, 0));
      expect(hit.targetPosition, const ArenaVector(0, 0));
    });

    test('基础普攻击杀:EnemyDefeated 携带移除前坐标', () {
      final result = reducePhase0aTick(
        state: _state(
          enemies: [
            _enemy(position: const ArenaVector(50, 0), currentHealth: 10),
          ],
        ),
        intents: [_attack('player')],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(),
      );
      final defeated = result.events.whereType<Phase0aEnemyDefeated>().single;
      expect(defeated.targetPosition, const ArenaVector(50, 0));
    });

    test('敌技释放 HitLanded 携带双坐标', () {
      final result = reducePhase0aTick(
        state: _state(
          enemies: [
            _enemy(
              position: const ArenaVector(0, -50),
              unlockedEnemySkillIds: const ['enemy_skill'],
            ),
          ],
        ),
        intents: const [
          Phase0aEnemySkillIntent(
            actorId: 'e1',
            skill: _enemySkill,
            aimDirection: ArenaVector(0, 1),
            range: 120,
            halfArcRadians: math.pi / 4,
            effectRadius: 0,
            cooldownSeconds: 4,
            actionCooldownSeconds: 1,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(),
        enemySkillDamageResolver: const _Resolver(),
      );
      final hit = result.events.whereType<Phase0aHitLanded>().single;
      expect(hit.actorPosition, const ArenaVector(0, -50));
      expect(hit.targetPosition, const ArenaVector(0, 0));
      expect(hit.moveKind, Phase0aMoveKind.heavy);
    });

    test('蓄力拍尾释放 HitLanded 携带双坐标', () {
      final result = reducePhase0aTick(
        state: _state(
          enemies: [
            _enemy(
              position: const ArenaVector(1, 0),
              chargeCast: _cast(),
              chargingCast: _cast(),
              chargeTicksRemaining: 1,
            ),
          ],
        ),
        intents: const [],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(),
        enemySkillDamageResolver: const _Resolver(),
      );
      final hit = result.events.whereType<Phase0aHitLanded>().single;
      expect(hit.actorPosition, const ArenaVector(1, 0));
      expect(hit.targetPosition, const ArenaVector(0, 0));
    });
  });

  group('A · Q/R/数字技能 started 与 outcome 坐标', () {
    test('Q started 携带施放点;outcome source=拉前位置、target=真实环点', () {
      final result = reducePhase0aTick(
        state: _state(
          enemies: [_enemy(position: const ArenaVector(200, 0))],
          skillSlots: const [_gatherSlot],
        ),
        intents: const [
          Phase0aGatherIntent(
            actorId: 'player',
            slot: 'gather',
            ringRadius: 90,
            effectRadius: 500,
            qiCost: 20,
            cooldownSeconds: 3,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(),
      );
      final started = result.events.whereType<Phase0aGatherStarted>().single;
      expect(started.actorPosition, const ArenaVector(0, 0));
      final applied = result.events.whereType<Phase0aGatherApplied>().single;
      final outcome = applied.outcomes.single;
      expect(outcome.sourcePosition, const ArenaVector(200, 0));
      expect(outcome.targetPosition, const ArenaVector(90, 0));
      // 不得把 Q 落点写成玩家中心。
      expect(outcome.targetPosition, isNot(const ArenaVector(0, 0)));
    });

    test('Q 同拍移动后施放:started 坐标是移动后施放点', () {
      final result = reducePhase0aTick(
        state: _state(
          enemies: [_enemy(position: const ArenaVector(200, 0))],
          skillSlots: const [_gatherSlot],
        ),
        intents: const [
          Phase0aMoveIntent(actorId: 'player', direction: ArenaVector(1, 0)),
          Phase0aGatherIntent(
            actorId: 'player',
            slot: 'gather',
            ringRadius: 90,
            effectRadius: 500,
            qiCost: 20,
            cooldownSeconds: 3,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(),
      );
      final started = result.events.whereType<Phase0aGatherStarted>().single;
      expect(started.actorPosition, const ArenaVector(10, 0));
      // 环点以施放时玩家位置为圆心。
      final outcome = result.events
          .whereType<Phase0aGatherApplied>()
          .single
          .outcomes
          .single;
      expect(outcome.targetPosition, const ArenaVector(100, 0));
    });

    test('Q 击杀:死亡事件保留拉后环点,不丢回原位置', () {
      final result = reducePhase0aTick(
        state: _state(
          enemies: [
            _enemy(position: const ArenaVector(200, 0), currentHealth: 10),
          ],
          skillSlots: const [_gatherSlot],
        ),
        intents: const [
          Phase0aGatherIntent(
            actorId: 'player',
            slot: 'gather',
            ringRadius: 90,
            effectRadius: 500,
            qiCost: 20,
            cooldownSeconds: 3,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(basicDamage: 25, gatherDamage: 999),
      );
      final defeated = result.events.whereType<Phase0aEnemyDefeated>().single;
      expect(defeated.targetPosition, const ArenaVector(90, 0));
      expect(defeated.targetPosition, isNot(const ArenaVector(200, 0)));
    });

    test('R started 携带施放点;多目标 outcome 各带结算时位置', () {
      final result = reducePhase0aTick(
        state: _state(
          enemies: [
            _enemy(id: 'e1', position: const ArenaVector(40, 0)),
            _enemy(id: 'e2', position: const ArenaVector(-30, 20)),
          ],
          skillSlots: const [_clearSlot],
        ),
        intents: const [
          Phase0aClearIntent(
            actorId: 'player',
            slot: 'clear',
            effectRadius: 500,
            qiCost: 20,
            cooldownSeconds: 4,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(clearDamage: 40),
      );
      final started = result.events.whereType<Phase0aClearStarted>().single;
      expect(started.actorPosition, const ArenaVector(0, 0));
      final applied = result.events.whereType<Phase0aClearApplied>().single;
      expect(applied.outcomes, hasLength(2));
      final byTarget = {
        for (final outcome in applied.outcomes) outcome.target: outcome,
      };
      expect(byTarget['e1']!.sourcePosition, const ArenaVector(0, 0));
      expect(byTarget['e1']!.targetPosition, const ArenaVector(40, 0));
      expect(byTarget['e2']!.sourcePosition, const ArenaVector(0, 0));
      expect(byTarget['e2']!.targetPosition, const ArenaVector(-30, 20));
    });

    test('数字技能 aoe:多目标 outcome 各带自己的目标坐标', () {
      final result = reducePhase0aTick(
        state: _state(
          enemies: [
            _enemy(id: 'e1', position: const ArenaVector(30, 10)),
            _enemy(id: 'e2', position: const ArenaVector(-20, -40)),
          ],
          skillSlots: const [_skill1Slot],
        ),
        intents: const [
          Phase0aSkillIntent(
            actorId: 'player',
            kind: Phase0aDamageKind.skill1,
            slot: 'skill1',
            skillId: 'skill_a',
            targetType: TargetType.aoe,
            aimDirection: ArenaVector(1, 0),
            range: 0,
            halfArcRadians: 0,
            effectRadius: 500,
            qiDelta: 0,
            cooldownSeconds: 2,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _Resolver(),
      );
      final applied = result.events.whereType<Phase0aSkillApplied>().single;
      expect(applied.outcomes, hasLength(2));
      final byTarget = {
        for (final outcome in applied.outcomes) outcome.target: outcome,
      };
      expect(byTarget['e1']!.targetPosition, const ArenaVector(30, 10));
      expect(byTarget['e2']!.targetPosition, const ArenaVector(-20, -40));
      expect(byTarget['e1']!.sourcePosition, const ArenaVector(0, 0));
    });
  });

  group('D · 坐标纳入等值与确定性回放', () {
    test('SkillOutcome 坐标差异参与等值与 hashCode', () {
      const base = Phase0aSkillOutcome(
        target: 'e1',
        resolvedDamage: 10,
        isCritical: false,
        defeated: false,
        statusApplied: Phase0aSkillStatus.pulled,
        sourcePosition: ArenaVector(200, 0),
        targetPosition: ArenaVector(90, 0),
      );
      const same = Phase0aSkillOutcome(
        target: 'e1',
        resolvedDamage: 10,
        isCritical: false,
        defeated: false,
        statusApplied: Phase0aSkillStatus.pulled,
        sourcePosition: ArenaVector(200, 0),
        targetPosition: ArenaVector(90, 0),
      );
      const differentTarget = Phase0aSkillOutcome(
        target: 'e1',
        resolvedDamage: 10,
        isCritical: false,
        defeated: false,
        statusApplied: Phase0aSkillStatus.pulled,
        sourcePosition: ArenaVector(200, 0),
        targetPosition: ArenaVector(91, 0),
      );
      const differentSource = Phase0aSkillOutcome(
        target: 'e1',
        resolvedDamage: 10,
        isCritical: false,
        defeated: false,
        statusApplied: Phase0aSkillStatus.pulled,
        sourcePosition: ArenaVector(201, 0),
        targetPosition: ArenaVector(90, 0),
      );
      const legacy = Phase0aSkillOutcome(
        target: 'e1',
        resolvedDamage: 10,
        isCritical: false,
        defeated: false,
        statusApplied: Phase0aSkillStatus.pulled,
      );
      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(differentTarget));
      expect(base.hashCode, isNot(differentTarget.hashCode));
      expect(base, isNot(differentSource));
      expect(base, isNot(legacy));
    });

    test('HitLanded/EnemyDefeated/started 事件坐标参与等值', () {
      const hitA = Phase0aHitLanded(
        seq: 1,
        tick: 1,
        actor: 'player',
        target: 'e1',
        moveKind: Phase0aMoveKind.light,
        isCritical: false,
        isUltimate: false,
        resolvedDamage: 10,
        remainingHealth: 50,
        actorPosition: ArenaVector(10, 0),
        targetPosition: ArenaVector(60, 0),
      );
      const hitSame = Phase0aHitLanded(
        seq: 1,
        tick: 1,
        actor: 'player',
        target: 'e1',
        moveKind: Phase0aMoveKind.light,
        isCritical: false,
        isUltimate: false,
        resolvedDamage: 10,
        remainingHealth: 50,
        actorPosition: ArenaVector(10, 0),
        targetPosition: ArenaVector(60, 0),
      );
      const hitNoCoords = Phase0aHitLanded(
        seq: 1,
        tick: 1,
        actor: 'player',
        target: 'e1',
        moveKind: Phase0aMoveKind.light,
        isCritical: false,
        isUltimate: false,
        resolvedDamage: 10,
        remainingHealth: 50,
      );
      expect(hitA, hitSame);
      expect(hitA.hashCode, hitSame.hashCode);
      expect(hitA, isNot(hitNoCoords));

      const defeatA = Phase0aEnemyDefeated(
        seq: 2,
        tick: 1,
        target: 'e1',
        defeatKind: Phase0aDefeatKind.normal,
        targetPosition: ArenaVector(90, 0),
      );
      const defeatB = Phase0aEnemyDefeated(
        seq: 2,
        tick: 1,
        target: 'e1',
        defeatKind: Phase0aDefeatKind.normal,
        targetPosition: ArenaVector(200, 0),
      );
      expect(defeatA, isNot(defeatB));

      const gatherA = Phase0aGatherStarted(
        seq: 3,
        tick: 1,
        actor: 'player',
        actorPosition: ArenaVector(10, 0),
      );
      const gatherB = Phase0aGatherStarted(
        seq: 3,
        tick: 1,
        actor: 'player',
        actorPosition: ArenaVector(0, 0),
      );
      expect(gatherA, isNot(gatherB));

      const clearA = Phase0aClearStarted(
        seq: 4,
        tick: 1,
        actor: 'player',
        actorPosition: ArenaVector(10, 0),
      );
      const clearB = Phase0aClearStarted(
        seq: 4,
        tick: 1,
        actor: 'player',
        actorPosition: ArenaVector(0, 0),
      );
      expect(clearA, isNot(clearB));
    });

    test('同初态同输入重复回放:含坐标事件序列全等', () {
      final state = _state(
        enemies: [
          _enemy(id: 'e1', position: const ArenaVector(80, 0)),
          _enemy(id: 'e2', position: const ArenaVector(200, 30)),
        ],
        skillSlots: const [_gatherSlot, _clearSlot],
      );
      final script = <List<Phase0aIntent>>[
        [
          const Phase0aMoveIntent(
            actorId: 'player',
            direction: ArenaVector(1, 1),
          ),
        ],
        [_attack('player')],
        [
          const Phase0aGatherIntent(
            actorId: 'player',
            slot: 'gather',
            ringRadius: 90,
            effectRadius: 500,
            qiCost: 20,
            cooldownSeconds: 3,
          ),
        ],
        [
          const Phase0aClearIntent(
            actorId: 'player',
            slot: 'clear',
            effectRadius: 500,
            qiCost: 20,
            cooldownSeconds: 4,
          ),
        ],
      ];

      List<Phase0aEvent> run() {
        var current = state;
        final all = <Phase0aEvent>[];
        for (final intents in script) {
          final result = reducePhase0aTick(
            state: current,
            intents: intents,
            deltaSeconds: 0.1,
            damageResolver: const _Resolver(),
          );
          current = result.state;
          all.addAll(result.events);
        }
        return all;
      }

      final first = run();
      final second = run();
      expect(second, first);
      // 回放的事件确实携带坐标(防止「全等」因字段全空而空转)。
      final hits = first.whereType<Phase0aHitLanded>().toList();
      expect(hits, isNotEmpty);
      for (final hit in hits) {
        expect(hit.actorPosition, isNotNull);
        expect(hit.targetPosition, isNotNull);
      }
    });
  });
}
