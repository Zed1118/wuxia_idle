import 'dart:math' as math;

import 'arena_vector.dart';

/// A stable, caller-owned target snapshot used by geometry queries.
final class CombatGeometryTarget {
  const CombatGeometryTarget(this.id, this.position);

  final String id;
  final ArenaVector position;
}

enum GeometryScopeKind {
  forwardFan,
  selfCircle,
  targetPointCircle,
  lineCapsule,
  displacementTrail,
  selfState,
}

enum StateRefreshPolicy { replace, extend, ignore }

enum StateStackingPolicy { unique, additive, independent }

enum SelfStateEffect {
  guardWindow,
  parryWindow,
  chargeCounter,
  movementModifier,
}

sealed class CombatGeometryScope {
  const CombatGeometryScope();

  GeometryScopeKind get kind;

  List<CombatGeometryTarget> hitTargets(Iterable<CombatGeometryTarget> targets);
}

final class ForwardFanScope extends CombatGeometryScope {
  const ForwardFanScope({
    required this.origin,
    required this.direction,
    required this.maxDistance,
    required this.halfAngleRadians,
    required this.maxTargets,
  });

  final ArenaVector origin;
  final ArenaVector direction;
  final double maxDistance;
  final double halfAngleRadians;
  final int maxTargets;

  @override
  GeometryScopeKind get kind => GeometryScopeKind.forwardFan;

  @override
  List<CombatGeometryTarget> hitTargets(
    Iterable<CombatGeometryTarget> targets,
  ) {
    final unit = _unit(direction);
    if (!_finiteVector(origin) ||
        unit == null ||
        !_validRange(maxDistance) ||
        !_validRange(halfAngleRadians) ||
        halfAngleRadians < 0 ||
        halfAngleRadians > math.pi ||
        maxTargets <= 0) {
      return const [];
    }
    final cosine = math.cos(halfAngleRadians);
    return _ordered(targets, (target) {
      final offset = target.position - origin;
      final distance = offset.length;
      if (!_finiteTarget(target) || distance > maxDistance) return null;
      if (distance == 0) return 0;
      return unit.dot(offset) / distance + _comparisonTolerance >= cosine
          ? distance
          : null;
    }, maxTargets);
  }
}

final class SelfCircleScope extends _CircleScope {
  const SelfCircleScope({
    required super.center,
    required super.innerRadius,
    required super.outerRadius,
    required super.maxTargets,
  });

  @override
  GeometryScopeKind get kind => GeometryScopeKind.selfCircle;
}

final class TargetPointCircleScope extends _CircleScope {
  const TargetPointCircleScope({
    required super.center,
    required super.innerRadius,
    required super.outerRadius,
    required super.maxTargets,
  });

  @override
  GeometryScopeKind get kind => GeometryScopeKind.targetPointCircle;
}

sealed class _CircleScope extends CombatGeometryScope {
  const _CircleScope({
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.maxTargets,
  });

  final ArenaVector center;
  final double innerRadius;
  final double outerRadius;
  final int maxTargets;

  @override
  List<CombatGeometryTarget> hitTargets(
    Iterable<CombatGeometryTarget> targets,
  ) {
    if (!_finiteVector(center) ||
        !_validRange(innerRadius) ||
        !_validRange(outerRadius) ||
        innerRadius < 0 ||
        outerRadius < innerRadius ||
        maxTargets <= 0) {
      return const [];
    }
    return _ordered(targets, (target) {
      if (!_finiteTarget(target)) return null;
      final distance = (target.position - center).length;
      return distance >= innerRadius && distance <= outerRadius
          ? distance
          : null;
    }, maxTargets);
  }
}

final class LineCapsuleScope extends CombatGeometryScope {
  const LineCapsuleScope({
    required this.start,
    required this.end,
    required this.radius,
    required this.maxTargets,
  });

  final ArenaVector start;
  final ArenaVector end;
  final double radius;
  final int maxTargets;

  @override
  GeometryScopeKind get kind => GeometryScopeKind.lineCapsule;

  @override
  List<CombatGeometryTarget> hitTargets(
    Iterable<CombatGeometryTarget> targets,
  ) {
    final axis = end - start;
    final lengthSquared = axis.dot(axis);
    if (!_finiteVector(start) ||
        !_finiteVector(end) ||
        !_validRange(radius) ||
        radius < 0 ||
        lengthSquared == 0 ||
        maxTargets <= 0)
      return const [];
    return _ordered(targets, (target) {
      if (!_finiteTarget(target)) return null;
      final offset = target.position - start;
      final projection = offset.dot(axis) / lengthSquared;
      final clamped = projection.clamp(0.0, 1.0).toDouble();
      final closest = start + axis * clamped;
      final distance = (target.position - closest).length;
      return distance <= radius ? projection.clamp(0.0, 1.0).toDouble() : null;
    }, maxTargets);
  }
}

final class DisplacementTrailScope extends CombatGeometryScope {
  const DisplacementTrailScope({
    required this.start,
    required this.end,
    required this.radius,
    required this.maxTargets,
  });

  final ArenaVector start;
  final ArenaVector end;
  final double radius;
  final int maxTargets;

  @override
  GeometryScopeKind get kind => GeometryScopeKind.displacementTrail;

  @override
  List<CombatGeometryTarget> hitTargets(
    Iterable<CombatGeometryTarget> targets,
  ) => LineCapsuleScope(
    start: start,
    end: end,
    radius: radius,
    maxTargets: maxTargets,
  ).hitTargets(targets);
}

final class SelfStateScope extends CombatGeometryScope {
  const SelfStateScope({
    required this.durationSeconds,
    required this.refreshPolicy,
    required this.stackingPolicy,
    required this.cancelWindowSeconds,
    required this.effects,
  });

  final double durationSeconds;
  final StateRefreshPolicy refreshPolicy;
  final StateStackingPolicy stackingPolicy;
  final double cancelWindowSeconds;
  final List<SelfStateEffect> effects;

  @override
  GeometryScopeKind get kind => GeometryScopeKind.selfState;

  @override
  List<CombatGeometryTarget> hitTargets(
    Iterable<CombatGeometryTarget> targets,
  ) => const [];
}

ArenaVector? _unit(ArenaVector vector) {
  if (!_finiteVector(vector) || vector.length == 0) return null;
  return vector.normalized();
}

bool _validRange(double value) => value.isFinite;

const _comparisonTolerance = 1e-12;

bool _finiteVector(ArenaVector vector) =>
    vector.x.isFinite && vector.y.isFinite;

bool _finiteTarget(CombatGeometryTarget target) =>
    _finiteVector(target.position);

List<CombatGeometryTarget> _ordered(
  Iterable<CombatGeometryTarget> targets,
  double? Function(CombatGeometryTarget) distance,
  int maxTargets,
) {
  final matches = <({CombatGeometryTarget target, double order})>[];
  for (final target in targets) {
    final order = distance(target);
    if (order != null) {
      matches.add((target: target, order: order));
    }
  }
  matches.sort((a, b) {
    final byGeometry = a.order.compareTo(b.order);
    if (byGeometry != 0) return byGeometry;
    return a.target.id.compareTo(b.target.id);
  });
  return matches
      .take(maxTargets)
      .map((entry) => entry.target)
      .toList(growable: false);
}
