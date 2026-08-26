import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';

const _chargeSkill = SkillDef(
  id: 'tower42_charge',
  name: 'tower42_charge',
  description: 'tower42_charge',
  type: SkillType.powerSkill,
  powerMultiplier: 2000,
  qiDelta: -10,
  cooldownTurns: 3,
  requiresManualTrigger: false,
  visualEffect: '',
);

final class _FixedResolver implements Phase0aDamageResolver {
  const _FixedResolver(this.damage);

  final int damage;

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1.0,
  }) => Phase0aResolvedHit(isHit: true, isCritical: false, damage: damage);
}

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required ArenaVector position,
  int hp = 100,
  int staggerTicksTotal = 2,
  Phase0aChargeCast? chargingCast,
  int chargeTicksRemaining = 0,
  List<String> guardianDefIds = const [],
  double? guardianWardMult,
  bool guardInterceptsInterrupt = false,
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: side == Phase0aSide.player
      ? const ArenaVector(1, 0)
      : const ArenaVector(-1, 0),
  maxHealth: hp,
  currentHealth: hp,
  moveSpeed: 0,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: side == Phase0aSide.enemy
      ? Phase0aDefeatKind.elite
      : Phase0aDefeatKind.normal,
  isBoss: id == 'boss',
  chargeCast: chargingCast,
  chargingCast: chargingCast,
  chargeTicksRemaining: chargeTicksRemaining,
  staggerTicksTotal: staggerTicksTotal,
  guardianDefIds: guardianDefIds,
  guardianWardMult: guardianWardMult,
  guardInterceptsInterrupt: guardInterceptsInterrupt,
  posture: side == Phase0aSide.enemy
      ? PostureState.initial(
          PostureConfig(
            capacity: 3,
            vulnerabilityTicks: 2,
            recoveryPolicy: PostureRecoveryPolicy.reset,
            postVulnerabilityAccumulated: 0,
            bossControlConversionFactor: 3,
          ),
        )
      : null,
);

Phase0aArenaState _state({
  required Phase0aActor boss,
  required List<Phase0aActor> guardians,
  List<Phase0aSkillSlot> skillSlots = const [
    Phase0aSkillSlot(
      slot: 'one',
      cooldownRemaining: 0,
      qiCost: 10,
      availability: Phase0aSkillAvailability.ready,
    ),
  ],
}) => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: _actor(
    id: 'player',
    side: Phase0aSide.player,
    position: ArenaVector.zero,
  ),
  enemies: [boss, ...guardians],
  skillSlots: skillSlots,
);

Phase0aSkillIntent _singleSkill({required int breakPower}) =>
    Phase0aSkillIntent(
      actorId: 'player',
      kind: Phase0aDamageKind.skill1,
      slot: 'one',
      skillId: 'tower42_break',
      targetType: TargetType.single,
      aimDirection: const ArenaVector(1, 0),
      range: 10,
      halfArcRadians: math.pi / 2,
      effectRadius: 10,
      qiDelta: -10,
      cooldownSeconds: 1,
      postureDamage: 1,
      postureHitKind: breakPower > 0
          ? PostureHitKind.bossControl
          : PostureHitKind.heavy,
      breakPower: breakPower,
    );

Phase0aSkillIntent _aoeSkill({required int breakPower}) => Phase0aSkillIntent(
  actorId: 'player',
  kind: Phase0aDamageKind.skill1,
  slot: 'one',
  skillId: 'tower42_aoe',
  targetType: TargetType.aoe,
  aimDirection: const ArenaVector(1, 0),
  range: 10,
  halfArcRadians: math.pi / 2,
  effectRadius: 10,
  qiDelta: -10,
  cooldownSeconds: 1,
  postureDamage: 1,
  postureHitKind: breakPower > 0
      ? PostureHitKind.bossControl
      : PostureHitKind.heavy,
  breakPower: breakPower,
);

Phase0aClearIntent _rangeSkill({required int breakPower}) => Phase0aClearIntent(
  actorId: 'player',
  slot: 'clear',
  effectRadius: 10,
  qiCost: 10,
  cooldownSeconds: 1,
  postureDamage: 1,
  postureHitKind: breakPower > 0
      ? PostureHitKind.bossControl
      : PostureHitKind.heavy,
  skillId: 'tower42_range',
  breakPower: breakPower,
);

