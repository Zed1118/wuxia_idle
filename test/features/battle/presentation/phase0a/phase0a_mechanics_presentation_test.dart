import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../../support/test_data.dart';

void main() {
  const viewports = [Size(1280, 720), Size(1440, 900)];

  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  testWidgets(
    'guardian fixture renders a non-3v3 Phase0A ward and both VFX states',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => Phase0aDebugBattleFixture.load(
          assetLoader: loadTestAsset,
          numbers: GameRepository.instance.numbers,
          assetPath: 'data/phase0a_debug_guardian_mechanics.yaml',
        ),
      ))!;
      final controller = Phase0aBattleController(
        flow: fixture.flow,
        roster: fixture.roster,
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );
      addTearDown(controller.dispose);
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
      final guardianLabelLanes = tester.widgetList<Transform>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Transform &&
              widget.key is ValueKey &&
              (widget.key! as ValueKey).value.toString().startsWith(
                'phase0a_guardian_label_lane_',
              ),
        ),
      );
      expect(guardianLabelLanes, hasLength(2));
      final laneOffsets = guardianLabelLanes
          .map((lane) => lane.transform.getTranslation().x)
          .toList();
      expect(laneOffsets.toSet(), {
        -Phase0aPresentationTokens.guardianLabelLaneOffset,
        Phase0aPresentationTokens.guardianLabelLaneOffset,
      });

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

  for (final viewport in viewports) {
    testWidgets('boss feedback chain stays readable at '
        '${viewport.width.toInt()}x${viewport.height.toInt()}', (tester) async {
      final bossFixture = (await tester.runAsync(
        () => Phase0aDebugBattleFixture.load(
          assetLoader: loadTestAsset,
          numbers: GameRepository.instance.numbers,
          assetPath: 'data/phase0a_debug_boss_battle.yaml',
        ),
      ))!;
      final bossController = Phase0aBattleController(
        flow: bossFixture.flow,
        roster: bossFixture.roster,
        fixedDeltaSeconds: bossFixture.fixedDeltaSeconds,
      );
      addTearDown(bossController.dispose);

      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Phase0aBattleScreen(
            controller: bossController,
            autoStep: false,
            feedbackHoldSeconds: 5,
          ),
        ),
      );
      await tester.pump();

      const bossId = 'wave2_elite';
      expect(
        find.byKey(const ValueKey('phase0a_vulnerability_guarded_$bossId')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.phase0aVulnerabilityGuarded), findsOneWidget);

      var chargeStarted = false;
      for (var i = 0; i < 80 && !chargeStarted; i++) {
        final events = bossController.step();
        chargeStarted = events.whereType<Phase0aBossChargeStarted>().isNotEmpty;
        await tester.pump();
      }
      expect(chargeStarted, isTrue);
      expect(
        find.byKey(const ValueKey('phase0a_boss_charge_banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('phase0a_charge_warning_$bossId')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('phase0a_vulnerability_open_$bossId')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.phase0aVulnerabilityOpen), findsOneWidget);

      final interruptEvents = bossController.step(
        const Phase0aPlayerCommand(clear: true),
      );
      await tester.pump();
      expect(
        interruptEvents.whereType<Phase0aBossChargeInterrupted>(),
        hasLength(1),
      );
      expect(
        find.byKey(const ValueKey('phase0a_boss_interrupt_banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('phase0a_staggered_$bossId')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('phase0a_vulnerability_open_$bossId')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.phase0aBossChargeInterrupted), findsOneWidget);
      expect(find.text(UiStrings.phase0aStaggered), findsNothing);
      expect(find.textContaining(UiStrings.phase0aStaggered), findsOneWidget);
    });
  }
}
