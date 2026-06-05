import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/section_header.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('渲染标题文字', (tester) async {
    await tester.pumpWidget(host(const SectionHeader('随身装备')));
    expect(find.text('随身装备'), findsOneWidget);
  });

  testWidgets('分隔线图缺失不抛异常', (tester) async {
    await tester.pumpWidget(host(const SectionHeader('武器')));
    expect(tester.takeException(), isNull);
  });
}
