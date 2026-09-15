import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_background_crowds.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';

import '../../../../support/test_data.dart';

void main() {
  late GameRepository repository;
  setUpAll(() async => repository = await loadTestGameRepository());

  Future<Phase0aBattleController> controllerFor(WidgetTester tester) async {
    final fixture = (await tester.runAsync(
      () => Phase0aDebugBattleFixture.load(
        assetLoader: loadTestAsset,
        numbers: repository.numbers,
      ),
    ))!;
    final controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  double phase(WidgetTester tester) => tester
      .widget<Phase0aBackgroundCrowds>(find.byType(Phase0aBackgroundCrowds))
      .phase
      .value;

  testWidgets('initially backgrounded screen keeps the crowd clock stopped', (
    tester,
  ) async {
    final controller = await controllerFor(tester);
    final original = controller.state;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Phase0aBattleScreen(
            controller: controller,
            autoStep: false,
            showBackgroundCrowds: true,
          ),
        ),
      );
      await tester.pump();
      final before = phase(tester);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(phase(tester), before);
      expect(controller.state, same(original));
      expect(controller.events, isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
  });

  testWidgets('resume without background frames does not replay crowd time', (
    tester,
  ) async {
    final controller = await controllerFor(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Phase0aBattleScreen(
          controller: controller,
          autoStep: false,
          showBackgroundCrowds: true,
        ),
      ),
    );
    try {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final before = phase(tester);
      expect(before, greaterThan(0));
      final original = controller.state;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      // No frames are delivered while the native application is suspended.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 11));
      expect(phase(tester), before);
      await tester.pump(const Duration(milliseconds: 100));
      expect(phase(tester), isNot(before));
      expect(controller.state, same(original));
      expect(controller.events, isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
  });

  for (final viewport in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('$viewport bounded ink ranks leave input and semantics clear', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final phase = ValueNotifier<double>(0);
      addTearDown(phase.dispose);
      final semantics = tester.ensureSemantics();
      var taps = 0;
      var camera = Offset.zero;
      var visible = true;
      late StateSetter update;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Semantics(
                      label: 'battle input',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => taps++,
                        child: const ColoredBox(color: Colors.white),
                      ),
                    ),
                    if (visible)
                      Phase0aBackgroundCrowds(
                        cameraOffset: camera,
                        phase: phase,
                      ),
                  ],
                );
              },
            ),
          ),
        );
        final finder = find.byKey(
          const ValueKey('phase0a_background_crowd_paint'),
        );
        final painter = tester.widget<CustomPaint>(finder).painter!;
        final calls = _record(painter, viewport);
        final heads = calls.where(
          (call) => call.invocation.memberName == #drawOval,
        );
        expect(heads, hasLength(Phase0aPresentationTokens.crowdFigureBudget));
        expect(_draws(calls), greaterThan(0));
        expect(_draws(calls), lessThanOrEqualTo(32 * 5));
        expect(
          calls.any((call) => call.invocation.memberName == #drawImageRect),
          isFalse,
        );
        final firstPixels = (await tester.runAsync(
          () => _pixels(painter, viewport),
        ))!;
        expect(firstPixels.any((byte) => byte != 0), isTrue);

        // A full-screen decorative paint layer must not eat real mouse input.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset(viewport.width * .2, 260));
        await mouse.down(Offset(viewport.width * .2, 260));
        await mouse.up();
        await mouse.removePointer();
        expect(taps, 1);
        expect(find.bySemanticsLabel('battle input'), findsOneWidget);

        phase.value = .25;
        await tester.pump();
        final animatedPixels = (await tester.runAsync(
          () => _pixels(painter, viewport),
        ))!;
        expect(listEquals(firstPixels, animatedPixels), isFalse);
        expect(_draws(_record(painter, viewport)), _draws(calls));
        update(() => camera = const Offset(140, -60));
        await tester.pump();
        final moved = tester.widget<CustomPaint>(finder).painter!;
        expect(moved.shouldRepaint(painter), isTrue);
        final movedPixels = (await tester.runAsync(
          () => _pixels(moved, viewport),
        ))!;
        expect(listEquals(animatedPixels, movedPixels), isFalse);
        expect(_draws(_record(moved, viewport)), _draws(calls));

        update(() => visible = false);
        await tester.pump();
        expect(finder, findsNothing);
        expect(find.bySemanticsLabel('battle input'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      '$viewport hidden paused and terminal screens stop crowd work',
      (tester) async {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixture = (await tester.runAsync(
          () => Phase0aDebugBattleFixture.load(
            assetLoader: loadTestAsset,
            numbers: repository.numbers,
          ),
        ))!;
        final controller = Phase0aBattleController(
          flow: fixture.flow,
          roster: fixture.roster,
          fixedDeltaSeconds: fixture.fixedDeltaSeconds,
        );
        addTearDown(controller.dispose);
        var visible = true;
        var tickerEnabled = true;
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return TickerMode(
                  enabled: tickerEnabled,
                  child: Phase0aBattleScreen(
                    controller: controller,
                    autoStep: false,
                    showBackgroundCrowds: visible,
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();
        final crowd = tester.widget<Phase0aBackgroundCrowds>(
          find.byType(Phase0aBackgroundCrowds),
        );
        var notifications = 0;
        void onPaint() => notifications++;
        crowd.phase.addListener(onPaint);
        try {
          await tester.pump(const Duration(milliseconds: 120));
          expect(notifications, 1);
          await tester.pump(const Duration(milliseconds: 10));
          expect(
            notifications,
            1,
          ); // Existing ticker, but no 60 Hz crowd paint.
          final original = controller.state;
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pump(const Duration(seconds: 1));
          final paused = notifications;
          await tester.pump(const Duration(seconds: 2));
          expect(notifications, paused);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 120));
          expect(notifications, greaterThan(paused));

          update(() => visible = false);
          await tester.pump();
          final hidden = notifications;
          await tester.pump(const Duration(seconds: 3));
          expect(find.byType(Phase0aBackgroundCrowds), findsNothing);
          expect(notifications, hidden);
          update(() => visible = true);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 120));
          await tester.pump(const Duration(milliseconds: 120));
          expect(notifications, greaterThan(hidden));

          update(() => tickerEnabled = false);
          await tester.pump();
          final muted = notifications;
          await tester.pump(const Duration(seconds: 2));
          expect(notifications, muted);
          update(() => tickerEnabled = true);
          await tester.pump();
          await tester.pump();
          expect(notifications, muted);
          await tester.pump(const Duration(milliseconds: 120));
          expect(notifications, greaterThan(muted));
          expect(controller.state, same(original));
          expect(controller.events, isEmpty);

          final bot = Phase0aPlayerBotAdapter(
            playerAdapter: fixture.playerAdapter,
          );
          for (
            var tick = 0;
            tick < 600 && controller.outcome == Phase0aBattleOutcome.ongoing;
            tick++
          ) {
            controller.step(bot.commandFor(controller.state));
          }
          expect(controller.outcome, Phase0aBattleOutcome.victory);
          final terminal = notifications;
          await tester.pump(const Duration(seconds: 2));
          expect(notifications, terminal);
          expect(tester.takeException(), isNull);
        } finally {
          crowd.phase.removeListener(onPaint);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }
}

List<RecordedInvocation> _record(CustomPainter painter, Size viewport) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, viewport);
  return canvas.invocations;
}

int _draws(List<RecordedInvocation> calls) => calls
    .where(
      (call) =>
          call.invocation.memberName.toString().startsWith('Symbol("draw'),
    )
    .length;

Future<List<int>> _pixels(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List().toList(growable: false);
  } finally {
    image.dispose();
    picture.dispose();
  }
}
