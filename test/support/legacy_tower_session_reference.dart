import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';

/// Frozen test reference extracted from the production legacy builder at
/// 00982ba029e2164c342f73c37eb36cae4d4faa97. Keep assembly, ids, RNG,
/// snapshots and settlement identical when comparing the migrated route.
/// Production must never import or select this reference.
Future<Phase0aTowerCombatSession> createLegacyTowerSessionForReference(
  Phase0aTowerCombatSessionBuildRequest request,
) async {
  final mapping = Phase0aStageContentMapper.mapTower(
    floor: request.floor,
    playerSnapshot: request.playerSnapshot,
    numbers: request.numbers,
    cycleIndex: request.cycleIndex,
  );
  final sourceByActor = <String, String>{};
  for (final combatant in mapping.combatants.skip(1)) {
    final sourceId = combatant.snapshot.enemyDefId;
    if (sourceId == null) {
      throw StateError('legacy tower mapping lost enemyDefId');
    }
    sourceByActor[combatant.actorId] = sourceId;
  }
  final flow = Phase0aProductionFlowAssembler.assemble(
    initialState: mapping.initialState,
    waves: mapping.waves,
    combatants: mapping.combatants,
    moveBindings: mapping.moveBindings,
    numbers: request.numbers,
    rng: request.rng,
    playerAdapter: mapping.playerAdapter,
    enemyAiAdapter: mapping.enemyAiAdapter,
    waveTransitionPolicy: mapping.waveTransitionPolicy,
  );
  return Phase0aTowerCombatSession(
    contentRef: request.contentRef,
    routeMode: Phase0aTowerEncounterRouteMode.legacy,
    flow: flow,
    combatants: mapping.combatants,
    playerAdapter: mapping.playerAdapter,
    sourceEnemyDefIdByActorId: sourceByActor,
    sourceEnemyDefIdsInEntryOrder: request.floor.enemyTeam
        .map((enemy) => enemy.id)
        .toList(),
    encounterCount: 1,
    activeLimit: request.floor.enemyTeam.length,
    settle: ({required outcome, required finalState, required events}) =>
        Phase0aSettlementAdapter.fromMapping(
          mapping: mapping,
          outcome: outcome,
          finalState: finalState,
          events: events,
        ),
  );
}
