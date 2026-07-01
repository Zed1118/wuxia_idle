import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('StageRetryDialogBody 同时显示提示与短诊断', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StageRetryDialogBody())),
    );
    expect(find.text(UiStrings.stageRetryPrompt), findsOneWidget);
    expect(find.text(UiStrings.stageRetryHintLine), findsOneWidget);
  });
}
