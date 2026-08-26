import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/defense_resolution.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

const _flags = AttackDefenseFlags(
  blockable: true,
  parryable: true,
  reflectable: false,
  dodgeable: true,
  interruptible: true,
);

class _FixedDamage implements Phase0aDamageResolver {
  const _FixedDamage();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 100);
}

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required ArenaVector position,
  required ArenaVector facing,
  int health = 200,
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: facing,
  maxHealth: health,
  currentHealth: health,
  moveSpeed: 100,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aArenaState _state() => Phase0aArenaState(
  tick: 0,
  nextSeq: 1,
  player: _actor(
    id: 'player',
    side: Phase0aSide.player,
    position: ArenaVector.zero,
    facing: const ArenaVector(1, 0),
  ),
  enemies: [
    _actor(
      id: 'enemy',
      side: Phase0aSide.enemy,
      position: const ArenaVector(40, 0),
      facing: const ArenaVector(-1, 0),
    ),
  ],
  skillSlots: const [],
);

Phase0aDefenseIntent _defense(Phase0aDefenseAction action) =>
    Phase0aDefenseIntent(
      actorId: 'player',
      action: action,
      direction: const ArenaVector(1, 0),
      shieldAbsorption: 30,
      shieldDurationTicks: 4,
      parryWindowTicks: 2,
      counterDamage: 25,
      counterUpperBound: 30,
      dodgeIframeTicks: 2,
      dodgeDistance: 110,
      cooldownSeconds: 1.2,
    );

const _enemyAttack = Phase0aAttackIntent(
  actorId: 'enemy',
  range: 100,
  halfArcRadians: math.pi,
  cooldownSeconds: 1,
  moveKind: Phase0aMoveKind.light,
  aimDirection: ArenaVector(-1, 0),
  qiDelta: 0,
  postureDamage: 0,
  postureHitKind: PostureHitKind.light,
  defenseFlags: _flags,
);

Phase0aStepResult _step(Phase0aDefenseAction action) => reducePhase0aTick(
  state: _state(),
  intents: [_defense(action), _enemyAttack],
  deltaSeconds: 0.1,
  damageResolver: const _FixedDamage(),
);

void main() {
  test('shield absorbs inbound damage and leaves observable branch state', () {
    final result = _step(Phase0aDefenseAction.shield);

    expect(result.state.player.currentHealth, 130);
    expect(result.state.player.shieldRemaining, 0);
    expect(result.events.whereType<Phase0aDefenseStarted>(), hasLength(1));
    final defense = result.events.whereType<Phase0aDefenseResolved>().single;
    expect(defense.branch, DefenseBranch.blockOrShield);
    expect(defense.incomingDamage, 70);
    expect(defense.counterDamage, 0);
  });

  test('parry prevents damage and applies bounded non-recursive counter', () {
    final result = _step(Phase0aDefenseAction.parry);

    expect(result.state.player.currentHealth, 200);
    expect(result.state.enemies.single.currentHealth, 175);
    final defense = result.events.whereType<Phase0aDefenseResolved>().single;
    expect(defense.branch, DefenseBranch.parry);
    expect(defense.counterDamage, 25);
    expect(defense.nonRecursive, isTrue);
  });

  test('dodge moves the player and grants an invulnerable inbound branch', () {
    final result = _step(Phase0aDefenseAction.dodge);

    expect(result.state.player.position, const ArenaVector(110, 0));
    expect(result.state.player.currentHealth, 200);
    expect(
      result.events.whereType<Phase0aDefenseResolved>().single.branch,
      DefenseBranch.dodge,
    );
    expect(
      result.events.whereType<Phase0aHitLanded>().single.resolvedDamage,
      0,
    );
  });

  test(
    'invalid defense payload fails closed and cooldown rejects repeat action',
    () {
      final invalid = reducePhase0aTick(
        state: _state(),
        intents: [
          const Phase0aDefenseIntent(
            actorId: 'player',
            action: Phase0aDefenseAction.shield,
            direction: ArenaVector(1, 0),
            shieldAbsorption: -1,
            shieldDurationTicks: 4,
            parryWindowTicks: 2,
            counterDamage: 25,
            counterUpperBound: 30,
            dodgeIframeTicks: 2,
            dodgeDistance: 110,
            cooldownSeconds: 1.2,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _FixedDamage(),
      );
      expect(invalid.events.whereType<Phase0aDefenseStarted>(), isEmpty);
      expect(invalid.state.player.shieldRemaining, 0);

      final first = reducePhase0aTick(
        state: _state(),
        intents: [_defense(Phase0aDefenseAction.shield)],
        deltaSeconds: 0.1,
        damageResolver: const _FixedDamage(),
      );
      final second = reducePhase0aTick(
        state: first.state,
        intents: [_defense(Phase0aDefenseAction.parry)],
        deltaSeconds: 0.1,
        damageResolver: const _FixedDamage(),
      );
      expect(second.events.whereType<Phase0aDefenseStarted>(), isEmpty);
      expect(second.state.player.shieldRemaining, greaterThan(0));
    },
  );

  test(
    'defense plus player attack is rejected as one invalid action bundle',
    () {
      final result = reducePhase0aTick(
        state: _state(),
        intents: [
          _defense(Phase0aDefenseAction.dodge),
          const Phase0aAttackIntent(
            actorId: 'player',
            range: 100,
            halfArcRadians: math.pi,
            cooldownSeconds: 1,
            moveKind: Phase0aMoveKind.light,
            aimDirection: ArenaVector(1, 0),
            qiDelta: 0,
            postureDamage: 0,
            postureHitKind: PostureHitKind.light,
          ),
        ],
        deltaSeconds: 0.1,
        damageResolver: const _FixedDamage(),
      );

      expect(result.events.whereType<Phase0aAttackStarted>(), isEmpty);
      expect(result.state.enemies.single.currentHealth, 200);
      expect(result.events.whereType<Phase0aDefenseStarted>(), hasLength(1));
    },
  );
}
