import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/stage_progress_row.dart';

Color? _textColor(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;

void main() {
  Widget row() => const StageProgressRow(
      ratio: 0.5, stageName: '小成', nextEffect: '下一阶 ×2.0');

  testWidgets('nextEffect 浅底取 jiang', (t) async {
    await t.pumpWidget(
      MaterialApp(home: Material(child: LightPaperPanel(child: row()))),
    );
    expect(_textColor(t, '下一阶 ×2.0'), WuxiaUi.jiang);
  });
  testWidgets('nextEffect 深底取 gold', (t) async {
    await t.pumpWidget(
      MaterialApp(home: Material(child: DarkParchmentPanel(child: row()))),
    );
    expect(_textColor(t, '下一阶 ×2.0'), WuxiaUi.gold);
  });
}
