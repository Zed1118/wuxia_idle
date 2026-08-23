// Pure domain contract for the P2-G2-D02 attack token director.
//
// Separates "how many enemies are present" from "how many may attack at
// once". The director grants at most the caller-supplied per-kind budgets
// (melee / ranged / charge / support) and enforces fail-closed fairness
// gates. It performs no damage, holds no cross-tick state and makes no
// assumption about the action lifecycle; token release and re-request are
// the caller's responsibility.

enum AttackTokenKind { melee, ranged, charge, support }

/// Typed denial reasons. Safety gates are evaluated before budgets so a
/// request that violates a fairness gate never reports budget exhaustion.
enum AttackTokenDenial {
  spawnGraceActive,
  telegraphIncomplete,
  offscreenHighImpact,
  unblockableAreaLimit,
  budgetExhausted,
}

/// Per-kind concurrent attack budgets. All four values are explicit caller
/// input; the contract defines no defaults (2-4 style values belong to
/// data/playtest configuration, never to Dart).
final class AttackTokenBudgets {
  AttackTokenBudgets({
    required this.melee,
    required this.ranged,
    required this.charge,
    required this.support,
  }) {
    _requireNonNegative(melee, 'melee');
    _requireNonNegative(ranged, 'ranged');
    _requireNonNegative(charge, 'charge');
    _requireNonNegative(support, 'support');
  }

  final int melee;
  final int ranged;
  final int charge;
  final int support;

  int forKind(AttackTokenKind kind) => switch (kind) {
    AttackTokenKind.melee => melee,
    AttackTokenKind.ranged => ranged,
    AttackTokenKind.charge => charge,
    AttackTokenKind.support => support,
  };

  @override
  bool operator ==(Object other) =>
      other is AttackTokenBudgets &&
      other.melee == melee &&
      other.ranged == ranged &&
      other.charge == charge &&
      other.support == support;

  @override
  int get hashCode => Object.hash(melee, ranged, charge, support);
}

/// One enemy's request to enter its attack. Every field is required and
/// validated at construction; invalid input fails closed with [ArgumentError].
final class AttackTokenRequest {
  AttackTokenRequest({
    required String actorId,
    required this.kind,
    required this.priority,
    required this.isOffscreen,
    required this.isHighImpact,
    required this.isUnblockableArea,
    required this.spawnGraceTicksRemaining,
    required this.telegraphReady,
  }) : actorId = _canonicalId(actorId, 'actorId') {
    _requireNonNegative(priority, 'priority');
    _requireNonNegative(spawnGraceTicksRemaining, 'spawnGraceTicksRemaining');
  }

  final String actorId;
  final AttackTokenKind kind;

  /// Higher priority is considered first. Ties break by [actorId] ascending.
  final int priority;
  final bool isOffscreen;

  /// Would directly cause heavy damage, a grab, or major posture damage.
  final bool isHighImpact;

  /// Unblockable large-area attack; at most one may be granted per batch.
  final bool isUnblockableArea;

  /// Ticks of post-spawn readability grace still remaining. Any positive
  /// value denies the request.
  final int spawnGraceTicksRemaining;

  /// False until the telegraph/windup has fully played out.
  final bool telegraphReady;

  @override
  bool operator ==(Object other) =>
      other is AttackTokenRequest &&
      other.actorId == actorId &&
      other.kind == kind &&
      other.priority == priority &&
      other.isOffscreen == isOffscreen &&
      other.isHighImpact == isHighImpact &&
      other.isUnblockableArea == isUnblockableArea &&
      other.spawnGraceTicksRemaining == spawnGraceTicksRemaining &&
      other.telegraphReady == telegraphReady;

  @override
  int get hashCode => Object.hash(
    actorId,
    kind,
    priority,
    isOffscreen,
    isHighImpact,
    isUnblockableArea,
    spawnGraceTicksRemaining,
    telegraphReady,
  );
}

/// Immutable outcome for one actor.
final class AttackTokenDecision {
  const AttackTokenDecision._({
    required this.actorId,
    required this.kind,
    required this.granted,
    this.denial,
  });

