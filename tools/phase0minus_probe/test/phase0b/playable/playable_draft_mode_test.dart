import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/phase0b/playable/phase0b_playable_draft_app.dart';

void main() {
  test('playable draft declares NOT FINAL non-gate metadata', () {
    expect(Phase0bPlayableDraftMetadata.gateEligible, isFalse);
    expect(Phase0bPlayableDraftMetadata.modeId, 'phase0b_playable_draft');
  });

  test('main mode registry accepts the draft mode', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("'phase0b_playable_draft'"));
    expect(source, contains('Phase0bPlayableDraftApp'));
  });

  test('draft app stays outside the gate/result-writing surface', () {
    final source = File(
      'lib/phase0b/playable/phase0b_playable_draft_app.dart',
    ).readAsStringSync();
    expect(source, contains('NOT FINAL'));
    expect(source, contains('gate_eligible=false'));
    expect(source.contains('ResultWriter'), isFalse);
    expect(source.contains('build/results'), isFalse);
  });

  testWidgets('draft entry launches and exposes the non-final boundary', (
    tester,
  ) async {
    await tester.pumpWidget(const Phase0bPlayableDraftApp());
    await tester.pump();

    expect(find.textContaining('NOT FINAL'), findsOneWidget);
    expect(find.textContaining('gate_eligible=false'), findsOneWidget);
    expect(find.textContaining('group A alive'), findsOneWidget);

    await tester.tap(find.text('CAST CLEAR (R)'));
    await tester.pump();
    expect(find.textContaining('group A alive'), findsOneWidget);

    await tester.tap(find.text('RESET (ENTER)'));
    await tester.pump();
    expect(find.textContaining('hero x=420'), findsOneWidget);
  });
}
