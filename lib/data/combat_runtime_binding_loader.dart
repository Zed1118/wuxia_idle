import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'defs/combat_catalog_manifest_def.dart';
import 'defs/combat_encounter_def.dart';
import 'defs/combat_enemy_archetype_def.dart';
import 'defs/combat_runtime_binding_def.dart';
import 'defs/skill_def.dart';
import 'defs/stage_def.dart';
import 'yaml_loader.dart';

enum CombatRuntimeBindingLoadFailureKind {
  manifestRead,
  manifestInvalid,
  sourceMissing,
  sourceRead,
  bindingInvalid,
  closureInvalid,
}

final class CombatRuntimeBindingLoadException extends FormatException {
  CombatRuntimeBindingLoadException({
    required this.kind,
    required this.path,
    required String message,
    this.cause,
  }) : super(message);

  final CombatRuntimeBindingLoadFailureKind kind;
  final String path;
  final Object? cause;
}

/// Loads the root-referenced production runtime binding and resolves all
/// host-facing references to typed catalog/SkillDef/asset values.
Future<CombatRuntimeBindingCatalog> loadProductionCombatRuntimeBindings({
  required Future<String> Function(String path) load,
  required CombatCatalogManifestDef manifest,
  required Map<String, StageDef> stageDefs,
  required Map<String, SkillDef> skillDefs,
  required CombatRuntimeArenaBounds arenaBounds,
  Future<bool> Function(String path)? assetExists,
}) async {
  const manifestPath = 'data/combat/manifest.yaml';
  final String rootRaw;
  try {
    rootRaw = await load(manifestPath);
  } catch (error) {
    final kind = _isMissingAssetError(error)
        ? CombatRuntimeBindingLoadFailureKind.sourceMissing
        : CombatRuntimeBindingLoadFailureKind.manifestRead;
    throw CombatRuntimeBindingLoadException(
      kind: kind,
      path: manifestPath,
      cause: error,
      message: 'production runtime binding manifest cannot be read: $error',
    );
  }

  late final String bindingPath;
  try {
    final root = parseYamlMap(rootRaw);
    final raw = root['runtime_bindings_source'];
    if (raw is! String || raw.trim().isEmpty || _hasWhitespace(raw)) {
      throw const FormatException(
        'manifest.runtime_bindings_source must be a non-empty path',
      );
    }
    bindingPath = raw;
  } catch (error) {
    throw CombatRuntimeBindingLoadException(
      kind: CombatRuntimeBindingLoadFailureKind.manifestInvalid,
      path: manifestPath,
      cause: error,
      message: 'production runtime binding manifest is invalid: $error',
    );
  }

  final String raw;
  try {
    raw = await load(bindingPath);
  } catch (error) {
    final kind = _isMissingAssetError(error)
        ? CombatRuntimeBindingLoadFailureKind.sourceMissing
        : CombatRuntimeBindingLoadFailureKind.sourceRead;
    throw CombatRuntimeBindingLoadException(
      kind: kind,
      path: bindingPath,
      cause: error,
      message: 'production runtime binding source cannot be read: $error',
    );
  }

  try {
    return await loadCombatRuntimeBindings(
      sourceName: bindingPath,
      yaml: raw,
      manifest: manifest,
      stageDefs: stageDefs,
      skillDefs: skillDefs,
      arenaBounds: arenaBounds,
      assetExists: assetExists ?? _rootBundleAssetExists,
    );
  } on CombatRuntimeBindingLoadException {
    rethrow;
  } on FormatException catch (error) {
    throw CombatRuntimeBindingLoadException(
      kind: CombatRuntimeBindingLoadFailureKind.bindingInvalid,
      path: bindingPath,
      cause: error,
      message: 'production runtime binding is invalid: $error',
    );
  } on ArgumentError catch (error) {
    throw CombatRuntimeBindingLoadException(
      kind: CombatRuntimeBindingLoadFailureKind.bindingInvalid,
      path: bindingPath,
      cause: error,
      message: 'production runtime binding is invalid: $error',
    );
  }
}

