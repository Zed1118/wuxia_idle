import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_title_bar.dart';

Color? _textColor(WidgetTester t, String s) =>
    t.widget<Text>(find.text(s)).style?.color;

Widget wrap(Widget c) => MaterialApp(home: Material(child: c));

// 标题文字（原 WuxiaUi.ink）读所在面板 surface.primary；返回/主菜单箭头为
// jiang 强调色，不迁移。showSeal/showHome 关掉避免 asset/tooltip 噪音。
const _component = WuxiaTitleBar(
  title: '标题',
  showSeal: false,
  showHome: false,
);

void main() {
  testWidgets('浅底标题取 ink', (t) async {
    await t.pumpWidget(wrap(const LightPaperPanel(child: _component)));
    expect(_textColor(t, '标题'), WuxiaUi.ink);
  });

  testWidgets('深底标题取 textPrimary', (t) async {
    await t.pumpWidget(wrap(const DarkParchmentPanel(child: _component)));
    expect(_textColor(t, '标题'), WuxiaColors.textPrimary);
  });
}
