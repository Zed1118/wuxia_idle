import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_status_pill.dart';

void main() {
  testWidgets('WuxiaStatusPill renders label and optional icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WuxiaStatusPill(
            label: UiStrings.equipmentDeltaUp,
            tone: WuxiaStatusTone.positive,
            icon: Icons.arrow_upward,
          ),
        ),
      ),
    );

    expect(find.text(UiStrings.equipmentDeltaUp), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });
}
