import 'combat_catalog_reference_index.dart';
import 'combat_enemy_archetype_def.dart';
import 'combat_encounter_def.dart';

/// One stage's explicit migration route and its unique encounter association.
///
/// Mirrors the content side of the runtime `Phase0aEncounterMigrationResolver`
/// contract (P2-G2-E05): a `legacy` stage carries no encounter, a `migrated`
/// stage carries exactly one. Both/neither combinations fail closed.
final class CombatStageEncounterAssignment {
  CombatStageEncounterAssignment({
    required String stageId,
    required this.migrationState,
    String? encounterId,
  }) : stageId = _checkedId(stageId, 'stageId'),
       encounterId = encounterId == null
           ? null
           : _checkedId(encounterId, 'encounterId') {
    if (migrationState == CombatEncounterMigrationState.migrated &&
        encounterId == null) {
      throw ArgumentError.value(
        encounterId,
        'encounterId',
        'migrated stage requires exactly one encounterId',
      );
    }
    if (migrationState == CombatEncounterMigrationState.legacy &&
        encounterId != null) {
      throw ArgumentError.value(
        encounterId,
        'encounterId',
        'legacy stage must not carry an encounterId',
      );
    }
  }

  /// Non-empty, whitespace-free stage id; unique across assignments.
  final String stageId;

  /// Explicit caller-declared migration route; no default exists.
  final CombatEncounterMigrationState migrationState;

  /// Encounter id; non-null exactly when [migrationState] is `migrated`.
  final String? encounterId;

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

/// Immutable catalog manifest tying combat content together.
///
/// Holds the archetype and encounter catalogs plus the stage assignments, and
/// resolves every cross-reference at construction time. All collections are
/// defensively copied and unmodifiable; caller input mutation after
/// construction cannot affect the manifest.
///
/// Unique association contract:
/// - assignment stage ids are unique,
/// - assignment encounter ids are unique (each encounter belongs to at most
///   one stage),
/// - every catalog encounter is referenced by exactly one migrated
///   assignment (each stage owns exactly one encounter),
/// - `migrated` assignments must reference an existing encounter,
/// - every spawn entry must reference an existing archetype and an existing
///   variant role of that archetype,
/// - every id-bearing objective primitive must resolve in its caller-provided
///   objective namespace; survive-duration carries no external id.
final class CombatCatalogManifestDef {
  CombatCatalogManifestDef({
    required this.referenceIndex,
    required Iterable<CombatEnemyArchetypeDef> archetypes,
    required Iterable<CombatEncounterDef> encounters,
    required Iterable<CombatStageEncounterAssignment> stageAssignments,
  }) : archetypes = List<CombatEnemyArchetypeDef>.unmodifiable(archetypes),
       encounters = List<CombatEncounterDef>.unmodifiable(encounters),
       stageAssignments = List<CombatStageEncounterAssignment>.unmodifiable(
         stageAssignments,
       ) {
    _validate();
  }

  final List<CombatEnemyArchetypeDef> archetypes;
  final List<CombatEncounterDef> encounters;
  final List<CombatStageEncounterAssignment> stageAssignments;
  final CombatCatalogReferenceIndex referenceIndex;

  /// Resolves an archetype by [id]; unknown ids return null.
  CombatEnemyArchetypeDef? archetypeById(String id) {
    for (final archetype in archetypes) {
      if (archetype.id == id) return archetype;
    }
    return null;
  }

  /// Resolves an encounter by [id]; unknown ids return null.
  CombatEncounterDef? encounterById(String id) {
    for (final encounter in encounters) {
      if (encounter.id == id) return encounter;
    }
    return null;
  }

  /// Resolves the assignment for [stageId]; unknown stages return null.
  CombatStageEncounterAssignment? assignmentForStage(String stageId) {
    for (final assignment in stageAssignments) {
      if (assignment.stageId == stageId) return assignment;
    }
    return null;
  }

  /// The single encounter associated with [stageId]; legacy stages and
  /// unknown stages return null.
  CombatEncounterDef? encounterForStage(String stageId) {
    final assignment = assignmentForStage(stageId);
    if (assignment == null || assignment.encounterId == null) return null;
    return encounterById(assignment.encounterId!);
  }

