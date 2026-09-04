import '../../features/battle/domain/phase0a/attack_token_director.dart';
import '../../features/battle/domain/phase0a/objective_controller.dart';
import '../../features/battle/domain/phase0a/spawn_director.dart';
import '../defs/combat_encounter_def.dart';
import 'combat_objective_primitive_mapper.dart';

/// Resolves the runtime enemy instance id for one encounter spawn entry.
///
/// The id is always an explicit caller-side resolution per entry; it is
/// never derived from or substituted by the content
/// [CombatEncounterSpawnEntry.entryId]. Failures (e.g. an unknown roster
/// lookup) propagate as-is; no fallback.
typedef CombatEnemyInstanceIdResolver =
    String Function(CombatEncounterSpawnEntry entry);

/// Immutable runtime contract bundle for one encounter: fresh owners only.
final class CombatEncounterRuntimeContractBundle {
  CombatEncounterRuntimeContractBundle({
    required this.spawnDirector,
    required this.attackTokenBudgets,
    required this.objectiveController,
  });

  final SpawnDirector spawnDirector;
  final AttackTokenBudgets attackTokenBudgets;
  final ObjectiveController objectiveController;
}

/// Maps one content encounter definition to a fresh runtime contract bundle.
///
/// All four spawn-config fields and all four token-budget fields pass through
/// one-to-one; the mapper applies no defaults, clamping or tuning. The
/// resolver is invoked once per spawn entry in content entry order and its
/// results are snapshotted immediately. Blank, whitespace or duplicate enemy
/// ids fail closed inside [SpawnEntry]/[SpawnDirector] itself.
CombatEncounterRuntimeContractBundle mapCombatEncounterRuntimeContract(
  CombatEncounterDef definition, {
  required Duration tickDuration,
  required CombatEnemyInstanceIdResolver resolveEnemyId,
  bool startWithAllEntriesActive = false,
}) {
  final spawnEntries = [
    for (final entry in definition.spawnEntries)
      SpawnEntry(entryId: entry.entryId, enemyId: resolveEnemyId(entry)),
  ];

  return CombatEncounterRuntimeContractBundle(
    spawnDirector: startWithAllEntriesActive
        ? SpawnDirector.allActive(
            config: SpawnDirectorConfig(
              activeLimit: definition.spawnConfig.activeLimit,
              reinforcementThreshold:
                  definition.spawnConfig.reinforcementThreshold,
              entryWarningTicks: definition.spawnConfig.entryWarningTicks,
              attackGraceTicks: definition.spawnConfig.attackGraceTicks,
            ),
            entries: spawnEntries,
          )
        : SpawnDirector(
            config: SpawnDirectorConfig(
              activeLimit: definition.spawnConfig.activeLimit,
              reinforcementThreshold:
                  definition.spawnConfig.reinforcementThreshold,
              entryWarningTicks: definition.spawnConfig.entryWarningTicks,
              attackGraceTicks: definition.spawnConfig.attackGraceTicks,
            ),
            entries: spawnEntries,
          ),
    attackTokenBudgets: AttackTokenBudgets(
      melee: definition.tokenBudgets.melee,
      ranged: definition.tokenBudgets.ranged,
      charge: definition.tokenBudgets.charge,
      support: definition.tokenBudgets.support,
    ),
    objectiveController: mapCombatObjectiveComposition(
      definition.objectives,
      tickDuration: tickDuration,
    ),
  );
}
