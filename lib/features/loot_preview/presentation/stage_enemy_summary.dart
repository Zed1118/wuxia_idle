import '../../../core/domain/enums.dart';
import '../../../data/defs/combat_catalog_manifest_def.dart';
import '../../../data/defs/mainline_wave_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../shared/strings.dart';

/// Shared enemy counts for the stage row, intel dialog and risk hints.
///
/// The catalog resolves the same assignment and encounter consumed by
/// createFreshPhase0aMainlineEncounter. Catalog spawn entries are a reserve
/// roster, not fixed waves. Non-mainline modes retain their own enemy team.
final class StageEnemySummary {
  const StageEnemySummary._({
    required this.totalEnemyCount,
    required this.listText,
    required this.detailLines,
  });

  factory StageEnemySummary.fromStage(
    StageDef stage, {
    required MainlineWaveDef mainlineWaves,
    CombatCatalogManifestDef? catalog,
  }) {
    final encounter = stage.stageType == StageType.mainline
        ? catalog?.encounterForStage(stage.id)
        : null;
    if (encounter != null) {
      final total = encounter.spawnEntries.length;
      final spawn = encounter.spawnConfig;
      final dependentCount = encounter.spawnEntries
          .where((entry) => entry.spawnAfterDefeated.isNotEmpty)
          .length;
      final summary = UiStrings.stageCatalogEnemySummary(
        total,
        spawn.activeLimit,
      );
      return StageEnemySummary._(
        totalEnemyCount: total,
        listText: summary,
        detailLines: [
          summary,
          if (total > spawn.activeLimit || dependentCount > 0)
            UiStrings.prebattleCatalogReinforcements(
              spawn.reinforcementThreshold,
            )
          else
            UiStrings.prebattleCatalogSingleDeployment,
          if (dependentCount > 0)
            UiStrings.prebattleCatalogSpawnDependencies(dependentCount),
        ],
      );
    }
    if (stage.stageType == StageType.mainline && mainlineWaves.isEnabled) {
      final profile = mainlineWaves.profileFor(isBossStage: stage.isBossStage);
      return StageEnemySummary._(
        totalEnemyCount: profile.totalEnemyCount,
        listText: UiStrings.stageListEnemyWaves(
          profile.waveCount,
          profile.totalEnemyCount,
        ),
        detailLines: [
          UiStrings.prebattleMainlineWaveSummary(
            profile.waveCount,
            profile.totalEnemyCount,
            bossFinal: stage.isBossStage,
          ),
        ],
      );
    }
    return StageEnemySummary._(
      totalEnemyCount: stage.enemyTeam.length,
      listText: UiStrings.stageListEnemyCount(stage.enemyTeam.length),
      detailLines: const [],
    );
  }

  final int totalEnemyCount;
  final String listText;
  final List<String> detailLines;
}
