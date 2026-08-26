import '../../../data/defs/combat_encounter_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/validation/combat_stage_encounter_route_selector.dart';
import '../../battle/application/phase0a/phase0a_encounter_host.dart';
import '../../battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import '../../battle/application/phase0a/phase0a_encounter_migration_resolver.dart';
import '../../battle/application/phase0a/phase0a_explicit_objective_event_source.dart';
import '../../battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import '../../battle/application/phase0a/phase0a_enemy_skill_binding.dart';
import '../../battle/application/phase0a/phase0a_migrated_encounter_plan_builder.dart';
import '../../battle/domain/phase0a/phase0a_combat_intent.dart';
import '../../battle/domain/phase0a/phase0a_combat_model.dart';
import '../../battle/domain/phase0a/attack_token_director.dart';
import '../../battle/domain/phase0a/phase0a_enemy_behavior_profile.dart';
import 'phase0a_mainline_encounter_host.dart';

Future<Phase0aEncounterHost?> createFreshPhase0aMainlineEncounter(
  Phase0aMainlineEncounterHostBuildRequest request,
) async {
  final repository = GameRepository.instance;
  final authoritativeMode = await request.routeAuthority?.modeForStage(
    stageId: request.stage.id,
  );
  final catalog = request.catalogOverride ?? repository.combatCatalog;
  // A repository without the optional production catalog is the pre-migration
  // runtime. Keep that runtime on its legacy path; once a catalog is present,
  // only an explicit legacy assignment may return null.
  if (catalog == null) {
    if (authoritativeMode == Phase0aMainlineEncounterRouteMode.migrated) {
      throw StateError(
        'migrated mainline route has no combat catalog: ${request.stage.id}',
      );
    }
    return null;
  }
  final assignment = catalog.assignmentForStage(request.stage.id);
  if (assignment == null) {
    if (authoritativeMode == Phase0aMainlineEncounterRouteMode.migrated) {
      throw StateError(
        'migrated mainline route has no catalog assignment: ${request.stage.id}',
      );
    }
    return null;
  }
  final route = selectCombatStageEncounterRoute(
    manifest: catalog,
    stageId: request.stage.id,
    migrationResolver: Phase0aEncounterMigrationResolver(
      legacyContentIds: catalog.stageAssignments
          .where(
            (item) =>
                item.migrationState == CombatEncounterMigrationState.legacy,
          )
          .map((item) => item.stageId),
    ),
    hasLegacyContent:
        assignment.migrationState == CombatEncounterMigrationState.legacy,
  );
  if (route is LegacyCombatStageEncounterRoute) return null;
  final migratedRoute = route as MigratedCombatStageEncounterRoute;
  final runtime = await request.runtimeBindingSource.load(
    stageId: migratedRoute.stageId,
    encounterId: migratedRoute.encounter.id,
    cycleIndex: request.cycleIndex,
  );
  if (runtime.stageId != migratedRoute.stageId ||
      runtime.encounterId != migratedRoute.encounter.id) {
    throw StateError('runtime binding route mismatch');
  }
  return _assemble(
    request: request,
    route: migratedRoute,
    runtime: runtime,
    repository: repository,
  );
}

