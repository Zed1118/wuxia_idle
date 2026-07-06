import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_dialog.dart';

Color? _textColor(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Material(child: child));

  const title = '凯旋';

  // PaperDialog 内含自带的 LightPaperPanel（恒浅宣纸底），标题读自身内层
  // surface，无论外层面板深浅都取深墨 ink，不随外层翻白。
  testWidgets('浅底外层：标题取 ink', (t) async {
    await t.pumpWidget(
      wrap(
        const LightPaperPanel(
          child: PaperDialog(title: title, body: Text('正文'), actions: []),
        ),
      ),
    );
    expect(_textColor(t, title), WuxiaUi.ink);
  });

  testWidgets('深底外层：标题仍取 ink（自带浅纸底）', (t) async {
    await t.pumpWidget(
      wrap(
        const DarkParchmentPanel(
          child: PaperDialog(title: title, body: Text('正文'), actions: []),
        ),
      ),
    );
    expect(_textColor(t, title), WuxiaUi.ink);
  });
}
