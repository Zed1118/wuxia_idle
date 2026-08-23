// Pure caller-provided loader assembling the Phase 0A combat catalog
// manifest (P2-G2-L01) from explicitly named YAML sources. No IO, no
// defaults, no placeholders: every violation fails closed with a
// FormatException carrying the source name and the offending field path.

import 'defs/combat_catalog_manifest_def.dart';
import 'defs/combat_encounter_def.dart';
import 'defs/combat_enemy_archetype_def.dart';
import 'validation/combat_encounter_catalog_validator.dart';

/// One caller-provided named YAML source: a stable display name plus content.
typedef CombatCatalogYamlSource = (String sourceName, String yaml);

/// Loads the combat catalog manifest from caller-provided named sources.
///
/// Merges all [archetypeSources] and [encounterSources] with the single
/// [manifestSource] into one [CombatCatalogManifestDef]. Duplicate ids across
/// sources, unknown archetype/role/encounter references and unassigned
/// encounters all fail closed; the typed manifest additionally closes
/// stage-encounter uniqueness and migration-state invariants. The result
/// never retains caller-mutable collections.
CombatCatalogManifestDef loadCombatCatalogManifest({
  required Iterable<CombatCatalogYamlSource> archetypeSources,
  required Iterable<CombatCatalogYamlSource> encounterSources,
  required CombatCatalogYamlSource manifestSource,
}) {
  final parsedArchetypeSources = [
    for (final source in archetypeSources)
      validateCombatArchetypeSource(source.$1, source.$2),
  ];
  final parsedEncounterSources = [
    for (final source in encounterSources)
      validateCombatEncounterSource(source.$1, source.$2),
  ];
  final parsedAssignments = validateCombatAssignmentSource(
    manifestSource.$1,
    manifestSource.$2,
  );

  final archetypes = <CombatEnemyArchetypeDef>[];
  final archetypesById = <String, CombatEnemyArchetypeDef>{};
  final archetypeOwners = <String, (String, int)>{};
  for (final source in parsedArchetypeSources) {
    for (var i = 0; i < source.archetypes.length; i++) {
      final entry = source.archetypes[i];
      final existingOwner = archetypeOwners[entry.id];
      if (existingOwner != null) {
        throw FormatException(
          'combat catalog source "${source.sourceName}": '
          'archetypes[$i].id: duplicate archetype id "${entry.id}"; '
          'first declared at source "${existingOwner.$1}": '
          'archetypes[${existingOwner.$2}].id',
        );
      }
      archetypeOwners[entry.id] = (source.sourceName, i);
      final archetype = _buildArchetype(entry, source.sourceName, i);
      archetypes.add(archetype);
      archetypesById[archetype.id] = archetype;
    }
  }

  final encounters = <CombatEncounterDef>[];
  final encounterOwners = <String, (String, int)>{};
  for (final source in parsedEncounterSources) {
    for (var i = 0; i < source.encounters.length; i++) {
      final entry = source.encounters[i];
      final existingOwner = encounterOwners[entry.id];
      if (existingOwner != null) {
        throw FormatException(
          'combat catalog source "${source.sourceName}": '
          'encounters[$i].id: duplicate encounter id "${entry.id}"; '
          'first declared at source "${existingOwner.$1}": '
          'encounters[${existingOwner.$2}].id',
        );
      }
      encounterOwners[entry.id] = (source.sourceName, i);
      for (var j = 0; j < entry.spawnEntries.length; j++) {
        final spawnEntry = entry.spawnEntries[j];
        final archetype = archetypesById[spawnEntry.archetypeId];
        if (archetype == null) {
          throw FormatException(
            'combat catalog source "${source.sourceName}": '
            'encounters[$i].spawn_entries[$j].archetype_id: '
            'unknown archetype "${spawnEntry.archetypeId}"',
          );
        }
        if (archetype.variantByRole(spawnEntry.roleId) == null) {
          throw FormatException(
            'combat catalog source "${source.sourceName}": '
            'encounters[$i].spawn_entries[$j].role_id: '
            'unknown role "${spawnEntry.roleId}" '
            'for archetype "${spawnEntry.archetypeId}"',
          );
        }
      }
      encounters.add(_buildEncounter(entry, source.sourceName, i));
    }
  }

  final assignments = <CombatStageEncounterAssignment>[];
  final assignedEncounterIds = <String>{};
  for (var i = 0; i < parsedAssignments.assignments.length; i++) {
    final entry = parsedAssignments.assignments[i];
    final path = 'stage_assignments[$i]';
    final encounterId = entry.encounterId;
    if (encounterId != null) {
      if (!encounterOwners.containsKey(encounterId)) {
        throw FormatException(
          'combat catalog source "${manifestSource.$1}": '
          '$path.encounter_id: unknown encounter "$encounterId"',
        );
      }
      assignedEncounterIds.add(encounterId);
    }
    try {
      assignments.add(
        CombatStageEncounterAssignment(
          stageId: entry.stageId,
          migrationState: CombatEncounterMigrationState.values.byName(
            entry.migrationState,
          ),
          encounterId: encounterId,
        ),
      );
    } on ArgumentError catch (e) {
      throw FormatException(
        'combat catalog source "${manifestSource.$1}": $path: '
        '${_argumentErrorText(e)}',
      );
    }
  }

  for (final source in parsedEncounterSources) {
    for (var i = 0; i < source.encounters.length; i++) {
      final id = source.encounters[i].id;
      if (!assignedEncounterIds.contains(id)) {
        throw FormatException(
          'combat catalog source "${source.sourceName}": encounters[$i]: '
          'encounter "$id" is not assigned to any stage',
        );
      }
    }
  }

  try {
    return CombatCatalogManifestDef(
      archetypes: archetypes,
      encounters: encounters,
      stageAssignments: assignments,
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'combat catalog manifest "${manifestSource.$1}": ${_argumentErrorText(e)}',
    );
  }
}

