import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/error_fallback.dart';

/// P0-4(2026-06-29 审查修复):统一错误兜底 UI。
/// 友好中文文案 + 可选重试;原始异常不上屏(仅 debugPrint)。
void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('默认文案走 UiStrings.errorFallbackMessage', (tester) async {
    await tester.pumpWidget(host(const ErrorFallback()));
    expect(find.text(UiStrings.errorFallbackMessage), findsOneWidget);
  });

  testWidgets('自定义 message 覆盖默认', (tester) async {
    await tester.pumpWidget(host(const ErrorFallback(message: '门派数据加载失败')));
    expect(find.text('门派数据加载失败'), findsOneWidget);
    expect(find.text(UiStrings.errorFallbackMessage), findsNothing);
  });

  testWidgets('onRetry != null → 显示重试按钮且点击触发回调', (tester) async {
    var n = 0;
    await tester.pumpWidget(host(ErrorFallback(onRetry: () => n++)));
    expect(find.text(UiStrings.errorRetry), findsOneWidget);
    await tester.tap(find.text(UiStrings.errorRetry));
    expect(n, 1);
  });

  testWidgets('onRetry == null → 不显示重试按钮', (tester) async {
    await tester.pumpWidget(host(const ErrorFallback()));
    expect(find.text(UiStrings.errorRetry), findsNothing);
  });

  testWidgets('原始异常不上屏(error 仅 debugPrint)', (tester) async {
    await tester.pumpWidget(
      host(ErrorFallback(error: StateError('IsarSetup 未初始化-内部细节'))),
    );
    expect(find.textContaining('IsarSetup'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
  });
}
