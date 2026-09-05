// Structural validator for the Phase 0A combat catalog YAML sources
// (P2-G2-L01). Pure and fail closed: every structural violation throws a
// FormatException whose message carries the source name and the offending
// field path. No defaults, no placeholders, no error swallowing.

import 'package:yaml/yaml.dart';

import '../yaml_loader.dart';

/// Allowed `attack_token_kind` values (S01 `CombatAttackTokenKind`).
const Set<String> combatAttackTokenKindNames = {
  'melee',
  'ranged',
  'charge',
  'support',
};

/// Allowed `migration_state` values (S01 `CombatEncounterMigrationState`).
const Set<String> combatMigrationStateNames = {'legacy', 'migrated'};

/// Allowed `objective.kind` values, one per O01 objective primitive.
const Set<String> combatObjectiveKindNames = {
  'defeat_targets',
  'destroy_anchors',
  'defend_entity',
  'survive_duration',
  'reach_checkpoint',
  'touch_markers',
  'pursue_target',
  'defeat_commander',
};

/// Allowed flat objective-composition completion rules.
const Set<String> combatObjectiveCompletionRuleNames = {'all', 'any'};

const Map<String, List<String>> _objectiveParamKeys = {
  'defeat_targets': ['target_ids'],
  'destroy_anchors': ['anchor_ids'],
  'defend_entity': [
    'entity_id',
    'position_id',
    'durability',
    'damage_per_hit',
    'required_ticks',
    'attacker_ids',
  ],
  'survive_duration': ['required_ticks'],
  'reach_checkpoint': ['checkpoint_ids'],
  'touch_markers': ['marker_ids'],
  'pursue_target': ['target_id'],
  'defeat_commander': ['commander_id'],
};

/// One fully parsed archetype document source.
final class ParsedCombatArchetypeSource {
  ParsedCombatArchetypeSource({
    required this.sourceName,
    required List<ParsedCombatArchetypeEntry> archetypes,
  }) : archetypes = List.unmodifiable(archetypes);

  final String sourceName;
  final List<ParsedCombatArchetypeEntry> archetypes;
}

/// One structurally valid archetype entry.
final class ParsedCombatArchetypeEntry {
  ParsedCombatArchetypeEntry({
    required this.id,
    required List<ParsedCombatArchetypeVariantEntry> variants,
  }) : variants = List.unmodifiable(variants);

  final String id;
  final List<ParsedCombatArchetypeVariantEntry> variants;
}

/// One structurally valid archetype variant role entry.
final class ParsedCombatArchetypeVariantEntry {
  ParsedCombatArchetypeVariantEntry({
    required this.roleId,
    required this.displayName,
    required this.attackTokenKind,
    required this.hpMultiplier,
    required this.attackMultiplier,
    required this.defenseMultiplier,
    required this.speedMultiplier,
    required this.attackSetId,
    required List<String> attackTagIds,
    required this.postureProfileId,
    required this.dropGroupId,
    required this.sfxGroupId,
    required List<String> visualVariantIds,
  }) : attackTagIds = List.unmodifiable(attackTagIds),
       visualVariantIds = List.unmodifiable(visualVariantIds);

  final String roleId;
  final String displayName;

  /// Raw enum name, already validated against [combatAttackTokenKindNames].
  final String attackTokenKind;
  final double hpMultiplier;
  final double attackMultiplier;
  final double defenseMultiplier;
  final double speedMultiplier;
  final String attackSetId;
  final List<String> attackTagIds;
  final String postureProfileId;
  final String dropGroupId;
  final String sfxGroupId;
  final List<String> visualVariantIds;
}

/// One fully parsed encounter document source.
final class ParsedCombatEncounterSource {
  ParsedCombatEncounterSource({
    required this.sourceName,
    required List<ParsedCombatEncounterEntry> encounters,
  }) : encounters = List.unmodifiable(encounters);

  final String sourceName;
  final List<ParsedCombatEncounterEntry> encounters;
}

