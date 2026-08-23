// Pure caller-provided loader assembling the Phase 0A combat catalog
// manifest (P2-G2-L01) from explicitly named YAML sources. No IO, no
// defaults, no placeholders: every violation fails closed with a
// FormatException carrying the source name and the offending field path.

import 'defs/combat_catalog_manifest_def.dart';
import 'defs/combat_catalog_reference_index.dart';
import 'defs/combat_encounter_def.dart';
import 'defs/combat_enemy_archetype_def.dart';
import 'validation/combat_encounter_catalog_validator.dart';

/// One caller-provided named YAML source: a stable display name plus content.
typedef CombatCatalogYamlSource = (String sourceName, String yaml);

/// Loads the combat catalog manifest from caller-provided named sources.
///
/// Merges all [archetypeSources] and [encounterSources] with the single
/// [manifestSource] into one [CombatCatalogManifestDef]. Duplicate ids across
/// sources, unknown archetype/role/encounter/external references and
/// unassigned encounters all fail closed; the typed manifest additionally
/// closes stage-encounter uniqueness and migration-state invariants. The
/// caller supplies [referenceIndex] explicitly; the loader never infers a
/// content fallback. The result never retains caller-mutable collections.
CombatCatalogManifestDef loadCombatCatalogManifest({
  required Iterable<CombatCatalogYamlSource> archetypeSources,
  required Iterable<CombatCatalogYamlSource> encounterSources,
  required CombatCatalogYamlSource manifestSource,
  required CombatCatalogReferenceIndex referenceIndex,
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
      final archetype = _buildArchetype(
        entry,
        source.sourceName,
        i,
        referenceIndex,
      );
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
        _requireKnownReference(
          spawnEntry.entranceId,
          referenceIndex.entranceIds,
          source.sourceName,
          'encounters[$i].spawn_entries[$j].entrance_id',
          'entrance',
        );
        _requireKnownReference(
          spawnEntry.positionId,
          referenceIndex.positionIds,
          source.sourceName,
          'encounters[$i].spawn_entries[$j].position_id',
          'position',
        );
        _requireKnownReference(
          spawnEntry.behaviorId,
          referenceIndex.behaviorIds,
          source.sourceName,
          'encounters[$i].spawn_entries[$j].behavior_id',
          'behavior',
        );
      }
      encounters.add(
        _buildEncounter(entry, source.sourceName, i, referenceIndex),
      );
    }
  }

  final assignments = <CombatStageEncounterAssignment>[];
  final stageOwners = <String, int>{};
  final assignedEncounterOwners = <String, int>{};
  for (var i = 0; i < parsedAssignments.assignments.length; i++) {
    final entry = parsedAssignments.assignments[i];
    final path = 'stage_assignments[$i]';
    final existingStageOwner = stageOwners[entry.stageId];
    if (existingStageOwner != null) {
      throw FormatException(
        'combat catalog source "${manifestSource.$1}": $path.stage_id: '
        'duplicate stage id "${entry.stageId}"; first declared at '
        'stage_assignments[$existingStageOwner].stage_id',
      );
    }
    stageOwners[entry.stageId] = i;
    final encounterId = entry.encounterId;
    if (encounterId != null) {
      if (!encounterOwners.containsKey(encounterId)) {
        throw FormatException(
          'combat catalog source "${manifestSource.$1}": '
          '$path.encounter_id: unknown encounter "$encounterId"',
        );
      }
      final existingEncounterOwner = assignedEncounterOwners[encounterId];
      if (existingEncounterOwner != null) {
        throw FormatException(
          'combat catalog source "${manifestSource.$1}": '
          '$path.encounter_id: duplicate assigned encounter id '
          '"$encounterId"; first declared at '
          'stage_assignments[$existingEncounterOwner].encounter_id',
        );
      }
      assignedEncounterOwners[encounterId] = i;
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
        'combat catalog source "${manifestSource.$1}": '
        '${_argumentErrorLeafPath(path, e)}: ${_argumentErrorMessage(e)}',
      );
    }
  }

  for (final source in parsedEncounterSources) {
    for (var i = 0; i < source.encounters.length; i++) {
      final id = source.encounters[i].id;
      if (!assignedEncounterOwners.containsKey(id)) {
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
      referenceIndex: referenceIndex,
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
  CombatCatalogReferenceIndex referenceIndex,
) {
  final variants = <CombatArchetypeVariant>[];
  final roleOwners = <String, int>{};
  for (var i = 0; i < entry.variants.length; i++) {
    final variant = entry.variants[i];
    final existingRoleOwner = roleOwners[variant.roleId];
    if (existingRoleOwner != null) {
      throw FormatException(
        'combat catalog source "$sourceName": '
        'archetypes[$index].variants[$i].role_id: duplicate role id '
        '"${variant.roleId}"; first declared at '
        'archetypes[$index].variants[$existingRoleOwner].role_id',
      );
    }
    roleOwners[variant.roleId] = i;
    final path = 'archetypes[$index].variants[$i]';
    _requireKnownReference(
      variant.attackSetId,
      referenceIndex.attackSetIds,
      sourceName,
      '$path.attack_set_id',
      'attack set',
    );
    for (var tagIndex = 0; tagIndex < variant.attackTagIds.length; tagIndex++) {
      _requireKnownReference(
        variant.attackTagIds[tagIndex],
        referenceIndex.attackTagIds,
        sourceName,
        '$path.attack_tag_ids[$tagIndex]',
        'attack tag',
      );
    }
    _requireKnownReference(
      variant.postureProfileId,
      referenceIndex.postureProfileIds,
      sourceName,
      '$path.posture_profile_id',
      'posture profile',
    );
    _requireKnownReference(
      variant.dropGroupId,
      referenceIndex.dropGroupIds,
      sourceName,
      '$path.drop_group_id',
      'drop group',
    );
    _requireKnownReference(
      variant.sfxGroupId,
      referenceIndex.sfxGroupIds,
      sourceName,
      '$path.sfx_group_id',
      'sfx group',
    );
    for (
      var visualIndex = 0;
      visualIndex < variant.visualVariantIds.length;
      visualIndex++
    ) {
      _requireKnownReference(
        variant.visualVariantIds[visualIndex],
        referenceIndex.visualVariantIds,
        sourceName,
        '$path.visual_variant_ids[$visualIndex]',
        'visual variant',
      );
    }
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
          attackSetId: variant.attackSetId,
          attackTagIds: variant.attackTagIds,
          postureProfileId: variant.postureProfileId,
          dropGroupId: variant.dropGroupId,
          sfxGroupId: variant.sfxGroupId,
          visualVariantIds: variant.visualVariantIds,
        ),
      );
    } on ArgumentError catch (e) {
      throw FormatException(
        'combat catalog source "$sourceName": '
        '${_argumentErrorLeafPath('archetypes[$index].variants[$i]', e)}: '
        '${_argumentErrorMessage(e)}',
      );
    }
  }
  try {
    return CombatEnemyArchetypeDef(id: entry.id, variants: variants);
  } on ArgumentError catch (e) {
    throw FormatException(
      'combat catalog source "$sourceName": '
      '${_argumentErrorLeafPath('archetypes[$index]', e)}: '
      '${_argumentErrorMessage(e)}',
    );
  }
}

