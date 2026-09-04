import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/combat_encounter_def.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/enemy_combatant_snapshot_assembler.dart';
import '../../battle/application/phase0a/combat_content_ref.dart';
import '../../battle/application/phase0a/phase0a_battle_flow.dart';
import '../../battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import '../../battle/application/phase0a/phase0a_encounter_host.dart';
import '../../battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import '../../battle/application/phase0a/phase0a_enemy_skill_binding.dart';
import '../../battle/application/phase0a/phase0a_migrated_encounter_plan_builder.dart';
import '../../battle/application/phase0a/phase0a_player_input_adapter.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_settlement_adapter.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../battle/domain/phase0a/attack_token_director.dart';
import '../../battle/domain/phase0a/phase0a_combat_events.dart';
import '../../battle/domain/phase0a/phase0a_combat_model.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../../data/validation/combat_stage_encounter_route_selector.dart';
import '../../mainline/application/phase0a_mainline_production_encounter_factory.dart';

enum Phase0aTowerEncounterRouteMode { legacy, migrated }

/// Production authority for tower migration routing.
///
/// The production set is deliberately empty at this foundation gate, so the
/// tower migration numerator remains 0/49. Tests and later per-floor migration
/// commits can opt exact floors into the typed path without changing callers.
final class Phase0aTowerEncounterRouteAuthority {
  const Phase0aTowerEncounterRouteAuthority.production()
    : migratedFloorIndices = const <int>{};

  Phase0aTowerEncounterRouteAuthority.migratedFloors(
    Set<int> migratedFloorIndices,
  ) : migratedFloorIndices = Set.unmodifiable(migratedFloorIndices) {
    for (final floorIndex in migratedFloorIndices) {
      if (floorIndex < 1 || floorIndex > 49) {
        throw ArgumentError.value(
          floorIndex,
          'migratedFloorIndices',
          'must contain only floors in 1..49',
        );
      }
    }
  }

  final Set<int> migratedFloorIndices;

  Phase0aTowerEncounterRouteMode modeForFloor(int floorIndex) {
    if (floorIndex < 1 || floorIndex > 49) {
      throw ArgumentError.value(floorIndex, 'floorIndex', 'must be in 1..49');
    }
    return migratedFloorIndices.contains(floorIndex)
        ? Phase0aTowerEncounterRouteMode.migrated
        : Phase0aTowerEncounterRouteMode.legacy;
  }
}

abstract interface class Phase0aTowerEncounterDefinitionSource {
  FutureOr<CombatEncounterDef?> load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
  });
}

final class Phase0aDerivedTowerEncounterDefinitionSource
    implements Phase0aTowerEncounterDefinitionSource {
  const Phase0aDerivedTowerEncounterDefinitionSource();

  @override
  CombatEncounterDef load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
  }) {
    final entryIds = <String>[
      for (var i = 0; i < floor.enemyTeam.length; i += 1)
        '${contentRef.contentId}_entry_${i.toString().padLeft(3, '0')}',
    ];
    return CombatEncounterDef(
      id: '${contentRef.contentId}_encounter',
      spawnConfig: CombatEncounterSpawnConfig(
        activeLimit: floor.enemyTeam.length,
        reinforcementThreshold: 0,
        entryWarningTicks: 0,
        attackGraceTicks: 0,
      ),
      tokenBudgets: CombatEncounterTokenBudgets(
        melee: floor.enemyTeam.length,
        ranged: 0,
        charge: 0,
        support: 0,
      ),
      spawnEntries: [
        for (var i = 0; i < floor.enemyTeam.length; i += 1)
          CombatEncounterSpawnEntry(
            entryId: entryIds[i],
            archetypeId: floor.enemyTeam[i].id,
            roleId: 'tower_enemy',
            entranceId: '${contentRef.contentId}_entrance_$i',
            positionId: '${contentRef.contentId}_position_$i',
            behaviorId: 'tower_existing_ai',
            sourceEnemyDefId: floor.enemyTeam[i].id,
          ),
      ],
      objectives: CombatObjectiveCompositionRef(
        completionRule: CombatObjectiveCompletionRule.all,
        clauses: [
          CombatObjectiveClauseRef(
            id: '${contentRef.contentId}_defeat_all',
            primitive: CombatDefeatTargetsRef(entryIds),
          ),
        ],
      ),
    );
  }
}

