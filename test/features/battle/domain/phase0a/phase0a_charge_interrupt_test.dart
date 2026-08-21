import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_skill_binding.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

/// Phase 0A Boss 蓄力 / 玩家破招纵切 focused 契约测(spec 2026-08-22)。
///
/// 语义基准 = 旧引擎 default_ground_strategy 的蓄力/破招层:蓄力倒计时归零
/// 释放招牌技、破招清蓄力+踉跄+招牌技上 CD、踉跄/蓄力中跳过行动;数值全部
/// 由 fixture 显式传入(对齐 numbers.combat.boss_charge 的预解析口径)。

const _signatureSkill = SkillDef(
  id: 'charge_signature',
  name: 'charge_signature',
  description: 'charge_signature',
  type: SkillType.powerSkill,
  powerMultiplier: 2000,
  qiDelta: -30,
  cooldownTurns: 4,
  requiresManualTrigger: false,
  visualEffect: '',
);

const _phaseSignatureSkill = SkillDef(
  id: 'phase_signature',
  name: 'phase_signature',
  description: 'phase_signature',
  type: SkillType.powerSkill,
  powerMultiplier: 1800,
  qiDelta: -20,
  cooldownTurns: 3,
  requiresManualTrigger: false,
  visualEffect: '',
);

Phase0aChargeCast _cast({SkillDef skill = _signatureSkill}) =>
    Phase0aChargeCast(
      skill: skill,
      chargeTicks: 3,
      attackRange: 10,
      halfArcRadians: 1,
      effectRadius: 10,
      cooldownSeconds: 4,
      actionCooldownSeconds: 1,
    );

final class _Resolver
    implements Phase0aDamageResolver, Phase0aEnemySkillDamageResolver {
  _Resolver({required this.basicDamage, this.hit = true});

  final int basicDamage;
  final bool hit;
  final List<String> staggeredTargets = [];

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
  }) {
    if (defenderStaggered) staggeredTargets.add(targetId);
    return Phase0aResolvedHit(
      isHit: hit,
      isCritical: false,
      damage: basicDamage,
    );
  }

  @override
  Phase0aResolvedHit resolveEnemySkill({
    required String attackerId,
    required String targetId,
    required SkillDef skill,
    bool defenderStaggered = false,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 17);
}

Phase0aActor _player({int qiCurrent = 100}) => Phase0aActor(
  id: 'player',
  side: Phase0aSide.player,
  position: ArenaVector.zero,
  facing: const ArenaVector(1, 0),
  maxHealth: 200,
  currentHealth: 200,
  moveSpeed: 100,
  qiCurrent: qiCurrent,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aActor _charger({
  int chargeTicksRemaining = 0,
  Phase0aChargeCast? chargingCast,
  int staggerTicksRemaining = 0,
  int qiCurrent = 100,
  Map<String, double> enemySkillCooldowns = const {},
  List<BossPhaseDef>? bossPhases,
  List<Phase0aChargeCast?> phaseChargeCasts = const [],
  int currentHealth = 100,
}) => Phase0aActor(
  id: 'boss',
  side: Phase0aSide.enemy,
  position: const ArenaVector(1, 0),
  facing: const ArenaVector(-1, 0),
  maxHealth: 100,
  currentHealth: currentHealth,
  moveSpeed: 50,
  qiCurrent: qiCurrent,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.elite,
  chargeCast: _cast(),
  staggerTicksTotal: 2,
  chargeTicksRemaining: chargeTicksRemaining,
  chargingCast: chargingCast,
  staggerTicksRemaining: staggerTicksRemaining,
  enemySkillCooldowns: enemySkillCooldowns,
  bossPhases: bossPhases,
  phaseChargeCasts: phaseChargeCasts,
);

Phase0aArenaState _state(
  Phase0aActor boss, {
  Phase0aActor? player,
  List<Phase0aSkillSlot> slots = const [],
}) => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: player ?? _player(),
  enemies: [boss],
  skillSlots: slots,
);

Phase0aEnemySkillIntent _chargeSkillIntent() => const Phase0aEnemySkillIntent(
  actorId: 'boss',
  skill: _signatureSkill,
  aimDirection: ArenaVector(-1, 0),
  range: 10,
  halfArcRadians: 1,
  effectRadius: 10,
  cooldownSeconds: 4,
  actionCooldownSeconds: 1,
);

