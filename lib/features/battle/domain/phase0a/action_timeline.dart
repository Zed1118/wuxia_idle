/// Fixed-tick action lifecycle candidate. It deliberately knows nothing about
/// resources, damage, reducers, or presentation.
enum ActionTimelinePhase {
  idle,
  windup,
  active,
  recovery,
  completed,
  cancelled,
  interrupted,
  failed,
}

enum ActionTimelineEventType {
  started,
  phaseChanged,
  firstEffect,
  completed,
  cancelled,
  interrupted,
  failed,
}

enum ActionTimelineCooldownMarker { none, cancelled, interrupted, failed }

final class ActionTimelineConfig {
  ActionTimelineConfig({
    required this.windupTicks,
    required this.activeTicks,
    required this.recoveryTicks,
    required this.firstEffectTick,
    required this.cancelWindowStartTick,
    required this.cancelWindowEndTick,
    required this.interruptedCooldownTicks,
    required this.cancelledCooldownTicks,
    required this.failedCooldownTicks,
  }) {
    _requireNonNegative(windupTicks, 'windupTicks');
    if (activeTicks <= 0) {
      throw ArgumentError.value(activeTicks, 'activeTicks');
    }
    _requireNonNegative(recoveryTicks, 'recoveryTicks');
    _requireNonNegative(firstEffectTick, 'firstEffectTick');
    final activeEnd = windupTicks + activeTicks;
    if (firstEffectTick < windupTicks || firstEffectTick >= activeEnd) {
      throw ArgumentError.value(firstEffectTick, 'firstEffectTick');
    }
    _requireWindow(cancelWindowStartTick, cancelWindowEndTick);
    _requireNonNegative(interruptedCooldownTicks, 'interruptedCooldownTicks');
    _requireNonNegative(cancelledCooldownTicks, 'cancelledCooldownTicks');
    _requireNonNegative(failedCooldownTicks, 'failedCooldownTicks');
  }

  final int windupTicks;
  final int activeTicks;
  final int recoveryTicks;
  final int firstEffectTick;
  final int cancelWindowStartTick;
  final int cancelWindowEndTick;
  final int interruptedCooldownTicks;
  final int cancelledCooldownTicks;
  final int failedCooldownTicks;

  int get totalTicks => windupTicks + activeTicks + recoveryTicks;
}

final class ActionTimelineEvent {
  const ActionTimelineEvent(this.type, {required this.tick});

  final ActionTimelineEventType type;
  final int tick;
}

final class ActionTimeline {
  ActionTimeline(this.config);

  final ActionTimelineConfig config;
  ActionTimelinePhase phase = ActionTimelinePhase.idle;
  ActionTimelineCooldownMarker cooldownMarker =
      ActionTimelineCooldownMarker.none;
  int cooldownRemainingTicks = 0;

  int _nextTick = 0;
  bool _firstEffectEmitted = false;
  final List<ActionTimelineEvent> _pendingTerminalEvents = [];

  List<ActionTimelineEvent> start() {
    if (phase != ActionTimelinePhase.idle) return const [];
    phase = _phaseFor(_nextTick);
    return [
      const ActionTimelineEvent(ActionTimelineEventType.started, tick: 0),
    ];
  }

  List<ActionTimelineEvent> advance(int ticks) {
    if (ticks <= 0) throw ArgumentError.value(ticks, 'ticks');
    if (!_isRunning) return const [];

    final events = <ActionTimelineEvent>[];
    for (var index = 0; index < ticks && _isRunning; index++) {
      final tick = _nextTick++;
      final nextPhase = _phaseFor(tick);
      if (nextPhase != phase) {
        phase = nextPhase;
        events.add(
          ActionTimelineEvent(ActionTimelineEventType.phaseChanged, tick: tick),
        );
      }
      if (phase == ActionTimelinePhase.active &&
          tick == config.firstEffectTick &&
          !_firstEffectEmitted) {
        _firstEffectEmitted = true;
        events.add(
          ActionTimelineEvent(ActionTimelineEventType.firstEffect, tick: tick),
        );
      }
      if (tick + 1 >= config.totalTicks) {
        phase = ActionTimelinePhase.completed;
        events.add(
          ActionTimelineEvent(ActionTimelineEventType.completed, tick: tick),
        );
      }
    }
    return events;
  }

  bool cancel() {
    if (!_isRunning || !_inCancelWindow) return false;
    phase = ActionTimelinePhase.cancelled;
    cooldownMarker = ActionTimelineCooldownMarker.cancelled;
    cooldownRemainingTicks = config.cancelledCooldownTicks;
    _pendingTerminalEvents.add(
      ActionTimelineEvent(ActionTimelineEventType.cancelled, tick: _nextTick),
    );
    return true;
  }

  bool interrupt() => _terminate(
    ActionTimelinePhase.interrupted,
    ActionTimelineCooldownMarker.interrupted,
    config.interruptedCooldownTicks,
  );

  bool fail() => _terminate(
    ActionTimelinePhase.failed,
    ActionTimelineCooldownMarker.failed,
    config.failedCooldownTicks,
  );

  bool get _isRunning =>
      phase == ActionTimelinePhase.windup ||
      phase == ActionTimelinePhase.active ||
      phase == ActionTimelinePhase.recovery;

  bool get _inCancelWindow =>
      _nextTick >= config.cancelWindowStartTick &&
      _nextTick <= config.cancelWindowEndTick;

  bool _terminate(
    ActionTimelinePhase terminalPhase,
    ActionTimelineCooldownMarker marker,
    int cooldown,
  ) {
    if (!_isRunning) return false;
    phase = terminalPhase;
    cooldownMarker = marker;
    cooldownRemainingTicks = cooldown;
    _pendingTerminalEvents.add(
      ActionTimelineEvent(switch (terminalPhase) {
        ActionTimelinePhase.interrupted => ActionTimelineEventType.interrupted,
        ActionTimelinePhase.failed => ActionTimelineEventType.failed,
        _ => throw StateError('unsupported terminal phase'),
      }, tick: _nextTick),
    );
    return true;
  }

  /// Returns terminal events emitted by cancel/interrupt/fail exactly once.
  List<ActionTimelineEvent> drainTerminalEvents() {
    final events = List<ActionTimelineEvent>.unmodifiable(
      _pendingTerminalEvents,
    );
    _pendingTerminalEvents.clear();
    return events;
  }

  ActionTimelinePhase _phaseFor(int tick) {
    if (tick < config.windupTicks) return ActionTimelinePhase.windup;
    if (tick < config.windupTicks + config.activeTicks) {
      return ActionTimelinePhase.active;
    }
    return ActionTimelinePhase.recovery;
  }
}

void _requireNonNegative(int value, String name) {
  if (value < 0) throw ArgumentError.value(value, name);
}

void _requireWindow(int start, int end) {
  _requireNonNegative(start, 'cancelWindowStartTick');
  _requireNonNegative(end, 'cancelWindowEndTick');
  if (start > end) {
    throw ArgumentError('cancel window start must not exceed end');
  }
}
