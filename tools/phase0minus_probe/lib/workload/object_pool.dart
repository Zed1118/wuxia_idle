abstract interface class PoolResettable {
  void resetForAcquire();
  void resetForRelease();
}

final class PoolCounters {
  int createdTotal = 0;
  int acquiredTotal = 0;
  int releasedTotal = 0;
  int reusedTotal = 0;
  int activeCurrent = 0;
  int activePeak = 0;
  int allocationAfterWarmup = 0;

  Map<String, int> toJson({required int freeCurrent}) => {
    'created_total': createdTotal,
    'acquired_total': acquiredTotal,
    'released_total': releasedTotal,
    'reused_total': reusedTotal,
    'active_current': activeCurrent,
    'active_peak': activePeak,
    'free_current': freeCurrent,
    'allocation_after_warmup': allocationAfterWarmup,
  };
}

final class ObjectPool<T extends PoolResettable> {
  ObjectPool(this._factory);

  final T Function() _factory;
  final List<T> _available = [];
  final Set<T> _active = Set<T>.identity();
  final PoolCounters counters = PoolCounters();
  bool warmupComplete = false;

  int get availableCount => _available.length;
  int get activeCount => _active.length;

  T acquire() {
    final T object;
    if (_available.isEmpty) {
      object = _factory();
      counters.createdTotal++;
      if (warmupComplete) counters.allocationAfterWarmup++;
    } else {
      object = _available.removeLast();
      counters.reusedTotal++;
    }
    if (!_active.add(object)) throw StateError('Object already active.');
    object.resetForAcquire();
    counters.acquiredTotal++;
    counters.activeCurrent = _active.length;
    if (counters.activeCurrent > counters.activePeak) {
      counters.activePeak = counters.activeCurrent;
    }
    return object;
  }

  void prewarm(int count) {
    final objects = <T>[];
    for (var index = 0; index < count; index++) {
      objects.add(acquire());
    }
    for (final object in objects) {
      release(object);
    }
  }

  void release(T object) {
    if (!_active.remove(object)) throw StateError('Duplicate pool release.');
    object.resetForRelease();
    _available.add(object);
    counters.releasedTotal++;
    counters.activeCurrent = _active.length;
  }

  bool get invariantHolds =>
      counters.createdTotal == activeCount + availableCount &&
      counters.activeCurrent == activeCount;
}
