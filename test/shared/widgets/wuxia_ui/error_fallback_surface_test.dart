import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/error_fallback.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';

Color? _textColor(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Material(child: child));

  const msg = '载入失败提示';

  // ErrorFallback 总把内容渲染在自带的 LightPaperPanel（恒浅宣纸底）上，
  // 故提示文字读的是内层浅底 surface，两种外层面板下都应取深墨 ink，
  // 不随外层翻白（否则深色面板里会出现白字压在自带浅纸上，对比度崩）。
  testWidgets('浅底外层：提示文字取 ink', (t) async {
    await t.pumpWidget(
      wrap(const LightPaperPanel(child: ErrorFallback(message: msg))),
    );
    expect(_textColor(t, msg), WuxiaUi.ink);
  });

  testWidgets('深底外层：提示文字仍取 ink（自带浅纸底）', (t) async {
    await t.pumpWidget(
      wrap(const DarkParchmentPanel(child: ErrorFallback(message: msg))),
    );
    expect(_textColor(t, msg), WuxiaUi.ink);
  });
}
