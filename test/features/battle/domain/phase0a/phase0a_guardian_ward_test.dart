import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

final class _RecordingResolver implements Phase0aDamageResolver {
  final wardMultipliers = <double>[];

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
    double defenderWardMult = 1.0,
  }) {
    wardMultipliers.add(defenderWardMult);
    return const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 1);
  }
}

final class _SequencedResolver implements Phase0aDamageResolver {
  final targetIds = <String>[];
  final wardMultipliers = <double>[];

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderCharging = false,
    double defenderWardMult = 1.0,
  }) {
    targetIds.add(targetId);
    wardMultipliers.add(defenderWardMult);
    return Phase0aResolvedHit(
      isHit: true,
      isCritical: false,
      damage: targetId.startsWith('guard_a') ? 10 : 1,
    );
  }
}

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required ArenaVector position,
  int currentHealth = 10,
  List<String> guardianDefIds = const [],
  double? guardianWardMult,
}) => Phase0aActor(
  id: id,
  side: side,
  position: position,
  facing: side == Phase0aSide.player
      ? const ArenaVector(1, 0)
      : const ArenaVector(-1, 0),
  maxHealth: currentHealth,
  currentHealth: currentHealth,
  moveSpeed: 0,
  qiCurrent: 0,
  qiMax: 0,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
  guardianDefIds: guardianDefIds,
  guardianWardMult: guardianWardMult,
);

const _attack = Phase0aAttackIntent(
  actorId: 'player',
  range: 300,
  halfArcRadians: 1,
  cooldownSeconds: 0,
  moveKind: Phase0aMoveKind.light,
  aimDirection: ArenaVector(1, 0),
  qiDelta: 0,
);

Phase0aArenaState _state({required List<Phase0aActor> enemies}) =>
    Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: _actor(
        id: 'player',
        side: Phase0aSide.player,
        position: ArenaVector.zero,
        currentHealth: 100,
      ),
      enemies: enemies,
      skillSlots: const [],
    );

void main() {
  test('reducer passes configured ward only while a guardian id is alive', () {
    final resolver = _RecordingResolver();
    final state = _state(
      enemies: [
        _actor(
          id: 'boss',
          side: Phase0aSide.enemy,
          position: const ArenaVector(100, 0),
          currentHealth: 10,
          guardianDefIds: const ['guard_a'],
          guardianWardMult: 0.35,
        ),
        _actor(
          id: 'guard_a_w0s1',
          side: Phase0aSide.enemy,
          position: const ArenaVector(200, 0),
        ),
      ],
    );

    reducePhase0aTick(
      state: state,
      intents: const [_attack],
      deltaSeconds: 0,
      damageResolver: resolver,
    );
    expect(resolver.wardMultipliers, [0.35]);

    final withoutGuardian = _state(
      enemies: [
        _actor(
          id: 'boss',
          side: Phase0aSide.enemy,
          position: const ArenaVector(100, 0),
          currentHealth: 10,
          guardianDefIds: const ['guard_a'],
          guardianWardMult: 0.35,
        ),
      ],
    );
    reducePhase0aTick(
      state: withoutGuardian,
      intents: const [_attack],
      deltaSeconds: 0,
      damageResolver: resolver,
    );
    expect(resolver.wardMultipliers, [0.35, 1.0]);
  });

  test('actor equality, hash and copyWith include guardian configuration', () {
    final actor = _actor(
      id: 'boss',
      side: Phase0aSide.enemy,
      position: const ArenaVector(100, 0),
      guardianDefIds: const ['guard_a'],
      guardianWardMult: 0.4,
    );
    final same = actor.copyWith();
    final changed = actor.copyWith(currentHealth: 9);
    expect(same, actor);
    expect(same.hashCode, actor.hashCode);
    expect(changed, isNot(actor));
  });

  test('guardian reduced to zero earlier in the same tick releases ward', () {
    final resolver = _SequencedResolver();
    final state = _state(
      enemies: [
        _actor(
          id: 'guard_a_w0s0',
          side: Phase0aSide.enemy,
          position: const ArenaVector(50, 0),
        ),
        _actor(
          id: 'boss_w0s1',
          side: Phase0aSide.enemy,
          position: const ArenaVector(100, 0),
          guardianDefIds: const ['guard_a'],
          guardianWardMult: 0.35,
        ),
      ],
    );

    reducePhase0aTick(
      state: state,
      intents: const [_attack, _attack],
      deltaSeconds: 0,
      damageResolver: resolver,
    );

    expect(resolver.targetIds, ['guard_a_w0s0', 'boss_w0s1']);
    expect(resolver.wardMultipliers, [1.0, 1.0]);
  });
}