/// Pure parser/validator used by production and focused contract tests.
Future<CombatRuntimeBindingCatalog> loadCombatRuntimeBindings({
  required String sourceName,
  required String yaml,
  required CombatCatalogManifestDef manifest,
  required Map<String, StageDef> stageDefs,
  required Map<String, SkillDef> skillDefs,
  required CombatRuntimeArenaBounds arenaBounds,
  required Future<bool> Function(String path) assetExists,
}) async {
  final root = parseYamlMap(yaml);
  final rawBindings = root['runtime_bindings'];
  if (rawBindings is! List || rawBindings.isEmpty) {
    throw FormatException(
      '$sourceName: runtime_bindings must be a non-empty list',
    );
  }
  final bindings = <CombatRuntimeStageBinding>[];
  final stageIds = <String>{};
  final encounterIds = <String>{};
  for (var index = 0; index < rawBindings.length; index++) {
    final raw = _map(
      rawBindings[index],
      '$sourceName.runtime_bindings[$index]',
    );
    final stageId = _requiredString(
      raw,
      'stage_id',
      '$sourceName.runtime_bindings[$index]',
    );
    final encounterId = _requiredString(
      raw,
      'encounter_id',
      '$sourceName.runtime_bindings[$index]',
    );
    if (!stageIds.add(stageId)) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index].stage_id: duplicate "$stageId"',
      );
    }
    if (!encounterIds.add(encounterId)) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index].encounter_id: duplicate "$encounterId"',
      );
    }

    final assignment = manifest.assignmentForStage(stageId);
    if (assignment == null) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index].stage_id: unknown stage "$stageId"',
      );
    }
    if (assignment.migrationState != CombatEncounterMigrationState.migrated) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index].stage_id: legacy stage "$stageId" cannot have a runtime binding',
      );
    }
    if (assignment.encounterId != encounterId) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index].encounter_id: expected "${assignment.encounterId}", got "$encounterId"',
      );
    }
    final encounter = manifest.encounterById(encounterId);
    if (encounter == null) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index].encounter_id: unknown encounter "$encounterId"',
      );
    }

    final baseEnemyId = _requiredString(
      raw,
      'base_enemy_id',
      '$sourceName.runtime_bindings[$index]',
    );
    final stageDef = stageDefs[stageId];
    if (stageDef == null) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index].stage_id: missing production StageDef "$stageId"',
      );
    }
    if (stageDef.enemyTeam.length != 1 ||
        stageDef.enemyTeam.single.id != baseEnemyId) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index].base_enemy_id: expected the exact single StageDef.enemyTeam template for "$stageId", got "$baseEnemyId"',
      );
    }

    final entrances = _parsePoints(
      raw,
      'entrances',
      sourceName,
      index,
      'spawn_position',
      arenaBounds,
    );
    final positions = _parsePoints(
      raw,
      'positions',
      sourceName,
      index,
      'world_position',
      arenaBounds,
    );
    final aiProfiles = _parseAiProfiles(raw, sourceName, index);
    final behaviors = _parseBehaviors(raw, aiProfiles, sourceName, index);
    final attackSets = _parseAttackSets(raw, skillDefs, sourceName, index);
    final visualVariants = await _parseVisualVariants(
      raw,
      sourceName,
      index,
      assetExists,
    );
    final verifiedOnly = _parseVerifiedOnly(
      raw,
      manifest,
      encounter,
      sourceName,
      index,
    );

    final stageBinding = _resolveStageBinding(
      stageId: stageId,
      encounter: encounter,
      manifest: manifest,
      baseEnemyId: baseEnemyId,
      entrances: entrances,
      positions: positions,
      behaviors: behaviors,
      aiProfiles: aiProfiles,
      attackSets: attackSets,
      visualVariants: visualVariants,
      verifiedOnlyReferences: verifiedOnly,
      sourceName: sourceName,
      index: index,
    );
    bindings.add(stageBinding);
  }

  for (final assignment in manifest.stageAssignments) {
    if (assignment.migrationState == CombatEncounterMigrationState.migrated &&
        !stageIds.contains(assignment.stageId)) {
      throw FormatException(
        '$sourceName.runtime_bindings: migrated stage "${assignment.stageId}" has no runtime binding',
      );
    }
  }
  return CombatRuntimeBindingCatalog(bindings);
}