void main() {
  test('普通单体目标池不越过存活护法，破招才允许锁定 Boss', () {
    final boss = _actor(
      id: 'boss',
      side: Phase0aSide.enemy,
      position: const ArenaVector(1, 0),
      chargingCast: Phase0aChargeCast(
        skill: _chargeSkill,
        chargeTicks: 3,
        attackRange: 10,
        halfArcRadians: 1,
        effectRadius: 10,
        cooldownSeconds: 3,
        actionCooldownSeconds: 1,
        postureDamage: 0,
        postureHitKind: PostureHitKind.heavy,
      ),
      chargeTicksRemaining: 2,
      guardianDefIds: const ['guard'],
      guardianWardMult: 0.15,
      guardInterceptsInterrupt: true,
    );
    final guard = _actor(
      id: 'guard_w0s1',
      side: Phase0aSide.enemy,
      position: const ArenaVector(2, 0),
      hp: 80,
    );
    final ordinary = reducePhase0aTick(
      state: _state(boss: boss, guardians: [guard]),
      intents: [_singleSkill(breakPower: 0)],
      deltaSeconds: 0,
      damageResolver: const _FixedResolver(10),
    );
    expect(
      ordinary.events
          .whereType<Phase0aSkillApplied>()
          .single
          .outcomes
          .single
          .target,
      'guard_w0s1',
    );
    final ordinaryRange = reducePhase0aTick(
      state: _state(
        boss: boss,
        guardians: [guard],
        skillSlots: const [
          Phase0aSkillSlot(
            slot: 'clear',
            cooldownRemaining: 0,
            qiCost: 10,
            availability: Phase0aSkillAvailability.ready,
          ),
        ],
      ),
      intents: [_rangeSkill(breakPower: 0)],
      deltaSeconds: 0,
      damageResolver: const _FixedResolver(10),
    );
    expect(
      ordinaryRange.events.whereType<Phase0aClearApplied>().single.outcomes.map(
        (outcome) => outcome.target,
      ),
      ['guard_w0s1'],
    );
    final ordinaryNumericAoe = reducePhase0aTick(
      state: _state(boss: boss, guardians: [guard]),
      intents: [_aoeSkill(breakPower: 0)],
      deltaSeconds: 0,
      damageResolver: const _FixedResolver(10),
    );
    expect(
      ordinaryNumericAoe.events
          .whereType<Phase0aSkillApplied>()
          .single
          .outcomes
          .map((outcome) => outcome.target),
      ['guard_w0s1'],
    );

    final intercepted = reducePhase0aTick(
      state: _state(boss: boss, guardians: [guard]),
      intents: [_singleSkill(breakPower: 1)],
      deltaSeconds: 0,
      damageResolver: const _FixedResolver(10),
    );
    final afterBoss = intercepted.state.enemies.firstWhere(
      (e) => e.id == 'boss',
    );
    final afterGuard = intercepted.state.enemies.firstWhere(
      (e) => e.id == 'guard_w0s1',
    );
    expect(afterBoss.currentHealth, 100);
    expect(afterBoss.chargingCast, isNotNull);
    expect(afterBoss.chargeTicksRemaining, 1, reason: '蓄力继续按既有拍前倒计时推进');
    expect(afterGuard.currentHealth, 70);
    expect(afterGuard.staggerTicksRemaining, 0);
    expect(afterGuard.posture!.accumulated, 1);
    expect(afterBoss.posture!.isVulnerable, isFalse);
    final guardEvents = intercepted.events
        .whereType<Phase0aGuardIntercepted>()
        .toList();
    expect(guardEvents, hasLength(1));
    expect(guardEvents.single.boss, 'boss');
    expect(guardEvents.single.guardian, 'guard_w0s1');
    expect(guardEvents.single.resolvedDamage, 10);

    final interceptedAoe = reducePhase0aTick(
      state: _state(
        boss: boss,
        guardians: [guard],
        skillSlots: const [
          Phase0aSkillSlot(
            slot: 'clear',
            cooldownRemaining: 0,
            qiCost: 10,
            availability: Phase0aSkillAvailability.ready,
          ),
        ],
      ),
      intents: [_rangeSkill(breakPower: 1)],
      deltaSeconds: 0,
      damageResolver: const _FixedResolver(10),
    );
    final aoeOutcomes = interceptedAoe.events
        .whereType<Phase0aClearApplied>()
        .single
        .outcomes;
    expect(aoeOutcomes.map((outcome) => outcome.target), ['guard_w0s1']);
    expect(
      interceptedAoe.state.enemies
          .firstWhere((e) => e.id == 'boss')
          .chargingCast,
      isNotNull,
    );
  });

  test('护法全灭后回落既有真打断，未配置路径保持直接命中', () {
    final boss = _actor(
      id: 'boss',
      side: Phase0aSide.enemy,
      position: const ArenaVector(1, 0),
      chargingCast: Phase0aChargeCast(
        skill: _chargeSkill,
        chargeTicks: 3,
        attackRange: 10,
        halfArcRadians: 1,
        effectRadius: 10,
        cooldownSeconds: 3,
        actionCooldownSeconds: 1,
        postureDamage: 0,
        postureHitKind: PostureHitKind.heavy,
      ),
      chargeTicksRemaining: 2,
      guardianDefIds: const ['guard'],
      guardianWardMult: 0.15,
      guardInterceptsInterrupt: true,
    );
    final result = reducePhase0aTick(
      state: _state(boss: boss, guardians: []),
      intents: [_singleSkill(breakPower: 1)],
      deltaSeconds: 0,
      damageResolver: const _FixedResolver(10),
    );
    final after = result.state.enemies.single;
    expect(after.currentHealth, 90);
    expect(after.chargingCast, isNull);
    expect(after.staggerTicksRemaining, 2);
    expect(
      result.events.whereType<Phase0aPostureChanged>().where(
        (event) => event.eventType == PostureEventType.vulnerabilityEntered,
      ),
      hasLength(1),
    );
  });
}
