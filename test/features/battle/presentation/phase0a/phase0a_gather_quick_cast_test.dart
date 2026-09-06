import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_stage.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';

import '../../../../support/test_data.dart';

void main() {
  late Phase0aDebugBattleFixture fixture;
  late Phase0aBattleController controller;

  setUp(() async {
    final repository = await loadTestGameRepository();
    fixture = await Phase0aDebugBattleFixture.load(
      assetLoader: loadTestAsset,
      numbers: repository.numbers,
    );
    controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
  });

  tearDown(() {
    controller.dispose();
    GameRepository.resetForTest();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size viewport = const Size(1280, 720),
    bool autoStep = false,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Padding(
          padding: padding,
          child: Phase0aBattleScreen(
            controller: controller,
            autoStep: autoStep,
            basicAttackRange: fixture.playerAdapter.attackRange,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<TestGesture> hoverAt(WidgetTester tester, Offset position) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: position);
    addTearDown(mouse.removePointer);
    await tester.pump();
    return mouse;
  }

  for (final viewport in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets(
      'Q casts at key-down pointer position without a click: $viewport',
      (tester) async {
        await pumpScreen(tester, viewport: viewport);
        final stage = Phase0aStage(
          viewport: viewport,
          cameraCenter: controller.state.player.position,
        );
        final playerBefore = controller.state.player.position;
        const target = ArenaVector(-560, 0);
        final mouse = await hoverAt(tester, stage.worldToScreen(target));

        await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
        // Moving after the key must not move an already requested cast.
        await mouse.moveTo(stage.worldToScreen(const ArenaVector(-440, 80)));
        await tester.pump();
        final events = controller.step();
        await tester.pump();
        expect(events.whereType<Phase0aGatherStarted>(), hasLength(1));
        expect(
          events.whereType<Phase0aGatherStarted>().single.centerPosition,
          target,
        );
        expect(controller.state.player.position, playerBefore);
        expect(
          tester
              .widget<MouseRegion>(
                find.byKey(const ValueKey('phase0a_stage_mouse_region')),
              )
              .cursor,
          SystemMouseCursors.basic,
        );

        // A cooldown key press must neither re-arm targeting nor queue a cast.
        await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
        expect(controller.step().whereType<Phase0aGatherStarted>(), isEmpty);
        await tester.pump();
        expect(
          tester
              .widget<MouseRegion>(
                find.byKey(const ValueKey('phase0a_stage_mouse_region')),
              )
              .cursor,
          SystemMouseCursors.basic,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('held Q consumes repeat without recasting after cooldown', (
    tester,
  ) async {
    await pumpScreen(tester);
    final mouse = await hoverAt(tester, const Offset(500, 350));
    expect(
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyQ, platform: 'macos'),
      isTrue,
    );
    expect(controller.step().whereType<Phase0aGatherStarted>(), hasLength(1));
    for (var tick = 0; tick < 60; tick++) {
      controller.step();
    }
    expect(
      controller.state.skillSlots
          .singleWhere((slot) => slot.slot == 'gather')
          .availability,
      Phase0aSkillAvailability.ready,
    );
    await mouse.moveTo(const Offset(800, 400));
    expect(
      await tester.sendKeyRepeatEvent(
        LogicalKeyboardKey.keyQ,
        platform: 'macos',
      ),
      isTrue,
    );
    expect(controller.step().whereType<Phase0aGatherStarted>(), isEmpty);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyQ, platform: 'macos');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    expect(controller.step().whereType<Phase0aGatherStarted>(), hasLength(1));
    expect(controller.events.whereType<Phase0aGatherStarted>(), hasLength(2));
  });

  for (final interruption in ['pause', 'focus loss', 'inactive application']) {
    testWidgets('$interruption rejects Q without a delayed cast after resume', (
      tester,
    ) async {
      await pumpScreen(tester);
      await hoverAt(tester, const Offset(500, 350));
      final battleFocus = tester.widget<Focus>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Focus &&
              widget.focusNode?.debugLabel == 'phase0a-battle-input',
        ),
      );
      switch (interruption) {
        case 'pause':
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        case 'focus loss':
          FocusManager.instance.primaryFocus?.unfocus();
        case 'inactive application':
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
      }
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      expect(controller.step().whereType<Phase0aGatherStarted>(), isEmpty);
      switch (interruption) {
        case 'pause':
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        case 'focus loss':
          battleFocus.focusNode!.requestFocus();
        case 'inactive application':
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
      }
      await tester.pump();
      expect(controller.step().whereType<Phase0aGatherStarted>(), isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      expect(controller.step().whereType<Phase0aGatherStarted>(), hasLength(1));
    });
  }

  testWidgets('Q preserves held movement before and after its cast', (
    tester,
  ) async {
    await pumpScreen(tester, autoStep: true);
    await hoverAt(tester, const Offset(500, 350));
    final initialX = controller.state.player.position.x;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
    await tester.pump(const Duration(milliseconds: 220));
    final beforeCastX = controller.state.player.position.x;
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pump(const Duration(milliseconds: 220));
    final castX = controller.state.player.position.x;
    await tester.pump(const Duration(milliseconds: 220));
    expect(beforeCastX, greaterThan(initialX));
    expect(castX, greaterThan(beforeCastX));
    expect(controller.state.player.position.x, greaterThan(castX));
    expect(controller.events.whereType<Phase0aGatherStarted>(), hasLength(1));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    final releasedX = controller.state.player.position.x;
    await tester.pump(const Duration(milliseconds: 220));
    expect(controller.state.player.position.x, releasedX);
  });

  testWidgets('stationary pointer uses the current camera and stage origin', (
    tester,
  ) async {
    const viewport = Size(1280, 720);
    const padding = EdgeInsets.fromLTRB(60, 35, 40, 25);
    const stageSize = Size(1180, 660);
    const localPointer = Offset(620, 350);
    await pumpScreen(tester, viewport: viewport, padding: padding);
    final oldStage = Phase0aStage(
      viewport: stageSize,
      cameraCenter: controller.state.player.position,
    );
    await hoverAt(tester, localPointer + const Offset(60, 35));
    // Move the camera beneath a stationary mouse. No pointer event is sent
    // after the camera moves, so retaining the last world point would fail.
    for (var tick = 0; tick < 20; tick++) {
      controller.step(const Phase0aPlayerCommand(right: true));
      await tester.pump(const Duration(milliseconds: 120));
    }
    final stage = Phase0aStage(
      viewport: stageSize,
      cameraCenter: ArenaVector(
        controller.state.player.position.x -
            Phase0aPresentationTokens.cameraDeadZoneHalfWidth,
        controller.state.player.position.y,
      ),
    );
    final expected = stage.screenToWorld(localPointer);
    expect(
      (expected - oldStage.screenToWorld(localPointer)).lengthSquared,
      greaterThan(100),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    final actual = controller
        .step()
        .whereType<Phase0aGatherStarted>()
        .single
        .centerPosition!;
    expect(actual.x, closeTo(expected.x, 1e-9));
    expect(actual.y, closeTo(expected.y, 1e-9));
  });
}
