import 'package:wuxia_idle/core/domain/enums.dart';

/// Typed, composable modifier candidate for the M1 combat domain.
sealed class CombatModifier {
  const CombatModifier();

  TechniqueSchool get school;

  ModifierValues applyTo(ModifierValues values);
}

final class GangMengModifier extends CombatModifier {
  GangMengModifier({
    required this.knockbackFactor,
    required this.postureDamageFactor,
    required this.breachPowerFactor,
  }) {
    _requirePositiveFactor(knockbackFactor, 'knockbackFactor');
    _requirePositiveFactor(postureDamageFactor, 'postureDamageFactor');
    _requirePositiveFactor(breachPowerFactor, 'breachPowerFactor');
  }

  final double knockbackFactor;
  final double postureDamageFactor;
  final double breachPowerFactor;

  @override
  TechniqueSchool get school => TechniqueSchool.gangMeng;

  @override
  ModifierValues applyTo(ModifierValues values) => values.copyWith(
    knockback: values.knockback * knockbackFactor,
    postureDamage: values.postureDamage * postureDamageFactor,
    breachPower: values.breachPower * breachPowerFactor,
  );
}

final class LingQiaoModifier extends CombatModifier {
  LingQiaoModifier({
    required this.pursuitFactor,
    required this.dodgeTrajectoryFactor,
    required this.recoveryFactor,
  }) {
    _requirePositiveFactor(pursuitFactor, 'pursuitFactor');
    _requirePositiveFactor(dodgeTrajectoryFactor, 'dodgeTrajectoryFactor');
    _requirePositiveFactor(recoveryFactor, 'recoveryFactor');
  }

  final double pursuitFactor;
  final double dodgeTrajectoryFactor;
  final double recoveryFactor;

  @override
  TechniqueSchool get school => TechniqueSchool.lingQiao;

  @override
  ModifierValues applyTo(ModifierValues values) => values.copyWith(
    pursuitDistance: values.pursuitDistance * pursuitFactor,
    dodgeTrajectory: values.dodgeTrajectory * dodgeTrajectoryFactor,
    recoveryDuration: values.recoveryDuration * recoveryFactor,
  );
}

final class YinRouModifier extends CombatModifier {
  YinRouModifier({
    required this.pullFactor,
    required this.slowFactor,
    required this.internalInjuryFactor,
    required this.controlDurationFactor,
  }) {
    _requirePositiveFactor(pullFactor, 'pullFactor');
    _requirePositiveFactor(slowFactor, 'slowFactor');
    _requirePositiveFactor(internalInjuryFactor, 'internalInjuryFactor');
    _requirePositiveFactor(controlDurationFactor, 'controlDurationFactor');
  }

  final double pullFactor;
  final double slowFactor;
  final double internalInjuryFactor;
  final double controlDurationFactor;

  @override
  TechniqueSchool get school => TechniqueSchool.yinRou;

  @override
  ModifierValues applyTo(ModifierValues values) => values.copyWith(
    pullStrength: values.pullStrength * pullFactor,
    slowStrength: values.slowStrength * slowFactor,
    internalInjuryStrength:
        values.internalInjuryStrength * internalInjuryFactor,
    controlDuration: values.controlDuration * controlDurationFactor,
  );
}

final class ModifierValues {
  ModifierValues({
    required this.knockback,
    required this.postureDamage,
    required this.breachPower,
    required this.pursuitDistance,
    required this.dodgeTrajectory,
    required this.recoveryDuration,
    required this.pullStrength,
    required this.slowStrength,
    required this.internalInjuryStrength,
    required this.controlDuration,
  }) {
    _validateFields({
      'knockback': knockback,
      'postureDamage': postureDamage,
      'breachPower': breachPower,
      'pursuitDistance': pursuitDistance,
      'dodgeTrajectory': dodgeTrajectory,
      'recoveryDuration': recoveryDuration,
      'pullStrength': pullStrength,
      'slowStrength': slowStrength,
      'internalInjuryStrength': internalInjuryStrength,
      'controlDuration': controlDuration,
    });
  }

  final double knockback;
  final double postureDamage;
  final double breachPower;
  final double pursuitDistance;
  final double dodgeTrajectory;
  final double recoveryDuration;
  final double pullStrength;
  final double slowStrength;
  final double internalInjuryStrength;
  final double controlDuration;

  ModifierValues copyWith({
    double? knockback,
    double? postureDamage,
    double? breachPower,
    double? pursuitDistance,
    double? dodgeTrajectory,
    double? recoveryDuration,
    double? pullStrength,
    double? slowStrength,
    double? internalInjuryStrength,
    double? controlDuration,
  }) => ModifierValues(
    knockback: knockback ?? this.knockback,
    postureDamage: postureDamage ?? this.postureDamage,
    breachPower: breachPower ?? this.breachPower,
    pursuitDistance: pursuitDistance ?? this.pursuitDistance,
    dodgeTrajectory: dodgeTrajectory ?? this.dodgeTrajectory,
    recoveryDuration: recoveryDuration ?? this.recoveryDuration,
    pullStrength: pullStrength ?? this.pullStrength,
    slowStrength: slowStrength ?? this.slowStrength,
    internalInjuryStrength:
        internalInjuryStrength ?? this.internalInjuryStrength,
    controlDuration: controlDuration ?? this.controlDuration,
  );

