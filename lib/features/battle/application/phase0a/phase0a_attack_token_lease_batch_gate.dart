import '../../domain/phase0a/attack_token_lease_runtime.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';

/// Caller-declared enemy-intent subsequence and lease lifecycle mutations for
/// one candidate combat tick.
///
/// Both iterables are fully materialized and frozen at construction time. The
/// plan does not infer action identity or lease lifecycle from the intents.
final class Phase0aAttackTokenLeaseBatchPlan {
  Phase0aAttackTokenLeaseBatchPlan({
    required Iterable<Phase0aIntent> enemyIntents,
    required Iterable<AttackTokenLeaseMutation> mutations,
  }) : enemyIntents = List<Phase0aIntent>.unmodifiable(enemyIntents),
       mutations = List<AttackTokenLeaseMutation>.unmodifiable(mutations);

  final List<Phase0aIntent> enemyIntents;
  final List<AttackTokenLeaseMutation> mutations;
}

/// Explicit caller policy for one transactional lease batch.
///
/// The snapshot and enemy-intent list are immutable inputs. The planner owns
/// every lease ID, request fact and acquire/release declaration.
typedef Phase0aAttackTokenLeaseBatchPlanner =
    Phase0aAttackTokenLeaseBatchPlan Function({
      required AttackTokenLeaseSnapshot leaseSnapshot,
      required List<Phase0aIntent> enemyIntents,
    });

/// Prepares one enemy-intent batch and its immutable lease successor without
/// publishing either to a combat session.
abstract interface class Phase0aAttackTokenLeaseBatchGate {
  Phase0aPreparedAttackTokenLeaseBatch prepare({
    required AttackTokenLeaseRuntime runtime,
    required List<Phase0aIntent> enemyIntents,
  });
}

/// Fully materialized batch bound to one exact lease-runtime predecessor.
final class Phase0aPreparedAttackTokenLeaseBatch {
  Phase0aPreparedAttackTokenLeaseBatch._({
    required AttackTokenLeaseRuntime predecessor,
    required this.enemyIntents,
    required this.mutations,
    required AttackTokenLeasePreparedSuccessor? leaseSuccessor,
  }) : _predecessor = predecessor,
       _leaseSuccessor = leaseSuccessor;

  final AttackTokenLeaseRuntime _predecessor;
  final AttackTokenLeasePreparedSuccessor? _leaseSuccessor;
  final List<Phase0aIntent> enemyIntents;
  final List<AttackTokenLeaseMutation> mutations;
  bool _committed = false;

  /// Consumes this prepared value once. Empty mutations return the exact
  /// predecessor so a no-op batch does not create a revision or owner fork.
  AttackTokenLeaseRuntime commit(AttackTokenLeaseRuntime predecessor) {
    if (!identical(predecessor, _predecessor)) {
      throw StateError(
        'Prepared attack-token lease batch has another predecessor',
      );
    }
    if (_committed) {
      throw StateError(
        'Prepared attack-token lease batch was already committed',
      );
    }

    final leaseSuccessor = _leaseSuccessor;
    final next = leaseSuccessor == null
        ? predecessor
        : predecessor.commit(leaseSuccessor);
    _committed = true;
    return next;
  }
}

/// Host-neutral gate driven only by an explicit caller planner.
final class Phase0aExplicitAttackTokenLeaseBatchGate
    implements Phase0aAttackTokenLeaseBatchGate {
  const Phase0aExplicitAttackTokenLeaseBatchGate({required this.planner});

  final Phase0aAttackTokenLeaseBatchPlanner planner;

  @override
  Phase0aPreparedAttackTokenLeaseBatch prepare({
    required AttackTokenLeaseRuntime runtime,
    required List<Phase0aIntent> enemyIntents,
  }) {
    final input = List<Phase0aIntent>.unmodifiable(
      List<Phase0aIntent>.of(enemyIntents),
    );
    final plan = planner(leaseSnapshot: runtime.snapshot, enemyIntents: input);
    final mutations = plan.mutations;
    final leaseSuccessor = mutations.isEmpty
        ? null
        : runtime.prepare(mutations);
    return Phase0aPreparedAttackTokenLeaseBatch._(
      predecessor: runtime,
      enemyIntents: plan.enemyIntents,
      mutations: mutations,
      leaseSuccessor: leaseSuccessor,
    );
  }
}
