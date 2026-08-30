import '../../domain/phase0a/arena_vector.dart';

/// Presentation-only camera follower that lets the player move inside a world
/// space dead zone before the camera follows. This keeps short combat lunges
/// readable as actor motion instead of making the world appear to pull toward
/// a player pinned to the screen center.
abstract final class Phase0aCameraDeadZone {
  static ArenaVector follow({
    required ArenaVector current,
    required ArenaVector target,
    required double halfWidth,
    required double halfHeight,
  }) {
    _requireExtent(halfWidth, 'halfWidth');
    _requireExtent(halfHeight, 'halfHeight');
    return ArenaVector(
      _followAxis(current.x, target.x, halfWidth),
      _followAxis(current.y, target.y, halfHeight),
    );
  }

  static double _followAxis(double current, double target, double extent) {
    final delta = target - current;
    if (delta > extent) return target - extent;
    if (delta < -extent) return target + extent;
    return current;
  }

  static void _requireExtent(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, name, 'must be finite and non-negative');
    }
  }
}
