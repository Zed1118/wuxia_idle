import 'dart:collection';

import 'combat_enemy_archetype_def.dart';

/// Explicit migration route for one stage's content, mirroring the runtime
/// `Phase0aEncounterMigrationState` contract (P2-G2-E05). The value is always
/// an explicit caller input; no default route exists.
enum CombatEncounterMigrationState { legacy, migrated }

/// Immutable attack-token budgets for one encounter, mirroring the runtime
/// `AttackTokenBudgets` contract (P2-G2-D02). All four per-kind budgets are
/// explicit caller inputs, each validated non-negative; no defaults.
final class CombatEncounterTokenBudgets {
  CombatEncounterTokenBudgets({
    required int melee,
    required int ranged,
    required int charge,
    required int support,
  }) : melee = _checkedBudget(melee, 'melee'),
       ranged = _checkedBudget(ranged, 'ranged'),
       charge = _checkedBudget(charge, 'charge'),
       support = _checkedBudget(support, 'support');

  final int melee;
  final int ranged;
  final int charge;
  final int support;

  static int _checkedBudget(int value, String field) {
    if (value < 0) {
      throw ArgumentError.value(value, field, 'must not be negative');
    }
    return value;
  }
}

/// Immutable spawn-director configuration for one encounter, mirroring the
/// runtime `SpawnDirectorConfig` contract (P2-G2-D01). Every value is an
/// explicit caller input; the schema provides no tuning defaults.
final class CombatEncounterSpawnConfig {
  CombatEncounterSpawnConfig({
    required this.activeLimit,
    required this.reinforcementThreshold,
    required this.entryWarningTicks,
    required this.attackGraceTicks,
  }) {
    if (activeLimit <= 0) {
      throw ArgumentError.value(activeLimit, 'activeLimit', 'must be positive');
    }
    if (reinforcementThreshold < 0 || reinforcementThreshold >= activeLimit) {
      throw ArgumentError.value(
        reinforcementThreshold,
        'reinforcementThreshold',
        'must be in [0, activeLimit)',
      );
    }
    if (entryWarningTicks < 0) {
      throw ArgumentError.value(
        entryWarningTicks,
        'entryWarningTicks',
        'must not be negative',
      );
    }
    if (attackGraceTicks < 0) {
      throw ArgumentError.value(
        attackGraceTicks,
        'attackGraceTicks',
        'must not be negative',
      );
    }
  }

  /// Maximum simultaneously present units (active + warning pipeline).
  final int activeLimit;

  /// Active count at or below which reinforcement is triggered.
  final int reinforcementThreshold;

  /// Warning ticks before an entry becomes active; 0 = no warning phase.
  final int entryWarningTicks;

  /// Attack grace ticks after an entry becomes active.
  final int attackGraceTicks;
}

/// One immutable spawn entry: a reference to an archetype variant role.
///
/// [archetypeId] plus [roleId] jointly form the archetype variant role
/// reference; resolution against the owning catalog fails closed at manifest
/// construction when either side is unknown. The runtime enemy instance id is
/// intentionally not part of the content schema (it is derived at load time).
final class CombatEncounterSpawnEntry {
  CombatEncounterSpawnEntry({
    required String entryId,
    required String archetypeId,
    required String roleId,
    required String entranceId,
    required String positionId,
    required String behaviorId,
  }) : entryId = _checkedId(entryId, 'entryId'),
       archetypeId = _checkedId(archetypeId, 'archetypeId'),
       roleId = _checkedId(roleId, 'roleId'),
       entranceId = _checkedId(entranceId, 'entranceId'),
       positionId = _checkedId(positionId, 'positionId'),
       behaviorId = _checkedId(behaviorId, 'behaviorId');

  /// Unique within the owning encounter.
  final String entryId;

  /// References a [CombatEnemyArchetypeDef] id in the owning catalog.
  final String archetypeId;

  /// References a variant [CombatArchetypeVariant.roleId] of that archetype.
  final String roleId;

  /// References a caller-declared encounter entrance.
  final String entranceId;

  /// References a caller-declared spawn position or anchor.
  final String positionId;

  /// References the behavior used when this entry is spawned.
  final String behaviorId;

