/// 出版美术视觉验收的目标验收点。每个值对应一个 (seed + screen) 组合,
/// 由 `--dart-define=VISUAL_ROUTE=<id>` 在 debug 启动时选中。
enum VisualRoute {
  mainMenu('main_menu', '主菜单(出版美术门面 bg + 题字 + 木牌)'),
  techniquePanelTierAll(
    'technique_panel_tier_all',
    '心法面板·武圣满学 7 阶 cover 同屏(梯度验收)',
  ),
  techniquePanelHero('technique_panel_hero', '心法面板·主修 hero 打坐内丹态'),
  techniqueRefineInsightDialog(
    'technique_refine_insight_dialog',
    '心法凝练·领悟点凝入主修小帖验收',
  ),
  encounterOutcomeSkillBanner(
    'encounter_outcome_skill_banner',
    '奇遇 outcome·灵光一现领悟新招小帖验收',
  ),
  sectScreenNpc(
    'sect_screen_npc',
    'sect_screen·成员立绘验收(祖师 + 6 sect_candidate 完整显)',
  ),
  characterPanelProfile(
    'character_panel',
    '角色页·档案头验收(祖师立绘 + 姓名/境界/流派/4 属性档案卡 + Tab 切弟子立绘)',
  ),
  characterPanelGrowth(
    'character_panel_growth',
    '角色页·心魔成长瓶颈(武圣 exp满被拦 → 心魔 2/7 面板 + 突破 CTA + 主修 hero)',
  ),
  chapterList(
    'chapter_list',
    '章节列表·封面接线验收(章节卡顶部封面条 + 锁章调暗 · 图未到位 errorBuilder 兜底)',
  ),
  stageList('stage_list', '主线章内行程·5 关路径 + Boss 节点 + 原进入关卡流程验收'),
  stageListAutoPlay(
    'stage_list_autoplay',
    '主线选关·per-stage 自动/手动开关验收(01_01 跟随=自动随设置 / 01_02 pin 手动 / 点开三选项菜单)',
  ),
  towerFloorList(
    'tower_floor_list',
    '爬塔列表·塔势概览验收(30 层横向节点 + Boss 小/大标记 + 原列表保留)',
  ),
  towerFloorListAutoPlay(
    'tower_floor_list_autoplay',
    '爬塔·per-floor 自动/手动开关验收(1/2 层通关+录记录 → 点已通关层弹重打 dialog,内含 enabled 开关:1 层跟随=自动随设置 / 2 层 pin 手动 / 点开三选项菜单)',
  ),
  seclusionMapList('seclusion_map_list', '闭关地图·5 地点图册验收(地图大图 + 解锁/产出/进行中状态)'),
  seclusionSetup('seclusion_setup', '闭关准备·地点 hero + 产出预览 + 时长驻留牌验收'),
  seclusionActive('seclusion_active', '闭关中·地图背景 + 宣纸进度面板 + 收功按钮验收'),
  seclusionResult('seclusion_result', '闭关收功·地图战报 + 5 维收益 + 提示/突破区验收'),
  battleScene(
    'battle_scene',
    '战斗屏·背景 scrim + 胜负仪式验收(seed 3v3 带背景,自动播放到胜负 overlay)',
  ),
  battleUltimateCaption(
    'battle_ultimate_caption',
    '战斗屏·大招题字静态验收(玩家暖金 + 敌方绛红 两态)',
  ),
  battleBossFrame(
    'battle_boss_frame',
    '战斗屏·Boss 头像金色加粗边框验收(scenarioBoss 右队首位 Boss)',
  ),
  battleChargeBreak(
    'battle_charge_break',
    '战斗屏·青衫剑客蓄力青锋绝 + 玩家破招按钮高亮(静态验收破招 UI)',
  ),
  battleVictoryFirstClear(
    'battle_victory_first_clear',
    '胜利弹窗·Boss 首胜封签 + 掉落/升层/共鸣三段验收',
  ),
  enemyGallery(
    'enemy_gallery',
    '敌人立绘 gallery·全敌人圆形头像滚动验收(buildEnemyTeam 真转换 + CharacterAvatar)',
  ),
  equipmentDetailScreen(
    'equipment_detail_screen',
    '装备详情页·水墨包装验收(神物天问剑 + 共鸣/强化/典故)',
  ),
  equipmentDetailGallery(
    'equipment_detail_gallery',
    '装备 detail gallery·全 detailPath 大图滚动验收(按阶排序,含神物 contain 显示)',
  ),
  narrativeScene(
    'narrative_scene',
    '剧情阅读屏·专属背景图 + scrim + 正文浮层验收(stage_01_05 风雨渡口)',
  ),
  inventory(
    'inventory',
    '仓库·装备格子化(部位分组武器/护甲/饰品 + tier 边框 + 强化徽章 + 师承标 + 境界锁灰化)',
  ),
  battleInterruptCaption(
    'battle_interrupt_caption',
    '战斗屏·破招「破！」题字静态验收(破招方暖金 + 敌方绛红 两态)',
  ),
  battleDefeat(
    'battle_defeat',
    '战斗屏·败北页验收(敗 题字 + 败北 + 破招提示 + 战报,战场背景上结算)',
  ),
  battleTreasureGlowPeak(
    'battle_treasure_glow_peak',
    '爆品·神物金光峰值帧验收(t≈0.32 金闪迸发 + 双环涟漪 + 辉光升起,验是否太抢)',
  ),
  battleTreasureGlowRest(
    'battle_treasure_glow_rest',
    '爆品·神物金光末态验收(t=1.0 辉光驻留,验是否 wash out 盖住内容)',
  ),
  battleTreasureZhongqi(
    'battle_treasure_zhongqi',
    '爆品·重器对比验收(青虚剑,tier-gate 神物专属金光不启用)',
  ),
  stageListCycle(
    'stage_list_cycle',
    '主线选关·章层周目控件 + 拖招真关卡入口(整章 Ch1 cycle1 全通 → 章头显周目控件;点 tile 进真战斗验纯自动流+拖招)',
  ),
  towerCycle(
    'tower_cycle',
    '爬塔·问鼎轮回验收(通关 30 层 cycle1 → 显当前轮回 + 挑战下一轮回入口)',
  ),
  hub('hub', '验收总入口·build 一次列出全部路由按钮点选(免每路由重 build,Codex 加速)');

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
