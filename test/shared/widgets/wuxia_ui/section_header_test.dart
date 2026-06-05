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

  testWidgets('分隔线保留枯笔裁切而非纵向压扁', (tester) async {
    await tester.pumpWidget(host(const SectionHeader('武器')));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect(image.alignment, Alignment.center);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 8,
      ),
      findsOneWidget,
    );
  });
}
