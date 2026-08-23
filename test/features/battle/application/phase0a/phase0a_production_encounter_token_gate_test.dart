import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/attack_token_enforcing_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_mapping.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

final class _CapturingObserver implements Phase0aEnemyIntentObserver {
  final List<Phase0aEnemyIntentObservation> observations = [];

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    observations.add(observation);
  }
}

final class _DelegatingCountingGate implements Phase0aEnemyIntentBatchGate {
  _DelegatingCountingGate(this.delegate);

  final Phase0aEnemyIntentBatchGate delegate;
  int calls = 0;

  @override
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) {
    calls++;
    return delegate.gateEnemyIntents(enemyIntents: enemyIntents);
  }
}

final class _InjectingBatchGate implements Phase0aEnemyIntentBatchGate {
  @override
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) {
    return [
      ...enemyIntents,
      const Phase0aMoveIntent(
        actorId: 'injected',
        direction: ArenaVector(-1, 0),
      ),
    ];
  }
}

void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  const basicSkill = SkillDef(
    id: 'phase0a_production_token_gate_basic',
    name: 'basic',
    description: 'basic',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    qiDelta: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: '',
  );

  Map<Phase0aDamageKind, SkillDef?> fullBindings() => {
    Phase0aDamageKind.basic: basicSkill,
    Phase0aDamageKind.gather: null,
    Phase0aDamageKind.clear: null,
  };

  CombatantSnapshot snapshot({
    required int characterId,
    required TechniqueSchool school,
    required int internalForce,
    required int equipmentAttack,
  }) {
    return testCombatantSnapshot(
      characterId: characterId,
      name: 'c$characterId',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.ruMen,
      school: school,
      maxHp: 1000,
      internalForce: internalForce,
      maxQi: 100,
      speed: 100,
      criticalRate: 0,
      evasionRate: 0,
      defenseRate: 0,
      totalEquipmentAttack: equipmentAttack,
    );
  }

  Map<String, CombatantSnapshot> snapshots() => {
    'player': snapshot(
      characterId: 1,
      school: TechniqueSchool.gangMeng,
      internalForce: 600,
      equipmentAttack: 130,
    ),
    'e1': snapshot(
      characterId: 2,
      school: TechniqueSchool.yinRou,
      internalForce: 400,
      equipmentAttack: 90,
    ),
    'e2': snapshot(
      characterId: 3,
      school: TechniqueSchool.yinRou,
      internalForce: 450,
      equipmentAttack: 95,
    ),
    'e3': snapshot(
      characterId: 4,
      school: TechniqueSchool.yinRou,
      internalForce: 500,
      equipmentAttack: 100,
    ),
  };

  List<Phase0aCombatantInput> combatants() => [
    for (final entry in snapshots().entries)
      Phase0aCombatantInput(actorId: entry.key, snapshot: entry.value),
  ];

  Phase0aActor actor({
    required String id,
    required Phase0aSide side,
    required double x,
  }) {
    return Phase0aActor(
      id: id,
      side: side,
      position: ArenaVector(x, 0),
      facing: side == Phase0aSide.player
          ? const ArenaVector(1, 0)
          : const ArenaVector(-1, 0),
      maxHealth: 100000,
      currentHealth: 100000,
      moveSpeed: 100,
      qiCurrent: 100,
      qiMax: 100,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    );
  }

  Phase0aArenaState initialState() => Phase0aArenaState(
    tick: 0,
    nextSeq: 1,
    player: actor(id: 'player', side: Phase0aSide.player, x: 0),
    enemies: const [],
    skillSlots: const [],
  );

  SpawnDirector director() => SpawnDirector(
    config: SpawnDirectorConfig(
      activeLimit: 3,
      reinforcementThreshold: 0,
      entryWarningTicks: 0,
      attackGraceTicks: 0,
    ),
    entries: [
      SpawnEntry(entryId: 'entry_e1', enemyId: 'e1'),
      SpawnEntry(entryId: 'entry_e2', enemyId: 'e2'),
      SpawnEntry(entryId: 'entry_e3', enemyId: 'e3'),
    ],
  );

  Phase0aEncounterRoster roster(SpawnDirector value) => Phase0aEncounterRoster(
    director: value,
    playerId: 'player',
    bindings: [
      Phase0aEncounterRosterBinding(
        entryId: 'entry_e1',
        actor: actor(id: 'e1', side: Phase0aSide.enemy, x: 50),
      ),
      Phase0aEncounterRosterBinding(
        entryId: 'entry_e2',
        actor: actor(id: 'e2', side: Phase0aSide.enemy, x: 60),
      ),
      Phase0aEncounterRosterBinding(
        entryId: 'entry_e3',
        actor: actor(id: 'e3', side: Phase0aSide.enemy, x: 65),
      ),
    ],
  );

  const playerAdapter = Phase0aPlayerInputAdapter(
    playerId: 'player',
    attackRange: 120,
    attackHalfArcRadians: math.pi / 4,
    attackCooldownSeconds: 0.5,
    attackQiDelta: 0,
    gatherSlot: 'gather',
    gatherRingRadius: 90,
    gatherEffectRadius: 500,
    gatherQiCost: 20,
    gatherCooldownSeconds: 3,
    clearSlot: 'clear',
    clearEffectRadius: 500,
    clearQiCost: 30,
    clearCooldownSeconds: 4,
  );

  const enemyAdapter = Phase0aEnemyAiAdapter(
    attackRange: 70,
    attackHalfArcRadians: math.pi / 3,
    attackCooldownSeconds: 0.5,
  );

  AttackTokenEnforcingBatchGate tokenGate({required int meleeBudget}) {
    return AttackTokenEnforcingBatchGate(
      director: const AttackTokenDirector(),
      budgets: AttackTokenBudgets(
        melee: meleeBudget,
        ranged: 0,
        charge: 0,
        support: 0,
      ),
      requestMapper: (intent) {
        if (intent is! Phase0aAttackIntent) return null;
        final priority = switch (intent.actorId) {
          'e3' => 30,
          'e1' => 20,
          'e2' => 10,
          _ => 0,
        };
        return AttackTokenRequest(
          actorId: intent.actorId,
          kind: AttackTokenKind.melee,
          priority: priority,
          isOffscreen: false,
          isHighImpact: false,
          isUnblockableArea: false,
          spawnGraceTicksRemaining: 0,
          telegraphReady: true,
        );
      },
    );
  }

  Phase0aEncounterFlow assembleWithoutGate({
    required math.Random rng,
    Phase0aEnemyIntentObserver? observer,
  }) {
    final value = director();
    return Phase0aProductionFlowAssembler.assembleEncounter(
      initialState: initialState(),
      director: value,
      roster: roster(value),
      combatants: combatants(),
      moveBindings: fullBindings(),
      numbers: GameRepository.instance.numbers,
      rng: rng,
      playerAdapter: playerAdapter,
      enemyAiAdapter: enemyAdapter,
      enemyIntentObserver: observer,
    );
  }

  Phase0aEncounterFlow assembleWithGate({
    required math.Random rng,
    required Phase0aEnemyIntentBatchGate? gate,
    Phase0aEnemyIntentObserver? observer,
  }) {
    final value = director();
    return Phase0aProductionFlowAssembler.assembleEncounter(
      initialState: initialState(),
      director: value,
      roster: roster(value),
      combatants: combatants(),
      moveBindings: fullBindings(),
      numbers: GameRepository.instance.numbers,
      rng: rng,
      playerAdapter: playerAdapter,
      enemyAiAdapter: enemyAdapter,
      enemyIntentObserver: observer,
      enemyIntentBatchGate: gate,
    );
  }

  Phase0aEncounterMapping mapping() {
    final value = director();
    return Phase0aEncounterMapping(
      initialState: initialState(),
      director: value,
      roster: roster(value),
      combatants: combatants(),
      moveBindings: fullBindings(),
      playerAdapter: playerAdapter,
      enemyAiAdapter: enemyAdapter,
    );
  }

  List<Phase0aEvent> advanceTicks(Phase0aEncounterFlow flow, int ticks) {
    final events = <Phase0aEvent>[];
    for (var tick = 0; tick < ticks; tick++) {
      events.addAll(
        flow.advance(deltaSeconds: 0.5, command: const Phase0aPlayerCommand()),
      );
    }
    return events;
  }

  group('production encounter token gate', () {
    test(
      'real gate keeps budget-approved stable subsequence and damage agrees',
      () {
        final observer = _CapturingObserver();
        final flow = assembleWithGate(
          rng: math.Random(101),
          gate: tokenGate(meleeBudget: 2),
          observer: observer,
        );
        final initialHealth = flow.state.player.currentHealth;

        final events = advanceTicks(flow, 1);

        expect(observer.observations, hasLength(1));
        final observed = observer.observations.single.enemyIntents;
        expect(observed, everyElement(isA<Phase0aAttackIntent>()));
        expect(observed.map((intent) => intent.actorId), ['e1', 'e3']);
        final enemyHits = events
            .whereType<Phase0aHitLanded>()
            .where((event) => event.target == 'player')
            .toList();
        expect(enemyHits.map((event) => event.actor), ['e1', 'e3']);
        expect(
          initialHealth - flow.state.player.currentHealth,
          enemyHits.fold<int>(0, (sum, event) => sum + event.resolvedDamage),
        );
      },
    );

    test('omitted and explicit null gate paths are replay equivalent', () {
      const seed = 103;
      final omittedRng = math.Random(seed);
      final nullRng = math.Random(seed);
      final omitted = assembleWithoutGate(rng: omittedRng);
      final explicitNull = assembleWithGate(rng: nullRng, gate: null);

      final omittedEvents = advanceTicks(omitted, 3);
      final nullEvents = advanceTicks(explicitNull, 3);

      expect(nullEvents, omittedEvents);
      expect(explicitNull.state, omitted.state);
      expect(explicitNull.outcome, omitted.outcome);
      expect(
        explicitNull.lastOrderedEventRecords,
        omitted.lastOrderedEventRecords,
      );
      expect(nullRng.nextDouble(), omittedRng.nextDouble());
    });

    test('grant-all gate adds no RNG consumption to the null path', () {
      const seed = 107;
      final baselineRng = math.Random(seed);
      final gatedRng = math.Random(seed);
      final baseline = assembleWithoutGate(rng: baselineRng);
      final gated = assembleWithGate(
        rng: gatedRng,
        gate: tokenGate(meleeBudget: 3),
      );

      final baselineEvents = advanceTicks(baseline, 3);
      final gatedEvents = advanceTicks(gated, 3);

      expect(gatedEvents, baselineEvents);
      expect(gated.state, baseline.state);
      expect(gated.outcome, baseline.outcome);
      expect(gated.lastOrderedEventRecords, baseline.lastOrderedEventRecords);
      expect(gatedRng.nextDouble(), baselineRng.nextDouble());
    });

    test('mapping bridge invokes the exact caller gate instance', () {
      final exactGate = _DelegatingCountingGate(tokenGate(meleeBudget: 1));
      final observer = _CapturingObserver();
      final flow = Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
        mapping: mapping(),
        numbers: GameRepository.instance.numbers,
        rng: math.Random(109),
        enemyIntentObserver: observer,
        enemyIntentBatchGate: exactGate,
      );

      final events = advanceTicks(flow, 1);

      expect(exactGate.calls, 1);
      expect(observer.observations.single.enemyIntents, hasLength(1));
      expect(observer.observations.single.enemyIntents.single.actorId, 'e3');
      final enemyHits = events
          .whereType<Phase0aHitLanded>()
          .where((event) => event.target == 'player')
          .toList();
      expect(enemyHits.single.actor, 'e3');
    });

    test('invalid output fails before observer/reducer and restores flow', () {
      final observer = _CapturingObserver();
      final flow = assembleWithGate(
        rng: math.Random(113),
        gate: _InjectingBatchGate(),
        observer: observer,
      );
      final beforeState = flow.state;
      final beforeSpawnState = flow.spawnState;
      final beforeOutcome = flow.outcome;
      final beforeRecords = flow.lastOrderedEventRecords;

      expect(() => advanceTicks(flow, 1), throwsStateError);

      expect(observer.observations, isEmpty);
      expect(flow.state, same(beforeState));
      expect(flow.spawnState.tick, beforeSpawnState.tick);
      expect(flow.spawnState.totalCount, beforeSpawnState.totalCount);
      expect(flow.spawnState.activeCount, beforeSpawnState.activeCount);
      expect(flow.spawnState.warningCount, beforeSpawnState.warningCount);
      expect(flow.spawnState.pendingCount, beforeSpawnState.pendingCount);
      expect(flow.spawnState.removedCount, beforeSpawnState.removedCount);
      expect(flow.spawnState.units, beforeSpawnState.units);
      expect(flow.outcome, beforeOutcome);
      expect(flow.lastOrderedEventRecords, same(beforeRecords));
      expect(flow.state.tick, 0);
      expect(flow.spawnState.tick, 0);
    });
  });
}
