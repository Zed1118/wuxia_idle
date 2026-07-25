import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/visual_acceptance_plan.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

void main() {
  test('smoke suite 固定覆盖核心视觉 route', () {
    final ids = visualAcceptanceRouteIds(VisualAcceptanceSuite.smoke);

    expect(ids.first, 'splash');
    expect(
      ids,
      containsAllInOrder([
        'splash',
        'save_select_empty',
        'save_select_filled',
        'main_menu_clean',
        'main_menu',
        'settings_panel',
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
    expect(
      ids,
      containsAll(<String>[
        'battle_v2_casualty_replacement',
        'battle_v2_fast_forward_peak',
        'battle_v2_pre_result',
        'battle_v2_neutral_3v3',
        'battle_v2_resource_pressure',
      ]),
    );
  });

  test('battle suite 覆盖70动态战斗与5个V2确定性状态', () {
    final ids = visualAcceptanceRouteIds(VisualAcceptanceSuite.battle);

    expect(ids, hasLength(75));
    expect(ids.toSet(), hasLength(75));
    expect(ids.first, 'battle_audit_stage_01_01');
    expect(ids, contains('battle_audit_stage_06_05'));
    expect(ids, contains('battle_audit_tower_01'));
    expect(ids, contains('battle_audit_tower_30'));
    expect(ids, contains('battle_audit_stage_light_foot_05'));
    expect(ids, contains('battle_audit_stage_mass_battle_05'));
    expect(ids.sublist(ids.length - 5), <String>[
      'battle_v2_casualty_replacement',
      'battle_v2_fast_forward_peak',
      'battle_v2_pre_result',
      'battle_v2_neutral_3v3',
      'battle_v2_resource_pressure',
    ]);
    for (final id in ids) {
      expect(parseVisualRoute(id), isNotNull, reason: id);
    }
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
    expect(markdown, contains('`splash`'));
    expect(markdown, contains('`save_select_filled`'));
    expect(markdown, contains('`main_menu_clean`'));
    expect(markdown, contains('`settings_panel`'));
    expect(markdown, contains('浅宣纸上的标题'));
  });
}