CombatEnemyArchetypeDef _buildArchetype(
  ParsedCombatArchetypeEntry entry,
  String sourceName,
  int index,
) {
  final variants = <CombatArchetypeVariant>[];
  for (var i = 0; i < entry.variants.length; i++) {
    final variant = entry.variants[i];
    try {
      variants.add(
        CombatArchetypeVariant(
          roleId: variant.roleId,
          attackTokenKind: CombatAttackTokenKind.values.byName(
            variant.attackTokenKind,
          ),
          hpMultiplier: variant.hpMultiplier,
          attackMultiplier: variant.attackMultiplier,
          defenseMultiplier: variant.defenseMultiplier,
          speedMultiplier: variant.speedMultiplier,
        ),
      );
    } on ArgumentError catch (e) {
      throw FormatException(
        'combat catalog source "$sourceName": '
        'archetypes[$index].variants[$i]: ${_argumentErrorText(e)}',
      );
    }
  }
  try {
    return CombatEnemyArchetypeDef(id: entry.id, variants: variants);
  } on ArgumentError catch (e) {
    throw FormatException(
      'combat catalog source "$sourceName": archetypes[$index]: '
      '${_argumentErrorText(e)}',
    );
  }
}

CombatEncounterDef _buildEncounter(
  ParsedCombatEncounterEntry entry,
  String sourceName,
  int index,
) {
  final path = 'encounters[$index]';

  final CombatEncounterSpawnConfig spawnConfig;
  try {
    spawnConfig = CombatEncounterSpawnConfig(
      activeLimit: entry.spawnConfig.activeLimit,
      reinforcementThreshold: entry.spawnConfig.reinforcementThreshold,
      entryWarningTicks: entry.spawnConfig.entryWarningTicks,
      attackGraceTicks: entry.spawnConfig.attackGraceTicks,
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'combat catalog source "$sourceName": $path.spawn_config: '
      '${_argumentErrorText(e)}',
    );
  }

  final CombatEncounterTokenBudgets tokenBudgets;
  try {
    tokenBudgets = CombatEncounterTokenBudgets(
      melee: entry.tokenBudgets.melee,
      ranged: entry.tokenBudgets.ranged,
      charge: entry.tokenBudgets.charge,
      support: entry.tokenBudgets.support,
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'combat catalog source "$sourceName": $path.token_budgets: '
      '${_argumentErrorText(e)}',
    );
  }

  final spawnEntries = <CombatEncounterSpawnEntry>[];
  for (var i = 0; i < entry.spawnEntries.length; i++) {
    final spawnEntry = entry.spawnEntries[i];
    try {
      spawnEntries.add(
        CombatEncounterSpawnEntry(
          entryId: spawnEntry.entryId,
          archetypeId: spawnEntry.archetypeId,
          roleId: spawnEntry.roleId,
        ),
      );
    } on ArgumentError catch (e) {
      throw FormatException(
        'combat catalog source "$sourceName": $path.spawn_entries[$i]: '
        '${_argumentErrorText(e)}',
      );
    }
  }

  final CombatObjectivePrimitiveRef objective;
  try {
    objective = _buildObjective(entry.objective);
  } on ArgumentError catch (e) {
    throw FormatException(
      'combat catalog source "$sourceName": $path.objective: '
      '${_argumentErrorText(e)}',
    );
  }

  try {
    return CombatEncounterDef(
      id: entry.id,
      spawnConfig: spawnConfig,
      tokenBudgets: tokenBudgets,
      spawnEntries: spawnEntries,
      objective: objective,
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'combat catalog source "$sourceName": $path: ${_argumentErrorText(e)}',
    );
  }
}

CombatObjectivePrimitiveRef _buildObjective(ParsedCombatObjective objective) {
  switch (objective.kind) {
    case 'defeat_targets':
      return CombatDefeatTargetsRef(objective.idList);
    case 'destroy_anchors':
      return CombatDestroyAnchorsRef(objective.idList);
    case 'defend_entity':
      return CombatDefendEntityRef(
        entityId: objective.singleId!,
        requiredTicks: objective.requiredTicks!,
      );
    case 'survive_duration':
      return CombatSurviveDurationRef(requiredTicks: objective.requiredTicks!);
    case 'reach_checkpoint':
      return CombatReachCheckpointRef(objective.idList);
    case 'touch_markers':
      return CombatTouchMarkersRef(objective.idList);
    case 'pursue_target':
      return CombatPursueTargetRef(targetId: objective.singleId!);
    case 'defeat_commander':
      return CombatDefeatCommanderRef(commanderId: objective.singleId!);
  }
  throw StateError('unreachable objective kind "${objective.kind}"');
}

String _argumentErrorText(ArgumentError error) {
  final message = error.message?.toString() ?? 'invalid argument';
  final name = error.name;
  return name == null || name.isEmpty ? message : '$name: $message';
}