final class Phase0aTowerActorRuntimeBinding {
  const Phase0aTowerActorRuntimeBinding({
    required this.entryId,
    required this.sourceEnemyDefId,
    required this.combatant,
  });

  final String entryId;
  final String sourceEnemyDefId;
  final CombatantSnapshot combatant;
}

final class Phase0aTowerRuntimeBindingBundle {
  Phase0aTowerRuntimeBindingBundle({
    required this.contentId,
    required this.encounterId,
    required List<Phase0aTowerActorRuntimeBinding> actorBindings,
  }) : actorBindings = List.unmodifiable(actorBindings);

  final String contentId;
  final String encounterId;
  final List<Phase0aTowerActorRuntimeBinding> actorBindings;
}

abstract interface class Phase0aTowerEncounterRuntimeBindingSource {
  FutureOr<Phase0aTowerRuntimeBindingBundle?> load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
    required CombatEncounterDef encounter,
    required int cycleIndex,
  });
}

final class Phase0aDerivedTowerEncounterRuntimeBindingSource
    implements Phase0aTowerEncounterRuntimeBindingSource {
  const Phase0aDerivedTowerEncounterRuntimeBindingSource();

  @override
  Phase0aTowerRuntimeBindingBundle load({
    required CombatContentRef contentRef,
    required TowerFloorDef floor,
    required CombatEncounterDef encounter,
    required int cycleIndex,
  }) => Phase0aTowerRuntimeBindingBundle(
    contentId: contentRef.contentId,
    encounterId: encounter.id,
    actorBindings: List.unmodifiable([
      for (var i = 0; i < encounter.spawnEntries.length; i += 1)
        Phase0aTowerActorRuntimeBinding(
          entryId: encounter.spawnEntries[i].entryId,
          sourceEnemyDefId: floor.enemyTeam[i].id,
          combatant: EnemyCombatantSnapshotAssembler.assembleOne(
            enemy: floor.enemyTeam[i],
            slotIndex: i,
            cycleIndex: cycleIndex,
            isTower: true,
          ),
        ),
    ]),
  );
}

typedef Phase0aTowerSettlementBuilder =
    CombatSettlementSnapshot Function({
      required Phase0aBattleOutcome outcome,
      required Phase0aArenaState finalState,
      required List<Phase0aEvent> events,
    });

final class Phase0aTowerCombatSession {
  Phase0aTowerCombatSession({
    required this.contentRef,
    required this.routeMode,
    required this.flow,
    required List<Phase0aCombatantInput> combatants,
    required this.playerAdapter,
    required Map<String, String> sourceEnemyDefIdByActorId,
    required List<String> sourceEnemyDefIdsInEntryOrder,
    required this.encounterCount,
    required this.activeLimit,
    required Phase0aTowerSettlementBuilder settle,
  }) : combatants = List.unmodifiable(combatants),
       sourceEnemyDefIdByActorId = Map.unmodifiable(sourceEnemyDefIdByActorId),
       sourceEnemyDefIdsInEntryOrder = List.unmodifiable(
         sourceEnemyDefIdsInEntryOrder,
       ),
       _settle = settle;

  final CombatContentRef contentRef;
  final Phase0aTowerEncounterRouteMode routeMode;
  final Phase0aBattleFlow flow;
  final List<Phase0aCombatantInput> combatants;
  final Phase0aPlayerInputAdapter playerAdapter;
  final Map<String, String> sourceEnemyDefIdByActorId;
  final List<String> sourceEnemyDefIdsInEntryOrder;
  final int encounterCount;
  final int activeLimit;
  final Phase0aTowerSettlementBuilder _settle;

  CombatSettlementSnapshot settle({
    required Phase0aBattleOutcome outcome,
    required Phase0aArenaState finalState,
    required List<Phase0aEvent> events,
  }) => _settle(outcome: outcome, finalState: finalState, events: events);
}

final class Phase0aTowerCombatSessionBuildRequest {
  const Phase0aTowerCombatSessionBuildRequest({
    required this.contentRef,
    required this.floor,
    required this.playerSnapshot,
    required this.numbers,
    required this.cycleIndex,
    required this.rng,
    this.routeAuthority =
        const Phase0aTowerEncounterRouteAuthority.production(),
    this.definitionSource =
        const Phase0aDerivedTowerEncounterDefinitionSource(),
    this.runtimeBindingSource =
        const Phase0aDerivedTowerEncounterRuntimeBindingSource(),
  });

