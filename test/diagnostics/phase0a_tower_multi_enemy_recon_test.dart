// Diagnostic only: authored tower multi-enemy reconnaissance, 2026-09-12.
// No production routing/data mutation. Kept with the audit for reproduction.
// Canonical comparison helpers below are copied from the baseline parity test;
// only wave lifecycle sequence offsets and guardian source/runtime IDs normalize.
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/combat_content_ref.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/tower/application/phase0a_tower_encounter_host.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../support/combatant_snapshot_fixture.dart';
import '../support/test_data.dart';

void main() {
  late GameRepository repo;
  setUpAll(() async => repo = await loadTestGameRepository());

  test('diagnostic authored roster and production authority inventory', () {
    final distribution = <String, int>{};
    for (final floor in repo.towerFloors) {
      distribution.update(
        '${floor.enemyTeam.length}',
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
    expect(
      const Phase0aTowerEncounterRouteAuthority.production()
          .migratedFloorIndices,
      {1, 2, 3, 4, 5, 6, 7},
    );
    _emit({
      'kind': 'inventory',
      'distribution': distribution,
      'floors': [
        for (final floor in repo.towerFloors.where((f) => f.floorIndex <= 14))
          {
            'floor': floor.floorIndex,
            'bossKind': floor.bossKind?.name,
            'productionRoute':
                const Phase0aTowerEncounterRouteAuthority.production()
                    .modeForFloor(floor.floorIndex)
                    .name,
            'enemies': [for (final e in floor.enemyTeam) e.id],
          },
      ],
      'deltaSeconds': repo.numbers.phase0aArena.fixedDeltaSeconds,
      'maxSimulationTicks': repo.numbers.phase0aArena.maxSimulationTicks,
    });
  });

  for (final profile in [
    'bot',
    'singleTarget',
    'pressure',
    'defeat',
    'bossMechanics',
  ]) {
    final floors = profile == 'bot'
        ? [1, 8, 9, 10, 11, 12, 13, 14, 32, 42, 49]
        : profile == 'bossMechanics'
        ? [11, 14]
        : profile == 'defeat'
        ? [8, 11, 14]
        : [8, 9, 10, 11, 12, 13, 14];
    for (final floor in floors) {
      for (final cycle in [1, 2]) {
        test('diagnostic $profile floor $floor cycle $cycle', () async {
          await _probe(repo, floor, cycle, profile);
        });
      }
    }
  }
}

void _emit(Map<String, Object?> value) {
  // ignore: avoid_print
  print('TOWER_RECON ${jsonEncode(value)}');
}

Future<void> _probe(
  GameRepository repo,
  int floorIndex,
  int cycle,
  String profile,
) async {
  final floor = repo.getTowerFloor(floorIndex);
  final seed = 20260912 + floorIndex * 10 + cycle;
  final player = testCombatantSnapshot(
    realmTier: profile == 'bossMechanics'
        ? RealmTier.sanLiu
        : RealmTier.wuSheng,
    maxHp: profile == 'defeat' ? 1 : 20000,
    internalForce: 15000,
    totalEquipmentAttack: profile == 'bossMechanics' ? 130 : 2000,
    defenseRate: profile == 'defeat' ? 0 : 0.9,
    includeProductionBasicAttack: true,
  );
  Future<Phase0aTowerCombatSession> build(bool typed) =>
      createFreshPhase0aTowerCombatSession(
        Phase0aTowerCombatSessionBuildRequest(
          contentRef: CombatContentRef.tower('tower_$floorIndex'),
          floor: floor,
          playerSnapshot: player,
          numbers: repo.numbers,
          cycleIndex: cycle,
          rng: Random(seed),
          routeAuthority: Phase0aTowerEncounterRouteAuthority.migratedFloors(
            typed ? {floorIndex} : {},
          ),
        ),
      );
  final typed = await build(true);
  final legacy = await build(false);
  expect(typed.routeMode, Phase0aTowerEncounterRouteMode.migrated);
  expect(legacy.routeMode, Phase0aTowerEncounterRouteMode.legacy);
  final flow = typed.flow as Phase0aEncounterFlow;
  final bot = Phase0aPlayerBotAdapter(playerAdapter: typed.playerAdapter);
  final typedEvents = <Phase0aEvent>[];
  final legacyEvents = <Phase0aEvent>[];
  final transitions = <Map<String, Object?>>[];
  final maxima = <String, int>{
    'pending': 0,
    'warning': 0,
    'active': 0,
    'grace': 0,
    'leaseActive': 0,
    'leaseMutations': 0,
  };
  var receiptFrames = 0;
  var partialFrames = 0;
  var zeroEnemyInitialEquality = false;
  String? previousProgress;

  void observe() {
    final progress = flow.objectiveProgress!;
    final spawn = flow.spawnState;
    final receipt = flow.lastAttackTokenLeaseBatchReceipt;
    maxima['pending'] = max(maxima['pending']!, spawn.pendingCount);
    maxima['warning'] = max(maxima['warning']!, spawn.warningCount);
    maxima['active'] = max(maxima['active']!, spawn.activeCount);
    for (final unit in spawn.units) {
      maxima['grace'] = max(maxima['grace']!, unit.remainingGraceTicks);
    }
    if (receipt != null) {
      receiptFrames++;
      maxima['leaseActive'] = max(
        maxima['leaseActive']!,
        receipt.after.activeLeases.length,
      );
      maxima['leaseMutations'] = max(
        maxima['leaseMutations']!,
        receipt.mutations.length,
      );
    }
    expect(progress.clauses, hasLength(1));
    expect(progress.clauses.single.id, 'tower_${floorIndex}_defeat_all');
    expect(flow.checkpointObjectiveObservation, isNull);
    expect(flow.surviveObjectiveObservation, isNull);
    expect(flow.defendObjectiveObservation, isNull);
    expect(flow.pursueObjectiveObservation, isNull);
    final started = legacyEvents.whereType<Phase0aWaveStarted>().length;
    final cleared = legacyEvents.whereType<Phase0aWaveCleared>().length;
    if (flow.state.tick == 0) {
      zeroEnemyInitialEquality = started == cleared && !progress.completed;
    } else {
      expect(
        progress.completed,
        started > 0 && started == cleared,
        reason: 'objective/wave equivalence at tick ${flow.state.tick}',
      );
    }
    final removedIds = spawn.units
        .where((u) => u.removedTick != null)
        .map((u) => u.entryId)
        .toSet();
    if (flow.state.player.isAlive) {
      expect(progress.clauses.single.progress.satisfied, removedIds);
    }
    final satisfied = progress.clauses.single.progress.satisfied.toList()
      ..sort();
    if (satisfied.isNotEmpty && satisfied.length < floor.enemyTeam.length) {
      partialFrames++;
      expect(progress.completed, isFalse);
      expect(cleared, 0);
    }
    final value = <String, Object?>{
      'tick': flow.state.tick,
      'completed': progress.completed,
      'clauses': [
        for (final c in progress.clauses)
          {
            'id': c.id,
            'completed': c.completed,
            'satisfied': c.progress.satisfied.toList()..sort(),
            'processedEventIds': c.progress.processedEventIds.toList()..sort(),
            'elapsedUs': c.progress.elapsed.inMicroseconds,
          },
      ],
      'spawn': {
        'pending': spawn.pendingCount,
        'warning': spawn.warningCount,
        'active': spawn.activeCount,
        'removed': spawn.removedCount,
      },
      'legacyWaveStarted': started,
      'legacyWaveCleared': cleared,
      'outcome': flow.outcome.name,
    };
    final signature = jsonEncode([
      progress.completed,
      satisfied,
      spawn.pendingCount,
      spawn.warningCount,
      spawn.activeCount,
      started,
      cleared,
      flow.outcome.name,
    ]);
    if (signature != previousProgress) {
      transitions.add(value);
      previousProgress = signature;
    }
  }

  expect(
    _combatants(typed, canonical: true),
    _combatants(legacy, canonical: true),
  );
  expect(
    _canonicalState(flow.state, typed),
    _canonicalState(legacy.flow.state, legacy),
  );
  observe();
  while (flow.outcome == Phase0aBattleOutcome.ongoing &&
      flow.state.tick < repo.numbers.phase0aArena.maxSimulationTicks) {
    final state = flow.state;
    Phase0aPlayerCommand command;
    if (profile == 'defeat' || (profile == 'pressure' && state.tick < 600)) {
      command = const Phase0aPlayerCommand();
    } else if (profile == 'singleTarget' || profile == 'bossMechanics') {
      final enemies = state.enemies.where((e) => e.isAlive).toList();
      if (enemies.isEmpty) {
        command = const Phase0aPlayerCommand();
      } else {
        final target = enemies.first;
        final offset = target.position - state.player.position;
        final aim = offset.length > 0
            ? offset.normalized()
            : state.player.facing;
        command = Phase0aPlayerCommand(
          moveDirection: offset.length > typed.playerAdapter.attackRange
              ? aim
              : null,
          attack: profile != 'bossMechanics' || target.chargingCast == null,
          attackAimDirection: aim,
          attackTargetId: target.id,
        );
      }
    } else {
      command = bot.commandFor(state);
    }
    final actual = flow.advance(
      deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
      command: command,
    );
    final expected = legacy.flow.advance(
      deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
      command: command,
    );
    typedEvents.addAll(actual);
    legacyEvents.addAll(expected);
    expect(
      _canonicalState(flow.state, typed),
      _canonicalState(legacy.flow.state, legacy),
      reason: 'all actor/state fields tick ${flow.state.tick}',
    );
    expect(
      _combatEvents(actual),
      _combatEvents(expected),
      reason: 'all combat payloads tick ${flow.state.tick}',
    );
    expect(flow.outcome, legacy.flow.outcome);
    observe();
  }
  expect(flow.outcome, isNot(Phase0aBattleOutcome.ongoing));
  if (floorIndex <= 14) {
    expect(
      flow.outcome,
      profile == 'defeat'
          ? Phase0aBattleOutcome.defeat
          : Phase0aBattleOutcome.victory,
    );
  }
  expect(
    _settlement(
      typed.settle(
        outcome: flow.outcome,
        finalState: flow.state,
        events: typedEvents,
      ),
    ),
    _settlement(
      legacy.settle(
        outcome: legacy.flow.outcome,
        finalState: legacy.flow.state,
        events: legacyEvents,
      ),
    ),
  );
  final starts = legacyEvents.whereType<Phase0aWaveStarted>().toList();
  final clears = legacyEvents.whereType<Phase0aWaveCleared>().toList();
  expect(starts, hasLength(1));
  expect(starts.single.tick, 1);
  expect(starts.single.waveIndex, 1);
  expect(starts.single.waveTotal, 1);
  expect(
    typedEvents.where(
      (e) => e is Phase0aWaveStarted || e is Phase0aWaveCleared,
    ),
    isEmpty,
  );
  if (flow.outcome == Phase0aBattleOutcome.victory) {
    expect(clears, hasLength(1));
    expect(clears.single.waveIndex, 1);
    expect(clears.single.tick, flow.state.tick);
    final lastDeath = legacyEvents.whereType<Phase0aEnemyDefeated>().last;
    final victory = legacyEvents.whereType<Phase0aBattleVictory>().single;
    expect(lastDeath.tick, victory.tick);
    expect(lastDeath.seq, lessThan(clears.single.seq));
    expect(clears.single.seq, lessThan(victory.seq));
  } else {
    expect(clears, isEmpty);
  }
  if (profile == 'singleTarget' && floor.enemyTeam.length > 1) {
    expect(partialFrames, greaterThan(0));
  }
  if (profile == 'bossMechanics' && floorIndex == 14) {
    expect(
      typedEvents.whereType<Phase0aBossPhaseChanged>().map((e) => e.phaseIndex),
      [1, 2],
    );
    expect(
      typedEvents.whereType<Phase0aBossChargeStarted>().map((e) => e.skillId),
      containsAll([
        'skill_gangmeng_changlian_fang_skill',
        'skill_gangmeng_changlian_fang_ult',
      ]),
    );
  }
  if (profile == 'pressure' && floorIndex == 11 && cycle == 2) {
    expect(typedEvents.whereType<Phase0aBossChargeStarted>(), isNotEmpty);
  }
  final afterTerminal = flow.objectiveProgress;
  expect(
    flow.advance(
      deltaSeconds: repo.numbers.phase0aArena.fixedDeltaSeconds,
      command: const Phase0aPlayerCommand(),
    ),
    isEmpty,
  );
  expect(identical(flow.objectiveProgress, afterTerminal), isTrue);
  final eventCounts = <String, int>{};
  final attackActorsByTick = <int, Set<String>>{};
  for (final event in typedEvents) {
    eventCounts.update(
      event.runtimeType.toString(),
      (n) => n + 1,
      ifAbsent: () => 1,
    );
    final actor = switch (event) {
      Phase0aAttackStarted() => event.actor,
      Phase0aEnemySkillStarted() => event.actor,
      Phase0aBossChargeStarted() => event.actor,
      _ => null,
    };
    if (actor != null && typed.sourceEnemyDefIdByActorId.containsKey(actor)) {
      attackActorsByTick.putIfAbsent(event.tick, () => {}).add(actor);
    }
  }
  final simultaneous = attackActorsByTick.entries.where(
    (e) => e.value.length > 1,
  );
  if (profile == 'pressure' && floor.enemyTeam.length > 1) {
    expect(
      simultaneous,
      isNotEmpty,
      reason: 'multi-enemy attacks must really participate',
    );
  }
  _emit({
    'kind': 'probe',
    'profile': profile,
    'floor': floorIndex,
    'cycle': cycle,
    'seed': seed,
    'enemies': floor.enemyTeam.length,
    'bossKind': floor.bossKind?.name,
    'routes': [typed.routeMode.name, legacy.routeMode.name],
    'ticks': flow.state.tick,
    'outcome': flow.outcome.name,
    'statesAndCombatAndSettlementEqual': true,
    'tickZeroZeroEqualsZeroButObjectiveFalse': zeroEnemyInitialEquality,
    'legacyWaves': [
      for (final e in legacyEvents)
        if (e is Phase0aWaveStarted)
          {
            'event': 'started',
            'tick': e.tick,
            'waveIndex': e.waveIndex,
            'waveTotal': e.waveTotal,
          }
        else if (e is Phase0aWaveCleared)
          {'event': 'cleared', 'tick': e.tick, 'waveIndex': e.waveIndex},
    ],
    'maxima': {
      ...maxima,
      if (receiptFrames == 0) 'leaseActive': null,
      if (receiptFrames == 0) 'leaseMutations': null,
    },
    'leaseReceiptFrames': receiptFrames,
    'partialFrames': partialFrames,
    'maxSimultaneousEnemyAttackActors': attackActorsByTick.values.fold<int>(
      0,
      (n, actors) => max(n, actors.length),
    ),
    'firstSimultaneousEnemyAttack': simultaneous.isEmpty
        ? null
        : {
            'tick': simultaneous.first.key,
            'actors': simultaneous.first.value.toList(),
          },
    'eventCounts': eventCounts,
    'bossSnapshots': [
      for (final c in typed.combatants.where((c) => c.snapshot.isBoss))
        {
          'actor': c.actorId,
          'chargeSkillId': c.snapshot.chargeSkillId,
          'guardianDefIds': c.snapshot.guardianDefIds,
          'guardianWardMult': c.snapshot.guardianWardMult,
          'guardInterceptsInterrupt': c.snapshot.guardInterceptsInterrupt,
          'phaseThresholds': c.snapshot.bossPhases
              ?.map((p) => p.hpThresholdPct)
              .toList(),
          'schoolDamageTakenMult': c.snapshot.schoolDamageTakenMult.map(
            (k, v) => MapEntry(k.name, v),
          ),
        },
    ],
    'bossSkillStarts': [
      for (final e in typedEvents.whereType<Phase0aEnemySkillStarted>())
        if (typed.combatants.any(
          (c) => c.actorId == e.actor && c.snapshot.isBoss,
        ))
          {'tick': e.tick, 'actor': e.actor, 'skillId': e.skillId},
    ],
    'bossHits': [
      for (final e in typedEvents.whereType<Phase0aHitLanded>())
        if (typed.combatants.any(
          (c) => c.actorId == e.actor && c.snapshot.isBoss,
        ))
          {
            'tick': e.tick,
            'actor': e.actor,
            'moveKind': e.moveKind.name,
            'damage': e.resolvedDamage,
          },
    ],
    'bossEvents': [
      for (final e in typedEvents)
        if (e is Phase0aBossPhaseChanged)
          {
            'kind': 'phase',
            'tick': e.tick,
            'actor': e.actor,
            'phaseIndex': e.phaseIndex,
            'unlocked': e.unlockedSkillIds,
          }
        else if (e is Phase0aBossChargeStarted)
          {
            'kind': 'charge',
            'tick': e.tick,
            'actor': e.actor,
            'skillId': e.skillId,
            'chargeTicks': e.chargeTicks,
          },
    ],
    'enemyDefeated': [
      for (final e in typedEvents.whereType<Phase0aEnemyDefeated>())
        {'tick': e.tick, 'target': e.target},
    ],
    'transitions': transitions,
  });
}

List<Object?> _combatants(
  Phase0aTowerCombatSession session, {
  bool canonical = false,
}) => [
  for (final binding in session.combatants)
    [
      binding.actorId,
      _snapshot(
        canonical
            ? binding.snapshot.copyWith(
                guardianDefIds: _guardianIds(
                  binding.snapshot.guardianDefIds,
                  session,
                ),
              )
            : binding.snapshot,
      ),
    ],
];

// SkillDef is immutable and deliberately compared by exact object identity:
// matching ids alone could hide loss of power, timing, Qi or behavior fields.
List<Object?> _snapshot(CombatantSnapshot s) => [
  s.characterId,
  s.name,
  s.realmTier,
  s.realmLayer,
  s.school,
  s.maxHp,
  s.currentHp,
  s.internalForce,
  s.maxQi,
  s.currentQi,
  s.qiGainMultiplier,
  s.qiCostReductionPct,
  s.autoUltimate,
  s.speed,
  s.criticalRate,
  s.evasionRate,
  s.defenseRate,
  s.totalEquipmentAttack,
  s.mainCultivationLayer,
  s.weaponArchetype,
  s.skillLoadout.basicAttack,
  [for (final slot in CombatantSkillSlot.values) s.skillLoadout.skillFor(slot)],
  s.availableSkills,
  s.openingSkillCooldowns,
  s.skillUses,
  s.activeBuffs,
  s.swordSongResonanceActive,
  s.iconPath,
  s.attackPowerMultiplier,
  s.outputMultiplier,
  s.isBoss,
  s.chargeSkillId,
  s.bossPhases
      ?.map(
        (p) => [
          p.hpThresholdPct,
          p.unlockSkillIds,
          p.aiMode,
          p.onEnterMechanic,
          p.titleKey,
        ],
      )
      .toList(),
  s.bossPhaseUnlockSkills,
  s.schoolDamageTakenMult,
  s.lineageRole,
  s.forgingPiercePct,
  s.forgingLifestealPct,
  s.enemyDefId,
  s.guardianWardMult,
  s.guardianDefIds,
  s.vulnerabilityMult,
  s.guardInterceptsInterrupt,
];

List<Object?> _settlement(CombatSettlementSnapshot s) => [
  s.result,
  s.totalTicks,
  s.hadActions,
  s.playerCharacterId,
  [
    for (final p in s.participants) [p.characterId, p.currentHp, p.maxHp],
  ],
  [
    for (final c in s.skillCasts) [c.tick, c.characterId, c.skillId],
  ],
  s.totalDamage,
  s.criticalCount,
  s.damageByCharacterId,
];

// Legacy emits wave lifecycle records and carries source guardian ids; typed
// emits encounter objectives and carries exact runtime guardian ids. Normalize
// only these representational differences, retaining tick, actors and payloads.
List<Phase0aEvent> _combatEvents(List<Phase0aEvent> events) => [
  for (final e in events)
    if (e is! Phase0aWaveStarted && e is! Phase0aWaveCleared)
      _withoutSequence(e),
];

Phase0aEvent _withoutSequence(Phase0aEvent e) => switch (e) {
  Phase0aActionTimelineChanged() => Phase0aActionTimelineChanged(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    actionId: e.actionId,
    eventType: e.eventType,
    phase: e.phase,
    actionTick: e.actionTick,
  ),
  Phase0aQiChanged() => Phase0aQiChanged(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    actionId: e.actionId,
    reason: e.reason,
    applied: e.applied,
    overflow: e.overflow,
    current: e.current,
    windowId: e.windowId,
  ),
  Phase0aAttackStarted() => Phase0aAttackStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    moveKind: e.moveKind,
    basicAttackSegment: e.basicAttackSegment,
    weaponArchetype: e.weaponArchetype,
    visualSchool: e.visualSchool,
  ),
  Phase0aHitLanded() => Phase0aHitLanded(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    target: e.target,
    moveKind: e.moveKind,
    isCritical: e.isCritical,
    isUltimate: e.isUltimate,
    resolvedDamage: e.resolvedDamage,
    remainingHealth: e.remainingHealth,
    actorPosition: e.actorPosition,
    targetPosition: e.targetPosition,
    basicAttackSegment: e.basicAttackSegment,
    weaponArchetype: e.weaponArchetype,
    visualSchool: e.visualSchool,
  ),
  Phase0aDefendedEntityHit() => Phase0aDefendedEntityHit(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    target: e.target,
    resolvedDamage: e.resolvedDamage,
    remainingDurability: e.remainingDurability,
    actorPosition: e.actorPosition,
    targetPosition: e.targetPosition,
  ),
  Phase0aDefendedEntityDestroyed() => Phase0aDefendedEntityDestroyed(
    seq: 0,
    tick: e.tick,
    target: e.target,
    targetPosition: e.targetPosition,
  ),
  Phase0aStatusDamageApplied() => Phase0aStatusDamageApplied(
    seq: 0,
    tick: e.tick,
    source: e.source,
    target: e.target,
    statusType: e.statusType,
    resolvedDamage: e.resolvedDamage,
    remainingHealth: e.remainingHealth,
    targetPosition: e.targetPosition,
  ),
  Phase0aEnemyDefeated() => Phase0aEnemyDefeated(
    seq: 0,
    tick: e.tick,
    target: e.target,
    defeatKind: e.defeatKind,
    targetPosition: e.targetPosition,
  ),
  Phase0aBossPhaseChanged() => Phase0aBossPhaseChanged(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    phaseIndex: e.phaseIndex,
    unlockedSkillIds: e.unlockedSkillIds,
  ),
  Phase0aBossChargeStarted() => Phase0aBossChargeStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    skillId: e.skillId,
    chargeTicks: e.chargeTicks,
  ),
  Phase0aGuardianCoopStrike() => Phase0aGuardianCoopStrike(
    seq: 0,
    tick: e.tick,
    mainGuardian: e.mainGuardian,
    partner: e.partner,
    boss: e.boss,
    target: e.target,
    mainGuardianDamage: e.mainGuardianDamage,
    mainGuardianCritical: e.mainGuardianCritical,
    totalDamage: e.totalDamage,
    mainGuardianPosition: e.mainGuardianPosition,
    partnerPosition: e.partnerPosition,
    bossPosition: e.bossPosition,
    targetPosition: e.targetPosition,
  ),
  Phase0aGuardIntercepted() => Phase0aGuardIntercepted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    boss: e.boss,
    guardian: e.guardian,
    skillId: e.skillId,
    resolvedDamage: e.resolvedDamage,
    bossPosition: e.bossPosition,
    guardianPosition: e.guardianPosition,
  ),
  Phase0aPostureChanged() => Phase0aPostureChanged(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    target: e.target,
    eventType: e.eventType,
    amount: e.amount,
    accumulated: e.accumulated,
    capacity: e.capacity,
    vulnerabilityTicksRemaining: e.vulnerabilityTicksRemaining,
    hitKind: e.hitKind,
    targetPosition: e.targetPosition,
  ),
  Phase0aEnemySkillStarted() => Phase0aEnemySkillStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    skillId: e.skillId,
  ),
  Phase0aGatherStarted() => Phase0aGatherStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    skillId: e.skillId,
    actorPosition: e.actorPosition,
    centerPosition: e.centerPosition,
  ),
  Phase0aGatherApplied() => Phase0aGatherApplied(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    outcomes: e.outcomes,
  ),
  Phase0aClearStarted() => Phase0aClearStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    skillId: e.skillId,
    actorPosition: e.actorPosition,
  ),
  Phase0aClearApplied() => Phase0aClearApplied(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    outcomes: e.outcomes,
  ),
  Phase0aSkillStarted() => Phase0aSkillStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    hotkey: e.hotkey,
    skillId: e.skillId,
  ),
  Phase0aSkillApplied() => Phase0aSkillApplied(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    hotkey: e.hotkey,
    skillId: e.skillId,
    outcomes: e.outcomes,
  ),
  Phase0aSkillAvailabilityChanged() => Phase0aSkillAvailabilityChanged(
    seq: 0,
    tick: e.tick,
    slot: e.slot,
    availability: e.availability,
    cooldownRemaining: e.cooldownRemaining,
    qiCurrent: e.qiCurrent,
    qiRequired: e.qiRequired,
  ),
  Phase0aWaveStarted() => Phase0aWaveStarted(
    seq: 0,
    tick: e.tick,
    waveIndex: e.waveIndex,
    waveTotal: e.waveTotal,
  ),
  Phase0aWaveCleared() => Phase0aWaveCleared(
    seq: 0,
    tick: e.tick,
    waveIndex: e.waveIndex,
  ),
  Phase0aSpawnWarningStarted() => Phase0aSpawnWarningStarted(
    seq: 0,
    tick: e.tick,
    entryId: e.entryId,
    enemyId: e.enemyId,
    entryPosition: e.entryPosition,
  ),
  Phase0aEnemyEntered() => Phase0aEnemyEntered(
    seq: 0,
    tick: e.tick,
    entryId: e.entryId,
    enemyId: e.enemyId,
    entryPosition: e.entryPosition,
  ),
  Phase0aSpawnGraceExpired() => Phase0aSpawnGraceExpired(
    seq: 0,
    tick: e.tick,
    entryId: e.entryId,
    enemyId: e.enemyId,
    entryPosition: e.entryPosition,
  ),
  Phase0aBattleVictory() => Phase0aBattleVictory(seq: 0, tick: e.tick),
  Phase0aBattleDefeat() => Phase0aBattleDefeat(seq: 0, tick: e.tick),
  Phase0aDefenseStarted() => Phase0aDefenseStarted(
    seq: 0,
    tick: e.tick,
    actor: e.actor,
    action: e.action,
    fromPosition: e.fromPosition,
    toPosition: e.toPosition,
    windowTicks: e.windowTicks,
    shieldAbsorption: e.shieldAbsorption,
  ),
  Phase0aDefenseResolved() => Phase0aDefenseResolved(
    seq: 0,
    tick: e.tick,
    attackId: e.attackId,
    attacker: e.attacker,
    target: e.target,
    branch: e.branch,
    incomingDamage: e.incomingDamage,
    counterDamage: e.counterDamage,
    shieldRemaining: e.shieldRemaining,
    nonRecursive: e.nonRecursive,
    targetPosition: e.targetPosition,
  ),
};

