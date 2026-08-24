import 'dart:io';

import 'package:flutter/foundation.dart';

import 'defs/combat_catalog_manifest_def.dart';
import 'defs/combat_catalog_reference_index.dart';
import 'combat_encounter_catalog_loader.dart';
import 'yaml_loader.dart';

enum CombatCatalogLoadFailureKind {
  manifestRead,
  manifestInvalid,
  sourceMissing,
  sourceRead,
  catalogInvalid,
}

final class CombatCatalogLoadException extends FormatException {
  CombatCatalogLoadException({
    required this.kind,
    required this.path,
    required String message,
    this.cause,
  }) : super(message);

  final CombatCatalogLoadFailureKind kind;
  final String path;
  final Object? cause;
}

/// Loads the production combat catalog from an explicit manifest.
///
/// The manifest is the only place that declares source paths and external
/// reference namespaces. Once the manifest exists, every referenced source is
/// mandatory and every parse/validation error is fatal. A missing manifest is
/// treated as "catalog not installed yet" so legacy fixtures remain usable;
/// this is deliberately the only non-fatal path.
Future<CombatCatalogManifestDef?> loadProductionCombatCatalogIfPresent(
  Future<String> Function(String path) load, {
  bool Function(Object error)? isMissingAssetError,
}) async {
  const manifestPath = 'data/combat/manifest.yaml';
  final isMissing = isMissingAssetError ?? _isMissingAssetError;
  final String manifestRaw;
  try {
    manifestRaw = await load(manifestPath);
  } catch (error) {
    if (isMissing(error)) return null;
    throw CombatCatalogLoadException(
      kind: CombatCatalogLoadFailureKind.manifestRead,
      path: manifestPath,
      cause: error,
      message: 'production combat catalog manifest cannot be read: $error',
    );
  }

  late final Map<String, dynamic> manifest;
  late final List<String> archetypePaths;
  late final List<String> encounterPaths;
  late final CombatCatalogReferenceIndex references;
  late final String assignmentYaml;
  try {
    manifest = parseYamlMap(manifestRaw);
    archetypePaths = _requiredPaths(manifest, 'archetype_sources');
    encounterPaths = _requiredPaths(manifest, 'encounter_sources');
    references = _parseReferenceIndex(manifest['reference_index']);
    assignmentYaml = _assignmentYaml(manifest['stage_assignments']);
  } catch (error) {
    if (error is CombatCatalogLoadException) rethrow;
    throw CombatCatalogLoadException(
      kind: CombatCatalogLoadFailureKind.manifestInvalid,
      path: manifestPath,
      cause: error,
      message: 'production combat catalog manifest is invalid: $error',
    );
  }

  Future<List<CombatCatalogYamlSource>> sources(List<String> paths) async {
    final result = <CombatCatalogYamlSource>[];
    for (final path in paths) {
      try {
        result.add((path, await load(path)));
      } catch (error) {
        final kind = isMissing(error)
            ? CombatCatalogLoadFailureKind.sourceMissing
            : CombatCatalogLoadFailureKind.sourceRead;
        throw CombatCatalogLoadException(
          kind: kind,
          path: path,
          cause: error,
          message: 'production combat catalog source "$path" cannot be read: $error',
        );
      }
    }
    return result;
  }

  try {
    return loadCombatCatalogManifest(
      archetypeSources: await sources(archetypePaths),
      encounterSources: await sources(encounterPaths),
      manifestSource: (manifestPath, assignmentYaml),
      referenceIndex: references,
    );
  } on FormatException catch (error) {
    if (error is CombatCatalogLoadException) rethrow;
    throw CombatCatalogLoadException(
      kind: CombatCatalogLoadFailureKind.catalogInvalid,
      path: manifestPath,
      cause: error,
      message: 'production combat catalog content is invalid: $error',
    );
  } on ArgumentError catch (error) {
    throw CombatCatalogLoadException(
      kind: CombatCatalogLoadFailureKind.catalogInvalid,
      path: manifestPath,
      cause: error,
      message: 'production combat catalog content is invalid: $error',
    );
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
    lines.add('  - stage_id: ${_yamlString(entry['stage_id'] as String)}');
    lines.add(
      '    migration_state: ${_yamlString(entry['migration_state'] as String)}',
    );
    final encounterId = entry['encounter_id'];
    if (encounterId != null) {
      if (encounterId is! String) {
        throw const FormatException(
          'production combat catalog manifest.stage_assignments.encounter_id must be a string',
        );
      }
      lines.add('    encounter_id: ${_yamlString(encounterId)}');
    }
  }
  return lines.join('\n');
}

String _yamlString(String value) => "'${value.replaceAll("'", "''")}'";

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

bool _isMissingAssetError(Object error) {
  if (error is FileSystemException) {
    final code = error.osError?.errorCode;
    return code == null || code == 2 || code == 3;
  }
  return error is FlutterError &&
      error.toString().contains('Unable to load asset');
}