  final CombatContentRef contentRef;
  final TowerFloorDef floor;
  final CombatantSnapshot playerSnapshot;
  final NumbersConfig numbers;
  final int cycleIndex;
  final Random rng;
  final Phase0aTowerEncounterRouteAuthority routeAuthority;
  final Phase0aTowerEncounterDefinitionSource definitionSource;
  final Phase0aTowerEncounterRuntimeBindingSource runtimeBindingSource;
}

typedef Phase0aTowerCombatSessionFactory =
    Future<Phase0aTowerCombatSession> Function(
      Phase0aTowerCombatSessionBuildRequest request,
    );

final phase0aTowerCombatSessionFactoryProvider =
    Provider<Phase0aTowerCombatSessionFactory>(
      (ref) => createFreshPhase0aTowerCombatSession,
    );

Future<Phase0aTowerCombatSession> createFreshPhase0aTowerCombatSession(
  Phase0aTowerCombatSessionBuildRequest request,
) async {
  _validateRequest(request);
  final mode = request.routeAuthority.modeForFloor(request.floor.floorIndex);
  if (mode == Phase0aTowerEncounterRouteMode.legacy) {
    return _createLegacySession(request);
  }

  final encounter = await request.definitionSource.load(
    contentRef: request.contentRef,
    floor: request.floor,
  );
  if (encounter == null) {
    throw StateError(
      'migrated tower route has no encounter: ${request.contentRef.contentId}',
    );
  }
  _validateDefinition(floor: request.floor, encounter: encounter);
  final runtime = await request.runtimeBindingSource.load(
    contentRef: request.contentRef,
    floor: request.floor,
    encounter: encounter,
    cycleIndex: request.cycleIndex,
  );
  if (runtime == null) {
    throw StateError(
      'migrated tower route has no runtime bindings: '
      '${request.contentRef.contentId}/${encounter.id}',
    );
  }
  return _createMigratedSession(request, encounter, runtime);
}

void _validateRequest(Phase0aTowerCombatSessionBuildRequest request) {
  final expectedContentId = 'tower_${request.floor.floorIndex}';
  if (request.contentRef.kind != CombatContentKind.tower ||
      request.contentRef.contentId != expectedContentId) {
    throw StateError(
      'tower content ref mismatch: expected=$expectedContentId '
      'actual=${request.contentRef.kind.name}/${request.contentRef.contentId}',
    );
  }
  if (request.floor.enemyTeam.isEmpty) {
    throw StateError('$expectedContentId has no enemy team');
  }
  if (request.cycleIndex < 1) {
    throw ArgumentError.value(request.cycleIndex, 'cycleIndex', 'must be >= 1');
  }
}

void _validateDefinition({
  required TowerFloorDef floor,
  required CombatEncounterDef encounter,
}) {
  final entries = encounter.spawnEntries;
  if (entries.length != floor.enemyTeam.length ||
      encounter.spawnConfig.activeLimit != floor.enemyTeam.length) {
    throw StateError(
      'tower encounter must bind every floor enemy exactly once',
    );
  }
  final expectedSourceIds = floor.enemyTeam.map((enemy) => enemy.id).toList();
  final sourceIds = entries.map((entry) => entry.sourceEnemyDefId).toList();
  if (sourceIds.any((id) => id == null) ||
      sourceIds.toSet().length != sourceIds.length ||
      !_sameOrder(sourceIds.whereType<String>().toList(), expectedSourceIds)) {
    throw StateError(
      'tower encounter sourceEnemyDefId bindings must be unique and ordered',
    );
  }
}

