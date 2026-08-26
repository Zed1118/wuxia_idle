import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/attack_token_observe_only_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/attack_token_director.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

const _basicSkill = SkillDef(
  id: 'phase0a_d08_basic',
  name: 'basic',
  description: 'basic',
  type: SkillType.normalAttack,
  powerMultiplier: 500,
  qiDelta: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: '',
);

Phase0aActor _actor({
  required String id,
  required Phase0aSide side,
  required ArenaVector position,
}) {
  return Phase0aActor(
    id: id,
    side: side,
    position: position,
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

CombatantSnapshot _snapshot({
  required int characterId,
  required TechniqueSchool school,
  required double criticalRate,
}) {
  return testCombatantSnapshot(
    characterId: characterId,
    name: 'd08_$characterId',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.ruMen,
    school: school,
    maxHp: 1000,
    internalForce: 400,
    maxQi: 100,
    speed: 100,
    criticalRate: criticalRate,
    evasionRate: 0,
    defenseRate: 0.05,
    totalEquipmentAttack: 90,
    mainCultivationLayer: CultivationLayer.chuKui,
  );
}

({SpawnDirector director, Phase0aEncounterRoster roster}) _encounter() {
  final director = SpawnDirector(
    config: SpawnDirectorConfig(
      activeLimit: 1,
      reinforcementThreshold: 0,
      entryWarningTicks: 1,
      attackGraceTicks: 2,
    ),
    entries: [SpawnEntry(entryId: 'entry_enemy_1', enemyId: 'enemy_1')],
  );
  return (
    director: director,
    roster: Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
      bindings: [
        Phase0aEncounterRosterBinding(
          entryId: 'entry_enemy_1',
          actor: _actor(
            id: 'enemy_1',
            side: Phase0aSide.enemy,
            position: const ArenaVector(50, 0),
          ),
        ),
      ],
    ),
  );
}

Phase0aEncounterFlow _assemble({
  required math.Random rng,
  AttackTokenObserveOnlyObserver? observer,
}) {
  final encounter = _encounter();
  return Phase0aProductionFlowAssembler.assembleEncounter(
    initialState: Phase0aArenaState(
      tick: 0,
      nextSeq: 0,
      player: _actor(
        id: 'player',
        side: Phase0aSide.player,
        position: ArenaVector.zero,
      ),
      enemies: const [],
      skillSlots: const [],
    ),
    director: encounter.director,
    roster: encounter.roster,
    combatants: [
      Phase0aCombatantInput(
        actorId: 'player',
        snapshot: _snapshot(
          characterId: 1,
          school: TechniqueSchool.gangMeng,
          criticalRate: 0,
        ),
      ),
      Phase0aCombatantInput(
        actorId: 'enemy_1',
        snapshot: _snapshot(
          characterId: 2,
          school: TechniqueSchool.yinRou,
          criticalRate: 0.5,
        ),
      ),
    ],
    moveBindings: const {
      Phase0aDamageKind.basic: _basicSkill,
      Phase0aDamageKind.gather: null,
      Phase0aDamageKind.clear: null,
    },
    numbers: GameRepository.instance.numbers,
    rng: rng,
    playerAdapter: const Phase0aPlayerInputAdapter(
      playerId: 'player',
      attackRange: 120,
      attackHalfArcRadians: math.pi / 4,
      attackCooldownSeconds: 0.5,
      attackQiDelta: 0,
      postureBasicPowerMultiplier: 1,
      attackPowerMultiplier: 1,
      gatherPowerMultiplier: 1,
      clearPowerMultiplier: 1,
      gatherSlot: 'gather',
      gatherRingRadius: 90,
      gatherEffectRadius: 500,
      gatherQiCost: 20,
      gatherCooldownSeconds: 3,
      clearSlot: 'clear',
      clearEffectRadius: 500,
      clearQiCost: 30,
      clearCooldownSeconds: 4,
    ),
    enemyAiAdapter: const Phase0aEnemyAiAdapter(
      attackRange: 70,
      attackHalfArcRadians: math.pi / 3,
      attackCooldownSeconds: 0.5,
      postureBasicPowerMultiplier: 1,
      uniformBasicPowerMultiplier: 1,
    ),
    enemyIntentObserver: observer,
  );
}

void _expectSpawnParity(
  Phase0aEncounterFlow observed,
  Phase0aEncounterFlow baseline,
) {
  expect(observed.spawnState.tick, baseline.spawnState.tick);
  expect(observed.spawnState.totalCount, baseline.spawnState.totalCount);
  expect(observed.spawnState.activeCount, baseline.spawnState.activeCount);
  expect(observed.spawnState.warningCount, baseline.spawnState.warningCount);
  expect(observed.spawnState.pendingCount, baseline.spawnState.pendingCount);
  expect(observed.spawnState.removedCount, baseline.spawnState.removedCount);
  expect(observed.spawnState.units, baseline.spawnState.units);
}

void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  test('assembleEncounter 五拍保留 AttackToken observer 且只观察 grace 后 intents', () {
    const seed = 80923;
    var mapperCalls = 0;
    final observer = AttackTokenObserveOnlyObserver(
      director: const AttackTokenDirector(),
      budgets: AttackTokenBudgets(melee: 1, ranged: 0, charge: 0, support: 0),
      requestMapper: (intent) {
        mapperCalls++;
        if (intent is! Phase0aAttackIntent) return null;
        return AttackTokenRequest(
          actorId: intent.actorId,
          kind: AttackTokenKind.melee,
          priority: 0,
          isOffscreen: false,
          isHighImpact: false,
          isUnblockableArea: false,
          spawnGraceTicksRemaining: 0,
          telegraphReady: true,
        );
      },
    );
    final baselineRng = math.Random(seed);
    final observedRng = math.Random(seed);
    final baseline = _assemble(rng: baselineRng);
    final observed = _assemble(rng: observedRng, observer: observer);

    AttackTokenAllocation? previousAllocation;
    for (var tick = 1; tick <= 5; tick++) {
      final baselineEvents = baseline.advance(
        deltaSeconds: 1,
        command: const Phase0aPlayerCommand(),
      );
      final observedEvents = observed.advance(
        deltaSeconds: 1,
        command: const Phase0aPlayerCommand(),
      );

      expect(observedEvents, baselineEvents, reason: 'tick $tick events');
      expect(observed.state, baseline.state, reason: 'tick $tick state');
      expect(observed.outcome, baseline.outcome, reason: 'tick $tick outcome');
      expect(
        observed.lastOrderedEventRecords,
        baseline.lastOrderedEventRecords,
        reason: 'tick $tick records',
      );
      _expectSpawnParity(observed, baseline);

      final allocation = observer.lastAllocation;
      expect(allocation, isNotNull, reason: 'tick $tick observer 未被调用');
      expect(
        allocation,
        isNot(same(previousAllocation)),
        reason: 'tick $tick fork 丢失外部 observer identity',
      );
      previousAllocation = allocation;

      if (tick <= 3) {
        expect(allocation!.decisions, isEmpty, reason: 'tick $tick grace');
        expect(mapperCalls, 0, reason: 'grace gate 必须先于 observer');
      } else {
        expect(allocation!.decisions, hasLength(1));
        expect(allocation.grantedActorIds, ['enemy_1']);
        expect(allocation.decisions.single.granted, isTrue);
        expect(mapperCalls, tick - 3);
      }

      if (tick == 1) {
        expect(
          observedEvents.whereType<Phase0aSpawnWarningStarted>(),
          hasLength(1),
        );
      } else if (tick == 2) {
        expect(observedEvents.whereType<Phase0aEnemyEntered>(), hasLength(1));
      } else if (tick == 4) {
        expect(
          observedEvents.whereType<Phase0aSpawnGraceExpired>(),
          hasLength(1),
        );
      }
      final enemyHits = observedEvents
          .whereType<Phase0aHitLanded>()
          .where((event) => event.actor == 'enemy_1')
          .toList();
      expect(enemyHits, tick >= 4 ? hasLength(1) : isEmpty);
    }

    expect(observed.outcome, Phase0aBattleOutcome.ongoing);
    expect(mapperCalls, 2);

    // 只有 tick4/tick5 两次真实敌方命中；每次伤害结算固定消费
    // evasion + critical 两个 roll。精确尾值同时锁住宽限拍零消费、
    // observer 零额外消费以及逐拍 fork 不重置 caller RNG。
    final expectedRng = math.Random(seed);
    for (var i = 0; i < 4; i++) {
      expectedRng.nextDouble();
    }
    final expectedTail = expectedRng.nextDouble();
    expect(baselineRng.nextDouble(), expectedTail);
    expect(observedRng.nextDouble(), expectedTail);
  });
}
