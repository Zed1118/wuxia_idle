import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('渲染 label', (tester) async {
    await tester.pumpWidget(host(const PlaqueButton(label: '强化', onTap: null)));
    expect(find.text('强化'), findsOneWidget);
  });

  testWidgets('点击触发 onTap', (tester) async {
    var n = 0;
    await tester.pumpWidget(host(PlaqueButton(label: '继续', onTap: () => n++)));
    await tester.tap(find.byType(PlaqueButton));
    expect(n, 1);
  });

  testWidgets('disabled 拦截点击且半透明', (tester) async {
    var n = 0;
    await tester.pumpWidget(host(
      PlaqueButton(label: '卸下', onTap: () => n++, disabled: true),
    ));
    await tester.tap(find.byType(PlaqueButton), warnIfMissed: false);
    expect(n, 0);
    final op = tester.widget<Opacity>(find.byType(Opacity));
    expect(op.opacity, 0.4);
  });
}
