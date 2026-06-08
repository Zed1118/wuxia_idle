/// UI 静态中文标签（phase1_tasks.md T14）。
///
/// 与 [lib/features/battle/domain/enum_localizations.dart] 同性质：Phase 1 把"代码内中文"集中
/// 一处便于以后 i18n 迁出。enum_localizations 负责战斗调试日志，本文件负责 UI
/// 标签（标题 / 按钮 / 占位符等）。
///
/// 不收纳剧情 / 装备典故 / 奇遇文案（那些走 data/narratives, lore, events，
/// 由 DeepSeek 端维护）。
class UiStrings {
  UiStrings._();

  /// 应用标题(splash screen / window title)。
  static const String appTitle = '挂机武侠';

  /// 战斗顶栏标题：`战斗 N v M`，N/M 为双方存活人数。
  static String battleTitle(int leftAlive, int rightAlive) =>
      '战斗 $leftAlive v $rightAlive';

  static const String tickPrefix = '回合';
  static const String battleLog = '战斗日志';
  static const String emptyLog = '（无动作）';
  static const String ultimate = '大招';
  static const String fastForward = '快进';

  // 伤害飘字（T15）
  static const String dodge = '闪';
  static const String counterUp = '⬆';
  static const String counterDown = '⬇';

  // 战斗结算（T16）
  static const String close = '关闭';
  static const String backToMenu = '返回菜单';

  // ─── 胜负仪式 overlay(出版美术 B1)──────────────────────────────────────
  static const String victoryTitle = '勝';
  static const String defeatTitle = '敗';
  static const String victorySubtitle = '旗开得胜';
  static const String defeatSubtitle = '败北';
  static const String battleContinue = '继续';
  static const String sealGlyph = '武'; // 印章符内字

  /// 战斗结算 dialog 内容：`总伤害 X  暴击 Y 次  用时 Z 回合`。
  static String battleSummary(int totalDamage, int critCount, int totalTicks) =>
      '总伤害 $totalDamage    暴击 $critCount 次    用时 $totalTicks 回合';

  // 主菜单（T32 子提交 3b；G1 剥「调试」字样,production-facing 产品名）
  static const String mainMenuTitle = '挂机武侠';

  /// 主菜单副标题（Phase A 出版美术 · 题字感）。
  static const String mainMenuSubtitle = '一剑霜寒 · 江湖路远';

  /// 主菜单入口分组标签（Phase A 出版美术 · 主/次分组）。
  static const String mainMenuGroupCore = '修行';
  static const String mainMenuGroupBattle = '演武';
  static const String mainMenuGroupJianghu = '江湖';
  static const String mainMenuGroupDebug = '调试';

  /// 主菜单「今日节日」chip（W16 GDD §12.4）。
  /// [festivalName] 走 [EnumL10n.festival]，例：「今日：春节」。
  static String mainMenuTodayFestival(String festivalName) =>
      '今日：$festivalName';

  static const String mainMenuPhase1 = 'Phase 1 战斗测试';
  static const String mainMenuPhase1Hint =
      '4 个 3v3 战斗场景（基础对决 / 流派克制 / 装备影响 / 境界差距）';
  static const String mainMenuPhase2 = 'Phase 2 调试场景';
  static const String mainMenuPhase2Hint =
      '4 个数据种子场景（强化曲线 / 共鸣触发 / 散功代价 / 全栈对比）';
  static const String mainMenuCharacterPanel = '角色面板';
  static const String mainMenuCharacterPanelHint = '查看角色属性 / 装备 / 心法';
  static const String mainMenuInventory = '装备仓库';
  static const String mainMenuInventoryHint = '查看 / 强化 / 开锋装备';
  static String mainMenuInventoryStatus(int count, String topTier) =>
      count <= 0 ? '暂无装备' : '$count件 · $topTier';
  static const String mainMenuTechniques = '心法面板';
  static const String mainMenuTechniquesHint = '查看主修 / 辅修 / 散功换主修';
  static const String mainMenuTechniquesLockedHint = '通过第三关后开放';
  static const String mainMenuTechniquesLockedStatus = '未开放';
  static const String mainMenuTechniquesNoMainStatus = '未主修';
  static String mainMenuTechniquesKnownStatus(int count) => '已修$count门';
  static String mainMenuTechniquesInsightStatus(int points) => '可凝练$points点';
  // H1 批1 §5.7:未解锁系统门控引导文案。
  static const String mainMenuLateGameLockedHint = '主线第六章通关后开放';
  static const String mainMenuSocialLockedHint = '主线第一章通关后开放';
  // H1 批1 §5.6:全新存档默认门派名(原 onboarding 硬编码迁出)。
  static const String defaultSectName = '我的门派';
  // H1 批2:装备穿戴 picker(玩家手动装备入口)。
  static const String equipPickerTitle = '选择装备';
  static const String equipPickerEmpty = '背包暂无该部位可用装备';
  static const String equipPickerClose = '关闭';
  static const String equipUnequip = '卸下当前装备';
  static const String equipLockedByRealm = '境界不足,无法装备(三系锁死)';

  /// H1 批3 picker 标注:该装备正被队内其他角色穿戴,选它会移装(原角色卸下)。
  /// 自由池移装是合理调配,故只标注提醒不禁用(去掉「静默卸下弟子」的意外感)。
  static const String equipWornByOther = '他人装备中';
  static const String mainMenuLineage = '师徒名单';
  static const String mainMenuLineageHint = '查看祖师与弟子的传承链路';

  // ─── 江湖恩怨 + 声望(P1.2 §12.1+§12.2 GDD)──────────────────────────────
  static const String mainMenuJianghu = '江湖恩怨';
  static const String mainMenuJianghuHint = '声望 7 阶 + 多门派关系 + NPC 仇敌';
  static const String reputationPanelTitle = '江湖声望';
  static const String reputationPanelEmpty = '暂无声望记录';
  static const String reputationPanelLoadError = '加载失败';
  static const String reputationTierXueTu = '声名狼藉';
  static const String reputationTierSanLiu = '恶名';
  static const String reputationTierErLiu = '默默无闻';
  static const String reputationTierYiLiu = '薄有微名';
  static const String reputationTierJueDing = '侠名初显';
  static const String reputationTierZongShi = '声振江湖';
  static const String reputationTierWuSheng = '天下闻名';
  static const String enmityWarning = '当前有敌对 NPC';
  static const String panelFriendSection = '盟友';
  static const String panelFoeSection = '敌对';