CombatEncounterDef _buildEncounter(
  ParsedCombatEncounterEntry entry,
  String sourceName,
  int index,
  CombatCatalogReferenceIndex referenceIndex,
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
      'combat catalog source "$sourceName": '
      '${_argumentErrorLeafPath('$path.spawn_config', e)}: '
      '${_argumentErrorMessage(e)}',
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
      'combat catalog source "$sourceName": '
      '${_argumentErrorLeafPath('$path.token_budgets', e)}: '
      '${_argumentErrorMessage(e)}',
    );
  }

  final spawnEntries = <CombatEncounterSpawnEntry>[];
  final entryOwners = <String, int>{};
  for (var i = 0; i < entry.spawnEntries.length; i++) {
    final spawnEntry = entry.spawnEntries[i];
    final existingEntryOwner = entryOwners[spawnEntry.entryId];
    if (existingEntryOwner != null) {
      throw FormatException(
        'combat catalog source "$sourceName": '
        '$path.spawn_entries[$i].entry_id: duplicate spawn entry id '
        '"${spawnEntry.entryId}"; first declared at '
        '$path.spawn_entries[$existingEntryOwner].entry_id',
      );
    }
    entryOwners[spawnEntry.entryId] = i;
    try {
      spawnEntries.add(
        CombatEncounterSpawnEntry(
          entryId: spawnEntry.entryId,
          archetypeId: spawnEntry.archetypeId,
          roleId: spawnEntry.roleId,
          entranceId: spawnEntry.entranceId,
          positionId: spawnEntry.positionId,
          behaviorId: spawnEntry.behaviorId,
        ),
      );
    } on ArgumentError catch (e) {
      throw FormatException(
        'combat catalog source "$sourceName": '
        '${_argumentErrorLeafPath('$path.spawn_entries[$i]', e)}: '
        '${_argumentErrorMessage(e)}',
      );
    }
  }

  final objectives = _buildObjectiveComposition(
    entry.objectives,
    sourceName,
    '$path.objectives',
    referenceIndex,
  );

  try {
    return CombatEncounterDef(
      id: entry.id,
      spawnConfig: spawnConfig,
      tokenBudgets: tokenBudgets,
      spawnEntries: spawnEntries,
      objectives: objectives,
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'combat catalog source "$sourceName": '
      '${_argumentErrorLeafPath(path, e)}: ${_argumentErrorMessage(e)}',
    );
  }
}

