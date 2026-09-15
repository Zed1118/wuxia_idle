import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/posture.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import 'package:wuxia_idle/features/debug/presentation/phase0a_boss_mechanics_route_driver.dart';
import 'package:wuxia_idle/features/debug/presentation/visual_route_host.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../../support/test_data.dart';

void main() {
  const viewports = [Size(1280, 720), Size(1440, 900)];

  setUpAll(() async {
    final font = Platform.environment['WUXIA_STANDEE_VISUAL_FONT'];
    if (font == null) return;
    final bytes = ByteData.sublistView(await File(font).readAsBytes());
    for (final family in ['Roboto', 'Ahem', 'sans-serif']) {
      await (FontLoader(family)..addFont(Future.value(bytes))).load();
    }
  });

  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  Future<void> expectPainterDrawsPixels(
    WidgetTester tester,
    Finder paintFinder, {
    required String label,
  }) async {
    expect(
      paintFinder,
      findsOneWidget,
      reason: '$label 必须进入真实 CustomPaint 渲染分支',
    );
    final size = tester.getSize(paintFinder);
    expect(size.width, greaterThan(0), reason: '$label 画布宽度必须非零');
    expect(size.height, greaterThan(0), reason: '$label 画布高度必须非零');

    final painter = tester.widget<CustomPaint>(paintFinder).painter;
    expect(painter, isNotNull, reason: '$label 必须携带生产 painter');
    final recorder = ui.PictureRecorder();
    painter!.paint(ui.Canvas(recorder), size);
    final picture = recorder.endRecording();
    final bytes = await tester.runAsync(() async {
      final image = await picture.toImage(
        size.width.ceil(),
        size.height.ceil(),
      );
      picture.dispose();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data;
    });
    expect(bytes, isNotNull, reason: '$label 必须可编码为 raw RGBA');

    var paintedPixels = 0;
    for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4) {
      if (bytes.getUint8(offset) != 0) paintedPixels++;
    }
    expect(paintedPixels, greaterThan(0), reason: '$label painter 不得退化为空画布');
  }

  for (final viewport in viewports) {
    testWidgets(
      'guardian fixture renders a non-3v3 Phase0A ward and both VFX states $viewport',
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
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final capture = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            // Provide normal Material text inheritance for this isolated screen.
            builder: (context, child) => Material(child: child),
            home: RepaintBoundary(
              key: capture,
              child: Phase0aBattleScreen(
                controller: controller,
                autoStep: false,
                feedbackHoldSeconds: 5,
              ),
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
        await expectPainterDrawsPixels(
          tester,
          find.byKey(const ValueKey('phase0a_guardian_ward_ring')),
          label: '守护阵环',
        );
        expect(find.text(UiStrings.guardianWardActiveLabel), findsOneWidget);
        expect(
          find.text(UiStrings.surviveConditionRemaining(80, 80)),
          findsOneWidget,
        );
        final actorBodies = <Rect>[];
        for (final actor in [
          controller.state.player,
          ...controller.state.enemies,
        ]) {
          final image = find.descendant(
            of: find.byKey(ValueKey('phase0a_actor_visual_${actor.id}')),
            matching: find.byType(Image),
          );
          expect(image, findsOneWidget);
          final box = tester.renderObject<RenderBox>(image);
          actorBodies.add(
            MatrixUtils.transformRect(
              box.getTransformTo(null),
              Offset.zero & box.size,
            ),
          );
        }
        final informationRects = <Rect>[];
        for (final actor in controller.state.enemies) {
          final information = find.byKey(
            ValueKey('phase0a_actor_info_${actor.id}'),
          );
          expect(information, findsOneWidget);
          expect(
            find.descendant(
              of: information,
              matching: find.text(controller.roster.nameOf(actor.id)),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: information,
              matching: find.byKey(ValueKey('phase0a_hp_${actor.id}')),
            ),
            findsOneWidget,
          );
          if (actor.guardianDefIds.isNotEmpty) {
            expect(
              find.descendant(
                of: information,
                matching: find.text(UiStrings.guardianWardActiveLabel),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: information,
                matching: find.byKey(
                  ValueKey('phase0a_vulnerability_guarded_${actor.id}'),
                ),
              ),
              findsOneWidget,
            );
          }
          final rect = tester.getRect(information);
          // All three enemies stand to the right of the player, with a free
          // information lane there. Their labels must not cross the player.
          expect(
            rect.left,
            greaterThan(actorBodies.first.right),
            reason: 'enemy information must stay beside its own group',
          );
          for (final body in actorBodies) {
            expect(
              rect.overlaps(body),
              isFalse,
              reason: '${actor.id} information must not cover an actual Image',
            );
          }
          for (final other in informationRects) {
            expect(
              rect.overlaps(other),
              isFalse,
              reason: 'guardian and boss information must remain separate',
            );
          }
          informationRects.add(rect);
        }
        expect(informationRects, hasLength(3));
        await _captureMechanics(
          tester,
          capture,
          'guardian-ward-${viewport.width.toInt()}x${viewport.height.toInt()}',
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
              sawCoop ||
              events.whereType<Phase0aGuardianCoopStrike>().isNotEmpty;
          if (events.whereType<Phase0aGuardIntercepted>().isNotEmpty) {
            final interceptFinder = find.byWidgetPredicate(
              (widget) =>
                  widget.key is ValueKey &&
                  (widget.key! as ValueKey).value.toString().startsWith(
                    'phase0a_guard_intercept_',
                  ),
            );
            expect(interceptFinder, findsOneWidget);
            await expectPainterDrawsPixels(
              tester,
              find.descendant(
                of: interceptFinder,
                matching: find.byType(CustomPaint),
              ),
              label: '守护截击轨迹',
            );
          }
          if (sawIntercept && sawCoop) break;
        }
        expect(sawIntercept, isTrue);
        expect(sawCoop, isTrue);
        final coopFinder = find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey &&
              (widget.key! as ValueKey).value.toString().startsWith(
                'phase0a_guardian_coop_',
              ),
        );
        expect(coopFinder, findsOneWidget);
        await expectPainterDrawsPixels(
          tester,
          find.descendant(of: coopFinder, matching: find.byType(CustomPaint)),
          label: '守护协击轨迹',
        );
      },
    );
  }

  test(
    'boss visual route reaches and freezes unified posture vulnerability',
    () async {
      final fixture = await Phase0aDebugBattleFixture.load(
        assetLoader: loadTestAsset,
        numbers: GameRepository.instance.numbers,
        assetPath: 'data/phase0a_debug_boss_battle.yaml',
      );
      final controller = Phase0aBattleController(
        flow: fixture.flow,
        roster: fixture.roster,
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );
      addTearDown(controller.dispose);
      final driver = Phase0aBossMechanicsRouteDriver(
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );

      for (var tick = 0; tick < 1000 && !driver.completed; tick++) {
        driver.advance(controller);
      }

      expect(driver.completed, isTrue);
      expect(controller.outcome, Phase0aBattleOutcome.ongoing);
      expect(controller.state.enemies.single.posture!.isVulnerable, isTrue);
      expect(
        controller.events.whereType<Phase0aPostureChanged>().any(
          (event) => event.eventType == PostureEventType.vulnerabilityEntered,
        ),
        isTrue,
      );
      final frozenState = controller.state;
      driver.advance(controller);
      expect(controller.state, same(frozenState));
    },
  );

  testWidgets('boss visual route emits READY only after vulnerability', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => Phase0aDebugBattleFixture.load(
        assetLoader: loadTestAsset,
        numbers: GameRepository.instance.numbers,
        assetPath: 'data/phase0a_debug_boss_battle.yaml',
      ),
    ))!;
    final controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
    addTearDown(controller.dispose);
    final summaries = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        // Provide normal Material text inheritance for this isolated screen.
        builder: (context, child) => Material(child: child),
        home: Phase0aBossMechanicsPreview(
          controller: controller,
          fixedDeltaSeconds: fixture.fixedDeltaSeconds,
          seed: fixture.seed,
          onReady: summaries.add,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 12));
    expect(summaries, isEmpty);

    await tester.pump(const Duration(seconds: 24));
    expect(summaries, hasLength(1));
    expect(
      summaries.single,
      allOf(
        startsWith('seed=${fixture.seed} tick='),
        endsWith('state=posture_vulnerable'),
      ),
    );
    expect(controller.state.enemies.single.posture!.isVulnerable, isTrue);
  });

  testWidgets('破势开窗同时渲染蓄条、本体失衡与独立非透明墨裂', (tester) async {
    final fixture = (await tester.runAsync(
      () => Phase0aDebugBattleFixture.load(
        assetLoader: loadTestAsset,
        numbers: GameRepository.instance.numbers,
        assetPath: 'data/phase0a_debug_boss_battle.yaml',
      ),
    ))!;
    final controller = Phase0aBattleController(
      flow: fixture.flow,
      roster: fixture.roster,
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );
    addTearDown(controller.dispose);
    final driver = Phase0aBossMechanicsRouteDriver(
      fixedDeltaSeconds: fixture.fixedDeltaSeconds,
    );

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        // Provide normal Material text inheritance for this isolated screen.
        builder: (context, child) => Material(child: child),
        home: Phase0aBattleScreen(
          controller: controller,
          autoStep: false,
          feedbackHoldSeconds: 5,
        ),
      ),
    );

    for (var tick = 0; tick < 1000 && !driver.completed; tick++) {
      driver.advance(controller);
    }
    expect(driver.completed, isTrue);
    expect(controller.state.enemies.single.posture!.isVulnerable, isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    const bossId = 'wave2_elite';
    expect(
      find.byKey(const ValueKey('phase0a_vulnerability_open_$bossId')),
      findsOneWidget,
    );
    final fill = tester.widget<FractionallySizedBox>(
      find.byKey(const ValueKey('phase0a_posture_fill_$bossId')),
    );
    expect(fill.widthFactor, 1);
    expect(
      find.byKey(const ValueKey('phase0a_posture_unbalanced_$bossId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('phase0a_posture_wash_$bossId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('phase0a_posture_break_$bossId')),
      findsOneWidget,
    );
    expect(find.text(UiStrings.phase0aPostureBroken), findsOneWidget);
    expect(find.text(UiStrings.phase0aBossChargeInterrupted), findsNothing);
    expect(
      UiStrings.phase0aPostureBroken,
      isNot(UiStrings.phase0aBossChargeInterrupted),
    );

    final paintFinder = find.byKey(
      const ValueKey('phase0a_posture_break_paint_$bossId'),
    );
    expect(paintFinder, findsOneWidget);
    final size = tester.getSize(paintFinder);
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));
    final painter = tester.widget<CustomPaint>(paintFinder).painter;
    expect(painter, isNotNull);
    final recorder = ui.PictureRecorder();
    painter!.paint(ui.Canvas(recorder), size);
    final picture = recorder.endRecording();
    final bytes = await tester.runAsync(() async {
      final image = await picture.toImage(
        size.width.ceil(),
        size.height.ceil(),
      );
      picture.dispose();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data;
    });
    expect(bytes, isNotNull);
    var paintedPixels = 0;
    for (var offset = 3; offset < bytes!.lengthInBytes; offset += 4) {
      if (bytes.getUint8(offset) != 0) paintedPixels++;
    }
    expect(paintedPixels, greaterThan(0), reason: '破势 painter 不得为空画布');

    final windowTicks =
        controller.state.enemies.single.posture!.vulnerabilityTicksRemaining;
    for (var tick = 0; tick < windowTicks; tick++) {
      controller.step();
    }
    await tester.pump();
    expect(controller.state.enemies.single.posture!.isVulnerable, isFalse);
    expect(
      find.byKey(const ValueKey('phase0a_posture_unbalanced_$bossId')),
      findsNothing,
      reason: '窗口结束后本体必须随权威 posture 状态恢复',
    );
    expect(
      find.byKey(const ValueKey('phase0a_posture_wash_$bossId')),
      findsNothing,
    );
  });

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
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          // Provide normal Material text inheritance for this isolated screen.
          builder: (context, child) => Material(child: child),
          home: RepaintBoundary(
            key: capture,
            child: Phase0aBattleScreen(
              controller: bossController,
              autoStep: false,
              feedbackHoldSeconds: 5,
            ),
          ),
        ),
      );
      await tester.pump();

      const bossId = 'wave2_elite';
      expect(
        find.byKey(const ValueKey('phase0a_vulnerability_guarded_$bossId')),
        findsOneWidget,
      );
      expect(
        find.textContaining(UiStrings.phase0aVulnerabilityGuarded),
        findsOneWidget,
      );

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
        find.byKey(const ValueKey('phase0a_vulnerability_guarded_$bossId')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.phase0aVulnerabilityOpen), findsNothing);
      await _captureMechanics(
        tester,
        capture,
        'boss-charge-${viewport.width.toInt()}x${viewport.height.toInt()}',
      );

      bossController.step(const Phase0aPlayerCommand(clear: true));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('phase0a_boss_interrupt_banner')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('phase0a_staggered_$bossId')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('phase0a_vulnerability_guarded_$bossId')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.phase0aBossChargeInterrupted), findsNothing);
      expect(find.text(UiStrings.phase0aStaggered), findsNothing);
      expect(find.textContaining(UiStrings.phase0aStaggered), findsNothing);
      expect(
        bossController.state.enemies.single.posture!.accumulated,
        greaterThan(0),
      );
      await _captureMechanics(
        tester,
        capture,
        'boss-posture-${viewport.width.toInt()}x${viewport.height.toInt()}',
      );
    });
  }
}

Future<void> _captureMechanics(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final output = Platform.environment['WUXIA_STANDEE_VISUAL_OUTPUT'];
  if (output == null) return;
  final context = key.currentContext!;
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image)).toList()) {
      Object? imageError;
      await precacheImage(
        image.image,
        context,
        onError: (error, _) => imageError = error,
      );
      expect(
        imageError,
        isNull,
        reason: 'mechanics screenshot must resolve actual assets',
      );
    }
    // No elapsed simulation time: only flush resolved image painting.
    await tester.pump();
    final boundary = context.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      final file = File('$output/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
