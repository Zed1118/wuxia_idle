import 'dart:io';

import 'package:flutter/foundation.dart';

import 'combat_encounter_catalog_loader.dart';
import 'defs/combat_catalog_manifest_def.dart';
import 'defs/combat_catalog_reference_index.dart';
import 'yaml_loader.dart';

enum CombatCatalogLoadFailureKind {
  manifestRead,
  manifestInvalid,
  sourceMissing,
  sourceRead,
  catalogInvalid,
}

/// Production catalog failures retain the source path and failure class so a
/// caller can distinguish an absent optional catalog from damaged production
/// data. Only a missing root manifest is non-fatal.
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

/// Loads the production combat catalog from an explicit root manifest.
///
/// Production migration truth remains in
/// `data/combat/manifest/stage_assignments.yaml`; the root manifest only
/// references that source. The root manifest also references the runtime
/// binding source, which is loaded here as a required source so a migrated
/// catalog can never silently install without its runtime contract. The
/// typed runtime validation is performed by the runtime binding loader.
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
  late final String assignmentPath;
  late final String? runtimeBindingPath;
  try {
    manifest = parseYamlMap(manifestRaw);
    archetypePaths = _requiredPaths(manifest, 'archetype_sources');
    encounterPaths = _requiredPaths(manifest, 'encounter_sources');
    references = _parseReferenceIndex(manifest['reference_index']);
    assignmentPath = _requiredSourcePath(
      manifest,
      'stage_assignments_source',
      legacyInlineField: 'stage_assignments',
    );
    final runtimeRaw = manifest['runtime_bindings_source'];
    if (runtimeRaw == null && manifest['stage_assignments'] is List) {
      // Older isolated catalog fixtures predate the runtime contract. The
      // production root manifest below always supplies this source.
      runtimeBindingPath = null;
    } else {
      runtimeBindingPath = _requiredSourcePath(
        manifest,
        'runtime_bindings_source',
      );
    }
  } catch (error) {
    throw CombatCatalogLoadException(
      kind: CombatCatalogLoadFailureKind.manifestInvalid,
      path: manifestPath,
      cause: error,
      message: 'production combat catalog manifest is invalid: $error',
    );
  }

  Future<String> requiredSource(String path) async {
    try {
      return await load(path);
    } catch (error) {
      final kind = isMissing(error)
          ? CombatCatalogLoadFailureKind.sourceMissing
          : CombatCatalogLoadFailureKind.sourceRead;
      throw CombatCatalogLoadException(
        kind: kind,
        path: path,
        cause: error,
        message:
            'production combat catalog source "$path" cannot be read: $error',
      );
    }
  }

  Future<List<CombatCatalogYamlSource>> sources(List<String> paths) async {
    final result = <CombatCatalogYamlSource>[];
    for (final path in paths) {
      result.add((path, await requiredSource(path)));
    }
    return result;
  }

  // Read both authoritative binding inputs at the catalog boundary. The
  // runtime loader reads the binding again to parse and resolve it, but a
  // missing root-referenced source is already classified here.
  if (runtimeBindingPath != null) await requiredSource(runtimeBindingPath);
  final assignmentRaw = assignmentPath.startsWith('inline:')
      ? null
      : await requiredSource(assignmentPath);

  try {
    final inlineAssignment = manifest['stage_assignments'];
    final assignmentSource = inlineAssignment == null
        ? (assignmentPath, assignmentRaw!)
        : (manifestPath, _assignmentYaml(inlineAssignment));
    return loadCombatCatalogManifest(
      archetypeSources: await sources(archetypePaths),
      encounterSources: await sources(encounterPaths),
      manifestSource: assignmentSource,
      referenceIndex: references,
    );
  } on CombatCatalogLoadException {
    rethrow;
  } on FormatException catch (error) {
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

String _requiredSourcePath(
  Map<String, dynamic> manifest,
  String field, {
  String? legacyInlineField,
}) {
  final raw = manifest[field];
  if (raw is String && raw.trim().isNotEmpty && !RegExp(r'\s').hasMatch(raw)) {
    return raw;
  }
  if (legacyInlineField != null && manifest[legacyInlineField] is List) {
    // Test-only compatibility for older isolated catalog fixtures. Production
    // data uses the explicit source field and is checked by the runtime loader.
    return 'inline:$legacyInlineField';
  }
  throw FormatException('manifest.$field must be a non-empty path');
}

String _assignmentYaml(Object? raw) {
  if (raw is! List || raw.isEmpty) {
    throw const FormatException(
      'production combat manifest.stage_assignments must be a non-empty list',
    );
  }
  final lines = <String>['stage_assignments:'];
  for (final entry in raw) {
    if (entry is! Map ||
        entry['stage_id'] is! String ||
        entry['migration_state'] is! String) {
      throw const FormatException(
        'production combat manifest.stage_assignments contains an invalid entry',
      );
    }
    lines.add("  - stage_id: '${_yamlQuote(entry['stage_id'] as String)}'");
    lines.add(
      "    migration_state: '${_yamlQuote(entry['migration_state'] as String)}'",
    );
    final encounterId = entry['encounter_id'];
    if (encounterId != null) {
      if (encounterId is! String) {
        throw const FormatException(
          'production combat manifest.stage_assignments.encounter_id must be a string',
        );
      }
      lines.add("    encounter_id: '${_yamlQuote(encounterId)}'");
    }
  }
  return lines.join('\n');
}

String _yamlQuote(String value) => value.replaceAll("'", "''");

List<String> _requiredPaths(Map<String, dynamic> manifest, String field) {
  final raw = manifest[field];
  if (raw is! List || raw.isEmpty || raw.any((value) => value is! String)) {
    throw FormatException(
      'production combat manifest.$field must be a non-empty list of paths',
    );
  }
  final paths = raw.cast<String>();
  if (paths.any(
    (path) => path.trim().isEmpty || RegExp(r'\s').hasMatch(path),
  )) {
    throw FormatException(
      'production combat manifest.$field contains an invalid path',
    );
  }
  return List<String>.unmodifiable(paths);
}

CombatCatalogReferenceIndex _parseReferenceIndex(Object? raw) {
  if (raw is! Map) {
    throw const FormatException(
      'production combat manifest.reference_index must be a map',
    );
  }
  final map = Map<String, dynamic>.from(raw);
  List<String> ids(String field) {
    final value = map[field];
    if (value is! List || value.any((id) => id is! String)) {
      throw FormatException(
        'production combat manifest.reference_index.$field must be a list of ids',
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
    return code == 2 || code == 3;
  }
  return error is FlutterError &&
      error.toString().contains('Unable to load asset');
}
