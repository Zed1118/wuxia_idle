final class Phase0aSurviveObjectiveObservation {
  const Phase0aSurviveObjectiveObservation({
    required this.requiredDuration,
    required this.elapsed,
  });

  final Duration requiredDuration;
  final Duration elapsed;
}

abstract interface class Phase0aSurviveObjectiveObservationSource {
  Phase0aSurviveObjectiveObservation? get surviveObjectiveObservation;
}
