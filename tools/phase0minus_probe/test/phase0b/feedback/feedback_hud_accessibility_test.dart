import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_events.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_state.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_view.dart';
import 'package:phase0minus_probe/phase0b/feedback/feedback_hud_widgets.dart';

void main() {
  const resetButtonKey = ValueKey('feedback-reset-button');

  Widget wrap(FeedbackHudState state, {VoidCallback? onReset}) => MaterialApp(
    home: Scaffold(
      body: FeedbackHud(state: state, onReset: onReset),
    ),
  );

  Future<void> pumpState(
    WidgetTester tester,
    FeedbackHudState state, {
    VoidCallback? onReset,
  }) async {
    await tester.pumpWidget(wrap(state, onReset: onReset));
    await tester.pump();
  }

  bool anyLiveRegion(WidgetTester tester) => tester
      .widgetList<Semantics>(find.byType(Semantics))
      .any((node) => node.properties.liveRegion ?? false);

  group('semantics', () {
    testWidgets('meters expose label and percent value', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(health: 0.35),
      );

      final meter = find.descendant(
        of: find.byKey(const ValueKey('meter-hp')),
        matching: find.byType(LinearProgressIndicator),
      );
      expect(
        tester.getSemantics(meter),
        matchesSemantics(label: 'HP', value: '35'),
      );
      handle.dispose();
    });

    testWidgets('boss pips expose a single phase label', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(bossPhase: 2, bossPhaseTotal: 3),
      );

      expect(
        tester.getSemantics(find.byType(BossPhasePips)),
        matchesSemantics(label: 'boss phase 2 of 3'),
      );
      handle.dispose();
    });

    testWidgets('danger banner and end panel are live regions only while '
        'active', (tester) async {
      await pumpState(tester, FeedbackHudState.initial());
      expect(anyLiveRegion(tester), isFalse);

      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(danger: FeedbackDanger.imminent),
      );
      expect(anyLiveRegion(tester), isTrue);

      await pumpState(tester, FeedbackHudState.initial());
      expect(anyLiveRegion(tester), isFalse);

      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(endState: FeedbackEndState.defeat),
      );
      expect(anyLiveRegion(tester), isTrue);
    });
  });

  group('announcements', () {
    testWidgets('danger escalation and battle conclusion are announced', (
      tester,
    ) async {
      final announcements = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/accessibility',
        (message) async {
          final decoded =
              const StandardMessageCodec().decodeMessage(message)
                  as Map<Object?, Object?>?;
          if (decoded != null && decoded['type'] == 'announce') {
            final data = decoded['data']! as Map<Object?, Object?>;
            announcements.add(data['message']! as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/accessibility',
          null,
        ),
      );

      // Initial build announces nothing.
      await pumpState(tester, FeedbackHudState.initial());
      expect(announcements, isEmpty);

      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(danger: FeedbackDanger.telegraph),
      );
      expect(announcements, ['Danger telegraph.']);

      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(danger: FeedbackDanger.imminent),
      );
      expect(announcements, [
        'Danger telegraph.',
        'Danger imminent. Break now.',
      ]);

      // Resolving danger is silent; concluding the battle speaks.
      await pumpState(tester, FeedbackHudState.initial());
      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(endState: FeedbackEndState.victory),
      );
      expect(announcements.last, 'Battle over. Victory.');

      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(endState: FeedbackEndState.defeat),
      );
      expect(announcements.last, 'Battle over. Defeat.');
    });
  });

  group('end-state focus and input lock', () {
    testWidgets('reset button takes focus at end state; Enter activates it', (
      tester,
    ) async {
      var resets = 0;
      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(endState: FeedbackEndState.victory),
        onReset: () => resets += 1,
      );

      final primary = WidgetsBinding.instance.focusManager.primaryFocus;
      final buttonElement = tester.element(find.byKey(resetButtonKey));
      var focusInsideButton = false;
      primary?.context?.visitAncestorElements((ancestor) {
        if (ancestor == buttonElement) focusInsideButton = true;
        return !focusInsideButton;
      });
      expect(
        focusInsideButton,
        isTrue,
        reason: 'reset button must hold keyboard focus at end state',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(resets, 1);
    });

    testWidgets('R shortcut activates reset while the end panel is up', (
      tester,
    ) async {
      var resets = 0;
      await pumpState(
        tester,
        FeedbackHudState.initial().copyWith(endState: FeedbackEndState.defeat),
        onReset: () => resets += 1,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(resets, 1);
    });

    testWidgets('no end panel focus steal during normal play', (tester) async {
      await pumpState(tester, FeedbackHudState.initial(), onReset: () {});
      expect(find.byKey(resetButtonKey), findsNothing);
    });
  });
}
