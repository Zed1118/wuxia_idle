/// In-memory-only loot presentation for the Phase 0B feedback draft.
///
/// Nothing in this file touches disk, the production database, shared
/// preferences, or the production drop/reward pipeline. Entries exist only
/// for the lifetime of the owning controller; the isolation guard test
/// enforces this.
library;

/// Coarse loot categories for the draft feed. Deliberately generic so the
/// draft does not pre-commit to production item taxonomy.
enum LootKind { currency, material, gear }

/// One displayed loot drop. [sequence] is a per-feed monotonically
/// increasing id so the UI can key entries without identity guesses.
final class LootEntry {
  const LootEntry({
    required this.sequence,
    required this.label,
    required this.kind,
  });

  final int sequence;
  final String label;
  final LootKind kind;
}

/// A bounded, in-memory-only loot feed.
final class LootFeed {
  LootFeed({this.capacity = 6}) {
    if (capacity < 1) {
      throw ArgumentError.value(capacity, 'capacity', 'must be >= 1');
    }
  }

  /// Maximum number of retained entries; oldest entries drop out first.
  final int capacity;

  final List<LootEntry> _entries = <LootEntry>[];
  int _nextSequence = 1;

  /// Current entries, oldest first. The returned list is unmodifiable.
  List<LootEntry> get entries => List<LootEntry>.unmodifiable(_entries);

  /// Append a drop, evicting the oldest entry when over capacity.
  LootEntry add({required String label, required LootKind kind}) {
    final entry = LootEntry(sequence: _nextSequence, label: label, kind: kind);
    _nextSequence += 1;
    _entries.add(entry);
    while (_entries.length > capacity) {
      _entries.removeAt(0);
    }
    return entry;
  }

  /// Drop every entry and restart sequencing (used on battle reset).
  void clear() {
    _entries.clear();
    _nextSequence = 1;
  }
}
