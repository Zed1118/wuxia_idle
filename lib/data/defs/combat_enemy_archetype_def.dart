import 'dart:collection';

/// Attack token kind that an archetype variant requests, mirroring the
/// runtime `AttackTokenKind` budget contract (P2-G2-D02). Every kind is an
/// explicit caller input; the schema defines no defaults.
enum CombatAttackTokenKind { melee, ranged, charge, support }

/// One immutable variant role of a combat enemy archetype.
///
/// A role is the stable content identity that encounter spawn entries
/// reference as `(archetypeId, roleId)`. All tuning multipliers are explicit
/// caller inputs validated at construction; no numeric defaults exist.
final class CombatArchetypeVariant {
  CombatArchetypeVariant({
    required String roleId,
    required this.attackTokenKind,
    required double hpMultiplier,
    required double attackMultiplier,
    required double defenseMultiplier,
    required double speedMultiplier,
    required String attackSetId,
    required Iterable<String> attackTagIds,
    required String postureProfileId,
    required String dropGroupId,
    required String sfxGroupId,
    required Iterable<String> visualVariantIds,
  }) : roleId = _checkedId(roleId, 'roleId'),
       hpMultiplier = _checkedPositive(hpMultiplier, 'hpMultiplier'),
       attackMultiplier = _checkedNonNegative(
         attackMultiplier,
         'attackMultiplier',
       ),
       defenseMultiplier = _checkedNonNegative(
         defenseMultiplier,
         'defenseMultiplier',
       ),
       speedMultiplier = _checkedNonNegative(
         speedMultiplier,
         'speedMultiplier',
       ),
       attackSetId = _checkedId(attackSetId, 'attackSetId'),
       attackTagIds = _checkedIdSet(attackTagIds, 'attackTagIds'),
       postureProfileId = _checkedId(postureProfileId, 'postureProfileId'),
       dropGroupId = _checkedId(dropGroupId, 'dropGroupId'),
       sfxGroupId = _checkedId(sfxGroupId, 'sfxGroupId'),
       visualVariantIds = _checkedIdSet(visualVariantIds, 'visualVariantIds');

  /// Unique within the owning archetype; non-empty and free of whitespace.
  final String roleId;

  /// Token budget kind this role's attacks request at runtime.
  final CombatAttackTokenKind attackTokenKind;

  /// Explicit caller-supplied tuning; must be finite and positive.
  final double hpMultiplier;

  /// Explicit caller-supplied tuning; must be finite and non-negative.
  final double attackMultiplier;

  /// Explicit caller-supplied tuning; must be finite and non-negative.
  final double defenseMultiplier;

  /// Explicit caller-supplied tuning; must be finite and non-negative.
  final double speedMultiplier;

  /// References the role's complete attack-set definition.
  final String attackSetId;

  /// References the attack tags declared by the role's attack set.
  final UnmodifiableSetView<String> attackTagIds;

  /// References the role's posture-capacity/recovery profile.
  final String postureProfileId;

  /// References the role's drop group; it does not define reward values here.
  final String dropGroupId;

  /// References the role's grouped combat sound profile.
  final String sfxGroupId;

  /// References one or more presentation variants. The schema intentionally
  /// does not impose a content-count target.
  final UnmodifiableSetView<String> visualVariantIds;

  static String _checkedId(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'must not be empty');
    }
    if (RegExp(r'\s').hasMatch(value)) {
      throw ArgumentError.value(value, field, 'must not contain whitespace');
    }
    return value;
  }

  static double _checkedPositive(double value, String field) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, field, 'must be finite and positive');
    }
    return value;
  }

  static double _checkedNonNegative(double value, String field) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        field,
        'must be finite and non-negative',
      );
    }
    return value;
  }

  static UnmodifiableSetView<String> _checkedIdSet(
    Iterable<String> values,
    String field,
  ) {
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      throw ArgumentError.value(values, field, 'must not be empty');
    }
    final seen = <String>{};
    final duplicates = <String>{};
    for (final value in list) {
      _checkedId(value, field);
      if (!seen.add(value)) duplicates.add(value);
    }
    if (duplicates.isNotEmpty) {
      final sorted = duplicates.toList()..sort();
      throw ArgumentError.value(sorted, field, 'duplicate id(s)');
    }
    return UnmodifiableSetView<String>(Set<String>.unmodifiable(list));
  }
}

/// Immutable combat enemy archetype: a reusable enemy kind exposing variant
/// roles that encounter spawn entries reference.
///
/// This is deliberately distinct from the legacy narrative
/// `EncounterDef` (encounter_def.dart); the two schemas share no fields and
/// are never interchangeable.
final class CombatEnemyArchetypeDef {
  CombatEnemyArchetypeDef({
    required String id,
    required Iterable<CombatArchetypeVariant> variants,
  }) : id = _checkedId(id, 'id'),
       variants = List<CombatArchetypeVariant>.unmodifiable(variants) {
    if (this.variants.isEmpty) {
      throw ArgumentError.value(this.variants, 'variants', 'must not be empty');
    }
    final duplicates = _duplicateIds(this.variants.map((v) => v.roleId));
    if (duplicates.isNotEmpty) {
      throw ArgumentError.value(duplicates, 'variants', 'duplicate roleId(s)');
    }
  }

  /// Non-empty, whitespace-free unique identifier for the archetype.
  final String id;

  /// Defensive copy; the caller's input list is never retained and the
  /// exposed list is unmodifiable. Stable in input order.
  final List<CombatArchetypeVariant> variants;

  /// Resolves a variant role by [roleId]; unknown roles return null.
  CombatArchetypeVariant? variantByRole(String roleId) {
    for (final variant in variants) {
      if (variant.roleId == roleId) return variant;
    }
    return null;
  }

  static String _checkedId(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'must not be empty');
    }
    if (RegExp(r'\s').hasMatch(value)) {
      throw ArgumentError.value(value, field, 'must not contain whitespace');
    }
    return value;
  }

  /// Returns the sorted unique ids that appear more than once, so duplicate
  /// reports are deterministic regardless of input order.
  static List<String> _duplicateIds(Iterable<String> ids) {
    final counts = <String, int>{};
    for (final id in ids) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final duplicates = <String>[
      for (final entry in counts.entries)
        if (entry.value > 1) entry.key,
    ]..sort();
    return duplicates;
  }
}
