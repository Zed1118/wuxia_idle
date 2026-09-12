import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';
import 'package:wuxia_idle/features/debug/presentation/visual_route_host.dart';

import '../../support/test_data.dart';

// This battle route never reads Isar. Any accidental database access fails.
class _UnusedIsar extends Fake implements Isar {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Widget target;
  late Phase0aDebugBattleFixture fixture;

  setUp(() async {
    await loadTestGameRepository();
    fixture = await Phase0aDebugBattleFixture.loadM4Density(
      assetLoader: loadTestAsset,
      numbers: GameRepository.instance.numbers,
    );
    target = await buildVisualTarget(
      VisualRoute.phase0aM4DensityProfile,
      _UnusedIsar(),
    );
  });
  tearDown(GameRepository.resetForTest);

  testWidgets(
    'real M4 profile restart resets old presentation before advancing and disposes both controllers',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home: target));
      await tester.pump();
      final screen = find.byType(Phase0aBattleScreen);
      final original = tester.widget<Phase0aBattleScreen>(screen).controller;
      const cameraKey = ValueKey('phase0a_background_parallax_translation');
      List<double> cameraTransform() => tester
          .widget<Transform>(find.byKey(cameraKey))
          .transform
          .storage
          .toList();
      final initialCamera = cameraTransform();
      final initialPosition = original.state.player.position;
      expect(original.state.enemies, hasLength(24));

      for (var tick = 0; tick < 8; tick++) {
        original.step(const Phase0aPlayerCommand(down: true));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(original.state.player.position, isNot(initialPosition));
      expect(cameraTransform(), isNot(initialCamera));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.tap(find.byKey(const ValueKey('phase0a_seal_gather')));
      await tester.pump();
      expect(
        tester
            .widget<MouseRegion>(
              find.byKey(const ValueKey('phase0a_stage_mouse_region')),
            )
            .cursor,
        SystemMouseCursors.precise,
      );

      // Use the production bot and reducer to reach a real terminal state.
      final bot = Phase0aPlayerBotAdapter(playerAdapter: fixture.playerAdapter);
      for (
        var tick = 0;
        tick < 2000 && original.outcome == Phase0aBattleOutcome.ongoing;
        tick++
      ) {
        original.step(bot.commandFor(original.state));
      }
      expect(original.outcome, isNot(Phase0aBattleOutcome.ongoing));
      await tester.pump();
      expect(find.byKey(const ValueKey('phase0a_defeat_ink')), findsWidgets);

      // Multiple due timer callbacks may run before this frame. They must not
      // advance the replacement controller until didUpdateWidget has cleared it.
      await tester.pump(const Duration(milliseconds: 250));
      final replacement = tester.widget<Phase0aBattleScreen>(screen).controller;
      expect(replacement, isNot(same(original)));
      expect(replacement.state.tick, fixture.flow.state.tick);
      expect(replacement.state.player.position, initialPosition);
      expect(replacement.state.enemies, hasLength(24));
      expect(replacement.fixedDeltaSeconds, fixture.fixedDeltaSeconds);
      expect(find.byKey(const ValueKey('phase0a_defeat_ink')), findsNothing);
      expect(find.byKey(const ValueKey('phase0a_gather_vortex')), findsNothing);
      expect(
        find.byKey(const ValueKey('phase0a_hit_flash_player')),
        findsNothing,
      );
      expect(cameraTransform(), initialCamera);
      expect(
        tester
            .widget<MouseRegion>(
              find.byKey(const ValueKey('phase0a_stage_mouse_region')),
            )
            .cursor,
        SystemMouseCursors.basic,
      );
      expect(() => original.addListener(() {}), throwsFlutterError);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.pump(const Duration(milliseconds: 100));
      expect(replacement.state.tick, greaterThan(fixture.flow.state.tick));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(() => replacement.addListener(() {}), throwsFlutterError);
      expect(tester.takeException(), isNull);
    },
  );
}
