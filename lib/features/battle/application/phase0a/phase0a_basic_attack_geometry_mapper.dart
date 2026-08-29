import '../../../../data/numbers_config.dart';
import '../../domain/phase0a/basic_attack_chain.dart';
import '../../domain/phase0a/basic_attack_geometry_registry.dart';

/// Converts typed numbers into the sword-only runtime geometry registry.
///
/// This mapper intentionally registers no heavy/flexible/dual/hidden refs.
final class Phase0aBasicAttackGeometryMapper {
  const Phase0aBasicAttackGeometryMapper._();

  static BasicAttackGeometryRegistry swordRegistryFromArena(
    Phase0aArenaConfig arena,
  ) {
    final configuredIds = arena.basicAttackChain.segmentIds.toSet();
    final swordIds = swordBasicAttackSegmentIds.toSet();
    if (configuredIds.length != swordIds.length ||
        !configuredIds.containsAll(swordIds)) {
      throw StateError(
        'sword basic attack tuning must exactly cover $swordBasicAttackSegmentIds',
      );
    }
    return BasicAttackGeometryRegistry({
      for (final segment in swordBasicAttackChain.segments)
        segment.geometryRef: _map(
          arena.basicAttackChain.tuningForSegmentId(segment.id),
        ),
    });
  }

  static BasicAttackArenaBounds arenaBoundsFrom(Phase0aArenaConfig arena) =>
      BasicAttackArenaBounds(
        minX: arena.arenaMinX,
        maxX: arena.arenaMaxX,
        minY: arena.arenaMinY,
        maxY: arena.arenaMaxY,
      );

  static BasicAttackGeometryTuning _map(
    Phase0aBasicAttackSegmentTuning tuning,
  ) => BasicAttackGeometryTuning(
    attackRange: tuning.attackRange,
    attackHalfArcRadians: tuning.attackHalfArcRadians,
    maxTargets: tuning.maxTargets,
    advanceDistance: tuning.advanceDistance,
    aimAssistRadians: tuning.aimAssistRadians,
  );
}