/// One structurally valid encounter entry.
final class ParsedCombatEncounterEntry {
  ParsedCombatEncounterEntry({
    required this.id,
    required this.spawnConfig,
    required this.tokenBudgets,
    required List<ParsedCombatSpawnEntry> spawnEntries,
    required this.objectives,
  }) : spawnEntries = List.unmodifiable(spawnEntries);

  final String id;
  final ParsedCombatSpawnConfig spawnConfig;
  final ParsedCombatTokenBudgets tokenBudgets;
  final List<ParsedCombatSpawnEntry> spawnEntries;
  final ParsedCombatObjectiveComposition objectives;
}

/// The four explicit spawn-director configuration values.
final class ParsedCombatSpawnConfig {
  ParsedCombatSpawnConfig({
    required this.activeLimit,
    required this.reinforcementThreshold,
    required this.entryWarningTicks,
    required this.attackGraceTicks,
  });

  final int activeLimit;
  final int reinforcementThreshold;
  final int entryWarningTicks;
  final int attackGraceTicks;
}

/// The four explicit per-kind attack-token budgets.
final class ParsedCombatTokenBudgets {
  ParsedCombatTokenBudgets({
    required this.melee,
    required this.ranged,
    required this.charge,
    required this.support,
  });

  final int melee;
  final int ranged;
  final int charge;
  final int support;
}

/// One structurally valid spawn entry: an archetype variant role reference.
final class ParsedCombatSpawnEntry {
  ParsedCombatSpawnEntry({
    required this.entryId,
    required this.archetypeId,
    required this.roleId,
    required this.entranceId,
    required this.positionId,
    required this.behaviorId,
    this.preserveSourceContract = false,
    this.spawnAfterDefeated = const [],
  });

  final String entryId;
  final String archetypeId;
  final String roleId;
  final String entranceId;
  final String positionId;
  final String behaviorId;
  final bool preserveSourceContract;
  final List<String> spawnAfterDefeated;
}

/// One structurally valid flat objective composition.
final class ParsedCombatObjectiveComposition {
  ParsedCombatObjectiveComposition({
    required this.completionRule,
    required List<ParsedCombatObjectiveClause> clauses,
  }) : clauses = List.unmodifiable(clauses);

  final String completionRule;
  final List<ParsedCombatObjectiveClause> clauses;
}

/// One named primitive clause in a composition.
final class ParsedCombatObjectiveClause {
  ParsedCombatObjectiveClause({required this.id, required this.primitive});

  final String id;
  final ParsedCombatObjective primitive;
}

/// One structurally valid objective reference payload.
///
/// Exactly one of [idList], [singleId] or [requiredTicks] combinations is
/// populated, depending on [kind]; resolution into the sealed S01 reference
/// types happens in the loader.
final class ParsedCombatObjective {
  ParsedCombatObjective({
    required this.kind,
    List<String> idList = const [],
    this.singleId,
    this.positionId,
    this.durability,
    this.damagePerHit,
    List<String> attackerIds = const [],
    this.requiredTicks,
  }) : idList = List.unmodifiable(idList),
       attackerIds = List.unmodifiable(attackerIds);

  /// Raw enum name, already validated against [combatObjectiveKindNames].
  final String kind;
  final List<String> idList;
  final String? singleId;
  final String? positionId;
  final int? durability;
  final int? damagePerHit;
  final List<String> attackerIds;
  final int? requiredTicks;
}

/// One fully parsed stage-assignment manifest source.
final class ParsedCombatAssignmentSource {
  ParsedCombatAssignmentSource({
    required this.sourceName,
    required List<ParsedCombatAssignmentEntry> assignments,
  }) : assignments = List.unmodifiable(assignments);

  final String sourceName;
  final List<ParsedCombatAssignmentEntry> assignments;
}

/// One structurally valid stage assignment entry.
final class ParsedCombatAssignmentEntry {
  ParsedCombatAssignmentEntry({
    required this.stageId,
    required this.migrationState,
    this.encounterId,
  });

  final String stageId;

  /// Raw enum name, already validated against [combatMigrationStateNames].
  final String migrationState;

  /// Present exactly when [migrationState] is `migrated`.
  final String? encounterId;
}

