import 'dart:collection';

Set<String> _immutableIds(Iterable<String> values, String name) {
  final ids = values.toList(growable: false);
  if (ids.isEmpty ||
      ids.any((id) => id.trim().isEmpty || id.contains(RegExp(r'\s'))) ||
      ids.toSet().length != ids.length) {
    throw ArgumentError.value(values, name, 'must be unique and non-empty');
  }
  return Set<String>.unmodifiable(ids);
}

String _validatedEventId(String value) {
  if (value.trim().isEmpty || value.contains(RegExp(r'\s'))) {
    throw ArgumentError.value(value, 'eventId');
  }
  return value;
}

String _validatedPayload(String value, String name) {
  if (value.trim().isEmpty || value.contains(RegExp(r'\s'))) {
    throw ArgumentError.value(value, name);
  }
  return value;
}

String _eventId(String? supplied, String kind, String payload, String name) {
  final validPayload = _validatedPayload(payload, name);
  return _validatedEventId(supplied ?? '$kind:$validPayload');
}

/// Content-neutral events consumed by encounter objectives.
sealed class EncounterObjectiveEvent {
  const EncounterObjectiveEvent(this.kind, this.id);

  final String kind;

  /// A stable caller-provided key. Replaying a key is a no-op.
  final String id;

  String get dedupeKey => '$kind:$id';
}

final class TargetDefeated extends EncounterObjectiveEvent {
  TargetDefeated(String targetId, {String? eventId})
    : targetId = _validatedPayload(targetId, 'targetId'),
      super(
        'targetDefeated',
        _eventId(eventId, 'defeat', targetId, 'targetId'),
      );
  final String targetId;
}

final class AnchorDestroyed extends EncounterObjectiveEvent {
  AnchorDestroyed(String anchorId, {String? eventId})
    : anchorId = _validatedPayload(anchorId, 'anchorId'),
      super(
        'anchorDestroyed',
        _eventId(eventId, 'destroy', anchorId, 'anchorId'),
      );
  final String anchorId;
}

final class EntityDefended extends EncounterObjectiveEvent {
  EntityDefended(String entityId, this.duration, {required String eventId})
    : entityId = _validatedPayload(entityId, 'entityId'),
      super('entityDefended', _validatedEventId(eventId)) {
    if (duration < Duration.zero) {
      throw ArgumentError.value(duration, 'duration');
    }
  }
  final String entityId;
  final Duration duration;
}

final class TimeElapsed extends EncounterObjectiveEvent {
  TimeElapsed(this.duration, {required String eventId})
    : super('timeElapsed', _validatedEventId(eventId)) {
    if (duration < Duration.zero) {
      throw ArgumentError.value(duration, 'duration');
    }
  }
  final Duration duration;
}

final class CheckpointReached extends EncounterObjectiveEvent {
  CheckpointReached(String checkpointId, {String? eventId})
    : checkpointId = _validatedPayload(checkpointId, 'checkpointId'),
      super(
        'checkpointReached',
        _eventId(eventId, 'checkpoint', checkpointId, 'checkpointId'),
      );
  final String checkpointId;
}

final class MarkerTouched extends EncounterObjectiveEvent {
  MarkerTouched(String markerId, {String? eventId})
    : markerId = _validatedPayload(markerId, 'markerId'),
      super('markerTouched', _eventId(eventId, 'marker', markerId, 'markerId'));
  final String markerId;
}

final class TargetPursued extends EncounterObjectiveEvent {
  TargetPursued(String targetId, {String? eventId})
    : targetId = _validatedPayload(targetId, 'targetId'),
      super('targetPursued', _eventId(eventId, 'pursue', targetId, 'targetId'));
  final String targetId;
}

final class CommanderDefeated extends EncounterObjectiveEvent {
  CommanderDefeated(String commanderId, {String? eventId})
    : commanderId = _validatedPayload(commanderId, 'commanderId'),
      super(
        'commanderDefeated',
        _eventId(eventId, 'commander', commanderId, 'commanderId'),
      );
  final String commanderId;
}

