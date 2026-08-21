import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

/// Phase 0A reducer 边界守卫红测(Kimi 交叉复核,派单加验两项)。
///
/// ① player-only 技能契约:敌方/AI 注入 gather/clear 不得消费玩家全局
/// skillSlots、不得改变玩家 HUD 事件流/真气/位置——reducer 必须拒绝,
/// 禁止静默污染。
/// ② 数值边界:deltaSeconds 与 intent 外部 double 参数一律要求 finite 且
/// 非负,非法即明确拒绝(deltaSeconds 抛 ArgumentError;非法 intent 静默
/// 拒绝,与既有 `ringRadius > effectRadius` 同款语义);resolver 返回负伤害
/// 抛 StateError fail-fast,不 clamp 掩盖公式错误。

/// 可配伤害的固定 resolver(确定性、无随机)。
class GuardDamageResolver implements Phase0aDamageResolver {
  const GuardDamageResolver({
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
  }) {
    final damage = switch (kind) {
      Phase0aDamageKind.basic => basicDamage,
      Phase0aDamageKind.gather => gatherDamage,
      Phase0aDamageKind.clear => clearDamage,
      Phase0aDamageKind.skill1 ||
      Phase0aDamageKind.skill2 ||
      Phase0aDamageKind.skill3 ||
      Phase0aDamageKind.skill4 ||
      Phase0aDamageKind.skill5 ||
      Phase0aDamageKind.skill6 => clearDamage,
    };
    return Phase0aResolvedHit(isHit: true, isCritical: false, damage: damage);
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
  int qiCurrent = 0,
  int qiMax = 0,
}) {
  return Phase0aActor(
    id: id,
    side: Phase0aSide.enemy,
    position: position,
    facing: const ArenaVector(-1, 0),
    maxHealth: 60,
    currentHealth: currentHealth,
    moveSpeed: 60,
    qiCurrent: qiCurrent,
    qiMax: qiMax,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  );
}

Phase0aSkillSlot makeSlot(String slot) {
  return Phase0aSkillSlot(
    slot: slot,
    cooldownRemaining: 0,
    qiCost: 20,
    availability: Phase0aSkillAvailability.ready,
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
    skillSlots: skillSlots ?? const [],
  );
}

Phase0aAttackIntent attackIntent({
  String actorId = 'player',
  double range = 120,
  double halfArcRadians = math.pi / 4,
  double cooldownSeconds = 1,
}) {
  return Phase0aAttackIntent(
    actorId: actorId,
    range: range,
    halfArcRadians: halfArcRadians,
    cooldownSeconds: cooldownSeconds,
    qiDelta: 0,
    moveKind: Phase0aMoveKind.light,
    aimDirection: const ArenaVector(1, 0),
  );
}

Phase0aGatherIntent gatherIntent({
  String actorId = 'player',
  String slot = 'gather',
  double ringRadius = 90,
  double effectRadius = 500,
  int qiCost = 20,
  double cooldownSeconds = 3,
}) {
  return Phase0aGatherIntent(
    actorId: actorId,
    slot: slot,
    ringRadius: ringRadius,
    effectRadius: effectRadius,
    qiCost: qiCost,
    cooldownSeconds: cooldownSeconds,
  );
}

Phase0aClearIntent clearIntent({
  String actorId = 'player',
  String slot = 'clear',
  double effectRadius = 500,
  int qiCost = 30,
  double cooldownSeconds = 4,
}) {
  return Phase0aClearIntent(
    actorId: actorId,
    slot: slot,
    effectRadius: effectRadius,
    qiCost: qiCost,
    cooldownSeconds: cooldownSeconds,
  );
}

Phase0aStepResult runTick(
  Phase0aArenaState state,
  List<Phase0aIntent> intents, {
  double deltaSeconds = 0,
  Phase0aDamageResolver damageResolver = const GuardDamageResolver(),
}) {
  return reducePhase0aTick(
    state: state,
    intents: intents,
    deltaSeconds: deltaSeconds,
    damageResolver: damageResolver,
  );
}