CombatRuntimeStageBinding _resolveStageBinding({
  required String stageId,
  required CombatEncounterDef encounter,
  required CombatCatalogManifestDef manifest,
  required String baseEnemyId,
  required Map<String, CombatRuntimePoint> entrances,
  required Map<String, CombatRuntimePoint> positions,
  required Map<String, CombatRuntimeBehaviorBinding> behaviors,
  required Map<String, CombatRuntimeAiProfile> aiProfiles,
  required Map<String, CombatRuntimeAttackSet> attackSets,
  required Map<String, CombatRuntimeVisualVariant> visualVariants,
  required CombatRuntimeVerifiedOnlyReferences verifiedOnlyReferences,
  required String sourceName,
  required int index,
}) {
  final usedEntrances = encounter.spawnEntries
      .map((entry) => entry.entranceId)
      .toSet();
  final usedPositions = encounter.spawnEntries
      .map((entry) => entry.positionId)
      .toSet();
  for (final clause in encounter.objectives.clauses) {
    if (clause.primitive case CombatDefendEntityRef(:final positionId)) {
      usedPositions.add(positionId);
    }
  }
  final usedBehaviors = encounter.spawnEntries
      .map((entry) => entry.behaviorId)
      .toSet();
  final archetypeVariants = <CombatEnemyArchetypeDef>[];
  final usedAttackSets = <String>{};
  final usedVisualVariants = <String>{};
  for (final entry in encounter.spawnEntries) {
    final archetype = manifest.archetypeById(entry.archetypeId);
    if (archetype == null) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index]: unknown archetype "${entry.archetypeId}"',
      );
    }
    archetypeVariants.add(archetype);
    final variant = archetype.variantByRole(entry.roleId)!;
    usedAttackSets.add(variant.attackSetId);
    usedVisualVariants.addAll(variant.visualVariantIds);
  }

  _requireExactIds(
    usedEntrances,
    entrances.keys,
    '$sourceName.runtime_bindings[$index].entrances',
  );
  _requireExactIds(
    usedPositions,
    positions.keys,
    '$sourceName.runtime_bindings[$index].positions',
  );
  _requireExactIds(
    usedBehaviors,
    behaviors.keys,
    '$sourceName.runtime_bindings[$index].behaviors',
  );
  _requireExactIds(
    usedAttackSets,
    attackSets.keys,
    '$sourceName.runtime_bindings[$index].attack_sets',
  );
  _requireExactIds(
    usedVisualVariants,
    visualVariants.keys,
    '$sourceName.runtime_bindings[$index].visual_variants',
  );

  final enemyBindings = <CombatRuntimeEnemyBinding>[];
  final entryIds = <String>{};
  final visualUseCounts = <String, int>{};
  for (var i = 0; i < encounter.spawnEntries.length; i++) {
    final entry = encounter.spawnEntries[i];
    if (!entryIds.add(entry.entryId)) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index]: duplicate encounter entry "${entry.entryId}"',
      );
    }
    final archetype = archetypeVariants[i];
    final variant = archetype.variantByRole(entry.roleId)!;
    final behavior = behaviors[entry.behaviorId]!;
    if (behavior.tokenPolicy.name != variant.attackTokenKind.name) {
      throw FormatException(
        '$sourceName.runtime_bindings[$index].behaviors[${entry.behaviorId}]: token policy does not match ${entry.roleId}',
      );
    }
    final visualIds = variant.visualVariantIds.toList(growable: false);
    final useIndex = visualUseCounts.update(
      entry.roleId,
      (count) => count + 1,
      ifAbsent: () => 0,
    );
    enemyBindings.add(
      CombatRuntimeEnemyBinding(
        entryId: entry.entryId,
        baseEnemyId: baseEnemyId,
        archetypeId: entry.archetypeId,
        roleId: entry.roleId,
        entranceId: entry.entranceId,
        entrance: entrances[entry.entranceId]!,
        positionId: entry.positionId,
        position: positions[entry.positionId]!,
        behavior: behavior,
        attackSet: attackSets[variant.attackSetId]!,
        visualVariant: visualVariants[visualIds[useIndex % visualIds.length]]!,
      ),
    );
  }
  return CombatRuntimeStageBinding(
    stageId: stageId,
    encounterId: encounter.id,
    baseEnemyId: baseEnemyId,
    entrances: entrances,
    positions: positions,
    behaviors: behaviors,
    aiProfiles: aiProfiles,
    attackSets: attackSets,
    visualVariants: visualVariants,
    enemyBindings: enemyBindings,
    verifiedOnlyReferences: verifiedOnlyReferences,
  );
}

