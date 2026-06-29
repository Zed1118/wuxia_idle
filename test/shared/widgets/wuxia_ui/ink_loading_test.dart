import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/ink_loading.dart';

/// P0-2(2026-06-29 审查修复):水墨 loading 组件,替换 Material
/// CircularProgressIndicator。墨晕扩散动画 · 用 WuxiaColors 不硬编码。
void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('默认尺寸 48 且无异常渲染', (tester) async {
    await tester.pumpWidget(host(const InkLoadingIndicator()));
    expect(tester.takeException(), isNull);
    final box = tester.getSize(find.byType(InkLoadingIndicator));
    expect(box.width, 48);
    expect(box.height, 48);
  });

  testWidgets('size 参数自定义尺寸', (tester) async {
    await tester.pumpWidget(host(const InkLoadingIndicator(size: 24)));
    final box = tester.getSize(find.byType(InkLoadingIndicator));
    expect(box.width, 24);
  });

  testWidgets('含 CustomPaint(墨晕绘制)', (tester) async {
    await tester.pumpWidget(host(const InkLoadingIndicator()));
    expect(
      find.descendant(
        of: find.byType(InkLoadingIndicator),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
  });

  testWidgets('动画推进多帧不抛异常', (tester) async {
    await tester.pumpWidget(host(const InkLoadingIndicator()));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispose 干净(替换 widget 不抛异常)', (tester) async {
    await tester.pumpWidget(host(const InkLoadingIndicator()));
    await tester.pumpWidget(host(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('const 构造支持(无外层 Material 也不红屏)', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: InkLoadingIndicator(color: WuxiaColors.textMuted)),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