List<String> _guardianIds(
  List<String> ids,
  Phase0aTowerCombatSession session,
) => [
  for (final id in ids)
    session.sourceEnemyDefIdByActorId.containsKey(id)
        ? id
        : session.sourceEnemyDefIdByActorId.entries
              .singleWhere((e) => e.value == id)
              .key,
];
Phase0aArenaState _canonicalState(
  Phase0aArenaState s,
  Phase0aTowerCombatSession session,
) => Phase0aArenaState(
  tick: s.tick,
  nextSeq: 0,
  player: s.player,
  enemies: [for (final a in s.enemies) _canonicalActor(a, session)],
  skillSlots: s.skillSlots,
  defendedEntity: s.defendedEntity,
  winCondition: s.winCondition,
);
Phase0aActor _canonicalActor(
  Phase0aActor a,
  Phase0aTowerCombatSession session,
) => Phase0aActor(
  id: a.id,
  side: a.side,
  position: a.position,
  facing: a.facing,
  maxHealth: a.maxHealth,
  currentHealth: a.currentHealth,
  moveSpeed: a.moveSpeed,
  qiCurrent: a.qiCurrent,
  qiMax: a.qiMax,
  attackCooldownRemaining: a.attackCooldownRemaining,
  defeatKind: a.defeatKind,
  isBoss: a.isBoss,
  autoUltimate: a.autoUltimate,
  bossPhases: a.bossPhases,
  bossPhaseIndex: a.bossPhaseIndex,
  unlockedEnemySkillIds: a.unlockedEnemySkillIds,
  enemySkillCooldowns: a.enemySkillCooldowns,
  chargeCast: a.chargeCast,
  phaseChargeCasts: a.phaseChargeCasts,
  staggerTicksTotal: a.staggerTicksTotal,
  guardianDefIds: _guardianIds(a.guardianDefIds, session),
  guardianWardMult: a.guardianWardMult,
  guardInterceptsInterrupt: a.guardInterceptsInterrupt,
  guardianCoopUsedInCharge: a.guardianCoopUsedInCharge,
  vulnerabilityMult: a.vulnerabilityMult,
  chargingCast: a.chargingCast,
  chargingDefenseFlags: a.chargingDefenseFlags,
  chargeTicksRemaining: a.chargeTicksRemaining,
  staggerTicksRemaining: a.staggerTicksRemaining,
  gatherControlTicksRemaining: a.gatherControlTicksRemaining,
  posture: a.posture,
  shieldRemaining: a.shieldRemaining,
  shieldTicksRemaining: a.shieldTicksRemaining,
  parryTicksRemaining: a.parryTicksRemaining,
  dodgeTicksRemaining: a.dodgeTicksRemaining,
  defenseCooldownRemaining: a.defenseCooldownRemaining,
  parryCounterDamage: a.parryCounterDamage,
  parryCounterBudgetRemaining: a.parryCounterBudgetRemaining,
  statusLedger: a.statusLedger,
  basicAttackSegmentIndex: a.basicAttackSegmentIndex,
  basicAction: a.basicAction,
  qiLedger: a.qiLedger,
  killQiGain: a.killQiGain,
  killQiWindowCap: a.killQiWindowCap,
  qiWindowSerial: a.qiWindowSerial,
);
