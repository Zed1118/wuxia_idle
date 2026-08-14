import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_widgets.dart';
import 'package:phase0minus_probe/phase0b/integration/phase0b_vertical_slice_draft_app.dart';

void main() {
  Future<void> pumpSlice(WidgetTester tester) async {
    await tester.pumpWidget(const Phase0bVerticalSliceDraftApp());
    await tester.pump();
  }

  double meterValue(WidgetTester tester, Key key) {
    final meter = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    return meter.value!;
  }

  List<String> cueLogTexts(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(CueLogView),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data!)
      .toList();

  test('vertical slice draft declares NOT FINAL non-gate metadata', () {
    expect(Phase0bVerticalSliceDraftMetadata.gateEligible, isFalse);
    expect(
      Phase0bVerticalSliceDraftMetadata.modeId,
      'phase0b_vertical_slice_draft',
    );
  });

  testWidgets('banner pins NOT FINAL / NON-GATE claims on screen', (
    tester,
  ) async {
    await pumpSlice(tester);
    expect(find.textContaining('NOT FINAL ENCOUNTER × FEEDBACK'), findsOne);
    expect(find.textContaining('NON-GATE'), findsOne);
    expect(find.textContaining('gate_eligible=false'), findsOne);
    expect(find.textContaining('no saves'), findsOne);
    expect(find.textContaining('memory-only loot'), findsOne);
  });

  for (final size in const [Size(1280, 720), Size(1440, 900)]) {
    testWidgets('launches overflow-free at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpSlice(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('VERTICAL SLICE DRAFT'), findsOne);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('real encounter events drive telegraph, damage, and style', (
    tester,
  ) async {
    await pumpSlice(tester);
    expect(meterValue(tester, const ValueKey('meter-hp')), 1);

    // Walk east into the boss's slam zone; the boss telegraphs (imminent)
    // and the strike lands through the real encounter event pipeline.
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    }
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('DANGER · BREAK NOW'), findsOneWidget);

    // The cue log keeps only the most recent cues, so poll at a fine step
    // to catch the hurt cue the moment the strike lands.
    var sawPlayerHurt = false;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (cueLogTexts(tester).contains('playerHurt')) sawPlayerHurt = true;
    }
    expect(find.text('DANGER · BREAK NOW'), findsNothing);
    expect(meterValue(tester, const ValueKey('meter-hp')), lessThan(1));
    expect(sawPlayerHurt, isTrue);
    expect(cueLogTexts(tester), contains('heavyStrike'));

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    expect(find.text('style · sinister'), findsOneWidget);
  });

  testWidgets('terminal panel locks input and reset rebuilds the run', (
    tester,
  ) async {
    await pumpSlice(tester);
    // Stand east of the boss: outside the hero's east-facing basic arc
    // (so the boss survives) but inside every slam zone, so slam cycles
    // grind the hero down.
    for (var i = 0; i < 7; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    }
    await tester.pump(const Duration(seconds: 60));
    expect(find.text('DEFEAT'), findsOneWidget);
    expect(meterValue(tester, const ValueKey('meter-hp')), 0);

    // Terminal input lock: movement and style keys change nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('style · rigid'), findsOneWidget);
    expect(meterValue(tester, const ValueKey('meter-hp')), 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(find.text('DEFEAT'), findsNothing);
    expect(meterValue(tester, const ValueKey('meter-hp')), 1);
    expect(cueLogTexts(tester), ['cues · silent sink', '—']);
  });

  testWidgets('same-seed reset reproduces identical HUD and cues', (
    tester,
  ) async {
    Future<(double, List<String>)> scriptedRun(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 1));
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pump(const Duration(seconds: 9));
      return (
        meterValue(tester, const ValueKey('meter-hp')),
        cueLogTexts(tester),
      );
    }

    await pumpSlice(tester);
    final first = await scriptedRun(tester);
    expect(first.$1, lessThan(1));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(meterValue(tester, const ValueKey('meter-hp')), 1);

    final second = await scriptedRun(tester);
    expect(second.$1, first.$1);
    expect(second.$2, first.$2);
  });
}
