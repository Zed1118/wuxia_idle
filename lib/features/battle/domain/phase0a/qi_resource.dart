/// Result of a reservation lifecycle operation.
enum QiReservationResult { committed, alreadyCommitted }

enum QiCancellationResult { releasedWithFailureCooldown, alreadyCancelled }

/// Result of a gain attempt. Overflow is deliberately observable so the
/// caller can emit a deterministic domain event instead of silently inflating
/// the resource.
final class QiGainResult {
  const QiGainResult({
    required this.applied,
    required this.overflow,
    required this.actionId,
  });

  const QiGainResult.alreadyApplied()
    : this(applied: 0, overflow: 0, actionId: null);

  final int applied;
  final int overflow;
  final String? actionId;

  bool get isAlreadyApplied => actionId == null;
}

final class QiReservation {
  const QiReservation({required this.actionId, required this.amount});

  final String actionId;
  final int amount;
}

enum _ReservationState { reserved, committed, cancelled }

final class _ReservationSnapshot {
  const _ReservationSnapshot(this.amount, this.state);
  final int amount;
  final _ReservationState state;
  @override
  bool operator ==(Object other) =>
      other is _ReservationSnapshot &&
      amount == other.amount &&
      state == other.state;
  @override
  int get hashCode => Object.hash(amount, state);
}

/// A value snapshot, never a mutable ledger shared between replay branches.
final class QiResourceLedgerSnapshot {
  QiResourceLedgerSnapshot._({
    required this.capacity,
    required this.current,
    required Map<String, _ReservationSnapshot> reservations,
    required Set<String> gainActionIds,
    required Map<String, int> windowGains,
  }) : _reservations = Map.unmodifiable(reservations),
       gainActionIds = Set.unmodifiable(gainActionIds),
       windowGains = Map.unmodifiable(windowGains);

  final int capacity;
  final int current;
  final Map<String, _ReservationSnapshot> _reservations;
  final Set<String> gainActionIds;
  final Map<String, int> windowGains;
  int get reserved => _reservations.values
      .where((r) => r.state == _ReservationState.reserved)
      .fold(0, (sum, r) => sum + r.amount);
  int get available => current - reserved;
  bool containsAction(String actionId) =>
      _reservations.containsKey(actionId) || gainActionIds.contains(actionId);

