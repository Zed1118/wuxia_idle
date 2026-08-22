import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

void main() {
  test('每个生产视觉 route id 均可稳定反解', () {
    for (final route in VisualRoute.values) {
      expect(parseVisualRoute(route.id), route, reason: route.id);
    }
  });

  test('未知或空 route id 返回 null', () {
    expect(parseVisualRoute(''), isNull);
    expect(parseVisualRoute('battle_scene'), isNull);
    expect(parseVisualRoute('battle_v2_neutral_3v3'), isNull);
    expect(parseVisualRoute('battle_tap_live'), isNull);
    expect(parseVisualRoute('nope'), isNull);
  });

  test('Phase 0A 七个目检/采样入口完整且不含旧 3v3 命名', () {
    final ids = VisualRoute.values
        .where((route) => route.name.startsWith('phase0aBattle'))
        .map((route) => route.id)
        .toList();

    expect(ids, <String>[
      'phase0a_battle_playable',
      'phase0a_battle_profile',
      'phase0a_battle_attack_feedback',
      'phase0a_battle_gather_feedback',
      'phase0a_battle_clear_feedback',
      'phase0a_battle_boss_mechanics',
      'phase0a_battle_guardian_mechanics',
    ]);
    expect(ids.join(','), isNot(contains('3v3')));
  });

  test('路由语义类型覆盖生产壳、组件、图册与瞬时浮层', () {
    expect(
      VisualRoute.values.map((route) => route.kind).toSet(),
      containsAll(VisualRouteKind.values),
    );
    expect(VisualRoute.splash.kind, VisualRouteKind.productionShell);
    expect(VisualRoute.redlineAudit.kind, VisualRouteKind.component);
    expect(VisualRoute.equipmentDetailGallery.kind, VisualRouteKind.gallery);
    expect(
      VisualRoute.settingsPanelDisabled.kind,
      VisualRouteKind.transientOverlay,
    );
  });
}
