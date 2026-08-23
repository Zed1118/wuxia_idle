import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/combat_encounter_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/validation/combat_stage_encounter_route_selector.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/attack_token_enforcing_batch_gate.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_explicit_objective_event_source.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_migrated_encounter_plan_builder.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

const _basicSkill = SkillDef(
  id: 'batch14_migrated_composition_basic',
  name: 'basic',
  description: 'basic',
  type: SkillType.normalAttack,
  powerMultiplier: 500,
  qiDelta: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
);

const _playerAdapter = Phase0aPlayerInputAdapter(
  playerId: 'player',
  attackRange: 20,
  attackHalfArcRadians: math.pi / 4,
  attackCooldownSeconds: 0.5,
  attackQiDelta: 0,
  gatherSlot: 'gather',
  gatherRingRadius: 10,
  gatherEffectRadius: 20,
  gatherQiCost: 20,
  gatherCooldownSeconds: 3,
  clearSlot: 'clear',
  clearEffectRadius: 20,
  clearQiCost: 30,
  clearCooldownSeconds: 4,
);

const _enemyAdapter = Phase0aEnemyAiAdapter(
  attackRange: 70,
  attackHalfArcRadians: math.pi / 3,
  attackCooldownSeconds: 0.5,
);

CombatEncounterSpawnEntry _entry(String id) => CombatEncounterSpawnEntry(
  entryId: 'entry_$id',
  archetypeId: 'archetype_$id',
  roleId: 'role_$id',
  entranceId: 'entrance_$id',
  positionId: 'position_$id',
  behaviorId: 'behavior_$id',
);

CombatEncounterDef _encounter() => CombatEncounterDef(
  id: 'batch14_migrated_encounter',
  spawnConfig: CombatEncounterSpawnConfig(
    activeLimit: 3,
    reinforcementThreshold: 0,
    entryWarningTicks: 0,
    attackGraceTicks: 0,
  ),
  tokenBudgets: CombatEncounterTokenBudgets(
    melee: 1,
    ranged: 0,
    charge: 0,
    support: 0,
  ),
  spawnEntries: [_entry('e1'), _entry('e2'), _entry('e3')],
  objectives: CombatObjectiveCompositionRef(
    completionRule: CombatObjectiveCompletionRule.all,
    clauses: [
      CombatObjectiveClauseRef(
        id: 'defeat_exact_target',
        primitive: CombatDefeatTargetsRef(const ['objective_e1']),
      ),
    ],
  ),
);

Phase0aActor _actor({
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
  maxHealth: side == Phase0aSide.player ? 100000 : health,
  currentHealth: health,
  moveSpeed: 100,
  qiCurrent: 100,
  qiMax: 100,
  attackCooldownRemaining: 0,
  defeatKind: Phase0aDefeatKind.normal,
);

CombatantSnapshot _snapshot({required int characterId, required bool player}) =>
    testCombatantSnapshot(
      characterId: characterId,
      name: 'c$characterId',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.ruMen,
      school: player ? TechniqueSchool.gangMeng : TechniqueSchool.yinRou,
      maxHp: 1000,
      internalForce: player ? 600 : 300,
      maxQi: 100,
      speed: 100,
      criticalRate: 0,
      evasionRate: 0,
      defenseRate: 0,
      totalEquipmentAttack: player ? 130 : 60,
    );

Phase0aAttackTokenEnforcementRequestMapper _requestMapper({
  String? forcedActorId,
}) => (intent) {
  if (intent is! Phase0aAttackIntent) return null;
  final priority = switch (intent.actorId) {
    'e3' => 30,
    'e1' => 20,
    'e2' => 10,
    _ => 0,
  };
  return AttackTokenRequest(
    actorId: forcedActorId ?? intent.actorId,
    kind: AttackTokenKind.melee,
    priority: priority,
    isOffscreen: false,
    isHighImpact: false,
    isUnblockableArea: false,
    spawnGraceTicksRemaining: 0,
    telegraphReady: true,
  );
};

({
  Phase0aEncounterFlow flow,
  math.Random rng,
  Phase0aMigratedEncounterPlan plan,
})
_buildFlow({
  required int seed,
  Phase0aAttackTokenEnforcementRequestMapper? tokenRequestMapper,
}) {
  final route = MigratedCombatStageEncounterRoute(
    'batch14_stage',
    _encounter(),
  );
  final enemyPositions = {'e1': 10.0, 'e2': 50.0, 'e3': 60.0};
  final enemyHealth = {'e1': 1, 'e2': 10000, 'e3': 10000};
  final plan = buildPhase0aMigratedEncounterPlan(
    route,
    tickDuration: const Duration(milliseconds: 500),
    resolveEnemyId: (entry) => entry.entryId.substring('entry_'.length),
    playerId: 'player',
    createActor: (entry, enemyId) => _actor(
      id: enemyId,
      side: Phase0aSide.enemy,
      health: enemyHealth[enemyId]!,
      x: enemyPositions[enemyId]!,
    ),
    initialState: Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: _actor(
        id: 'player',
        side: Phase0aSide.player,
        health: 100000,
        x: 0,
      ),
      enemies: const [],
      skillSlots: const [],
    ),
    combatants: [
      Phase0aCombatantInput(
        actorId: 'player',
        snapshot: _snapshot(characterId: 1, player: true),
      ),
      for (var index = 1; index <= 3; index += 1)
        Phase0aCombatantInput(
          actorId: 'e$index',
          snapshot: _snapshot(characterId: index + 1, player: false),
        ),
    ],
    moveBindings: const {
      Phase0aDamageKind.basic: _basicSkill,
      Phase0aDamageKind.gather: null,
      Phase0aDamageKind.clear: null,
    },
    playerAdapter: _playerAdapter,
    enemyAiAdapter: _enemyAdapter,
  );
  final objectiveSource = Phase0aExplicitObjectiveEventSource(
    roster: plan.roster,
    defeatProjectionsByActorId: const {
      'e1': [Phase0aTargetDefeatProjection('objective_e1')],
      'e2': [],
      'e3': [],
    },
    externalProjectors: const [],
  );
  final rng = math.Random(seed);
  final flow = Phase0aProductionFlowAssembler.assembleMigratedEncounterPlan(
    plan: plan,
    numbers: GameRepository.instance.numbers,
    rng: rng,
    tokenRequestMapper: tokenRequestMapper ?? _requestMapper(),
    objectiveEventSource: objectiveSource,
  );
  return (flow: flow, rng: rng, plan: plan);
}

