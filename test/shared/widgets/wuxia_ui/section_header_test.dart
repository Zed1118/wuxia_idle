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

  testWidgets('分隔线使用绘制墨线而非位图裁切', (tester) async {
    await tester.pumpWidget(host(const SectionHeader('武器')));
    final dividerBox = find.byWidgetPredicate(
      (widget) => widget is SizedBox && widget.height == 8,
    );
    final dividerPaint = find.descendant(
      of: dividerBox,
      matching: find.byType(CustomPaint),
    );
    expect(find.byType(Image), findsNothing);
    expect(dividerPaint, findsOneWidget);
    expect(dividerBox, findsOneWidget);
  });

  testWidgets('宽屏下分隔线限制最大宽度并压低透明度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      host(const SizedBox(width: 1000, child: SectionHeader('武器'))),
    );

    final dividerPaint = find.descendant(
      of: find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 8,
      ),
      matching: find.byType(CustomPaint),
    );
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: dividerPaint, matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.68);

    final constrained = tester.widget<ConstrainedBox>(
      find.ancestor(of: dividerPaint, matching: find.byType(ConstrainedBox)),
    );
    expect(constrained.constraints.maxWidth, 560);
  });
}