/// Immutable reducer state. Sets are snapshots and cannot be mutated by a caller.
final class EncounterObjectiveProgress {
  EncounterObjectiveProgress._({
    required Object ownerToken,
    required this.completed,
    required Set<String> satisfied,
    required this.elapsed,
    required Set<String> processedEventIds,
  }) : _ownerToken = ownerToken,
       satisfied = UnmodifiableSetView<String>(
         Set<String>.unmodifiable(satisfied),
       ),
       processedEventIds = UnmodifiableSetView<String>(
         Set<String>.unmodifiable(processedEventIds),
       );

  final Object _ownerToken;
  final bool completed;
  final UnmodifiableSetView<String> satisfied;
  final Duration elapsed;
  final UnmodifiableSetView<String> processedEventIds;

  EncounterObjectiveProgress _copyWith({
    bool? completed,
    Set<String>? satisfied,
    Duration? elapsed,
    Set<String>? processedEventIds,
  }) => EncounterObjectiveProgress._(
    ownerToken: _ownerToken,
    completed: completed ?? this.completed,
    satisfied: satisfied ?? this.satisfied,
    elapsed: elapsed ?? this.elapsed,
    processedEventIds: processedEventIds ?? this.processedEventIds,
  );

  @override
  bool operator ==(Object other) =>
      other is EncounterObjectiveProgress &&
      other.completed == completed &&
      other.satisfied.length == satisfied.length &&
      other.satisfied.containsAll(satisfied) &&
      other.elapsed == elapsed &&
      other.processedEventIds.length == processedEventIds.length &&
      other.processedEventIds.containsAll(processedEventIds);

  @override
  int get hashCode => Object.hash(
    completed,
    Object.hashAll(satisfied.toList()..sort()),
    elapsed,
    Object.hashAll(processedEventIds.toList()..sort()),
  );
}

sealed class EncounterObjective {
  EncounterObjective() : _ownerToken = Object();

  final Object _ownerToken;

  EncounterObjectiveProgress get initialProgress =>
      EncounterObjectiveProgress._(
        ownerToken: _ownerToken,
        completed: false,
        satisfied: const <String>{},
        elapsed: Duration.zero,
        processedEventIds: const <String>{},
      );

  EncounterObjectiveProgress advance(
    EncounterObjectiveProgress progress,
    EncounterObjectiveEvent event,
  );

  EncounterObjectiveProgress apply(
    EncounterObjectiveProgress progress,
    EncounterObjectiveEvent event,
  ) => advance(progress, event);

  EncounterObjectiveProgress _guard(
    EncounterObjectiveProgress progress,
    EncounterObjectiveEvent event,
  ) {
    if (!identical(progress._ownerToken, _ownerToken)) {
      throw StateError('Objective progress belongs to another objective');
    }
    if (progress.completed ||
        progress.processedEventIds.contains(event.dedupeKey)) {
      return progress;
    }
    return progress._copyWith(
      processedEventIds: {...progress.processedEventIds, event.dedupeKey},
    );
  }

  void _requireId(String value, String name) {
    if (value.trim().isEmpty || value.contains(RegExp(r'\s'))) {
      throw ArgumentError.value(value, name);
    }
  }

  void _requireDuration(Duration value, String name) {
    if (value <= Duration.zero) throw ArgumentError.value(value, name);
  }
}

final class DefeatTargetsObjective extends EncounterObjective {
  DefeatTargetsObjective(Iterable<String> targetIds)
    : targetIds = UnmodifiableSetView(_immutableIds(targetIds, 'targetIds'));
  final UnmodifiableSetView<String> targetIds;
  @override
  EncounterObjectiveProgress advance(p, e) {
    final next = _guard(p, e);
    if (identical(next, p)) return p;
    if (e is TargetDefeated && targetIds.contains(e.targetId)) {
      final done = {...next.satisfied, e.targetId};
      return next._copyWith(
        satisfied: done,
        completed: done.length == targetIds.length,
      );
    }
    return next;
  }
}

