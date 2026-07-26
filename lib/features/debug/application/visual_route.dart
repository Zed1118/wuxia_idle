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
  battleScene(
    'battle_scene',
    '战斗屏·背景 scrim + 胜负仪式验收(seed 3v3 带背景,自动播放到胜负 overlay)',
  ),
  mainlineFirstClearBattle(
    'mainline_first_clear_battle',
    '主线首通真战斗验收·真 stage_01_03 + readable_first_clear 调参 + 起手暂停可单步',
  ),
  mainlineFirstClearBattleAuto(
    'mainline_first_clear_battle_auto',
    '主线首通真战斗自动播放验收·真 stage_01_03 + readable_first_clear + 起手/爆发/胜利截图',
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
  battleInnerDemonStage(
    'battle_inner_demon_stage',
    '战斗屏·心魔镜像墨色反相 + 敌方轮廓晕染静态验收',
  ),
  battleLightFootStage('battle_light_foot_stage', '战斗屏·轻功上下错层 + 加长交锋位移静态验收'),
  battleMassBattleStage(
    'battle_mass_battle_stage',
    '战斗屏·群战三名主战立绘 + 余敌墨影队列静态验收',
  ),
  battleV2CasualtyReplacement(
    'battle_v2_casualty_replacement',
    '战斗界面 V2·固定 seed 回放至首次阵亡递补完成后暂停',
  ),
  battleV2FastForwardPeak(
    'battle_v2_fast_forward_peak',
    '战斗界面 V2·固定 seed 回放至同槽同拍双伤害峰值后暂停',
  ),
  battleV2PreResult(
    'battle_v2_pre_result',
    '战斗界面 V2·固定 seed 冻结在最后一次致胜 action 之前',
  ),
  battleV2Neutral3v3('battle_v2_neutral_3v3', '战斗界面 V2·中性标准 3v3 静态帧'),
  battleIdentitySilhouette(
    'battle_identity_silhouette',
    '战斗人物素材门禁·三名未配专用站姿弟子使用透明身份剪影',
  ),
  battleV2ResourcePressure(
    'battle_v2_resource_pressure',
    '战斗界面 V2·冷却签与真气不足签同帧静态验收',
  ),
  battleV2AutoRotationFirst(
    'battle_v2_auto_rotation_first',
    '战斗界面 V2·自动案台第一名执招者与招式签亮起',
  ),
  battleV2AutoRotationSecond(
    'battle_v2_auto_rotation_second',
    '战斗界面 V2·自动案台第二名执招者与招式签轮转亮起',
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
  battleInterruptCaption(
    'battle_interrupt_caption',
    '战斗屏·破招「破！」题字静态验收(破招方暖金 + 敌方绛红 两态)',
  ),
  battleFirstClearShowcase(
    'battle_first_clear_showcase',
    '战斗屏·首通展示帧题字静态验收(开局「初战」+ 敌方「蓄力可破」+ 破招 flourish 峰值字号三态,§十三 #2 T1)',
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
  battleTapLive(
    'battle_tap_live',
    '两段点选交互真玩/验收(真战斗·已开干预·高血耐久敌久撑 → 点 single 强力技进待发态(软暂停)点敌头像出手 / 点 aoe 大招一键即对全体触发)',
  ),
  battleTapPreview(
    'battle_tap_preview',
    '两段点选交互静态预览(冻结态·single 技能待发高亮 + 敌头像可选标记 + 单体/群体角标)',
  ),
  battleDamagePopupGallery(
    'battle_damage_popup_gallery',
    '战斗飘字图册·普通/暴击/暴击+剑鸣/克制升降/闪避 同屏冻结在真战斗深底(暴击语义色专用验收位)',
  ),
  offlineRecapActive(
    'offline_recap_active',
    'M2 闭关归来卡静态验收(active 闭关·长材料明细 +「稍后再说/前去收功」双操作)',
  ),
  offlineRecapPassive(
    'offline_recap_passive',
    'M2 离线被动归来卡静态验收(无 active 闭关·涓流入库告知卡:水墨 LightPaperPanel + 离线时长/磨剑石/经验 + 仅「知道了」按钮,无领取按钮守 §5.1)',
  ),
  battleBossPhase(
    'battle_boss_phase',
    '第七阶段批二目检·真 stage_01_05 撑伞高人 Boss(HP抬高)vs at-level 玩家队真玩:跌破50%背水一击转阶段+蓄力反扑 / 刚猛打弱点会心×1.25 / 灵巧吃抗性×0.75(已开干预层可拖招)',
  ),
  battleGuardianWard(
    'battle_guardian_ward',
    'floor30 护法结界目检·真终局塔队(九霄魔尊+左使/右使)vs 宗师 on-level:起手冻结在护罩生效帧看「护法结界」pill(内力色)+ boss 金边 + 流派克制标多 tag 堆叠;手动步进清完两护法 → 「结界破！」题字 + 破界闪白动效(单帧截不出手感须真机步进看)',
  ),
  battleTowerFloor13('battle_tower_floor_13', '敌人立绘验收·真塔13层（暗夜剑客 + 暗夜刀客）'),
  battleTowerFloor14('battle_tower_floor_14', '敌人立绘验收·真塔14层（江湖前辈 + 师爷）'),
  battleTowerFloor19('battle_tower_floor_19', '敌人立绘验收·真塔19层（武林前辈 + 武林宿老）'),
  battleTowerFloor22('battle_tower_floor_22', '敌人立绘验收·真塔22层（绝顶护法甲 + 乙）'),
  battleStage0102('battle_stage_01_02', '敌人立绘验收·真主线1-2（ruffian_a）'),
  battleStage0103('battle_stage_01_03', '敌人立绘验收·真主线1-3（bandit_head）'),
  battleStage0104('battle_stage_01_04', '敌人立绘验收·真主线1-4（qingshan）'),
  battleTowerFloor02('battle_tower_floor_02', '敌人立绘验收·真塔2层（thug_b）'),
  battleTowerFloor03('battle_tower_floor_03', '敌人立绘验收·真塔3层（thug_c）'),
  battleTowerFloor08('battle_tower_floor_08', '敌人立绘验收·真塔8层（bandit_head）'),
  battleStage0401('battle_stage_04_01', '敌人立绘验收·真主线4-1（liukou_a）'),
  battleStage0402('battle_stage_04_02', '敌人立绘验收·真主线4-2（guard_a）'),
  battleStage0403('battle_stage_04_03', '敌人立绘验收·真主线4-3（shafei_a）'),
  battleStage0404('battle_stage_04_04', '敌人立绘验收·真主线4-4（xiliangboss）'),
  battleStage0405('battle_stage_04_05', '敌人立绘验收·真主线4-5（xiliangbazhu）'),
  battleStage0501('battle_stage_05_01', '敌人立绘验收·真主线5-1（tongguan_shoujiang）'),
  battleStage0502('battle_stage_05_02', '敌人立绘验收·真主线5-2（songshan_daozong_dizi）'),
  battleStage0503('battle_stage_05_03', '敌人立绘验收·真主线5-3（caobang_duozhu）'),
  battleStage0504(
    'battle_stage_05_04',
    '敌人立绘验收·真主线5-4（zhongzhou_lunjian_xianfeng）',
  ),
  battleStage0505('battle_stage_05_05', '敌人立绘验收·真主线5-5（xiliang_sandizi）'),
  battleStage0601(
    'battle_stage_06_01',
    '敌人立绘验收·真主线6-1（lunjian_sanchang_xunluo）',
  ),
  battleStage0602('battle_stage_06_02', '敌人立绘验收·真主线6-2（songshan_shouguan）'),
  battleStage0603('battle_stage_06_03', '敌人立绘验收·真主线6-3（huanghe_yuantou_yufu）'),
  battleStage0604(
    'battle_stage_06_04',
    '敌人立绘验收·真主线6-4（kunlun_waimen_shouguan）',
  ),
  battleStage0605('battle_stage_06_05', '敌人立绘验收·真主线6-5（xiliang_bazhu）'),
  battleTowerFloor06('battle_tower_floor_06', '敌人立绘验收·真塔6层（bandit_b）'),
  battleTowerFloor07('battle_tower_floor_07', '敌人立绘验收·真塔7层（bandit_c）'),
  battleTowerFloor12(
    'battle_tower_floor_12',
    '敌人立绘验收·真塔12层（jianghu_a + jianghu_b）',
  ),
  battleStageAudit(
    'battle_audit_stage',
    '敌人立绘全关卡验收·动态真 stage（实际 id 形如 battle_audit_stage_01_01）',
  ),
  battleTowerAudit(
    'battle_audit_tower',
    '敌人立绘全塔层验收·动态真 floor（实际 id 形如 battle_audit_tower_01）',
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
    battleV2CasualtyReplacement ||
    battleV2FastForwardPeak ||
    battleV2PreResult ||
    battleV2Neutral3v3 ||
    battleIdentitySilhouette ||
    battleV2ResourcePressure ||
    battleV2AutoRotationFirst ||
    battleV2AutoRotationSecond => true,
    _ => false,
  };

  /// 验收目标的语义类型。完整生产页面、局部组件、图册和瞬时浮层不能按
  /// 同一套标准评分，因此在 manifest 中显式区分。
  VisualRouteKind get kind {
    if (id.contains('gallery')) return VisualRouteKind.gallery;
    if (this == VisualRoute.redlineAudit ||
        this == VisualRoute.battleTapPreview ||
        this == VisualRoute.battleIdentitySilhouette ||
        this == VisualRoute.hub) {
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
        this == VisualRoute.battleVictoryFirstClear ||
        this == VisualRoute.battleFirstClearShowcase ||
        this == VisualRoute.battleDefeat ||
        this == VisualRoute.defeatInnerDemonResidue ||
        this == VisualRoute.battleTreasureGlowPeak ||
        this == VisualRoute.battleTreasureGlowRest ||
        this == VisualRoute.battleTreasureZhongqi ||
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
  if (battleAuditStageId(raw) != null) return VisualRoute.battleStageAudit;
  if (battleAuditTowerFloor(raw) != null) return VisualRoute.battleTowerAudit;
  return null;
}

const String battleAuditStagePrefix = 'battle_audit_stage_';
const String battleAuditTowerPrefix = 'battle_audit_tower_';

/// 动态主线/轻功/群战验收 route → 真 stage id。
String? battleAuditStageId(String routeId) {
  if (!routeId.startsWith(battleAuditStagePrefix)) return null;
  final suffix = routeId.substring(battleAuditStagePrefix.length);
  return suffix.isEmpty ? null : 'stage_$suffix';
}

/// 动态爬塔验收 route → 1-based floor。
int? battleAuditTowerFloor(String routeId) {
  if (!routeId.startsWith(battleAuditTowerPrefix)) return null;
  return int.tryParse(routeId.substring(battleAuditTowerPrefix.length));
}

/// 保留动态 route 的完整 id，供 host 取 stage/floor 参数并回报 READY。
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