void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  test(
    'typed plan composes exact budgets and objective source in one flow',
    () {
      final first = _buildFlow(seed: 211);
      final second = _buildFlow(seed: 211);
      const command = Phase0aPlayerCommand(
        attack: true,
        attackAimDirection: ArenaVector(1, 0),
      );

      final firstEvents = first.flow.advance(
        deltaSeconds: 0.5,
        command: command,
      );
      final secondEvents = second.flow.advance(
        deltaSeconds: 0.5,
        command: command,
      );

      expect(first.plan.stageId, 'batch14_stage');
      expect(
        first.plan.mapping.director,
        same(first.plan.runtimeContracts.spawnDirector),
      );
      final enemyHits = firstEvents
          .whereType<Phase0aHitLanded>()
          .where((event) => event.target == 'player')
          .toList();
      expect(enemyHits.map((event) => event.actor), ['e3']);
      expect(
        first.flow.state.enemies
            .where((enemy) => enemy.isAlive)
            .map((enemy) => enemy.id),
        containsAll(['e2', 'e3']),
      );
      expect(first.flow.outcome, Phase0aBattleOutcome.victory);
      expect(firstEvents.last, isA<Phase0aBattleVictory>());
      expect(secondEvents, firstEvents);
      expect(second.flow.state, first.flow.state);
      expect(second.flow.outcome, first.flow.outcome);
      expect(second.rng.nextDouble(), first.rng.nextDouble());
    },
  );

  test('caller token mapper mismatch fails before publishing a tick', () {
    final built = _buildFlow(
      seed: 223,
      tokenRequestMapper: _requestMapper(forcedActorId: 'foreign_actor'),
    );
    final beforeState = built.flow.state;
    final beforeSpawn = built.flow.spawnState;

    expect(
      () => built.flow.advance(
        deltaSeconds: 0.5,
        command: const Phase0aPlayerCommand(),
      ),
      throwsArgumentError,
    );

    expect(built.flow.state, same(beforeState));
    expect(built.flow.spawnState.tick, beforeSpawn.tick);
    expect(built.flow.spawnState.units, beforeSpawn.units);
    expect(built.flow.outcome, Phase0aBattleOutcome.ongoing);
  });

  test('migrated bridge remains explicit and does not wire lease runtime', () {
    final source = File(
      'lib/features/battle/application/phase0a/'
      'phase0a_production_flow_assembler.dart',
    ).readAsStringSync();
    final method = source.substring(
      source.indexOf(
        'static Phase0aEncounterFlow assembleMigratedEncounterPlan',
      ),
      source.indexOf('  /// 全场 actor 精确覆盖'),
    );

    expect(method, contains('required Phase0aMigratedEncounterPlan plan'));
    expect(method, contains('contracts.attackTokenBudgets'));
    expect(method, contains('controller: contracts.objectiveController'));
    expect(method, contains('required Random rng'));
    expect(method, contains('required Phase0aEncounterObjectiveEventSource'));
    for (final forbidden in const [
      'AttackTokenLeaseRuntime',
      'ActionTimeline',
      'GameRepository',
      'rootBundle',
      'LegacyCombatStageEncounterRoute',
    ]) {
      expect(method, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