  // Phase 2 调试场景（T32 子提交 3d）
  static const String phase2MenuTitle = 'Phase 2 调试场景';
  static const String scenarioP1 = 'P1 · 强化曲线';
  static const String scenarioP2 = 'P2 · 共鸣触发';
  static const String scenarioP3 = 'P3 · 散功代价';
  static const String scenarioP4 = 'P4 · 全栈对比';
  static const String hintP1 = '+0 利器 + 1000 磨剑石 / 100 结晶，连续强化看成功率分布';
  static const String hintP2 = 'battleCount=99 装备，下场战斗 →100 触发"趁手"+10%';
  static const String hintP3 =
      '主修 yuanMan/1500 + IF 10000，散功后 daCheng/750 + IF 5000';
  static const String hintP4 = '+0 强化到 +19 + 开锋 + 默契满，对比裸装伤害';
  static const String scenarioP5 = 'P5 · 师徒种子';
  static const String hintP5 = '祖师一流 + 大弟子二流 + 二弟子三流，3 师徒入阵可直接进战斗';
  static const String scenarioVc = 'VC · W7-W11 视觉验收预设';
  static const String hintVc = '在 P5 基础上标 Ch1 01-04 通关，直接挑战 stage_01_05';
  static const String scenarioVc14_3 = 'VC · W14-3 奇遇 skill 视觉验收预设';
  static const String hintVc14_3 =
      '在 VC 基础上预 unlock 7 招（tier 1-7 各 1）+ 大弟子装 tier 3，看 lock icon 行为';
  static const String scenarioVcEvent = 'VC-EVENT · 触发奇遇 debug';
  static const String hintVcEvent =
      '绕过软概率，直接选 encounter id 触发 dialog + outcome 流（visual check 用）';
  static const String scenarioVc15R2 = 'VC15-r2 · tier 5-7 装备入背包';
  static const String hintVc15R2 =
      '在 VC 基础上额外入 6 件重器/宝物/神物入背包（祖师 owner 不装备），看 3 段 lore + 强化流程';
  static const String scenarioVc15Resonance = 'VC15-res · 共鸣/强化/开锋光谱';
  static const String hintVc15Resonance =
      '6 件武器覆盖共鸣 4 阶段 + 强化 +0/+5/+10/+15/+19 + 开锋 0/1/2/3 槽 + 师承遗物 1 件';
  static const String scenarioVc15Fresh =
      'VC15-fresh · 3 active 学徒启蒙(升层 banner 验收)';
  static const String hintVc15Fresh =
      '3 active 全员 xueTu·qiMeng + experience=0 + 主线塔进度清零,通 stage_01_01 触发升层多行 banner';
  static const String scenarioVc18A1 = 'VC18-A1 · 心法相生 5 组合视觉验收预设';
  static const String hintVc18A1 =
      '5 角色一流·启蒙 + main/assist 配对覆盖 5 相生组合各 1 命中,切 Tab 看 chip + 进 stage_01_05 看 HpBar/内力条数字注入';
  static const String scenarioVcP5Plus = 'VC-P5+ · 飞升流视觉验收预设(Codex 派单)';
  static const String hintVcP5Plus =
      '祖师 wuSheng·dengFeng + stage_inner_demon_07 + stage_06_05 cleared · 「步入飞升」按钮 enable · 直跳 AscensionScreen 拿 dialog/snackbar/多代 chip 截图';
  static const String scenarioVcShenwuDrop =
      'VC · 神物掉落 06_04（Ch1-6 全清·满配·Codex 派单）';
  static const String hintVcShenwuDrop =
      '祖师 wuSheng·dengFeng 满配 + Ch1–Ch5 全通 + stage_06_01/02/03 cleared，独留 stage_06_04 可挑 · 直跳章节列表 → 第六章 → 打 06_04 必掉神物「昆仑佩」(dropChance 1.0) → 截金色品阶掉落弹窗';
  static const String scenarioRefineInsight = '凝练态验证';
  static const String hintRefineInsight =
      '主修心法 + 领悟点 50 + tutorialStep 3，进心法面板看主修卡「凝练领悟 · N 点」有点态';
  static const String encounterDebugPickerTitle = 'VC-EVENT · 触发奇遇';

  // W16 节日 chip DEBUG 覆盖入口（Phase2TestMenu）
  static const String debugFestivalOverrideLabel = 'DEBUG · 切今日节日';
  static const String debugFestivalOverrideHintNone = '当前无覆盖（走真实日期）';
  static String debugFestivalOverrideHint(String festivalName) =>
      '当前覆盖：$festivalName';
  static const String debugFestivalOverrideDialogTitle = '切今日节日（DEBUG）';
  static const String debugFestivalOverrideClear = '清除覆盖';
  static String debugFestivalOverrideSnack(String festivalName) =>
      '已覆盖今日为：$festivalName';
  static const String debugFestivalOverrideSnackCleared = '已清除节日覆盖';

  // 调试菜单（T17）
  static const String testMenuTitle = '战斗测试场景';
  static const String scenarioA = 'A · 同境界基础对决';
  static const String scenarioB = 'B · 流派克制循环';
  static const String scenarioC = 'C · 装备影响伤害';
  static const String scenarioD = 'D · 境界差距碾压';
  static const String hintA = '观察点：基础伤害落在 2000-8000，节奏纯比速度';
  static const String hintB = '观察点：左队全面克制右队（×1.25 攻 / ×0.75 受），差距约 1.67 倍';
  static const String hintC =
      '观察点：纯武器攻击对比（IF=0），+12强化+默契 = ×1.92 基础攻，伤害约为裸装 1.9 倍';
  static const String hintD = '观察点：低境界（三流）打高境界（绝顶）守方修正 ×0.05，几乎打不动';

  // 角色面板（T28）
  static const String panelAttributes = '基础属性';
  static const String panelDerived = '派生数值';
  static const String panelEquipment = '装备';
  static const String panelTechnique = '心法';
  static const String profileRealmLabel = '境界';
  static const String profilePortraitPlaque = '人物签';
  static const String lineageRoleFounder = '开派祖师';
  static const String lineageRoleDisciple = '门下弟子';
  static const String lineageRoleGrandDisciple = '再传弟子';

  // 师承段（T56）
  static const String panelLineage = '师承';
  static const String lineageMasterLabel = '师父';
  static const String lineageDisciplesLabel = '徒弟';
  static const String lineageBiographyLabel = '传记';
  static const String lineageHeritageLabel = '遗物';
  static const String lineageBiographyPlaceholder = '[传记待补]';
  static const String lineageNoMaster = '无';
  static const String lineageNoDisciples = '无';
  static const String lineageNoHeritage = '无';

  /// 师承 Tab 标签：按 activeCharacterIds 顺序展示。
  /// 与 Phase2SeedService.seedMasterDisciple 槽位约定锁死（slot0=祖师 / 1=大弟子 / 2=二弟子）。
  /// 2026-05-20 T01 +2 扩到 7 槽供 [seedVisualCheckW18A1] debug fixture 一次显 7 相生组合角色;
  /// 正常 P5 主线 ids.length=3 仍只显前 3,无视觉影响(GDD §7.1 demo_max_characters=3 不变)。
  static const List<String> lineageTabLabels = [
    '祖师',
    '大弟子',
    '二弟子',
    '三弟子',
    '四弟子',
    '五弟子',
    '六弟子',
  ];

  // 师徒名单 panel（W17 候选 E）
  static const String lineagePanelTitle = '师徒名单';
  static const String lineagePanelDisciplesSection = '弟子';
  static const String lineagePanelHeritageSection = '师承遗物';
  static const String lineagePanelNoFounder = '祖师未定';
  static const String lineagePanelNoDisciples = '尚无弟子';
  static const String lineagePanelNoHeritage = '尚未拥有师承遗物';
  static String lineagePanelHeritageCount(int n) => '$n 件';

  static const String attrConstitution = '根骨';
  static const String attrEnlightenment = '悟性';
  static const String attrAgility = '身法';
  static const String attrFortune = '机缘';

  static const String statHp = '生命';
  static const String statInternalForce = '内力';
  static const String statSpeed = '速度';
  static const String statCriticalRate = '暴击率';
  static const String statEvasionRate = '闪避率';

  /// 内力当前/上限文案：`X / Y`。
  static String internalForceValue(int current, int max) => '$current / $max';

  /// 修炼度进度文案：`X / Y`。
  static String cultivationProgress(int current, int next) =>
      '$current / $next';

  /// B5 段位阶梯进度（当前层 / 总层数）。
  static String layerProgressLabel(int current, int total) =>
      '$current / $total 层';

  /// 百分比小数 → `X%`（向下取整以避免视觉超额，与战斗调试一致）。
  static String percent(double rate) => '${(rate * 100).toInt()}%';

