/// Read-only objective progress; pending reinforcements remain enemies.
final class Phase0aCheckpointObjectiveObservation {
  Phase0aCheckpointObjectiveObservation({
    required Map<String, bool> checkpoints,
    required this.remainingEnemies,
  }) : checkpoints = Map.unmodifiable(checkpoints);

  final Map<String, bool> checkpoints;
  final int remainingEnemies;

  bool get reached => checkpoints.values.every((value) => value);
}

abstract interface class Phase0aCheckpointObjectiveObservationSource {
  Phase0aCheckpointObjectiveObservation? get checkpointObjectiveObservation;
}