/// Structurally validates one caller-provided archetype YAML source.
ParsedCombatArchetypeSource validateCombatArchetypeSource(
  String sourceName,
  String yamlContent,
) {
  final doc = _parseDocument(sourceName, yamlContent);
  _requireExactKeys(doc, const {'archetypes'}, '', sourceName);
  final list = _requireList(doc['archetypes'], 'archetypes', sourceName);
  final entries = <ParsedCombatArchetypeEntry>[];
  for (var i = 0; i < list.length; i++) {
    final path = 'archetypes[$i]';
    final map = _requireMap(list[i], path, sourceName);
    _requireExactKeys(map, const {'id', 'variants'}, path, sourceName);
    final id = _requireString(map['id'], '$path.id', sourceName);
    final variantsList = _requireList(
      map['variants'],
      '$path.variants',
      sourceName,
    );
    final variants = <ParsedCombatArchetypeVariantEntry>[];
    for (var j = 0; j < variantsList.length; j++) {
      final variantPath = '$path.variants[$j]';
      final variantMap = _requireMap(variantsList[j], variantPath, sourceName);
      _requireExactKeys(
        variantMap,
        const {
          'role_id',
          'display_name',
          'attack_token_kind',
          'hp_multiplier',
          'attack_multiplier',
          'defense_multiplier',
          'speed_multiplier',
          'attack_set_id',
          'attack_tag_ids',
          'posture_profile_id',
          'drop_group_id',
          'sfx_group_id',
          'visual_variant_ids',
        },
        variantPath,
        sourceName,
      );
      variants.add(
        ParsedCombatArchetypeVariantEntry(
          roleId: _requireString(
            variantMap['role_id'],
            '$variantPath.role_id',
            sourceName,
          ),
          displayName: _requireDisplayName(
            variantMap['display_name'],
            '$variantPath.display_name',
            sourceName,
          ),
          attackTokenKind: _requireEnum(
            variantMap['attack_token_kind'],
            '$variantPath.attack_token_kind',
            sourceName,
            combatAttackTokenKindNames,
            'attack token kind',
          ),
          hpMultiplier: _requireNumAsDouble(
            variantMap['hp_multiplier'],
            '$variantPath.hp_multiplier',
            sourceName,
          ),
          attackMultiplier: _requireNumAsDouble(
            variantMap['attack_multiplier'],
            '$variantPath.attack_multiplier',
            sourceName,
          ),
          defenseMultiplier: _requireNumAsDouble(
            variantMap['defense_multiplier'],
            '$variantPath.defense_multiplier',
            sourceName,
          ),
          speedMultiplier: _requireNumAsDouble(
            variantMap['speed_multiplier'],
            '$variantPath.speed_multiplier',
            sourceName,
          ),
          attackSetId: _requireString(
            variantMap['attack_set_id'],
            '$variantPath.attack_set_id',
            sourceName,
          ),
          attackTagIds: _requireIdList(
            variantMap['attack_tag_ids'],
            '$variantPath.attack_tag_ids',
            sourceName,
          ),
          postureProfileId: _requireString(
            variantMap['posture_profile_id'],
            '$variantPath.posture_profile_id',
            sourceName,
          ),
          dropGroupId: _requireString(
            variantMap['drop_group_id'],
            '$variantPath.drop_group_id',
            sourceName,
          ),
          sfxGroupId: _requireString(
            variantMap['sfx_group_id'],
            '$variantPath.sfx_group_id',
            sourceName,
          ),
          visualVariantIds: _requireIdList(
            variantMap['visual_variant_ids'],
            '$variantPath.visual_variant_ids',
            sourceName,
          ),
        ),
      );
    }
    entries.add(ParsedCombatArchetypeEntry(id: id, variants: variants));
  }
  return ParsedCombatArchetypeSource(
    sourceName: sourceName,
    archetypes: entries,
  );
}