  static String _checkedId(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'must not be empty');
    }
    if (RegExp(r'\s').hasMatch(value)) {
      throw ArgumentError.value(value, field, 'must not contain whitespace');
    }
    return value;
  }
}

/// Content-neutral reference to an encounter objective primitive.
///
/// The eight sealed kinds mirror the P2-G2-O01 objective primitives
/// (DefeatTargets / DestroyAnchors / DefendEntity / SurviveDuration /
/// ReachCheckpoint / TouchMarkers / PursueTarget / DefeatCommander). This
/// schema side carries only the primitive kind and its explicit caller
/// parameters; it never hardcodes a stage, content or production objective.
sealed class CombatObjectivePrimitiveRef {
  const CombatObjectivePrimitiveRef();
}

/// Reference to the defeat-targets primitive: every listed target must be
/// defeated. Target ids are caller-supplied content keys.
final class CombatDefeatTargetsRef extends CombatObjectivePrimitiveRef {
  CombatDefeatTargetsRef(Iterable<String> targetIds)
    : targetIds = _checkedIdSet(targetIds, 'targetIds');

  final UnmodifiableSetView<String> targetIds;
}

/// Reference to the destroy-anchors primitive: every listed anchor must be
/// destroyed. Anchor ids are caller-supplied content keys.
final class CombatDestroyAnchorsRef extends CombatObjectivePrimitiveRef {
  CombatDestroyAnchorsRef(Iterable<String> anchorIds)
    : anchorIds = _checkedIdSet(anchorIds, 'anchorIds');

  final UnmodifiableSetView<String> anchorIds;
}

/// Reference to the defend-entity primitive: the listed entity must survive
/// for [requiredTicks]. All values are explicit caller inputs.
final class CombatDefendEntityRef extends CombatObjectivePrimitiveRef {
  CombatDefendEntityRef({required String entityId, required int requiredTicks})
    : entityId = _checkedId(entityId, 'entityId'),
      requiredTicks = _checkedPositiveTicks(requiredTicks, 'requiredTicks');

  final String entityId;
  final int requiredTicks;
}

/// Reference to the survive-duration primitive: the player must survive for
/// [requiredTicks]. The duration is an explicit caller input.
final class CombatSurviveDurationRef extends CombatObjectivePrimitiveRef {
  CombatSurviveDurationRef({required int requiredTicks})
    : requiredTicks = _checkedPositiveTicks(requiredTicks, 'requiredTicks');

  final int requiredTicks;
}

/// Reference to the reach-checkpoint primitive: every listed checkpoint must
/// be reached. Checkpoint ids are caller-supplied content keys.
final class CombatReachCheckpointRef extends CombatObjectivePrimitiveRef {
  CombatReachCheckpointRef(Iterable<String> checkpointIds)
    : checkpointIds = _checkedIdSet(checkpointIds, 'checkpointIds');

  final UnmodifiableSetView<String> checkpointIds;
}

/// Reference to the touch-markers primitive: every listed marker must be
/// touched. Marker ids are caller-supplied content keys.
final class CombatTouchMarkersRef extends CombatObjectivePrimitiveRef {
  CombatTouchMarkersRef(Iterable<String> markerIds)
    : markerIds = _checkedIdSet(markerIds, 'markerIds');

  final UnmodifiableSetView<String> markerIds;
}

/// Reference to the pursue-target primitive: the listed target must be
/// pursued. The target id is a caller-supplied content key.
final class CombatPursueTargetRef extends CombatObjectivePrimitiveRef {
  CombatPursueTargetRef({required String targetId})
    : targetId = _checkedId(targetId, 'targetId');

  final String targetId;
}

/// Reference to the defeat-commander primitive: the listed commander must be
/// defeated. The commander id is a caller-supplied content key.
final class CombatDefeatCommanderRef extends CombatObjectivePrimitiveRef {
  CombatDefeatCommanderRef({required String commanderId})
    : commanderId = _checkedId(commanderId, 'commanderId');

  final String commanderId;
}

/// Explicit completion rule for a flat objective composition.
///
/// Flat `all` and `any` are sufficient for the frozen M2 template evidence;
/// nested precedence, failure composition and phase transitions deliberately
/// remain outside this schema.
enum CombatObjectiveCompletionRule { all, any }