  @override
  bool operator ==(Object other) =>
      other is ModifierValues &&
      other.knockback == knockback &&
      other.postureDamage == postureDamage &&
      other.breachPower == breachPower &&
      other.pursuitDistance == pursuitDistance &&
      other.dodgeTrajectory == dodgeTrajectory &&
      other.recoveryDuration == recoveryDuration &&
      other.pullStrength == pullStrength &&
      other.slowStrength == slowStrength &&
      other.internalInjuryStrength == internalInjuryStrength &&
      other.controlDuration == controlDuration;

  @override
  int get hashCode => Object.hashAll([
    knockback,
    postureDamage,
    breachPower,
    pursuitDistance,
    dodgeTrajectory,
    recoveryDuration,
    pullStrength,
    slowStrength,
    internalInjuryStrength,
    controlDuration,
  ]);
}

final class ModifierBounds {
  ModifierBounds({
    required this.knockback,
    required this.postureDamage,
    required this.breachPower,
    required this.pursuitDistance,
    required this.dodgeTrajectory,
    required this.recoveryDuration,
    required this.pullStrength,
    required this.slowStrength,
    required this.internalInjuryStrength,
    required this.controlDuration,
  }) {
    _validateFields({
      'knockback': knockback,
      'postureDamage': postureDamage,
      'breachPower': breachPower,
      'pursuitDistance': pursuitDistance,
      'dodgeTrajectory': dodgeTrajectory,
      'recoveryDuration': recoveryDuration,
      'pullStrength': pullStrength,
      'slowStrength': slowStrength,
      'internalInjuryStrength': internalInjuryStrength,
      'controlDuration': controlDuration,
    });
  }

  final double knockback;
  final double postureDamage;
  final double breachPower;
  final double pursuitDistance;
  final double dodgeTrajectory;
  final double recoveryDuration;
  final double pullStrength;
  final double slowStrength;
  final double internalInjuryStrength;
  final double controlDuration;

  ModifierBounds copyWith({
    double? knockback,
    double? postureDamage,
    double? breachPower,
    double? pursuitDistance,
    double? dodgeTrajectory,
    double? recoveryDuration,
    double? pullStrength,
    double? slowStrength,
    double? internalInjuryStrength,
    double? controlDuration,
  }) => ModifierBounds(
    knockback: knockback ?? this.knockback,
    postureDamage: postureDamage ?? this.postureDamage,
    breachPower: breachPower ?? this.breachPower,
    pursuitDistance: pursuitDistance ?? this.pursuitDistance,
    dodgeTrajectory: dodgeTrajectory ?? this.dodgeTrajectory,
    recoveryDuration: recoveryDuration ?? this.recoveryDuration,
    pullStrength: pullStrength ?? this.pullStrength,
    slowStrength: slowStrength ?? this.slowStrength,
    internalInjuryStrength:
        internalInjuryStrength ?? this.internalInjuryStrength,
    controlDuration: controlDuration ?? this.controlDuration,
  );
}

ModifierValues applyCombatModifiers(
  ModifierValues base,
  ModifierBounds bounds,
  Iterable<CombatModifier> modifiers,
) {
  var result = base;
  for (final modifier in modifiers) {
    result = modifier.applyTo(result);
  }
  return ModifierValues(
    knockback: _cap(result.knockback, bounds.knockback),
    postureDamage: _cap(result.postureDamage, bounds.postureDamage),
    breachPower: _cap(result.breachPower, bounds.breachPower),
    pursuitDistance: _cap(result.pursuitDistance, bounds.pursuitDistance),
    dodgeTrajectory: _cap(result.dodgeTrajectory, bounds.dodgeTrajectory),
    recoveryDuration: _cap(result.recoveryDuration, bounds.recoveryDuration),
    pullStrength: _cap(result.pullStrength, bounds.pullStrength),
    slowStrength: _cap(result.slowStrength, bounds.slowStrength),
    internalInjuryStrength: _cap(
      result.internalInjuryStrength,
      bounds.internalInjuryStrength,
    ),
    controlDuration: _cap(result.controlDuration, bounds.controlDuration),
  );
}

double _cap(double value, double bound) => value > bound ? bound : value;

void _requirePositiveFactor(double value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'must be finite and positive');
  }
}

void _validateFields(Map<String, double> fields) {
  for (final entry in fields.entries) {
    final value = entry.value;
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        entry.key,
        'must be finite and non-negative',
      );
    }
  }
}