Map<String, CombatRuntimePoint> _parsePoints(
  Map<String, dynamic> root,
  String field,
  String sourceName,
  int index,
  String pointField,
  CombatRuntimeArenaBounds arenaBounds,
) {
  final raw = root[field];
  if (raw is! List || raw.isEmpty) {
    throw FormatException(
      '$sourceName.runtime_bindings[$index].$field must be a non-empty list',
    );
  }
  final result = <String, CombatRuntimePoint>{};
  for (var i = 0; i < raw.length; i++) {
    final map = _map(raw[i], '$sourceName.runtime_bindings[$index].$field[$i]');
    final id = _requiredString(
      map,
      'id',
      '$sourceName.runtime_bindings[$index].$field[$i]',
    );
    if (result.containsKey(id)) {
      throw FormatException('$sourceName...$field[$i].id: duplicate "$id"');
    }
    final point = _map(map[pointField], '$sourceName...$field[$i].$pointField');
    final x = _finiteNumber(
      point['x'],
      '$sourceName...$field[$i].$pointField.x',
    );
    final y = _finiteNumber(
      point['y'],
      '$sourceName...$field[$i].$pointField.y',
    );
    if (!arenaBounds.contains(x, y)) {
      throw FormatException(
        '$sourceName...$field[$i].$pointField: coordinate ($x, $y) is outside arena bounds',
      );
    }
    result[id] = CombatRuntimePoint(x: x, y: y);
  }
  return result;
}

Map<String, CombatRuntimeAiProfile> _parseAiProfiles(
  Map<String, dynamic> root,
  String sourceName,
  int index,
) {
  final raw = root['ai_profiles'];
  if (raw is! List || raw.isEmpty) {
    throw FormatException('$sourceName...ai_profiles must be a non-empty list');
  }
  final result = <String, CombatRuntimeAiProfile>{};
  for (var i = 0; i < raw.length; i++) {
    final map = _map(
      raw[i],
      '$sourceName.runtime_bindings[$index].ai_profiles[$i]',
    );
    final id = _requiredString(map, 'id', '$sourceName...ai_profiles[$i]');
    if (result.containsKey(id)) {
      throw FormatException(
        '$sourceName...ai_profiles[$i].id: duplicate "$id"',
      );
    }
    result[id] = CombatRuntimeAiProfile(
      id: id,
      targetPolicy: _enumValue(
        CombatRuntimeTargetPolicy.values,
        _requiredString(map, 'target_policy', '$sourceName...ai_profiles[$i]'),
        '$sourceName...ai_profiles[$i].target_policy',
      ),
      movementPolicy: _enumValue(
        CombatRuntimeMovementPolicy.values,
        _requiredString(
          map,
          'movement_policy',
          '$sourceName...ai_profiles[$i]',
        ),
        '$sourceName...ai_profiles[$i].movement_policy',
      ),
      attackPolicy: _enumValue(
        CombatRuntimeAttackPolicy.values,
        _requiredString(map, 'attack_policy', '$sourceName...ai_profiles[$i]'),
        '$sourceName...ai_profiles[$i].attack_policy',
      ),
    );
  }
  return result;
}

