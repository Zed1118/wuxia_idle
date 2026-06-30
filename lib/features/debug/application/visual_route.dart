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
  battleDefeat('battle_defeat', '战斗屏·败北页验收(敗 题字 + 败北 + 破招提示 + 战报,战场背景上结算)'),
  defeatInnerDemonResidue(
    'defeat_inner_demon_residue',
    'M6 心魔关战败损失摘要·余毒未消段排版验收(战败剧情屏顶 banner:混合「含主修最长行」+「仅内力」两条余毒 entry,验内力段·修炼度回退段·余毒未消段拼接换行)',
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
  towerCycle('tower_cycle', '爬塔·问鼎轮回验收(通关 30 层 cycle1 → 显当前轮回 + 挑战下一轮回入口)'),
  battleDragLive(
    'battle_drag_live',
    '拖招交互真玩/验收(真战斗·已开干预·高血耐久敌久撑 → 长按拖 single 强力技到敌头像指定 + aoe 大招拖动松手即对全体触发)',
  ),
  battleDragPreview(
    'battle_drag_preview',
    '拖招表现层静态验收(冻结画面预置态·Codex 截图:引导线外发光+末端白心 / 蓄势呼吸脉动光晕(截帧) / 悬停敌头像浅金高亮)',
  ),
  offlineRecapPassive(
    'offline_recap_passive',
    'M2 离线被动归来卡静态验收(无 active 闭关·涓流入库告知卡:水墨 PaperPanel + 离线时长/磨剑石/经验 + 仅「知道了」按钮,无领取按钮守 §5.1)',
  ),
  battleBossPhase(
    'battle_boss_phase',
    '第七阶段批二目检·真 stage_01_05 撑伞高人 Boss(HP抬高)vs at-level 玩家队真玩:跌破50%背水一击转阶段+蓄力反扑 / 刚猛打弱点会心×1.25 / 灵巧吃抗性×0.75(已开干预层可拖招)',
  ),
  discipleJoinCeremony(
    'disciple_join_ceremony',
    '第七阶段批三目检·拜入立绘题字 overlay 动效(读真 lineage_onboarding 配置:大弟子/二弟子真立绘交替循环滑入+放大+「XX 拜入门下」题字,自动重播;单帧截不出须真机看动效)',
  ),
  heroCamera(
    'hero_camera',
    '第七阶段批一目检·Boss 首胜英雄镜头 overlay 动效(祖师真立绘 + 真 stage_01_05 Boss 名「击破 XX」题字,从右滑入+放大,自动重播;单帧截不出须真机看动效。生产仅 Boss 首胜触发,故走此专属路由验)',
  ),
  battleRecord(
    'battle_record',
    'P4 战绩册主屏目检·已击败纪念卡 + 未击败剩影占位混合态(种 2-3 条纪念,其余 27 槽显剩影)',
  ),
  bossMemoryDetail(
    'boss_memory_detail',
    'P4 战绩册详情屏目检·完整纪念(伤害/英雄/掉落/阵容) + pre-record 骨架(此役不详)两态',
  ),
  weaponCodex('weapon_codex', '兵器谱主屏目检·混合态(点亮/回填/剪影三态混排 + slot 筛选 + 分档进度)'),
  weaponCodexDetail(
    'weapon_codex_detail',
    '兵器谱详情屏目检·正常态(器物档案 + 个人历程 + 首得来源/日期)',
  ),
  lineageCodex('lineage_codex', '门派谱主屏目检·世代卷(进度头 + 祖师卡 + 门人 + 师承遗物 + 屏底飞升入口)'),
  lineageCharacterDetail(
    'lineage_character_detail',
    '门派谱角色详情屏目检·祖师态(纪事 + 资质四项 + 主修 + 所持遗物 + 祖师恩泽)',
  ),
  shop(
    'shop',
    '江湖商店主屏目检·种银两80(够磨剑石30两·不够心血结晶120):货币顶栏 + 固定货架分类 + 磨剑石可买(绿)/心血结晶不可买(红 disabled)两态',
  ),
  shopBuyConfirm(
    'shop_buy_confirm',
    '商店购买确认弹窗打开态目检·真 ShopScreen 货架为背景 + 暗幕 + 复刻 _handleBuy 的 PaperDialog 确认弹窗(磨剑石 ×1 · 定价取真 def · 取消/购买木牌),冻结在弹窗打开态(静态截动态确认态)',
  ),
  inventoryCurrency(
    'inventory_currency',
    '背包货币位目检·种银两+磨剑石+心血结晶,直开材料 tab:顶部货币位顶栏(银两X两) + 材料网格(磨剑石/心血结晶,银两不重复进网格)',
  ),
  mainMenuShop(
    'main_menu_shop',
    '主菜单商店入口目检·种银两解锁:验「江湖商店」隐藏式入口木牌出现(§5.7,沿兵器谱体例)',
  ),
  itemUseInventory(
    'item_use_inventory',
    'P2 材料用途目检·背包物料 tab 直开:种经验丹三档(凝神/培元/大还,验 per-item 名不同)+ 秘籍(开碑手)+ 磨剑石,验丹/秘籍显「使用」按钮·磨剑石无按钮(仅可用道具显),点使用→确认弹窗→结果三态浮层',
  ),
  itemUseConfirmDialog(
    'item_use_confirm_dialog',
    '道具使用确认弹窗打开态目检·真 InventoryScreen 物料 tab 为背景 + 暗幕 + 复刻 _onUse 的 PaperDialog 使用确认弹窗(凝神丹 · 道具名取真 ItemDef · 取消/使用木牌),冻结在弹窗打开态(静态截动态确认态)',
  ),
  taohuaIsland(
    'taohua_island',
    '桃花岛主屏目检·建筑热区 + 生产队列 + 建筑志入口 + 空/错/loading 统一体例',
  ),
  recruitmentDialog('recruitment_dialog', '收徒页目检·候选卡 + 拜师/谢绝确认弹窗按钮水墨体例'),
  encounterCodex('encounter_codex', '奇遇录 tab 目检·混态(点亮+剪影 3 段分组 + 进度)'),
  encounterCodexDetail(
    'encounter_codex_detail',
    '奇遇录详情屏目检·回看 opening 故事 + 类型标',
  ),
  skillCodex('skill_codex', '武学图鉴 tab 目检·混态(点亮+剪影按来源5组+心法小节+进度)'),
  skillCodexDetail(
    'skill_codex_detail',
    '武学详情屏目检·同步显招名+description+数值+所属心法+熟练阶',
  ),
  skillCodexLockedSnackbar(
    'skill_codex_locked_snackbar',
    '武学图鉴点剪影未解锁 snackbar 态目检·真混态图鉴(前6点亮+其余剪影)为背景,post-frame 触发与 _SilhouetteRow 一致的 ScaffoldMessenger snackbar「尚未习得」(守 §5.7 不泄解锁条件,延长 duration 驻留供截图)',
  ),
  zangjuange('zangjuange', '藏卷阁 Hub 目检·战绩册/兵器谱/奇遇录/藏经阁聚合入口 + 卷中线索'),
  redlineAudit('redline_audit', '数值红线审计·开发工具视图(PASS/WARN/FAIL + 当前最大值 + 来源)'),
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
