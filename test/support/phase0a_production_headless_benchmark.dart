import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_settlement_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';

enum HeadlessBenchmarkContentKind { mainline, tower, lightFoot, massBattle }

/// Tool-only identity. Production content IDs are retained; formation is an
/// additional scenario dimension, not a new stage or automation permission.
final class HeadlessBenchmarkContent {
  const HeadlessBenchmarkContent.mainline(this.contentId)
    : kind = HeadlessBenchmarkContentKind.mainline,
      formation = null;
  const HeadlessBenchmarkContent.tower(this.contentId)
    : kind = HeadlessBenchmarkContentKind.tower,
      formation = null;
  const HeadlessBenchmarkContent.lightFoot(this.contentId)
    : kind = HeadlessBenchmarkContentKind.lightFoot,
      formation = null;
  const HeadlessBenchmarkContent.massBattle(
    this.contentId, {
    required Formation formation,
  }) : kind = HeadlessBenchmarkContentKind.massBattle,
       // Keep the constructor parameter non-nullable for this variant.
       // ignore: prefer_initializing_formals
       formation = formation;

  final String contentId;
  final HeadlessBenchmarkContentKind kind;
  final Formation? formation;
  String get variant => formation?.name ?? 'default';
  String get caseId => '${kind.name}/$contentId/$variant';

  @override
  bool operator ==(Object other) =>
      other is HeadlessBenchmarkContent &&
      kind == other.kind &&
      contentId == other.contentId &&
      formation == other.formation;
  @override
  int get hashCode => Object.hash(kind, contentId, formation);
}

/// Current combat assembly scope, not admission, rewards or saves. No route
/// override: later tower floors remain legacy and inner-demon stays manual-only.
List<HeadlessBenchmarkContent> productionHeadlessManifest(
  GameRepository repository,
) {
  final stages =
      repository.stageDefs.values
          .where((stage) => stage.stageType == StageType.mainline)
          .map((stage) => stage.id)
          .toList()
        ..sort();
  final floors = repository.towerFloors.toList()
    ..sort((a, b) => a.floorIndex.compareTo(b.floorIndex));
  final activities =
      repository.stageDefs.values
          .where(
            (stage) =>
                stage.stageType == StageType.lightFoot ||
                stage.stageType == StageType.massBattle,
          )
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  return List.unmodifiable([
    for (final id in stages) HeadlessBenchmarkContent.mainline(id),
    for (final floor in floors)
      HeadlessBenchmarkContent.tower('tower_${floor.floorIndex}'),
    for (final stage in activities)
      if (stage.stageType == StageType.lightFoot)
        HeadlessBenchmarkContent.lightFoot(stage.id)
      else
        for (final formation in Formation.values)
          HeadlessBenchmarkContent.massBattle(stage.id, formation: formation),
  ]);
}

enum HeadlessBenchmarkMode { sync, async }

typedef HeadlessSettlementBuilder =
    CombatSettlementSnapshot Function({
      required Phase0aBattleOutcome outcome,
      required Phase0aArenaState finalState,
      required List<Phase0aEvent> events,
    });

final class ProductionHeadlessSession {
  ProductionHeadlessSession(
    this.route,
    this.flow,
    this.bot,
    this.settle,
    List<Phase0aCombatantInput> combatants,
  ) : combatants = List.unmodifiable(combatants);
  final String route;
  final Phase0aBattleFlow flow;
  final Phase0aPlayerBotAdapter bot;
  final HeadlessSettlementBuilder settle;
  final List<Phase0aCombatantInput> combatants;
}

