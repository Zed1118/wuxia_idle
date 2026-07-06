import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_title_bar.dart';

Color? _textColor(WidgetTester t, String s) =>
    t.widget<Text>(find.text(s)).style?.color;

Widget wrap(Widget c) => MaterialApp(home: Material(child: c));

// 顶栏自带固定浅色纸渐变底并 provide 自身 PanelSurface.light，标题恒读 light
// surface → 恒深墨 ink，不随外层面板翻转。故两个 case（外浅/外深）都断言 ink。
// 返回/主菜单箭头为 jiang 强调色，不迁移。showSeal/showHome 关掉避免噪音。
const _component = WuxiaTitleBar(
  title: '标题',
  showSeal: false,
  showHome: false,
);

void main() {
  testWidgets('外层浅面板标题取 ink', (t) async {
    await t.pumpWidget(wrap(const LightPaperPanel(child: _component)));
    expect(_textColor(t, '标题'), WuxiaUi.ink);
  });

  testWidgets('外层深面板标题仍取 ink（恒浅底不翻转）', (t) async {
    await t.pumpWidget(wrap(const DarkParchmentPanel(child: _component)));
    expect(_textColor(t, '标题'), WuxiaUi.ink);
  });
}
