import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_headless_runner.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/application/phase0a_expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_seed.dart';

import '../../support/isar_test_support.dart';
import '../../support/phase0a_ch1_founder_profile.dart';
import '../../support/phase0a_production_headless_benchmark.dart';

void main() {
  late Directory directory;
  late GameRepository repository;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('expedition_detail_');
    await IsarSetup.init(directory: directory, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  Future<({ExpeditionRun run, ExpeditionNode node, int seed})> prepare(
    String school,
  ) async {
    final profile = await seedPhase0aCh1FounderProfile(
      isar: IsarSetup.instance,
      schoolId: school,
      originId: 'mountain_wanderer',
      fateId: 'balanced_seed',
      rngSeed: 20260820,
    );
    final service = ExpeditionService(IsarSetup.instance);
    await service.dispatchRequest(
      request: ExpeditionService.dispatchRequestFor(
        characterId: profile.snapshot.characterId,
      ),
      policy: ExpeditionPolicy.yiZhanLiXing,
      now: DateTime.utc(2026, 9, 14),
    );
    final run = (await service.activeRun())!;
    final config = repository.expeditionConfig!;
    // A generated ordinary node exercises the production combat adapter only.
    // It is not a simulated passage through preceding nodes or a manual clear.
    final node = [
      for (var index = 1; index <= 20; index++)
        ExpeditionRules.generateNode(
          saveId: run.saveDataId,
          runSerial: run.seed,
          node: index,
          policy: run.policy,
          normalMinutes: config.normalNodeMinutes,
          eliteMinutes: config.eliteNodeMinutes,
        ),
    ].firstWhere((node) => node.type == ExpeditionNodeType.zaoYu);
    return (
      run: run,
      node: node,
      seed: ExpeditionSeed.forNode(
        saveId: run.saveDataId,
        runSerial: run.seed,
        node: node.index,
      ),
    );
  }

  for (final school in ['gang_meng', 'ling_qiao', 'yin_rou']) {
    test(
      '$school detailed evidence and service-facing outcome use one combat path',
      () async {
        final plan = await prepare(school);
        Phase0aExpeditionCombatRunner runner() => Phase0aExpeditionCombatRunner(
          IsarSetup.instance,
          expectedMember: plan.run.members.single,
        );
        final firstRunner = runner();
        final id = plan.run.members.single.characterId;
        final caps = (await firstRunner.memberCaps([id]))[id]!;
        final states = {
          id: ExpeditionMemberVital(hp: caps.maxHp, qi: caps.maxQi),
        };
        Future<Phase0aExpeditionCombatResult> detailed(
          Phase0aExpeditionCombatRunner combat,
        ) => combat.fightDetailed(
          node: plan.node,
          memberStates: states,
          nodeSeed: plan.seed,
          cycleIndex: plan.run.cycleIndex,
        );
        final first = await detailed(firstRunner);
        final second = await detailed(runner());
        final ordinary = await runner().fight(
          node: plan.node,
          memberStates: states,
          nodeSeed: plan.seed,
          cycleIndex: plan.run.cycleIndex,
        );
        expect(first.headless.ticks, greaterThan(0));
        expect(first.headless.events, isNotEmpty);
        expect(first.headless.eventRecords, isNotEmpty);
        expect(second.headless.outcome, first.headless.outcome);
        expect(second.headless.ticks, first.headless.ticks);
        expect(second.headless.finalState, first.headless.finalState);
        expect(second.headless.events, first.headless.events);
        expect(second.headless.eventRecords, first.headless.eventRecords);
        for (final outcome in [second.nodeOutcome, ordinary]) {
          expect(outcome.leftWin, first.nodeOutcome.leftWin);
          expect(outcome.survivorHp, first.nodeOutcome.survivorHp);
          expect(outcome.survivorQi, first.nodeOutcome.survivorQi);
          expect(
            headlessSettlementFacts(outcome.combatSettlement!),
            headlessSettlementFacts(first.nodeOutcome.combatSettlement!),
          );
        }
        expect(first.nodeOutcome.survivorHp, {
          id: first.headless.finalState.player.currentHealth,
        });
        expect(first.nodeOutcome.survivorQi, {
          id: first.headless.finalState.player.qiCurrent,
        });
        expect(first.mapping.initialState.player.currentHealth, caps.maxHp);
        expect(first.mapping.initialState.player.qiCurrent, caps.maxQi);
        final unchanged = (await ExpeditionService(
          IsarSetup.instance,
        ).activeRun())!;
        expect(
          unchanged.currentNode,
          0,
          reason: 'Observing combat must not settle progression',
        );
        expect(unchanged.stagedRewards, isEmpty);
      },
    );
  }

  test(
    'real reducer tick-limit boundary retains ongoing beside the existing defeat policy',
    () async {
      final plan = await prepare('yin_rou');
      final runner = Phase0aExpeditionCombatRunner(
        IsarSetup.instance,
        expectedMember: plan.run.members.single,
      );
      final id = plan.run.members.single.characterId;
      final caps = (await runner.memberCaps([id]))[id]!;
      final reference = await runner.fightDetailed(
        node: plan.node,
        memberStates: {
          id: ExpeditionMemberVital(hp: caps.maxHp, qi: caps.maxQi),
        },
        nodeSeed: plan.seed,
        cycleIndex: plan.run.cycleIndex,
      );
      final mapping = reference.mapping;
      final flow = Phase0aProductionFlowAssembler.assemble(
        initialState: mapping.initialState,
        waves: mapping.waves,
        combatants: mapping.combatants,
        moveBindings: mapping.moveBindings,
        numbers: repository.numbers,
        rng: Random(plan.seed),
        playerAdapter: mapping.playerAdapter,
        enemyAiAdapter: mapping.enemyAiAdapter,
      );
      // Deliberately short boundary fixture, not a production timeout sample.
      final limited = Phase0aHeadlessRunner.runToEnd(
        flow: flow,
        bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
        deltaSeconds: repository.numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: 1,
      );
      expect(limited.outcome, Phase0aBattleOutcome.ongoing);
      final result = Phase0aExpeditionCombatResult.fromHeadless(
        mapping: mapping,
        headless: limited,
      );
      expect(result.headless.timedOut, isTrue);
      expect(result.headless.ticks, 1);
      expect(result.headless.events, limited.events);
      expect(result.headless.eventRecords, limited.eventRecords);
      expect(result.nodeOutcome.leftWin, isFalse);
      expect(
        result.nodeOutcome.combatSettlement!.isFinished,
        isTrue,
        reason: 'Existing expedition defeat policy remains unchanged',
      );
      expect(result.nodeOutcome.survivorHp, {
        id: limited.finalState.player.currentHealth,
      });
      expect(result.nodeOutcome.survivorQi, {
        id: limited.finalState.player.qiCurrent,
      });
    },
  );
}