/// Structurally validates one caller-provided encounter YAML source.
ParsedCombatEncounterSource validateCombatEncounterSource(
  String sourceName,
  String yamlContent,
) {
  final doc = _parseDocument(sourceName, yamlContent);
  _requireExactKeys(doc, const {'encounters'}, '', sourceName);
  final list = _requireList(doc['encounters'], 'encounters', sourceName);
  final entries = <ParsedCombatEncounterEntry>[];
  for (var i = 0; i < list.length; i++) {
    final path = 'encounters[$i]';
    final map = _requireMap(list[i], path, sourceName);
    _requireExactKeys(
      map,
      const {
        'id',
        'spawn_config',
        'token_budgets',
        'spawn_entries',
        'objectives',
      },
      path,
      sourceName,
    );
    final id = _requireString(map['id'], '$path.id', sourceName);

    final configMap = _requireMap(
      map['spawn_config'],
      '$path.spawn_config',
      sourceName,
    );
    _requireExactKeys(
      configMap,
      const {
        'active_limit',
        'reinforcement_threshold',
        'entry_warning_ticks',
        'attack_grace_ticks',
      },
      '$path.spawn_config',
      sourceName,
    );
    final spawnConfig = ParsedCombatSpawnConfig(
      activeLimit: _requireInt(
        configMap['active_limit'],
        '$path.spawn_config.active_limit',
        sourceName,
      ),
      reinforcementThreshold: _requireInt(
        configMap['reinforcement_threshold'],
        '$path.spawn_config.reinforcement_threshold',
        sourceName,
      ),
      entryWarningTicks: _requireInt(
        configMap['entry_warning_ticks'],
        '$path.spawn_config.entry_warning_ticks',
        sourceName,
      ),
      attackGraceTicks: _requireInt(
        configMap['attack_grace_ticks'],
        '$path.spawn_config.attack_grace_ticks',
        sourceName,
      ),
    );

    final budgetsMap = _requireMap(
      map['token_budgets'],
      '$path.token_budgets',
      sourceName,
    );
    _requireExactKeys(
      budgetsMap,
      const {'melee', 'ranged', 'charge', 'support'},
      '$path.token_budgets',
      sourceName,
    );
    final tokenBudgets = ParsedCombatTokenBudgets(
      melee: _requireInt(
        budgetsMap['melee'],
        '$path.token_budgets.melee',
        sourceName,
      ),
      ranged: _requireInt(
        budgetsMap['ranged'],
        '$path.token_budgets.ranged',
        sourceName,
      ),
      charge: _requireInt(
        budgetsMap['charge'],
        '$path.token_budgets.charge',
        sourceName,
      ),
      support: _requireInt(
        budgetsMap['support'],
        '$path.token_budgets.support',
        sourceName,
      ),
    );

    final entriesList = _requireList(
      map['spawn_entries'],
      '$path.spawn_entries',
      sourceName,
    );
    final spawnEntries = <ParsedCombatSpawnEntry>[];
    for (var j = 0; j < entriesList.length; j++) {
      final entryPath = '$path.spawn_entries[$j]';
      final entryMap = _requireMap(entriesList[j], entryPath, sourceName);
      _requireExactKeys(
        entryMap,
        const {
          'entry_id',
          'archetype_id',
          'role_id',
          'entrance_id',
          'position_id',
          'behavior_id',
        },
        entryPath,
        sourceName,
        optional: const {'preserve_source_contract', 'spawn_after_defeated'},
      );
      spawnEntries.add(
        ParsedCombatSpawnEntry(
          entryId: _requireString(
            entryMap['entry_id'],
            '$entryPath.entry_id',
            sourceName,
          ),
          archetypeId: _requireString(
            entryMap['archetype_id'],
            '$entryPath.archetype_id',
            sourceName,
          ),
          roleId: _requireString(
            entryMap['role_id'],
            '$entryPath.role_id',
            sourceName,
          ),
          entranceId: _requireString(
            entryMap['entrance_id'],
            '$entryPath.entrance_id',
            sourceName,
          ),
          positionId: _requireString(
            entryMap['position_id'],
            '$entryPath.position_id',
            sourceName,
          ),
          behaviorId: _requireString(
            entryMap['behavior_id'],
            '$entryPath.behavior_id',
            sourceName,
          ),
          preserveSourceContract:
              entryMap.containsKey('preserve_source_contract')
              ? _requireBool(
                  entryMap['preserve_source_contract'],
                  '$entryPath.preserve_source_contract',
                  sourceName,
                )
              : false,
          spawnAfterDefeated: entryMap.containsKey('spawn_after_defeated')
              ? _requireIdList(
                  entryMap['spawn_after_defeated'],
                  '$entryPath.spawn_after_defeated',
                  sourceName,
                )
              : const [],
        ),
      );
    }

    final objectives = _parseObjectiveComposition(
      map['objectives'],
      '$path.objectives',
      sourceName,
    );
    entries.add(
      ParsedCombatEncounterEntry(
        id: id,
        spawnConfig: spawnConfig,
        tokenBudgets: tokenBudgets,
        spawnEntries: spawnEntries,
        objectives: objectives,
      ),
    );
  }
  return ParsedCombatEncounterSource(
    sourceName: sourceName,
    encounters: entries,
  );
}