Future<ProductionHeadlessSession> createProductionHeadlessSession({
  required GameRepository repository,
  required HeadlessBenchmarkContent content,
  required CombatantSnapshot player,
  required int seed,
}) async {
  final rng = newMathRandom(seed: seed);
  if (content.kind == HeadlessBenchmarkContentKind.lightFoot ||
      content.kind == HeadlessBenchmarkContentKind.massBattle) {
    final stage = repository.stageDefs[content.contentId];
    if (stage == null) {
      throw ArgumentError('unknown activity: ${content.contentId}');
    }
    final mapping = content.kind == HeadlessBenchmarkContentKind.lightFoot
        ? Phase0aStageContentMapper.mapLightFoot(
            stage: stage,
            playerSnapshot: player,
            numbers: repository.numbers,
            cycleIndex: 1,
          )
        : Phase0aStageContentMapper.mapMassBattle(
            stage: stage,
            playerSnapshot: player,
            numbers: repository.numbers,
            formation: content.formation!,
            cycleIndex: 1,
          );
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: mapping.initialState,
      waves: mapping.waves,
      combatants: mapping.combatants,
      moveBindings: mapping.moveBindings,
      numbers: repository.numbers,
      rng: rng,
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
      waveTransitionPolicy: mapping.waveTransitionPolicy,
    );
    return ProductionHeadlessSession(
      content.kind == HeadlessBenchmarkContentKind.lightFoot
          ? 'legacy_light_foot'
          : 'legacy_mass_battle',
      flow,
      Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
      ({required outcome, required finalState, required events}) =>
          Phase0aSettlementAdapter.fromMapping(
            mapping: mapping,
            outcome: outcome,
            finalState: finalState,
            events: events,
          ),
      mapping.combatants,
    );
  }
  if (content.kind == HeadlessBenchmarkContentKind.mainline) {
    final stage = repository.stageDefs[content.contentId];
    if (stage == null || stage.stageType != StageType.mainline) {
      throw ArgumentError(
        'not a mainline benchmark entry: ${content.contentId}',
      );
    }
    final host = await createFreshPhase0aMainlineEncounter(
      Phase0aMainlineEncounterHostBuildRequest(
        stage: stage,
        playerMapping: Phase0aStageContentMapper.mapPlayerOnly(
          contentId: stage.id,
          playerSnapshot: player,
          numbers: repository.numbers,
        ),
        numbers: repository.numbers,
        cycleIndex: 1,
        rng: rng,
        runtimeBindingSource:
            const Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
              loader: loadPhase0aMainlineRuntimeBindingBundleFromRepository,
            ),
      ),
    );
    if (host == null) {
      throw StateError(
        'mainline benchmark requires production typed route: ${stage.id}',
      );
    }
    return ProductionHeadlessSession(
      'typed_mainline',
      host.flow,
      Phase0aPlayerBotAdapter(
        playerAdapter: host.mapping!.playerAdapter,
        objectiveContinuationCommandBuilder:
            host.objectiveContinuationCommandBuilder,
      ),
      ({required outcome, required finalState, required events}) => host
          .settle(outcome: outcome, finalState: finalState, events: events)
          .snapshot,
      host.mapping!.combatants,
    );
  }
  final floor = repository.towerFloors.singleWhere(
    (floor) => 'tower_${floor.floorIndex}' == content.contentId,
  );
  final session = await createFreshPhase0aTowerCombatSession(
    Phase0aTowerCombatSessionBuildRequest(
      contentRef: CombatContentRef.tower(content.contentId),
      floor: floor,
      playerSnapshot: player,
      numbers: repository.numbers,
      cycleIndex: 1,
      rng: rng,
    ),
  );
  return ProductionHeadlessSession(
    session.routeMode == Phase0aTowerEncounterRouteMode.migrated
        ? 'typed_tower'
        : 'legacy_tower',
    session.flow,
    Phase0aPlayerBotAdapter(playerAdapter: session.playerAdapter),
    session.settle,
    session.combatants,
  );
}

final class HeadlessBenchmarkRun {
  const HeadlessBenchmarkRun({
    required this.route,
    required this.mode,
    required this.result,
    required this.settlement,
    required this.assemblyMicroseconds,
    required this.simulationMicroseconds,
    required this.settlementMicroseconds,
    this.encounterFacts,
    this.waveFacts,
  });
  final String route;
  final HeadlessBenchmarkMode mode;
  final Phase0aHeadlessResult result;
  final CombatSettlementSnapshot? settlement;
  final String? encounterFacts;
  final String? waveFacts;
  final int assemblyMicroseconds,
      simulationMicroseconds,
      settlementMicroseconds;

  Map<String, Object?> toJson(double deltaSeconds) => {
    'route': route,
    'mode': mode.name,
    'outcome': result.outcome.name,
    'timed_out': result.timedOut,
    'simulated_ticks': result.ticks,
    'simulated_seconds': result.ticks * deltaSeconds,
    'assembly_microseconds': assemblyMicroseconds,
    'simulation_microseconds': simulationMicroseconds,
    'settlement_microseconds': settlementMicroseconds,
    'event_count': result.events.length,
    'event_record_count': result.eventRecords.length,
    'player_hp_end': result.finalState.player.currentHealth,
    'encounter_state': encounterFacts == null
        ? null
        : jsonDecode(encounterFacts!),
    'wave_state': waveFacts == null ? null : jsonDecode(waveFacts!),
    'settlement': settlement == null
        ? null
        : headlessSettlementFacts(settlement!),
  };
}

