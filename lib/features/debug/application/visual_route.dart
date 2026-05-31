/// 出版美术视觉验收的目标验收点。每个值对应一个 (seed + screen) 组合,
/// 由 `--dart-define=VISUAL_ROUTE=<id>` 在 debug 启动时选中。
enum VisualRoute {
  mainMenu('main_menu', '主菜单(出版美术门面 bg + 题字 + 木牌)'),
  techniquePanelTierAll(
      'technique_panel_tier_all', '心法面板·武圣满学 7 阶 cover 同屏(梯度验收)'),
  techniquePanelHero('technique_panel_hero', '心法面板·主修 hero 打坐内丹态'),
  sectScreenNpc(
      'sect_screen_npc', 'sect_screen·成员立绘验收(祖师 + 6 sect_candidate 完整显)');

  const VisualRoute(this.id, this.label);

  /// dart-define 用的稳定字符串标识。
  final String id;

  /// 人读说明,进 manifest 供读图对照。
  final String label;
}

/// 纯函数:id 字符串 → 枚举,未知/空 → null。便于单测。
VisualRoute? parseVisualRoute(String raw) {
  for (final r in VisualRoute.values) {
    if (r.id == raw) return r;
  }
  return null;
}

/// 读 `--dart-define=VISUAL_ROUTE=<id>`。未传/未知 → null。
VisualRoute? visualRouteFromEnv() {
  const raw = String.fromEnvironment('VISUAL_ROUTE');
  return parseVisualRoute(raw);
}