/// Structurally validates the single caller-provided manifest YAML source.
ParsedCombatAssignmentSource validateCombatAssignmentSource(
  String sourceName,
  String yamlContent,
) {
  final doc = _parseDocument(sourceName, yamlContent);
  _requireExactKeys(doc, const {'stage_assignments'}, '', sourceName);
  final list = _requireList(
    doc['stage_assignments'],
    'stage_assignments',
    sourceName,
  );
  final entries = <ParsedCombatAssignmentEntry>[];
  for (var i = 0; i < list.length; i++) {
    final path = 'stage_assignments[$i]';
    final map = _requireMap(list[i], path, sourceName);
    if (!map.containsKey('migration_state')) {
      _fail(sourceName, path, 'missing required key "migration_state"');
    }
    final migrationState = _requireEnum(
      map['migration_state'],
      '$path.migration_state',
      sourceName,
      combatMigrationStateNames,
      'migration state',
    );
    final allowedKeys = migrationState == 'legacy'
        ? const {'stage_id', 'migration_state'}
        : const {'stage_id', 'migration_state', 'encounter_id'};
    _requireExactKeys(map, allowedKeys, path, sourceName);
    entries.add(
      ParsedCombatAssignmentEntry(
        stageId: _requireString(map['stage_id'], '$path.stage_id', sourceName),
        migrationState: migrationState,
        encounterId: migrationState == 'legacy'
            ? null
            : _requireString(
                map['encounter_id'],
                '$path.encounter_id',
                sourceName,
              ),
      ),
    );
  }
  return ParsedCombatAssignmentSource(
    sourceName: sourceName,
    assignments: entries,
  );
}

ParsedCombatObjectiveComposition _parseObjectiveComposition(
  dynamic value,
  String path,
  String sourceName,
) {
  final map = _requireMap(value, path, sourceName);
  _requireExactKeys(
    map,
    const {'completion_rule', 'clauses'},
    path,
    sourceName,
  );
  final completionRule = _requireEnum(
    map['completion_rule'],
    '$path.completion_rule',
    sourceName,
    combatObjectiveCompletionRuleNames,
    'objective completion rule',
  );
  final rawClauses = _requireList(map['clauses'], '$path.clauses', sourceName);
  final clauses = <ParsedCombatObjectiveClause>[];
  final owners = <String, int>{};
  for (var i = 0; i < rawClauses.length; i++) {
    final clausePath = '$path.clauses[$i]';
    final clauseMap = _requireMap(rawClauses[i], clausePath, sourceName);
    if (!clauseMap.containsKey('id')) {
      _fail(sourceName, clausePath, 'missing required key "id"');
    }
    final id = _requireString(clauseMap['id'], '$clausePath.id', sourceName);
    final existingOwner = owners[id];
    if (existingOwner != null) {
      _fail(
        sourceName,
        '$clausePath.id',
        'duplicate objective clause id "$id"; first declared at '
            '$path.clauses[$existingOwner].id',
      );
    }
    owners[id] = i;
    final primitiveMap = Map<String, dynamic>.from(clauseMap)..remove('id');
    clauses.add(
      ParsedCombatObjectiveClause(
        id: id,
        primitive: _parseObjective(primitiveMap, clausePath, sourceName),
      ),
    );
  }
  return ParsedCombatObjectiveComposition(
    completionRule: completionRule,
    clauses: clauses,
  );
}