  /// Existing content recovery and drains still update the same qi balance.
  QiResourceLedgerSnapshot withCurrent(int value) {
    if (value < reserved || value > capacity) {
      throw StateError('qi balance outside spendable ledger bounds');
    }
    return QiResourceLedgerSnapshot._(
      capacity: capacity,
      current: value,
      reservations: _reservations,
      gainActionIds: gainActionIds,
      windowGains: windowGains,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QiResourceLedgerSnapshot &&
      capacity == other.capacity &&
      current == other.current &&
      _equalMap(_reservations, other._reservations) &&
      gainActionIds.length == other.gainActionIds.length &&
      gainActionIds.containsAll(other.gainActionIds) &&
      _equalMap(windowGains, other.windowGains);
  @override
  int get hashCode => Object.hash(
    capacity,
    current,
    Object.hashAllUnordered(
      _reservations.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(gainActionIds),
    Object.hashAllUnordered(
      windowGains.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

bool _equalMap<T>(Map<String, T> a, Map<String, T> b) =>
    a.length == b.length &&
    a.entries.every((e) => b.containsKey(e.key) && b[e.key] == e.value);

final class _ReservationRecord {
  _ReservationRecord(this.amount) : state = _ReservationState.reserved;

  final int amount;
  _ReservationState state;
}

/// Pure, caller-configured qi reservation ledger.
///
/// Reserving holds spendable qi without changing [current]. The caller commits
/// exactly once at the first effect tick, or cancels before that tick. Action
/// IDs are unique across reservations and gains, making multi-segment actions
/// unable to spend or gain more than once.
final class QiResourceLedger {
  QiResourceLedger({required this.capacity, required int current})
    : _current = current {
    if (capacity < 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must not be negative');
    }
    if (current < 0 || current > capacity) {
      throw ArgumentError.value(current, 'current', 'must be within capacity');
    }
  }

  QiResourceLedger.fromSnapshot(QiResourceLedgerSnapshot snapshot)
    : capacity = snapshot.capacity,
      _current = snapshot.current {
    for (final entry in snapshot._reservations.entries) {
      _reservations[entry.key] = _ReservationRecord(entry.value.amount)
        ..state = entry.value.state;
    }
    _gainActionIds.addAll(snapshot.gainActionIds);
    _windowGains.addAll(snapshot.windowGains);
  }

  QiResourceLedgerSnapshot get snapshot => QiResourceLedgerSnapshot._(
    capacity: capacity,
    current: current,
    reservations: {
      for (final e in _reservations.entries)
        e.key: _ReservationSnapshot(e.value.amount, e.value.state),
    },
    gainActionIds: _gainActionIds,
    windowGains: _windowGains,
  );

  final int capacity;
  int _current;
  final Map<String, _ReservationRecord> _reservations = {};
  final Set<String> _gainActionIds = {};
  final Map<String, int> _windowGains = {};

  int get current => _current;

  int get reserved => _reservations.values
      .where((record) => record.state == _ReservationState.reserved)
      .fold(0, (sum, record) => sum + record.amount);

  int get available => _current - reserved;

  QiReservation reserve({required String actionId, required int amount}) {
    _validateId(actionId);
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    if (_reservations.containsKey(actionId) ||
        _gainActionIds.contains(actionId)) {
      throw StateError('actionId already used: $actionId');
    }
    if (amount > available) {
      throw StateError('insufficient spendable qi for action: $actionId');
    }
    _reservations[actionId] = _ReservationRecord(amount);
    return QiReservation(actionId: actionId, amount: amount);
  }

  QiReservationResult commit(String actionId) {
    _validateId(actionId);
    final record = _reservations[actionId];
    if (record == null) throw StateError('unknown reservation: $actionId');
    switch (record.state) {
      case _ReservationState.reserved:
        _current -= record.amount;
        record.state = _ReservationState.committed;
        return QiReservationResult.committed;
      case _ReservationState.committed:
        return QiReservationResult.alreadyCommitted;
      case _ReservationState.cancelled:
        throw StateError('cancelled reservation cannot commit: $actionId');
    }
  }

  QiCancellationResult cancel(String actionId) {
    _validateId(actionId);
    final record = _reservations[actionId];
    if (record == null) throw StateError('unknown reservation: $actionId');
    switch (record.state) {
      case _ReservationState.reserved:
        record.state = _ReservationState.cancelled;
        return QiCancellationResult.releasedWithFailureCooldown;
      case _ReservationState.cancelled:
        return QiCancellationResult.alreadyCancelled;
      case _ReservationState.committed:
        throw StateError('committed reservation cannot cancel: $actionId');
    }
  }

  QiGainResult gainAction({required String actionId, required int amount}) {
    _validateGain(actionId, amount);
    if (_gainActionIds.contains(actionId)) {
      return const QiGainResult.alreadyApplied();
    }
    if (_reservations.containsKey(actionId)) {
      throw StateError('actionId already used by reservation: $actionId');
    }
    _gainActionIds.add(actionId);
    return _applyGain(actionId, amount);
  }

  QiGainResult gainKill({
    required String actionId,
    required String windowId,
    required int amount,
    required int windowCap,
  }) {
    _validateGain(actionId, amount);
    _validateId(windowId, name: 'windowId');
    if (windowCap < 0) {
      throw ArgumentError.value(windowCap, 'windowCap', 'must not be negative');
    }
    if (_gainActionIds.contains(actionId)) {
      return const QiGainResult.alreadyApplied();
    }
    if (_reservations.containsKey(actionId)) {
      throw StateError('actionId already used by reservation: $actionId');
    }
    _gainActionIds.add(actionId);
    final rawWindowRemaining = windowCap - (_windowGains[windowId] ?? 0);
    // Callers inject the cap. A later, lower cap must close the window rather
    // than turn the remaining budget negative and accidentally drain qi.
    final windowRemaining = rawWindowRemaining < 0 ? 0 : rawWindowRemaining;
    final allowed = amount < windowRemaining ? amount : windowRemaining;
    final result = _applyGain(actionId, allowed);
    _windowGains[windowId] = (_windowGains[windowId] ?? 0) + result.applied;
    return QiGainResult(
      actionId: actionId,
      applied: result.applied,
      overflow: result.overflow + (amount - allowed),
    );
  }

  QiGainResult _applyGain(String actionId, int amount) {
    final applied = amount < capacity - _current ? amount : capacity - _current;
    _current += applied;
    return QiGainResult(
      actionId: actionId,
      applied: applied,
      overflow: amount - applied,
    );
  }

  void _validateGain(String actionId, int amount) {
    _validateId(actionId);
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
  }

  void _validateId(String id, {String name = 'actionId'}) {
    if (id.isEmpty) throw ArgumentError.value(id, name, 'must not be empty');
  }
}
