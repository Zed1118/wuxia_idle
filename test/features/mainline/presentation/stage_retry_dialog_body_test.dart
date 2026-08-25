import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('StageRetryDialogBody 只显示事实与参与者，不给配装建议', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StageRetryDialogBody(participantName: '门人甲')),
      ),
    );
    expect(find.text(UiStrings.stageRetryPrompt), findsOneWidget);
    expect(find.text(UiStrings.stageReportParticipant('门人甲')), findsOneWidget);
    expect(find.textContaining('换装备'), findsNothing);
  });
}
