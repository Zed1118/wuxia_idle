import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/dark_parchment_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/light_paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/panel_surface.dart';

void main() {
  testWidgets('LightPaperPanel 向下 provide light surface', (t) async {
    late PanelSurface s;
    await t.pumpWidget(MaterialApp(home: LightPaperPanel(
      child: Builder(builder: (c) { s = PanelSurface.of(c); return const SizedBox(); }))));
    expect(s.primary, WuxiaUi.ink);
    expect(s.accent, WuxiaUi.jiang);
  });
  testWidgets('DarkParchmentPanel 向下 provide dark surface', (t) async {
    late PanelSurface s;
    await t.pumpWidget(MaterialApp(home: DarkParchmentPanel(
      child: Builder(builder: (c) { s = PanelSurface.of(c); return const SizedBox(); }))));
    expect(s.primary, WuxiaColors.textPrimary);
    expect(s.accent, WuxiaUi.gold);
  });
}
