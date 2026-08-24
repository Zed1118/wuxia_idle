import 'dart:math';

import '../../../../data/defs/skill_def.dart';
import '../../../../data/numbers_config.dart';
import '../../../../data/validation/combat_encounter_roster_mapper.dart';
import '../../../../data/validation/combat_encounter_runtime_contract_mapper.dart';
import '../../../../data/validation/combat_stage_encounter_route_selector.dart';
import '../../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../../shared/battle_shared/battle_result.dart';
import '../../domain/phase0a/attack_token_director.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_damage_kind.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import 'attack_token_enforcing_batch_gate.dart';
import 'phase0a_battle_flow.dart';
import 'phase0a_encounter_mapping.dart';
import 'phase0a_battle_snapshot_factory.dart';
import 'phase0a_encounter_objective_event_source.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_enemy_skill_binding.dart';
import 'phase0a_headless_runner.dart';
import 'phase0a_migrated_encounter_plan_builder.dart';
import 'phase0a_player_bot_adapter.dart';
import 'phase0a_player_input_adapter.dart';
import 'phase0a_production_flow_assembler.dart';
import 'phase0a_settlement_adapter.dart';

/// Typed runtime binding for one production spawn entry.
///
/// A data session resolves entrance/position, behavior profile, attack set and
/// visual variant before creating this object. The host only consumes the
/// already-resolved actor and snapshot; it never switches on content IDs.
final class Phase0aEncounterActorRuntimeBinding {
  const Phase0aEncounterActorRuntimeBinding({
    required this.createActor,
    required this.combatant,
    required this.token,
    required this.enemySkillBindings,
    required this.basicQiDelta,
    required this.entrance,
    required this.behaviorAiProfile,
    required this.attackSet,
    required this.visualVariant,
    required this.visualAssetPath,
  });

  final Phase0aActor Function(String runtimeEnemyId) createActor;
  final CombatantSnapshot combatant;
  final Phase0aEncounterTokenBinding token;
  final List<Phase0aEnemySkillBinding> enemySkillBindings;
  final int basicQiDelta;
  final String entrance;
  final String behaviorAiProfile;
  final String attackSet;
  final String visualVariant;
  final String visualAssetPath;
}

/// Explicit token metadata resolved from the production runtime binding.
/// `tag` and `visibility` remain content-facing diagnostics; the director
/// consumes only the typed request fields below.
final class Phase0aEncounterTokenBinding {
  const Phase0aEncounterTokenBinding({
    required this.kind,
    required this.priority,
    required this.tag,
    required this.visibility,
    required this.isOffscreen,
    required this.isHighImpact,
    required this.isUnblockableArea,
    required this.spawnGraceTicksRemaining,
    required this.telegraphReady,
  });

  final AttackTokenKind kind;
  final int priority;
  final String tag;
  final String visibility;
  final bool isOffscreen;
  final bool isHighImpact;
  final bool isUnblockableArea;
  final int spawnGraceTicksRemaining;
  final bool telegraphReady;
}

/// All non-content runtime inputs needed to compose one migrated encounter.
///
/// Production data loading owns entry lookup, archetype multipliers,
/// skill/asset resolution and candidate/TUNING promotion. The existing
/// assembler remains the only owner of combat flow construction.
final class Phase0aEncounterRuntimeBindings {
  const Phase0aEncounterRuntimeBindings({
    required this.initialState,
    required this.combatants,
    required this.moveBindings,
    required this.playerAdapter,
    required this.enemyAiAdapter,
    required this.resolveEnemyId,
    required this.createActor,
    required this.tokenRequestMapper,
    required this.objectiveEventSource,
  });

  final Phase0aArenaState initialState;
  final List<Phase0aCombatantInput> combatants;
  final Map<Phase0aDamageKind, SkillDef?> moveBindings;
  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aEnemyAiAdapter enemyAiAdapter;
  final CombatEnemyInstanceIdResolver resolveEnemyId;
  final CombatEncounterActorFactory createActor;
  final Phase0aAttackTokenEnforcementRequestMapper tokenRequestMapper;
  final Phase0aEncounterObjectiveEventSource objectiveEventSource;
}

/// Dynamic Encounter host over the existing Phase0A flow contract.
///
/// Manual, auto and headless callers all receive the same [flow]. This class
/// only exposes driving and settlement seams; it does not contain reducer,
/// spawn, AI, token, objective or reward rules.
final class Phase0aEncounterHost {
  Phase0aEncounterHost._({
    required this.stageId,
    required this.nextStageId,
    required this.flow,
    this.mapping,
    this.visualAssetPathByActorId,
  });

