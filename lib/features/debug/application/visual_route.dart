/// 出版美术视觉验收的目标验收点。每个值对应一个 (seed + screen) 组合,
/// 由 `--dart-define=VISUAL_ROUTE=<id>` 在 debug 启动时选中。
enum VisualRoute {
  mainMenu('main_menu', '主菜单(出版美术门面 bg + 题字 + 木牌)'),
  techniquePanelTierAll(
      'technique_panel_tier_all', '心法面板·武圣满学 7 阶 cover 同屏(梯度验收)'),
  techniquePanelHero('technique_panel_hero', '心法面板·主修 hero 打坐内丹态'),
  sectScreenNpc(
      'sect_screen_npc', 'sect_screen·成员立绘验收(祖师 + 6 sect_candidate 完整显)'),
  characterPanelProfile('character_panel',
      '角色页·档案头验收(祖师立绘 + 姓名/境界/流派/4 属性档案卡 + Tab 切弟子立绘)'),
  chapterList('chapter_list',
      '章节列表·封面接线验收(章节卡顶部封面条 + 锁章调暗 · 图未到位 errorBuilder 兜底)'),
  battleScene('battle_scene',
      '战斗屏·背景 scrim + 胜负仪式验收(seed 3v3 带背景,自动播放到胜负 overlay)'),
  battleUltimateCaption('battle_ultimate_caption',
      '战斗屏·大招题字静态验收(玩家暖金 + 敌方绛红 两态)'),
  battleBossFrame('battle_boss_frame',
      '战斗屏·Boss 头像金色加粗边框验收(scenarioBoss 右队首位 Boss)'),
  enemyGallery('enemy_gallery',
      '敌人立绘 gallery·全敌人圆形头像滚动验收(buildEnemyTeam 真转换 + CharacterAvatar)'),
  equipmentDetailGallery('equipment_detail_gallery',
      '装备 detail gallery·全 detailPath 大图滚动验收(按阶排序,含神物 contain 显示)'),
  narrativeScene('narrative_scene',
      '剧情阅读屏·专属背景图 + scrim + 正文浮层验收(stage_01_05 风雨渡口)'),
  inventory('inventory',
      '仓库·装备格子化(部位分组武器/护甲/饰品 + tier 边框 + 强化徽章 + 师承标 + 境界锁灰化)'),
  hub('hub',
      '验收总入口·build 一次列出全部路由按钮点选(免每路由重 build,Codex 加速)');

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
