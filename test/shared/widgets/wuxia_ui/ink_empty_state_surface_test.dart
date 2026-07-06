import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/ink_empty_state.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';

Color? _textColor(WidgetTester t, String s) =>
    t.widget<Text>(find.text(s)).style?.color;

Widget wrap(Widget c) => MaterialApp(home: Material(child: c));

// 本组件唯一随底色翻转的文字是副描述 body（原 ink2 → surface.secondary）；
// 主标题走 variant 强调色（qing/jiang/muted），非 ink，不迁移。
const _component = InkEmptyState(
  variant: InkEmptyStateVariant.empty,
  title: '标题',
  body: '副描述内容',
  showFrame: false,
);

void main() {
  testWidgets('浅底副描述取 muted', (t) async {
    await t.pumpWidget(wrap(const LightPaperPanel(child: _component)));
    expect(_textColor(t, '副描述内容'), WuxiaUi.muted);
  });

  testWidgets('深底副描述取 textSecondary', (t) async {
    await t.pumpWidget(wrap(const DarkParchmentPanel(child: _component)));
    expect(_textColor(t, '副描述内容'), WuxiaColors.textSecondary);
  });
}
