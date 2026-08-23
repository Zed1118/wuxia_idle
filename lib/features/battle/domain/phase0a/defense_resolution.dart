// Pure, unconnected candidate for the M1 defense-resolution contract.

enum DefenseBranch {
  dodge,
  parry,
  redirect,
  blockOrShield,
  baseMitigation,
  hit,
}

final class AttackDefenseFlags {
  AttackDefenseFlags({
    required this.blockable,
    required this.parryable,
    required this.reflectable,
    required this.dodgeable,
    required this.interruptible,
  }) {
    if (!blockable && parryable) {
      throw ArgumentError.value(parryable, 'parryable', 'requires blockable');
    }
  }

  factory AttackDefenseFlags.checked({
    required bool blockable,
    required bool parryable,
    required bool reflectable,
    required bool dodgeable,
    required bool interruptible,
  }) {
    if (!blockable && parryable) {
      throw ArgumentError.value(parryable, 'parryable', 'requires blockable');
    }
    return AttackDefenseFlags(
      blockable: blockable,
      parryable: parryable,
      reflectable: reflectable,
      dodgeable: dodgeable,
      interruptible: interruptible,
    );
  }

  final bool blockable;
  final bool parryable;
  final bool reflectable;
  final bool dodgeable;
  final bool interruptible;

  bool get isUnblockable => !blockable && !parryable;

  @override
  bool operator ==(Object other) =>
      other is AttackDefenseFlags &&
      other.blockable == blockable &&
      other.parryable == parryable &&
      other.reflectable == reflectable &&
      other.dodgeable == dodgeable &&
      other.interruptible == interruptible;

  @override
  int get hashCode =>
      Object.hash(blockable, parryable, reflectable, dodgeable, interruptible);
}

final class DefenseInput {
  DefenseInput({
    required this.flags,
    required this.incomingHpDamage,
    required this.incomingPostureDamage,
    required this.dodgeSucceeded,
    required this.parrySucceeded,
    required this.redirectSucceeded,
    required this.blockSucceeded,
    required this.shieldAbsorption,
    required this.blockDamageMultiplier,
    required this.baseMitigationFraction,
    required this.counterDamage,
    required this.counterUpperBound,
  }) {
    _requireFiniteNonNegative(incomingHpDamage, 'incomingHpDamage');
    _requireFiniteNonNegative(incomingPostureDamage, 'incomingPostureDamage');
    _requireFiniteNonNegative(shieldAbsorption, 'shieldAbsorption');
    _requireFiniteNonNegative(blockDamageMultiplier, 'blockDamageMultiplier');
    _requireUnitFraction(baseMitigationFraction, 'baseMitigationFraction');
    _requireFiniteNonNegative(counterDamage, 'counterDamage');
    _requireFiniteNonNegative(counterUpperBound, 'counterUpperBound');
  }

  final AttackDefenseFlags flags;
  final double incomingHpDamage;
  final double incomingPostureDamage;
  final bool dodgeSucceeded;
  final bool parrySucceeded;
  final bool redirectSucceeded;
  final bool blockSucceeded;
  final double shieldAbsorption;
  final double blockDamageMultiplier;
  final double baseMitigationFraction;
  final double counterDamage;
  final double counterUpperBound;

  @override
  bool operator ==(Object other) =>
      other is DefenseInput &&
      other.flags == flags &&
      other.incomingHpDamage == incomingHpDamage &&
      other.incomingPostureDamage == incomingPostureDamage &&
      other.dodgeSucceeded == dodgeSucceeded &&
      other.parrySucceeded == parrySucceeded &&
      other.redirectSucceeded == redirectSucceeded &&
      other.blockSucceeded == blockSucceeded &&
      other.shieldAbsorption == shieldAbsorption &&
      other.blockDamageMultiplier == blockDamageMultiplier &&
      other.baseMitigationFraction == baseMitigationFraction &&
      other.counterDamage == counterDamage &&
      other.counterUpperBound == counterUpperBound;

  @override
  int get hashCode => Object.hashAll([
    flags,
    incomingHpDamage,
    incomingPostureDamage,
    dodgeSucceeded,
    parrySucceeded,
    redirectSucceeded,
    blockSucceeded,
    shieldAbsorption,
    blockDamageMultiplier,
    baseMitigationFraction,
    counterDamage,
    counterUpperBound,
  ]);
}

