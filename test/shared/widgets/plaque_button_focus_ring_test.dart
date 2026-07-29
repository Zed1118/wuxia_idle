import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';

/// [PlaqueButton] 键盘焦点**可见落点**锁。
///
/// 立项背景(2026-07-30 桌面语义真机走查):`PlaqueButton` 有
/// `FocusableActionDetector(onShowFocusHighlight:)` + `if (_focused)` 金边环,
/// 实现看着对;但真机 Tab 走查(`shop_buy_confirm` 路由,确有两个真 PlaqueButton)
/// 按 Tab ×3 后**内容区零像素变化**,看不到任何落点。
///
/// 本测把「有焦点 → 必须画出金边环」钉死在 widget 层,用来区分
/// 「实现坏了」与「真机 highlightMode / 路由复刻件」的问题。
Finder goldRing() => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final d = w.decoration;
  if (d is! BoxDecoration) return false;
  final b = d.border;
  return b is Border && b.top.color == WuxiaUi.gold && b.top.width == 2;
});

void main() {
  setUp(() {
    // 桌面键盘导航语境:确保处于「传统高亮」模式,否则
    // onShowFocusHighlight 即使拿到焦点也不会回调 true。
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  Widget host({bool autofocus = false}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: PlaqueButton(label: '购买', autofocus: autofocus, onTap: () {}),
      ),
    ),
  );

  testWidgets('无焦点时不画金边环', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(goldRing(), findsNothing);
  });

  testWidgets('autofocus 拿到焦点 → 画出金边环(键盘落点可见)', (tester) async {
    await tester.pumpWidget(host(autofocus: true));
    await tester.pumpAndSettle();
    expect(goldRing(), findsOneWidget, reason: '有键盘焦点却不画金边环 = 桌面玩家看不见落点');
  });

  testWidgets('Tab traversal 拿到焦点 → 画出金边环', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(goldRing(), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(goldRing(), findsOneWidget, reason: 'Tab 走查后应有可见落点');
  });

  testWidgets('失焦后金边环撤掉', (tester) async {
    await tester.pumpWidget(host(autofocus: true));
    await tester.pumpAndSettle();
    expect(goldRing(), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(goldRing(), findsNothing);
  });
}
