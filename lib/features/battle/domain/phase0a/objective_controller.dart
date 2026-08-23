import 'dart:collection';

import 'encounter_objective.dart';

/// Aggregate completion semantics for a flat objective composition.
enum ObjectiveCompletionRule { all, any }

/// One stable, caller-identified primitive within an objective composition.
final class ObjectiveClause {
  ObjectiveClause({required String id, required this.objective})
    : id = _validatedClauseId(id);

  final String id;
  final EncounterObjective objective;
}

/// Immutable progress for one clause, kept in controller declaration order.
final class ObjectiveClauseProgress {
  const ObjectiveClauseProgress._({required this.id, required this.progress});

  final String id;
  final EncounterObjectiveProgress progress;

  bool get completed => progress.completed;

  @override
  bool operator ==(Object other) =>
      other is ObjectiveClauseProgress &&
      other.id == id &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(id, progress);
}

/// Immutable aggregate progress owned by exactly one [ObjectiveController].
final class ObjectiveControllerProgress {
  ObjectiveControllerProgress._({
    required Object ownerToken,
    required this.completed,
    required Iterable<ObjectiveClauseProgress> clauses,
  }) : _ownerToken = ownerToken,
       clauses = UnmodifiableListView<ObjectiveClauseProgress>(
         List<ObjectiveClauseProgress>.unmodifiable(clauses),
       );

  final Object _ownerToken;
  final bool completed;
  final UnmodifiableListView<ObjectiveClauseProgress> clauses;

  @override
  bool operator ==(Object other) {
    if (other is! ObjectiveControllerProgress ||
        !identical(other._ownerToken, _ownerToken) ||
        other.completed != completed ||
        other.clauses.length != clauses.length) {
      return false;
    }
    for (var index = 0; index < clauses.length; index += 1) {
      if (other.clauses[index] != clauses[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(_ownerToken),
    completed,
    Object.hashAll(clauses),
  );
}

/// Pure controller for one immutable, flat objective composition.
///
/// Events are reduced against every unfinished primitive in stable clause
/// order. Aggregate completion is evaluated only from the resulting snapshot;
/// once terminal, every later event returns the same progress instance.
final class ObjectiveController {
  ObjectiveController({
    required this.completionRule,
    required Iterable<ObjectiveClause> clauses,
  }) : clauses = UnmodifiableListView<ObjectiveClause>(
         List<ObjectiveClause>.unmodifiable(clauses),
       ),
       _ownerToken = Object() {
    if (this.clauses.isEmpty) {
      throw ArgumentError.value(this.clauses, 'clauses', 'must not be empty');
    }
    final ids = <String>{};
    for (final clause in this.clauses) {
      if (!ids.add(clause.id)) {
        throw ArgumentError.value(clause.id, 'clauses', 'ids must be unique');
      }
    }
  }

  final ObjectiveCompletionRule completionRule;
  final UnmodifiableListView<ObjectiveClause> clauses;
  final Object _ownerToken;

  ObjectiveControllerProgress get initialProgress =>
      ObjectiveControllerProgress._(
        ownerToken: _ownerToken,
        completed: false,
        clauses: [
          for (final clause in clauses)
            ObjectiveClauseProgress._(
              id: clause.id,
              progress: clause.objective.initialProgress,
            ),
        ],
      );

  ObjectiveControllerProgress advance(
    ObjectiveControllerProgress progress,
    EncounterObjectiveEvent event,
  ) {
    if (!identical(progress._ownerToken, _ownerToken)) {
      throw StateError('Objective progress belongs to another controller');
    }
    if (progress.completed) return progress;

    var changed = false;
    final nextClauses = <ObjectiveClauseProgress>[];
    for (var index = 0; index < clauses.length; index += 1) {
      final clause = clauses[index];
      final current = progress.clauses[index];
      if (current.completed) {
        nextClauses.add(current);
        continue;
      }
      final nextProgress = clause.objective.advance(current.progress, event);
      if (identical(nextProgress, current.progress)) {
        nextClauses.add(current);
      } else {
        changed = true;
        nextClauses.add(
          ObjectiveClauseProgress._(id: clause.id, progress: nextProgress),
        );
      }
    }

    final completed = switch (completionRule) {
      ObjectiveCompletionRule.all => nextClauses.every(
        (clause) => clause.completed,
      ),
      ObjectiveCompletionRule.any => nextClauses.any(
        (clause) => clause.completed,
      ),
    };
    if (!changed && completed == progress.completed) return progress;
    return ObjectiveControllerProgress._(
      ownerToken: _ownerToken,
      completed: completed,
      clauses: nextClauses,
    );
  }

  ObjectiveControllerProgress apply(
    ObjectiveControllerProgress progress,
    EncounterObjectiveEvent event,
  ) => advance(progress, event);
}

String _validatedClauseId(String value) {
  if (value.trim().isEmpty || value.contains(RegExp(r'\s'))) {
    throw ArgumentError.value(value, 'id', 'must be non-empty and clean');
  }
  return value;
}
