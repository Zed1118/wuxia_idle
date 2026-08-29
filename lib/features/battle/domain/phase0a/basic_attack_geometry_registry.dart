import 'dart:math' as math;

import 'arena_vector.dart';
import 'basic_attack_chain.dart';
import 'combat_geometry.dart';

/// Runtime values for one basic-attack geometry ref.
///
/// The registry never supplies tuning defaults. Every value is injected from
/// the typed numbers configuration by the production mapper.
final class BasicAttackGeometryTuning {
  const BasicAttackGeometryTuning({
    required this.attackRange,
    required this.attackHalfArcRadians,
    required this.maxTargets,
    required this.advanceDistance,
    required this.aimAssistRadians,
  });

  final double attackRange;
  final double attackHalfArcRadians;
  final int maxTargets;
  final double advanceDistance;
  final double aimAssistRadians;

  void validate() {
    if (!attackRange.isFinite || attackRange <= 0) {
      throw ArgumentError.value(attackRange, 'attackRange');
    }
    if (!attackHalfArcRadians.isFinite ||
        attackHalfArcRadians < 0 ||
        attackHalfArcRadians > math.pi) {
      throw ArgumentError.value(attackHalfArcRadians, 'attackHalfArcRadians');
    }
    if (maxTargets <= 0) {
      throw ArgumentError.value(maxTargets, 'maxTargets');
    }
    if (!advanceDistance.isFinite || advanceDistance < 0) {
      throw ArgumentError.value(advanceDistance, 'advanceDistance');
    }
    if (!aimAssistRadians.isFinite ||
        aimAssistRadians < 0 ||
        aimAssistRadians > math.pi) {
      throw ArgumentError.value(aimAssistRadians, 'aimAssistRadians');
    }
  }
}

final class BasicAttackAimCandidate {
  const BasicAttackAimCandidate(this.id, this.position);

  final String id;
  final ArenaVector position;
}

final class BasicAttackArenaBounds {
  const BasicAttackArenaBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  void validate() {
    if (!minX.isFinite ||
        !maxX.isFinite ||
        !minY.isFinite ||
        !maxY.isFinite ||
        minX >= maxX ||
        minY >= maxY) {
      throw ArgumentError('invalid basic attack arena bounds');
    }
  }

  ArenaVector clamp(ArenaVector position) => ArenaVector(
    position.x.clamp(minX, maxX).toDouble(),
    position.y.clamp(minY, maxY).toDouble(),
  );
}

/// Fail-closed bridge from an opaque [BasicAttackSegment.geometryRef] to the
/// existing combat geometry kernel.
final class BasicAttackGeometryRegistry {
  BasicAttackGeometryRegistry(Map<String, BasicAttackGeometryTuning> mappings)
    : _mappings = Map.unmodifiable(Map.of(mappings)) {
    for (final entry in _mappings.entries) {
      if (entry.key.isEmpty || entry.key != entry.key.trim()) {
        throw ArgumentError.value(entry.key, 'geometryRef');
      }
      entry.value.validate();
    }
  }

  final Map<String, BasicAttackGeometryTuning> _mappings;

  List<String> get refs => List.unmodifiable(_mappings.keys);

  BasicAttackGeometryTuning tuningFor(BasicAttackSegment segment) {
    final tuning = _mappings[segment.geometryRef];
    if (tuning == null) {
      throw StateError(
        'missing basic attack geometry ref: ${segment.geometryRef}',
      );
    }
    return tuning;
  }

  ForwardFanScope scopeFor({
    required BasicAttackSegment segment,
    required ArenaVector origin,
    required ArenaVector direction,
  }) {
    final tuning = tuningFor(segment);
    return ForwardFanScope(
      origin: origin,
      direction: direction,
      maxDistance: tuning.attackRange,
      halfAngleRadians: tuning.attackHalfArcRadians,
      maxTargets: tuning.maxTargets,
    );
  }

  ArenaVector resolveAimDirection({
    required BasicAttackSegment segment,
    required ArenaVector origin,
    required ArenaVector inputDirection,
    required Iterable<BasicAttackAimCandidate> candidates,
  }) {
    final tuning = tuningFor(segment);
    if (tuning.aimAssistRadians == 0 || inputDirection.lengthSquared == 0) {
      return inputDirection;
    }
    final inputUnit = inputDirection.normalized();
    final eligible =
        <
          ({BasicAttackAimCandidate candidate, double angle, double distance})
        >[];
    for (final candidate in candidates) {
      final offset = candidate.position - origin;
      final distance = offset.length;
      if (!distance.isFinite ||
          distance == 0 ||
          distance > tuning.attackRange) {
        continue;
      }
      final dot = inputUnit.dot(offset.normalized()).clamp(-1.0, 1.0);
      final angle = math.acos(dot.toDouble());
      if (angle <= tuning.aimAssistRadians) {
        eligible.add((candidate: candidate, angle: angle, distance: distance));
      }
    }
    if (eligible.isEmpty) return inputDirection;
    eligible.sort((a, b) {
      final byAngle = a.angle.compareTo(b.angle);
      if (byAngle != 0) return byAngle;
      final byDistance = a.distance.compareTo(b.distance);
      return byDistance != 0
          ? byDistance
          : a.candidate.id.compareTo(b.candidate.id);
    });
    return (eligible.first.candidate.position - origin).normalized();
  }
}

ArenaVector resolveBasicAttackAdvance({
  required ArenaVector origin,
  required ArenaVector direction,
  required double distance,
  CombatGeometryTarget? stopTarget,
  required BasicAttackArenaBounds bounds,
}) {
  bounds.validate();
  if (!distance.isFinite || distance < 0) {
    throw ArgumentError.value(distance, 'distance');
  }
  if (distance == 0 || direction.lengthSquared == 0) return origin;
  final directionUnit = direction.normalized();
  var travelDistance = distance;
  if (stopTarget != null) {
    // Phase0A actors currently use point geometry, so center contact is the
    // existing zero-radius engagement margin. Never advance past the target.
    final forwardDistance = directionUnit.dot(stopTarget.position - origin);
    travelDistance = math.min(distance, math.max(0, forwardDistance));
  }
  return bounds.clamp(origin + directionUnit * travelDistance);
}
