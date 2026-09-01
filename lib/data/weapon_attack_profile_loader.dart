import 'defs/weapon_attack_profile_def.dart';
import '../core/domain/enums.dart';
import 'yaml_loader.dart';

enum WeaponAttackProfileLoadFailureKind {
  manifestRead,
  manifestInvalid,
  sourceRead,
  profileInvalid,
}

final class WeaponAttackProfileLoadException extends FormatException {
  WeaponAttackProfileLoadException({
    required this.kind,
    required this.path,
    required String message,
    this.cause,
  }) : super(message);

  final WeaponAttackProfileLoadFailureKind kind;
  final String path;
  final Object? cause;
}

/// Resolves the production profile source from the combat root manifest.
///
/// Older isolated catalog fixtures with inline stage assignments predate M3
/// and may omit the field. The checked-in production manifest must declare it.
Future<WeaponAttackProfileCatalog?> loadProductionWeaponAttackProfiles({
  required Future<String> Function(String path) load,
}) async {
  const manifestPath = 'data/combat/manifest.yaml';
  final String manifestRaw;
  try {
    manifestRaw = await load(manifestPath);
  } catch (error) {
    throw WeaponAttackProfileLoadException(
      kind: WeaponAttackProfileLoadFailureKind.manifestRead,
      path: manifestPath,
      cause: error,
      message: 'weapon attack profile manifest cannot be read: $error',
    );
  }

  late final String sourcePath;
  try {
    final manifest = parseYamlMap(manifestRaw);
    final raw = manifest['player_attack_profiles_source'];
    if (raw == null && manifest['stage_assignments'] is List) return null;
    if (raw is! String || raw.trim().isEmpty || RegExp(r'\s').hasMatch(raw)) {
      throw const FormatException(
        'manifest.player_attack_profiles_source must be a non-empty path',
      );
    }
    sourcePath = raw;
  } catch (error) {
    throw WeaponAttackProfileLoadException(
      kind: WeaponAttackProfileLoadFailureKind.manifestInvalid,
      path: manifestPath,
      cause: error,
      message: 'weapon attack profile manifest is invalid: $error',
    );
  }

  final String raw;
  try {
    raw = await load(sourcePath);
  } catch (error) {
    throw WeaponAttackProfileLoadException(
      kind: WeaponAttackProfileLoadFailureKind.sourceRead,
      path: sourcePath,
      cause: error,
      message: 'weapon attack profile source cannot be read: $error',
    );
  }
  try {
    return loadWeaponAttackProfileCatalog(sourceName: sourcePath, yaml: raw);
  } catch (error) {
    throw WeaponAttackProfileLoadException(
      kind: WeaponAttackProfileLoadFailureKind.profileInvalid,
      path: sourcePath,
      cause: error,
      message: 'weapon attack profile source is invalid: $error',
    );
  }
}

WeaponAttackProfileCatalog loadWeaponAttackProfileCatalog({
  required String sourceName,
  required String yaml,
}) {
  final root = parseYamlMap(yaml);
  final rawProfiles = root['player_attack_profiles'];
  if (rawProfiles is! List || rawProfiles.isEmpty) {
    throw FormatException(
      '$sourceName.player_attack_profiles must be a non-empty list',
    );
  }
  final profiles = <WeaponAttackProfileDef>[];
  for (var index = 0; index < rawProfiles.length; index++) {
    final raw = rawProfiles[index];
    if (raw is! Map) {
      throw FormatException(
        '$sourceName.player_attack_profiles[$index] must be a map',
      );
    }
    final map = raw.cast<String, dynamic>();
    profiles.add(
      WeaponAttackProfileDef(
        archetype: _archetype(
          _requiredString(map, 'archetype', sourceName, index),
          sourceName,
          index,
        ),
        rangeFactor: _requiredDouble(map, 'range_factor', sourceName, index),
        halfArcFactor: _requiredDouble(
          map,
          'half_arc_factor',
          sourceName,
          index,
        ),
        cooldownFactor: _requiredDouble(
          map,
          'cooldown_factor',
          sourceName,
          index,
        ),
        postureDamageFactor: _requiredDouble(
          map,
          'posture_damage_factor',
          sourceName,
          index,
        ),
        maxTargets: _requiredInt(map, 'max_targets', sourceName, index),
        attackDisplacement: _requiredDouble(
          map,
          'attack_displacement',
          sourceName,
          index,
        ),
      ),
    );
  }
  return WeaponAttackProfileCatalog(profiles);
}

WeaponArchetype _archetype(String raw, String sourceName, int index) {
  for (final archetype in WeaponArchetype.values) {
    if (archetype.name == raw) return archetype;
  }
  throw FormatException(
    '$sourceName.player_attack_profiles[$index].archetype: unknown "$raw"',
  );
}

String _requiredString(
  Map<String, dynamic> map,
  String field,
  String sourceName,
  int index,
) {
  final value = map[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      '$sourceName.player_attack_profiles[$index].$field must be a string',
    );
  }
  return value;
}

double _requiredDouble(
  Map<String, dynamic> map,
  String field,
  String sourceName,
  int index,
) {
  final value = map[field];
  if (value is! num) {
    throw FormatException(
      '$sourceName.player_attack_profiles[$index].$field must be numeric',
    );
  }
  return value.toDouble();
}

int _requiredInt(
  Map<String, dynamic> map,
  String field,
  String sourceName,
  int index,
) {
  final value = map[field];
  if (value is! int) {
    throw FormatException(
      '$sourceName.player_attack_profiles[$index].$field must be an integer',
    );
  }
  return value;
}