  /// 强化等级文案：`+N`（N=0 不省略，仍显示 `+0` 表示未强化）。
  static String enhanceLevel(int level) => '+$level';

  static const String techniqueRoleMain = '主修';
  static const String techniqueRoleAssist = '辅修';

  static const String slotEmpty = '未装备';
  static const String techniqueEmpty = '未学';
  static const String noMainTechnique = '未修主修';
  static const String dashPlaceholder = '—';

  // W18-A1 心法相生(GDD §4.5,CharacterPanel chip 显示)
  static const String synergyActiveLabel = '相生';

  // 仓库 / 强化对话框（T29）
  static const String inventoryTitle = '装备仓库';
  static const String inventoryEmpty = '仓库空空如也';
  /// 装备详情共鸣行:`战斗 N 次`。
  static String equipmentBattleCount(int count) => '战斗 $count 次';

  // 仓库 Tab（W15 #30 P3 后续 A · 物料 Tab）
  static const String inventoryTabEquipment = '装备';
  static const String inventoryTabMaterial = '物料';
  static const String inventoryMaterialEmpty = '暂无物料';

  /// 物料行文案：`磨剑石 × 1234`。
  static String materialQuantity(String name, int qty) => '$name × $qty';
  static const String enhanceDialogTitle = '强化';
  static const String enhanceButton = '强化';
  static const String guaranteeButton = '保底成功';
  static const String enhanceCapped = '已达上限';
  static const String successLabel = '强化成功';
  static const String failureLabel = '强化失败';

  /// 强化预览：`+5 → +6`。
  static String enhancePreview(int oldLevel, int newLevel) =>
      '+$oldLevel → +$newLevel';

  /// 磨剑石余量 / 需求：`磨剑石 X / Y`。
  static String mojianshiUsage(int current, int cost) => '磨剑石 $current / $cost';

  /// 心血结晶余量：`心血结晶 X`。
  static String crystalAvailable(int qty) => '心血结晶 $qty';

  /// 保底所需结晶：`保底 X 颗`。
  static String guaranteeCost(int cost) => '保底 $cost 颗';

  /// 失败提示：`+1 心血结晶`（GDD §6.3 每次失败必给 1 颗）。
  static String crystalGained(int gained) => '+$gained 心血结晶';

  static const String metricSuccessRate = '成功率';
  static const String metricMaterial = '材料';
  static const String metricCrystal = '结晶';

  // 开锋（T30）
  static const String tabEnhance = '强化';
  static const String tabForging = '开锋';
  static const String forgingForged = '已开锋';
  static const String forgingNoSpecialSkill = '该装备无专属技能';
  static const String forgingConfirmTitle = '确认开锋';
  static const String forgingConfirmBody = '开锋一旦下手不能更改。确认在此槽位开锋？';
  static const String forgingConfirmOk = '确认';
  static const String forgingConfirmCancel = '取消';

  /// 槽位标题：`槽 1` / `槽 2` / `槽 3`。
  static String forgingSlotTitle(int slotIndex) => '槽 $slotIndex';

  /// 未解锁文案：`强化到 +N 解锁`。
  static String forgingUnlockHint(int unlockAtLevel) =>
      '强化到 +$unlockAtLevel 解锁';

  /// 已开锋词条：`攻击 +15%`。
  static String forgingBonusLabel(String typeLabel, int bonus) =>
      '$typeLabel +$bonus%';

  // 心法面板 / 散功 dialog（T31）
  static const String techniquePanelTitle = '心法面板';
  static const String techniquePanelEmpty = '尚未学习任何心法';
  static const String techniquePanelMainHeroLabel = '主修心法';
  static const String techniqueSchoolMatrixTitle = '三系相克';
  static const String techniqueSchoolMatrixHint = '刚猛克阴柔，阴柔克灵巧，灵巧克刚猛';
  static const String techniqueSchoolMatrixCurrentPrefix = '当前';
  static const String techniqueSchoolMatrixUnset = '未定';
  static const String techniqueSchoolEffectGangMeng = '震伤';
  static const String techniqueSchoolEffectLingQiao = '暴击';
  static const String techniqueSchoolEffectYinRou = '内伤';
  static const String setAsMainButton = '设为主修';
  static const String dispelDialogTitle = '散功换主修';
  static const String dispelLayerWarning = '修炼度层可能回退';
  static const String dispelConfirm = '确认散功';
  static const String dispelSuccess = '散功完成';

  // 凝练领悟（根因A 2026-05-29：insightPoints 兑换主修修炼度 sink）
  static const String refineInsightButton = '凝练领悟';

  /// 主修凝练入口常驻态(H1 批3):有领悟点时显点数,引导玩家点击;0 点时
  /// 入口走 [refineInsightButtonEmpty] 灰显常驻态,不再靠点击后 SnackBar 才知。
  static String refineInsightButtonWithPoints(int points) => '凝练领悟 · $points 点';
  static const String refineInsightButtonEmpty = '凝练领悟 · 暂无领悟点';
  static const String refineInsightTitle = '凝练领悟';

  /// 凝练 dialog 正文:`将 X 点领悟点凝入主修修炼度。`
  static String refineInsightBody(int insightPoints) =>
      '将 $insightPoints 点领悟点凝入主修修炼度。';
  static String refineInsightSpendLine(int insightPoints) =>
      '消耗领悟点 $insightPoints';
  static const String refineInsightTargetLine = '注入主修修炼度';
  static const String refineInsightCeremonyHint = '闭关所得灵光，将化为心法火候。';
  static const String refineInsightConfirm = '全部凝练';

  /// 凝练成功 SnackBar:`凝练 +X 修炼度`(升层时追加)。
  static String refineInsightSuccess(int progress, {bool leveledUp = false}) =>
      leveledUp ? '凝练 +$progress 修炼度 · 突破一层！' : '凝练 +$progress 修炼度';
  static const String refineInsightNoPoints = '没有可凝练的领悟点（闭关挂机可得）';

  /// 散功代价 · 内力：`内力 X → Y`。
  static String dispelCostInternalForce(int before, int after) =>
      '内力 $before → $after';

  /// 散功代价 · 修炼度:`修炼度 X → Y`。
  static String dispelCostCultivation(int before, int after) =>
      '修炼度 $before → $after';

  // ── Phase 3 主线（T35）──

  static const String mainMenuMainline = '主线';
  static const String mainMenuMainlineHint = '6 章 30 关,按章节顺序解锁';
  static String mainMenuMainlineStatus(int chapterIndex, String stageName) =>
      '第$chapterIndex章 · $stageName';
  static const String mainMenuMainlineCompleteStatus = '主线已通';

  static const String chapterListTitle = '主线 · 章节';
  static const String mainlineRouteMapTitle = '江湖路引';
  static const String mainlineRouteMapSubtitle = '六章江湖路 · 每章五关，朱印为 Boss';
  static const String mainlineRouteCurrent = '当前';
  static const String mainlineRouteCleared = '已通';
  static const String mainlineRouteLocked = '未至';
  static const String mainlineRouteBoss = 'Boss';
  static const String chapter1Title = '第一章 · 学武出山';
  static const String chapter2Title = '第二章 · 武林初识';
  static const String chapter3Title = '第三章 · 名扬江湖';
  static const String chapter4Title = '第四章 · 西出阳关';
  static const String chapter5Title = '第五章 · 征东';
  static const String chapter6Title = '第六章 · 飞升';
  static const String chapter1Hint = '初出茅庐，山道试剑、林间伏击';
  static const String chapter2Hint = '镖局护送、黑风寨剿匪';
  static const String chapter3Hint = '武林会、一战封王';
  static const String chapter4Hint = '潼关西行,玉门古道、大漠迷踪、嘉峪关一决';
  static const String chapter5Hint = '东归长安、嵩山道观、中州论剑大会';
  static const String chapter6Hint = '论剑散场、嵩山再访、黄河之源、昆仑山顶';

