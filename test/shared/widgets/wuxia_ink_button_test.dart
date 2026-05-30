import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('渲染 label 与 hint 两行', (tester) async {
    await tester.pumpWidget(host(const WuxiaInkButton(
      label: '主线',
      hint: '继续江湖路',
      onTap: null,
    )));
    expect(find.text('主线'), findsOneWidget);
    expect(find.text('继续江湖路'), findsOneWidget);
  });

  testWidgets('点击触发 onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(host(WuxiaInkButton(
      label: '心法',
      hint: 'x',
      onTap: () => tapped++,
    )));
    await tester.tap(find.byType(WuxiaInkButton));
    expect(tapped, 1);
  });

  testWidgets('disabled 拦截点击且半透明 0.4', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(host(WuxiaInkButton(
      label: '门派',
      hint: 'x',
      onTap: () => tapped++,
      disabled: true,
    )));
    await tester.tap(find.byType(WuxiaInkButton), warnIfMissed: false);
    expect(tapped, 0);
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 0.4);
  });
}
