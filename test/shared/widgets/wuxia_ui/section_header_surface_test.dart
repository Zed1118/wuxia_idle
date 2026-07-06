import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/section_header.dart';

Color? _textColor(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Material(child: child));

  testWidgets('浅底标题取 ink', (t) async {
    await t.pumpWidget(wrap(const LightPaperPanel(child: SectionHeader('分段标题'))));
    expect(_textColor(t, '分段标题'), WuxiaUi.ink);
  });

  testWidgets('深底标题取 textPrimary', (t) async {
    await t.pumpWidget(
      wrap(const DarkParchmentPanel(child: SectionHeader('分段标题'))),
    );
    expect(_textColor(t, '分段标题'), WuxiaColors.textPrimary);
  });
}
