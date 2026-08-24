import 'defs/combat_catalog_manifest_def.dart';
import 'defs/combat_catalog_reference_index.dart';
import 'combat_encounter_catalog_loader.dart';
import 'yaml_loader.dart';

/// Loads the production combat catalog from an explicit manifest.
///
/// The manifest is the only place that declares source paths and external
/// reference namespaces. Once the manifest exists, every referenced source is
/// mandatory and every parse/validation error is fatal. A missing manifest is
/// treated as "catalog not installed yet" so legacy fixtures remain usable;
/// this is deliberately the only non-fatal path.
Future<CombatCatalogManifestDef?> loadProductionCombatCatalogIfPresent(
  Future<String> Function(String path) load,
) async {
  const manifestPath = 'data/combat/manifest.yaml';
  final String manifestRaw;
  try {
    manifestRaw = await load(manifestPath);
  } catch (_) {
    return null;
  }

  final manifest = parseYamlMap(manifestRaw);
  final archetypePaths = _requiredPaths(manifest, 'archetype_sources');
  final encounterPaths = _requiredPaths(manifest, 'encounter_sources');
  final references = _parseReferenceIndex(manifest['reference_index']);

  Future<List<CombatCatalogYamlSource>> sources(List<String> paths) async {
    final result = <CombatCatalogYamlSource>[];
    for (final path in paths) {
      try {
        result.add((path, await load(path)));
      } catch (e) {
        throw FormatException(
          'production combat catalog source "$path" cannot be loaded: $e',
        );
      }
    }
    return result;
  }

  try {
    return loadCombatCatalogManifest(
      archetypeSources: await sources(archetypePaths),
      encounterSources: await sources(encounterPaths),
      manifestSource: (
        manifestPath,
        _assignmentYaml(manifest['stage_assignments']),
      ),
      referenceIndex: references,
    );
  } on FormatException {
    rethrow;
  } on ArgumentError catch (e) {
    throw FormatException('production combat catalog manifest invalid: $e');
  }
}

String _assignmentYaml(Object? raw) {
  if (raw is! List || raw.isEmpty) {
    throw const FormatException(
      'production combat catalog manifest.stage_assignments must be a non-empty list',
    );
  }
  final lines = <String>['stage_assignments:'];
  for (final entry in raw) {
    if (entry is! Map ||
        entry['stage_id'] is! String ||
        entry['migration_state'] is! String) {
      throw const FormatException(
        'production combat catalog manifest.stage_assignments contains an invalid entry',
      );
    }
    lines.add('  - stage_id: ${entry['stage_id']}');
    lines.add('    migration_state: ${entry['migration_state']}');
    final encounterId = entry['encounter_id'];
    if (encounterId != null) {
      if (encounterId is! String) {
        throw const FormatException(
          'production combat catalog manifest.stage_assignments.encounter_id must be a string',
        );
      }
      lines.add('    encounter_id: $encounterId');
    }
  }
  return lines.join('\n');
}

List<String> _requiredPaths(Map<String, dynamic> manifest, String field) {
  final raw = manifest[field];
  if (raw is! List || raw.isEmpty || raw.any((value) => value is! String)) {
    throw FormatException(
      'production combat catalog manifest.$field must be a non-empty list of paths',
    );
  }
  final paths = raw.cast<String>();
  if (paths.any((path) => path.trim().isEmpty)) {
    throw FormatException(
      'production combat catalog manifest.$field contains an empty path',
    );
  }
  return List<String>.unmodifiable(paths);
}

CombatCatalogReferenceIndex _parseReferenceIndex(Object? raw) {
  if (raw is! Map) {
    throw const FormatException(
      'production combat catalog manifest.reference_index must be a map',
    );
  }
  final map = Map<String, dynamic>.from(raw);
  List<String> ids(String field) {
    final value = map[field];
    if (value is! List || value.any((id) => id is! String)) {
      throw FormatException(
        'production combat catalog manifest.reference_index.$field must be a list of ids',
      );
    }
    return value.cast<String>();
  }

  return CombatCatalogReferenceIndex(
    entranceIds: ids('entrance_ids'),
    positionIds: ids('position_ids'),
    behaviorIds: ids('behavior_ids'),
    attackSetIds: ids('attack_set_ids'),
    attackTagIds: ids('attack_tag_ids'),
    postureProfileIds: ids('posture_profile_ids'),
    dropGroupIds: ids('drop_group_ids'),
    sfxGroupIds: ids('sfx_group_ids'),
    visualVariantIds: ids('visual_variant_ids'),
    objectiveTargetIds: ids('objective_target_ids'),
    objectiveAnchorIds: ids('objective_anchor_ids'),
    objectiveEntityIds: ids('objective_entity_ids'),
    objectiveCheckpointIds: ids('objective_checkpoint_ids'),
    objectiveMarkerIds: ids('objective_marker_ids'),
  );
}