  static const String chapterStatusLocked = '未解锁';
  static const String chapterStatusInProgress = '进行中';
  static const String chapterStatusCompleted = '已完成';

  static const String stageListLocked = '锁';
  static const String stageListAvailable = '可挑战';
  static const String stageListCleared = '✓ 已通关';
  static const String stageListPrevHint = '通关前一关解锁';
  static const String stageListEmpty = '该章暂无关卡';
  static const String stageListJourneyTitle = '章内行程';
  static const String stageListBoss = 'Boss';
  static String stageListJourneyNodeLabel(int stageIndex) => '第$stageIndex关';

  static String chapterRouteNodeLabel(int chapterIndex) => '第$chapterIndex章';

  static String mainlineRouteStageNode(int stageIndex) => '$stageIndex';

  static String stageListEnemyCount(int count) => '$count 名敌人';

  /// 章节标题路由：按 chapterIndex 返回对应中文标题。
  static String chapterTitle(int chapterIndex) {
    return switch (chapterIndex) {
      1 => chapter1Title,
      2 => chapter2Title,
      3 => chapter3Title,
      4 => chapter4Title,
      5 => chapter5Title,
      6 => chapter6Title,
      _ => '第 $chapterIndex 章',
    };
  }

  /// 章节简介路由。
  static String chapterHint(int chapterIndex) {
    return switch (chapterIndex) {
      1 => chapter1Hint,
      2 => chapter2Hint,
      3 => chapter3Hint,
      4 => chapter4Hint,
      5 => chapter5Hint,
      6 => chapter6Hint,
      _ => '',
    };
  }

  // ── H2 小套餐 C1:章节翻篇过场 ──

  /// 章节卡「卷」入口 tooltip。
  static const String chapterScrollTooltip = '卷首/卷尾';
  static const String chapterProloguelabel = '卷首';
  static const String chapterEpiloguelabel = '卷尾';

  /// 卷尾未解锁(章节进行中)的弱提示。
  static const String chapterEpilogueLocked = '通关此章后，卷尾自现。';

  /// 卷首/卷尾文案缺失兜底。
  static const String chapterScrollPlaceholder = '此章卷语待补。';

  /// 过场底部「入此章」按钮。
  static const String chapterScrollEnter = '翻过此页 · 入关';

  // ── Phase 3 爬塔（T42）──

  static const String mainMenuTower = '问鼎九霄';
  static const String mainMenuTowerHint = '30 层，无限重试，永久记录';
  static String mainMenuTowerStatus(int highest, int next) =>
      highest <= 0 ? '未登塔 · 1层' : '已至$highest层 · 下$next层';
  static String mainMenuTowerBossStatus(int highest, int next) =>
      highest <= 0 ? '未登塔 · 1层' : '已至$highest层 · 下$next层Boss';
  static const String mainMenuTowerCompleteStatus = '三十层已通';

  // ── P0.2 #40 排行榜(本地榜,D 方案 Demo 不接 Supabase backend)──

  static const String mainMenuLeaderboard = '排行榜';
  static const String mainMenuLeaderboardHint = '最高通关层 / 最佳耗时 / 累计挑战';

  static const String leaderboardTitle = '排行榜';
  static const String leaderboardEmpty = '尚未通关任何爬塔层';
  static const String leaderboardHighestLayer = '最高通关层';
  static const String leaderboardLayerSuffix = '层';
  static const String leaderboardBestClearTime = '最佳通关耗时';
  static const String leaderboardTotalAttempts = '累计挑战次数';
  static const String leaderboardWinRate = '胜率';
  static const String leaderboardNoData = '—';

  static String leaderboardDurationSeconds(int seconds) => '$seconds 秒';
  static String leaderboardDurationMinutes(int minutes, int seconds) =>
      '$minutes 分 $seconds 秒';
  static String leaderboardWinRatePct(int pct) => '$pct%';

  static const String towerTitle = '问鼎九霄';
  static const String towerSpineTitle = '九霄塔势';

  static const String towerBossMinor = '小 Boss';
  static const String towerBossMajor = '大 Boss';

  static const String towerFloorLocked = '通关前一层解锁';
  static const String towerFloorChallenge = '挑战';

  static const String towerReplayTitle = '已通关';
  static const String towerReplayBody = '已通关，是否重打？（重打不发奖）';
  static const String towerReplayConfirm = '重打';
  static const String towerReplayCancel = '取消';

  static const String towerEntryPlaceholder = '爬塔进入流程待 T43 接入';

  static String towerProgressCleared(int cleared) => '已通 $cleared / 30 层';
  static String towerProgressAttempts(int n) => '总尝试 $n 次';
  static String towerProgressDefeats(int n) => '失败 $n 次';

  static String towerFloorLabel(int floorIndex) => '第 $floorIndex 层';
  static String towerFloorEnemies(int count) => '$count 名敌人';
  static String towerRequiredRealm(String realmName) => '推荐 $realmName';

  static const String towerDropSource = '爬塔奖励';
  static const String towerVictoryConfirm = '确定';
  static const String towerReplayNoReward = '已重打通关，重打不发奖';
  static const String towerFirstClearLabel = '首通奖励：';
  static const String towerFirstClearNoReward = '首通！本层无固定奖励。';
  static String towerFirstClearCeremony(
    int floorIndex, {
    bool isBoss = false,
  }) => isBoss ? '破阵 · 第 $floorIndex 层 Boss' : '首通 · 第 $floorIndex 层';

  // ─── 主线 victory dialog（W15 #30 P3 后续 A 任务）────────────────────────

  static const String stageVictoryTitle = '战斗胜利';
  static const String stageVictoryConfirm = '继续';
  static const String stageVictoryDropLabel = '掉落：';
  static const String stageVictoryNoDrop = '本战无固定掉落';
  static const String firstClearCeremonySubtitle = '朱印封记';
  static String stageVictoryBossFirstClear(String stageName) =>
      '首胜 · $stageName';

  // P1.1 候选 3-a：共鸣度晋阶 banner（victory dialog 内）
  static const String stageVictoryResonanceLabel = '共鸣晋阶：';
  static const String stageVictoryResonanceCeremonyTitle = '兵器应手';
  static String stageVictoryResonanceUpgrade(String name, String stage) =>
      '「$name」共鸣度晋至 $stage';

  // P1.1 候选 3-d：equipment_detail 共鸣度晋升信息透明 section
  static String equipmentDetailResonanceBonus(int pct) =>
      pct == 0 ? '当前无属性加成' : '当前属性加成 +$pct%';
  static const String equipmentDetailResonanceJointSkill = '✦ 已解锁「人剑合一」招式';
  static const String equipmentDetailResonanceSwordSong = '✦ 暴击附带「剑鸣」浮字';
  static String equipmentDetailResonanceNextHint(int remaining, String next) =>
      '距「$next」尚需 $remaining 战';
  // §5.6 审计抽出(2026-06-08):装备详情属性基础值后缀
  static String equipmentStatBaseValue(int base) => '(基 $base)';

  // P1.1 候选 3-c：sword_song 暴击剑鸣浮字（damage_popup 附加）
  static const String swordSongHint = '✦剑鸣';

  // ─── 升层 banner 多角色版（mainline / tower 共用）─────────────────────

  static const String advancementCeremonyTitle = '境界精进';

