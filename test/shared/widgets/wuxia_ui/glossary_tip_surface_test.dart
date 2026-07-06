import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/glossary_tip.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';

Color? _textColor(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Material(child: child));

  // GlossaryLabel 的「?」标记直接排在父面板纸底上（inline），默认色随所在
  // 面板底翻转取次要色：浅底 → WuxiaUi.muted，深底 → WuxiaColors.textSecondary。
  const mk = GlossaryLabel.marker;

  testWidgets('浅底：marker 取 secondary(muted)', (t) async {
    await t.pumpWidget(
      wrap(
        const LightPaperPanel(
          child: GlossaryLabel(label: '内力', definition: '内功修为'),
        ),
      ),
    );
    expect(_textColor(t, mk), WuxiaUi.muted);
  });

  testWidgets('深底：marker 取 secondary(textSecondary)', (t) async {
    await t.pumpWidget(
      wrap(
        const DarkParchmentPanel(
          child: GlossaryLabel(label: '内力', definition: '内功修为'),
        ),
      ),
    );
    expect(_textColor(t, mk), WuxiaColors.textSecondary);
  });

  testWidgets('显式 markerColor 优先于 surface', (t) async {
    await t.pumpWidget(
      wrap(
        const DarkParchmentPanel(
          child: GlossaryLabel(
            label: '内力',
            definition: '内功修为',
            markerColor: WuxiaUi.gold,
          ),
        ),
      ),
    );
    expect(_textColor(t, mk), WuxiaUi.gold);
  });
}
