import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_settlement_journal.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/utils/math_random.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';
import '../support/isar_test_support.dart';
import '../support/test_data.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(
    finder,
    findsWidgets,
    reason: tester.allWidgets.whereType<Text>().map((t) => t.data).join('|'),
  );
}

void main() {
  testWidgets(
    'real first victory survives progress reload and enters next stage',
    (tester) async {
      late Directory temp;
      await tester.runAsync(() async {
        await initializeTestIsarCore();
        await loadTestGameRepository();
        temp = await Directory.systemTemp.createTemp('p2_legal_chain_');
        addTearDown(() async {
          if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
          IsarSetup.resetForTest();
          if (await temp.exists()) await temp.delete(recursive: true);
        });
        await IsarSetup.init(directory: temp, inspector: false);
        final c = GameRepository.instance.founderCreation;
        expect(
          await OnboardingService(
            isar: IsarSetup.instance,
            rng: DefaultRng(seed: 20260820),
          ).createFoundingMaster(
            selection: FounderCreationSelection(
              school: c.schools.singleWhere((s) => s.id == 'gang_meng'),
              origin: c.origins.singleWhere((s) => s.id == 'mountain_wanderer'),
              fate: c.fatePool.singleWhere((s) => s.id == 'balanced_seed'),
            ),
          ),
          isTrue,
        );
      });
      final records = <Map<String, Object?>>[];
      final held = <LogicalKeyboardKey>{};
      Future<void> keys(Set<LogicalKeyboardKey> desired) async {
        for (final key in held.difference(desired).toList()) {
          await tester.sendKeyUpEvent(key);
          held.remove(key);
        }
        for (final key in desired.difference(held).toList()) {
          await tester.sendKeyDownEvent(key);
          held.add(key);
        }
      }

      await tester.binding.setSurfaceSize(const Size(1280, 720));
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mathRandomProvider.overrideWithValue(Random(20260906)),
              rngProvider.overrideWithValue(DefaultRng(seed: 20260906)),
            ],
            child: const MaterialApp(home: StageListScreen(chapterIndex: 1)),
          ),
        );
        await waitFor(tester, find.text('山门之外'));
        await tester.tap(find.text('山门之外'));
        for (var index = 1; index <= 1; index++) {
          await waitFor(tester, find.byType(Phase0aBattleScreen));
          final host = tester.widget<Phase0aMainlineBattleHost>(
            find.byType(Phase0aMainlineBattleHost),
          );
          final screen = tester.widget<Phase0aBattleScreen>(
            find.byType(Phase0aBattleScreen),
          );
          final controller = screen.controller;
          expect(host.stage.id, 'stage_01_0$index');
          expect(host.controller, ActivityController.human);
          final initialHp = controller.state.player.maxHealth;
          final row = <String, Object?>{
            'stage': host.stage.id,
            'maxHp': initialHp,
            'characterId': host.playerSnapshot!.characterId,
            'weapon': host.playerSnapshot!.weaponArchetype?.name,
            'equipmentAttack': host.playerSnapshot!.totalEquipmentAttack,
            'skills': host.playerSnapshot!.availableSkills
                .map((s) => s.id)
                .toList(),
          };
          records.add(row);
          for (
            var tick = 0;
            tick < 2400 && controller.outcome == Phase0aBattleOutcome.ongoing;
            tick++
          ) {
            final p = controller.state.player.position;
            final enemies =
                controller.state.enemies.where((e) => e.isAlive).toList()..sort(
                  (a, b) => (a.position - p).lengthSquared.compareTo(
                    (b.position - p).lengthSquared,
                  ),
                );
            final desired = <LogicalKeyboardKey>{LogicalKeyboardKey.keyJ};
            if (enemies.isNotEmpty) {
              var d = enemies.first.position - p;
              final distance = d.length;
              const policy = 'kite';
              var move = distance > screen.basicAttackRange! * .85;
              if (policy == 'stationary') move = false;
              if (policy == 'kite') {
                final retreat =
                    distance < 130 &&
                    controller.state.player.attackCooldownRemaining > 0;
                if (retreat) d = d * -1;
                move = retreat || distance > screen.basicAttackRange! * .9;
                if (p.x.abs() > 570 || p.y.abs() > 220) {
                  d = p * -1;
                  move = true;
                }
              }
              if (move) {
                if (d.x.abs() > 10) {
                  desired.add(
                    d.x > 0 ? LogicalKeyboardKey.keyD : LogicalKeyboardKey.keyA,
                  );
                }
                if (d.y.abs() > 10) {
                  desired.add(
                    d.y > 0 ? LogicalKeyboardKey.keyS : LogicalKeyboardKey.keyW,
                  );
                }
              }
            } else if (controller
                    .checkpointObjectiveProgress
                    ?.remainingEnemies ==
                0) {
              desired.add(LogicalKeyboardKey.keyD);
            }
            await keys(desired);
            final close =
                enemies.isNotEmpty && (enemies.first.position - p).length < 180;
            if (close && tick % 10 == 0) {
              await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
            }
            if (close && tick % 10 == 5) {
              await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
            }
            if (close &&
                controller.state.player.defenseCooldownRemaining == 0) {
              await tester.sendKeyEvent(LogicalKeyboardKey.space);
            }
            await tester.pump(const Duration(milliseconds: 100));
          }
          await keys({});
          row.addAll({
            'outcome': controller.outcome.name,
            'ticks': controller.state.tick,
            'remainingHp': controller.state.player.currentHealth,
            'kills': controller.events.whereType<Phase0aEnemyDefeated>().length,
            'enemyAttacks': controller.events
                .whereType<Phase0aAttackStarted>()
                .where((e) => e.actor != controller.state.player.id)
                .length,
            'playerAttacks': controller.events
                .whereType<Phase0aAttackStarted>()
                .where((e) => e.actor == controller.state.player.id)
                .length,
          });

          if (controller.outcome != Phase0aBattleOutcome.victory) break;
          await waitFor(
            tester,
            find.text(
              index == 5
                  ? UiStrings.stageVictoryReturnToMap
                  : UiStrings.stageVictoryEnterNextStage,
            ),
          );
          await tester.tap(
            find.text(
              index == 5
                  ? UiStrings.stageVictoryReturnToMap
                  : UiStrings.stageVictoryEnterNextStage,
            ),
          );
          // Allow real Isar transaction futures and post-settlement UI to finish.
          for (var spin = 0; spin < 100; spin++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump(const Duration(milliseconds: 50));
            final active = find.byType(Phase0aMainlineBattleHost);
            if (active.evaluate().isNotEmpty &&
                tester.widget<Phase0aMainlineBattleHost>(active).stage.id !=
                    host.stage.id) {
              break;
            }
          }
        }
        await waitFor(tester, find.byType(Phase0aBattleScreen));
        final next = tester.widget<Phase0aMainlineBattleHost>(
          find.byType(Phase0aMainlineBattleHost),
        );
        expect(next.stage.id, 'stage_01_02');
        expect(next.playerSnapshot!.characterId, records.single['characterId']);
        await tester.runAsync(() async {
          final progress = await IsarSetup.instance.mainlineProgress
              .where()
              .findAll();
          expect(progress.single.clearedStageIds, ['stage_01_01']);
          final journals = await IsarSetup.instance.mainlineSettlementJournals
              .where()
              .findAll();
          final prepared = journals.singleWhere(
            (j) => j.phase == MainlineSettlementPhase.prepared,
          );
          expect(prepared.stageId, 'stage_01_02');
          expect(prepared.loadoutVersion, 2);
          expect(prepared.participantId, records.single['characterId']);
        });
      } finally {
        await keys({});
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(null);
      }
      expect(records.length, 1);
      expect(records.map((r) => r['outcome']), everyElement('victory'));
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
