import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/panel_surface.dart';

void main() {
  testWidgets('light 工厂角色值', (t) async {
    late PanelSurface s;
    await t.pumpWidget(PanelSurface.light(
      child: Builder(builder: (c) { s = PanelSurface.of(c); return const SizedBox(); })));
    expect(s.primary, WuxiaUi.ink);
    expect(s.secondary, WuxiaUi.muted);
    expect(s.accent, WuxiaUi.jiang);
  });
  testWidgets('dark 工厂角色值', (t) async {
    late PanelSurface s;
    await t.pumpWidget(PanelSurface.dark(
      child: Builder(builder: (c) { s = PanelSurface.of(c); return const SizedBox(); })));
    expect(s.primary, WuxiaColors.textPrimary);
    expect(s.secondary, WuxiaColors.textSecondary);
    expect(s.accent, WuxiaUi.gold);
  });
  testWidgets('无 ancestor 兜底 light', (t) async {
    late PanelSurface s;
    await t.pumpWidget(Builder(builder: (c) { s = PanelSurface.of(c); return const SizedBox(); }));
    expect(s.primary, WuxiaUi.ink);
    expect(PanelSurface.maybeOf(t.element(find.byType(SizedBox))), isNull);
  });
}