/// Wall clock deliberately excludes catalog loading, profile seeding, equality
/// checks and serialization. Async time includes the production event-loop yield.
Future<HeadlessBenchmarkRun> measureProductionHeadless({
  required GameRepository repository,
  required HeadlessBenchmarkContent content,
  required CombatantSnapshot player,
  required int seed,
  required HeadlessBenchmarkMode mode,
  int? maxTicks,
  int yieldEveryTicks = 32, // Same cadence as Phase0aSweepHeadlessRunner.
}) async {
  final clock = Stopwatch()..start();
  final session = await createProductionHeadlessSession(
    repository: repository,
    content: content,
    player: player,
    seed: seed,
  );
  final assemblyUs = clock.elapsedMicroseconds;
  clock.reset();
  final arena = repository.numbers.phase0aArena;
  final result = switch (mode) {
    HeadlessBenchmarkMode.sync => Phase0aHeadlessRunner.runToEnd(
      flow: session.flow,
      bot: session.bot,
      deltaSeconds: arena.fixedDeltaSeconds,
      maxTicks: maxTicks ?? arena.maxSimulationTicks,
    ),
    HeadlessBenchmarkMode.async => await Phase0aHeadlessRunner.runToEndAsync(
      flow: session.flow,
      bot: session.bot,
      deltaSeconds: arena.fixedDeltaSeconds,
      maxTicks: maxTicks ?? arena.maxSimulationTicks,
      yieldEveryTicks: yieldEveryTicks,
    ),
  };
  final simulationUs = clock.elapsedMicroseconds;
  clock.reset();
  final settlement = result.timedOut
      ? null
      : session.settle(
          outcome: result.outcome,
          finalState: result.finalState,
          events: result.events,
        );
  clock.stop();
  return HeadlessBenchmarkRun(
    route: session.route,
    mode: mode,
    result: result,
    settlement: settlement,
    assemblyMicroseconds: assemblyUs,
    simulationMicroseconds: simulationUs,
    settlementMicroseconds: clock.elapsedMicroseconds,
    encounterFacts: session.flow is Phase0aEncounterFlow
        ? _encounterFacts(session.flow as Phase0aEncounterFlow)
        : null,
    waveFacts: session.flow is Phase0aWaveBattleFlow
        ? _waveFacts(session.flow as Phase0aWaveBattleFlow, result.events)
        : null,
  );
}

/// All persisted-settlement input fields, ordered collections kept in order.
/// This is not a reward grant and never touches Isar.
Map<String, Object?> headlessSettlementFacts(CombatSettlementSnapshot s) => {
  'result': s.result?.name,
  'total_ticks': s.totalTicks,
  'had_actions': s.hadActions,
  'player_character_id': s.playerCharacterId,
  'participants': [
    for (final p in s.participants) [p.characterId, p.currentHp, p.maxHp],
  ],
  'skill_casts': [
    for (final c in s.skillCasts) [c.tick, c.characterId, c.skillId],
  ],
  'total_damage': s.totalDamage,
  'critical_count': s.criticalCount,
  'damage_by_character_id': {
    for (final id in s.damageByCharacterId.keys.toList()..sort())
      '$id': s.damageByCharacterId[id],
  },
};

/// Exact domain equality, not hashCode (which is not a portable replay digest).
/// Timing, event count alone, and summary statistics cannot establish parity.
void requireSameHeadlessResult(
  HeadlessBenchmarkRun expected,
  HeadlessBenchmarkRun actual,
) {
  final a = expected.result, b = actual.result;
  final differing = <String>[
    if (expected.route != actual.route) 'route',
    if (a.outcome != b.outcome) 'outcome',
    if (a.ticks != b.ticks) 'ticks',
    if (a.finalState != b.finalState) 'finalState',
    if (expected.encounterFacts != actual.encounterFacts) 'encounterState',
    if (expected.waveFacts != actual.waveFacts) 'waveState',
    if (!listEquals(a.events, b.events)) 'events',
    if (!listEquals(a.eventRecords, b.eventRecords)) 'eventRecords',
    if (!_sameSettlement(expected.settlement, actual.settlement)) 'settlement',
  ];
  if (differing.isNotEmpty) {
    throw StateError('headless same-seed mismatch: $differing');
  }
}

String _waveFacts(Phase0aWaveBattleFlow flow, List<Phase0aEvent> events) {
  final policy = flow.waveTransitionPolicy;
  return jsonEncode({
    'waves': [
      for (final wave in flow.waves)
        [for (final enemy in wave.enemies) enemy.id],
    ],
    'started_wave_indices': [
      for (final event in events.whereType<Phase0aWaveStarted>())
        event.waveIndex,
    ],
    'cleared_wave_indices': [
      for (final event in events.whereType<Phase0aWaveCleared>())
        event.waveIndex,
    ],
    'transition_policy': policy == null
        ? null
        : {
            'heal_player_to_full': policy.healPlayerToFull,
            'qi_recovery_pct': policy.qiRecoveryPct,
            'reset_attack_cooldown': policy.resetAttackCooldown,
            'reset_skill_cooldowns': policy.resetSkillCooldowns,
            'intermission_seconds': policy.intermissionSeconds,
          },
  });
}

