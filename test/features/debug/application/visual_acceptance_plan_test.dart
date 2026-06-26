import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/visual_acceptance_plan.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

void main() {
  test('smoke suite 固定覆盖核心视觉 route', () {
    expect(visualAcceptanceRouteIds(VisualAcceptanceSuite.smoke), [
      'main_menu',
      'technique_panel_tier_all',
      'technique_panel_hero',
      'battle_charge_break',
      'battle_interrupt_caption',
      'battle_defeat',
    ]);
  });

  test('full suite 覆盖全部可直达 route,排除 hub', () {
    final ids = visualAcceptanceRouteIds(VisualAcceptanceSuite.full);
    final expected = VisualRoute.values
        .where((r) => r != VisualRoute.hub)
        .map((r) => r.id)
        .toList();

    expect(ids, expected);
    expect(ids, isNot(contains(VisualRoute.hub.id)));
  });

  test('checklist 输出 route、seed、截图命令', () {
    final markdown = visualAcceptanceChecklistMarkdown(
      VisualAcceptanceSuite.smoke,
    );

    expect(markdown, contains('suite: `smoke`'));
    expect(markdown, contains('seed: `$visualAcceptanceSeed`'));
    expect(markdown, contains('tools/visual_capture/visual_capture.sh'));
    expect(markdown, contains('`main_menu`'));
    expect(markdown, contains('主菜单入口可见'));
  });
}