  static String advancementForCharacter(
    String chName,
    String realmAfter,
    int layers,
  ) => layers == 1
      ? '$chName · 突破至 $realmAfter'
      : '$chName · 连破 $layers 层 → $realmAfter';

  /// H2 C2:大境界突破 badge(跨境界 tier 的里程碑,区别于小层升级)。
  static const String advancementTierUpBadge = '大境界突破';

  // ─── 闭关修炼（Phase 3 T49）─────────────────────────────────────────────

  static const String mainMenuSeclusion = '闭关修炼';
  static const String mainMenuSeclusionHint = '5 张地图，离线挂机，最长 72 小时';
  static const String mainMenuSeclusionLockedHint = '通关第一章后开放';
  static const String mainMenuSeclusionReadyStatus = '可择地图';
  static const String mainMenuSeclusionLockedStatus = '未开放';
  static String mainMenuSeclusionActiveStatus(String mapName) =>
      '闭关中 · $mapName';
  static String mainMenuSeclusionDoneStatus(String mapName) => '可收功 · $mapName';

  // ─── 心魔境（1.0 P2.2 §12.1,Batch 2.5.B 入口）─────────────────────────────
  static const String mainMenuInnerDemon = '心魔境';
  static const String mainMenuInnerDemonHint = '7 关克己 · 武圣突破前置';

  // ─── 轻功对决（1.0 P3.1 §12.3,Batch B.3 入口）────────────────────────────
  static const String mainMenuLightFoot = '轻功试炼';
  static const String mainMenuLightFootHint = '5 关地形 · 一寸余地';

  // ─── 群战守城（1.0 P3.2 §12.3,Batch 2.4 入口）────────────────────────────
  static const String mainMenuMassBattle = '守城试炼';
  static const String mainMenuMassBattleHint = '5 关守城 · 以少胜多';
  static const String massBattleFormationTitle = '选择阵型';
  static const String massBattleFormationYanXing = '雁行阵';
  static const String massBattleFormationYanXingHint = '暴击 +10% · 防御 -5%';
  static const String massBattleFormationBaGua = '八卦阵';
  static const String massBattleFormationBaGuaHint = '防御 +10% · 闪避 +5%';
  static const String massBattleFormationFengShi = '锋矢阵';
  static const String massBattleFormationFengShiHint = '伤害 ×1.10 · 暴击 +5%';

  // ─── 论剑对决 PVP(1.0 P3.3 §12.3,Phase 4 入口)───────────────────────────
  static const String mainMenuPvp = '论剑对决';
  static const String mainMenuPvpHint =
      '异步快照 PVP · 跨 ELO 段位匹配对手(主线 Ch5 cleared 解锁)';

  static const String pvpTitle = '论剑对决';
  static const String pvpLockedHint = '主线 Ch5 通关后开放';
  static const String pvpMatchButton = '立即论剑';
  static const String pvpMatchPlaceholder =
      'PVP 真战斗流程留 Phase 5 wire(读玩家阵容 + Isar 持久化)';
  static const String pvpHistoryTitle = '近期战例';
  static const String pvpHistoryEmpty = '尚未踏入论剑场';
  static const String pvpHistoryWin = '胜';
  static const String pvpHistoryLoss = '负';
  static const String pvpHistoryDraw = '和';
  static String pvpHistoryEloDelta(int delta) =>
      delta > 0 ? '+$delta' : '$delta';

  static const String pvpRankXueTu = '学徒';
  static const String pvpRankSanLiu = '三流';
  static const String pvpRankErLiu = '二流';
  static const String pvpRankYiLiu = '一流';
  static const String pvpRankJueDing = '绝顶';
  static const String pvpRankZongShi = '宗师';
  static const String pvpRankWuSheng = '武圣';
  static String pvpEloLabel(int elo) => '当前 ELO · $elo';
  static String pvpRankNext(int remaining, String nextRank) =>
      '距「$nextRank」尚需 $remaining 分';
  static const String pvpRankTopHint = '已至段位之巅';

  // ─── 门派事务（1.0 P3.4 §12.1,Batch 2.3-2.5 入口)─────────────────────────
  static const String mainMenuSect = '门派事务';
  static const String mainMenuSectHint = '门派经营 · 比武大会 · 声望积累(一流境界 yiLiu 解锁)';

  // ─── 帮派门派 P4.1 §12.2 B3 UI(成员 + 领地 Tab · 路径 A 扩 sect_screen)───
  static const String sectTabEventsActive = '当前事件';
  static const String sectTabEventsHistory = '历史记录';
  static const String sectTabMembers = '成员';
  static const String sectTabTerritories = '领地';
  static const String sectRankInitiate = '初入';
  static const String sectRankInner = '内门';
  static const String sectRankElder = '长老';
  static const String sectMemberFounderTag = '祖师';
  static const String sectMemberPromote = '内升';
  static const String sectMemberDismiss = '退派';
  static const String sectTerritoryClaim = '占领';
  static const String sectTerritoryRelease = '释放';
  static const String sectTerritoryNeutral = '中立';
  static const String sectTerritoryOwnedSelf = '本派持有';
  static const String sectTerritoryOwnedOther = '他派持有';
  static const String sectMemberCountLabel = '成员数';
  static const String sectTerritoryCountLabel = '领地数';
  static const String sectTerritoryDefenseLabel = '防御阶';
  static const String sectMemberEmpty = '尚无门派成员';
  static const String sectTerritoryEmpty = '尚无可占领领地';
  static const String sectRecruitSuccess = '招收成功';
  static const String sectRecruitFullCap = '成员已满';
  static const String sectRecruitAlreadyInSect = '已在派中';
  static const String sectPromoteSuccess = '阶位已升';
  static const String sectPromoteBelowThreshold = '贡献不足无法升阶';
  static const String sectPromoteAlreadyMax = '已是顶阶';
  static const String sectDismissSuccess = '已退派';
  static const String sectClaimSuccess = '已纳入麾下';
  static const String sectClaimAlreadyOwned = '此地已有归属';
  static const String sectClaimFullCap = '领地已满';
  static const String sectReleaseSuccess = '已释放领地';
  static String sectMemberCapDisplay(int count, int cap) => '$count / $cap';
  static String sectPromoteRequire(int required) => '需贡献 $required';

  // ─── P4.1 1.1 Q6A · encounter-triggered 门派招收 confirm dialog ───
  static const String sectEncounterRecruitConfirmTitle = '是否招入门派?';
  static const String sectEncounterRecruitAccept = '招入门派';
  static const String sectEncounterRecruitDecline = '婉拒';
  static String sectEncounterRecruitSuccess(String name) =>
      '$name 已入门派,任 [初入] 阶';
  static String sectEncounterRecruitCapFull(String name) => '门派人数已满,$name 婉言告别';
  static String sectEncounterRecruitNoSect(String name) => '尚未建派,$name 无缘相邀';

