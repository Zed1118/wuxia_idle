import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../../support/test_data.dart';

void main() {
  late Phase0aDebugBattleFixture fixture;
  late Phase0aBattleController controller;

  setUp(() async {
    await loadTestGameRepository();
    fixture = await Phase0aDebugBattleFixture.load(
      assetLoader: loadTestAsset,
      numbers: GameRepository.instance.numbers,
      assetPath: 'data/phase0a_debug_guardian_mechanics.yaml',
    );
    controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
  });

  tearDown(GameRepository.resetForTest);

  testWidgets(
    'guardian fixture renders a non-3v3 Phase0A ward and both VFX states',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Phase0aBattleScreen(
            controller: controller,
            autoStep: false,
            feedbackHoldSeconds: 5,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('phase0a_battle_screen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('phase0a_guardian_ward_ring')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.guardianWardActiveLabel), findsOneWidget);
      expect(
        find.text(UiStrings.surviveConditionRemaining(80, 80)),
        findsOneWidget,
      );

      var breakSent = false;
      var sawIntercept = false;
      var sawCoop = false;
      for (var i = 0; i < 80; i++) {
        final charging = controller.state.enemies.first.chargingCast != null;
        final events = controller.step(
          !breakSent && charging
              ? const Phase0aPlayerCommand(clear: true)
              : null,
        );
        if (charging) breakSent = true;
        await tester.pump();
        sawIntercept =
            sawIntercept ||
            events.whereType<Phase0aGuardIntercepted>().isNotEmpty;
        sawCoop =
            sawCoop || events.whereType<Phase0aGuardianCoopStrike>().isNotEmpty;
        if (events.whereType<Phase0aGuardIntercepted>().isNotEmpty) {
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget.key is ValueKey &&
                  (widget.key! as ValueKey).value.toString().startsWith(
                    'phase0a_guard_intercept_',
                  ),
            ),
            findsOneWidget,
          );
        }
        if (sawIntercept && sawCoop) break;
      }
      expect(sawIntercept, isTrue);
      expect(sawCoop, isTrue);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey &&
              (widget.key! as ValueKey).value.toString().startsWith(
                'phase0a_guardian_coop_',
              ),
        ),
        findsOneWidget,
      );
    },
  );
}
