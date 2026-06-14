import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_enter_caption.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('题字过场渲染「闭关」并自动结束', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeclusionEnterCaption(onDone: () => done = true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(UiStrings.seclusionEnterCaption), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    expect(done, isTrue);
  });
}