final class DestroyAnchorsObjective extends EncounterObjective {
  DestroyAnchorsObjective(Iterable<String> anchorIds)
    : anchorIds = UnmodifiableSetView(_immutableIds(anchorIds, 'anchorIds'));
  final UnmodifiableSetView<String> anchorIds;
  @override
  EncounterObjectiveProgress advance(p, e) {
    final next = _guard(p, e);
    if (identical(next, p)) return p;
    if (e is AnchorDestroyed && anchorIds.contains(e.anchorId)) {
      final done = {...next.satisfied, e.anchorId};
      return next._copyWith(
        satisfied: done,
        completed: done.length == anchorIds.length,
      );
    }
    return next;
  }
}

final class DefendEntityObjective extends EncounterObjective {
  DefendEntityObjective(this.entityId, this.requiredDuration) {
    _requireId(entityId, 'entityId');
    _requireDuration(requiredDuration, 'requiredDuration');
  }
  final String entityId;
  final Duration requiredDuration;
  @override
  EncounterObjectiveProgress advance(p, e) {
    final next = _guard(p, e);
    if (identical(next, p)) return p;
    if (e is EntityDefended && e.entityId == entityId) {
      final elapsed = next.elapsed + e.duration;
      return next._copyWith(
        elapsed: elapsed,
        completed: elapsed >= requiredDuration,
      );
    }
    return next;
  }
}

final class SurviveDurationObjective extends EncounterObjective {
  SurviveDurationObjective(this.requiredDuration) {
    _requireDuration(requiredDuration, 'requiredDuration');
  }
  final Duration requiredDuration;
  @override
  EncounterObjectiveProgress advance(p, e) {
    final next = _guard(p, e);
    if (identical(next, p)) return p;
    if (e is TimeElapsed) {
      if (e.duration <= Duration.zero) return next;
      final elapsed = next.elapsed + e.duration;
      return next._copyWith(
        elapsed: elapsed,
        completed: elapsed >= requiredDuration,
      );
    }
    return next;
  }
}

final class ReachCheckpointObjective extends EncounterObjective {
  ReachCheckpointObjective(Iterable<String> checkpointIds)
    : checkpointIds = UnmodifiableSetView(
        _immutableIds(checkpointIds, 'checkpointIds'),
      );
  final UnmodifiableSetView<String> checkpointIds;
  @override
  EncounterObjectiveProgress advance(p, e) {
    final next = _guard(p, e);
    if (identical(next, p)) return p;
    if (e is CheckpointReached && checkpointIds.contains(e.checkpointId)) {
      final done = {...next.satisfied, e.checkpointId};
      return next._copyWith(
        satisfied: done,
        completed: done.length == checkpointIds.length,
      );
    }
    return next;
  }
}

final class TouchMarkersObjective extends EncounterObjective {
  TouchMarkersObjective(Iterable<String> markerIds)
    : markerIds = UnmodifiableSetView(_immutableIds(markerIds, 'markerIds'));
  final UnmodifiableSetView<String> markerIds;
  @override
  EncounterObjectiveProgress advance(p, e) {
    final next = _guard(p, e);
    if (identical(next, p)) return p;
    if (e is MarkerTouched && markerIds.contains(e.markerId)) {
      final done = {...next.satisfied, e.markerId};
      return next._copyWith(
        satisfied: done,
        completed: done.length == markerIds.length,
      );
    }
    return next;
  }
}

final class PursueTargetObjective extends EncounterObjective {
  PursueTargetObjective(this.targetId) {
    _requireId(targetId, 'targetId');
  }
  final String targetId;
  @override
  EncounterObjectiveProgress advance(p, e) {
    final next = _guard(p, e);
    if (identical(next, p)) return p;
    return e is TargetPursued && e.targetId == targetId
        ? next._copyWith(satisfied: {targetId}, completed: true)
        : next;
  }
}

final class DefeatCommanderObjective extends EncounterObjective {
  DefeatCommanderObjective(this.commanderId) {
    _requireId(commanderId, 'commanderId');
  }
  final String commanderId;
  @override
  EncounterObjectiveProgress advance(p, e) {
    final next = _guard(p, e);
    if (identical(next, p)) return p;
    return e is CommanderDefeated && e.commanderId == commanderId
        ? next._copyWith(satisfied: {commanderId}, completed: true)
        : next;
  }
}
