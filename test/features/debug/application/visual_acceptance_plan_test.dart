import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/visual_acceptance_plan.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

void main() {
  test('smoke suite 固定覆盖核心视觉 route', () {
    final ids = visualAcceptanceRouteIds(VisualAcceptanceSuite.smoke);

    expect(ids.first, 'main_menu');
    expect(
      ids,
      containsAllInOrder([
        'main_menu',
        'inventory',
        'battle_scene',
        'technique_panel_tier_all',
        'shop',
        'seclusion_map_list',
        'tower_floor_list',
        'zangjuange',
        'encounter_codex',
        'skill_codex',
      ]),
    );
  });

  test('full suite 覆盖全部可直达 route,排除 hub', () {
    final ids = visualAcceptanceRouteIds(VisualAcceptanceSuite.full);
    final expected = VisualRoute.values
        .where((r) => r != VisualRoute.hub)
        .map((r) => r.id)
        .toList();

    expect(ids, expected);
    expect(ids, isNot(contains(VisualRoute.hub.id)));
    expect(ids, contains(VisualRoute.taohuaIsland.id));
    expect(ids, contains(VisualRoute.recruitmentDialog.id));
  });

  test('checklist 输出 route、seed、截图命令', () {
    final markdown = visualAcceptanceChecklistMarkdown(
      VisualAcceptanceSuite.smoke,
    );

    expect(markdown, contains('suite: `smoke`'));
    expect(markdown, contains('seed: `$visualAcceptanceSeed`'));
    expect(markdown, contains('tools/visual_capture/visual_capture.sh'));
    expect(markdown, contains('1440x900'));
    expect(markdown, contains('2560x1080'));
    expect(markdown, contains('`main_menu`'));
    expect(markdown, contains('主菜单入口可见'));
  });
}
