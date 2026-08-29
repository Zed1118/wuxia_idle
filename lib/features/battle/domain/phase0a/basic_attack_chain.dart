/// Shared schema for weapon basic-attack chains.
///
/// Segment identity and ordering are production-consumed. Geometry, timeline
/// and effect references stay opaque typed IDs until their wider registries
/// are wired; the reducer does not duplicate their tuning values here.
enum WeaponType { sword, heavy, flexible, dual, hidden }

const swordBasicAttackSegmentIds = <String>[
  'sword_thrust',
  'sword_sweep',
  'sword_advancing_slash',
];

/// M2 teaching/baseline sword chain frozen by the Phase 2 authority plan.
///
/// All three segments currently reuse the production basic-attack resolver;
/// their identity drives deterministic sequencing and distinct presentation.
/// Per-segment target caps and displacement remain outside this chain schema.
final swordBasicAttackChain = BasicAttackChain(
  weapon: WeaponType.sword,
  segments: [
    BasicAttackSegment(
      id: swordBasicAttackSegmentIds[0],
      geometryRef: 'geometry.sword.thrust',
      timelineRef: 'timeline.weapon.sword',
      effectRefs: const ['effect.damage.basic'],
    ),
    BasicAttackSegment(
      id: swordBasicAttackSegmentIds[1],
      geometryRef: 'geometry.sword.sweep',
      timelineRef: 'timeline.weapon.sword',
      effectRefs: const ['effect.damage.basic'],
    ),
    BasicAttackSegment(
      id: swordBasicAttackSegmentIds[2],
      geometryRef: 'geometry.sword.advancing_slash',
      timelineRef: 'timeline.weapon.sword',
      effectRefs: const ['effect.damage.basic'],
    ),
  ],
  // This schema field is not a production idle timer yet. Keep it derived
  // from the declared chain rather than inventing an independent tuning value.
  resetAfterIdleTicks: swordBasicAttackSegmentIds.length,
);

final class BasicAttackSegment {
  BasicAttackSegment({
    required this.id,
    required this.geometryRef,
    required this.timelineRef,
    required List<String> effectRefs,
  }) : _effectRefs = List<String>.unmodifiable(effectRefs) {
    validate();
  }

  final String id;
  final String geometryRef;
  final String timelineRef;
  final List<String> _effectRefs;

  List<String> get effectRefs => _effectRefs;

  void validate() {
    _requireRef(id, 'id');
    _requireRef(geometryRef, 'geometryRef');
    _requireRef(timelineRef, 'timelineRef');
    if (_effectRefs.isEmpty) {
      throw ArgumentError.value(_effectRefs, 'effectRefs');
    }
    for (final ref in _effectRefs) {
      _requireRef(ref, 'effectRefs');
    }
    if (_effectRefs.length != _effectRefs.toSet().length) {
      throw ArgumentError.value(_effectRefs, 'effectRefs');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BasicAttackSegment &&
      other.id == id &&
      other.geometryRef == geometryRef &&
      other.timelineRef == timelineRef &&
      _sameRefs(other._effectRefs);

  bool _sameRefs(List<String> other) =>
      other.length == _effectRefs.length &&
      List.generate(
        other.length,
        (index) => other[index] == _effectRefs[index],
      ).every((same) => same);

  @override
  int get hashCode =>
      Object.hash(id, geometryRef, timelineRef, Object.hashAll(_effectRefs));
}

final class BasicAttackChain {
  BasicAttackChain({
    required this.weapon,
    required List<BasicAttackSegment> segments,
    required this.resetAfterIdleTicks,
  }) : _segments = List<BasicAttackSegment>.unmodifiable(segments) {
    if (_segments.isEmpty) throw ArgumentError.value(segments, 'segments');
    if (resetAfterIdleTicks <= 0) {
      throw ArgumentError.value(resetAfterIdleTicks, 'resetAfterIdleTicks');
    }
    final ids = <String>{};
    for (final segment in _segments) {
      segment.validate();
      if (!ids.add(segment.id)) {
        throw ArgumentError('segment ids must be unique');
      }
    }
  }

  final WeaponType weapon;
  final List<BasicAttackSegment> _segments;
  final int resetAfterIdleTicks;

  List<BasicAttackSegment> get segments => _segments;

  List<String> get timelineRefs => List<String>.unmodifiable(
    _segments.map((segment) => segment.timelineRef),
  );

  List<String> get geometryRefs => List<String>.unmodifiable(
    _segments.map((segment) => segment.geometryRef),
  );

  BasicAttackSegment segmentAt(int index) {
    if (index < 0 || index >= _segments.length) {
      throw RangeError.index(index, _segments, 'index');
    }
    return _segments[index];
  }

  @override
  bool operator ==(Object other) =>
      other is BasicAttackChain &&
      other.weapon == weapon &&
      other.resetAfterIdleTicks == resetAfterIdleTicks &&
      _sameSegments(other._segments);

  bool _sameSegments(List<BasicAttackSegment> other) =>
      other.length == _segments.length &&
      List.generate(
        other.length,
        (index) => other[index] == _segments[index],
      ).every((same) => same);

  @override
  int get hashCode =>
      Object.hash(weapon, resetAfterIdleTicks, Object.hashAll(_segments));

  /// Computes the next segment without mutating state.
  ///
  /// The caller owns the current index and supplies elapsed idle ticks. An
  /// interrupt always resets before the next action; otherwise the chain
  /// wraps only after the declared segment list ends.
  int nextSegmentIndex({
    required int currentIndex,
    required int idleTicks,
    bool interrupted = false,
  }) {
    if (currentIndex < 0 || currentIndex >= _segments.length) {
      throw RangeError.index(currentIndex, _segments, 'currentIndex');
    }
    if (idleTicks < 0) throw ArgumentError.value(idleTicks, 'idleTicks');
    if (interrupted || idleTicks >= resetAfterIdleTicks) return 0;
    return (currentIndex + 1) % _segments.length;
  }
}

void _requireRef(String value, String name) {
  if (value.isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, name, 'must be a trimmed non-empty ID');
  }
}
