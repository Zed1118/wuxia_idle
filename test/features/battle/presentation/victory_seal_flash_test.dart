import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_ceremony.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('VictorySealFlash 显「勝」题字,~800ms 后自动 onDone', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VictorySealFlash(onDone: () => done++)),
    ));
    expect(find.text(UiStrings.victoryTitle), findsOneWidget);
    expect(done, 0);

    await tester.pump(const Duration(milliseconds: 1700));
    expect(done, 1);
  });

  testWidgets('点击提前跳过 → 立即 onDone', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VictorySealFlash(onDone: () => done++)),
    ));
    await tester.tap(find.byType(VictorySealFlash));
    await tester.pump();
    expect(done, 1);

    await tester.pump(const Duration(milliseconds: 1700));
    expect(done, 1);
  });
}