/// Stable caller-defined identity for one primitive within a composition.
final class CombatObjectiveClauseRef {
  CombatObjectiveClauseRef({required String id, required this.primitive})
    : id = _checkedId(id, 'id');

  final String id;
  final CombatObjectivePrimitiveRef primitive;
}

/// Immutable flat composition of one or more objective primitives.
final class CombatObjectiveCompositionRef {
  CombatObjectiveCompositionRef({
    required this.completionRule,
    required Iterable<CombatObjectiveClauseRef> clauses,
  }) : clauses = List<CombatObjectiveClauseRef>.unmodifiable(clauses) {
    if (this.clauses.isEmpty) {
      throw ArgumentError.value(this.clauses, 'clauses', 'must not be empty');
    }
    final duplicates = _duplicateIds(this.clauses.map((clause) => clause.id));
    if (duplicates.isNotEmpty) {
      throw ArgumentError.value(duplicates, 'clauses', 'duplicate id(s)');
    }
  }

  final CombatObjectiveCompletionRule completionRule;
  final List<CombatObjectiveClauseRef> clauses;
}

/// Immutable typed combat encounter content definition.
///
/// Deliberately distinct from the legacy narrative `EncounterDef`
/// (encounter_def.dart); this schema carries spawn entries/config, attack
/// token budgets and a content-neutral objective composition for the Phase 0A
/// combat runtime, and shares no fields with the narrative def. All tuning
/// values are explicit caller inputs; no numeric defaults exist.
final class CombatEncounterDef {
  CombatEncounterDef({
    required String id,
    required this.spawnConfig,
    required this.tokenBudgets,
    required Iterable<CombatEncounterSpawnEntry> spawnEntries,
    required this.objectives,
  }) : id = _checkedId(id, 'id'),
       spawnEntries = List<CombatEncounterSpawnEntry>.unmodifiable(
         spawnEntries,
       ) {
    if (this.spawnEntries.isEmpty) {
      throw ArgumentError.value(
        this.spawnEntries,
        'spawnEntries',
        'must not be empty',
      );
    }
    final duplicates = _duplicateIds(this.spawnEntries.map((e) => e.entryId));
    if (duplicates.isNotEmpty) {
      throw ArgumentError.value(
        duplicates,
        'spawnEntries',
        'duplicate entryId(s)',
      );
    }
  }

  /// Non-empty, whitespace-free unique identifier for the encounter.
  final String id;

  /// Explicit spawn-director configuration (warning/grace included).
  final CombatEncounterSpawnConfig spawnConfig;

  /// Explicit per-kind attack-token budgets.
  final CombatEncounterTokenBudgets tokenBudgets;

  /// At least one entry; entry ids unique within the encounter. Defensive
  /// copy: the exposed list is unmodifiable.
  final List<CombatEncounterSpawnEntry> spawnEntries;

  /// Explicit flat composition of one or more content-neutral primitive refs.
  final CombatObjectiveCompositionRef objectives;
}

String _checkedId(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  if (RegExp(r'\s').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must not contain whitespace');
  }
  return value;
}

int _checkedPositiveTicks(int value, String field) {
  if (value <= 0) {
    throw ArgumentError.value(value, field, 'must be positive');
  }
  return value;
}

UnmodifiableSetView<String> _checkedIdSet(Iterable<String> ids, String field) {
  final list = ids.toList(growable: false);
  if (list.isEmpty) {
    throw ArgumentError.value(ids, field, 'must not be empty');
  }
  final seen = <String>{};
  final duplicates = <String>[];
  for (final id in list) {
    _checkedId(id, field);
    if (!seen.add(id)) duplicates.add(id);
  }
  if (duplicates.isNotEmpty) {
    duplicates.sort();
    throw ArgumentError.value(duplicates, field, 'duplicate id(s)');
  }
  return UnmodifiableSetView<String>(Set.unmodifiable(list));
}

/// Returns the sorted unique ids that appear more than once, so duplicate
/// reports are deterministic regardless of input order.
List<String> _duplicateIds(Iterable<String> ids) {
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
