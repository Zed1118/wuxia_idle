import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

final class _FixedDamageResolver implements Phase0aDamageResolver {
  const _FixedDamageResolver();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 99);
}

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required ArenaVector position,
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: side == Phase0aSide.player
      ? const ArenaVector(1, 0)
      : const ArenaVector(-1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 60,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

Phase0aAttackIntent _attack(String actorId, String preferredTargetId) =>
    Phase0aAttackIntent(
      actorId: actorId,
      range: 82,
      halfArcRadians: 1.2,
      cooldownSeconds: 1,
      moveKind: Phase0aMoveKind.light,
      aimDirection: const ArenaVector(-1, 0),
      qiDelta: 0,
      postureDamage: 0,
      postureHitKind: PostureHitKind.light,
      preferredTargetId: preferredTargetId,
    );

void main() {
  test(
    'designated attacker damages the positioned entity on the same reducer',
    () {
      const ward = Phase0aDefendedEntityState(
        id: 'ward',
        position: ArenaVector(20, 0),
        maxDurability: 30,
        currentDurability: 30,
        damagePerHit: 7,
      );
      final state = Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: _actor(
          id: 'player',
          side: Phase0aSide.player,
          position: const ArenaVector(-200, 0),
        ),
        enemies: [
          _actor(
            id: 'attacker',
            side: Phase0aSide.enemy,
            position: const ArenaVector(70, 0),
          ),
        ],
        skillSlots: const [],
        defendedEntity: ward,
      );

      final result = reducePhase0aTick(
        state: state,
        intents: [_attack('attacker', 'ward')],
        deltaSeconds: 0.1,
        damageResolver: const _FixedDamageResolver(),
      );

      expect(result.state.defendedEntity?.currentDurability, 23);
      expect(result.state.player.currentHealth, 100);
      final hit = result.events.whereType<Phase0aDefendedEntityHit>().single;
      expect(hit.actor, 'attacker');
      expect(hit.target, 'ward');
      expect(hit.resolvedDamage, 7);
      expect(hit.remainingDurability, 23);
      expect(result.state.enemies.single.attackCooldownRemaining, 1);
    },
  );

  test(
    'same-frame attackers cannot retarget player after entity is destroyed',
    () {
      const ward = Phase0aDefendedEntityState(
        id: 'ward',
        position: ArenaVector(20, 0),
        maxDurability: 5,
        currentDurability: 5,
        damagePerHit: 5,
      );
      final state = Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: _actor(
          id: 'player',
          side: Phase0aSide.player,
          position: const ArenaVector(0, 0),
        ),
        enemies: [
          _actor(
            id: 'attacker_a',
            side: Phase0aSide.enemy,
            position: const ArenaVector(70, 0),
          ),
          _actor(
            id: 'attacker_b',
            side: Phase0aSide.enemy,
            position: const ArenaVector(70, 4),
          ),
        ],
        skillSlots: const [],
        defendedEntity: ward,
      );

      final result = reducePhase0aTick(
        state: state,
        intents: [_attack('attacker_a', 'ward'), _attack('attacker_b', 'ward')],
        deltaSeconds: 0.1,
        damageResolver: const _FixedDamageResolver(),
      );

      expect(result.state.defendedEntity?.isDestroyed, isTrue);
      expect(result.state.player.currentHealth, 100);
      expect(
        result.events.whereType<Phase0aDefendedEntityDestroyed>(),
        hasLength(1),
      );
      expect(result.events.whereType<Phase0aHitLanded>(), isEmpty);
    },
  );
}
