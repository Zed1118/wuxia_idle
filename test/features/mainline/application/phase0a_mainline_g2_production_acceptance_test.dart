import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_host.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_encounter_host.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_production_encounter_factory.dart';
import 'package:wuxia_idle/features/mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  late Phase0aPlayerRuntimeMapping playerMapping;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
      contentId: 'stage_01_03',
      playerSnapshot: testCombatantSnapshot(
        maxHp: 20000,
        currentHp: 20000,
        internalForce: 15000,
        maxQi: 15000,
        currentQi: 15000,
        totalEquipmentAttack: 2000,
        includeProductionBasicAttack: true,
      ),
      numbers: repository.numbers,
    );
  });

  Future<Phase0aEncounterHost> fresh(int seed) async {
    final source = Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
      loader:
          ({
            required String stageId,
            required String encounterId,
            required int cycleIndex,
          }) async => buildPhase0aMainlineRuntimeBindingBundleFromRepository(
            stageId: stageId,
            encounterId: encounterId,
            cycleIndex: cycleIndex,
            repository: repository,
          ),
    );
    return (await createFreshPhase0aMainlineEncounter(
      Phase0aMainlineEncounterHostBuildRequest(
        stage: repository.getStage('stage_01_03'),
        playerMapping: playerMapping,
        numbers: repository.numbers,
        cycleIndex: 1,
        rng: Random(seed),
        runtimeBindingSource: source,
        catalogOverride: repository.combatCatalog,
      ),
    ))!;
  }

  test('production stage_01_03 continuously clears all 40 enemies', () async {
    final host = await fresh(20260824);
    final bot = Phase0aPlayerBotAdapter(
      playerAdapter: host.mapping!.playerAdapter,
    );
    final delta = repository.numbers.phase0aArena.fixedDeltaSeconds;
    final maxTicks = repository.numbers.phase0aArena.maxSimulationTicks;
    final events = <Phase0aEvent>[];
    var ticks = 0;
    var maxActive = 0;
    var moveAndAttackCommands = 0;
    var moveAndAttackResolved = 0;

    while (host.flow.outcome == Phase0aBattleOutcome.ongoing &&
        ticks < maxTicks) {
      final before = host.flow.state;
      final command = bot.commandFor(before);
      final emitted = host.advanceManual(deltaSeconds: delta, command: command);
      events.addAll(emitted);
      maxActive = max(maxActive, host.flow.state.enemies.length);
      final moving =
          command.left || command.right || command.up || command.down;
      if (moving && command.attack) {
        moveAndAttackCommands += 1;
        final playerMoved =
            host.flow.state.player.position != before.player.position;
        final playerAttacked = emitted.whereType<Phase0aAttackStarted>().any(
          (event) => event.actor == before.player.id,
        );
        if (playerMoved && playerAttacked) moveAndAttackResolved += 1;
      }
      ticks += 1;
    }

    final defeated = events.whereType<Phase0aEnemyDefeated>().toList();
    expect(host.flow.outcome, Phase0aBattleOutcome.victory);
    expect(ticks, lessThan(maxTicks));
    expect(defeated, hasLength(40));
    expect(defeated.map((event) => event.target).toSet(), hasLength(40));
    expect(maxActive, 12);
    expect(moveAndAttackCommands, greaterThan(0));
    expect(moveAndAttackResolved, greaterThan(0));
    final settlement = host.settle(
      outcome: host.flow.outcome,
      finalState: host.flow.state,
      events: events,
    );
    expect(settlement.snapshot.result, BattleResult.leftWin);
    expect(settlement.nextStageId, 'stage_01_04');
  });

  test('manual auto and headless use the same production rules', () async {
    final manual = await fresh(20260824);
    final auto = await fresh(20260824);
    final headless = await fresh(20260824);
    final delta = repository.numbers.phase0aArena.fixedDeltaSeconds;
    final maxTicks = repository.numbers.phase0aArena.maxSimulationTicks;
    final manualBot = Phase0aPlayerBotAdapter(
      playerAdapter: manual.mapping!.playerAdapter,
    );
    final autoBot = Phase0aPlayerBotAdapter(
      playerAdapter: auto.mapping!.playerAdapter,
    );
    final headlessBot = Phase0aPlayerBotAdapter(
      playerAdapter: headless.mapping!.playerAdapter,
    );
    final manualEvents = <Phase0aEvent>[];
    final autoEvents = <Phase0aEvent>[];
    var manualTicks = 0;
    var autoTicks = 0;

    while (manual.flow.outcome == Phase0aBattleOutcome.ongoing &&
        manualTicks < maxTicks) {
      manualEvents.addAll(
        manual.advanceManual(
          deltaSeconds: delta,
          command: manualBot.commandFor(manual.flow.state),
        ),
      );
      manualTicks += 1;
    }
    while (auto.flow.outcome == Phase0aBattleOutcome.ongoing &&
        autoTicks < maxTicks) {
      autoEvents.addAll(auto.advanceAuto(deltaSeconds: delta, bot: autoBot));
      autoTicks += 1;
    }
    final headlessResult = headless.runHeadless(
      bot: headlessBot,
      deltaSeconds: delta,
      maxTicks: maxTicks,
    );

    expect(manual.flow.outcome, Phase0aBattleOutcome.victory);
    expect(auto.flow.outcome, manual.flow.outcome);
    expect(headlessResult.outcome, manual.flow.outcome);
    expect(autoTicks, manualTicks);
    expect(headlessResult.ticks, manualTicks);
    expect(autoEvents, manualEvents);
    expect(headlessResult.events, manualEvents);
    expect(auto.flow.state, manual.flow.state);
    expect(headlessResult.finalState, manual.flow.state);
  });
}
