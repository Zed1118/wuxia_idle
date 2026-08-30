import '../../domain/phase0a/arena_vector.dart';

/// Presentation-only interpolation for one actor's authoritative domain
/// position. Priority motions (currently the sword advancing slash) finish
/// before ordinary fixed-tick targets are consumed, so a following held move
/// cannot collapse the lunge back into a one-tick visual jump.
final class Phase0aActorRenderMotion {
  Phase0aActorRenderMotion(ArenaVector position)
    : current = position,
      _from = position,
      _target = position;

  ArenaVector current;
  ArenaVector _from;
  ArenaVector _target;
  double _elapsedSeconds = 0;
  double _durationSeconds = 0;
  bool _preserveUntilComplete = false;
  ArenaVector? _queuedTarget;
  double? _queuedDurationSeconds;

  void retarget(
    ArenaVector target, {
    required double durationSeconds,
    bool preserveUntilComplete = false,
  }) {
    _requireDuration(durationSeconds);
    final semanticTarget = _queuedTarget ?? _target;
    if (target == semanticTarget) return;
    if (_preserveUntilComplete &&
        current != _target &&
        !preserveUntilComplete) {
      _queuedTarget = target;
      _queuedDurationSeconds = durationSeconds;
      return;
    }
    _start(
      target,
      durationSeconds: durationSeconds,
      preserveUntilComplete: preserveUntilComplete,
    );
  }

  bool advance(double deltaSeconds) {
    if (!deltaSeconds.isFinite || deltaSeconds < 0) {
      throw ArgumentError.value(
        deltaSeconds,
        'deltaSeconds',
        'must be finite and non-negative',
      );
    }
    var remainingSeconds = deltaSeconds;
    var changed = false;
    while (true) {
      if (current == _target) {
        _preserveUntilComplete = false;
        final queuedTarget = _queuedTarget;
        final queuedDuration = _queuedDurationSeconds;
        if (queuedTarget != null && queuedDuration != null) {
          _queuedTarget = null;
          _queuedDurationSeconds = null;
          _start(
            queuedTarget,
            durationSeconds: queuedDuration,
            preserveUntilComplete: false,
          );
          if (remainingSeconds == 0) return changed;
          continue;
        }
        return changed;
      }
      if (remainingSeconds == 0) return changed;

      final durationRemaining = _durationSeconds - _elapsedSeconds;
      final stepSeconds = remainingSeconds < durationRemaining
          ? remainingSeconds
          : durationRemaining;
      _elapsedSeconds += stepSeconds;
      remainingSeconds -= stepSeconds;
      final progress = (_elapsedSeconds / _durationSeconds).clamp(0.0, 1.0);
      current = _from + (_target - _from) * progress;
      changed = true;
      if (_elapsedSeconds >= _durationSeconds) current = _target;
    }
  }

  void _start(
    ArenaVector target, {
    required double durationSeconds,
    required bool preserveUntilComplete,
  }) {
    _from = current;
    _target = target;
    _elapsedSeconds = 0;
    _durationSeconds = durationSeconds;
    _preserveUntilComplete = preserveUntilComplete;
    _queuedTarget = null;
    _queuedDurationSeconds = null;
  }

  static void _requireDuration(double durationSeconds) {
    if (!durationSeconds.isFinite || durationSeconds <= 0) {
      throw ArgumentError.value(
        durationSeconds,
        'durationSeconds',
        'must be finite and positive',
      );
    }
  }
}
