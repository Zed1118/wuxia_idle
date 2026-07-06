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
  test('updateShouldNotify 按三色比较', () {
    const child = SizedBox.shrink();
    const base = PanelSurface(
        primary: Color(0xFF111111),
        secondary: Color(0xFF222222),
        accent: Color(0xFF333333),
        child: child);
    const same = PanelSurface(
        primary: Color(0xFF111111),
        secondary: Color(0xFF222222),
        accent: Color(0xFF333333),
        child: child);
    const diffAccent = PanelSurface(
        primary: Color(0xFF111111),
        secondary: Color(0xFF222222),
        accent: Color(0xFF999999),
        child: child);
    expect(base.updateShouldNotify(same), isFalse);
    expect(base.updateShouldNotify(diffAccent), isTrue);
  });
}