void main() {
  group('player-only 技能契约(敌方注入 gather/clear 必须拒绝)', () {
    test('敌方 gather:无事件、玩家槽/真气/位置零污染、敌方真气不动', () {
      final state = makeState(
        enemies: [
          makeEnemy(
            id: 'e1',
            position: const ArenaVector(100, 0),
            qiCurrent: 100,
            qiMax: 100,
          ),
        ],
        skillSlots: [makeSlot('gather'), makeSlot('clear')],
      );
      final result = runTick(state, [gatherIntent(actorId: 'e1')]);

      expect(result.events, isEmpty);
      expect(result.state.skillSlots, state.skillSlots);
      expect(result.state.player, state.player);
      expect(result.state.enemies.single.qiCurrent, 100);
    });

    test('敌方 clear:无事件、玩家槽/真气/位置零污染、敌方真气不动', () {
      final state = makeState(
        enemies: [
          makeEnemy(
            id: 'e1',
            position: const ArenaVector(100, 0),
            qiCurrent: 100,
            qiMax: 100,
          ),
        ],
        skillSlots: [makeSlot('gather'), makeSlot('clear')],
      );
      final result = runTick(state, [clearIntent(actorId: 'e1')]);

      expect(result.events, isEmpty);
      expect(result.state.skillSlots, state.skillSlots);
      expect(result.state.player, state.player);
      expect(result.state.enemies.single.qiCurrent, 100);
    });

    test('玩家 gather 仍正常结算(player-only 不误伤合法路径)', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(100, 0))],
        skillSlots: [makeSlot('gather')],
      );
      final result = runTick(state, [gatherIntent()]);

      expect(
        result.events.whereType<Phase0aGatherApplied>().single.outcomes,
        hasLength(1),
      );
      expect(result.state.player.qiCurrent, 80);
    });
  });

  group('deltaSeconds 边界(非 finite 或负 → ArgumentError)', () {
    final state = makeState();

    test('负 deltaSeconds 抛 ArgumentError', () {
      expect(
        () => runTick(state, const [], deltaSeconds: -0.1),
        throwsArgumentError,
      );
    });

    test('NaN deltaSeconds 抛 ArgumentError', () {
      expect(
        () => runTick(state, const [], deltaSeconds: double.nan),
        throwsArgumentError,
      );
    });

    test('Infinity deltaSeconds 抛 ArgumentError', () {
      expect(
        () => runTick(state, const [], deltaSeconds: double.infinity),
        throwsArgumentError,
      );
    });
  });

  group('intent 数值边界(非 finite 或负 → 静默拒绝该 intent)', () {
    test('负 range 普攻:无 attack_started、目标不掉血', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(80, 0))],
      );
      final result = runTick(state, [attackIntent(range: -120)]);

      expect(result.events, isEmpty);
      expect(result.state.enemies.single.currentHealth, 60);
    });

    test('NaN range 普攻:无 attack_started、目标不掉血', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(80, 0))],
      );
      final result = runTick(state, [attackIntent(range: double.nan)]);

      expect(result.events, isEmpty);
      expect(result.state.enemies.single.currentHealth, 60);
    });

    test('负 halfArcRadians 普攻:无 attack_started', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(80, 0))],
      );
      final result = runTick(state, [attackIntent(halfArcRadians: -1)]);

      expect(result.events, isEmpty);
    });

    test('负 cooldownSeconds 普攻:无 attack_started、不置冷却', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(80, 0))],
      );
      final result = runTick(state, [attackIntent(cooldownSeconds: -1)]);

      expect(result.events, isEmpty);
      expect(result.state.player.attackCooldownRemaining, 0);
    });

    test('负 effectRadius 聚怪:无事件、不耗气、不动冷却', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(100, 0))],
        skillSlots: [makeSlot('gather')],
      );
      final result = runTick(state, [gatherIntent(effectRadius: -500)]);

      expect(result.events, isEmpty);
      expect(result.state.player.qiCurrent, 100);
      expect(result.state.skillSlots, state.skillSlots);
    });

    test('NaN effectRadius 清场:无事件、不耗气、不动冷却', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(100, 0))],
        skillSlots: [makeSlot('clear')],
      );
      final result = runTick(state, [clearIntent(effectRadius: double.nan)]);

      expect(result.events, isEmpty);
      expect(result.state.player.qiCurrent, 100);
      expect(result.state.skillSlots, state.skillSlots);
    });

    test('负 ringRadius 聚怪:无事件、不耗气、目标不位移', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(300, 0))],
        skillSlots: [makeSlot('gather')],
      );
      final result = runTick(state, [gatherIntent(ringRadius: -90)]);

      expect(result.events, isEmpty);
      expect(result.state.player.qiCurrent, 100);
      expect(result.state.enemies.single.position, const ArenaVector(300, 0));
    });

    test('负 cooldownSeconds 技能:无事件、不置槽冷却', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(100, 0))],
        skillSlots: [makeSlot('gather')],
      );
      final result = runTick(state, [gatherIntent(cooldownSeconds: -3)]);

      expect(result.events, isEmpty);
      expect(result.state.skillSlots, state.skillSlots);
    });

    test('负 qiCost 技能:无事件、真气不反增', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(100, 0))],
        skillSlots: [makeSlot('gather')],
      );
      final result = runTick(state, [gatherIntent(qiCost: -20)]);

      expect(result.events, isEmpty);
      expect(result.state.player.qiCurrent, 100);
    });
  });

  group('resolver 负伤害 fail-fast(StateError,不 clamp 不掩盖)', () {
    test('普攻负伤害抛 StateError,状态不被修改', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(80, 0))],
      );
      expect(
        () => runTick(
          state,
          [attackIntent()],
          damageResolver: const GuardDamageResolver(
            basicDamage: -10,
            gatherDamage: 0,
            clearDamage: 40,
          ),
        ),
        throwsStateError,
      );
    });

    test('清场负伤害抛 StateError,状态不被修改', () {
      final state = makeState(
        enemies: [makeEnemy(id: 'e1', position: const ArenaVector(100, 0))],
        skillSlots: [makeSlot('clear')],
      );
      expect(
        () => runTick(
          state,
          [clearIntent()],
          damageResolver: const GuardDamageResolver(
            basicDamage: 25,
            gatherDamage: 0,
            clearDamage: -40,
          ),
        ),
        throwsStateError,
      );
    });
  });
}
