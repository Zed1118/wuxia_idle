// Pure, unconnected candidate for the M1 defense-resolution contract.

enum DefenseBranch {
  dodge,
  parry,
  redirect,
  blockOrShield,
  baseMitigation,
  hit,
}

/// Optional exceptions for standardized counter damage.
///
/// The empty set is intentional: counters never inherit critical, lifesteal,
/// or on-hit reflect behavior unless a typed ability explicitly opts in.
enum CounterEffect { critical, lifesteal, onHitReflect }

final class CounterEffectAllowlist {
  const CounterEffectAllowlist({this.effects = const <CounterEffect>{}});

  final Set<CounterEffect> effects;

  bool contains(CounterEffect effect) => effects.contains(effect);

  @override
  bool operator ==(Object other) =>
      other is CounterEffectAllowlist &&
      other.effects.length == effects.length &&
      other.effects.containsAll(effects);

  @override
  int get hashCode => Object.hashAll(effects);
}

final class AttackDefenseFlags {
  AttackDefenseFlags({
    required this.blockable,
    required this.parryable,
    required this.reflectable,
    required this.dodgeable,
    required this.interruptible,
  });

  factory AttackDefenseFlags.checked({
    required bool blockable,
    required bool parryable,
    required bool reflectable,
    required bool dodgeable,
    required bool interruptible,
  }) {
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
    this.counterPerSecondUpperBound,
    this.counterEffectAllowlist = const CounterEffectAllowlist(),
  }) {
    _requireFiniteNonNegative(incomingHpDamage, 'incomingHpDamage');
    _requireFiniteNonNegative(incomingPostureDamage, 'incomingPostureDamage');
    _requireFiniteNonNegative(shieldAbsorption, 'shieldAbsorption');
    _requireFiniteNonNegative(blockDamageMultiplier, 'blockDamageMultiplier');
    _requireUnitFraction(baseMitigationFraction, 'baseMitigationFraction');
    _requireFiniteNonNegative(counterDamage, 'counterDamage');
    _requireFiniteNonNegative(counterUpperBound, 'counterUpperBound');
    if (counterPerSecondUpperBound != null) {
      _requireFiniteNonNegative(
        counterPerSecondUpperBound!,
        'counterPerSecondUpperBound',
      );
    }
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
  final double? counterPerSecondUpperBound;
  final CounterEffectAllowlist counterEffectAllowlist;

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
      other.counterUpperBound == counterUpperBound &&
      other.counterPerSecondUpperBound == counterPerSecondUpperBound &&
      other.counterEffectAllowlist == counterEffectAllowlist;

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
    counterPerSecondUpperBound,
    counterEffectAllowlist,
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
    required this.projectileRedirect,
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

  /// True only for the projectile ownership/target redirect branch.
  /// It is deliberately separate from [counterDamage].
  final bool projectileRedirect;

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
      other.canTriggerOnHitReflect == canTriggerOnHitReflect &&
      other.projectileRedirect == projectileRedirect;

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
    projectileRedirect,
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
      projectileRedirect: true,
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
    hpDamage = _safeScale(hpDamage, input.blockDamageMultiplier);
    postureDamage = _safeScale(postureDamage, input.blockDamageMultiplier);
  }
  final afterShield = hpDamage - input.shieldAbsorption;
  hpDamage = afterShield > 0 ? afterShield : 0;
  final mitigationMultiplier = 1 - input.baseMitigationFraction;
  hpDamage = _safeScale(hpDamage, mitigationMultiplier);
  postureDamage = _safeScale(postureDamage, mitigationMultiplier);
  final counter = usesBlockOrShield ? _boundedCounter(input) : 0.0;
  return DefenseResult(
    branch: branch,
    incomingHpDamage: hpDamage,
    incomingPostureDamage: postureDamage,
    counterDamage: counter,
    wasRedirected: false,
    nonRecursive: true,
    canCrit:
        usesBlockOrShield &&
        input.counterEffectAllowlist.contains(CounterEffect.critical),
    canLifesteal:
        usesBlockOrShield &&
        input.counterEffectAllowlist.contains(CounterEffect.lifesteal),
    canTriggerOnHitReflect:
        usesBlockOrShield &&
        input.counterEffectAllowlist.contains(CounterEffect.onHitReflect),
    projectileRedirect: false,
  );
}

DefenseResult _counterResult(DefenseInput input, DefenseBranch branch) {
  return DefenseResult(
    branch: branch,
    incomingHpDamage: 0,
    incomingPostureDamage: 0,
    counterDamage: _boundedCounter(input),
    wasRedirected: false,
    nonRecursive: true,
    canCrit: input.counterEffectAllowlist.contains(CounterEffect.critical),
    canLifesteal: input.counterEffectAllowlist.contains(
      CounterEffect.lifesteal,
    ),
    canTriggerOnHitReflect: input.counterEffectAllowlist.contains(
      CounterEffect.onHitReflect,
    ),
    projectileRedirect: false,
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
  projectileRedirect: false,
);

double _boundedCounter(DefenseInput input) {
  var upperBound = input.counterUpperBound;
  final perSecond = input.counterPerSecondUpperBound;
  if (perSecond != null && perSecond < upperBound) upperBound = perSecond;
  return _safeScale(
    input.counterDamage < upperBound ? input.counterDamage : upperBound,
    1,
  );
}

double _safeScale(double value, double multiplier) {
  final scaled = value * multiplier;
  if (!scaled.isFinite) return double.maxFinite;
  return scaled < 0 ? 0 : scaled;
}

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
