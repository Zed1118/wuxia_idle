import '../../domain/phase0a/arena_vector.dart';

final class Phase0aDefendObjectiveObservation {
  const Phase0aDefendObjectiveObservation({
    required this.entityId,
    required this.position,
    required this.maxDurability,
    required this.currentDurability,
    required this.requiredDuration,
    required this.elapsed,
    required this.completed,
  });

  final String entityId;
  final ArenaVector position;
  final int maxDurability;
  final int currentDurability;
  final Duration requiredDuration;
  final Duration elapsed;
  final bool completed;

  bool get destroyed => currentDurability <= 0;
}

abstract interface class Phase0aDefendObjectiveObservationSource {
  Phase0aDefendObjectiveObservation? get defendObjectiveObservation;
}