  factory Phase0aEncounterHost.fromRuntimeBindings({
    required MigratedCombatStageEncounterRoute route,
    required Phase0aEncounterRuntimeBindings bindings,
    required Duration tickDuration,
    required String? nextStageId,
    required NumbersConfig numbers,
    required Random rng,
  }) {
    final plan = buildPhase0aMigratedEncounterPlan(
      route,
      tickDuration: tickDuration,
      resolveEnemyId: bindings.resolveEnemyId,
      playerId: bindings.initialState.player.id,
      createActor: bindings.createActor,
      initialState: bindings.initialState,
      combatants: bindings.combatants,
      moveBindings: bindings.moveBindings,
      playerAdapter: bindings.playerAdapter,
      enemyAiAdapter: bindings.enemyAiAdapter,
    );
    return Phase0aEncounterHost.fromPlan(
      plan: plan,
      nextStageId: nextStageId,
      numbers: numbers,
      rng: rng,
      tokenRequestMapper: bindings.tokenRequestMapper,
      objectiveEventSource: bindings.objectiveEventSource,
    );
  }

  factory Phase0aEncounterHost.fromPlan({
    required Phase0aMigratedEncounterPlan plan,
    required String? nextStageId,
    required NumbersConfig numbers,
    required Random rng,
    required Phase0aAttackTokenEnforcementRequestMapper tokenRequestMapper,
    required Phase0aEncounterObjectiveEventSource objectiveEventSource,
    Map<String, String>? visualAssetPathByActorId,
  }) {
    final flow = Phase0aProductionFlowAssembler.assembleMigratedEncounterPlan(
      plan: plan,
      numbers: numbers,
      rng: rng,
      tokenRequestMapper: tokenRequestMapper,
      objectiveEventSource: objectiveEventSource,
    );
    return Phase0aEncounterHost._(
      stageId: plan.stageId,
      nextStageId: nextStageId,
      flow: flow,
      mapping: plan.mapping,
      visualAssetPathByActorId: visualAssetPathByActorId,
    );
  }

  /// Test and adapter seam for a preassembled flow. Production callers should
  /// use [fromRuntimeBindings] or [fromPlan].
  factory Phase0aEncounterHost.fromFlow({
    required String stageId,
    required String? nextStageId,
    required Phase0aBattleFlow flow,
    Phase0aEncounterMapping? mapping,
    Map<String, String>? visualAssetPathByActorId,
  }) => Phase0aEncounterHost._(
    stageId: stageId,
    nextStageId: nextStageId,
    flow: flow,
    mapping: mapping,
    visualAssetPathByActorId: visualAssetPathByActorId,
  );

  final String stageId;
  final String? nextStageId;
  final Phase0aBattleFlow flow;
  final Phase0aEncounterMapping? mapping;
  final Map<String, String>? visualAssetPathByActorId;

  List<Phase0aEvent> advanceManual({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) => flow.advance(deltaSeconds: deltaSeconds, command: command);

  List<Phase0aEvent> advanceAuto({
    required double deltaSeconds,
    required Phase0aPlayerBotAdapter bot,
  }) => flow.advance(
    deltaSeconds: deltaSeconds,
    command: bot.commandFor(flow.state),
  );

  Phase0aHeadlessResult runHeadless({
    required Phase0aPlayerBotAdapter bot,
    required double deltaSeconds,
    required int maxTicks,
  }) => Phase0aHeadlessRunner.runToEnd(
    flow: flow,
    bot: bot,
    deltaSeconds: deltaSeconds,
    maxTicks: maxTicks,
  );

  Future<Phase0aHeadlessResult> runHeadlessAsync({
    required Phase0aPlayerBotAdapter bot,
    required double deltaSeconds,
    required int maxTicks,
    required int yieldEveryTicks,
  }) => Phase0aHeadlessRunner.runToEndAsync(
    flow: flow,
    bot: bot,
    deltaSeconds: deltaSeconds,
    maxTicks: maxTicks,
    yieldEveryTicks: yieldEveryTicks,
  );

  Phase0aEncounterHostSettlement settle({
    required Phase0aBattleOutcome outcome,
    required Phase0aArenaState finalState,
    required List<Phase0aEvent> events,
  }) {
    final mapping = this.mapping;
    if (mapping == null) {
      throw StateError('settlement requires a migrated encounter mapping');
    }
    final snapshot = Phase0aSettlementAdapter.fromEncounterMapping(
      mapping: mapping,
      outcome: outcome,
      finalState: finalState,
      events: events,
    );
    return Phase0aEncounterHostSettlement(
      stageId: stageId,
      nextStageId: nextStageId,
      snapshot: snapshot,
    );
  }
}

/// Typed result passed from dynamic encounter settlement to the mainline
/// admission layer. Durable reward/claim identity remains an outer concern.
final class Phase0aEncounterHostSettlement {
  const Phase0aEncounterHostSettlement({
    required this.stageId,
    required this.nextStageId,
    required this.snapshot,
  });

  final String stageId;
  final String? nextStageId;
  final CombatSettlementSnapshot snapshot;

  bool get canAdmitNextStage =>
      nextStageId != null && snapshot.result == BattleResult.leftWin;
}
