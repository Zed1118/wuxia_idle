enum ProgressiveUnlockId {
  tower,
  lightFoot,
  discipleScheduling,
  massBattle,
  expedition,
  gauntlet,
  innerDemon,
}

enum ProgressiveUnlockState { hidden, heard, open }

ProgressiveUnlockState resolveProgressiveUnlockState({
  required bool visible,
  required bool enabled,
}) {
  if (!visible && enabled) {
    throw StateError('An enabled progressive unlock route must be visible');
  }
  if (!visible) return ProgressiveUnlockState.hidden;
  return enabled ? ProgressiveUnlockState.open : ProgressiveUnlockState.heard;
}

class ProgressiveUnlockSnapshot {
  ProgressiveUnlockSnapshot(
    Map<ProgressiveUnlockId, ProgressiveUnlockState> states,
  ) : states = Map.unmodifiable(Map.of(states)) {
    final expected = ProgressiveUnlockId.values.toSet();
    if (this.states.length != expected.length ||
        !this.states.keys.toSet().containsAll(expected)) {
      throw ArgumentError.value(
        states,
        'states',
        'must contain every progressive unlock id exactly once',
      );
    }
  }

  final Map<ProgressiveUnlockId, ProgressiveUnlockState> states;

  ProgressiveUnlockState operator [](ProgressiveUnlockId id) => states[id]!;
}
