import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/meridian_bar.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: SizedBox(width: 200, child: child)));

  testWidgets('ratio 超界钳到 1：填充宽不溢出', (tester) async {
    await tester.pumpWidget(host(const MeridianBar(ratio: 1.8)));
    expect(tester.takeException(), isNull);
    final fsb = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fsb.widthFactor, 1.0);
  });

  testWidgets('负 ratio 钳到 0', (tester) async {
    await tester.pumpWidget(host(const MeridianBar(ratio: -0.5)));
    final fsb = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fsb.widthFactor, 0.0);
  });

  testWidgets('给 label 时渲染文字', (tester) async {
    await tester.pumpWidget(host(const MeridianBar(ratio: 0.3, label: '心魔 2/7')));
    expect(find.text('心魔 2/7'), findsOneWidget);
  });
}
