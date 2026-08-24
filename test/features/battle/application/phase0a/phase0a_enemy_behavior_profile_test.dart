import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_enemy_behavior_profile.dart';

void main() {
  const profiles = {
    'direct': Phase0aEnemyBehaviorProfile(
      id: 'ai_bandit_press',
      movementPolicy: Phase0aEnemyMovementPolicy.directAdvance,
      attackPolicy: Phase0aEnemyAttackPolicy.closeRange,
    ),
    'hold': Phase0aEnemyBehaviorProfile(
      id: 'ai_crossbow_offset',
      movementPolicy: Phase0aEnemyMovementPolicy.holdDistance,
      attackPolicy: Phase0aEnemyAttackPolicy.rangedPressure,
    ),
    'flank': Phase0aEnemyBehaviorProfile(
      id: 'ai_rope_flank',
      movementPolicy: Phase0aEnemyMovementPolicy.lateralFlank,
      attackPolicy: Phase0aEnemyAttackPolicy.chargeAndReposition,
    ),
    'guard': Phase0aEnemyBehaviorProfile(
      id: 'ai_gong_command',
      movementPolicy: Phase0aEnemyMovementPolicy.guardedPosition,
      attackPolicy: Phase0aEnemyAttackPolicy.supportPulse,
    ),
  };

  Phase0aActor actor(
    String id,
    ArenaVector position, {
    double attackCooldownRemaining = 0,
  }) => Phase0aActor(
    id: id,
    side: Phase0aSide.enemy,
    position: position,
    facing: const ArenaVector(-1, 0),
    maxHealth: 1000,
    currentHealth: 1000,
    moveSpeed: 100,
    qiCurrent: 0,
    qiMax: 0,
    attackCooldownRemaining: attackCooldownRemaining,
    defeatKind: Phase0aDefeatKind.normal,
  );

  Phase0aArenaState state({
    double holdCooldown = 0,
    bool flankInRange = false,
    double flankCooldown = 0,
  }) => Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: const Phase0aActor(
      id: 'player',
      side: Phase0aSide.player,
      position: ArenaVector.zero,
      facing: ArenaVector(1, 0),
      maxHealth: 1000,
      currentHealth: 1000,
      moveSpeed: 100,
      qiCurrent: 0,
      qiMax: 0,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    ),
    enemies: [
      actor('direct', const ArenaVector(200, 0)),
      actor(
        'hold',
        const ArenaVector(50, 0),
        attackCooldownRemaining: holdCooldown,
      ),
      actor(
        'flank',
        flankInRange ? const ArenaVector(50, 0) : const ArenaVector(200, 100),
        attackCooldownRemaining: flankCooldown,
      ),
      actor('guard', const ArenaVector(200, -100)),
    ],
    skillSlots: const [],
  );

  test('each stage_01_03 movement policy produces a distinct intent', () {
    final adapter = const Phase0aEnemyAiAdapter(
      attackRange: 82,
      attackHalfArcRadians: 0.9,
      attackCooldownSeconds: 1,
      behaviorProfilesByActor: profiles,
    );

    final intents = adapter.intentsFor(state: state(holdCooldown: 1));
    final moves = {
      for (final intent in intents.whereType<Phase0aMoveIntent>())
        intent.actorId: intent,
    };

    expect(moves.keys, containsAll(profiles.keys));
    for (final entry in profiles.entries) {
      expect(moves[entry.key]!.behaviorProfile, entry.value);
    }
    expect(moves['direct']!.direction, const ArenaVector(-1, 0));
    expect(moves['hold']!.direction, const ArenaVector(1, 0));
    expect(moves['flank']!.direction.x, lessThan(0));
    expect(moves['flank']!.direction.y, lessThan(0));
    expect(moves['guard']!.direction, ArenaVector.zero);
  });

  test('holdDistance and lateralFlank attack when their cooldown is ready', () {
    final adapter = const Phase0aEnemyAiAdapter(
      attackRange: 82,
      attackHalfArcRadians: 0.9,
      attackCooldownSeconds: 1,
      behaviorProfilesByActor: profiles,
    );
    final intents = adapter.intentsFor(state: state(flankInRange: true));
    final byActor = {for (final intent in intents) intent.actorId: intent};

    expect(byActor['hold'], isA<Phase0aAttackIntent>());
    expect(
      (byActor['hold']! as Phase0aAttackIntent).behaviorProfile,
      profiles['hold'],
    );
    expect(byActor['flank'], isA<Phase0aAttackIntent>());
    expect(
      (byActor['flank']! as Phase0aAttackIntent).behaviorProfile,
      profiles['flank'],
    );
  });

  test(
    'the reducer consumes the profile-derived direction in the same core',
    () {
      final adapter = const Phase0aEnemyAiAdapter(
        attackRange: 82,
        attackHalfArcRadians: 0.9,
        attackCooldownSeconds: 1,
        behaviorProfilesByActor: profiles,
      );
      final initial = state(holdCooldown: 1);
      final result = reducePhase0aTick(
        state: initial,
        intents: adapter.intentsFor(state: initial),
        deltaSeconds: 1,
        damageResolver: const _NoDamageResolver(),
      );
      final enemies = {
        for (final enemy in result.state.enemies) enemy.id: enemy,
      };

      expect(enemies['direct']!.position, const ArenaVector(100, 0));
      expect(enemies['hold']!.position, const ArenaVector(150, 0));
      expect(enemies['flank']!.position.x, closeTo(168.377, 0.001));
      expect(enemies['flank']!.position.y, closeTo(5.131, 0.001));
      expect(enemies['guard']!.position, const ArenaVector(200, -100));
    },
  );
}

final class _NoDamageResolver implements Phase0aDamageResolver {
  const _NoDamageResolver();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
    required double defenderWardMult,
  }) => const Phase0aResolvedHit(isHit: false, isCritical: false, damage: 0);
}
