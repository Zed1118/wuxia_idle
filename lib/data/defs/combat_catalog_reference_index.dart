import 'dart:collection';

/// Caller-provided universe of stable combat-content reference ids.
///
/// The catalog schema deliberately does not load or infer these external
/// content families. A production or test caller must assemble the complete
/// known-id universe from its own authoritative sources, then the manifest
/// validates every archetype and spawn reference against it. No namespace has
/// a fallback id or placeholder.
final class CombatCatalogReferenceIndex {
  CombatCatalogReferenceIndex({
    required Iterable<String> entranceIds,
    required Iterable<String> positionIds,
    required Iterable<String> behaviorIds,
    required Iterable<String> attackSetIds,
    required Iterable<String> attackTagIds,
    required Iterable<String> postureProfileIds,
    required Iterable<String> dropGroupIds,
    required Iterable<String> sfxGroupIds,
    required Iterable<String> visualVariantIds,
  }) : entranceIds = _checkedIds(entranceIds, 'entranceIds'),
       positionIds = _checkedIds(positionIds, 'positionIds'),
       behaviorIds = _checkedIds(behaviorIds, 'behaviorIds'),
       attackSetIds = _checkedIds(attackSetIds, 'attackSetIds'),
       attackTagIds = _checkedIds(attackTagIds, 'attackTagIds'),
       postureProfileIds = _checkedIds(postureProfileIds, 'postureProfileIds'),
       dropGroupIds = _checkedIds(dropGroupIds, 'dropGroupIds'),
       sfxGroupIds = _checkedIds(sfxGroupIds, 'sfxGroupIds'),
       visualVariantIds = _checkedIds(visualVariantIds, 'visualVariantIds');

  final UnmodifiableSetView<String> entranceIds;
  final UnmodifiableSetView<String> positionIds;
  final UnmodifiableSetView<String> behaviorIds;
  final UnmodifiableSetView<String> attackSetIds;
  final UnmodifiableSetView<String> attackTagIds;
  final UnmodifiableSetView<String> postureProfileIds;
  final UnmodifiableSetView<String> dropGroupIds;
  final UnmodifiableSetView<String> sfxGroupIds;
  final UnmodifiableSetView<String> visualVariantIds;
}

UnmodifiableSetView<String> _checkedIds(Iterable<String> values, String field) {
  final list = values.toList(growable: false);
  final seen = <String>{};
  final duplicates = <String>{};
  for (final value in list) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'must not contain an empty id');
    }
    if (RegExp(r'\s').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        field,
        'ids must not contain whitespace',
      );
    }
    if (!seen.add(value)) duplicates.add(value);
  }
  if (duplicates.isNotEmpty) {
    final sorted = duplicates.toList()..sort();
    throw ArgumentError.value(sorted, field, 'duplicate id(s)');
  }
  return UnmodifiableSetView<String>(Set<String>.unmodifiable(list));
}
