import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/human_gate/readability_stimulus_app.dart';

void main() {
  testWidgets('frozen manifest loads five hash-verified stimuli', (
    tester,
  ) async {
    final stimuli = await loadReadabilityStimuli();
    expect(stimuli, hasLength(5));
    expect(stimuli.map((stimulus) => stimulus.id).toSet(), hasLength(5));
    expect(stimuli.every((stimulus) => stimulus.sha256.length == 64), isTrue);
  });

  testWidgets('each stimulus is visible for the frozen exposure then masked', (
    tester,
  ) async {
    const stimuli = [
      ReadabilityStimulus(
        id: 'one',
        asset: 'assets/readability/frame1_wave2_peak.png',
        sha256: 'unused-in-widget-test',
      ),
      ReadabilityStimulus(
        id: 'two',
        asset: 'assets/readability/frame2_wave3_peak.png',
        sha256: 'unused-in-widget-test',
      ),
    ];
    await tester.pumpWidget(
      const MaterialApp(
        home: ReadabilityStimulusSession(
          stimuli: stimuli,
          exposure: Duration(seconds: 1),
          prepareStimulus: _noOpPrepare,
        ),
      ),
    );

    await tester.tap(find.text('显示第 1 帧'));
    await tester.pump();
    expect(find.byKey(const ValueKey('stimulus-visible')), findsOneWidget);
    expect(find.byKey(const ValueKey('stimulus-masked')), findsNothing);

    await tester.pump(const Duration(milliseconds: 999));
    expect(find.byKey(const ValueKey('stimulus-visible')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('stimulus-masked')), findsOneWidget);

    await tester.tap(find.text('下一帧'));
    await tester.pump();
    expect(find.text('显示第 2 帧'), findsOneWidget);
    await tester.tap(find.text('显示第 2 帧'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('下一帧'));
    await tester.pump();
    expect(find.byKey(const ValueKey('stimulus-complete')), findsOneWidget);
  });
}

Future<void> _noOpPrepare(
  BuildContext context,
  ReadabilityStimulus stimulus,
) async {}
