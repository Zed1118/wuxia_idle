import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_bot_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_controller.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_vfx_controller.dart';
import 'package:wuxia_idle/features/debug/application/phase0a_debug_battle_fixture.dart';
import 'package:wuxia_idle/shared/theme/wuxia_app_theme.dart';

import '../../../../support/test_data.dart';

// Rendering fixtures deliberately exercise rich feedback. They do not prove
// production density, balance, natural progression or physical frame budgets.
void main() {
  late GameRepository repository;
  setUpAll(() async {
    repository = await loadTestGameRepository();
    final path = Platform.environment['WUXIA_EFFECTS_VISUAL_FONT'];
    if (path != null) {
      final bytes = ByteData.sublistView(await File(path).readAsBytes());
      for (final family in ['Roboto', 'Ahem', 'sans-serif']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
    }
  });

  for (final viewport in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets(
      '$viewport reduced effects retain Boss warning and guardian cues',
      (tester) async {
        final fixture = (await tester.runAsync(
          () => Phase0aDebugBattleFixture.load(
            assetLoader: loadTestAsset,
            numbers: repository.numbers,
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
        var reduced = false;
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Phase0aBattleScreen(
                  controller: controller,
                  autoStep: false,
                  reduceEffects: reduced,
                  feedbackHoldSeconds: 5,
                );
              },
            ),
          ),
        );
        await tester.pump();
        final seen = <String>{};
        var breakSent = false;
        for (var tick = 0; tick < 80; tick++) {
          final charging = controller.state.enemies.first.chargingCast != null;
          controller.step(
            !breakSent && charging
                ? const Phase0aPlayerCommand(clear: true)
                : null,
          );
          if (charging) breakSent = true;
          await tester.pump(const Duration(milliseconds: 20));
          final normal = _criticalCues(tester);
          final state = controller.state;
          final events = controller.events.toList();
          update(() => reduced = true);
          await tester.pump();
          expect(_criticalCues(tester), normal);
          expect(controller.state, same(state));
          expect(controller.events, events);
          seen.addAll(normal.keys);
          update(() => reduced = false);
          await tester.pump();
        }
        expect(seen, contains('phase0a_guardian_ward_ring'));
        expect(seen, contains('phase0a_boss_charge_banner'));
        expect(
          seen.any((key) => key.startsWith('phase0a_guard_intercept_')),
          isTrue,
        );
        expect(
          seen.any((key) => key.startsWith('phase0a_guardian_coop_')),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      '$viewport low ink detail repaints live feedback without hiding it',
      (tester) async {
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
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var reduced = false;
        late StateSetter update;
        final capture = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: wuxiaAppTheme(),
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return RepaintBoundary(
                  key: capture,
                  child: Phase0aBattleScreen(
                    controller: controller,
                    autoStep: false,
                    reduceEffects: reduced,
                    reduceFlashing: true,
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();
        final seen = <String>{};
        final proofs = <String, List<int>>{};
        Future<void> compareCurrent({bool screenshot = false}) async {
          await tester.pump(const Duration(milliseconds: 80));
          update(() => reduced = false);
          await tester.pump();
          final state = controller.state;
          final events = controller.events.toList();
          final entries = controller.feedback;
          final normal = _paintedFeedback(tester);
          if (screenshot) {
            await _capture(
              tester,
              capture,
              '${viewport.width.toInt()}-standard',
            );
          }
          update(() => reduced = true);
          await tester.pump();
          final low = _paintedFeedback(tester);
          expect(
            low.keys.toSet(),
            normal.keys.toSet(),
            reason: 'No feedback is removed',
          );
          for (final key in normal.keys) {
            final a = normal[key]!, b = low[key]!;
            final shouldReduce =
                key.startsWith('phase0a_gather_pull_') ||
                key == 'phase0a_gather_vortex' ||
                key == 'phase0a_clear_burst' ||
                key.startsWith('phase0a_defeat_ink_') ||
                key == 'phase0a_melee_slash' ||
                key == 'phase0a_palm_trail';
            if (shouldReduce) {
              expect(b.draws, lessThan(a.draws), reason: key);
              expect(
                b.draws,
                greaterThan(0),
                reason: '$key keeps its core shape',
              );
              expect(
                b.painter.shouldRepaint(a.painter),
                isTrue,
                reason: '$key updates without a tick',
              );
              seen.add(key);
              proofs[key] = [a.draws, b.draws];
            } else {
              expect(b.draws, a.draws, reason: '$key is not decorative detail');
            }
          }
          expect(controller.state, same(state));
          expect(controller.events, events);
          expect(controller.feedback, same(entries));
          for (final actor in [state.player, ...state.enemies]) {
            expect(
              find.byKey(ValueKey('phase0a_actor_visual_${actor.id}')),
              findsOneWidget,
            );
          }
          if (screenshot) {
            await _capture(
              tester,
              capture,
              '${viewport.width.toInt()}-reduced',
            );
          }
          update(() => reduced = false);
          await tester.pump();
          final restored = _paintedFeedback(tester);
          expect(
            restored.map((k, v) => MapEntry(k, v.draws)),
            normal.map((k, v) => MapEntry(k, v.draws)),
          );
          expect(tester.takeException(), isNull);
        }

        controller.step(const Phase0aPlayerCommand(gather: true));
        expect(
          controller.feedback.any((e) => e.kind == Phase0aVfxKind.gatherPull),
          isTrue,
        );
        await compareCurrent(screenshot: true);
        controller.step(const Phase0aPlayerCommand(clear: true));
        expect(
          controller.feedback.any((e) => e.kind == Phase0aVfxKind.clearBurst),
          isTrue,
        );
        await compareCurrent();
        final bot = Phase0aPlayerBotAdapter(
          playerAdapter: fixture.playerAdapter,
        );
        for (
          var tick = 0;
          tick < 600 && controller.outcome == Phase0aBattleOutcome.ongoing;
          tick++
        ) {
          controller.step(bot.commandFor(controller.state));
          if (controller.feedback.any(
            (e) =>
                e.kind == Phase0aVfxKind.defeatInk ||
                e.kind == Phase0aVfxKind.meleeSlash ||
                e.kind == Phase0aVfxKind.palmTrail,
          )) {
            await compareCurrent();
          }
        }
        expect(controller.outcome, Phase0aBattleOutcome.victory);
        expect(
          seen,
          containsAll(['phase0a_gather_vortex', 'phase0a_clear_burst']),
        );
        expect(
          seen.any((key) => key.startsWith('phase0a_gather_pull_')),
          isTrue,
        );
        expect(
          seen.any((key) => key.startsWith('phase0a_defeat_ink_')),
          isTrue,
        );
        expect(
          seen.any(
            (key) =>
                key == 'phase0a_melee_slash' || key == 'phase0a_palm_trail',
          ),
          isTrue,
        );
        // Evidence is actual draw calls from mounted painters, not predicted budgets.
        debugPrint('reduced-effects-painter-proof $viewport $proofs');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

Map<String, ({CustomPainter painter, int draws})> _paintedFeedback(
  WidgetTester tester,
) {
  final result = <String, ({CustomPainter painter, int draws})>{};
  for (final element in find.byType(CustomPaint).evaluate()) {
    final widget = element.widget as CustomPaint;
    final painter = widget.painter;
    if (painter == null || widget.key is! ValueKey<String>) continue;
    var key = (widget.key! as ValueKey<String>).value;
    if (!key.startsWith('phase0a_')) continue;
    if (key == 'phase0a_defeat_ink') {
      final parent = element.findAncestorWidgetOfExactType<SizedBox>();
      key = (parent!.key! as ValueKey<String>).value;
    }
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, (element.renderObject! as RenderBox).size);
    result[key] = (
      painter: painter,
      draws: canvas.invocations
          .where(
            (i) =>
                i.invocation.memberName.toString().startsWith('Symbol("draw'),
          )
          .length,
    );
  }
  return result;
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final directory = Platform.environment['WUXIA_EFFECTS_VISUAL_OUTPUT'];
  if (directory == null) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final output = File('$directory/$name.png');
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Map<String, List<String>> _criticalCues(WidgetTester tester) {
  final cues = find.byWidgetPredicate((widget) {
    final key = widget.key;
    if (key is! ValueKey<String>) return false;
    return key.value == 'phase0a_guardian_ward_ring' ||
        key.value == 'phase0a_offscreen_indicators' ||
        key.value.startsWith('phase0a_boss_charge_') ||
        key.value.startsWith('phase0a_guard_intercept_') ||
        key.value.startsWith('phase0a_guardian_coop_');
  });
  return {
    for (final element in cues.evaluate())
      (element.widget.key! as ValueKey<String>).value: [
        for (final e
            in find
                .descendant(
                  of: find.byWidget(element.widget),
                  matching: find.byType(CustomPaint),
                  matchRoot: true,
                )
                .evaluate())
          if ((e.widget as CustomPaint).painter != null)
            ..._drawDescription(
              (e.widget as CustomPaint).painter!,
              (e.renderObject! as RenderBox).size,
            ),
        for (final text
            in find
                .descendant(
                  of: find.byWidget(element.widget),
                  matching: find.byType(Text),
                )
                .evaluate())
          (text.widget as Text).data ?? '',
      ],
  };
}

List<String> _drawDescription(CustomPainter painter, Size size) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, size);
  return [for (final invocation in canvas.invocations) invocation.toString()];
}
