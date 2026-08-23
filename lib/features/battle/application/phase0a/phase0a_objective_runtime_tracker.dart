import '../../domain/phase0a/encounter_objective.dart';
import '../../domain/phase0a/objective_controller.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';

/// Explicit caller policy for translating one combat defeat into objective
/// events. The tracker never infers target, commander, role, or defeat kind.
typedef Phase0aDefeatObjectiveEventMapper =
    Iterable<EncounterObjectiveEvent> Function(Phase0aEnemyDefeated defeat);

/// Pure application owner for one objective controller progress lineage.
///
/// Combat batches are reduced against a local snapshot and committed only
/// after every input, mapping, and controller advance succeeds.
final class Phase0aObjectiveRuntimeTracker {
  Phase0aObjectiveRuntimeTracker({
    required this.controller,
    ObjectiveControllerProgress? initialProgress,
  }) : _progress = _validatedInitialProgress(controller, initialProgress);

  final ObjectiveController controller;
  ObjectiveControllerProgress _progress;

  ObjectiveControllerProgress get progress => _progress;

  ObjectiveControllerProgress advanceExternal(EncounterObjectiveEvent event) {
    final current = _progress;
    if (current.completed) return current;

    final next = controller.advance(current, event);
    _progress = next;
    return next;
  }

  ObjectiveControllerProgress advanceCombatEvents(
    Iterable<Phase0aEvent> combatEvents, {
    required Phase0aDefeatObjectiveEventMapper mapDefeat,
  }) {
    final current = _progress;
    if (current.completed) return current;

    final inputSnapshot = List<Phase0aEvent>.unmodifiable(combatEvents);
    var next = current;
    for (final combatEvent in inputSnapshot) {
      if (next.completed) break;
      if (combatEvent is! Phase0aEnemyDefeated) continue;

      final mappedEvents = List<EncounterObjectiveEvent>.unmodifiable(
        mapDefeat(combatEvent),
      );
      for (final objectiveEvent in mappedEvents) {
        next = controller.advance(next, objectiveEvent);
        if (next.completed) break;
      }
    }

    _progress = next;
    return next;
  }
}

ObjectiveControllerProgress _validatedInitialProgress(
  ObjectiveController controller,
  ObjectiveControllerProgress? initialProgress,
) {
  if (initialProgress == null) return controller.initialProgress;

  // Advancing is side-effect free. Discarding this probe validates controller
  // ownership without mutating the caller's immutable progress snapshot.
  controller.advance(
    initialProgress,
    MarkerTouched(
      'phase0a_objective_runtime_tracker_owner_probe',
      eventId: 'phase0a_objective_runtime_tracker_owner_probe',
    ),
  );
  return initialProgress;
}
