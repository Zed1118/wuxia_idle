import '../../../../data/defs/combat_encounter_def.dart';
import '../../../../data/defs/skill_def.dart';
import '../../../../data/validation/combat_encounter_roster_mapper.dart';
import '../../../../data/validation/combat_encounter_runtime_contract_mapper.dart';
import '../../../../data/validation/combat_stage_encounter_route_selector.dart';
import '../../domain/phase0a/encounter_enemy_roster.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_damage_kind.dart';
import 'phase0a_battle_snapshot_factory.dart';
import 'phase0a_encounter_mapping.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_player_input_adapter.dart';

/// One composed runtime plan for an exact typed migrated encounter route.
final class Phase0aMigratedEncounterPlan {
  Phase0aMigratedEncounterPlan._(
    this.route,
    this.runtimeContracts,
    this.mapping,
  );

  final MigratedCombatStageEncounterRoute route;
  final CombatEncounterRuntimeContractBundle runtimeContracts;
  final Phase0aEncounterMapping mapping;

  String get stageId => route.stageId;

  CombatEncounterDef get encounter => route.encounter;

  Phase0aEncounterRoster get roster => mapping.roster;
}

/// Composes fresh runtime contracts, roster and mapping in that order.
Phase0aMigratedEncounterPlan buildPhase0aMigratedEncounterPlan(
  MigratedCombatStageEncounterRoute route, {
  required Duration tickDuration,
  required CombatEnemyInstanceIdResolver resolveEnemyId,
  required String playerId,
  required CombatEncounterActorFactory createActor,
  required Phase0aArenaState initialState,
  required List<Phase0aCombatantInput> combatants,
  required Map<Phase0aDamageKind, SkillDef?> moveBindings,
  required Phase0aPlayerInputAdapter playerAdapter,
  required Phase0aEnemyAiAdapter enemyAiAdapter,
}) {
  final runtimeContracts = mapCombatEncounterRuntimeContract(
    route.encounter,
    tickDuration: tickDuration,
    resolveEnemyId: resolveEnemyId,
  );
  final roster = mapCombatEncounterRoster(
    route.encounter,
    runtimeContracts.spawnDirector,
    playerId: playerId,
    createActor: createActor,
  );
  final mapping = Phase0aEncounterMapping(
    initialState: initialState,
    director: runtimeContracts.spawnDirector,
    roster: roster,
    combatants: combatants,
    moveBindings: moveBindings,
    playerAdapter: playerAdapter,
    enemyAiAdapter: enemyAiAdapter,
  );
  return Phase0aMigratedEncounterPlan._(route, runtimeContracts, mapping);
}