ParsedCombatObjective _parseObjective(
  dynamic value,
  String path,
  String sourceName,
) {
  final map = _requireMap(value, path, sourceName);
  if (!map.containsKey('kind')) {
    _fail(sourceName, path, 'missing required key "kind"');
  }
  final kind = _requireEnum(
    map['kind'],
    '$path.kind',
    sourceName,
    combatObjectiveKindNames,
    'objective kind',
  );
  final paramKeys = _objectiveParamKeys[kind]!;
  final allowedKeys = {'kind', ...paramKeys};
  final unknown = map.keys.where((key) => !allowedKeys.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    _fail(
      sourceName,
      path,
      'unknown key(s) for objective kind "$kind": ${unknown.join(', ')}',
    );
  }
  final missing = paramKeys.where((key) => !map.containsKey(key)).toList()
    ..sort();
  if (missing.isNotEmpty) {
    _fail(sourceName, path, _missingKeyDetail(missing));
  }
  switch (kind) {
    case 'defeat_targets':
      return ParsedCombatObjective(
        kind: kind,
        idList: _requireIdList(
          map['target_ids'],
          '$path.target_ids',
          sourceName,
        ),
      );
    case 'destroy_anchors':
      return ParsedCombatObjective(
        kind: kind,
        idList: _requireIdList(
          map['anchor_ids'],
          '$path.anchor_ids',
          sourceName,
        ),
      );
    case 'reach_checkpoint':
      return ParsedCombatObjective(
        kind: kind,
        idList: _requireIdList(
          map['checkpoint_ids'],
          '$path.checkpoint_ids',
          sourceName,
        ),
      );
    case 'touch_markers':
      return ParsedCombatObjective(
        kind: kind,
        idList: _requireIdList(
          map['marker_ids'],
          '$path.marker_ids',
          sourceName,
        ),
      );
    case 'defend_entity':
      return ParsedCombatObjective(
        kind: kind,
        singleId: _requireString(
          map['entity_id'],
          '$path.entity_id',
          sourceName,
        ),
        positionId: _requireString(
          map['position_id'],
          '$path.position_id',
          sourceName,
        ),
        durability: _requireInt(
          map['durability'],
          '$path.durability',
          sourceName,
        ),
        damagePerHit: _requireInt(
          map['damage_per_hit'],
          '$path.damage_per_hit',
          sourceName,
        ),
        requiredTicks: _requireInt(
          map['required_ticks'],
          '$path.required_ticks',
          sourceName,
        ),
        attackerIds: _requireIdList(
          map['attacker_ids'],
          '$path.attacker_ids',
          sourceName,
        ),
      );
    case 'survive_duration':
      return ParsedCombatObjective(
        kind: kind,
        requiredTicks: _requireInt(
          map['required_ticks'],
          '$path.required_ticks',
          sourceName,
        ),
      );
    case 'pursue_target':
      return ParsedCombatObjective(
        kind: kind,
        singleId: _requireString(
          map['target_id'],
          '$path.target_id',
          sourceName,
        ),
      );
    case 'defeat_commander':
      return ParsedCombatObjective(
        kind: kind,
        singleId: _requireString(
          map['commander_id'],
          '$path.commander_id',
          sourceName,
        ),
      );
  }
  throw StateError('unreachable objective kind "$kind"');
}

Map<String, dynamic> _parseDocument(String sourceName, String content) {
  final dynamic converted;
  try {
    converted = deepConvertYaml(loadYaml(content));
  } on FormatException catch (e) {
    throw FormatException(
      'combat catalog source "$sourceName": document root: ${e.message}',
    );
  }
  if (converted is! Map<String, dynamic>) {
    _fail(
      sourceName,
      '',
      'top level must be a map, got ${_typeName(converted)}',
    );
  }
  return converted;
}