Phase0aClearIntent _clearIntent({int breakPower = 0}) => Phase0aClearIntent(
  actorId: 'player',
  slot: 'clear',
  effectRadius: 500,
  qiCost: 20,
  cooldownSeconds: 8,
  skillId: 'skill_phase0a_clear',
  breakPower: breakPower,
);

List<Phase0aSkillSlot> _clearSlot() => const [
  Phase0aSkillSlot(
    slot: 'clear',
    cooldownRemaining: 0,
    qiCost: 20,
    availability: Phase0aSkillAvailability.ready,
  ),
];

void main() {
  test('顶层招牌技 intent 起手蓄力:不出伤、不上 CD、不耗真气', () {
    final result = reducePhase0aTick(
      state: _state(_charger()),
      intents: [_chargeSkillIntent()],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 5),
      enemySkillDamageResolver: _Resolver(basicDamage: 5),
    );

    final started = result.events.whereType<Phase0aBossChargeStarted>();
    expect(started, hasLength(1));
    expect(started.single.actor, 'boss');
    expect(started.single.skillId, 'charge_signature');
    expect(started.single.chargeTicks, 3);
    expect(result.events.whereType<Phase0aEnemySkillStarted>(), isEmpty);
    expect(result.events.whereType<Phase0aHitLanded>(), isEmpty);

    final boss = result.state.enemies.single;
    expect(boss.chargeTicksRemaining, 3);
    expect(boss.chargingCast, isNotNull);
    expect(boss.chargingCast!.skill.id, 'charge_signature');
    expect(boss.enemySkillCooldowns, isEmpty);
    expect(boss.qiCurrent, 100);
  });

  test('蓄力倒计时:未满不出手,归零当拍释放且仅一次', () {
    final resolver = _Resolver(basicDamage: 5);
    final state = _state(
      _charger(chargeTicksRemaining: 3, chargingCast: _cast()),
    );

    final first = reducePhase0aTick(
      state: state,
      intents: const [],
      deltaSeconds: 0.1,
      damageResolver: resolver,
      enemySkillDamageResolver: resolver,
    );
    expect(first.events.whereType<Phase0aEnemySkillStarted>(), isEmpty);
    expect(first.state.enemies.single.chargeTicksRemaining, 2);

    final second = reducePhase0aTick(
      state: first.state,
      intents: const [],
      deltaSeconds: 0.1,
      damageResolver: resolver,
      enemySkillDamageResolver: resolver,
    );
    expect(second.events.whereType<Phase0aEnemySkillStarted>(), isEmpty);
    expect(second.state.enemies.single.chargeTicksRemaining, 1);

    final third = reducePhase0aTick(
      state: second.state,
      intents: const [],
      deltaSeconds: 0.1,
      damageResolver: resolver,
      enemySkillDamageResolver: resolver,
    );
    final fired = third.events.whereType<Phase0aEnemySkillStarted>();
    expect(fired, hasLength(1));
    expect(fired.single.skillId, 'charge_signature');
    final hits = third.events.whereType<Phase0aHitLanded>();
    expect(hits, hasLength(1));
    expect(hits.single.target, 'player');
    expect(hits.single.resolvedDamage, 17);
    expect(third.state.player.currentHealth, 183);

    final boss = third.state.enemies.single;
    expect(boss.chargeTicksRemaining, 0);
    expect(boss.chargingCast, isNull);
    expect(boss.enemySkillCooldowns['charge_signature'], 4);
    expect(boss.qiCurrent, 70);
    expect(boss.attackCooldownRemaining, 1);

    final fourth = reducePhase0aTick(
      state: third.state,
      intents: const [],
      deltaSeconds: 0.1,
      damageResolver: resolver,
      enemySkillDamageResolver: resolver,
    );
    expect(fourth.events.whereType<Phase0aEnemySkillStarted>(), isEmpty);
  });

  test('蓄力/踉跄期间移动、普攻、技能 intent 全部被拒', () {
    for (final suppressed in [
      _charger(chargeTicksRemaining: 2, chargingCast: _cast()),
      _charger(staggerTicksRemaining: 2),
    ]) {
      final before = suppressed;
      final result = reducePhase0aTick(
        state: _state(suppressed),
        intents: [
          const Phase0aMoveIntent(
            actorId: 'boss',
            direction: ArenaVector(-1, 0),
          ),
          const Phase0aAttackIntent(
            actorId: 'boss',
            range: 10,
            halfArcRadians: 1,
            cooldownSeconds: 1,
            moveKind: Phase0aMoveKind.light,
            aimDirection: ArenaVector(-1, 0),
            qiDelta: 0,
          ),
          _chargeSkillIntent(),
        ],
        deltaSeconds: 0.1,
        damageResolver: _Resolver(basicDamage: 5),
        enemySkillDamageResolver: _Resolver(basicDamage: 5),
      );
      final boss = result.state.enemies.single;
      expect(boss.position, before.position, reason: '压制期不得移动');
      expect(result.events.whereType<Phase0aAttackStarted>(), isEmpty);
      expect(
        result.events.whereType<Phase0aBossChargeStarted>(),
        isEmpty,
        reason: '压制期不得起手蓄力',
      );
      expect(result.state.player.currentHealth, 200);
    }
  });

  test('破招成功:清蓄力 + 踉跄 + 招牌技上 CD + 事件可观测', () {
    final result = reducePhase0aTick(
      state: _state(
        _charger(chargeTicksRemaining: 2, chargingCast: _cast()),
        slots: _clearSlot(),
      ),
      intents: [_clearIntent(breakPower: 1)],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 10),
    );

    final interrupted = result.events.whereType<Phase0aBossChargeInterrupted>();
    expect(interrupted, hasLength(1));
    expect(interrupted.single.actor, 'player');
    expect(interrupted.single.target, 'boss');
    expect(interrupted.single.skillId, 'charge_signature');
    expect(interrupted.single.staggerTicks, 2);

    final boss = result.state.enemies.single;
    expect(boss.chargeTicksRemaining, 0);
    expect(boss.chargingCast, isNull);
    expect(boss.staggerTicksRemaining, 2);
    expect(boss.enemySkillCooldowns['charge_signature'], 4);
    expect(boss.currentHealth, 90, reason: '破招命中仍结算清场伤害');
  });

  test('同拍竞态:倒计时本拍归零已登记释放,玩家同拍破招命中 → 招牌技不释放', () {
    // chargeTicksRemaining==1:pre-step 归零并把该敌登记进拍尾释放队列,
    // 但 chargingCast 仍保留;玩家同拍 typed break 命中先清蓄力,拍尾释放
    // 循环读得 chargingCast==null 即跳过——「完成仅一次」与「破招优先」并存。
    final result = reducePhase0aTick(
      state: _state(
        _charger(chargeTicksRemaining: 1, chargingCast: _cast()),
        slots: _clearSlot(),
      ),
      intents: [_clearIntent(breakPower: 1)],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 10),
      enemySkillDamageResolver: _Resolver(basicDamage: 17),
    );

    // 招牌技未释放:无 EnemySkillStarted、无蓄力伤害 HitLanded。
    expect(result.events.whereType<Phase0aEnemySkillStarted>(), isEmpty);
    expect(result.events.whereType<Phase0aHitLanded>(), isEmpty);

    // 蓄力被清除、进入踉跄、招牌技上 CD。
    final boss = result.state.enemies.single;
    expect(boss.chargingCast, isNull);
    expect(boss.chargeTicksRemaining, 0);
    expect(boss.staggerTicksRemaining, 2);
    expect(boss.enemySkillCooldowns['charge_signature'], 4);

    // 中断事件存在且指向被打断的招牌技。
    final interrupted = result.events.whereType<Phase0aBossChargeInterrupted>();
    expect(interrupted, hasLength(1));
    expect(interrupted.single.target, 'boss');
    expect(interrupted.single.skillId, 'charge_signature');
    expect(interrupted.single.staggerTicks, 2);
  });

  test('破招对非蓄力敌人 no-op;breakPower=0 与未命中不破招', () {
    // (a) 非蓄力:只结算伤害。
    final plain = reducePhase0aTick(
      state: _state(_charger(), slots: _clearSlot()),
      intents: [_clearIntent(breakPower: 1)],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 10),
    );
    expect(plain.events.whereType<Phase0aBossChargeInterrupted>(), isEmpty);
    expect(plain.state.enemies.single.staggerTicksRemaining, 0);
    expect(plain.state.enemies.single.currentHealth, 90);

    // (b) 蓄力中但 breakPower=0:蓄力不受影响。
    final noPower = reducePhase0aTick(
      state: _state(
        _charger(chargeTicksRemaining: 2, chargingCast: _cast()),
        slots: _clearSlot(),
      ),
      intents: [_clearIntent()],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 10),
    );
    expect(noPower.events.whereType<Phase0aBossChargeInterrupted>(), isEmpty);
    final stillCharging = noPower.state.enemies.single;
    expect(stillCharging.chargingCast, isNotNull);
    // 本拍 intent 阶段蓄力未被打断;拍前扣减已在 clear 之前完成 → 剩 1。
    expect(stillCharging.chargeTicksRemaining, 1);

    // (c) 闪避(isHit=false):不破招。
    final dodged = reducePhase0aTick(
      state: _state(
        _charger(chargeTicksRemaining: 2, chargingCast: _cast()),
        slots: _clearSlot(),
      ),
      intents: [_clearIntent(breakPower: 1)],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 10, hit: false),
    );
    expect(dodged.events.whereType<Phase0aBossChargeInterrupted>(), isEmpty);
    expect(dodged.state.enemies.single.chargingCast, isNotNull);
  });

  test('踉跄窗口:压制恰为窗口拍数,期间减防语义可见,窗口后恢复行动', () {
    final broken = reducePhase0aTick(
      state: _state(
        _charger(chargeTicksRemaining: 2, chargingCast: _cast()),
        slots: _clearSlot(),
      ),
      intents: [_clearIntent(breakPower: 1)],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 0),
    );
    expect(broken.state.enemies.single.staggerTicksRemaining, 2);

    // 第 1 拍:压制(移动被拒),玩家普攻结算带踉跄减防标记。
    final resolverA = _Resolver(basicDamage: 3);
    final tickA = reducePhase0aTick(
      state: broken.state,
      intents: const [
        Phase0aMoveIntent(actorId: 'boss', direction: ArenaVector(-1, 0)),
        Phase0aAttackIntent(
          actorId: 'player',
          range: 10,
          halfArcRadians: 1,
          cooldownSeconds: 0.1,
          moveKind: Phase0aMoveKind.light,
          aimDirection: ArenaVector(1, 0),
          qiDelta: 0,
        ),
      ],
      deltaSeconds: 0.1,
      damageResolver: resolverA,
    );
    expect(tickA.state.enemies.single.position, const ArenaVector(1, 0));
    expect(resolverA.staggeredTargets, contains('boss'));
    expect(tickA.state.enemies.single.staggerTicksRemaining, 1);

    // 第 2 拍:仍压制。
    final resolverB = _Resolver(basicDamage: 3);
    final tickB = reducePhase0aTick(
      state: tickA.state,
      intents: const [
        Phase0aAttackIntent(
          actorId: 'player',
          range: 10,
          halfArcRadians: 1,
          cooldownSeconds: 0.1,
          moveKind: Phase0aMoveKind.light,
          aimDirection: ArenaVector(1, 0),
          qiDelta: 0,
        ),
      ],
      deltaSeconds: 0.1,
      damageResolver: resolverB,
    );
    expect(resolverB.staggeredTargets, contains('boss'));
    expect(tickB.state.enemies.single.staggerTicksRemaining, 0);

    // 第 3 拍:窗口结束,敌方移动 intent 生效,减防标记消失。
    final resolverC = _Resolver(basicDamage: 3);
    final tickC = reducePhase0aTick(
      state: tickB.state,
      intents: const [
        Phase0aMoveIntent(actorId: 'boss', direction: ArenaVector(-1, 0)),
        Phase0aAttackIntent(
          actorId: 'player',
          range: 10,
          halfArcRadians: 1,
          cooldownSeconds: 0.1,
          moveKind: Phase0aMoveKind.light,
          aimDirection: ArenaVector(1, 0),
          qiDelta: 0,
        ),
      ],
      deltaSeconds: 0.1,
      damageResolver: resolverC,
    );
    expect(
      tickC.state.enemies.single.position.x,
      lessThan(1),
      reason: '窗口结束后恢复行动',
    );
    expect(resolverC.staggeredTargets, isEmpty);
  });

  test('招牌技冷却未归零时不得二次起手蓄力', () {
    final result = reducePhase0aTick(
      state: _state(
        _charger(enemySkillCooldowns: const {'charge_signature': 2}),
      ),
      intents: [_chargeSkillIntent()],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 5),
      enemySkillDamageResolver: _Resolver(basicDamage: 5),
    );
    expect(result.events.whereType<Phase0aBossChargeStarted>(), isEmpty);
    expect(result.state.enemies.single.chargeTicksRemaining, 0);
    expect(result.state.enemies.single.chargingCast, isNull);
  });

  test('阶段 chargeCounter:进阶即蓄力,倒计时后释放阶段招牌', () {
    const phases = [
      BossPhaseDef(hpThresholdPct: 1),
      BossPhaseDef(
        hpThresholdPct: 0.5,
        unlockSkillIds: ['phase_signature'],
        onEnterMechanic: BossPhaseMechanic.chargeCounter,
      ),
    ];
    final boss = _charger(
      bossPhases: phases,
      phaseChargeCasts: [
        null,
        _cast(skill: _phaseSignatureSkill),
      ],
    );
    final entered = reducePhase0aTick(
      state: _state(boss),
      intents: const [
        Phase0aAttackIntent(
          actorId: 'player',
          range: 10,
          halfArcRadians: 1,
          cooldownSeconds: 1,
          moveKind: Phase0aMoveKind.light,
          aimDirection: ArenaVector(1, 0),
          qiDelta: 0,
        ),
      ],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 60),
      enemySkillDamageResolver: _Resolver(basicDamage: 17),
    );

    expect(entered.state.enemies.single.bossPhaseIndex, 1);
    final started = entered.events.whereType<Phase0aBossChargeStarted>();
    expect(started, hasLength(1));
    expect(started.single.skillId, 'phase_signature');
    expect(
      entered.state.enemies.single.chargingCast!.skill.id,
      'phase_signature',
    );

    var state = entered.state;
    Phase0aStepResult? firedStep;
    for (var i = 0; i < 3; i++) {
      firedStep = reducePhase0aTick(
        state: state,
        intents: const [],
        deltaSeconds: 0.1,
        damageResolver: _Resolver(basicDamage: 0),
        enemySkillDamageResolver: _Resolver(basicDamage: 17),
      );
      state = firedStep.state;
    }
    final fired = firedStep!.events.whereType<Phase0aEnemySkillStarted>();
    expect(fired, hasLength(1));
    expect(fired.single.skillId, 'phase_signature');
    expect(state.enemies.single.enemySkillCooldowns['phase_signature'], 4);
  });

  test('chargeCounter 阶段解锁招为空 → 不蓄力(no-op)', () {
    const phases = [
      BossPhaseDef(hpThresholdPct: 1),
      BossPhaseDef(
        hpThresholdPct: 0.5,
        onEnterMechanic: BossPhaseMechanic.chargeCounter,
      ),
    ];
    final boss = _charger(
      bossPhases: phases,
      phaseChargeCasts: const [null, null],
    );
    final entered = reducePhase0aTick(
      state: _state(boss),
      intents: const [
        Phase0aAttackIntent(
          actorId: 'player',
          range: 10,
          halfArcRadians: 1,
          cooldownSeconds: 1,
          moveKind: Phase0aMoveKind.light,
          aimDirection: ArenaVector(1, 0),
          qiDelta: 0,
        ),
      ],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 60),
    );
    expect(entered.state.enemies.single.bossPhaseIndex, 1);
    expect(entered.events.whereType<Phase0aBossChargeStarted>(), isEmpty);
    expect(entered.state.enemies.single.chargingCast, isNull);
  });

  test('数字技能 intent 携带 breakPower 同样消费破招迁移', () {
    final result = reducePhase0aTick(
      state: _state(
        _charger(chargeTicksRemaining: 2, chargingCast: _cast()),
        slots: const [
          Phase0aSkillSlot(
            slot: 'phase0a_skill_1',
            cooldownRemaining: 0,
            qiCost: 30,
            availability: Phase0aSkillAvailability.ready,
          ),
        ],
      ),
      intents: const [
        Phase0aSkillIntent(
          actorId: 'player',
          kind: Phase0aDamageKind.skill1,
          slot: 'phase0a_skill_1',
          skillId: 'skill_po_shi',
          targetType: TargetType.single,
          aimDirection: ArenaVector(1, 0),
          range: 10,
          halfArcRadians: 1,
          effectRadius: 0,
          qiDelta: -30,
          cooldownSeconds: 3,
          breakPower: 2,
        ),
      ],
      deltaSeconds: 0.1,
      damageResolver: _Resolver(basicDamage: 8),
    );
    final interrupted = result.events.whereType<Phase0aBossChargeInterrupted>();
    expect(interrupted, hasLength(1));
    expect(interrupted.single.skillId, 'charge_signature');
    expect(result.state.enemies.single.staggerTicksRemaining, 2);
    expect(
      result.state.enemies.single.enemySkillCooldowns['charge_signature'],
      4,
    );
  });

  test('同 seed 同指令序列:事件流与末态逐值可重放', () {
    Phase0aStepResult runSequence() {
      var state = _state(
        _charger(chargeTicksRemaining: 3, chargingCast: _cast()),
        slots: _clearSlot(),
      );
      final allEvents = <Phase0aEvent>[];
      // 拍 1:玩家破招命中 → 踉跄。
      var step = reducePhase0aTick(
        state: state,
        intents: [_clearIntent(breakPower: 1)],
        deltaSeconds: 0.1,
        damageResolver: _Resolver(basicDamage: 9),
        enemySkillDamageResolver: _Resolver(basicDamage: 17),
      );
      allEvents.addAll(step.events);
      state = step.state;
      // 踉跄窗口 + 等招牌技 CD(4s = 40 拍)转好,再重新起手蓄力。
      final intentSequence = <List<Phase0aIntent>>[
        for (var i = 0; i < 45; i++) <Phase0aIntent>[],
        [_chargeSkillIntent()],
      ];
      for (final intents in intentSequence) {
        step = reducePhase0aTick(
          state: state,
          intents: intents,
          deltaSeconds: 0.1,
          damageResolver: _Resolver(basicDamage: 9),
          enemySkillDamageResolver: _Resolver(basicDamage: 17),
        );
        allEvents.addAll(step.events);
        state = step.state;
      }
      return Phase0aStepResult(state: state, events: allEvents);
    }

    final a = runSequence();
    final b = runSequence();
    expect(b.events, a.events);
    expect(b.state, a.state);
    // 序列本身语义自检:破招发生且其后重新蓄力。
    expect(a.events.whereType<Phase0aBossChargeInterrupted>(), hasLength(1));
    expect(a.events.whereType<Phase0aBossChargeStarted>(), hasLength(1));
    expect(a.state.enemies.single.chargeTicksRemaining, 3);
  });

  test('AI:蓄力/踉跄敌人零 intent;chargeCast 放开 unlock 门但守 CD 门', () {
    final ai = Phase0aEnemyAiAdapter(
      attackRange: 10,
      attackHalfArcRadians: 1,
      attackCooldownSeconds: 1,
      skillBindingsByActor: {
        'boss': [
          Phase0aEnemySkillBinding(
            skill: _signatureSkill,
            attackRange: 10,
            halfArcRadians: 1,
            effectRadius: 10,
            cooldownSeconds: 4,
          ),
        ],
      },
    );

    // 蓄力中/踉跄中:零 intent。
    for (final suppressed in [
      _charger(chargeTicksRemaining: 2, chargingCast: _cast()),
      _charger(staggerTicksRemaining: 1),
    ]) {
      expect(ai.intentsFor(state: _state(suppressed)), isEmpty);
    }

    // 未蓄力、无解锁招但有 chargeCast:选招牌技(旁路 unlock 门)。
    final pick = ai.intentsFor(state: _state(_charger()));
    expect(pick, hasLength(1));
    expect(pick.single, isA<Phase0aEnemySkillIntent>());
    expect(
      (pick.single as Phase0aEnemySkillIntent).skill.id,
      'charge_signature',
    );

    // 招牌技 CD 未归零:回落普攻。
    final cooling = ai.intentsFor(
      state: _state(
        _charger(enemySkillCooldowns: const {'charge_signature': 2}),
      ),
    );
    expect(cooling, hasLength(1));
    expect(cooling.single, isA<Phase0aAttackIntent>());
  });
}
