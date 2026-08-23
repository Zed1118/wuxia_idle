import '../../features/battle/application/phase0a/phase0a_encounter_migration_resolver.dart';
import '../defs/combat_catalog_manifest_def.dart';
import '../defs/combat_encounter_def.dart';

/// One validated host-neutral route for a stage's encounter content.
sealed class CombatStageEncounterRoute {
  const CombatStageEncounterRoute(this.stageId);

  final String stageId;
}

/// A stage that must continue through its explicitly allowlisted legacy path.
final class LegacyCombatStageEncounterRoute extends CombatStageEncounterRoute {
  const LegacyCombatStageEncounterRoute(super.stageId);

  @override
  bool operator ==(Object other) =>
      other is LegacyCombatStageEncounterRoute && stageId == other.stageId;

  @override
  int get hashCode => Object.hash(LegacyCombatStageEncounterRoute, stageId);
}

/// A stage that must use the exact typed encounter owned by its manifest.
final class MigratedCombatStageEncounterRoute
    extends CombatStageEncounterRoute {
  const MigratedCombatStageEncounterRoute(super.stageId, this.encounter);

  final CombatEncounterDef encounter;

  @override
  bool operator ==(Object other) =>
      other is MigratedCombatStageEncounterRoute &&
      stageId == other.stageId &&
      identical(encounter, other.encounter);

  @override
  int get hashCode => Object.hash(stageId, identityHashCode(encounter));
}

/// Selects one stage's route after revalidating its migration shape.
///
/// The manifest remains authoritative for the assignment and encounter. The
/// caller remains authoritative for legacy-content presence and supplies the
/// existing migration resolver that owns the explicit legacy allowlist.
/// Unknown stages and every inconsistent shape fail before a route exists.
CombatStageEncounterRoute selectCombatStageEncounterRoute({
  required CombatCatalogManifestDef manifest,
  required String stageId,
  required Phase0aEncounterMigrationResolver migrationResolver,
  required bool hasLegacyContent,
}) {
  final assignment = manifest.assignmentForStage(stageId);
  if (assignment == null) {
    throw ArgumentError.value(
      stageId,
      'stageId',
      'must have an explicit manifest assignment',
    );
  }

  final encounter = manifest.encounterForStage(stageId);
  final resolvedState = migrationResolver.resolve(
    Phase0aEncounterMigrationRequest(
      contentId: stageId,
      migrationState: _runtimeStateFor(assignment.migrationState),
      encounterCount: encounter == null ? 0 : 1,
      hasLegacyContent: hasLegacyContent,
    ),
  );

  return switch (resolvedState) {
    Phase0aEncounterMigrationState.legacy when encounter == null =>
      LegacyCombatStageEncounterRoute(stageId),
    Phase0aEncounterMigrationState.legacy => throw StateError(
      'validated legacy route must not carry an encounter',
    ),
    Phase0aEncounterMigrationState.migrated when encounter != null =>
      MigratedCombatStageEncounterRoute(stageId, encounter),
    Phase0aEncounterMigrationState.migrated => throw StateError(
      'validated migrated route must carry exactly one encounter',
    ),
  };
}

Phase0aEncounterMigrationState _runtimeStateFor(
  CombatEncounterMigrationState state,
) => switch (state) {
  CombatEncounterMigrationState.legacy => Phase0aEncounterMigrationState.legacy,
  CombatEncounterMigrationState.migrated =>
    Phase0aEncounterMigrationState.migrated,
};
