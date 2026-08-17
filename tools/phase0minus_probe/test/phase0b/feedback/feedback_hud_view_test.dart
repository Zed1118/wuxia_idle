import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_cues.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_view.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_loot.dart';

void main() {
  Future<void> pumpHud(
    WidgetTester tester,
    Size size, {
    FeedbackHudState? state,
    VoidCallback? onReset,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedbackHud(
            state: state ?? FeedbackHudState.initial(),
            onReset: onReset,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double meterBarWidth(WidgetTester tester, Key key) => tester
      .getSize(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(LinearProgressIndicator),
        ),
      )
      .width;

  /// Maximal content: every HUD region filled to its bound. Any overflow
  /// throws during layout and fails the test.
  FeedbackHudState busyState({
    FeedbackEndState endState = FeedbackEndState.none,
  }) => FeedbackHudState.initial().copyWith(
    health: 0.35,
    resource: 0.8,
    style: FeedbackStyle.sinister,
    bossPhase: 3,
    danger: FeedbackDanger.imminent,
    endState: endState,
    loot: [
      for (var index = 1; index <= 6; index++)
        LootEntry(sequence: index, label: 'drop $index', kind: LootKind.gear),
    ],
    recentCues: FeedbackCue.values.take(recentCueLimit).toList(),
  );

  testWidgets('1280x720 renders the compact variant without overflow', (
    tester,
  ) async {
    await pumpHud(tester, const Size(1280, 720), state: busyState());

    expect(meterBarWidth(tester, const ValueKey('meter-hp')), 150);
    expect(meterBarWidth(tester, const ValueKey('meter-resource')), 150);
    expect(find.text('DANGER · BREAK NOW'), findsOneWidget);
    expect(find.textContaining('drop 6'), findsOneWidget);
    expect(find.text(FeedbackCue.values.first.name), findsWidgets);
  });

  testWidgets('1440x900 renders the comfortable variant without overflow', (
    tester,
  ) async {
    await pumpHud(tester, const Size(1440, 900), state: busyState());

    expect(meterBarWidth(tester, const ValueKey('meter-hp')), 200);
    expect(meterBarWidth(tester, const ValueKey('meter-resource')), 200);
    expect(find.text('DANGER · BREAK NOW'), findsOneWidget);
    expect(find.textContaining('drop 6'), findsOneWidget);
  });

  for (final size in const [Size(1280, 720), Size(1440, 900)]) {
    testWidgets('end panel fits ${size.width.toInt()}x${size.height.toInt()} '
        'and reset callback fires', (tester) async {
      var resets = 0;
      await pumpHud(
        tester,
        size,
        state: busyState(endState: FeedbackEndState.victory),
        onReset: () => resets += 1,
      );

      expect(find.text('VICTORY'), findsOneWidget);
      await tester.tap(find.text('RESET (R)'));
      expect(resets, 1);
    });
  }

  test('compact breakpoint pins the two reference viewports', () {
    expect(FeedbackHud.isCompact(const Size(1280, 720)), isTrue);
    expect(FeedbackHud.isCompact(const Size(1440, 900)), isFalse);
  });
}
