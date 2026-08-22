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
        'settings_panel_bottom',
        'settings_panel_disabled',
        'inventory',
        'phase0a_battle_playable',
        'phase0a_battle_boss_mechanics',
        'phase0a_battle_guardian_mechanics',
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

  test('route metadata 区分生产壳、组件、图册与瞬时浮层', () {
    final routes = visualAcceptanceRoutes(VisualAcceptanceSuite.full);

    expect(VisualRoute.splash.kind, VisualRouteKind.productionShell);
    expect(VisualRoute.saveSelectFilled.kind, VisualRouteKind.productionShell);
    expect(VisualRoute.redlineAudit.kind, VisualRouteKind.component);
    expect(VisualRoute.equipmentDetailGallery.kind, VisualRouteKind.gallery);
    expect(
      VisualRoute.settingsPanelDisabled.kind,
      VisualRouteKind.transientOverlay,
    );
    expect(
      VisualRoute.offlineRecapActive.kind,
      VisualRouteKind.transientOverlay,
    );
    expect(
      routes.map((target) => target.kind).toSet(),
      containsAll(VisualRouteKind.values),
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
        'phase0a_battle_playable',
        'phase0a_battle_attack_feedback',
        'phase0a_battle_gather_feedback',
        'phase0a_battle_clear_feedback',
        'phase0a_battle_boss_mechanics',
        'phase0a_battle_guardian_mechanics',
      ]),
    );
  });

  test('battle suite 仅覆盖六个 Phase 0A 确定性目检 route', () {
    final ids = visualAcceptanceRouteIds(VisualAcceptanceSuite.battle);

    expect(ids, <String>[
      'phase0a_battle_playable',
      'phase0a_battle_attack_feedback',
      'phase0a_battle_gather_feedback',
      'phase0a_battle_clear_feedback',
      'phase0a_battle_boss_mechanics',
      'phase0a_battle_guardian_mechanics',
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
    expect(markdown, contains('`settings_panel_bottom`'));
    expect(markdown, contains('`settings_panel_disabled`'));
    expect(markdown, contains('| route | kind | seed | checks |'));
    expect(markdown, contains('`transientOverlay`'));
    expect(markdown, contains('浅宣纸上的标题'));
  });
}