String _encounterFacts(Phase0aEncounterFlow flow) {
  final spawn = flow.spawnState;
  final objective = flow.objectiveProgress;
  // Objective equality includes a private owner token, deliberately different
  // for fresh sessions. Compare every public progress field instead.
  return jsonEncode({
    'spawn': [
      spawn.tick,
      spawn.totalCount,
      spawn.activeCount,
      spawn.warningCount,
      spawn.pendingCount,
      spawn.removedCount,
      [
        for (final unit in spawn.units)
          [
            unit.entryId,
            unit.enemyId,
            unit.stage.name,
            unit.remainingWarningTicks,
            unit.remainingGraceTicks,
            unit.enteredTick,
            unit.removedTick,
          ],
      ],
    ],
    'objectives': objective == null
        ? null
        : [
            objective.completed,
            [
              for (final clause in objective.clauses)
                [
                  clause.id,
                  clause.progress.completed,
                  clause.progress.elapsed.inMicroseconds,
                  clause.progress.satisfied.toList()..sort(),
                  clause.progress.processedEventIds.toList()..sort(),
                ],
            ],
          ],
  });
}

/// Exact scalar/profile inputs plus ordered content references. Skill/Boss
/// definitions and their decoder code are fingerprinted by the outer wrapper.
Map<String, Object?> headlessPlayerFacts(CombatantSnapshot s) => {
  'character_id': s.characterId,
  'name': s.name,
  'realm_tier': s.realmTier.name,
  'realm_layer': s.realmLayer.name,
  'school': s.school.name,
  'max_hp': s.maxHp,
  'current_hp': s.currentHp,
  'internal_force': s.internalForce,
  'max_qi': s.maxQi,
  'current_qi': s.currentQi,
  'qi_gain_multiplier': s.qiGainMultiplier,
  'qi_cost_reduction_pct': s.qiCostReductionPct,
  'auto_ultimate': s.autoUltimate,
  'speed': s.speed,
  'critical_rate': s.criticalRate,
  'evasion_rate': s.evasionRate,
  'defense_rate': s.defenseRate,
  'equipment_attack': s.totalEquipmentAttack,
  'cultivation_layer': s.mainCultivationLayer.name,
  'weapon_archetype': s.weaponArchetype?.name,
  'basic_attack': s.skillLoadout.basicAttack?.id,
  'skill_slots': [
    for (final slot in CombatantSkillSlot.values)
      [slot.name, s.skillLoadout.skillFor(slot)?.id],
  ],
  'available_skills': [for (final skill in s.availableSkills) skill.id],
  'opening_skill_cooldowns': s.openingSkillCooldowns,
  'skill_uses': s.skillUses,
  'active_buffs': s.activeBuffs,
  'sword_song_resonance': s.swordSongResonanceActive,
  'icon_path': s.iconPath,
  'attack_power_multiplier': s.attackPowerMultiplier,
  'output_multiplier': s.outputMultiplier,
  'is_boss': s.isBoss,
  'charge_skill_id': s.chargeSkillId,
  'boss_phases': s.bossPhases
      ?.map(
        (p) => [
          p.hpThresholdPct,
          p.unlockSkillIds,
          p.aiMode.name,
          p.onEnterMechanic?.name,
          p.titleKey,
        ],
      )
      .toList(),
  'boss_phase_unlock_skills': s.bossPhaseUnlockSkills
      ?.map((skills) => [for (final skill in skills) skill.id])
      .toList(),
  'school_damage_taken_mult': {
    for (final entry in s.schoolDamageTakenMult.entries)
      entry.key.name: entry.value,
  },
  'lineage_role': s.lineageRole?.name,
  'forging_pierce_pct': s.forgingPiercePct,
  'forging_lifesteal_pct': s.forgingLifestealPct,
  'enemy_def_id': s.enemyDefId,
  'guardian_ward_mult': s.guardianWardMult,
  'guardian_def_ids': s.guardianDefIds,
  'vulnerability_mult': s.vulnerabilityMult,
  'guard_intercepts_interrupt': s.guardInterceptsInterrupt,
};

bool _sameSettlement(CombatSettlementSnapshot? a, CombatSettlementSnapshot? b) {
  if (a == null || b == null) return a == b;
  return a.result == b.result &&
      a.totalTicks == b.totalTicks &&
      a.hadActions == b.hadActions &&
      a.playerCharacterId == b.playerCharacterId &&
      a.totalDamage == b.totalDamage &&
      a.criticalCount == b.criticalCount &&
      mapEquals(a.damageByCharacterId, b.damageByCharacterId) &&
      listEquals(
        [for (final p in a.participants) (p.characterId, p.currentHp, p.maxHp)],
        [for (final p in b.participants) (p.characterId, p.currentHp, p.maxHp)],
      ) &&
      listEquals(
        [for (final c in a.skillCasts) (c.tick, c.characterId, c.skillId)],
        [for (final c in b.skillCasts) (c.tick, c.characterId, c.skillId)],
      );
}
