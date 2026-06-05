import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/seal_badge.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('渲染朱印文字', (tester) async {
    await tester.pumpWidget(host(const SealBadge(text: '+7')));
    expect(find.text('+7'), findsOneWidget);
  });

  testWidgets('朱印图缺失不抛异常，文字仍在', (tester) async {
    await tester.pumpWidget(host(const SealBadge(text: '传')));
    expect(tester.takeException(), isNull);
    expect(find.text('传'), findsOneWidget);
  });
}