  void _validate() {
    _checkNoDuplicates(archetypes.map((a) => a.id), 'archetypes', 'archetype');
    _checkNoDuplicates(encounters.map((e) => e.id), 'encounters', 'encounter');
    _checkNoDuplicates(
      stageAssignments.map((a) => a.stageId),
      'stageAssignments',
      'stageId',
    );
    _checkNoDuplicates(
      stageAssignments
          .where((a) => a.encounterId != null)
          .map((a) => a.encounterId!),
      'stageAssignments',
      'encounterId',
    );

    final encountersById = <String, CombatEncounterDef>{
      for (final encounter in encounters) encounter.id: encounter,
    };
    final archetypesById = <String, CombatEnemyArchetypeDef>{
      for (final archetype in archetypes) archetype.id: archetype,
    };

    final referencedEncounterIds = <String>{};
    for (final assignment in stageAssignments) {
      final encounterId = assignment.encounterId;
      if (encounterId == null) continue;
      if (!encountersById.containsKey(encounterId)) {
        throw ArgumentError.value(
          encounterId,
          'stageAssignments',
          'unknown encounterId reference',
        );
      }
      if (!referencedEncounterIds.add(encounterId)) {
        throw ArgumentError.value(
          encounterId,
          'stageAssignments',
          'encounter must be assigned to at most one stage',
        );
      }
    }
    for (final encounter in encounters) {
      if (!referencedEncounterIds.contains(encounter.id)) {
        throw ArgumentError.value(
          encounter.id,
          'encounters',
          'every encounter must be assigned to exactly one stage',
        );
      }
    }

    for (final encounter in encounters) {
      for (final entry in encounter.spawnEntries) {
        final archetype = archetypesById[entry.archetypeId];
        if (archetype == null) {
          throw ArgumentError.value(
            entry.archetypeId,
            'spawnEntries',
            'unknown archetypeId reference',
          );
        }
        if (archetype.variantByRole(entry.roleId) == null) {
          throw ArgumentError.value(
            entry.roleId,
            'spawnEntries',
            'unknown roleId for archetype ${archetype.id}',
          );
        }
        _requireKnown(
          entry.entranceId,
          referenceIndex.entranceIds,
          'spawnEntries',
          'entranceId',
        );
        _requireKnown(
          entry.positionId,
          referenceIndex.positionIds,
          'spawnEntries',
          'positionId',
        );
        _requireKnown(
          entry.behaviorId,
          referenceIndex.behaviorIds,
          'spawnEntries',
          'behaviorId',
        );
      }
      for (final clause in encounter.objectives.clauses) {
        _validateObjectiveReference(clause.primitive);
      }
    }

    for (final archetype in archetypes) {
      for (final variant in archetype.variants) {
        _requireKnown(
          variant.attackSetId,
          referenceIndex.attackSetIds,
          'variants',
          'attackSetId',
        );
        for (final id in variant.attackTagIds) {
          _requireKnown(
            id,
            referenceIndex.attackTagIds,
            'variants',
            'attackTagIds',
          );
        }
        _requireKnown(
          variant.postureProfileId,
          referenceIndex.postureProfileIds,
          'variants',
          'postureProfileId',
        );
        _requireKnown(
          variant.dropGroupId,
          referenceIndex.dropGroupIds,
          'variants',
          'dropGroupId',
        );
        _requireKnown(
          variant.sfxGroupId,
          referenceIndex.sfxGroupIds,
          'variants',
          'sfxGroupId',
        );
        for (final id in variant.visualVariantIds) {
          _requireKnown(
            id,
            referenceIndex.visualVariantIds,
            'variants',
            'visualVariantIds',
          );
        }
      }
    }
  }

  void _validateObjectiveReference(CombatObjectivePrimitiveRef primitive) {
    switch (primitive) {
      case CombatDefeatTargetsRef(:final targetIds):
        for (final id in targetIds) {
          _requireKnown(
            id,
            referenceIndex.objectiveTargetIds,
            'objectives',
            'targetIds',
          );
        }
      case CombatDestroyAnchorsRef(:final anchorIds):
        for (final id in anchorIds) {
          _requireKnown(
            id,
            referenceIndex.objectiveAnchorIds,
            'objectives',
            'anchorIds',
          );
        }
      case CombatDefendEntityRef(:final entityId):
        _requireKnown(
          entityId,
          referenceIndex.objectiveEntityIds,
          'objectives',
          'entityId',
        );
      case CombatSurviveDurationRef():
        break;
      case CombatReachCheckpointRef(:final checkpointIds):
        for (final id in checkpointIds) {
          _requireKnown(
            id,
            referenceIndex.objectiveCheckpointIds,
            'objectives',
            'checkpointIds',
          );
        }
      case CombatTouchMarkersRef(:final markerIds):
        for (final id in markerIds) {
          _requireKnown(
            id,
            referenceIndex.objectiveMarkerIds,
            'objectives',
            'markerIds',
          );
        }
      case CombatPursueTargetRef(:final targetId):
        _requireKnown(
          targetId,
          referenceIndex.objectiveTargetIds,
          'objectives',
          'targetId',
        );
      case CombatDefeatCommanderRef(:final commanderId):
        _requireKnown(
          commanderId,
          referenceIndex.objectiveTargetIds,
          'objectives',
          'commanderId',
        );
    }
  }

  static void _requireKnown(
    String id,
    Set<String> knownIds,
    String field,
    String label,
  ) {
    if (!knownIds.contains(id)) {
      throw ArgumentError.value(id, field, 'unknown $label reference');
    }
  }

  static void _checkNoDuplicates(
    Iterable<String> ids,
    String field,
    String label,
  ) {
    final duplicates = _duplicateIds(ids);
    if (duplicates.isNotEmpty) {
      throw ArgumentError.value(duplicates, field, 'duplicate $label id(s)');
    }
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
