import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_bot_tactic.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';

import '../support/combatant_snapshot_fixture.dart';
import '../support/test_data.dart';

enum _Scenario { clear, elite, boss }

extension on _Scenario {
  String get stageId => switch (this) {
    _Scenario.clear => 'stage_02_03',
    _Scenario.elite => 'stage_02_04',
    _Scenario.boss => 'stage_02_05',
  };
}

typedef _Metrics = ({
  Phase0aBattleOutcome outcome,
  bool timedOut,
  int ticks,
  int attacks,
  int hits,
  int maxHitsPerTick,
  int enemyActions,
  int enemyHits,
  int defeatedEnemies,
  int postureEvents,
  int initialHealth,
  int finalHealth,
});

void main() {
  late GameRepository repository;

  setUpAll(() async {
    repository = await loadTestGameRepository();
  });

  tearDownAll(GameRepository.resetForTest);

  test(
    'five production profiles x three schools clear real encounters with a capped control player',
    () async {
      final results =
          <WeaponArchetype, Map<TechniqueSchool, Map<_Scenario, _Metrics>>>{};
      for (final archetype in WeaponArchetype.values) {
        results[archetype] = {};
        for (final school in TechniqueSchool.values) {
          results[archetype]![school] = {};
          for (final scenario in _Scenario.values) {
            results[archetype]![school]![scenario] = await _simulate(
              repository: repository,
              archetype: archetype,
              school: school,
              scenario: scenario,
            );
          }
        }
      }

      final allMetrics = results.values
          .expand((schools) => schools.values)
          .expand((scenarios) => scenarios.values)
          .toList();
      expect(results, hasLength(WeaponArchetype.values.length));
      expect(
        allMetrics,
        hasLength(
          WeaponArchetype.values.length *
              TechniqueSchool.values.length *
              _Scenario.values.length,
        ),
      );
      for (final archetypeEntry in results.entries) {
        for (final schoolEntry in archetypeEntry.value.entries) {
          for (final scenarioEntry in schoolEntry.value.entries) {
            final metrics = scenarioEntry.value;
            final caseId =
                '${archetypeEntry.key.name}/${schoolEntry.key.name}/${scenarioEntry.key.name}';
            expect(
              metrics.outcome,
              Phase0aBattleOutcome.victory,
              reason: caseId,
            );
            expect(metrics.timedOut, isFalse, reason: caseId);
            expect(
              metrics.ticks,
              inInclusiveRange(
                1,
                repository.numbers.phase0aArena.maxSimulationTicks - 1,
              ),
              reason: caseId,
            );
            expect(metrics.attacks, greaterThan(0), reason: caseId);
            expect(metrics.hits, greaterThan(0), reason: caseId);
            expect(
              metrics.hits,
              lessThanOrEqualTo(metrics.attacks),
              reason: caseId,
            );
            expect(metrics.maxHitsPerTick, 1, reason: caseId);
            expect(metrics.enemyActions, greaterThan(0), reason: caseId);
            expect(metrics.defeatedEnemies, greaterThan(0), reason: caseId);
            expect(
              metrics.finalHealth,
              inInclusiveRange(1, metrics.initialHealth),
              reason: caseId,
            );
          }
          final schoolMetrics = schoolEntry.value.values;
          expect(
            schoolMetrics.fold(0, (sum, metrics) => sum + metrics.enemyHits),
            greaterThan(0),
            reason:
                '${archetypeEntry.key.name}/${schoolEntry.key.name}/enemy pressure',
          );
          expect(
            schoolMetrics.any(
              (metrics) => metrics.finalHealth < metrics.initialHealth,
            ),
            isTrue,
            reason:
                '${archetypeEntry.key.name}/${schoolEntry.key.name}/health pressure',
          );
        }
      }
      expect(
        allMetrics.fold(0, (sum, metrics) => sum + metrics.postureEvents),
        greaterThan(0),
        reason: 'real elite/Boss encounters must exercise posture settlement',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<_Metrics> _simulate({
  required GameRepository repository,
  required WeaponArchetype archetype,
  required TechniqueSchool school,
  required _Scenario scenario,
}) async {
  // This red-line-capped control profile isolates weapon/runtime compatibility.
  // It is not evidence that a normal save clears the stages or that the five
  // profiles feel equally good under human control.
  final playerSnapshot = testCombatantSnapshot(
    characterId: 1,
    name: 'm3_player',
    school: school,
    maxHp: 20000,
    currentHp: 20000,
    internalForce: 15000,
    maxQi: 100,
    currentQi: 0,
    criticalRate: 0,
    evasionRate: 0,
    defenseRate: repository.numbers.cycleEvolution.defenseRateCap,
    totalEquipmentAttack: 2000,
    weaponArchetype: archetype,
    includeProductionBasicAttack: true,
  );
  final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
    contentId: scenario.stageId,
    playerSnapshot: playerSnapshot,
    numbers: repository.numbers,
  );
  final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
    loader: ({required stageId, required encounterId, required cycleIndex}) =>
        buildPhase0aMainlineRuntimeBindingBundleFromRepository(
          stageId: stageId,
          encounterId: encounterId,
          cycleIndex: cycleIndex,
          repository: repository,
        ),
  );
  final host = await createFreshPhase0aMainlineEncounter(
    Phase0aMainlineEncounterHostBuildRequest(
      stage: repository.getStage(scenario.stageId),
      playerMapping: playerMapping,
      numbers: repository.numbers,
      cycleIndex: 1,
      rng: math.Random(
        archetype.index * 100 + school.index * 10 + scenario.index + 1,
      ),
      runtimeBindingSource: source,
      catalogOverride: repository.combatCatalog,
    ),
  );
  expect(host, isNotNull, reason: scenario.stageId);
  final productionHost = host!;
  final bot = Phase0aPlayerBotAdapter(
    playerAdapter: productionHost.mapping!.playerAdapter,
    policy: const Phase0aBotTacticPolicy.assault(),
    objectiveContinuationCommandBuilder:
        productionHost.objectiveContinuationCommandBuilder,
  );
  final deltaSeconds = repository.numbers.phase0aArena.fixedDeltaSeconds;
  final maxTicks = repository.numbers.phase0aArena.maxSimulationTicks;
  final events = <Phase0aEvent>[];
  var ticks = 0;
  var enemyIntentCount = 0;
  while (productionHost.flow.outcome == Phase0aBattleOutcome.ongoing &&
      ticks < maxTicks) {
    enemyIntentCount += productionHost.mapping!.enemyAiAdapter
        .intentsFor(state: productionHost.flow.state)
        .length;
    events.addAll(
      productionHost.advanceAuto(deltaSeconds: deltaSeconds, bot: bot),
    );
    ticks += 1;
  }

  final playerAttacks = events
      .whereType<Phase0aAttackStarted>()
      .where((event) => event.actor == 'player')
      .toList();
  final playerHits = events
      .whereType<Phase0aHitLanded>()
      .where((event) => event.actor == 'player')
      .toList();
  final playerHitsByTick = <int, int>{};
  for (final hit in playerHits) {
    playerHitsByTick.update(hit.tick, (count) => count + 1, ifAbsent: () => 1);
  }
  final enemyBasicActions = events
      .whereType<Phase0aAttackStarted>()
      .where((event) => event.actor != 'player')
      .length;
  final enemySkillActions = events
      .whereType<Phase0aEnemySkillStarted>()
      .where((event) => event.actor != 'player')
      .length;
  final enemyHits = events
      .whereType<Phase0aHitLanded>()
      .where((event) => event.target == 'player')
      .length;

  expect(
    playerAttacks.every(
      (event) =>
          event.basicAttackSegment == null &&
          event.weaponArchetype == archetype &&
          event.visualSchool == school,
    ),
    isTrue,
    reason: '${scenario.stageId}/${archetype.name}/${school.name}',
  );
  expect(
    playerHits.every(
      (event) =>
          event.basicAttackSegment == null &&
          event.weaponArchetype == archetype &&
          event.visualSchool == school,
    ),
    isTrue,
    reason: '${scenario.stageId}/${archetype.name}/${school.name}',
  );

  return (
    outcome: productionHost.flow.outcome,
    timedOut: productionHost.flow.outcome == Phase0aBattleOutcome.ongoing,
    ticks: ticks,
    attacks: playerAttacks.length,
    hits: playerHits.length,
    maxHitsPerTick: playerHitsByTick.values.fold(0, math.max),
    enemyActions: enemyIntentCount + enemyBasicActions + enemySkillActions,
    enemyHits: enemyHits,
    defeatedEnemies: events.whereType<Phase0aEnemyDefeated>().length,
    postureEvents: events.whereType<Phase0aPostureChanged>().length,
    initialHealth: playerSnapshot.currentHp,
    finalHealth: productionHost.flow.state.player.currentHealth,
  );
}
