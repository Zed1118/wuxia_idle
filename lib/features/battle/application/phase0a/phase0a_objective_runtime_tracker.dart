import '../../domain/phase0a/encounter_objective.dart';
import '../../domain/phase0a/objective_controller.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';

/// Explicit caller policy for translating one combat defeat into objective
/// events. The tracker never infers target, commander, role, or defeat kind.
typedef Phase0aDefeatObjectiveEventMapper =
    Iterable<EncounterObjectiveEvent> Function(Phase0aEnemyDefeated defeat);

/// One owner-bound objective transition prepared without mutating its tracker.
///
/// [base] and [next] are the exact immutable controller snapshots used during
/// preparation. Only the tracker that prepared this value may commit it, and
/// one successful commit consumes it permanently.
final class Phase0aPreparedObjectiveTransition {
  Phase0aPreparedObjectiveTransition._({
    required Object ownerToken,
    required this.base,
    required this.next,
  }) : _ownerToken = ownerToken;

  final Object _ownerToken;
  final ObjectiveControllerProgress base;
  final ObjectiveControllerProgress next;
  bool _committed = false;
}

/// Pure application owner for one objective controller progress lineage.
///
/// Batches are reduced against a local snapshot. A prepared transition remains
/// side-effect free until [commit] validates tracker ownership and the exact
/// base snapshot with compare-and-set semantics.
final class Phase0aObjectiveRuntimeTracker {
  Phase0aObjectiveRuntimeTracker({
    required this.controller,
    ObjectiveControllerProgress? initialProgress,
  }) : _progress = _validatedInitialProgress(controller, initialProgress),
       _ownerToken = Object();

  final ObjectiveController controller;
  final Object _ownerToken;
  ObjectiveControllerProgress _progress;

  ObjectiveControllerProgress get progress => _progress;

  /// Reduces an ordered external event batch without mutating [progress].
  ///
  /// Terminal progress is a strict no-op: [events] is not iterated.
  Phase0aPreparedObjectiveTransition prepareExternalEvents(
    Iterable<EncounterObjectiveEvent> events,
  ) {
    final current = _progress;
    if (current.completed) return _prepared(current, current);

    final inputSnapshot = List<EncounterObjectiveEvent>.unmodifiable(events);
    return _prepareSnapshot(current, inputSnapshot);
  }

  /// Maps and reduces an ordered combat batch without mutating [progress].
  ///
  /// Combat input and every mapped iterable are snapshotted before their events
  /// are reduced. Any iteration, mapper, or controller failure therefore
  /// leaves the tracker unchanged.
  Phase0aPreparedObjectiveTransition prepareCombatEvents(
    Iterable<Phase0aEvent> combatEvents, {
    required Phase0aDefeatObjectiveEventMapper mapDefeat,
  }) {
    final current = _progress;
    if (current.completed) return _prepared(current, current);

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
    return _prepared(current, next);
  }

  /// Commits one prepared transition with owner-bound compare-and-set checks.
  ///
  /// Foreign, stale, and already committed transitions fail closed. Equality
  /// is accepted only for the same controller owner lineage; normally the
  /// exact [Phase0aPreparedObjectiveTransition.base] instance is retained.
  ObjectiveControllerProgress commit(
    Phase0aPreparedObjectiveTransition transition,
  ) {
    if (!identical(transition._ownerToken, _ownerToken)) {
      throw StateError(
        'Prepared objective transition belongs to another tracker',
      );
    }
    if (transition._committed) {
      throw StateError('Prepared objective transition was already committed');
    }
    if (!identical(_progress, transition.base) &&
        _progress != transition.base) {
      throw StateError('Prepared objective transition is stale');
    }

    transition._committed = true;
    _progress = transition.next;
    return _progress;
  }

  ObjectiveControllerProgress advanceExternal(EncounterObjectiveEvent event) {
    return commit(prepareExternalEvents([event]));
  }

  ObjectiveControllerProgress advanceCombatEvents(
    Iterable<Phase0aEvent> combatEvents, {
    required Phase0aDefeatObjectiveEventMapper mapDefeat,
  }) {
    return commit(prepareCombatEvents(combatEvents, mapDefeat: mapDefeat));
  }

  Phase0aPreparedObjectiveTransition _prepareSnapshot(
    ObjectiveControllerProgress current,
    List<EncounterObjectiveEvent> events,
  ) {
    var next = current;
    for (final event in events) {
      next = controller.advance(next, event);
      if (next.completed) break;
    }
    return _prepared(current, next);
  }

  Phase0aPreparedObjectiveTransition _prepared(
    ObjectiveControllerProgress base,
    ObjectiveControllerProgress next,
  ) => Phase0aPreparedObjectiveTransition._(
    ownerToken: _ownerToken,
    base: base,
    next: next,
  );
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