  // ── P1 #42 Phase 2 §10 P1.y · 新手引导 banner 文案(GDD §10.2 第 2 方式)──
  // §5.7 合规:仅在「新系统解锁」那一步提示一次,跳过纯进度祝贺(step 1/2/4)。
  // step 3 心法面板 / step 5 Ch1 通关(闭关 + 江湖/门派/排行榜)/ step 6/7/8 收徒·奇遇·开锋。
  static const String tutorialHintStep3Title = '心法已可修习';
  static const String tutorialHintStep3Body =
      '初通拳脚,可习心法了。主修一门立为根本,辅修旁系以求相生 —— 招式威能、内力深浅,皆由心法而定。心法面板已为你开启,择一门细细参详。';
  static const String tutorialHintStep5Title = '山门之外天地宽';
  static const String tutorialHintStep5Body =
      '学武出山一章已了。可寻一处清幽闭关潜修,内息日进;亦可就此踏入江湖 —— 结识同道、开宗立派、登台较技。前路已开,凭你去闯。';
  static const String tutorialHintStep6Title = '收徒资格已达成';
  static const String tutorialHintStep6Body =
      '内功已至一流境界,可以收徒了。开派祖师才能将一身所学传承下去 —— 待你择一可造之材为徒,武林便多一位你的弟子。';
  static const String tutorialHintStep7Title = '江湖奇遇初体验';
  static const String tutorialHintStep7Body =
      '江湖见闻初触。在挂机与探索中,你将渐次邂逅各种奇遇 —— 听雨悟剑、瀑下持戟,皆可能引出未传之秘技。机缘所在,各凭悟性。';
  static const String tutorialHintStep8Title = '装备开锋已可寻';
  static const String tutorialHintStep8Body =
      '宝器初成。装备强化至 +10 已具开锋资格 —— 攻、速、吸、破,可任选一道为剑铸魂。一柄长剑亦可有破甲与吸血两副面目。';

  static const String seclusionTitle = '闭关修炼';
  static const String seclusionMapLocked = '境界不足，尚未解锁';
  static const String seclusionMapAvailable = '进入';
  static const String seclusionMapActive = '进行中';
  static const String seclusionMapReady = '可闭关';
  static const String seclusionMapAtlasTitle = '山水地点图册';
  static const String seclusionMapActiveHint = '已有闭关正在此地进行';
  // 地图卡产出加成摘要 / 进行中提示(_mapBonusSummary + _activeHint)。
  static const String seclusionBonusEquipDrop = '兵器掉率 +50%';
  static const String seclusionBonusTechniqueLearn = '心法领悟 +50%';
  static const String seclusionBonusInternalForce = '内力增长 +50%';
  static const String seclusionBonusBalanced = '综合产出';
  static const String seclusionMapActiveDoneHint = '已完成，可收功';
  static String seclusionMapActiveRemainingHint(int remainingMinutes) =>
      '剩余 ${remainingMinutes ~/ 60}h${remainingMinutes % 60}min，可查看';

  static const String seclusionSetupTitle = '选择时长';
  static const String seclusionSetupStartButton = '开始闭关';
  static String seclusionHourlyPreview(double scale) =>
      '每小时预估产出（境界加成 ×${scale.toStringAsFixed(2)}）';
  static String seclusionEstimatedMojianshi(int amount) => '预估磨剑石 ×$amount';
  static String seclusionStayCardTitle(int hours) => hours == 1
      ? '驻留片刻'
      : hours == 4
      ? '半日闭关'
      : '长夜闭关';
  static const String seclusionStarting = '请稍候…';

  static const String activeRetreatTitle = '闭关中';
  static const String activeRetreatCollect = '收功';
  static const String activeRetreatEarlyCollect = '提前收功';
  static const String activeRetreatDone = '已完成';
  static const String activeRetreatProgressTitle = '行功进度';
  static const String activeRetreatStateSeal = '入定闭关';
  static const String activeRetreatDoneHint = '气息已满，可收功离山';
  static const String activeRetreatEarlyHint = '行功未满，提前收功将按实际时长结算';
  static String activeRetreatTimeRange(String start, String end, int hours) =>
      '$start → $end（$hours h）';
  static String activeRetreatProgressPct(int pct) => '$pct%';
  static const String activeRetreatConfirmTitle = '确认提前收功';
  static const String activeRetreatConfirmBody = '现在收功将按实际时间结算，是否确认？';
  static const String activeRetreatConfirm = '确认';
  static const String activeRetreatCancel = '取消';

  static const String seclusionResultTitle = '闭关收获';
  static const String seclusionResultReportTitle = '收功战报';
  static const String seclusionResultEmpty = '此次收获甚微';
  static const String seclusionResultBack = '返回';

  static String seclusionRequiredRealm(String realmName) => '需要境界：$realmName';
  static String seclusionDurationLabel(int hours) => '$hours 小时';
  static String seclusionMojianshi(int n) => '磨剑石 × $n';
  static String seclusionInternalForce(int n) => '内力 +$n';
  static String seclusionInsightPoints(int n) => '心法领悟点 +$n';
  // 根因A B3 sink 引导(2026-05-29):结算屏 insightPoints>0 时提示去「心法面板」
  // 凝练为修炼度,让死钱包→修炼度路径更显(§5.7 气泡提示,非教程弹窗)。
  static const String seclusionInsightHint = '领悟点可在「心法面板」凝练为修炼度';
  static String seclusionExperience(int n) => '经验 +$n';
  static String seclusionAdvancement(String realmAfter, int layers) =>
      layers == 1 ? '突破至 $realmAfter' : '连破 $layers 层 → $realmAfter';
  static String seclusionActualHours(double h) =>
      '实际挂机 ${h.toStringAsFixed(1)} 小时';
  static String seclusionExpected(String key, double perHour) =>
      '$key：${perHour.toStringAsFixed(1)}/h';

  // ── P1 #42 Phase 4 · BaikeScreen 江湖见闻录(GDD §10.2 第 3 方式)──

  static const String mainMenuBaike = '江湖见闻录';
  static const String mainMenuBaikeHint = '记事与典故,永久可查';

  static const String baikeScreenTitle = '江湖见闻录';
  static const String baikeTabFeed = '见闻';
  static const String baikeTabLore = '典故';
  static const String baikeTabCodex = '机制';
  static const String baikeFeedEmpty = '尚无见闻,且看下回。';
  static const String baikeLoreEmpty = '装备尚浅,典故未集。';
  static const String baikeCodexEmpty = '机制百科尚未编纂。';

  // P1 #42 Phase 2 §10 P1.z 机制百科条目状态
  static const String codexLockedTitle = '待解锁';
  static const String codexLockedBody = '修行未至,机缘未到。';
  static const String codexUnlockedHintLabel = '已解锁';
  static String codexUnlockedHint(int unlocked, int total) =>
      '$codexUnlockedHintLabel $unlocked / $total';
  // P2 扩段:江湖背景段标题(永久可查,与 8 档机制分段)
  static const String codexLoreSectionTitle = '江湖背景';

  // ── P1 #42 Phase 3 · HomeFeedScreen 上线第一屏(GDD §9.2)──

  static const String homeFeedTitle = '江湖见闻';
  static const String homeFeedEmptyHint = '江湖初醒，昨夜风平浪静。\n按下「直入江湖」启程。';
  static const String homeFeedQuickClaimLabel = '直入江湖';

