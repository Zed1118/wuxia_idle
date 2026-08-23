import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_mapping.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_objective_runtime_tracker.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_objective.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/objective_controller.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

final class _CountingPassThroughGate implements Phase0aEnemyIntentBatchGate {
  int calls = 0;

  @override
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) {
    calls += 1;
    return List<Phase0aIntent>.unmodifiable(enemyIntents);
  }
}

final class _DefeatObjectiveSource
    implements Phase0aEncounterObjectiveEventSource {
  int calls = 0;
  final List<Phase0aEncounterObjectiveFrame> frames = [];

  @override
  Iterable<EncounterObjectiveEvent> eventsFor(
    Phase0aEncounterObjectiveFrame frame,
  ) {
    calls += 1;
    frames.add(frame);
    return [
      for (final event in frame.combatEvents)
        if (event is Phase0aEnemyDefeated && event.target == 'enemy')
          TargetDefeated(
            'objective_enemy',
            eventId: 'defeat:${event.tick}:${event.seq}',
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
    id: 'batch13_objective_integration_basic',
    name: 'basic',
    description: 'basic',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    qiDelta: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: '',
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

  Phase0aActor actor({
    required String id,
    required Phase0aSide side,
    required int health,
    required double x,
  }) => Phase0aActor(
    id: id,
    side: side,
    position: ArenaVector(x, 0),
    facing: side == Phase0aSide.player
        ? const ArenaVector(1, 0)
        : const ArenaVector(-1, 0),
    maxHealth: side == Phase0aSide.player ? 100000 : 100,
    currentHealth: health,
    moveSpeed: 100,
    qiCurrent: 100,
    qiMax: 100,
    attackCooldownRemaining: 0,
    defeatKind: Phase0aDefeatKind.normal,
  );

  CombatantSnapshot snapshot({
    required int characterId,
    required TechniqueSchool school,
  }) => testCombatantSnapshot(
    characterId: characterId,
    name: 'c$characterId',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.ruMen,
    school: school,
    maxHp: 1000,
    internalForce: characterId == 1 ? 600 : 300,
    maxQi: 100,
    speed: 100,
    criticalRate: 0,
    evasionRate: 0,
    defenseRate: 0,
    totalEquipmentAttack: characterId == 1 ? 130 : 60,
  );

  Phase0aObjectiveRuntimeTracker tracker() => Phase0aObjectiveRuntimeTracker(
    controller: ObjectiveController(
      completionRule: ObjectiveCompletionRule.all,
      clauses: [
        ObjectiveClause(
          id: 'defeat',
          objective: DefeatTargetsObjective(const ['objective_enemy']),
        ),
      ],
    ),
  );

  Phase0aEncounterFlow assemble({
    required bool fromMapping,
    required Phase0aEnemyIntentBatchGate? enemyIntentBatchGate,
    required Phase0aObjectiveRuntimeTracker? objectiveTracker,
    required Phase0aEncounterObjectiveEventSource? objectiveEventSource,
  }) {
    final director = SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: 1,
        reinforcementThreshold: 0,
        entryWarningTicks: 0,
        attackGraceTicks: 0,
      ),
      entries: [SpawnEntry(entryId: 'entry_enemy', enemyId: 'enemy')],
    );
    final roster = Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        Phase0aEncounterRosterBinding(
          entryId: 'entry_enemy',
          actor: actor(id: 'enemy', side: Phase0aSide.enemy, health: 1, x: 50),
        ),
      ],
    );
    final initialState = Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: actor(
        id: 'player',
        side: Phase0aSide.player,
        health: 100000,
        x: 0,
      ),
      enemies: const [],
      skillSlots: const [],
    );
    final combatants = <Phase0aCombatantInput>[
      Phase0aCombatantInput(
        actorId: 'player',
        snapshot: snapshot(characterId: 1, school: TechniqueSchool.gangMeng),
      ),
      Phase0aCombatantInput(
        actorId: 'enemy',
        snapshot: snapshot(characterId: 2, school: TechniqueSchool.yinRou),
      ),
    ];
    final moveBindings = <Phase0aDamageKind, SkillDef?>{
      Phase0aDamageKind.basic: basicSkill,
      Phase0aDamageKind.gather: null,
      Phase0aDamageKind.clear: null,
    };

    if (fromMapping) {
      return Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
        mapping: Phase0aEncounterMapping(
          initialState: initialState,
          director: director,
          roster: roster,
          combatants: combatants,
          moveBindings: moveBindings,
          playerAdapter: playerAdapter,
          enemyAiAdapter: enemyAdapter,
        ),
        numbers: GameRepository.instance.numbers,
        rng: math.Random(131),
        enemyIntentBatchGate: enemyIntentBatchGate,
        objectiveTracker: objectiveTracker,
        objectiveEventSource: objectiveEventSource,
      );
    }
    return Phase0aProductionFlowAssembler.assembleEncounter(
      initialState: initialState,
      director: director,
      roster: roster,
      combatants: combatants,
      moveBindings: moveBindings,
      numbers: GameRepository.instance.numbers,
      rng: math.Random(131),
      playerAdapter: playerAdapter,
      enemyAiAdapter: enemyAdapter,
      enemyIntentBatchGate: enemyIntentBatchGate,
      objectiveTracker: objectiveTracker,
      objectiveEventSource: objectiveEventSource,
    );
  }

  test(
    'direct and mapping bridges compose explicit token and objective seams',
    () {
      for (final fromMapping in [false, true]) {
        final exactGate = _CountingPassThroughGate();
        final exactTracker = tracker();
        final exactSource = _DefeatObjectiveSource();
        final flow = assemble(
          fromMapping: fromMapping,
          enemyIntentBatchGate: exactGate,
          objectiveTracker: exactTracker,
          objectiveEventSource: exactSource,
        );

        final events = flow.advance(
          deltaSeconds: 0.5,
          command: const Phase0aPlayerCommand(
            attack: true,
            attackAimDirection: ArenaVector(1, 0),
          ),
        );

        expect(exactGate.calls, 1, reason: 'fromMapping=$fromMapping');
        expect(exactSource.calls, 1, reason: 'fromMapping=$fromMapping');
        expect(
          exactSource.frames.single.combatEvents,
          contains(isA<Phase0aEnemyDefeated>()),
        );
        expect(exactTracker.progress.completed, isTrue);
        expect(flow.outcome, Phase0aBattleOutcome.victory);
        expect(events.last, isA<Phase0aBattleVictory>());
      }
    },
  );

  test('assembler keeps objective tracker and source pair fail closed', () {
    for (final fromMapping in [false, true]) {
      expect(
        () => assemble(
          fromMapping: fromMapping,
          enemyIntentBatchGate: null,
          objectiveTracker: tracker(),
          objectiveEventSource: null,
        ),
        throwsArgumentError,
      );
      expect(
        () => assemble(
          fromMapping: fromMapping,
          enemyIntentBatchGate: null,
          objectiveTracker: null,
          objectiveEventSource: _DefeatObjectiveSource(),
        ),
        throwsArgumentError,
      );
    }
  });
}
