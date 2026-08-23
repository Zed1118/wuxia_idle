import '../../features/battle/domain/phase0a/encounter_objective.dart';
import '../defs/combat_encounter_def.dart';

/// Maps one immutable content reference to a new pure-domain objective.
///
/// [tickDuration] is always an explicit positive caller input. The mapper
/// defines no default tick and fails closed when converting `requiredTicks`
/// would overflow the platform's positive [Duration] range.
EncounterObjective mapCombatObjectivePrimitive(
  CombatObjectivePrimitiveRef reference, {
  required Duration tickDuration,
}) {
  if (tickDuration <= Duration.zero) {
    throw ArgumentError.value(tickDuration, 'tickDuration', 'must be positive');
  }

  return switch (reference) {
    CombatDefeatTargetsRef(:final targetIds) => DefeatTargetsObjective(
      targetIds,
    ),
    CombatDestroyAnchorsRef(:final anchorIds) => DestroyAnchorsObjective(
      anchorIds,
    ),
    CombatDefendEntityRef(:final entityId, :final requiredTicks) =>
      DefendEntityObjective(
        entityId,
        _durationForTicks(requiredTicks, tickDuration),
      ),
    CombatSurviveDurationRef(:final requiredTicks) => SurviveDurationObjective(
      _durationForTicks(requiredTicks, tickDuration),
    ),
    CombatReachCheckpointRef(:final checkpointIds) => ReachCheckpointObjective(
      checkpointIds,
    ),
    CombatTouchMarkersRef(:final markerIds) => TouchMarkersObjective(markerIds),
    CombatPursueTargetRef(:final targetId) => PursueTargetObjective(targetId),
    CombatDefeatCommanderRef(:final commanderId) => DefeatCommanderObjective(
      commanderId,
    ),
  };
}

Duration _durationForTicks(int requiredTicks, Duration tickDuration) {
  final microsecondsPerTick = tickDuration.inMicroseconds;
  final totalMicroseconds = microsecondsPerTick * requiredTicks;
  if (totalMicroseconds <= 0 ||
      totalMicroseconds ~/ requiredTicks != microsecondsPerTick) {
    throw ArgumentError.value(
      requiredTicks,
      'requiredTicks',
      'conversion overflows Duration',
    );
  }
  return Duration(microseconds: totalMicroseconds);
}