  final String actorId;
  final AttackTokenKind kind;
  final bool granted;

  /// Non-null exactly when [granted] is false.
  final AttackTokenDenial? denial;

  @override
  bool operator ==(Object other) =>
      other is AttackTokenDecision &&
      other.actorId == actorId &&
      other.kind == kind &&
      other.granted == granted &&
      other.denial == denial;

  @override
  int get hashCode => Object.hash(actorId, kind, granted, denial);
}

/// Immutable batch result. Decisions are emitted in deterministic candidate
/// order (priority descending, actorId ascending), independent of input order.
final class AttackTokenAllocation {
  AttackTokenAllocation._(List<AttackTokenDecision> decisions)
    : decisions = List.unmodifiable(decisions);

  final List<AttackTokenDecision> decisions;

  int get grantedCount {
    var count = 0;
    for (final decision in decisions) {
      if (decision.granted) count++;
    }
    return count;
  }

  List<String> get grantedActorIds => List.unmodifiable(
    decisions.where((d) => d.granted).map((d) => d.actorId),
  );
}

/// Stateless, deterministic attack-token allocator for one batch of requests.
final class AttackTokenDirector {
  const AttackTokenDirector();

  /// Safety invariant: at most one unblockable large-area attack may be
  /// granted per batch, regardless of kind budgets. Stacking beyond one is a
  /// Boss-specific explicit mechanism requiring human readability review and
  /// is intentionally not representable here.
  static const int maxUnblockableAreaGrantsPerBatch = 1;

  AttackTokenAllocation allocate({
    required AttackTokenBudgets budgets,
    required List<AttackTokenRequest> requests,
  }) {
    final candidates = List<AttackTokenRequest>.unmodifiable(requests);
    final seen = <String>{};
    for (final request in candidates) {
      if (!seen.add(request.actorId)) {
        throw ArgumentError.value(
          request.actorId,
          'requests',
          'duplicate actorId in a single batch fails closed',
        );
      }
    }

    final ordered = [...candidates]
      ..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) return byPriority;
        return a.actorId.compareTo(b.actorId);
      });

    final remaining = {
      for (final kind in AttackTokenKind.values) kind: budgets.forKind(kind),
    };
    var unblockableGrants = 0;
    final decisions = <AttackTokenDecision>[];

    for (final request in ordered) {
      final denial = _denialFor(request, remaining, unblockableGrants);
      if (denial != null) {
        decisions.add(
          AttackTokenDecision._(
            actorId: request.actorId,
            kind: request.kind,
            granted: false,
            denial: denial,
          ),
        );
        continue;
      }
      remaining[request.kind] = remaining[request.kind]! - 1;
      if (request.isUnblockableArea) unblockableGrants++;
      decisions.add(
        AttackTokenDecision._(
          actorId: request.actorId,
          kind: request.kind,
          granted: true,
        ),
      );
    }

    return AttackTokenAllocation._(decisions);
  }

  AttackTokenDenial? _denialFor(
    AttackTokenRequest request,
    Map<AttackTokenKind, int> remaining,
    int unblockableGrants,
  ) {
    if (request.spawnGraceTicksRemaining > 0) {
      return AttackTokenDenial.spawnGraceActive;
    }
    if (!request.telegraphReady) {
      return AttackTokenDenial.telegraphIncomplete;
    }
    if (request.isOffscreen && request.isHighImpact) {
      return AttackTokenDenial.offscreenHighImpact;
    }
    if (request.isUnblockableArea &&
        unblockableGrants >= maxUnblockableAreaGrantsPerBatch) {
      return AttackTokenDenial.unblockableAreaLimit;
    }
    if (remaining[request.kind]! <= 0) {
      return AttackTokenDenial.budgetExhausted;
    }
    return null;
  }
}

void _requireNonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must be non-negative');
  }
}

String _canonicalId(String value, String name) {
  final canonical = value.trim();
  if (canonical.isEmpty || canonical != value) {
    throw ArgumentError.value(
      value,
      name,
      'must be a trimmed non-empty ID',
    );
  }
  return canonical;
}