final class DefenseResult {
  const DefenseResult({
    required this.branch,
    required this.incomingHpDamage,
    required this.incomingPostureDamage,
    required this.counterDamage,
    required this.wasRedirected,
    required this.nonRecursive,
    required this.canCrit,
    required this.canLifesteal,
    required this.canTriggerOnHitReflect,
  });

  final DefenseBranch branch;
  final double incomingHpDamage;
  final double incomingPostureDamage;
  final double counterDamage;
  final bool wasRedirected;
  final bool nonRecursive;
  final bool canCrit;
  final bool canLifesteal;
  final bool canTriggerOnHitReflect;

  @override
  bool operator ==(Object other) =>
      other is DefenseResult &&
      other.branch == branch &&
      other.incomingHpDamage == incomingHpDamage &&
      other.incomingPostureDamage == incomingPostureDamage &&
      other.counterDamage == counterDamage &&
      other.wasRedirected == wasRedirected &&
      other.nonRecursive == nonRecursive &&
      other.canCrit == canCrit &&
      other.canLifesteal == canLifesteal &&
      other.canTriggerOnHitReflect == canTriggerOnHitReflect;

  @override
  int get hashCode => Object.hash(
    branch,
    incomingHpDamage,
    incomingPostureDamage,
    counterDamage,
    wasRedirected,
    nonRecursive,
    canCrit,
    canLifesteal,
    canTriggerOnHitReflect,
  );
}

DefenseResult resolveDefense(DefenseInput input) {
  final flags = input.flags;
  if (input.dodgeSucceeded && flags.dodgeable) {
    return _zeroResult(DefenseBranch.dodge);
  }
  if (input.parrySucceeded && flags.parryable) {
    return _counterResult(input, DefenseBranch.parry);
  }
  if (input.redirectSucceeded && flags.reflectable) {
    return const DefenseResult(
      branch: DefenseBranch.redirect,
      incomingHpDamage: 0,
      incomingPostureDamage: 0,
      counterDamage: 0,
      wasRedirected: true,
      nonRecursive: true,
      canCrit: false,
      canLifesteal: false,
      canTriggerOnHitReflect: false,
    );
  }

  final usesBlockOrShield =
      (input.blockSucceeded && flags.blockable) || input.shieldAbsorption > 0;
  final branch = usesBlockOrShield
      ? DefenseBranch.blockOrShield
      : DefenseBranch.baseMitigation;
  var hpDamage = input.incomingHpDamage;
  var postureDamage = input.incomingPostureDamage;
  if (input.blockSucceeded && flags.blockable) {
    hpDamage *= input.blockDamageMultiplier;
    postureDamage *= input.blockDamageMultiplier;
  }
  final afterShield = hpDamage - input.shieldAbsorption;
  hpDamage = afterShield > 0 ? afterShield : 0;
  final mitigationMultiplier = 1 - input.baseMitigationFraction;
  hpDamage *= mitigationMultiplier;
  postureDamage *= mitigationMultiplier;
  final counter = usesBlockOrShield
      ? _boundedCounter(input.counterDamage, input.counterUpperBound)
      : 0.0;
  return DefenseResult(
    branch: branch,
    incomingHpDamage: hpDamage,
    incomingPostureDamage: postureDamage,
    counterDamage: counter,
    wasRedirected: false,
    nonRecursive: true,
    canCrit: false,
    canLifesteal: false,
    canTriggerOnHitReflect: false,
  );
}

DefenseResult _counterResult(DefenseInput input, DefenseBranch branch) {
  return DefenseResult(
    branch: branch,
    incomingHpDamage: 0,
    incomingPostureDamage: 0,
    counterDamage: _boundedCounter(
      input.counterDamage,
      input.counterUpperBound,
    ),
    wasRedirected: false,
    nonRecursive: true,
    canCrit: false,
    canLifesteal: false,
    canTriggerOnHitReflect: false,
  );
}

DefenseResult _zeroResult(DefenseBranch branch) => DefenseResult(
  branch: branch,
  incomingHpDamage: 0,
  incomingPostureDamage: 0,
  counterDamage: 0,
  wasRedirected: false,
  nonRecursive: true,
  canCrit: false,
  canLifesteal: false,
  canTriggerOnHitReflect: false,
);

double _boundedCounter(double damage, double upperBound) =>
    damage < upperBound ? damage : upperBound;

void _requireFiniteNonNegative(double value, String name) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(value, name, 'must be finite and non-negative');
  }
}

void _requireUnitFraction(double value, String name) {
  _requireFiniteNonNegative(value, name);
  if (value > 1) {
    throw ArgumentError.value(value, name, 'must be between zero and one');
  }
}
