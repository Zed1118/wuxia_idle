/// Deterministic domain ordering and read-only presentation projection.
enum CombatEventStage {
  legalityAndResources,
  startup,
  displacementAndSelection,
  hitFreeze,
  defense,
  damageAndPosture,
  status,
  killAndResources,
  presentation,
}

enum CombatFeedKind { none, action, impact, status, defeat }

final class CombatEventRecord {
  CombatEventRecord({
    required this.eventId,
    required this.tick,
    required this.stage,
    required this.tieBreak,
    this.aggregateKey,
    this.priority,
    this.feedKind = CombatFeedKind.none,
  }) {
    _requireText(eventId, 'eventId');
    _requireNonNegative(tick, 'tick');
    _requireNonNegative(tieBreak, 'tieBreak');
    if (feedKind == CombatFeedKind.none) {
      if (aggregateKey != null || priority != null) {
        throw ArgumentError(
          'non-presentation events must not carry feed fields',
        );
      }
    } else {
      if (stage != CombatEventStage.presentation) {
        throw ArgumentError.value(
          feedKind,
          'feedKind',
          'feed events must use the presentation stage',
        );
      }
      _requireText(aggregateKey, 'aggregateKey');
      if (priority == null) {
        throw ArgumentError.value(priority, 'priority');
      }
      _requireNonNegative(priority!, 'priority');
    }
  }

  final String eventId;
  final int tick;
  final CombatEventStage stage;
  final int tieBreak;
  final String? aggregateKey;
  final int? priority;
  final CombatFeedKind feedKind;

  @override
  bool operator ==(Object other) =>
      other is CombatEventRecord &&
      other.eventId == eventId &&
      other.tick == tick &&
      other.stage == stage &&
      other.tieBreak == tieBreak &&
      other.aggregateKey == aggregateKey &&
      other.priority == priority &&
      other.feedKind == feedKind;

  @override
  int get hashCode => Object.hash(
    eventId,
    tick,
    stage,
    tieBreak,
    aggregateKey,
    priority,
    feedKind,
  );
}

final class CombatEventOrder {
  const CombatEventOrder._();

  static List<CombatEventRecord> order(Iterable<CombatEventRecord> events) {
    final ordered = events.toList(growable: true);
    final eventIds = <String>{};
    for (final event in ordered) {
      if (!eventIds.add(event.eventId)) {
        throw ArgumentError.value(event.eventId, 'eventId', 'must be unique');
      }
    }
    ordered.sort(_compare);
    return List<CombatEventRecord>.unmodifiable(ordered);
  }

  static int _compare(CombatEventRecord left, CombatEventRecord right) {
    final tick = left.tick.compareTo(right.tick);
    if (tick != 0) return tick;
    final stage = left.stage.index.compareTo(right.stage.index);
    if (stage != 0) return stage;
    final tieBreak = left.tieBreak.compareTo(right.tieBreak);
    if (tieBreak != 0) return tieBreak;
    return left.eventId.compareTo(right.eventId);
  }
}

final class CombatPresentationFeedEntry {
  const CombatPresentationFeedEntry({
    required this.eventId,
    required this.tick,
    required this.aggregateKey,
    required this.priority,
    required this.kind,
  });

  final String eventId;
  final int tick;
  final String aggregateKey;
  final int priority;
  final CombatFeedKind kind;

  @override
  bool operator ==(Object other) =>
      other is CombatPresentationFeedEntry &&
      other.eventId == eventId &&
      other.tick == tick &&
      other.aggregateKey == aggregateKey &&
      other.priority == priority &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(eventId, tick, aggregateKey, priority, kind);
}

final class CombatPresentationFeed {
  CombatPresentationFeed._(List<CombatPresentationFeedEntry> entries)
    : entries = List<CombatPresentationFeedEntry>.unmodifiable(entries);

  final List<CombatPresentationFeedEntry> entries;

  factory CombatPresentationFeed.fromOrderedEvents(
    Iterable<CombatEventRecord> events,
  ) {
    final orderedEvents = List<CombatEventRecord>.unmodifiable(events);
    _validateOrdered(orderedEvents);
    final entries = <CombatPresentationFeedEntry>[];
    for (final event in orderedEvents) {
      if (event.feedKind == CombatFeedKind.none) continue;
      entries.add(
        CombatPresentationFeedEntry(
          eventId: event.eventId,
          tick: event.tick,
          aggregateKey: event.aggregateKey!,
          priority: event.priority!,
          kind: event.feedKind,
        ),
      );
    }
    return CombatPresentationFeed._(entries);
  }
}

void _validateOrdered(Iterable<CombatEventRecord> events) {
  CombatEventRecord? previous;
  final ids = <String>{};
  for (final event in events) {
    if (!ids.add(event.eventId)) {
      throw ArgumentError.value(event.eventId, 'eventId', 'must be unique');
    }
    if (previous != null && CombatEventOrder._compare(previous, event) > 0) {
      throw ArgumentError('events must already be ordered');
    }
    previous = event;
  }
}

void _requireText(String? value, String name) {
  if (value == null || value.isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, name, 'must be a trimmed non-empty ID');
  }
}

void _requireNonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name);
  }
}