void _requireExactKeys(
  Map<String, dynamic> map,
  Set<String> allowed,
  String path,
  String sourceName, {
  Set<String> optional = const {},
}) {
  final unknown =
      map.keys
          .where((key) => !allowed.contains(key) && !optional.contains(key))
          .toList()
        ..sort();
  if (unknown.isNotEmpty) {
    _fail(
      sourceName,
      path,
      'unknown key(s): ${unknown.join(', ')} (allowed: ${allowed.join(', ')})',
    );
  }
  final missing = allowed.where((key) => !map.containsKey(key)).toList()
    ..sort();
  if (missing.isNotEmpty) {
    _fail(sourceName, path, _missingKeyDetail(missing));
  }
}

String _missingKeyDetail(List<String> missing) {
  if (missing.length == 1) return 'missing required key "${missing.single}"';
  return 'missing required key(s): ${missing.join(', ')}';
}

List<dynamic> _requireList(dynamic value, String path, String sourceName) {
  if (value is! List) {
    _fail(sourceName, path, 'expected a list, got ${_typeName(value)}');
  }
  if (value.isEmpty) {
    _fail(sourceName, path, 'must not be empty');
  }
  return value;
}

Map<String, dynamic> _requireMap(
  dynamic value,
  String path,
  String sourceName,
) {
  if (value is! Map<String, dynamic>) {
    _fail(sourceName, path, 'expected a map, got ${_typeName(value)}');
  }
  return value;
}

String _requireString(dynamic value, String path, String sourceName) {
  if (value is! String) {
    _fail(sourceName, path, 'expected a string, got ${_typeName(value)}');
  }
  if (value.trim().isEmpty) {
    _fail(sourceName, path, 'must not be empty');
  }
  if (RegExp(r'\s').hasMatch(value)) {
    _fail(sourceName, path, 'must not contain whitespace');
  }
  return value;
}

String _requireDisplayName(dynamic value, String path, String sourceName) {
  if (value is! String) {
    _fail(sourceName, path, 'expected a string, got ${_typeName(value)}');
  }
  if (value.trim().isEmpty) {
    _fail(sourceName, path, 'must not be empty');
  }
  if (value != value.trim()) {
    _fail(sourceName, path, 'must not contain leading or trailing whitespace');
  }
  return value;
}

int _requireInt(dynamic value, String path, String sourceName) {
  if (value is! int) {
    _fail(sourceName, path, 'expected an integer, got ${_typeName(value)}');
  }
  return value;
}

bool _requireBool(dynamic value, String path, String sourceName) {
  if (value is! bool) {
    _fail(sourceName, path, 'expected a boolean, got ${_typeName(value)}');
  }
  return value;
}

double _requireNumAsDouble(dynamic value, String path, String sourceName) {
  if (value is num) {
    final result = value.toDouble();
    if (!result.isFinite) {
      _fail(sourceName, path, 'must be finite');
    }
    return result;
  }
  _fail(sourceName, path, 'expected a number, got ${_typeName(value)}');
}

String _requireEnum(
  dynamic value,
  String path,
  String sourceName,
  Set<String> allowed,
  String label,
) {
  final name = _requireString(value, path, sourceName);
  if (!allowed.contains(name)) {
    _fail(
      sourceName,
      path,
      'unknown $label "$name" (allowed: ${allowed.join(', ')})',
    );
  }
  return name;
}

List<String> _requireIdList(dynamic value, String path, String sourceName) {
  final list = _requireList(value, path, sourceName);
  final result = <String>[];
  final owners = <String, int>{};
  for (var i = 0; i < list.length; i++) {
    final id = _requireString(list[i], '$path[$i]', sourceName);
    final existingOwner = owners[id];
    if (existingOwner != null) {
      _fail(
        sourceName,
        '$path[$i]',
        'duplicate id "$id"; first declared at $path[$existingOwner]',
      );
    }
    owners[id] = i;
    result.add(id);
  }
  return result;
}

String _typeName(dynamic value) => value?.runtimeType.toString() ?? 'null';

Never _fail(String sourceName, String path, String detail) {
  final location = path.isEmpty ? 'document root' : path;
  throw FormatException(
    'combat catalog source "$sourceName": $location: $detail',
  );
}
