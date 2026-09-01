import 'dart:collection';

import '../../core/domain/enums.dart';

/// Non-persistent production modifiers for one single-stage weapon attack.
///
/// The values multiply the existing Phase 0A player basic-attack baseline;
/// damage continues to come only from the bound basic [SkillDef].
final class WeaponAttackProfileDef {
  WeaponAttackProfileDef({
    required this.archetype,
    required this.rangeFactor,
    required this.halfArcFactor,
    required this.cooldownFactor,
    required this.postureDamageFactor,
    required this.maxTargets,
    required this.attackDisplacement,
  }) {
    _requirePositiveFinite(rangeFactor, 'rangeFactor');
    _requirePositiveFinite(halfArcFactor, 'halfArcFactor');
    _requirePositiveFinite(cooldownFactor, 'cooldownFactor');
    _requirePositiveFinite(postureDamageFactor, 'postureDamageFactor');
    if (maxTargets != 1) {
      throw ArgumentError.value(
        maxTargets,
        'maxTargets',
        'single-stage production basic attacks must target exactly one actor',
      );
    }
    if (!attackDisplacement.isFinite || attackDisplacement != 0) {
      throw ArgumentError.value(
        attackDisplacement,
        'attackDisplacement',
        'single-stage production basic attacks must not move the player',
      );
    }
  }

  final WeaponArchetype archetype;
  final double rangeFactor;
  final double halfArcFactor;
  final double cooldownFactor;
  final double postureDamageFactor;
  final int maxTargets;
  final double attackDisplacement;
}

final class WeaponAttackProfileCatalog {
  WeaponAttackProfileCatalog(Iterable<WeaponAttackProfileDef> profiles)
    : profiles = List<WeaponAttackProfileDef>.unmodifiable(profiles) {
    final byArchetype = <WeaponArchetype, WeaponAttackProfileDef>{};
    for (final profile in this.profiles) {
      if (byArchetype.containsKey(profile.archetype)) {
        throw ArgumentError.value(
          profile.archetype.name,
          'profiles',
          'duplicate weapon archetype',
        );
      }
      byArchetype[profile.archetype] = profile;
    }
    final missing = WeaponArchetype.values
        .where((archetype) => !byArchetype.containsKey(archetype))
        .map((archetype) => archetype.name)
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw ArgumentError.value(
        missing,
        'profiles',
        'every production weapon archetype requires one profile',
      );
    }
    _byArchetype = UnmodifiableMapView(byArchetype);
  }

  final List<WeaponAttackProfileDef> profiles;
  late final UnmodifiableMapView<WeaponArchetype, WeaponAttackProfileDef>
  _byArchetype;

  WeaponAttackProfileDef profileFor(WeaponArchetype archetype) =>
      _byArchetype[archetype]!;
}

void _requirePositiveFinite(double value, String field) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, field, 'must be finite and positive');
  }
}
