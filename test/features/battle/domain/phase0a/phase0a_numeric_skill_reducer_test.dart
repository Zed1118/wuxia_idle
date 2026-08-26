import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

final class _Resolver implements Phase0aDamageResolver {
  final calls = <({String attacker, String target, Phase0aDamageKind kind})>[];

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1.0,
  }) {
    calls.add((attacker: attackerId, target: targetId, kind: kind));
    return const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 10);
  }
}

Phase0aArenaState _state({int qi = 50, double cooldown = 0}) =>
    Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: Phase0aActor(
        id: 'player',
        side: Phase0aSide.player,
        position: ArenaVector.zero,
        facing: const ArenaVector(1, 0),
        maxHealth: 100,
        currentHealth: 100,
        moveSpeed: 0,
        qiCurrent: qi,
        qiMax: 100,
        attackCooldownRemaining: 0,
        defeatKind: Phase0aDefeatKind.normal,
      ),
      enemies: [
        _enemy('e1', const ArenaVector(10, 0)),
        _enemy('e2', const ArenaVector(20, 0)),
        _enemy('e3', const ArenaVector(80, 0)),
      ],
      skillSlots: [
        for (var index = 1; index <= 6; index++)
          Phase0aSkillSlot(
            slot: '$index',
            cooldownRemaining: index == 1 ? cooldown : 0,
            qiCost: 20,
            availability: Phase0aSkillAvailability.ready,
          ),
      ],
    );

Phase0aActor _enemy(String id, ArenaVector position) => Phase0aActor(
  id: id,
  side: Phase0aSide.enemy,
  position: position,
  facing: const ArenaVector(-1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 0,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aSkillIntent _skill({
  required String skillId,
  required int hotkey,
  required Phase0aDamageKind kind,
  required TargetType targetType,
  required int qiDelta,
  required double cooldownSeconds,
  required double range,
  ArenaVector aimDirection = const ArenaVector(1, 0),
  double effectRadius = 0,
}) => Phase0aSkillIntent(
  actorId: 'player',
  kind: kind,
  skillId: skillId,
  slot: '$hotkey',
  targetType: targetType,
  qiDelta: qiDelta,
  cooldownSeconds: cooldownSeconds,
  postureDamage: 0,
  postureHitKind: PostureHitKind.heavy,
  range: range,
  halfArcRadians: 0.7853981633974483,
  effectRadius: effectRadius,
  aimDirection: aimDirection,
);

void main() {
  test('single skill uses aim/range and resolves exactly one target', () {
    final resolver = _Resolver();
    final result = reducePhase0aTick(
      state: _state(),
      intents: [
        _skill(
          skillId: 'skill_one',
          hotkey: 1,
          kind: Phase0aDamageKind.skill1,
          targetType: TargetType.single,
          qiDelta: -20,
          cooldownSeconds: 2,
          range: 30,
        ),
      ],
      deltaSeconds: 0,
      damageResolver: resolver,
    );

    expect(resolver.calls, hasLength(1));
    expect(resolver.calls.single.target, 'e1');
    expect(resolver.calls.single.kind, Phase0aDamageKind.skill1);
    expect(
      result.events.whereType<Phase0aSkillStarted>().single.skillId,
      'skill_one',
    );
    expect(
      result.events.whereType<Phase0aSkillApplied>().single.skillId,
      'skill_one',
    );
  });

  test('aoe resolves stable in-radius order and consumes negative qi', () {
    final resolver = _Resolver();
    final result = reducePhase0aTick(
      state: _state(qi: 50),
      intents: [
        _skill(
          skillId: 'skill_two',
          hotkey: 2,
          kind: Phase0aDamageKind.skill2,
          targetType: TargetType.aoe,
          qiDelta: -20,
          cooldownSeconds: 2,
          range: 0,
          effectRadius: 25,
        ),
      ],
      deltaSeconds: 0,
      damageResolver: resolver,
    );

    expect(resolver.calls.map((call) => call.target), ['e1', 'e2']);
    expect(
      resolver.calls.every((call) => call.kind == Phase0aDamageKind.skill2),
      isTrue,
    );
    expect(result.state.player.qiCurrent, 30);
  });

  test('positive qiDelta returns qi but clamps to qiMax', () {
    final resolver = _Resolver();
    final result = reducePhase0aTick(
      state: _state(qi: 95),
      intents: [
        _skill(
          skillId: 'skill_three',
          hotkey: 3,
          kind: Phase0aDamageKind.skill3,
          targetType: TargetType.single,
          qiDelta: 20,
          cooldownSeconds: 1,
          range: 30,
        ),
      ],
      deltaSeconds: 0,
      damageResolver: resolver,
    );

    expect(result.state.player.qiCurrent, 100);
    expect(resolver.calls.single.kind, Phase0aDamageKind.skill3);
  });

  test('cooldown blocks repeat and invalid or empty intents fail closed', () {
    final resolver = _Resolver();
    final state = _state(cooldown: 1);
    final result = reducePhase0aTick(
      state: state,
      intents: [
        _skill(
          skillId: 'skill_four',
          hotkey: 4,
          kind: Phase0aDamageKind.skill4,
          targetType: TargetType.single,
          qiDelta: -20,
          cooldownSeconds: 2,
          range: 30,
        ),
        _skill(
          skillId: '',
          hotkey: 9,
          kind: Phase0aDamageKind.skill5,
          targetType: TargetType.single,
          qiDelta: -1,
          cooldownSeconds: -1,
          range: double.nan,
        ),
      ],
      deltaSeconds: 0,
      damageResolver: resolver,
    );

    expect(resolver.calls, hasLength(1));
    expect(resolver.calls.single.kind, Phase0aDamageKind.skill4);
    expect(result.events.whereType<Phase0aSkillStarted>(), hasLength(1));
  });
}
