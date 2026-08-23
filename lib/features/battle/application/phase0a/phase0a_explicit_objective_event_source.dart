import '../../domain/phase0a/encounter_enemy_roster.dart';
import '../../domain/phase0a/encounter_objective.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import 'phase0a_encounter_objective_event_source.dart';

/// One explicit objective projection for an exact defeated runtime actor.
///
/// The actor identity belongs exclusively to the source map key. Concrete
/// projections carry only the caller-declared objective payload, so neither
/// runtime identity nor any content metadata is promoted into objective
/// meaning by this contract.
sealed class Phase0aDefeatObjectiveProjection {
  const Phase0aDefeatObjectiveProjection();
}

/// Emits one [TargetDefeated] with the exact caller-declared [targetId].
final class Phase0aTargetDefeatProjection
    extends Phase0aDefeatObjectiveProjection {
  const Phase0aTargetDefeatProjection(this.targetId);

  final String targetId;
}

/// Emits one [CommanderDefeated] with the exact caller-declared [commanderId].
final class Phase0aCommanderDefeatProjection
    extends Phase0aDefeatObjectiveProjection {
  const Phase0aCommanderDefeatProjection(this.commanderId);

  final String commanderId;
}

/// Explicit caller projection for the six non-defeat objective event kinds.
///
/// Implementations may return a lazy iterable. This source fully materializes
/// and validates every projector result before returning the final event
/// batch. Projectors receive R09's frame as read-only facts and must not mutate
/// mutable payload containers retained by individual combat event objects.
typedef Phase0aExternalObjectiveEventProjector =
    Iterable<EncounterObjectiveEvent> Function(
      Phase0aEncounterObjectiveFrame frame,
    );

/// Exact-roster objective event source for one dynamic encounter.
///
/// Every roster actor has one explicit projection list, including actors that
/// deliberately map to an empty list. Defeat events are projected in combat
/// event order and per-actor declaration order. The six non-defeat kinds are
/// appended in projector declaration and yield order.
final class Phase0aExplicitObjectiveEventSource
    implements Phase0aEncounterObjectiveEventSource {
  Phase0aExplicitObjectiveEventSource({
    required Phase0aEncounterRoster roster,
    required Map<String, Iterable<Phase0aDefeatObjectiveProjection>>
    defeatProjectionsByActorId,
    required Iterable<Phase0aExternalObjectiveEventProjector>
    externalProjectors,
  }) : _defeatProjectionsByActorId = _freezeDefeatProjections(
         roster,
         defeatProjectionsByActorId,
       ),
       _externalProjectors =
           List<Phase0aExternalObjectiveEventProjector>.unmodifiable(
             externalProjectors,
           );

  final Map<String, List<Phase0aDefeatObjectiveProjection>>
  _defeatProjectionsByActorId;
  final List<Phase0aExternalObjectiveEventProjector> _externalProjectors;

  @override
  List<EncounterObjectiveEvent> eventsFor(
    Phase0aEncounterObjectiveFrame frame,
  ) {
    final events = <EncounterObjectiveEvent>[];

    for (final combatEvent in frame.combatEvents) {
      if (combatEvent is! Phase0aEnemyDefeated) continue;

      final projections = _defeatProjectionsByActorId[combatEvent.target];
      if (projections == null) {
        throw ArgumentError.value(
          combatEvent.target,
          'frame.combatEvents',
          'defeated actor is not present in the exact roster projection map',
        );
      }
      for (var index = 0; index < projections.length; index += 1) {
        final eventId = _defeatEventId(combatEvent, index);
        events.add(switch (projections[index]) {
          Phase0aTargetDefeatProjection(:final targetId) => TargetDefeated(
            targetId,
            eventId: eventId,
          ),
          Phase0aCommanderDefeatProjection(:final commanderId) =>
            CommanderDefeated(commanderId, eventId: eventId),
        });
      }
    }

    final externalEvents = <EncounterObjectiveEvent>[];
    for (final projector in _externalProjectors) {
      final projected = List<EncounterObjectiveEvent>.unmodifiable(
        projector(frame),
      );
      for (final event in projected) {
        _checkExternalEvent(event);
      }
      externalEvents.addAll(projected);
    }
    events.addAll(externalEvents);
    return List<EncounterObjectiveEvent>.unmodifiable(events);
  }
}

Map<String, List<Phase0aDefeatObjectiveProjection>> _freezeDefeatProjections(
  Phase0aEncounterRoster roster,
  Map<String, Iterable<Phase0aDefeatObjectiveProjection>> source,
) {
  final expected = {for (final binding in roster.bindings) binding.actorId};
  final actual = source.keys.toSet();
  final missing = expected.difference(actual).toList()..sort();
  final extra = actual.difference(expected).toList()..sort();
  if (missing.isNotEmpty || extra.isNotEmpty) {
    throw ArgumentError.value(
      {'missing': missing, 'extra': extra},
      'defeatProjectionsByActorId',
      'keys must exactly cover the roster actor ids',
    );
  }

  return Map<String, List<Phase0aDefeatObjectiveProjection>>.unmodifiable({
    for (final entry in source.entries)
      entry.key: List<Phase0aDefeatObjectiveProjection>.unmodifiable(
        entry.value,
      ),
  });
}

String _defeatEventId(Phase0aEnemyDefeated event, int projectionIndex) =>
    'phase0a:defeat:${event.tick}:${event.seq}:$projectionIndex';

void _checkExternalEvent(EncounterObjectiveEvent event) {
  switch (event) {
    case AnchorDestroyed():
    case EntityDefended():
    case TimeElapsed():
    case CheckpointReached():
    case MarkerTouched():
    case TargetPursued():
      return;
    case TargetDefeated():
    case CommanderDefeated():
      throw ArgumentError.value(
        event,
        'externalProjectors',
        'defeat objective events require an exact roster actor projection',
      );
  }
}
