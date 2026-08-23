import 'attack_token_director.dart';

/// Stable caller identity for one attack-token lease.
final class AttackTokenLeaseId {
  AttackTokenLeaseId(String value) : value = _canonicalLeaseId(value, 'value');

  final String value;

  @override
  bool operator ==(Object other) =>
      other is AttackTokenLeaseId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AttackTokenLeaseId($value)';
}

/// One active lease and the exact request facts supplied by its caller.
final class AttackTokenLease {
  const AttackTokenLease({required this.id, required this.request});

  final AttackTokenLeaseId id;
  final AttackTokenRequest request;

  @override
  bool operator ==(Object other) =>
      other is AttackTokenLease && other.id == id && other.request == request;

  @override
  int get hashCode => Object.hash(id, request);
}

/// Explicit lifecycle input reduced in caller declaration order.
sealed class AttackTokenLeaseMutation {
  const AttackTokenLeaseMutation();
}

final class AcquireAttackTokenLease extends AttackTokenLeaseMutation {
  const AcquireAttackTokenLease(this.lease);

  final AttackTokenLease lease;
}

final class ReleaseAttackTokenLease extends AttackTokenLeaseMutation {
  const ReleaseAttackTokenLease(this.leaseId);

  final AttackTokenLeaseId leaseId;
}

/// Immutable revisioned view of active leases.
final class AttackTokenLeaseSnapshot {
  AttackTokenLeaseSnapshot._({
    required this.revision,
    required Map<AttackTokenLeaseId, AttackTokenLease> activeLeases,
  }) : activeLeases = Map.unmodifiable(
         Map<AttackTokenLeaseId, AttackTokenLease>.of(activeLeases),
       );

  final int revision;
  final Map<AttackTokenLeaseId, AttackTokenLease> activeLeases;
}

/// A fully validated successor bound to one exact predecessor runtime.
final class AttackTokenLeasePreparedSuccessor {
  AttackTokenLeasePreparedSuccessor._({
    required Object ownerToken,
    required AttackTokenLeaseRuntime predecessor,
    required this.base,
    required this.next,
    required List<AttackTokenLeaseMutation> mutations,
  }) : _ownerToken = ownerToken,
       _predecessor = predecessor,
       mutations = List.unmodifiable(mutations);

  final Object _ownerToken;
  final AttackTokenLeaseRuntime _predecessor;
  final AttackTokenLeaseSnapshot base;
  final AttackTokenLeaseSnapshot next;
  final List<AttackTokenLeaseMutation> mutations;
  bool _committed = false;
}

/// Immutable owner lineage for explicit attack-token lease transitions.
final class AttackTokenLeaseRuntime {
  AttackTokenLeaseRuntime._({
    required Object ownerToken,
    required this.snapshot,
  }) : _ownerToken = ownerToken;

  factory AttackTokenLeaseRuntime.empty() => AttackTokenLeaseRuntime._(
    ownerToken: Object(),
    snapshot: AttackTokenLeaseSnapshot._(revision: 0, activeLeases: const {}),
  );

  factory AttackTokenLeaseRuntime.restore({
    required int revision,
    required Map<AttackTokenLeaseId, AttackTokenLease> activeLeases,
  }) {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must be non-negative');
    }

    final copiedLeases = Map<AttackTokenLeaseId, AttackTokenLease>.of(
      activeLeases,
    );
    _validateRestoredLeases(copiedLeases);
    return AttackTokenLeaseRuntime._(
      ownerToken: Object(),
      snapshot: AttackTokenLeaseSnapshot._(
        revision: revision,
        activeLeases: copiedLeases,
      ),
    );
  }

  final Object _ownerToken;
  final AttackTokenLeaseSnapshot snapshot;

  /// Materializes and validates one ordered batch without changing this value.
  AttackTokenLeasePreparedSuccessor prepare(
    Iterable<AttackTokenLeaseMutation> mutations,
  ) {
    final input = List<AttackTokenLeaseMutation>.unmodifiable(mutations);
    final nextLeases = Map<AttackTokenLeaseId, AttackTokenLease>.of(
      snapshot.activeLeases,
    );
    final activeLeaseByActor = <String, AttackTokenLeaseId>{
      for (final lease in nextLeases.values) lease.request.actorId: lease.id,
    };

    for (final mutation in input) {
      switch (mutation) {
        case AcquireAttackTokenLease(:final lease):
          if (nextLeases.containsKey(lease.id)) {
            throw StateError('Attack-token lease ID is already active');
          }
          if (activeLeaseByActor.containsKey(lease.request.actorId)) {
            throw StateError('Attack-token actor already has an active lease');
          }
          nextLeases[lease.id] = lease;
          activeLeaseByActor[lease.request.actorId] = lease.id;
        case ReleaseAttackTokenLease(:final leaseId):
          final released = nextLeases.remove(leaseId);
          if (released == null) {
            throw StateError(
              'Attack-token release references an unknown lease',
            );
          }
          activeLeaseByActor.remove(released.request.actorId);
      }
    }

    final next = AttackTokenLeaseSnapshot._(
      revision: snapshot.revision + 1,
      activeLeases: nextLeases,
    );
    return AttackTokenLeasePreparedSuccessor._(
      ownerToken: _ownerToken,
      predecessor: this,
      base: snapshot,
      next: next,
      mutations: input,
    );
  }

  /// Consumes one owner-bound prepared value and returns its new runtime.
  AttackTokenLeaseRuntime commit(AttackTokenLeasePreparedSuccessor prepared) {
    if (!identical(prepared._ownerToken, _ownerToken)) {
      throw StateError('Prepared lease successor belongs to another owner');
    }
    if (!identical(prepared._predecessor, this)) {
      throw StateError('Prepared lease successor has another predecessor');
    }
    if (prepared._committed) {
      throw StateError('Prepared lease successor was already committed');
    }

    prepared._committed = true;
    return AttackTokenLeaseRuntime._(
      ownerToken: _ownerToken,
      snapshot: prepared.next,
    );
  }
}

void _validateRestoredLeases(
  Map<AttackTokenLeaseId, AttackTokenLease> activeLeases,
) {
  final activeActors = <String>{};
  for (final entry in activeLeases.entries) {
    if (entry.key != entry.value.id) {
      throw ArgumentError.value(
        entry.key,
        'activeLeases',
        'map key must match lease ID',
      );
    }
    if (!activeActors.add(entry.value.request.actorId)) {
      throw ArgumentError.value(
        entry.value.request.actorId,
        'activeLeases',
        'actor may have only one active lease',
      );
    }
  }
}

String _canonicalLeaseId(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be a non-empty canonical ID');
  }
  return value;
}