Phase0aTowerCombatSession _createLegacySession(
  Phase0aTowerCombatSessionBuildRequest request,
) {
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

Phase0aTowerCombatSession _createMigratedSession(
  Phase0aTowerCombatSessionBuildRequest request,
  CombatEncounterDef encounter,
  Phase0aTowerRuntimeBindingBundle runtime,
) {
  if (runtime.contentId != request.contentRef.contentId ||
      runtime.encounterId != encounter.id ||
      runtime.actorBindings.length != encounter.spawnEntries.length) {
    throw StateError('tower runtime binding route mismatch');
  }
  final entries = encounter.spawnEntries;
  final bindings = runtime.actorBindings;
  final seenEntries = <String>{};
  final seenSources = <String>{};
  for (var i = 0; i < bindings.length; i += 1) {
    final binding = bindings[i];
    final entry = entries[i];
    if (!seenEntries.add(binding.entryId) ||
        !seenSources.add(binding.sourceEnemyDefId) ||
        binding.entryId != entry.entryId ||
        binding.sourceEnemyDefId != entry.sourceEnemyDefId ||
        binding.combatant.enemyDefId != binding.sourceEnemyDefId) {
      throw StateError(
        'tower runtime bindings must match entry/source order bijectively',
      );
    }
  }

  final runtimeIdBySourceId = <String, String>{
    for (var i = 0; i < entries.length; i += 1)
      bindings[i].sourceEnemyDefId: entries.length == 1
          ? bindings[i].sourceEnemyDefId
          : '${bindings[i].sourceEnemyDefId}_w0s$i',
  };
  final translatedSnapshots = <CombatantSnapshot>[];
  for (final binding in bindings) {
    final guardianSourceIds = binding.combatant.guardianDefIds;
    if (guardianSourceIds.toSet().length != guardianSourceIds.length) {
      throw StateError(
        '${binding.sourceEnemyDefId} has duplicate guardian ids',
      );
    }
    final guardianRuntimeIds = <String>[];
    for (final guardianSourceId in guardianSourceIds) {
      if (guardianSourceId == binding.sourceEnemyDefId) {
        throw StateError('${binding.sourceEnemyDefId} cannot guard itself');
      }
      final guardianRuntimeId = runtimeIdBySourceId[guardianSourceId];
      if (guardianRuntimeId == null) {
        throw StateError(
          '${binding.sourceEnemyDefId} has dangling guardian '
          '$guardianSourceId',
        );
      }
      guardianRuntimeIds.add(guardianRuntimeId);
    }
    translatedSnapshots.add(
      binding.combatant.copyWith(guardianDefIds: guardianRuntimeIds),
    );
  }

  final player = Phase0aStageContentMapper.mapPlayerOnly(
    contentId: request.contentRef.contentId,
    playerSnapshot: request.playerSnapshot,
    numbers: request.numbers,
  );
  final arena = request.numbers.phase0aArena;
  final actorByEntryId = <String, Phase0aActor>{};
  final combatants = <Phase0aCombatantInput>[
    Phase0aCombatantInput(
      actorId: player.initialPlayer.id,
      snapshot: request.playerSnapshot,
    ),
  ];
  final skillsByActor = <String, List<Phase0aEnemySkillBinding>>{};
  final basicQiByActor = <String, int>{};
  final basicPowerByActor = <String, int>{};
  final sourceByActor = <String, String>{};
  for (var i = 0; i < entries.length; i += 1) {
    final entry = entries[i];
    final sourceId = bindings[i].sourceEnemyDefId;
    final runtimeId = runtimeIdBySourceId[sourceId]!;
    final snapshot = translatedSnapshots[i];
    final chargeCast = Phase0aStageContentMapper.preResolveTopLevelChargeCast(
      snapshot: snapshot,
      arena: arena,
      chargeTicks: request.numbers.combat.bossCharge.defaultChargeTicks,
      defenseFlags: player.defenseTuning?.skillAttackFlags,
    );
    final actor = Phase0aStageContentMapper.buildEnemyActor(
      arena: arena,
      snapshot: snapshot,
      actorId: runtimeId,
      position: Phase0aStageContentMapper.enemyPositionForSlot(
        arena: arena,
        slot: i,
        count: entries.length,
      ),
      chargeCast: chargeCast,
      phaseChargeCasts: Phase0aStageContentMapper.preResolvePhaseChargeCasts(
        snapshot: snapshot,
        arena: arena,
        chargeTicks: request.numbers.combat.bossCharge.defaultChargeTicks,
        defenseFlags: player.defenseTuning?.skillAttackFlags,
      ),
      staggerTicksTotal: request.numbers.combat.bossCharge.defaultStaggerTicks,
      postureConfig: Phase0aStageContentMapper.postureConfig(
        request.numbers.combat.posture,
      ),
      guardianRuntimeIds: snapshot.guardianDefIds,
      guardianWardMult: snapshot.guardianWardMult,
      guardInterceptsInterrupt: snapshot.guardInterceptsInterrupt,
      vulnerabilityMult: snapshot.vulnerabilityMult,
    );
    actorByEntryId[entry.entryId] = actor;
    combatants.add(
      Phase0aCombatantInput(actorId: runtimeId, snapshot: snapshot),
    );
    skillsByActor[runtimeId] =
        Phase0aStageContentMapper.preResolveEnemySkillBindings(
          arena: arena,
          snapshot: snapshot,
        );
    final basic = Phase0aStageContentMapper.requiredBasicSkillOf(
      snapshot,
      actorId: runtimeId,
    );
    basicQiByActor[runtimeId] = basic.qiDelta;
    basicPowerByActor[runtimeId] = basic.powerMultiplier;
    sourceByActor[runtimeId] = sourceId;
  }
  final enemyAi = Phase0aEnemyAiAdapter(
    attackRange: arena.enemyAttackRange,
    attackHalfArcRadians: arena.enemyAttackHalfArcRadians,
    attackCooldownSeconds: arena.enemyAttackCooldownSeconds,
    skillBindingsByActor: Map.unmodifiable(skillsByActor),
    basicQiDeltaByActor: Map.unmodifiable(basicQiByActor),
    basicPowerMultiplierByActor: Map.unmodifiable(basicPowerByActor),
    postureBasicPowerMultiplier: arena.basicPowerMultiplier,
    defenseTuning: player.defenseTuning,
  );
  final route = MigratedCombatStageEncounterRoute(
    request.contentRef.contentId,
    encounter,
  );
  final plan = buildPhase0aMigratedEncounterPlan(
    route,
    tickDuration: Duration(
      microseconds: (arena.fixedDeltaSeconds * Duration.microsecondsPerSecond)
          .round(),
    ),
    resolveEnemyId: (entry) {
      final sourceId = entry.sourceEnemyDefId;
      final runtimeId = sourceId == null ? null : runtimeIdBySourceId[sourceId];
      if (runtimeId == null) {
        throw StateError('tower entry has no runtime id: ${entry.entryId}');
      }
      return runtimeId;
    },
    playerId: player.initialPlayer.id,
    createActor: (entry, runtimeEnemyId) {
      final actor = actorByEntryId[entry.entryId];
      if (actor == null || actor.id != runtimeEnemyId) {
        throw StateError(
          'tower actor binding changed authoritative runtime id',
        );
      }
      return actor;
    },
    initialState: Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: player.initialPlayer,
      enemies: List.unmodifiable(actorByEntryId.values),
      skillSlots: player.skillSlots,
    ),
    combatants: combatants,
    moveBindings: player.moveBindings,
    playerAdapter: player.playerAdapter,
    enemyAiAdapter: enemyAi,
    startWithAllEntriesActive: true,
  );
  final tokensByActor = <String, Phase0aEncounterTokenBinding>{
    for (final actorId in sourceByActor.keys)
      actorId: const Phase0aEncounterTokenBinding(
        kind: AttackTokenKind.melee,
        priority: 0,
        tag: 'tower_existing_ai',
        visibility: 'visible',
        isOffscreen: false,
        isHighImpact: false,
        isUnblockableArea: false,
        spawnGraceTicksRemaining: 0,
        telegraphReady: true,
      ),
  };
  final host = Phase0aEncounterHost.fromPlan(
    plan: plan,
    nextStageId: null,
    numbers: request.numbers,
    rng: request.rng,
    // Existing tower AI has no attack-token throttling. Retaining that exact
    // behavior is part of this foundation gate; a later floor migration may
    // opt in only with separate tuning/feel evidence.
    tokenRequestMapper: (_) => null,
    objectiveEventSource: buildPhase0aMainlineObjectiveEventSource(
      encounter: encounter,
      roster: plan.roster,
    ),
    tokenBindingsByActorId: tokensByActor,
  );
  return Phase0aTowerCombatSession(
    contentRef: request.contentRef,
    routeMode: Phase0aTowerEncounterRouteMode.migrated,
    flow: host.flow,
    combatants: host.mapping!.combatants,
    playerAdapter: host.mapping!.playerAdapter,
    sourceEnemyDefIdByActorId: sourceByActor,
    sourceEnemyDefIdsInEntryOrder: bindings
        .map((binding) => binding.sourceEnemyDefId)
        .toList(),
    encounterCount: 1,
    activeLimit: encounter.spawnConfig.activeLimit,
    settle: ({required outcome, required finalState, required events}) => host
        .settle(outcome: outcome, finalState: finalState, events: events)
        .snapshot,
  );
}

bool _sameOrder(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
