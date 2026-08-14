import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/feedback/phase0b_feedback_draft_app.dart';

void main() {
  Future<void> pumpDraft(WidgetTester tester) async {
    await tester.pumpWidget(const Phase0bFeedbackDraftApp());
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

  testWidgets('banner pins NOT FINAL and non-Gate claim on screen', (
    tester,
  ) async {
    await pumpDraft(tester);
    expect(find.textContaining('NOT FINAL HUD'), findsOneWidget);
    expect(find.textContaining('gate_eligible=false'), findsOneWidget);
    expect(find.textContaining('no saves'), findsOneWidget);
  });

  testWidgets('damage key drives the health meter through the state model', (
    tester,
  ) async {
    await pumpDraft(tester);
    expect(meterValue(tester, const ValueKey('meter-hp')), 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pump();
    expect(meterValue(tester, const ValueKey('meter-hp')), closeTo(0.82, 1e-9));

    // The cue log observes the mapped cue for the same event.
    expect(find.text('playerHurt'), findsOneWidget);
  });

  testWidgets('danger telegraph shows cinnabar banner and break clears it', (
    tester,
  ) async {
    await pumpDraft(tester);
    expect(find.text('danger'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pump();
    expect(find.text('danger'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pump();
    expect(find.text('DANGER · BREAK NOW'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.pump();
    expect(find.text('danger'), findsNothing);
    expect(find.text('DANGER · BREAK NOW'), findsNothing);
    expect(find.text('breakSuccess'), findsOneWidget);
  });

  testWidgets('loot key shows in-memory drops and reset clears them', (
    tester,
  ) async {
    await pumpDraft(tester);
    expect(find.textContaining('silver taels'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.pump();
    expect(find.textContaining('silver taels'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(find.textContaining('silver taels'), findsNothing);
  });

  testWidgets('victory end panel locks input until reset', (tester) async {
    await pumpDraft(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.pump();
    expect(find.text('VICTORY'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.pump();
    expect(meterValue(tester, const ValueKey('meter-hp')), 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(find.text('VICTORY'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await tester.pump();
    expect(find.text('DEFEAT'), findsOneWidget);
  });

  testWidgets('boss phase, style, and resource keys move their HUD pieces', (
    tester,
  ) async {
    await pumpDraft(tester);
    expect(meterValue(tester, const ValueKey('meter-resource')), 0.4);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
    await tester.pump();
    expect(
      meterValue(tester, const ValueKey('meter-resource')),
      closeTo(0.2, 1e-9),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
    await tester.pump();
    expect(find.text('style · agile'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
    await tester.pump();
    expect(find.text('bossPhaseShift'), findsOneWidget);
  });
}