  /// GameEvent occurredAt 相对时间格式(GDD §9.2 "昨晚发生的事"调子)。
  ///
  /// 阈值:
  /// - < 5 分钟:"刚才"
  /// - 5-59 分钟:"$N 分钟前"
  /// - 1-23 小时:"$N 小时前"
  /// - 同一日:"今日 HH:MM"
  /// - 1 日前:"昨日 HH:MM"
  /// - 2-6 日前:"$N 日前"
  /// - > 7 日:"MM-DD"
  static String homeFeedRelativeTime(DateTime occurredAt, DateTime now) {
    final diff = now.difference(occurredAt);
    if (diff.inMinutes < 5) return '刚才';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24 && now.day == occurredAt.day) {
      final hh = occurredAt.hour.toString().padLeft(2, '0');
      final mm = occurredAt.minute.toString().padLeft(2, '0');
      return '今日 $hh:$mm';
    }
    final daysAgo = now
        .difference(DateTime(occurredAt.year, occurredAt.month, occurredAt.day))
        .inDays;
    if (daysAgo == 1) {
      final hh = occurredAt.hour.toString().padLeft(2, '0');
      final mm = occurredAt.minute.toString().padLeft(2, '0');
      return '昨日 $hh:$mm';
    }
    if (daysAgo < 7) return '$daysAgo 日前';
    final mm = occurredAt.month.toString().padLeft(2, '0');
    final dd = occurredAt.day.toString().padLeft(2, '0');
    return '$mm-$dd';
  }

  // ── P1 #42 Phase 2 · GameEvent 9 type 文案模板(GDD §9.2 昨晚发生的事)──

  // #1 retreatCompleted
  static const String gameEventRetreatTitle = '闭关收功';
  static String gameEventRetreatSummary(
    String charName,
    int actualHours,
    String mapName,
  ) => '$charName 于「$mapName」闭关 $actualHours 时，今晨收功。';

  // #2 adventureTriggered
  static String gameEventAdventureSummary(String encounterTitle) =>
      '江湖偶遇：$encounterTitle。';

  // #3 equipmentObtained
  static String gameEventEquipmentTitle(String equipName) => '得 $equipName';
  static String gameEventEquipmentSummary(String equipName, String source) =>
      '于「$source」得 $equipName，藏入囊中。';

  // #5 skillEnlightened
  static String gameEventSkillTitle(String skillName) => '悟得「$skillName」';
  static String gameEventSkillSummary(String skillName) =>
      '心头一动，悟得武学「$skillName」。';

  // #6 realmBreakthrough(主角) / #9 disciplePromoted(弟子)
  static const String gameEventBreakthroughTitle = '境界突破';
  static String gameEventDiscipleTitle(String discipleName) =>
      '$discipleName 突破';
  static String gameEventBreakthroughSummary(String charName, String realm) =>
      '$charName 修为精进，已至 $realm。';

  // #7 resonanceUpgraded
  static String gameEventResonanceTitle(String equipName) => '$equipName 共鸣晋阶';
  static String gameEventResonanceSummary(String equipName, int newStage) =>
      '$equipName 历经血战，共鸣度晋至第 $newStage 阶。';

  // #8 bossDefeated
  static String gameEventBossTitle(String bossName) => '斩 $bossName';
  static String gameEventBossSummary(String bossName, String stageName) =>
      '于「$stageName」一战胜 $bossName，江湖见闻。';

  // ── P1 #42 Phase 5 · 延续典故文案模板(GDD §6.6,挂账 #44 推 Phase 2 抽 yaml)──
  // 当前 Dart 端模板违反 CLAUDE.md §5.6,接受作为占位,挂账 #44 推 DeepSeek
  // 端写 data/lore/<id>.yaml 的 continued_lore 字段池。

  static String continuedLoreObtained(String equipName, String source) =>
      '于「$source」得此 $equipName，初见锋芒。';

  static String continuedLoreBossDefeated(String bossName, String stageName) =>
      '$bossName 一战，伴你穿身，沾血未崩。';

  // ── P1 #42 Phase 5 · EquipmentDetailScreen 延续典故 chip ──
  static const String continuedLoreChipLabel = '延续';

  // ── P1.1 A1 E.1 · 收徒弹窗(GDD §7.1)──
  static const String recruitmentDialogTitle = '择徒授业';
  static const String recruitmentDialogIntro =
      '内功既至一流,开派祖师可收徒授业。三位投奔者已至门前,可择其一拜入门下;也可暂且谢绝,待来日再议。';
  static const String recruitmentSchoolGangMengLabel = '刚猛';
  static const String recruitmentSchoolLingQiaoLabel = '灵巧';
  static const String recruitmentSchoolYinRouLabel = '阴柔';
  static const String recruitmentSchoolNoneLabel = '无流派';
  static const String recruitmentAttrConstitutionLabel = '根骨';
  static const String recruitmentAttrEnlightenmentLabel = '悟';
  static const String recruitmentAttrAgilityLabel = '身法';
  static const String recruitmentAttrFortuneLabel = '机缘';
  static const String recruitmentAcceptButton = '拜师';
  static const String recruitmentDeclineButton = '谢绝';
  static const String recruitmentConfirmTitle = '确认收徒';
  static String recruitmentConfirmBody(String name) =>
      '收 $name 为徒,自此师徒名分既定,不可悔改。';
  static const String recruitmentConfirmYes = '确认';
  static const String recruitmentConfirmNo = '再想想';
  static const String recruitmentDeclineConfirmTitle = '谢绝收徒';
  static const String recruitmentDeclineConfirmBody =
      '此乃一次性时机,谢绝即此生不再收徒。是否仍要谢绝?';
  static String recruitmentSuccessSnack(String name) => '$name 已拜入门下';
  static const String recruitmentDeclineSnack = '已谢绝收徒,门派维持三人';
  static const String recruitmentStartingTechniqueLabel = '起手心法';
  static const String recruitmentStartingEquipmentLabel = '起手装备';
  static const String recruitmentNoStartingTechnique = '无(待师父亲授)';

  // ── P1.1 A1 E.1 · LineagePanelScreen inactive 段 ──
  static const String lineagePanelInactiveSection = '在册弟子(未出阵)';
  static const String lineagePanelNoInactive = '尚无在册弟子';

  // ── P1.1 A1 E.5 · LineagePanelScreen 祖师爷 buff 摆台 ──
  static const String lineagePanelFounderBuffSection = '祖师爷光环';
  static const String lineagePanelFounderBuffSubtitle =
      '开派祖师在堂,门派内众弟子修为得益。作用于出阵全员。';
  static const String lineagePanelFounderBuffInternalForce = '内力上限';
  static const String lineagePanelFounderBuffMaxHp = '最大血量';
  static const String lineagePanelFounderBuffCritRate = '暴击率';
  static const String lineagePanelFounderBuffCultivation = '修炼度获取';

  // ── P2.3 §7.1 飞升 + 遗物 transfer(spec p2_3_ascension_spec_2026-05-24)──
  static const String ascensionPanelSection = '飞升渡劫';
  static const String ascensionPanelHint = '武圣登峰后,可传位遗物于弟子,自此退出江湖。';
  static const String ascensionPanelButton = '步入飞升';
  static const String ascensionPanelLocked = '飞升条件未满足';
  static const String ascensionTitle = '飞升渡劫';
  static const String ascensionRitualHint =
      '渡劫之夜,你将取最贴身的一二件兵刃甲胄,亲手赠予弟子。其余之物随你而去。';
  static const String ascensionPickEquipment = '选 1-2 件遗物传予弟子';
  static const String ascensionAssignTo = '分配给';
  static const String ascensionSelectionStatus = '已选 {0} / {1} 件';
  static const String ascensionConfirmButton = '确认飞升';
  static const String ascensionConfirmDialogTitle = '飞升渡劫';
  static const String ascensionConfirmDialogBody =
      '飞升之后你将退出江湖,门派由弟子继承。\n此举无法回头,确认?';
  static const String ascensionConfirmDialogOk = '确认飞升';
  static const String ascensionConfirmDialogCancel = '再思量片刻';
  static const String ascensionCompleteSnackbar =
      '飞升渡劫已成 · 已传 {0} 件遗物 · 你已退出江湖';
  static const String ascensionNoEquipments = '尚无装备可传';
  static const String ascensionNoDisciples = '尚无可继承弟子';

  // P5+ 真传位(spec p5_lineage_full_spec §Q1+Q2 · ④+⑤ 合并 batch)
  static const String ascensionPromotedSection = '传位于';
  static const String ascensionPromotedHint =
      '飞升后,此弟子接任祖师之位,统领门派 · 享祖师 buff(基础 +5% 内力上限/血量 · +2% 暴击)';
  static const String ascensionPromotedNone = '不传位(留待来日)';
  static const String ascensionMultiGenChip = '{0} 代传承';

  // P5+ UI polish 续作(本批)· dialog 内强调传位 + snackbar 追加接任人名
  static const String ascensionConfirmDialogPromotedLine = '门派衣钵:{0}';
  static const String ascensionCompletePromotedSuffix = ' · {0} 接掌门派';

  // P4.1 1.1 Q6B · Boss 战胜后招降 SnackBar(spec p4_1_q6b §4 · 沿 sectEncounterRecruit 体例)
  static String stageBossRecruitSuccess(String name) =>
      '$name 折服于你的剑下,入门派任 [初入] 阶';
  static String stageBossRecruitCapFull(String name) => '门派人数已满,$name 婉言告别';
  static String stageBossRecruitNoSect(String name) => '尚未建派,$name 不知归处';

  // 1.1 战败收降 SnackBar(stageBossFailRecoverProb 0.30 · 沿 stageBossRecruit 体例)
  static String stageBossFailRecoverSuccess(String name) =>
      '$name 感于你的血气,入门派任 [初入] 阶';
  static String stageBossFailRecoverCapFull(String name) => '门派人数已满,$name 转身离去';
  static String stageBossFailRecoverNoSect(String name) => '尚未建派,$name 不知归处';

  // P4.1 1.1 polish · character_panel 门派同道行(_SectMembershipRow · 沿 lineageDisciplesLabel 体例)
  static const String panelSectMembersLabel = '门派同道:';
  static const String panelSectMembersEmpty = '门派人少';

  // ── overnight Batch1:presentation 硬编码中文迁出(§5.6)──────────────────
  // A1 各子系统屏 AppBar 标题/按钮(原 inline const Text 字面迁出)。
  static const String innerDemonScreenTitle = '心魔';
  static const String lightFootScreenTitle = '轻功试炼';
  static const String massBattleScreenTitle = '守城试炼';
  static const String sectScreenTitle = '门派事务';
  static const String characterPanelScreenTitle = '角色面板';
  static const String breakthroughGoToInnerDemon = '前往心魔境';

  // ─── 心魔成长瓶颈面板(P0-3 ③)──────────────────────────────────────────
  static const String innerDemonPanelTitle = '心魔试炼';
  static String innerDemonPanelProgress(int cleared, int total) =>
      '$cleared / $total';
  static const String innerDemonBlockedTitle = '突破被拦';
  static String innerDemonBlockedBody(String stageName) =>
      '心魔关「$stageName」未通,经验留账';
  static String innerDemonNextLabel(String stageName) => '下一关:$stageName';
  static const String innerDemonClearedLabel = '心魔已尽,更无可破';
  static const String innerDemonBreakthroughCta = '突破';
  static const String sectEventEnterBattle = '应战赴会';
  // §5.6 审计抽出(2026-06-08):门派事件 dialog fallback / lazy-init / 拒绝按钮
  static const String sectLazyInitName = '无名宗';
  static const String sectEventNarrativeFallbackOpening = '事件触发,详情待载入。';
  static const String sectEventNarrativeFallbackVictory = '此役大胜,本派声威远播。';
  static const String sectEventNarrativeFallbackDefeat = '此役失利,归山再练。';
  static const String sectEventRefuseButton = '闭门谢客';
  static const String encounterSkillUnequipButton = '卸下';
  static const String commonCancel = '取消';

  // A2 SnackBar / 错误提示($e 变量用带参方法保留)。
  static const String encounterSkillUnequipSuccess = '已卸下奇遇招式';
  static String encounterSkillEquipFailed(Object e) => '装备失败: $e';
  static String encounterSkillUnequipFailed(Object e) => '卸下失败: $e';
  static String retreatCollectFailed(Object e) => '收功失败：$e';
  static String seclusionStartFailed(Object e) => '开始闭关失败：$e';
  static String ascensionFailed(Object e) => '飞升失败:$e';
  static String battleSetupFailed(Object e) => '战斗准备失败：$e';
  static String sectLoadFailed(Object e) => '加载失败:$e';

  // A5 剧情占位提示(去退役 DeepSeek 术语)。
  static const String narrativePlaceholderHint = '⚠ 剧情占位（待补）';

  // ── overnight Batch5:清理 round-2 剩余 presentation 硬编码中文(§5.6)──────
  // encounter_skill_section 剩余字面(复用既有 encounterSkill* 组)。
  static const String encounterSkillSectionTitle = '奇遇招式';
  static const String encounterSkillPickButton = '选择招式';
  static const String encounterSkillNoneAvailable = '尚无可装备奇遇招式';
  static const String encounterSkillSlotEmpty = '未装备奇遇招式';
  static const String encounterSkillPickerTitle = '选择奇遇招式';
  static const String encounterSkillEquipped = '已装备';
  // :188「该招式尚未 unlock」中英混排统一为中文。
  static const String encounterSkillNotUnlocked = '该招式尚未领悟';
  static String encounterSkillTierLocked(int requiredTier, String current) =>
      '境界不足:需 tier $requiredTier,当前 $current';
  static String encounterSkillEquipFailedReason(String reason) =>
      '装备失败: $reason';
  static String encounterSkillDefMissing(String id) => '招式定义缺失: $id';

  // sect_screen 空状态。
  static const String sectNotCreated = '门派尚未创建';

  // equipment_detail 属性标签 + 典故段。
  static const String equipStatAttack = '攻击';
  static const String equipStatHealth = '血量';
  static const String equipStatSpeed = '速度';
  static const String loreEmptyPlaceholder = '典故待补';
  static const String loreSectionDivider = '◇ 典故 ◇';

  // narrative_reader 翻页按钮。
  static const String narrativeReaderFinish = '完成';
  static const String narrativeReaderContinue = '继续';

  /// G4 · 首段轻点提示(§5.7 气泡引导,仅首段显一次,点明轻点画面/按钮即可往下读)。
  static const String narrativeReaderTapHint = '轻点画面，继续往下读';

  // seclusion_setup 产出维度标签。
  static const String seclusionOutputMojianshi = '磨剑石';
  static const String seclusionOutputExperience = '经验';
  static const String seclusionOutputEquipDrop = '兵器掉率';
  static const String seclusionOutputTechniqueLearn = '心法领悟';
  static const String seclusionOutputInternalForce = '内力增长';

  // ── overnight Batch7:encounter_dialog §5.6 残留迁移 ──────────────────────
  static const String encounterDialogTitleFallback = '机缘';
  static const String encounterDialogTitleLabel = '机缘';
  static const String encounterDialogOutcomeBodyFallback = '此情此景,已铭于心。';
  static const String encounterDialogConfirmButton = '行路 →';
  // outcome banner($ 变量用带参方法,enum 映射由 caller 解析后传入)。
  static const String encounterOutcomeSkillTitle = '灵光一现';
  static const String encounterOutcomeAttributeTitle = '机缘入身';
  static const String encounterOutcomeCapTitle = '造化已满';
  static const String encounterOutcomeNoneTitle = '机缘已记';
  static String encounterOutcomeSkillUnlocked(String skillName) =>
      '领悟新招:$skillName';
  static String encounterOutcomeAttributeBonus(String attrName, int delta) =>
      '$attrName +$delta';
  static String encounterOutcomeCapReached(int cap) => '已达生涯造化极限(总加 $cap)';
  static const String encounterOutcomeNone = '心中默念,继续前行';
}
