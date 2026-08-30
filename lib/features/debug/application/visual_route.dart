/// 出版美术视觉验收的目标验收点。每个值对应一个 (seed + screen) 组合,
/// 由 `--dart-define=VISUAL_ROUTE=<id>` 在 debug 启动时选中。
enum VisualRoute {
  splash('splash', '启动闪屏·真实 SplashScreen 加载态(水墨渔舟 + 标题 + 展卷状态)'),
  saveSelectEmpty('save_select_empty', '存档选择·三槽皆空的首次启动生产屏'),
  saveSelectFilled('save_select_filled', '存档选择·最近存档 + 首周目完成 + 两个空槽混合生产屏'),
  mainMenu('main_menu', '主菜单(出版美术门面 bg + 题字 + 木牌)'),
  mainMenuClean('main_menu_clean', '主菜单·清洁首帧(无归来/闭关弹层污染的完整生产壳)'),
  settingsPanel(
    'settings_panel',
    '设置弹窗·真实 SettingsPanel.show 生产路径(浅宣纸组件对比 + 720p 滚动)',
  ),
  settingsPanelBottom(
    'settings_panel_bottom',
    '设置弹窗·真实生产单栏底部(存档管理 + 切换存档 + 关于 + 退出)',
  ),
  settingsPanelDisabled(
    'settings_panel_disabled',
    '设置弹窗·真实生产显示段(全屏开启 + 分辨率禁用态)',
  ),
  techniquePanelTierAll(
    'technique_panel_tier_all',
    '心法面板·武圣满学 7 阶分组头同屏(水墨文字头梯度验收)',
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
  towerFloorList(
    'tower_floor_list',
    '爬塔列表·塔势概览验收(30 层横向节点 + Boss 小/大标记 + 原列表保留)',
  ),
  seclusionMapList('seclusion_map_list', '闭关地图·5 地点图册验收(地图大图 + 解锁/产出/进行中状态)'),
  seclusionSetup('seclusion_setup', '闭关准备·地点 hero + 产出预览 + 无限时说明验收'),
  seclusionActive('seclusion_active', '闭关中·双阶段时长 + 装备节点 + 收功按钮验收'),
  seclusionResult('seclusion_result', '闭关收功·72h 闭关 + 接续挂机 + 装备节点验收'),
  phase0aBattlePlayable(
    'phase0a_battle_playable',
    'Phase 0A 单角色水墨 ARPG·真实 flow 键鼠可玩验收',
  ),
  phase0aBattleProfile(
    'phase0a_battle_profile',
    'Phase 0A 生产 Profile·同核 bot 循环负载与自动重开',
  ),
  phase0aBlackRidgeProfile(
    'phase0a_black_ridge_profile',
    'G2 黑风岭生产 Profile·真实 catalog/runtime binding/40 敌人/12 active 循环负载',
  ),
  phase0aM4DensityProfile(
    'phase0a_m4_density_profile',
    'M4 P09 群战 Profile fixture·真实生产屏/同核 reducer/24 active 循环负载',
  ),
  phase0aBattleAttackFeedback(
    'phase0a_battle_attack_feedback',
    'Phase 0A 单角色战斗·首拍 J 攻击反馈静态验收',
  ),
  phase0aBattleGatherFeedback(
    'phase0a_battle_gather_feedback',
    'Phase 0A 单角色战斗·首拍 Q 聚怪反馈静态验收',
  ),
  phase0aBattleClearFeedback(
    'phase0a_battle_clear_feedback',
    'Phase 0A 单角色战斗·首拍 R 清场反馈静态验收',
  ),
  phase0aBattleBossMechanics(
    'phase0a_battle_boss_mechanics',
    'Phase 0A Boss charge / break / stagger / vulnerability fixture',
  ),
  phase0aBattleGuardianMechanics(
    'phase0a_battle_guardian_mechanics',
    'Phase 0A guardian ward / intercept / coop visual fixture',
  ),
  equipmentDetailScreen(
    'equipment_detail_screen',
    '装备详情页·水墨包装验收(神物天问剑 + 共鸣/强化/典故)',
  ),
  equipmentDetailGallery(
    'equipment_detail_gallery',
    '装备 detail gallery·全 detailPath 大图滚动验收(按阶排序,含神物 contain 显示)',
  ),
  equipmentDetailRepairGallery(
    'equipment_detail_repair_gallery',
    '装备详情修复对照·断魂庄三件 icon/detail 双底色验收',
  ),
  equipmentDetailGauntletReward(
    'equipment_detail_gauntlet_reward',
    '装备详情生产屏·断魂庄锁脉囊专用详情图接线验收',
  ),
  narrativeScene(
    'narrative_scene',
    '剧情阅读屏·专属背景图 + scrim + 正文浮层验收(stage_01_05 风雨渡口)',
  ),
  inventory(
    'inventory',
    '仓库·装备格子化(部位分组武器/护甲/饰品 + tier 边框 + 强化徽章 + 师承标 + 境界锁灰化)',
  ),
  stageListCycle(
    'stage_list_cycle',
    '主线选关·章层周目控件 + 拖招真关卡入口(整章 Ch1 cycle1 全通 → 章头显周目控件;点 tile 进真战斗验纯自动流+拖招)',
  ),
  towerCycle('tower_cycle', '爬塔·问鼎轮回验收(通关 30 层 cycle1 → 显当前轮回 + 挑战下一轮回入口)'),
  offlineRecapActive(
    'offline_recap_active',
    'M2 闭关归来卡静态验收(active 闭关·长材料明细 +「稍后再说/前去收功」双操作)',
  ),
  offlineRecapPassive(
    'offline_recap_passive',
    'M2 离线被动归来卡静态验收(无 active 闭关·涓流入库告知卡:水墨 LightPaperPanel + 离线时长/磨剑石/经验 + 仅「知道了」按钮,无领取按钮守 §5.1)',
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
  resourceOverview('resource_overview', '资源总览目检·五类资源混合库存 + 来源/用途/近期去向一屏扫读'),
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
  taohuaBuildingPopup(
    'taohua_building_popup',
    '桃花岛产业弹窗目检·默认打开打造台操作菜单,验一屏信息与操作入口',
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
  founderCreation(
    'founder_creation',
    '祖师塑形创建页·确认区决策可逆说明验收(S1·深底 textMuted 提示行)',
  ),
  stageRetryDialog(
    'stage_retry_dialog',
    '普通关战败重试弹框·非教学化短诊断验收(S3·浅纸底 muted 提示行)',
  ),
  teamLineup('team_lineup', '出战编成屏目检·三席(前排标+梯度境界)+替补池三态(无标/境界偏低/闭关中),§十三 #4'),
  expeditionRecap(
    'expedition_recap',
    '百草岭远征返程行记目检·主动召回态(最深14处+奖获修为/药草/灵泉/银两+断魂帖×1里程碑高亮+1人负伤调息),§4.7',
  ),
  expeditionOverview(
    'expedition_overview',
    '江湖远行总览·派遣态目检(百草岭卡·候选多选[可派遣/在外/未修主修三态]+三方针择一+拔营出发),§7.1',
  ),
  expeditionActive(
    'expedition_active',
    '江湖远行·派遣中目检(在途态·当前深入第8处/已踏平节点/本次方针/下一节点剩余/召回队伍),§7.1',
  ),
  gauntletLoadout(
    'gauntlet_loadout',
    '断魂庄装载屏目检·帖库存×2 + 庄中三关(苏无咎/石镇岳/闻九针 + 推荐境界) + 择人1-3(占用/未修主修标) + 补给装载步进 + 持帖入庄,§7.1',
  ),
  gauntletLoadoutCycle(
    'gauntlet_loadout_cycle',
    '断魂庄装载屏·周目选择区目检(批 C:种已通 cycle1 → 选择区起显,cycle1 可选 + cycle2 境界门槛锁态;未通态由 gauntlet_loadout 覆盖),批 B §B5',
  ),
  expeditionOverviewCycle(
    'expedition_overview_cycle',
    '江湖远行总览·周目选择区目检(批 C:种 baicaoMaxDepth=25 达首里程碑 → 折算已通 cycle1 选择区起显;未达态由 expedition_overview 覆盖),批 B §B5',
  ),
  gauntletInterlude(
    'gauntlet_interlude',
    '断魂庄庄内整备目检·第2关整备(三成员生命/真气/阵亡/冷却) + 托管补给余量(疗伤丹余1/行囊补给余1) + 使用/继续闯关/认输离庄,§7.2',
  ),
  gauntletReward(
    'gauntlet_reward',
    '断魂庄通关三选一奖励目检·Boss 终关胜(awaitingRewardChoice) + 三件好家伙候选卡(名/阶/位/属性) + 首通全奖标 + 点选择取,§6.2',
  ),
  gauntletDefeat(
    'gauntlet_defeat',
    '断魂庄战败结算目检·已破 1 关精英经验 + 逐弟子轻重伤(沈青轻伤/楚河重伤) + 离庄,§6.3',
  ),
  hub('hub', '验收总入口·build 一次列出全部路由按钮点选(免每路由重 build,Codex 加速)');

  const VisualRoute(this.id, this.label);

  /// dart-define 用的稳定字符串标识。
  final String id;

  /// 人读说明,进 manifest 供读图对照。
  final String label;

  /// 需要由目标战斗状态控制 READY 的 V2 验收路由。
  bool get controlsReadiness => switch (this) {
    settingsPanel ||
    settingsPanelBottom ||
    settingsPanelDisabled ||
    phase0aBattleBossMechanics => true,
    _ => false,
  };

  /// 验收目标的语义类型。完整生产页面、局部组件、图册和瞬时浮层不能按
  /// 同一套标准评分，因此在 manifest 中显式区分。
  VisualRouteKind get kind {
    if (id.contains('gallery')) return VisualRouteKind.gallery;
    if (this == VisualRoute.redlineAudit || this == VisualRoute.hub) {
      return VisualRouteKind.component;
    }
    if (id.contains('dialog') ||
        id.contains('popup') ||
        id.contains('snackbar') ||
        id.contains('caption') ||
        this == VisualRoute.settingsPanel ||
        this == VisualRoute.settingsPanelBottom ||
        this == VisualRoute.settingsPanelDisabled ||
        this == VisualRoute.encounterOutcomeSkillBanner ||
        this == VisualRoute.offlineRecapActive ||
        this == VisualRoute.offlineRecapPassive ||
        this == VisualRoute.discipleJoinCeremony ||
        this == VisualRoute.heroCamera) {
      return VisualRouteKind.transientOverlay;
    }
    return VisualRouteKind.productionShell;
  }
}

enum VisualRouteKind { productionShell, component, gallery, transientOverlay }

/// 纯函数:id 字符串 → 枚举,未知/空 → null。便于单测。
VisualRoute? parseVisualRoute(String raw) {
  for (final r in VisualRoute.values) {
    if (r.id == raw) return r;
  }
  return null;
}

/// 保留 route 的完整 id，供 host 回报 READY。
String visualRouteIdFromEnv() {
  const raw = String.fromEnvironment('VISUAL_ROUTE');
  return raw;
}

/// 读 `--dart-define=VISUAL_ROUTE=<id>`。未传/未知 → null。
VisualRoute? visualRouteFromEnv() {
  const raw = String.fromEnvironment('VISUAL_ROUTE');
  return parseVisualRoute(raw);
}

/// 预构建 macOS 验收包可用运行时参数切 route，避免每张截图重编译。
/// compile-time `VISUAL_ROUTE` 仍优先，保持既有 flutter run 用法不变。
String visualRouteIdFromInputs(List<String> args) {
  const compiled = String.fromEnvironment('VISUAL_ROUTE');
  if (compiled.isNotEmpty) return compiled;
  const prefix = '--visual-route=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return '';
}
