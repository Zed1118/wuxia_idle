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
    required this.aggregateKey,
    required this.priority,
    this.feedKind = CombatFeedKind.none,
  }) {
    _requireText(eventId, 'eventId');
    _requireText(aggregateKey, 'aggregateKey');
    _requireNonNegative(tick, 'tick');
    _requireNonNegative(tieBreak, 'tieBreak');
    _requireNonNegative(priority, 'priority');
    if (feedKind != CombatFeedKind.none &&
        stage != CombatEventStage.presentation) {
      throw ArgumentError.value(
        feedKind,
        'feedKind',
        'feed events must use the presentation stage',
      );
    }
  }

  final String eventId;
  final int tick;
  final CombatEventStage stage;
  final int tieBreak;
  final String aggregateKey;
  final int priority;
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
    final entries = <CombatPresentationFeedEntry>[];
    for (final event in events) {
      if (event.feedKind == CombatFeedKind.none) continue;
      entries.add(
        CombatPresentationFeedEntry(
          eventId: event.eventId,
          tick: event.tick,
          aggregateKey: event.aggregateKey,
          priority: event.priority,
          kind: event.feedKind,
        ),
      );
    }
    return CombatPresentationFeed._(entries);
  }
}

void _requireText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name);
  }
}

void _requireNonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name);
  }
}
