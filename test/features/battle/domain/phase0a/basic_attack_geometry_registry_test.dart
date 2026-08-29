import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/basic_attack_chain.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/basic_attack_geometry_registry.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';

final class _HitResolver implements Phase0aDamageResolver {
  const _HitResolver();

  @override
  Phase0aResolvedHit resolve({
    required String attackerId,
    required String targetId,
    required Phase0aDamageKind kind,
    bool defenderStaggered = false,
    bool defenderVulnerable = false,
    double defenderWardMult = 1.0,
  }) => const Phase0aResolvedHit(isHit: true, isCritical: false, damage: 1);
}

const _bounds = BasicAttackArenaBounds(
  minX: -640,
  maxX: 640,
  minY: -260,
  maxY: 260,
);

BasicAttackGeometryRegistry _registry({bool includeSweep = true}) =>
    BasicAttackGeometryRegistry({
      swordBasicAttackChain.segments[0].geometryRef:
          const BasicAttackGeometryTuning(
            attackRange: 480,
            attackHalfArcRadians: 0.35,
            maxTargets: 1,
            advanceDistance: 0,
            aimAssistRadians: 0,
          ),
      if (includeSweep)
        swordBasicAttackChain.segments[1].geometryRef:
            const BasicAttackGeometryTuning(
              attackRange: 400,
              attackHalfArcRadians: 1.30,
              maxTargets: 1,
              advanceDistance: 0,
              aimAssistRadians: 0,
            ),
      swordBasicAttackChain.segments[2].geometryRef:
          const BasicAttackGeometryTuning(
            attackRange: 440,
            attackHalfArcRadians: 0.60,
            maxTargets: 1,
            advanceDistance: 120,
            aimAssistRadians: 0,
          ),
    });

Phase0aActor _player({int segmentIndex = 0, double x = 0}) => Phase0aActor(
  id: 'player',
  side: Phase0aSide.player,
  position: ArenaVector(x, 0),
  facing: const ArenaVector(1, 0),
  maxHealth: 100,
  currentHealth: 100,
  moveSpeed: 100,
  qiCurrent: 0,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
  basicAttackSegmentIndex: segmentIndex,
);

Phase0aActor _enemy(ArenaVector position, {String id = 'enemy'}) =>
    Phase0aActor(
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

Phase0aStepResult _attack({
  required int segmentIndex,
  required List<Phase0aActor> enemies,
  BasicAttackGeometryRegistry? registry,
  double playerX = 0,
  List<double> barriersX = const [],
}) => reducePhase0aTick(
  state: Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: _player(segmentIndex: segmentIndex, x: playerX),
    enemies: enemies,
    skillSlots: const [],
  ),
  intents: [
    Phase0aAttackIntent(
      actorId: 'player',
      range: 420,
      halfArcRadians: 0.72,
      cooldownSeconds: 0.55,
      moveKind: Phase0aMoveKind.light,
      aimDirection: const ArenaVector(1, 0),
      qiDelta: 0,
      postureDamage: 0,
      postureHitKind: PostureHitKind.light,
      basicAttackChain: swordBasicAttackChain,
      basicAttackGeometryRegistry: registry ?? _registry(),
      basicAttackArenaBounds: _bounds,
      basicAttackDisplacementBarriersX: barriersX,
    ),
  ],
  deltaSeconds: 0.1,
  damageResolver: const _HitResolver(),
);

void main() {
  test('production sword refs use one geometry.sword namespace', () {
    expect(swordBasicAttackChain.geometryRefs, [
      'geometry.sword.thrust',
      'geometry.sword.sweep',
      'geometry.sword.advancing_slash',
    ]);
  });

  test('same side target misses thrust but hits sweep', () {
    final sideTarget = _enemy(
      ArenaVector(100 * math.cos(0.8), 100 * math.sin(0.8)),
    );

    final thrust = _attack(segmentIndex: 0, enemies: [sideTarget]);
    final sweep = _attack(segmentIndex: 1, enemies: [sideTarget]);

    expect(
      thrust.events.whereType<Phase0aHitLanded>(),
      isEmpty,
      reason: '0.8 rad is outside thrust ±0.35 rad',
    );
    expect(
      sweep.events.whereType<Phase0aHitLanded>().single.target,
      'enemy',
      reason: '0.8 rad is inside sweep ±1.30 rad',
    );
  });

  test(
    'missing geometry ref fails closed instead of using shared fallback',
    () {
      expect(
        () => _attack(
          segmentIndex: 1,
          enemies: [_enemy(const ArenaVector(100, 0))],
          registry: _registry(includeSweep: false),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'advancing slash clamps to arena and cannot cross a displacement barrier',
    () {
      final arenaEdge = _attack(
        segmentIndex: 2,
        playerX: 630,
        enemies: const [],
      );
      expect(arenaEdge.state.player.position, const ArenaVector(640, 0));

      final checkpoint = _attack(
        segmentIndex: 2,
        playerX: 500,
        enemies: const [],
        barriersX: const [520],
      );
      expect(checkpoint.state.player.position, const ArenaVector(500, 0));
    },
  );

  test(
    'advancing slash stops at and resolves the target selected before moving',
    () {
      final result = _attack(
        segmentIndex: 2,
        enemies: [
          _enemy(const ArenaVector(60, 20), id: 'near'),
          _enemy(const ArenaVector(200, 0), id: 'far'),
        ],
      );

      expect(result.state.player.position, const ArenaVector(60, 0));
      expect(
        result.events.whereType<Phase0aHitLanded>().single.target,
        'near',
        reason: 'movement and damage must reuse one pre-move geometry target',
      );
    },
  );

  test('advancing slash uses its full cap when the cone has no target', () {
    final result = _attack(
      segmentIndex: 2,
      enemies: [_enemy(const ArenaVector(0, 200))],
    );

    expect(result.state.player.position, const ArenaVector(120, 0));
    expect(result.events.whereType<Phase0aHitLanded>(), isEmpty);
  });

  test('zero aim assist preserves the exact caller direction', () {
    const input = ArenaVector(0.8, 0.6);
    final resolved = _registry().resolveAimDirection(
      segment: swordBasicAttackChain.segments.first,
      origin: ArenaVector.zero,
      inputDirection: input,
      candidates: const [BasicAttackAimCandidate('enemy', ArenaVector(100, 0))],
    );
    expect(resolved, same(input));
  });
}