Phase0aEncounterHost _assemble({
  required Phase0aMainlineEncounterHostBuildRequest request,
  required MigratedCombatStageEncounterRoute route,
  required Phase0aMainlineEncounterRuntimeBindingBundle runtime,
  required GameRepository repository,
}) {
  final entries = route.encounter.spawnEntries;
  final bindings = runtime.actorBindingsByEntryId;
  final expectedIds = entries.map((entry) => entry.entryId).toSet();
  if (bindings.length != expectedIds.length ||
      !bindings.keys.toSet().containsAll(expectedIds)) {
    throw StateError('runtime bindings must cover every migrated spawn entry');
  }

  final player = request.playerMapping;
  final combatants = <Phase0aCombatantInput>[
    Phase0aCombatantInput(
      actorId: player.initialPlayer.id,
      snapshot: player.snapshot,
    ),
  ];
  final runtimeIds = <String, String>{};
  final skillsByActor = <String, List<Phase0aEnemySkillBinding>>{};
  final basicQiByActor = <String, int>{};
  final basicPowerByActor = <String, int>{};
  final behaviorProfilesByActor = <String, Phase0aEnemyBehaviorProfile>{};
  final tokensByActor = <String, Phase0aEncounterTokenBinding>{};
  final visualAssetPathByActorId = <String, String>{};
  final arena = request.numbers.phase0aArena;
  final activeLimit = route.encounter.spawnConfig.activeLimit;
  final positionKeys = <String>[];
  for (var ordinal = 0; ordinal < entries.length; ordinal += 1) {
    final entry = entries[ordinal];
    final binding = bindings[entry.entryId]!;
    final runtimeId =
        '${request.stage.id}/${route.encounter.id}/actor-${ordinal.toString().padLeft(3, '0')}';
    final actor = binding.createActor(runtimeId);
    if (actor.id != runtimeId ||
        actor.side != Phase0aSide.enemy ||
        !actor.isAlive) {
      throw StateError('invalid migrated actor binding ${entry.entryId}');
    }
    final position = actor.position;
    final positionKey = '${position.x}:${position.y}';
    positionKeys.add(positionKey);
    if (positionKeys.length >= activeLimit) {
      final windowStart = positionKeys.length - activeLimit;
      final window = positionKeys.sublist(windowStart, positionKeys.length);
      if (window.toSet().length != activeLimit) {
        throw StateError(
          'Encounter ${runtime.encounterId} has duplicate positions in an active window',
        );
      }
    }
    if (position.x < arena.arenaMinX ||
        position.x > arena.arenaMaxX ||
        position.y < arena.arenaMinY ||
        position.y > arena.arenaMaxY) {
      throw StateError(
        'Encounter ${runtime.encounterId} actor position is outside arena bounds',
      );
    }
    runtimeIds[entry.entryId] = runtimeId;
    combatants.add(
      Phase0aCombatantInput(actorId: runtimeId, snapshot: binding.combatant),
    );
    skillsByActor[runtimeId] = binding.enemySkillBindings;
    basicQiByActor[runtimeId] = binding.basicQiDelta;
    basicPowerByActor[runtimeId] = binding.basicPowerMultiplier;
    final behaviorProfile = binding.behaviorProfile;
    if (behaviorProfile != null) {
      behaviorProfilesByActor[runtimeId] = behaviorProfile;
    }
    tokensByActor[runtimeId] = binding.token;
    visualAssetPathByActorId[runtimeId] = binding.visualAssetPath;
  }
  final enemyAi = Phase0aEnemyAiAdapter(
    attackRange: arena.enemyAttackRange,
    attackHalfArcRadians: arena.enemyAttackHalfArcRadians,
    attackCooldownSeconds:
        request.numbers.phase0aArena.enemyAttackCooldownSeconds,
    skillBindingsByActor: skillsByActor,
    basicQiDeltaByActor: basicQiByActor,
    basicPowerMultiplierByActor: basicPowerByActor,
    postureBasicPowerMultiplier: arena.basicPowerMultiplier,
    behaviorProfilesByActor: behaviorProfilesByActor,
    defenseTuning: player.defenseTuning,
  );
  final plan = buildPhase0aMigratedEncounterPlan(
    route,
    tickDuration: runtime.tickDuration,
    resolveEnemyId: (entry) => runtimeIds[entry.entryId]!,
    playerId: player.initialPlayer.id,
    createActor: (entry, runtimeEnemyId) {
      final actor = bindings[entry.entryId]!.createActor(runtimeEnemyId);
      if (actor.id != runtimeEnemyId) {
        throw StateError('actor factory changed the authoritative runtime id');
      }
      return actor;
    },
    initialState: Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: player.initialPlayer,
      enemies: const [],
      skillSlots: player.skillSlots,
    ),
    combatants: combatants,
    moveBindings: player.moveBindings,
    playerAdapter: player.playerAdapter,
    enemyAiAdapter: enemyAi,
  );
  final objectiveSource = Phase0aExplicitObjectiveEventSource(
    roster: plan.roster,
    defeatProjectionsByActorId: {
      for (final entry in entries)
        runtimeIds[entry.entryId]!: [
          Phase0aTargetDefeatProjection(entry.entryId),
        ],
    },
    externalProjectors: const [],
  );
  AttackTokenRequest? tokenMapper(Phase0aIntent intent) {
    if (intent is Phase0aMoveIntent) {
      return null;
    }
    final token = tokensByActor[intent.actorId];
    if (token == null) {
      throw StateError('missing token binding ${intent.actorId}');
    }
    return AttackTokenRequest(
      actorId: intent.actorId,
      kind: token.kind,
      priority: token.priority,
      isOffscreen: token.isOffscreen,
      isHighImpact: token.isHighImpact,
      isUnblockableArea: token.isUnblockableArea,
      spawnGraceTicksRemaining: token.spawnGraceTicksRemaining,
      telegraphReady: token.telegraphReady,
    );
  }

  return Phase0aEncounterHost.fromPlan(
    plan: plan,
    nextStageId: nextMainlineStageId(repository, request.stage.id),
    numbers: request.numbers,
    rng: request.rng,
    tokenRequestMapper: tokenMapper,
    objectiveEventSource: objectiveSource,
    visualAssetPathByActorId: visualAssetPathByActorId,
  );
}

Future<Phase0aEncounterHost?> buildPhase0aMainlineProductionEncounterHost(
  Phase0aMainlineEncounterHostBuildRequest request,
) => createFreshPhase0aMainlineEncounter(request);

String? nextMainlineStageId(GameRepository repository, String stageId) {
  final successors = repository.stageDefs.values
      .where((stage) => stage.prevStageId == stageId)
      .map((stage) => stage.id)
      .toList(growable: false);
  if (successors.length > 1) throw StateError('stage has multiple successors');
  return successors.isEmpty ? null : successors.single;
}
