/// Candidate-only schema for shared weapon basic-attack chains.
///
/// References are opaque IDs until G1 freezes the geometry, timeline and
/// effect registries. This module does not execute any referenced behavior.
enum WeaponType { sword, heavy, flexible, dual, hidden }

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

  List<String> get effectRefs => List<String>.unmodifiable(_effectRefs);

  void validate() {
    _requireRef(id, 'id');
    _requireRef(geometryRef, 'geometryRef');
    _requireRef(timelineRef, 'timelineRef');
    if (_effectRefs.isEmpty || _effectRefs.any((ref) => ref.trim().isEmpty)) {
      throw ArgumentError.value(_effectRefs, 'effectRefs');
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
  int get hashCode => Object.hash(id, geometryRef, timelineRef, effectRefs);
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
    final geometryRefs = <String>{};
    final timelineRefs = <String>{};
    for (final segment in _segments) {
      segment.validate();
      if (!ids.add(segment.id)) {
        throw ArgumentError('segment ids must be unique');
      }
      if (!geometryRefs.add(segment.geometryRef)) {
        throw ArgumentError('geometry refs must be unique');
      }
      if (!timelineRefs.add(segment.timelineRef)) {
        throw ArgumentError('timeline refs must be unique');
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
  if (value.trim().isEmpty) throw ArgumentError.value(value, name);
}
