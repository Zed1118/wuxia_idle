import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_skill_seals.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_stage.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import '../../../../support/test_data.dart';
import 'phase0a_terminal_test_driver.dart';

/// Phase 0A Batch 9C 键盘焦点/导航红测(plan §验收):
/// - 技能印与再战按钮「有键盘焦点 → 必须画出金边环」(沿用 PlaqueButton
///   体例,见 plaque_button_focus_ring_test);
/// - 整屏 Tab 环游:战斗中 screen → gather → clear → screen,终局跳过
///   禁用印直达再战按钮;
/// - 焦点停在技能印上时战斗键(W/Q/R)仍冒泡到屏幕 handler;
/// - 技能印 Semantics label = 印字 + 键位 + 状态行(读屏可辨)。
void main() {
  const gatherSealKey = ValueKey('phase0a_seal_gather');
  const clearSealKey = ValueKey('phase0a_seal_clear');
  const retryButtonKey = ValueKey('phase0a_retry_button');

  /// 金边环断言:体例同 plaque_button_focus_ring_test(桌面键盘落点可见锁)。
  Finder goldRing() => find.byWidgetPredicate((w) {
    if (w is! DecoratedBox) return false;
    final d = w.decoration;
    if (d is! BoxDecoration) return false;
    final b = d.border;
    return b is Border &&
        b.top.color == WuxiaUi.gold &&
        b.top.width == Phase0aPresentationTokens.focusRingWidth;
  });

  Finder ringInside(Finder host) =>
      find.descendant(of: host, matching: goldRing());

  setUp(() {
    // 桌面键盘导航语境:钉死「传统高亮」,否则 onShowFocusHighlight
    // 即使拿到焦点也不会回调 true(plaque_button_focus_ring_test 同体例)。
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  group('技能印焦点环与 Semantics label', () {
    Phase0aSkillSlot slot(
      String name, {
      double cooldownRemaining = 0,
      int qiCost = 5,
      Phase0aSkillAvailability availability = Phase0aSkillAvailability.ready,
    }) => Phase0aSkillSlot(
      slot: name,
      cooldownRemaining: cooldownRemaining,
      qiCost: qiCost,
      availability: availability,
    );

    Widget harness({
      Phase0aSkillSlot? gather,
      Phase0aSkillSlot? clear,
      int qiCurrent = 10,
    }) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: Phase0aSkillSeals(
            gatherSlot: gather ?? slot('gather'),
            clearSlot: clear ?? slot('clear'),
            qiCurrent: qiCurrent,
            onGather: () {},
            onClear: () {},
          ),
        ),
      ),
    );

    testWidgets('无焦点时不画金边环', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(goldRing(), findsNothing);
    });

    testWidgets('Tab 到达 ready 印 → 金边环出现,随焦点移动,失焦撤掉', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringInside(find.byKey(gatherSealKey)), findsOneWidget);
      expect(ringInside(find.byKey(clearSealKey)), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringInside(find.byKey(gatherSealKey)), findsNothing);
      expect(ringInside(find.byKey(clearSealKey)), findsOneWidget);

      FocusManager.instance.primaryFocus?.unfocus();
      // 焦点回调走帧后派发,pumpAndSettle 才能吃干净(体例同
      // plaque_button_focus_ring_test 的失焦断言)。
      await tester.pumpAndSettle();
      expect(goldRing(), findsNothing);
    });

    testWidgets('Semantics label = 印字 + 键位 + 状态行', (tester) async {
      await tester.pumpWidget(
        harness(
          gather: slot('gather'),
          clear: slot(
            'clear',
            cooldownRemaining: 4.5,
            availability: Phase0aSkillAvailability.cooldown,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byKey(gatherSealKey)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label:
              '${UiStrings.phase0aSealGatherGlyph} '
              '${UiStrings.phase0aSealGatherKey} '
              '${UiStrings.skillReady}',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(clearSealKey)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label:
              '${UiStrings.phase0aSealClearGlyph} '
              '${UiStrings.phase0aSealClearKey} '
              '${UiStrings.phase0aSealCooldown(4.5)}',
        ),
      );
    });
  });

  group('整屏 Tab 环游与战斗键冒泡', () {
    late Phase0aDebugBattleFixture fixture;
    late Phase0aBattleController controller;

    setUp(() async {
      await loadTestGameRepository();
      fixture = await Phase0aDebugBattleFixture.load(
        assetLoader: loadTestAsset,
        numbers: GameRepository.instance.numbers,
      );
      controller = Phase0aBattleController(
        flow: fixture.flow,
        roster: fixture.roster,
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );
    });

    tearDown(GameRepository.resetForTest);

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Phase0aBattleScreen(
            controller: controller,
            // 终局两例需要再战入口;进行中用例不受影响。
            retryFlowBuilder: () async => (await Phase0aDebugBattleFixture.load(
              assetLoader: loadTestAsset,
              numbers: GameRepository.instance.numbers,
            )).flow,
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> driveToEndPumped(WidgetTester tester) async {
      for (var i = 0; i < 2000; i++) {
        if (controller.outcome != Phase0aBattleOutcome.ongoing) break;
        controller.step(phase0aVictoryTerminalCommand(controller));
        await tester.pump();
      }
      expect(controller.outcome, Phase0aBattleOutcome.victory);
    }

    testWidgets('战斗中 Tab 环游 screen → gather → clear → screen', (tester) async {
      await pumpScreen(tester);
      // autofocus 在屏幕根 Focus,无金边环(纯容器焦点)。
      expect(goldRing(), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringInside(find.byKey(gatherSealKey)), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringInside(find.byKey(clearSealKey)), findsOneWidget);

      // 回到屏幕根 Focus,环游闭合。
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(goldRing(), findsNothing);
    });

    testWidgets('焦点停在技能印上,W 仍冒泡驱动移动', (tester) async {
      await pumpScreen(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringInside(find.byKey(gatherSealKey)), findsOneWidget);

      final beforeY = controller.state.player.position.y;
      await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
      controller.step();
      await tester.pump();
      await tester.pump(
        Duration(
          microseconds:
              (controller.fixedDeltaSeconds * Duration.microsecondsPerSecond)
                  .round(),
        ),
      );
      expect(
        beforeY - controller.state.player.position.y,
        greaterThan(0),
        reason: '焦点在印上时 W 必须冒泡到屏幕 handler 并推进领域上移',
      );
    });

    testWidgets('焦点停在技能印上,Q/R 仍冒泡真实驱动技能', (tester) async {
      await pumpScreen(tester);

      // 焦点先到 gather 印,再按 Q。
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringInside(find.byKey(gatherSealKey)), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      final stage = Phase0aStage(viewport: const Size(1280, 720));
      stage.updateCameraCenter(controller.state.player.position);
      await tester.tapAt(stage.worldToScreen(const ArenaVector(80, 0)));
      final gatherEvents = controller.step();
      await tester.pump();
      expect(
        gatherEvents.whereType<Phase0aGatherStarted>(),
        hasLength(1),
        reason: '焦点在 gather 印上按 Q 必须冒泡驱动聚怪',
      );

      // Tab 推进到 clear 印(gather 已冷却被跳过),再按 R。
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringInside(find.byKey(clearSealKey)), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      final clearEvents = controller.step();
      await tester.pump();
      expect(
        clearEvents.whereType<Phase0aClearStarted>(),
        hasLength(1),
        reason: '焦点在 clear 印上按 R 必须冒泡驱动清场',
      );
    });

    testWidgets('终局 Tab 跳过禁用印直达再战按钮,金边环可见', (tester) async {
      await pumpScreen(tester);
      await driveToEndPumped(tester);
      expect(find.byKey(retryButtonKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        ringInside(find.byKey(retryButtonKey)),
        findsOneWidget,
        reason: '终局首个 Tab 必须落在再战按钮且落点可见',
      );
      expect(ringInside(find.byKey(gatherSealKey)), findsNothing);
      expect(ringInside(find.byKey(clearSealKey)), findsNothing);
    });

    testWidgets('焦点在再战按钮上 Enter 触发再战', (tester) async {
      await pumpScreen(tester);
      await driveToEndPumped(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringInside(find.byKey(retryButtonKey)), findsOneWidget);

      await tester.runAsync(() async {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump();

      expect(controller.outcome, Phase0aBattleOutcome.ongoing);
      expect(find.byKey(retryButtonKey), findsNothing);
    });
  });
}