Map<String, CombatRuntimeBehaviorBinding> _parseBehaviors(
  Map<String, dynamic> root,
  Map<String, CombatRuntimeAiProfile> aiProfiles,
  String sourceName,
  int index,
) {
  final raw = root['behaviors'];
  if (raw is! List || raw.isEmpty) {
    throw FormatException('$sourceName...behaviors must be a non-empty list');
  }
  final result = <String, CombatRuntimeBehaviorBinding>{};
  for (var i = 0; i < raw.length; i++) {
    final map = _map(
      raw[i],
      '$sourceName.runtime_bindings[$index].behaviors[$i]',
    );
    final id = _requiredString(map, 'id', '$sourceName...behaviors[$i]');
    if (result.containsKey(id)) {
      throw FormatException('$sourceName...behaviors[$i].id: duplicate "$id"');
    }
    final aiId = _requiredString(
      map,
      'ai_profile_id',
      '$sourceName...behaviors[$i]',
    );
    final ai = aiProfiles[aiId];
    if (ai == null) {
      throw FormatException(
        '$sourceName...behaviors[$i].ai_profile_id: unknown "$aiId"',
      );
    }
    result[id] = CombatRuntimeBehaviorBinding(
      id: id,
      aiProfile: ai,
      tokenPolicy: _enumValue(
        CombatRuntimeTokenPolicy.values,
        _requiredString(map, 'token_policy', '$sourceName...behaviors[$i]'),
        '$sourceName...behaviors[$i].token_policy',
      ),
      priority: _requiredInt(map, 'priority', '$sourceName...behaviors[$i]'),
      isOffscreen: _requiredBool(
        map,
        'is_offscreen',
        '$sourceName...behaviors[$i]',
      ),
      isHighImpact: _requiredBool(
        map,
        'is_high_impact',
        '$sourceName...behaviors[$i]',
      ),
      isUnblockableArea: _requiredBool(
        map,
        'is_unblockable_area',
        '$sourceName...behaviors[$i]',
      ),
      spawnGraceTicksRemaining: _requiredInt(
        map,
        'spawn_grace_ticks_remaining',
        '$sourceName...behaviors[$i]',
      ),
      telegraphReady: _requiredBool(
        map,
        'telegraph_ready',
        '$sourceName...behaviors[$i]',
      ),
    );
  }
  return result;
}

Map<String, CombatRuntimeAttackSet> _parseAttackSets(
  Map<String, dynamic> root,
  Map<String, SkillDef> skillDefs,
  String sourceName,
  int index,
) {
  final raw = root['attack_sets'];
  if (raw is! List || raw.isEmpty) {
    throw FormatException('$sourceName...attack_sets must be a non-empty list');
  }
  final result = <String, CombatRuntimeAttackSet>{};
  for (var i = 0; i < raw.length; i++) {
    final map = _map(
      raw[i],
      '$sourceName.runtime_bindings[$index].attack_sets[$i]',
    );
    final id = _requiredString(map, 'id', '$sourceName...attack_sets[$i]');
    if (result.containsKey(id)) {
      throw FormatException(
        '$sourceName...attack_sets[$i].id: duplicate "$id"',
      );
    }
    final ids = _requiredIds(
      map['skill_ids'],
      '$sourceName...attack_sets[$i].skill_ids',
    );
    final skills = <SkillDef>[];
    for (final skillId in ids) {
      final skill = skillDefs[skillId];
      if (skill == null) {
        throw FormatException(
          '$sourceName...attack_sets[$i].skill_ids: unknown SkillDef "$skillId"',
        );
      }
      skills.add(skill);
    }
    result[id] = CombatRuntimeAttackSet(id: id, skills: skills);
  }
  return result;
}

Future<Map<String, CombatRuntimeVisualVariant>> _parseVisualVariants(
  Map<String, dynamic> root,
  String sourceName,
  int index,
  Future<bool> Function(String path) assetExists,
) async {
  final raw = root['visual_variants'];
  if (raw is! List || raw.isEmpty) {
    throw FormatException(
      '$sourceName...visual_variants must be a non-empty list',
    );
  }
  final result = <String, CombatRuntimeVisualVariant>{};
  for (var i = 0; i < raw.length; i++) {
    final map = _map(
      raw[i],
      '$sourceName.runtime_bindings[$index].visual_variants[$i]',
    );
    final id = _requiredString(map, 'id', '$sourceName...visual_variants[$i]');
    if (result.containsKey(id)) {
      throw FormatException(
        '$sourceName...visual_variants[$i].id: duplicate "$id"',
      );
    }
    final assetPath = _requiredString(
      map,
      'asset_path',
      '$sourceName...visual_variants[$i]',
    );
    if (!assetPath.startsWith('assets/')) {
      throw FormatException(
        '$sourceName...visual_variants[$i].asset_path: must be a production asset path',
      );
    }
    if (!await assetExists(assetPath)) {
      throw FormatException(
        '$sourceName...visual_variants[$i].asset_path: missing asset "$assetPath"',
      );
    }
    result[id] = CombatRuntimeVisualVariant(id: id, assetPath: assetPath);
  }
  return result;
}

