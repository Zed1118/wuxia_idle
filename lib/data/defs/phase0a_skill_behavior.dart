enum Phase0aSkillGeometryShape { radial }

enum Phase0aSkillGeometryAnchor { caster }

enum Phase0aSkillEffectType { damage, pull, stagger, breakPower }

final class Phase0aSkillGeometry {
  const Phase0aSkillGeometry({
    required this.shape,
    required this.anchor,
    required this.radius,
  });

  final Phase0aSkillGeometryShape shape;
  final Phase0aSkillGeometryAnchor anchor;
  final double radius;
}

final class Phase0aSkillEffect {
  const Phase0aSkillEffect({
    required this.type,
    this.destinationRadius,
    this.points,
  });

  final Phase0aSkillEffectType type;
  final double? destinationRadius;
  final int? points;
}

/// Data-defined Phase 0A tactical behavior. Damage magnitude, qi and cooldown
/// remain on SkillDef; this object only carries spatial/effect semantics.
final class Phase0aSkillBehavior {
  Phase0aSkillBehavior({
    required this.geometry,
    required List<Phase0aSkillEffect> effects,
  }) : effects = List.unmodifiable(effects) {
    if (!geometry.radius.isFinite || geometry.radius <= 0) {
      throw StateError('Phase0a skill geometry radius must be finite/positive');
    }
    if (effects.isEmpty) {
      throw StateError('Phase0a skill behavior requires at least one effect');
    }
    final seen = <Phase0aSkillEffectType>{};
    for (final effect in effects) {
      if (!seen.add(effect.type)) {
        throw StateError('Duplicate Phase0a effect: ${effect.type.name}');
      }
      switch (effect.type) {
        case Phase0aSkillEffectType.pull:
          final destination = effect.destinationRadius;
          if (destination == null ||
              !destination.isFinite ||
              destination < 0 ||
              destination > geometry.radius) {
            throw StateError(
              'Phase0a pull destinationRadius must be within geometry radius',
            );
          }
          if (effect.points != null) {
            throw StateError('Phase0a pull effect cannot define points');
          }
        case Phase0aSkillEffectType.breakPower:
          final points = effect.points;
          if (points == null || points <= 0) {
            throw StateError('Phase0a break effect requires positive points');
          }
          if (effect.destinationRadius != null) {
            throw StateError(
              'Phase0a break effect cannot define destinationRadius',
            );
          }
        case Phase0aSkillEffectType.damage || Phase0aSkillEffectType.stagger:
          if (effect.destinationRadius != null || effect.points != null) {
            throw StateError(
              'Phase0a ${effect.type.name} effect has unexpected parameters',
            );
          }
      }
    }
  }

  final Phase0aSkillGeometry geometry;
  final List<Phase0aSkillEffect> effects;

  bool hasEffect(Phase0aSkillEffectType type) =>
      effects.any((effect) => effect.type == type);

  Phase0aSkillEffect? effectOf(Phase0aSkillEffectType type) {
    for (final effect in effects) {
      if (effect.type == type) return effect;
    }
    return null;
  }

  factory Phase0aSkillBehavior.fromYaml(Map<String, dynamic> yaml) {
    final rawGeometry = Map<String, dynamic>.from(
      yaml['geometry'] as Map? ?? const {},
    );
    final rawShape = rawGeometry['shape'];
    final rawAnchor = rawGeometry['anchor'];
    if (rawShape != 'radial') {
      throw StateError('Unsupported Phase0a geometry shape: $rawShape');
    }
    if (rawAnchor != 'caster') {
      throw StateError('Unsupported Phase0a geometry anchor: $rawAnchor');
    }
    final rawEffects = yaml['effects'];
    if (rawEffects is! List) {
      throw StateError('Phase0a behavior effects must be a list');
    }
    return Phase0aSkillBehavior(
      geometry: Phase0aSkillGeometry(
        shape: Phase0aSkillGeometryShape.radial,
        anchor: Phase0aSkillGeometryAnchor.caster,
        radius: (rawGeometry['radius'] as num).toDouble(),
      ),
      effects: [
        for (final raw in rawEffects)
          _effectFromYaml(Map<String, dynamic>.from(raw as Map)),
      ],
    );
  }

  static Phase0aSkillEffect _effectFromYaml(Map<String, dynamic> yaml) {
    final rawType = yaml['type'];
    final type = switch (rawType) {
      'damage' => Phase0aSkillEffectType.damage,
      'pull' => Phase0aSkillEffectType.pull,
      'stagger' => Phase0aSkillEffectType.stagger,
      'break' => Phase0aSkillEffectType.breakPower,
      _ => throw StateError('Unsupported Phase0a effect type: $rawType'),
    };
    return Phase0aSkillEffect(
      type: type,
      destinationRadius: (yaml['destinationRadius'] as num?)?.toDouble(),
      points: (yaml['points'] as num?)?.toInt(),
    );
  }
}