CombatObjectiveCompositionRef _buildObjectiveComposition(
  ParsedCombatObjectiveComposition composition,
  String sourceName,
  String path,
  CombatCatalogReferenceIndex referenceIndex,
) {
  final clauses = <CombatObjectiveClauseRef>[];
  for (var i = 0; i < composition.clauses.length; i++) {
    final clause = composition.clauses[i];
    _validateObjectiveReferences(
      clause.primitive,
      referenceIndex,
      sourceName,
      '$path.clauses[$i]',
    );
    try {
      clauses.add(
        CombatObjectiveClauseRef(
          id: clause.id,
          primitive: _buildObjective(clause.primitive),
        ),
      );
    } on ArgumentError catch (e) {
      throw FormatException(
        'combat catalog source "$sourceName": '
        '${_argumentErrorLeafPath('$path.clauses[$i]', e)}: '
        '${_argumentErrorMessage(e)}',
      );
    }
  }
  try {
    return CombatObjectiveCompositionRef(
      completionRule: CombatObjectiveCompletionRule.values.byName(
        composition.completionRule,
      ),
      clauses: clauses,
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'combat catalog source "$sourceName": '
      '${_argumentErrorLeafPath(path, e)}: ${_argumentErrorMessage(e)}',
    );
  }
}

void _validateObjectiveReferences(
  ParsedCombatObjective objective,
  CombatCatalogReferenceIndex referenceIndex,
  String sourceName,
  String path,
) {
  switch (objective.kind) {
    case 'defeat_targets':
      _requireKnownReferenceList(
        objective.idList,
        referenceIndex.objectiveTargetIds,
        sourceName,
        '$path.target_ids',
        'objective target',
      );
    case 'destroy_anchors':
      _requireKnownReferenceList(
        objective.idList,
        referenceIndex.objectiveAnchorIds,
        sourceName,
        '$path.anchor_ids',
        'objective anchor',
      );
    case 'defend_entity':
      _requireKnownReference(
        objective.singleId!,
        referenceIndex.objectiveEntityIds,
        sourceName,
        '$path.entity_id',
        'objective entity',
      );
    case 'survive_duration':
      break;
    case 'reach_checkpoint':
      _requireKnownReferenceList(
        objective.idList,
        referenceIndex.objectiveCheckpointIds,
        sourceName,
        '$path.checkpoint_ids',
        'objective checkpoint',
      );
    case 'touch_markers':
      _requireKnownReferenceList(
        objective.idList,
        referenceIndex.objectiveMarkerIds,
        sourceName,
        '$path.marker_ids',
        'objective marker',
      );
    case 'pursue_target':
      _requireKnownReference(
        objective.singleId!,
        referenceIndex.objectiveTargetIds,
        sourceName,
        '$path.target_id',
        'objective target',
      );
    case 'defeat_commander':
      _requireKnownReference(
        objective.singleId!,
        referenceIndex.objectiveTargetIds,
        sourceName,
        '$path.commander_id',
        'objective target',
      );
  }
}

void _requireKnownReferenceList(
  List<String> ids,
  Set<String> knownIds,
  String sourceName,
  String path,
  String label,
) {
  for (var i = 0; i < ids.length; i++) {
    _requireKnownReference(ids[i], knownIds, sourceName, '$path[$i]', label);
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

void _requireKnownReference(
  String id,
  Set<String> knownIds,
  String sourceName,
  String path,
  String label,
) {
  if (!knownIds.contains(id)) {
    throw FormatException(
      'combat catalog source "$sourceName": $path: '
      'unknown $label reference "$id"',
    );
  }
}

String _argumentErrorText(ArgumentError error) {
  final message = error.message?.toString() ?? 'invalid argument';
  final name = error.name;
  return name == null || name.isEmpty ? message : '$name: $message';
}

String _argumentErrorLeafPath(String prefix, ArgumentError error) {
  final name = error.name;
  if (name == null || name.isEmpty) return prefix;
  final snakeCase = name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
  return '$prefix.$snakeCase';
}

String _argumentErrorMessage(ArgumentError error) =>
    error.message?.toString() ?? 'invalid argument';
