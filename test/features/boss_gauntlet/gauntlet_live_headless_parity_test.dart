import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/phase0a_gauntlet_stage_runner.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/phase0a_gauntlet_battle_host.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_gauntlet_parity_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await IsarSetup.instance.writeTxn(() async {
      final isar = IsarSetup.instance;
      final character = (await isar.characters.get(1))!
        ..isFounder = false
        ..lineageRole = LineageRole.disciple
        ..realmTier = RealmTier.wuSheng
        ..currentRetreatSessionId = null;
      await isar.characters.put(character);
      final save = (await isar.saveDatas.get(0))!
        ..gauntletRunSerial = 20
        ..duanhunClearedCyclesMax = 1;
      await isar.saveDatas.put(save);
      final ticket =
          await isar.inventoryItems.getByDefId(GauntletService.ticketDefId) ??
          (InventoryItem()
            ..defId = GauntletService.ticketDefId
            ..itemType = ItemType.ticket
            ..firstObtainedAt = DateTime.utc(2026, 9, 7)
            ..lastObtainedAt = DateTime.utc(2026, 9, 7));
      ticket.quantity = 1;
      await isar.inventoryItems.put(ticket);
    });
  });
  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  for (final cycle in [1, 2]) {
    testWidgets('新开局 cycle=$cycle 真实 live 宿主与 headless 全状态及事件流一致', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = GauntletService(IsarSetup.instance);
      final repository = GameRepository.instance;
      final config = repository.bossGauntletConfig!;
      final numbers = repository.numbers;
      final headless = (await tester.runAsync(() async {
        await service.enter(characterIds: [1], supplyCap: 3, cycleIndex: cycle);
        final plan = await service.preparePhase0aStage(config: config);
        return Phase0aGauntletStageRunner.run(
          contentId: 'gauntlet_${plan.stage}',
          playerSnapshot: plan.playerSnapshot,
          enemyTeam: plan.enemyDefs,
          numbers: numbers,
          seed: plan.seed,
          cycleIndex: plan.cycleIndex,
        );
      }))!;
      Phase0aGauntletStageResult? live;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [gauntletServiceProvider.overrideWithValue(service)],
          // Both consumers receive exactly the same fixed-step bot commands.
          // The production host still assembles its own plan, mapping and RNG.
          child: TickerMode(
            enabled: false,
            child: MaterialApp(
              home: Phase0aGauntletBattleHost(
                config: config,
                onCompleted: (result) => live = result,
              ),
            ),
          ),
        ),
      );
      final screenFinder = find.byType(Phase0aBattleScreen);
      for (
        var attempt = 0;
        attempt < 100 && screenFinder.evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(screenFinder, findsOneWidget);
      final controller = tester
          .widget<Phase0aBattleScreen>(screenFinder)
          .controller;
      expect(controller.state.tick, 0);
      final bot = Phase0aPlayerBotAdapter(
        playerAdapter: headless.mapping.playerAdapter,
      );
      for (
        var tick = 0;
        tick < numbers.phase0aArena.maxSimulationTicks &&
            controller.outcome == Phase0aBattleOutcome.ongoing;
        tick++
      ) {
        controller.step(bot.commandFor(controller.state));
      }
      expect(headless.outcome, isNot(Phase0aBattleOutcome.ongoing));
      expect(headless.events, isNotEmpty);
      expect(live, isNotNull);
      expect(live!.outcome, headless.outcome);
      expect(live!.finalState, headless.finalState);
      expect(live!.events, headless.events);
      expect(live!.checkpoint.currentHp, headless.checkpoint.currentHp);
      expect(live!.checkpoint.currentQi, headless.checkpoint.currentQi);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }
}
