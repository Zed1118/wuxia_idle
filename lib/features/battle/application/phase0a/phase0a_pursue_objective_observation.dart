final class Phase0aPursueObjectiveObservation {
  const Phase0aPursueObjectiveObservation({
    required this.targetId,
    required this.targetActorId,
    required this.distance,
    required this.completed,
  });

  final String targetId;
  final String targetActorId;
  final double? distance;
  final bool completed;
}

abstract interface class Phase0aPursueObjectiveObservationSource {
  Phase0aPursueObjectiveObservation? get pursueObjectiveObservation;
}