CombatRuntimeVerifiedOnlyReferences _parseVerifiedOnly(
  Map<String, dynamic> root,
  CombatCatalogManifestDef manifest,
  CombatEncounterDef encounter,
  String sourceName,
  int index,
) {
  final map = _map(
    root['verified_only_references'],
    '$sourceName.runtime_bindings[$index].verified_only_references',
  );
  if (map['host_consumption'] != 'none') {
    throw FormatException(
      '$sourceName...verified_only_references.host_consumption must be none',
    );
  }
  final posture = _requiredIds(
    map['posture_profile_ids'],
    '$sourceName...posture_profile_ids',
  );
  final drop = _requiredIds(
    map['drop_group_ids'],
    '$sourceName...drop_group_ids',
  );
  final sfx = _requiredIds(map['sfx_group_ids'], '$sourceName...sfx_group_ids');

  final archetypeIds = encounter.spawnEntries
      .map((entry) => entry.archetypeId)
      .toSet();
  final variants = [
    for (final archetypeId in archetypeIds)
      ...manifest.archetypeById(archetypeId)!.variants,
  ];
  _requireExactIds(
    variants.map((variant) => variant.postureProfileId),
    posture,
    '$sourceName...posture_profile_ids',
  );
  _requireExactIds(
    variants.map((variant) => variant.dropGroupId),
    drop,
    '$sourceName...drop_group_ids',
  );
  _requireExactIds(
    variants.map((variant) => variant.sfxGroupId),
    sfx,
    '$sourceName...sfx_group_ids',
  );
  return CombatRuntimeVerifiedOnlyReferences(
    postureProfileIds: posture,
    dropGroupIds: drop,
    sfxGroupIds: sfx,
  );
}

Map<String, dynamic> _map(Object? value, String path) {
  if (value is! Map) throw FormatException('$path must be a map');
  return Map<String, dynamic>.from(value);
}

String _requiredString(Map<String, dynamic> map, String field, String path) {
  final value = map[field];
  if (value is! String || value.trim().isEmpty || _hasWhitespace(value)) {
    throw FormatException(
      '$path.$field must be a non-empty whitespace-free string',
    );
  }
  return value;
}

List<String> _requiredIds(Object? value, String path) {
  if (value is! List || value.isEmpty || value.any((id) => id is! String)) {
    throw FormatException('$path must be a non-empty list of ids');
  }
  final ids = value.cast<String>();
  final seen = <String>{};
  for (final id in ids) {
    if (id.trim().isEmpty || _hasWhitespace(id) || !seen.add(id)) {
      throw FormatException(
        '$path contains an empty, whitespace or duplicate id',
      );
    }
  }
  return List<String>.unmodifiable(ids);
}

double _finiteNumber(Object? value, String path) {
  if (value is! num || !value.isFinite) {
    throw FormatException('$path must be a finite number');
  }
  return value.toDouble();
}

int _requiredInt(Map<String, dynamic> map, String field, String path) {
  final value = map[field];
  if (value is! int || value < 0) {
    throw FormatException('$path.$field must be a non-negative integer');
  }
  return value;
}

bool _requiredBool(Map<String, dynamic> map, String field, String path) {
  final value = map[field];
  if (value is! bool) throw FormatException('$path.$field must be boolean');
  return value;
}

T _enumValue<T extends Enum>(List<T> values, String raw, String path) {
  final canonicalRaw = raw.replaceAll('_', '').toLowerCase();
  for (final value in values) {
    if (value.name.replaceAll('_', '').toLowerCase() == canonicalRaw) {
      return value;
    }
  }
  throw FormatException('$path has unknown policy "$raw"');
}

void _requireExactIds(
  Iterable<String> expected,
  Iterable<String> actual,
  String path,
) {
  final expectedSet = expected.toSet();
  final actualSet = actual.toSet();
  if (expectedSet.length != actualSet.length ||
      !expectedSet.containsAll(actualSet)) {
    throw FormatException(
      '$path must exactly close the production references; missing=${expectedSet.difference(actualSet)} extra=${actualSet.difference(expectedSet)}',
    );
  }
}

bool _hasWhitespace(String value) => RegExp(r'\s').hasMatch(value);

Future<bool> _rootBundleAssetExists(String path) async {
  try {
    await rootBundle.load(path);
    return true;
  } catch (_) {
    return false;
  }
}

bool _isMissingAssetError(Object error) {
  if (error is FileSystemException) {
    final code = error.osError?.errorCode;
    return code == 2 || code == 3;
  }
  return error is FlutterError &&
      error.toString().contains('Unable to load asset');
}
