/// Status kinds accepted by the Phase 0A fixed-tick candidate.
enum TimedStatusType { slow, root, internalInjury, poison }

/// Caller-supplied definition for one timed status source.
///
/// This is deliberately engine-neutral: it carries no scheduler, reducer, UI,
/// or data-loader dependency. Balance values (duration, cadence, movement and
/// damage) must be supplied by the caller.
final class TimedStatusSpec {
  TimedStatusSpec({
    required this.type,
    required this.sourceId,
    required this.durationTicks,
    required this.tickIntervalTicks,
    required this.stackLimit,
    this.movementMultiplier,
    this.damagePerTick,
  }) {
    if (sourceId.isEmpty) {
      throw ArgumentError.value(sourceId, 'sourceId', 'must not be empty');
    }
    if (durationTicks <= 0) {
      throw ArgumentError.value(
        durationTicks,
        'durationTicks',
        'must be positive',
      );
    }
    if (tickIntervalTicks <= 0) {
      throw ArgumentError.value(
        tickIntervalTicks,
        'tickIntervalTicks',
        'must be positive',
      );
    }
    if (stackLimit <= 0) {
      throw ArgumentError.value(stackLimit, 'stackLimit', 'must be positive');
    }
    final tickDamage = damagePerTick;
    if (tickDamage != null && tickDamage < 0) {
      throw ArgumentError.value(
        tickDamage,
        'damagePerTick',
        'must not be negative',
      );
    }
    if (type == TimedStatusType.slow) {
      final multiplier = movementMultiplier;
      if (multiplier == null ||
          !multiplier.isFinite ||
          multiplier <= 0 ||
          multiplier > 1) {
        throw ArgumentError.value(
          multiplier,
          'movementMultiplier',
          'slow requires a multiplier in (0, 1]',
        );
      }
      if (damagePerTick != null) {
        throw ArgumentError('slow may only modify movement');
      }
    } else if (movementMultiplier != null) {
      throw ArgumentError('only slow may provide movementMultiplier');
    }
  }

  final TimedStatusType type;
  final String sourceId;
  final int durationTicks;
  final int tickIntervalTicks;
  final int stackLimit;
  final double? movementMultiplier;
  final int? damagePerTick;
}

final class TimedStatusInstance {
  TimedStatusInstance._(TimedStatusSpec spec)
    : this._values(spec, spec.durationTicks, 0, 1);

  TimedStatusInstance._snapshot(TimedStatusInstance source)
    : this._values(
        source.spec,
        source.remainingTicks,
        source.elapsedTicks,
        source.stacks,
      );

  TimedStatusInstance._values(
    this.spec,
    this.remainingTicks,
    this.elapsedTicks,
    this.stacks,
  );

  TimedStatusSpec spec;
  int remainingTicks;
  int elapsedTicks;
  int stacks;

  String get sourceId => spec.sourceId;
  TimedStatusType get type => spec.type;
}

final class StatusDamage {
  const StatusDamage({
    required this.tick,
    required this.sourceId,
    required this.type,
    required this.amount,
  });

  final int tick;
  final String sourceId;
  final TimedStatusType type;
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is StatusDamage &&
      other.tick == tick &&
      other.sourceId == sourceId &&
      other.type == type &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(tick, sourceId, type, amount);
}

final class StatusAdvanceResult {
  const StatusAdvanceResult(this.damages);

  final List<StatusDamage> damages;
}

/// Deterministic mutable ledger for timed status instances.
///
/// One source refreshes by default. A source may stack only when both the
/// existing and incoming definitions explicitly provide a stack limit above
/// one. Tick processing happens in logical tick order, and emitted damage is
/// sorted by type then source ID for replay stability.
final class TimedStatusLedger {
  TimedStatusLedger._();

  static TimedStatusLedger get empty => TimedStatusLedger._();

  final List<TimedStatusInstance> _statuses = [];
  int _timelineTick = 0;

  /// Returns detached snapshots; mutating an item cannot mutate this ledger.
  List<TimedStatusInstance> get active =>
      List.unmodifiable(_sortedStatuses().map(TimedStatusInstance._snapshot));

  bool get blocksRegularMovement =>
      _statuses.any((status) => status.type == TimedStatusType.root);

  bool get allowsAttack => true;
  bool get allowsDefense => true;

  double get movementMultiplier => _statuses
      .where((status) => status.type == TimedStatusType.slow)
      .fold(1.0, (value, status) {
        var stackedValue = value;
        for (var stack = 0; stack < status.stacks; stack++) {
          stackedValue *= status.spec.movementMultiplier!;
        }
        return stackedValue;
      });

  void apply(TimedStatusSpec spec) {
    final existing = _statuses.cast<TimedStatusInstance?>().firstWhere(
      (status) => status!.type == spec.type && status.sourceId == spec.sourceId,
      orElse: () => null,
    );
    if (existing == null) {
      _statuses.add(TimedStatusInstance._(spec));
      return;
    }

    final mayStack = existing.spec.stackLimit > 1 && spec.stackLimit > 1;
    existing.spec = spec;
    existing.remainingTicks = spec.durationTicks;
    existing.elapsedTicks = 0;
    if (mayStack) {
      existing.stacks = existing.stacks < spec.stackLimit
          ? existing.stacks + 1
          : spec.stackLimit;
    } else {
      existing.stacks = 1;
    }
  }

  StatusAdvanceResult advance(int ticks) {
    if (ticks < 0) {
      throw ArgumentError.value(ticks, 'ticks', 'must not be negative');
    }
    final damages = <StatusDamage>[];
    for (var tick = 0; tick < ticks; tick++) {
      _timelineTick++;
      final expired = <TimedStatusInstance>[];
      for (final status in _sortedStatuses()) {
        status.elapsedTicks++;
        status.remainingTicks--;
        final interval = status.spec.tickIntervalTicks;
        final damage = status.spec.damagePerTick;
        if (damage != null && status.elapsedTicks % interval == 0) {
          damages.add(
            StatusDamage(
              tick: _timelineTick,
              sourceId: status.sourceId,
              type: status.type,
              amount: damage * status.stacks,
            ),
          );
        }
        if (status.remainingTicks <= 0) expired.add(status);
      }
      _statuses.removeWhere(expired.contains);
    }
    damages.sort(_compareDamage);
    return StatusAdvanceResult(List.unmodifiable(damages));
  }

  List<TimedStatusInstance> _sortedStatuses() =>
      [..._statuses]..sort(_compareStatus);

  static int _compareStatus(TimedStatusInstance a, TimedStatusInstance b) {
    final byType = a.type.index.compareTo(b.type.index);
    return byType != 0 ? byType : a.sourceId.compareTo(b.sourceId);
  }

  static int _compareDamage(StatusDamage a, StatusDamage b) {
    final byTick = a.tick.compareTo(b.tick);
    if (byTick != 0) return byTick;
    final byType = a.type.index.compareTo(b.type.index);
    return byType != 0 ? byType : a.sourceId.compareTo(b.sourceId);
  }
}
