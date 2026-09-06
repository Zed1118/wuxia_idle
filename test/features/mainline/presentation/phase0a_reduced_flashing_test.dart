import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/mainline/presentation/phase0a_mainline_battle_host.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_provider.dart';
import 'package:wuxia_idle/features/settings/application/gameplay_settings_service.dart';
import 'package:wuxia_idle/features/settings/domain/gameplay_settings.dart';

import '../../../support/combatant_snapshot_fixture.dart';
import '../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  setUpAll(() async => repository = await loadTestGameRepository());
  for (final viewport in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets(
      '$viewport stored reduced flashing affects real Boss hit only visually',
      (tester) async {
        final hitStates = <String>[];
        for (final reduced in [false, true]) {
          SharedPreferences.setMockInitialValues({});
          final settings = GameplaySettingsService();
          await settings.save(GameplaySettings(reduceFlashing: reduced));
          final container = ProviderContainer();
          addTearDown(container.dispose);
          await container.read(gameplaySettingsProvider.future);
          await tester.binding.setSurfaceSize(viewport);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                home: Phase0aMainlineBattleHost(
                  stage: repository.getStage('stage_01_04'),
                  seedForTest: 20260905,
                  playerSnapshotForTest: testCombatantSnapshot(
                    maxHp: 20000,
                    currentHp: 20000,
                    includeProductionBasicAttack: true,
                  ),
                  onVictory: (_) {},
                  onDefeat: (_) {},
                ),
              ),
            ),
          );
          for (
            var i = 0;
            i < 50 && find.byType(Phase0aBattleScreen).evaluate().isEmpty;
            i++
          ) {
            await tester.pump(const Duration(milliseconds: 10));
          }
          final controller = tester
              .widget<Phase0aBattleScreen>(find.byType(Phase0aBattleScreen))
              .controller;
          final initialHp = controller.state.player.currentHealth;
          for (
            var i = 0;
            i < 100 && controller.state.player.currentHealth == initialHp;
            i++
          ) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(controller.state.player.currentHealth, lessThan(initialHp));
          final stateAtHit = controller.state;
          hitStates.add(
            '${stateAtHit.tick}:${stateAtHit.player.currentHealth}:${stateAtHit.player.position}',
          );
          final flash = find.byKey(
            ValueKey('phase0a_hit_flash_${stateAtHit.player.id}'),
          );
          expect(flash, reduced ? findsNothing : findsOneWidget);
          expect(
            find.byKey(ValueKey('phase0a_hp_emphasis_${stateAtHit.player.id}')),
            findsOneWidget,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          if (!reduced) {
            await settings.save(const GameplaySettings(reduceFlashing: true));
            container.invalidate(gameplaySettingsProvider);
            await container.read(gameplaySettingsProvider.future);
            await tester.pump();
            expect(
              flash,
              findsNothing,
              reason: 'Changing the setting must also suppress an active flash',
            );
            expect(controller.state, same(stateAtHit));
          } else {
            expect(
              hitStates.last,
              hitStates.first,
              reason:
                  'The visual preference must not change simulation or damage',
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }
}
