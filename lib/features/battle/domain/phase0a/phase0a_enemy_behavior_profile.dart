/// Per-actor behavior resolved by the production encounter binding.
///
/// The reducer does not resolve content ids or tuning. It only receives this
/// profile on the intent produced by the enemy adapter, while the adapter
/// turns the movement policy into the concrete direction for this tick.
enum Phase0aEnemyMovementPolicy {
  directAdvance,
  holdDistance,
  lateralFlank,
  guardedPosition,
}

enum Phase0aEnemyAttackPolicy {
  closeRange,
  rangedPressure,
  chargeAndReposition,
  supportPulse,
}

final class Phase0aEnemyBehaviorProfile {
  const Phase0aEnemyBehaviorProfile({
    required this.id,
    required this.movementPolicy,
    required this.attackPolicy,
  });

  final String id;
  final Phase0aEnemyMovementPolicy movementPolicy;

  /// Catalog provenance carried through intents; the current Phase0A adapter
  /// keeps skill selection on the existing resolved skill bindings.
  final Phase0aEnemyAttackPolicy attackPolicy;

  @override
  bool operator ==(Object other) =>
      other is Phase0aEnemyBehaviorProfile &&
      other.id == id &&
      other.movementPolicy == movementPolicy &&
      other.attackPolicy == attackPolicy;

  @override
  int get hashCode => Object.hash(id, movementPolicy, attackPolicy);
}
