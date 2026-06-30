import '../core/domain/item_source.dart';
import '../core/domain/item_usage.dart';
import '../core/domain/resource_overview_display.dart';

enum CombatTerm { charge, interrupt, zhenqi, yuti, phase, heavyInjury }

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

  /// Debug hitbox overlay summary. Only shown in debug visual route builds.
  static String hitboxDebugSummary(int count) => '命中框调试 · $count';

  /// P0-4(2026-06-29 审查修复):统一错误兜底文案。原始异常不上屏(走
  /// debugPrint),玩家只见友好中文 + 可选「重试」。
  static const String errorFallbackMessage = '数据加载异常，请重试';
  static const String errorRetry = '重试';
  static const String errorNoSaveTitle = '卷宗未启';

  /// 战斗顶栏标题：`战斗 N v M`，N/M 为双方存活人数。
  static String battleTitle(int leftAlive, int rightAlive) =>
      '战斗 $leftAlive v $rightAlive';

  static const String tickPrefix = '回合';
  static const String battleLog = '战斗日志';
  // H3:战斗暂停(停 tick + 遮罩 + 继续)。
  static const String battlePause = '暂停';
  static const String battleResume = '继续';
  static const String battlePausedTitle = '已暂停';
  // 验收路由专用(startPaused):暂停态逐步推进战斗,仅 debug 渲染,生产挂机不出现。
  static const String battleStepOnce = '单步';
  // H3:投降(主动认输撤退 · 二次确认 · 无掉落 / Boss 不散功)。
  static const String battleSurrender = '投降';
  static const String surrenderConfirmTitle = '认输撤退';
  static const String surrenderConfirmMessage =
      '确定认输撤退?本场不计掉落,Boss 关也不折损修为,只是退回去重整旗鼓。';
  static const String surrenderConfirmAction = '撤退';
  static const String surrenderCancelAction = '再打打';
  // M3:普通关战败立即重试(Boss 关不给 · 试错免费无惩罚)。
  static const String stageRetryTitle = '功亏一篑';
  static const String stageRetryPrompt = '这一战未能取胜。要再试一次吗?';
  static const String stageRetryAction = '再战';
  static const String stageRetryBackAction = '返回';
  static const String emptyLog = '（无动作）';
  static const String ultimate = '大招';
  static const String fastForward = '快进';

  static String combatTermLabel(CombatTerm term) => switch (term) {
    CombatTerm.charge => '蓄力',
    CombatTerm.interrupt => '破招',
    CombatTerm.zhenqi => '真气',
    CombatTerm.yuti => '御体',
    CombatTerm.phase => '相位',
    CombatTerm.heavyInjury => '重伤',
  };

  static String combatTermGloss(
    CombatTerm term, {
    String? pct,
    double? hours,
    int? attackPenaltyPct,
    int? internalForcePenaltyPct,
  }) => switch (term) {
    CombatTerm.charge => '蓄力：敌方招牌技发动前的预备状态。倒数结束会释放重招，可用破招截断。',
    CombatTerm.interrupt => '破招：命中蓄力中的目标可打断其招牌技，并让目标短暂踉跄、防御骤降。',
    CombatTerm.zhenqi => '真气：敌方内力上限提高 ${pct ?? ''}，更容易多放一次大招。',
    CombatTerm.yuti => '御体：敌方防御率提高 ${pct ?? ''}，更耐久，适合用克制流派或破甲手段处理。',
    CombatTerm.phase => '相位：Boss 血量跌破阈值后的阶段变化，会切换招式节奏或触发蓄力反扑。',
    CombatTerm.heavyInjury =>
      '重伤：硬仗战败或惨胜后的伤势。'
          '调息 ${hours?.ceil() ?? 0}h，输出 -${attackPenaltyPct ?? 0}%，'
          '内力上限 -${internalForcePenaltyPct ?? 0}%。',
  };

  // P0 破招
  static const String battleInterruptSkill = '破招';
  // T2 蓄力危险条：敌人正在蓄力大招的顶部警示（招名 + 剩余回合）。
  static String battleDangerCharging(
    String enemyName,
    String skillName,
    int ticks,
  ) =>
      '$enemyName 正在${combatTermLabel(CombatTerm.charge)}：$skillName（还有 $ticks 回合发动）';
  static const String battleDangerPrefix = '⚠ ';

  // T1 战斗指令台：技能分组标签 + 状态印 + 内力/冷却短标。
  static const String skillGroupPower = '强力';
  static const String skillGroupJoint = '共鸣';
  // 破招用 [battleInterruptSkill]='破招'、大招用 [ultimate]='大招'。
  static const String skillPendingStamp = '待发';
  // 可用态：耗内 N · CD M（让玩家知道耗的是内力、看得到基础 CD）。
  static String skillCostShort(int cost, int cooldown) =>
      '耗内$cost · CD$cooldown';
  static String skillCooldownShort(int turns) => '冷却$turns';
  // 内力不足态短标。
  static const String skillInsufficientForce = '内力不足';
  // 批次 1.3 技能简介浮层：点击技能方块弹出，直接读 SkillDef 活数据。
  // 字段标签（左列），值由活数据 / EnumL10n 填。
  static const String skillInfoType = '类型';
  static const String skillInfoTarget = '目标';
  static const String skillInfoPower = '倍率';
  static const String skillInfoCost = '耗内';
  static const String skillInfoCooldown = '冷却';
  static const String skillInfoTrait = '特性';
  // 特性值：可打断 → 破招（命中蓄力中目标可打断其招牌技）。
  static String get skillTraitInterrupt =>
      '${combatTermLabel(CombatTerm.interrupt)} · 可打断${combatTermLabel(CombatTerm.charge)}';
  // 无特殊特性时的占位（普通技无可打断等标签）。
  static const String skillTraitNone = '无';
  // 冷却值单位（回合）。
  static String skillInfoCooldownTurns(int turns) => '$turns 回合';
  // 浮层底部操作提示：长按拖到敌人头像下发。
  static const String skillInfoDragHint = '长按方块拖到目标头像下发';
  // 浮层关闭按钮。
  static const String skillInfoClose = '知道了';
  // 角色头像内力条标签前缀（HpBar labelPrefix），如「内 100 / 100」。
  static const String internalForceShortLabel = '内 ';
  // B3 破招成功「破！」题字 overlay 文案(破招方暖金/敌方绛红)。
  static const String interruptCaption = '破！';
  // 批次 2.4 打击感单字效果字（重击非破招非大招）。破由现有 interruptCaption 承载。
  static const String impactGlyphZhan = '斩'; // 灵巧 / 无流派 默认
  static const String impactGlyphZhen = '震'; // 刚猛
  static const String impactGlyphDuan = '断'; // 阴柔
  // 第六阶段 开窗题字：破防打开破绽窗口时弹出（互斥于 interrupted 的「破!」）。
  static const String impactGlyphBreakWindow = '破绽'; // 破防开窗
  // 第六阶段 破绽窗口指令栏提示：敌方踉跄期间出现，引导玩家拖招爆发技。
  static const String coopBurstPrompt = '破绽 · 该爆发了';
  // 第七阶段批二 ②：会心题字（命中守方弱点流派 mult>1.0 时弹）。2 字适配单字
  // glyph overlay box（200px / 72pt），区别于多字转阶段标题走 caption overlay。
  static const String weaknessHitGlyph = '会心';

  // 第七阶段批二 ①：Boss 转阶段题字短标题（4 字水墨）。
  // BossPhaseDef.titleKey → 显示标题；未知 / null → 空串（调用方走
  // EnumL10n.bossPhaseTransition 通用兜底）。中文集中此 sink，不内联进 widget。
  static String bossPhaseTitle(String? key) {
    return switch (key) {
      'bossPhase_awaken' => '困兽之斗',
      'bossPhase_desperate' => '背水一击',
      _ => '',
    };
  }

  // 伤害飘字（T15）
  static const String dodge = '闪';
  static const String counterUp = '⬆';
  static const String counterDown = '⬇';

  // 战斗结算（T16）
  static const String close = '关闭';
  static const String backToMenu = '返回菜单';
  static const String unknown = '未明';

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

  // ── 战报失败诊断（spec 2026-06-15-battle-report-diagnosis）──
  static String defeatShortfallLabel(String label) => '主要短板：$label';
  static String defeatShortfallName(String name) {
    return switch (name) {
      'realm' => '等级 / 境界',
      'equipment' => '装备',
      'technique' => '心法 / 招式',
      'roster' => '阵容',
      'counter' => '流派克制',
      'supplies' => '补给 / 续航',
      _ => unknown,
    };
  }

  // 主因（1 条/规则）
  static const String diagCauseRealm = '境界差距压住了招式';
  static const String diagCauseCharge = '被 Boss 蓄力大招击溃';
  static const String diagCauseCounter = '主力流派被对面克住';
  static const String diagCauseInternalWound = '被内伤层层拖垮';
  static const String diagCauseMob = '被群敌围殴拖死';
  static const String diagCauseFrontline = '前排太脆，过早倒下';
  static const String diagCauseSupplies = '续航不足，伤势拖到见底';
  static const String diagCauseDps = '输出不足，未能速决';
  static const String diagCauseGeneric = '惜败，调整战术后再战';

  // 关键数据（2 条/规则）
  static String diagPlayerTopRealm(String realm) => '己方最高境界：$realm';
  static String diagEnemyTopRealm(String realm) => '敌方最高境界：$realm';
  static String diagLethalHit(String skill, int dmg) => '致命一击：$skill $dmg';
  static String diagInternalForceLeft(int cur, int max) => '内力余量：$cur/$max';
  static String diagCounteredDamageRatio(int pct) => '受克制伤害占比：$pct%';
  static String diagDominantEnemySchool(String school) => '敌方主攻流派：$school';
  static String diagInternalWoundRatio(int pct) => '内伤占比：$pct%';
  static String diagDamageTaken(int dmg) => '受到总伤：$dmg';
  static String diagMinionRatio(int pct) => '小怪伤害占比：$pct%';
  static String diagFrontlineDeath(String name, int tick) =>
      '$name 在第 $tick 回合倒下';
  static String diagFrontlineMaxHp(int hp) => '其最大血量：$hp';
  static String diagRecoveryDone(int hp) => '战中回复：$hp';
  static String diagTotalTicks(int tick) => '总回合：$tick';
  static String diagSurvivorHp(int pct) => '敌方残血：平均 $pct%';
  static String diagTotalDamage(int dmg) => '总伤害：$dmg';

  // 建议（1 条/规则）
  static const String diagSuggestRealm = '先闭关推境界，再回来碰硬仗。';
  static const String diagSuggestCharge = '保留内力、装配破招技，看准蓄力时机破招。';
  static const String diagSuggestCounter = '换一名主修不被克的门人上阵，或调整主修流派。';
  static const String diagSuggestInternalWound = '备好回复，或换能压住内伤的心法。';
  static const String diagSuggestMob = '补一名清场手，先清场再攻坚。';
  static const String diagSuggestFrontline = '强化护具、以虚弱/回复护住前排。';
  static const String diagSuggestSupplies = '查看药囊、疗伤丹与带回复的装备。';
  static const String diagSuggestDps = '提升技能熟练度，使用破防技提速。';
  static const String diagSuggestGeneric = '检视技能装配，调整后再战。';

  // 跳转按钮 label
  static const String diagJumpSkills = '查看技能装配';
  static const String diagJumpEquipment = '查看装备';
  static const String diagJumpCultivation = '查看心法';
  static const String diagJumpRoster = '查看角色面板';
  static const String diagJumpSupplies = '查看行囊补给';

  // 主菜单（T32 子提交 3b；G1 剥「调试」字样,production-facing 产品名）
  static const String mainMenuTitle = '挂机武侠';
  // 开场闪屏:加载中提示 + 加载完成「轻触继续」(放慢一闪而过的开场 + 给跳过出口)。
  static const String splashLoadingHint = '正在展卷……';
  static const String splashTapToContinue = '轻触继续';

  /// 主菜单副标题（Phase A 出版美术 · 题字感）。
  static const String mainMenuSubtitle = '一剑霜寒 · 江湖路远';

  /// 主菜单入口分组标签（视觉批次 · 水墨行程版式）。
  static const String mainMenuGroupJourney = '江湖行程';
  static const String mainMenuGroupJourneyHint = '主线、登塔与各路试炼';
  static const String mainMenuGroupGrowth = '养成经营';
  static const String mainMenuGroupGrowthHint = '门人、装备、闭关与产业';
  static const String mainMenuGroupArchive = '档案藏卷';
  static const String mainMenuGroupArchiveHint = '谱牒、战绩、见闻与榜单';
  static const String mainMenuGroupSettings = '设置与系统';
  static const String mainMenuGroupSettingsHint = '音量、显示与舒适性';
  static const String mainMenuGroupDebug = '调试';
  static const String mainMenuGroupDebugHint = '开发期校验入口';

  /// 主菜单「今日节日」chip（W16 GDD §12.4）。
  /// [festivalName] 走 [EnumL10n.festival]，例：「今日：春节」。
  static String mainMenuTodayFestival(String festivalName) =>
      '今日：$festivalName';

  // 主菜单状态摘要二期（只读派生，不改变结算 / 门槛 / 收益）。
  static const String mainMenuStatusSummaryTitle = '当前要事';
  static const String mainMenuStatusRetreatTitle = '闭关中';
  static const String mainMenuStatusIslandTitle = '桃花岛可收';
  static const String mainMenuStatusInjuryTitle = '伤势待处理';
  static const String mainMenuStatusBreakthroughTitle = '修为已满';
  static const String mainMenuStatusMainlineTitle = '主线目标';
  static const String mainMenuStatusMainlineCompleteDetail = '江湖主线已收束';
  static String mainMenuStatusRetreatDetail(String mapName, String remaining) =>
      '$mapName · $remaining';
  static String mainMenuStatusRetreatCappedDetail(String mapName) =>
      '$mapName · 收益已满';
  static String mainMenuStatusIslandDetail(int count) => '约$count 件产物待收';
  static String mainMenuStatusInjuryDetail(int count, double maxHours) {
    if (maxHours <= 0) return '$count 名角色需调息';
    return '$count 名角色需疗养 · 最长 ${maxHours.toStringAsFixed(1)} 小时';
  }

  static String mainMenuStatusBreakthroughDetail(String name) =>
      '$name 经验已满，查看瓶颈';
  static String mainMenuStatusMainlineDetail(int chapterIndex, String stage) =>
      '前往第$chapterIndex章 · $stage';

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
  static const String mainMenuResourceOverview = '资源总览';
  static const String mainMenuResourceOverviewHint = '库存 / 来源 / 用途一屏可察';
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
  // T10 已穿装备快捷操作面板。
  static const String equipQuickReplace = '更换装备';
  static const String equipQuickViewLore = '查看典故';
  static const String equipLockedByRealm = '境界不足,无法装备(三系锁死)';
  static const String equipProtectedCurrent = '当前装备受保护,请先卸下或解锁';
  // 装备槽对话框(2026-06-26 · 一步到位 + 全量对比两栏)。
  static const String equipSlotDialogConfirm = '确认更换';
  static const String equipSlotDialogEquip = '装备';
  static const String equipSlotDialogPickHint = '选一件查看属性';
  static const String equipSlotDialogCompareTitle = '属性对比';
  static const String equipSlotDialogForgingLabel = '开锋';
  static const String equipRealmLockedPill = '境界不足';
  static const String equipmentCompareAttack = '实战攻击';
  static const String equipmentCompareHealth = '实战血量';
  static const String equipmentCompareSpeed = '实战速度';
  static const String equipmentCompareEnhance = '强化等级';
  static const String equipmentCompareTier = '品阶';
  static const String equipmentCompareResonance = '共鸣';
  static const String equipmentCompareSchool = '流派';
  static const String equipmentCompareHeritage = '师承遗物';
  static const String equipmentCompareEmptyForging = '—';
  static const String equipmentCompareSchoolNone = '无';
  static const String equipmentCompareHeritageYes = '遗物';
  static const String equipmentCompareHeritageNo = '—';
  static const String equipmentDeltaUp = '提升';
  static const String equipmentDeltaDown = '下降';
  static const String equipmentDeltaFlat = '持平';
  static const String equipmentDeltaChanged = '更替';
  static const String equipmentDeltaBaseline = '新增';
  static const String equipmentStatAttackShort = '攻';
  static const String equipmentStatHealthShort = '血';
  static const String equipmentStatSpeedShort = '速';
  static const String equipmentDeltaUpGlyph = '↑';
  static const String equipmentDeltaDownGlyph = '↓';
  static const String equipmentDeltaFlatGlyph = '·';
  static String equipRealmLockHint(String realm) => '需达$realm境界';
  static String equipmentDeltaValue(int delta) {
    if (delta > 0) return '+$delta';
    if (delta < 0) return '$delta';
    return equipmentDeltaFlat;
  }

  /// H1 批3 picker 标注:该装备正被队内其他角色穿戴,选它会移装(原角色卸下)。
  /// 自由池移装是合理调配,故只标注提醒不禁用(去掉「静默卸下弟子」的意外感)。
  static const String equipWornByOther = '他人装备中';
  static const String mainMenuLineage = '门派谱';
  static const String mainMenuLineageHint = '查看祖师与弟子的传承链路';

  // ─── 江湖商店 + 货币(P4 材料经济)──────────────────────────────────────────
  static const String mainMenuShop = '江湖商店';
  static const String mainMenuShopHint = '采办所需，行走江湖';
  static const String shopTitle = '江湖商店';
  static const String shopBuy = '购买';
  static const String shopInsufficientSilver = '银两不足';

  /// balance T3：无法获取祖师经验信息，动态标价商品不可购买。
  static const String shopPricingUnavailable = '当前无法定价，请稍候';
  static const String shopFilterAll = '全部';
  static const String shopFilterAffordable = '可买';
  static const String shopFilterNeedSaving = '需攒钱';
  static const String shopFilterWatch = '关注';
  static const String shopStatusAffordable = '可买';
  static const String shopStatusPricingPending = '待定价';
  static const String shopStatusDynamicPrice = '随境界标价';
  static const String shopWatchHint = '值得关注';
  static const String shopCategoryMaterial = '炼器材料';
  static const String shopCategoryPill = '药品';
  static const String shopCategoryEquipment = '装备';
  static const String shopCategoryTechniqueClue = '心法线索';
  static const String shopCategoryOther = '杂项';
  static const String shopShelfGroupCultivation = '修行补给';
  static const String shopShelfGroupEnhancement = '兵刃强化';
  static const String shopShelfGroupForging = '开锋整备';
  static const String shopShelfGroupRecovery = '疗伤补给';
  static const String shopShelfGroupIslandProduction = '桃花岛营造';
  static const String shopShelfGroupTechnique = '武学秘卷';
  static const String shopShelfGroupCommon = '行囊常备';
  static const String shopShelfGroupCultivationDesc = '补足修为进境，标价随当前境界同步。';
  static const String shopShelfGroupEnhancementDesc = '强化、保底相关材料，按现有货架采买。';
  static const String shopShelfGroupForgingDesc = '开锋相关整备物，只显示当前货架已有项。';
  static const String shopShelfGroupRecoveryDesc = '伤后整备所需物，只显示当前货架已有项。';
  static const String shopShelfGroupIslandProductionDesc =
      '岛上修缮与加工牵涉物，只读分层不改产出。';
  static const String shopShelfGroupTechniqueDesc = '武学与秘籍相关线索，仍守江湖偶得。';
  static const String shopShelfGroupCommonDesc = '暂未归入专门用途的常备之物。';
  static String silverBalanceLabel(int n) => '银两 $n';
  static String shopItemPrice(int p) => '$p 两';
  static String shopFilterLabel(String label, int count) => '$label $count';
  static String shopNeedSilver(int n) => '还差 $n 两';
  static String shopOwnedQuantity(int n) => '已有 ×$n';
  static String shopCategorySummary({
    required int total,
    required int affordable,
    required int needSaving,
  }) => '$total 件 · $affordable 可买 · $needSaving 需攒钱';
  static String shopItemPurpose(String itemDefId) => switch (itemDefId) {
    'item_mojianshi' => '强化兵刃的常用材料，适合先备几块。',
    'item_xinxuejiejing' => '强化受挫后积攒的硬材料，后段开销更紧。',
    'item_jingyandan_small' => '补一截境界经验，适合临近升层时补足。',
    'item_jingyandan_mid' => '补更多境界经验，标价随当前境界同步上涨。',
    _ => '江湖行走备用之物。',
  };
  static String shopNeedCurrentUsers(List<String> names) {
    if (names.isEmpty) return '当前可用：暂无合适角色';
    return '当前可用：${names.take(3).join(' / ')}';
  }

  static String shopNeedUsageSummary(List<ItemUsage> usages) {
    final summary = materialUsageSummary(usages);
    return summary.isEmpty ? '' : '消耗系统：$summary';
  }

  static String shopNeedAlternateSourceSummary(List<ItemSource> sources) {
    final labels = <String>{
      for (final source in sources) itemSourceLabel(source),
    }..remove('');
    return labels.isEmpty ? '' : '其他来源：${labels.take(4).join(' / ')}';
  }

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
  /// 角色 provider 返回 null 时各面板的兜底空态文案（审计 E1 2026-06-24 集中归集）。
  static const String characterNotFound = '角色不存在';

  /// 叙事/剧情阅读器跳过按钮（审计 E2 2026-06-24 集中归集）。
  static const String narrativeSkip = '跳过';

  static const String panelAttributes = '基础属性';
  static const String panelIdentity = '身份信息';
  static const String panelRealmCultivation = '境界修为';
  static const String panelDerived = '战斗属性';
  static const String panelEquipment = '装备概况';
  static const String panelTechnique = '心法概况';
  static const String panelStatusEffects = '状态效果';
  static const String profileRealmLabel = '境界';
  static String realmEquipmentCap(String tier) => '可用装备：$tier';
  static const String profileLevelLabel = '等级'; // 第八阶段·角色等级 Lv
  static const String profileLevelPeak = '巅峰';
  static String profileLevelValue(int level) => 'Lv $level';
  static String profileLevelProgress(int current, int next) =>
      '$current / $next';
  static const String levelUpCeremonyTitle = '修为精进'; // 第八阶段 D·Lv 升级 banner 标题
  static const String profilePortraitPlaque = '人物签';
  static const String characterBiographyTitle = '门人小传';
  static String characterBiographyRole(String role) => '身份 $role';
  static String characterBiographySchool(String school) => '路数 $school';
  static const String characterBiographySchoolUnset = '路数未定';
  static String characterBiographyEquipment(int equipped, int total) =>
      '装备 $equipped/$total';
  static String characterBiographyTechnique(int learned, int total) =>
      '心法 $learned/$total';
  static const String characterBiographyConditionHealthy = '状态安稳';
  static const String characterBiographyConditionInjured = '有伤待养';
  static const String lineageRoleFounder = '开派祖师';
  static const String lineageRoleDisciple = '门下弟子';
  static const String lineageRoleSenior = '大弟子';
  static const String lineageRoleJunior = '二弟子';
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

  // 门派谱 panel（W17 候选 E → 1.1 世代卷沿用）
  static const String lineagePanelNoFounder = '祖师未定';

  // 门派谱世代卷（1.1）
  static const String lineageCodexTitle = '门派谱';
  static String lineageCodexGenerationLabel(int gen) =>
      gen == 1 ? '第一代 · 太祖' : '第 $gen 代';
  static const String lineageCodexCurrentTag = '当代';
  static const String lineageCodexRetiredTag = '已退隐';
  static String lineageCodexProgress(int gens, int members) =>
      '传承 $gens 代 · 门人 $members 人';
  static const String lineageCodexNoDisciples = '孤身一人，传承待续';
  static const String lineageCodexNoHeritage = '尚无师承遗物';
  static const String lineageCodexHeritageSection = '师承遗物';
  static const String lineageCodexDiscipleSection = '门人';
  // 角色详情屏
  static const String lineageCharacterDetailTitle = '门人档案';
  static const String lineageCharacterDetailDeeds = '纪事';
  static const String lineageCharacterDetailAttributes = '资质';
  static const String lineageCharacterDetailMainTechnique = '主修';
  static const String lineageCharacterDetailHeritage = '所持师承遗物';
  static const String lineageCharacterDetailFounderBuff = '祖师恩泽';
  static const String lineageCharacterDetailConditionTitle = '状态';
  static String lineageCharacterDetailJoinedAt(int year, String stage) =>
      '江湖 $year 年，过「$stage」拜入';
  static String lineageCharacterDetailJoinedYearOnly(int year) =>
      '江湖 $year 年拜入';
  static String lineageCharacterDetailFounderGen(int gen) =>
      gen == 1 ? '开派太祖' : '第 $gen 代掌门';

  static const String attrConstitution = '根骨';
  static const String attrEnlightenment = '悟性';
  static const String attrAgility = '身法';
  static const String attrFortune = '机缘';

  static const String statHp = '生命';
  static const String statInternalForce = '内力';
  static const String statSpeed = '速度';
  static const String statCriticalRate = '暴击率';
  static const String statEvasionRate = '闪避率';

  // M4 术语释义气泡（GlossaryTip）：四项属性 + 派生数值 + 养成进度术语。
  // §5.7 框架下用悬停/长按气泡，非教程弹窗。文案水墨克制、不用网游词汇。
  static const String glossaryConstitution = '根骨：体魄根基，决定血量上限。根骨越厚，越能久战不溃。';
  static const String glossaryEnlightenment =
      '悟性：资质灵慧，影响修炼速度与武学领悟概率。悟性高者，一点即通。';
  static const String glossaryAgility = '身法：轻灵敏捷，决定出手速度与闪避。身法高者，快人一步。';
  static const String glossaryFortune = '机缘：缘法深浅，影响奇遇触发率与商店折扣。机缘厚者，常逢造化。';
  static const String glossaryHp = '生命：可承受的伤害总量，归零即败。由内力、根骨与装备共同撑起。';
  static const String glossaryInternalForce =
      '内力：施展招式的根本，关乎招式威能与血量基底。战斗中随出招消耗，大招耗内力尤甚。';
  static const String glossarySpeed = '出手速度：决定行动快慢，速度越高出手越频。由身法、装备与心法共同加成。';
  static const String glossaryCriticalRate =
      '暴击率：触发暴击的概率，暴击额外加成伤害。身法越高，暴击越易触发。';
  static const String glossaryEvasionRate = '闪避率：完全避开来袭的概率。身法越高，越易闪躲。';
  static const String glossaryCultivation = '修炼度：心法的精熟程度，越高则招式伤害倍率越大。随实战与闭关渐积。';
  static const String glossaryResonance = '共鸣度：人与兵刃的默契，血战中渐积。圆满者可悟人剑合一。';

  // 上下文帮助系统（2026-06-16）：装备 / 心法 / 境界侧术语释义。
  // 说明经 GlossaryTopicLabel / ContextHelpButton（features/help）展示，
  // 复杂机制 codexEntryId 跳「江湖见闻录」长说明。仍为悬停/长按气泡，非教程弹窗（§5.7）。
  static const String glossaryRealm =
      '境界：修为高低的总纲，学徒至武圣共七阶。境界锁定可用装备阶与心法阶，越阶不可强用。';
  static const String glossaryEquipmentTier =
      '品阶：兵器防具的层次，寻常货至神物共七阶。须境界相称方可佩用，得高阶神物亦不可越阶强用。';
  static const String glossaryStrengthening =
      '强化：耗磨剑石提升装备数值，越高越难成。失败不降级，必返心血结晶兜底。';
  static const String glossaryForging = '开锋：为兵器开锋镶嵌增益，凑成流派 build。境界未达不可开高阶锋。';
  static const String glossaryHeartBloodCrystal =
      '心血结晶：强化失败的保底所得，亦是高阶强化的硬通货。多败多攒，终成大器。';
  static const String glossaryLineageHeritage =
      '师承遗物：先辈传下的兵刃，自带传承之力。徒弟境界未及亦不可强用，须待修为相称。';
  static const String glossaryMainTechnique =
      '主修：当前主修心法，定招式与流派根基。换主修须散功，半数内力与修炼度折损，非同小可。';
  static const String glossaryAssistTechnique =
      '辅修：旁修的心法，添额外加成而不动根基。换辅修无散功之痛，可放手尝试。';
  static const String glossarySchool = '流派：刚猛克灵巧、灵巧克阴柔、阴柔克刚猛，循环相克。顺克加伤，逆克减伤。';
  static const String glossarySynergy = '相生：特定心法搭配可生额外威能，相辅相成。配伍得当，事半功倍。';
  static const String glossaryCombatAdvanced =
      '战斗机制：蓄力、破招、内伤、克制环环相扣。看准敌招蓄力时破招，可截下大招、反客为主。';
  static const String glossarySeclusion =
      '闭关：择地静修，将光阴沉淀为修为。地点、时辰、节气皆影响产出；关游戏亦照常累积（在线＝离线）。';
  static const String labelCombatAdvanced = '战斗机制';

  // ── 批次 1.4:头像旁战斗状态标签(buff/debuff)label + hover 释义 ──
  // 纯展示层,读 BattleCharacter 现有状态字段渲染;无独立 HelpTopic,挂薄 GlossaryTip。
  /// 内伤 debuff(InternalInjurySlot):守方出手时持续掉血,可致死。
  static const String statusInternalInjuryLabel = '内伤';
  static const String statusInternalInjuryGloss =
      '内伤:经脉受创,每次自己出手都要再受一记暗伤,层数耗尽方止,拖久了能要命。';

  /// 踉跄 debuff(staggerTicksRemaining):被破招后阵脚大乱,数回合内任人宰割。
  static const String statusStaggerLabel = '踉跄';
  static String get statusStaggerGloss => combatTermGloss(CombatTerm.interrupt);

  /// 剑鸣 buff(swordSongResonanceActive):心剑通灵,暴击附剑鸣威能。
  static const String statusSwordSongLabel = '剑鸣';
  static const String statusSwordSongGloss =
      '剑鸣:人剑通灵之境,暴击之时剑发清吟,威势暗涨。共鸣愈深,剑意愈盛。';

  // ── 第六阶段 破防:技能特性标签 ──
  // 破防技命中存活敌人即开破绽窗口（不要求蓄力），窗口期内敌防御骤降，
  // 宜集中火力以爆发技收割。三流派各有一手破防手：刚猛→破甲掌，灵巧→旋身刺，阴柔→隐影爪。
  // skill_slot_picker 中与 canInterrupt 一致展示为纯文字特性 label，无 GlossaryTip 机制。
  /// 破防技特性 label（skill_slot_picker subtitle · 与 canInterrupt / cangjingPickerCanInterrupt 模式一致）。
  /// 关联常量：[cangjingPickerCanInterrupt]（同为纯文字特性 label，可检索其 def 参考模式）。
  static const String skillTraitDefenseBreak = '破防';

  // HelpCatalog 引用的术语 label（集中 sink，复用既有 attr/stat/tab 常量，仅补缺失）。
  static const String labelCultivation = '修炼度';
  static const String labelResonance = '共鸣度';
  static const String labelEquipmentTier = '品阶';
  static const String labelHeartBloodCrystal = '心血结晶';
  static const String labelSchool = '流派';

  /// 页面级帮助 `?` 未解锁时的气泡（吃 CodexIndex step gating，不剧透机制）。
  static const String contextHelpLocked = '阅历未至，待你历练更深，再来翻阅。';

  /// 内力当前/上限文案：`X / Y`。
  static String internalForceValue(int current, int max) => '$current / $max';

  /// 修炼度进度文案：`X / Y`。
  static String cultivationProgress(int current, int next) =>
      '$current / $next';

  /// 修炼度当前层伤害倍率文案（D · 五要素「当前效果」）：`伤害 ×1.75`。
  static String cultivationDamageMult(double mult) =>
      '伤害 ×${mult.toStringAsFixed(2)}';

  /// 修炼度下一层伤害倍率文案（D · 五要素「下一阶效果」）：`下一阶 ×2.00`。
  static String cultivationNextDamageMult(double mult) =>
      '下一阶 ×${mult.toStringAsFixed(2)}';

  /// 修炼度已至最高层（极境）标记（D · 五要素「下一阶效果」退化）。
  static const String cultivationMaxLayer = '已至极境';

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
  static const String equipmentSlotEmptyStatus = '空槽';
  static const String equipmentNameUnknown = '未名器';
  static const String equipmentSlotRealmUsable = '可用';
  static const String equipmentSlotRealmLocked = '境界不足';
  static const String equipmentSlotBelowRealm = '低于当前境界';
  static const String equipmentSlotRealmMatched = '境界相称';
  static String equipmentBattleCountShort(int count) => '#$count';
  static const String techniqueEmpty = '未学';
  static const String noMainTechnique = '未修主修';
  static const String dashPlaceholder = '—';

  // W18-A1 心法相生(GDD §4.5,CharacterPanel chip 显示)
  static const String synergyActiveLabel = '相生';

  // 仓库 / 强化对话框（T29）
  static const String inventoryTitle = '装备仓库';
  static const String inventoryEmpty = '仓库空空如也';
  static const String inventorySummaryTitle = '仓库总览';
  static String inventorySummaryLine({
    required int total,
    required int shown,
    required int equippable,
    required int equipped,
    required int locked,
    required int realmLocked,
  }) =>
      '显示 $shown / $total 件 · 可装备 $equippable · 已穿戴 $equipped · 锁定 $locked · 境界不足 $realmLocked';
  static String inventoryCurrentCondition(String condition, String sort) =>
      '条件：$condition · $sort';
  static const String inventoryConditionAll = '全部';
  static String inventoryConditionParts(List<String> parts) =>
      parts.isEmpty ? inventoryConditionAll : parts.join(' / ');
  static const String equipmentCardCoreStats = '核心属性';
  static const String equipmentCardRealmGate = '门槛';
  static const String equipmentCardStatusReady = '可装备';
  static const String equipmentCardActionView = '查看';

  /// 装备详情共鸣行:`战斗 N 次`。
  static String equipmentBattleCount(int count) => '战斗 $count 次';

  // 仓库 Tab（W15 #30 P3 后续 A · 物料 Tab）
  static const String inventoryTabEquipment = '装备';
  static const String inventoryTabMaterial = '物料';
  static const String inventoryMaterialEmpty = '暂无物料';

  // 资源总览页（只读经营面板）。
  static const String resourceOverviewTitle = '资源总览';
  static const String resourceOverviewIntro =
      '汇总当前库存与主要去向，只作经营判断，不在此处消费、购买或结算。';
  static const String resourceOverviewEmpty = '暂无相关资源';
  static const String resourceOverviewUsageLabel = '用途：';
  static const String resourceOverviewSourceLabel = '来源：';
  static const String resourceOverviewDirectionLabel = '近期去向：';
  static const String resourceOverviewSourceDetailTitle = '主要来源';
  static const String resourceOverviewNoUsage = '暂无已接入用途';
  static const String resourceOverviewNoSource = '暂无稳定来源';
  static const String resourceOverviewNoDirection = '暂未接入消耗';
  static const String resourceOverviewCategoryCurrency = '银两';
  static const String resourceOverviewCategoryEquipmentMaterial = '炼器材料';
  static const String resourceOverviewCategoryIslandProduct = '桃花岛产物';
  static const String resourceOverviewCategoryPill = '丹药补给';
  static const String resourceOverviewCategoryScroll = '秘籍残卷';
  static String resourceOverviewQuantity(int quantity) => '库存 ×$quantity';
  static String resourceOverviewLoadFailed(Object error) => '资源读取失败：$error';

  static String resourceUsageGroupLabel(ResourceUsageGroup group) {
    return switch (group) {
      ResourceUsageGroup.cultivation => '修炼',
      ResourceUsageGroup.equipment => '炼器',
      ResourceUsageGroup.island => '桃花岛',
      ResourceUsageGroup.recovery => '疗伤',
      ResourceUsageGroup.shopping => '采买',
    };
  }

  static String resourceConsumptionDirectionLabel(
    ResourceConsumptionDirection direction,
  ) {
    return switch (direction) {
      ResourceConsumptionDirection.cultivation => '修为与招式消耗',
      ResourceConsumptionDirection.equipment => '装备强化与开锋消耗',
      ResourceConsumptionDirection.island => '桃花岛建设与加工消耗',
      ResourceConsumptionDirection.recovery => '疗伤整备消耗',
      ResourceConsumptionDirection.shopping => '江湖采买通用消耗',
      ResourceConsumptionDirection.mixed => '多系统共同消耗',
      ResourceConsumptionDirection.none => resourceOverviewNoDirection,
    };
  }

  /// 物料行文案：`磨剑石 × 1234`。
  static String materialQuantity(String name, int qty) => '$name × $qty';

  /// 物料用途摘要。空 = 不显。
  static String materialUsageSummary(List<ItemUsage> usages) {
    final labels = <String>{for (final usage in usages) itemUsageLabel(usage)}
      ..remove('');
    return labels.join(' / ');
  }

  /// 物料主要来源摘要。空 = 不显。
  static String materialSourceSummary(List<ItemSource> sources) {
    final labels = <String>{
      for (final source in sources) itemSourceLabel(source),
    }..remove('');
    if (labels.isEmpty) return '';
    return '$materialSourcePrefix${labels.take(6).join(' / ')}';
  }

  static const String materialSourcePrefix = '主要来源：';

  /// 单项来源标签（集中中文 sink；业务层只返回 enum）。
  static String itemSourceLabel(ItemSource source) {
    return switch (source.kind) {
      ItemSourceKind.mainline => '主线掉落',
      ItemSourceKind.stage => '关卡掉落',
      ItemSourceKind.tower => '爬塔奖励',
      ItemSourceKind.seclusion => '闭关所得',
      ItemSourceKind.shop => '江湖商店',
      ItemSourceKind.equipmentDisassembly => '装备分解',
      ItemSourceKind.enhancementFailure => '强化失败',
      ItemSourceKind.islandSource => '桃花岛采集',
      ItemSourceKind.islandRecipe => '桃花岛加工',
    };
  }

  /// 单项用途标签（集中中文 sink；业务层只返回 enum）。
  static String itemUsageLabel(ItemUsage usage) {
    return switch (usage.kind) {
      ItemUsageKind.realmProgress => '修为突破',
      ItemUsageKind.techniqueUnlock => '解锁招式',
      ItemUsageKind.equipmentEnhancement => '装备强化',
      ItemUsageKind.equipmentForging => '装备开锋',
      ItemUsageKind.equipmentGuarantee => '强化保底',
      ItemUsageKind.injuryRecovery => '疗伤整备',
      ItemUsageKind.shopPurchaseCurrency => '商店采买',
      ItemUsageKind.islandUpgradeCurrency => '桃花岛升级',
      ItemUsageKind.islandBuildingUpgrade => '建筑升级',
      ItemUsageKind.islandRecipeInput => '桃花岛加工',
    };
  }

  // ── P4 材料经济 P2 T4:道具使用(经验丹/秘籍)──────────────────────────────
  static const String itemUseButton = '使用';
  static const String itemUseConfirmTitle = '使用道具';
  static String itemUseConfirmBody(String name) => '确定使用「$name」？';
  static String itemUseExpResult(String name, int layersGained) =>
      layersGained > 0 ? '服下「$name」，境界精进 $layersGained 层。' : '服下「$name」，内息渐长。';
  static String itemUseScrollResult(String name) => '研读「$name」，已了然于胸，得此绝学。';
  static String itemUseRecoveryResult(String name, String targetName) =>
      '给$targetName服下「$name」，伤势渐平。';
  static String itemUseAlreadyKnown(String name) => '「$name」所载之招，早已了然于胸。';
  static String itemUseNoEffect(String name, String targetName) =>
      '$targetName此刻无需服用「$name」。';
  static const String postBattleHealingTitle = '战后疗伤';
  static String postBattleHealingAvailable(int count) => '疗伤丹 ×$count';
  static const String postBattleHealingAction = '服用疗伤丹';
  static String postBattleHealingApplied(String targetName) =>
      '$targetName伤势稍平。';
  static const String postBattleHealingFailed = '暂时无法用药。';
  static const String itemUseFailed = '此物此刻无法使用。';
  static const String itemUseDismiss = '收下';

  // ── 装备出售/分解(2026-06-26)──────────────────────────────────────────────
  static const String equipmentSell = '出售';
  static const String equipmentDisassemble = '分解';
  static const String equipmentLock = '锁定';
  static const String equipmentUnlock = '解锁';
  static const String equipmentActionStrengthen = '强化';
  static const String equipmentActionForge = '开锋';
  static const String equipmentLockedLabel = '已锁定';
  static const String equipmentDropActionLater = '稍后处理';
  static const String equipmentDropActionSource = '查看来源';
  static const String equipmentDropActionFavorite = '标记常用';
  static const String equipmentDropFavoriteLabel = '常用';
  static const String equipmentDropActionDone = '已处理';
  static const String equipmentDropSourceTitle = '装备来源';
  static const String equipmentDropSourceEmpty = '此物来源未明。';
  static const String equipmentDropActionProtected = '已受保护';
  static const String equipmentDropActionEquipped = '已穿戴';
  static const String equipmentDropFavoriteHint = '常用装备将以锁定状态保留，避免整理时误处置。';
  static String equipmentDropRealmGate(String realmName) => '门槛：$realmName及以上';
  static String equipmentDropUsableCharacters(String names) => '可用：$names';
  static const String equipmentDropNoUsableCharacters = '可用：暂无达标角色';
  static String equipmentDropSchoolFit(String schoolName) => '适合：$schoolName流派';
  static const String equipmentDropSchoolFitAny = '适合：通用整备';
  static const String equipmentDropLockAdviceRare = '建议锁定：高阶装备，先留作核心养成。';
  static const String equipmentDropLockAdviceFit = '建议锁定：当前队伍已有合适人选。';
  static const String equipmentDropLockAdviceWait = '建议稍候：境界未达，先留仓观望。';
  static const String equipmentDropLockAdviceCommon = '建议按需锁定：寻常装备可先看属性再整理。';
  static const String equipmentBulkEntry = '整理';
  static const String equippedBadge = '装备中';
  static const String inventoryLineageSealLabel = '师承遗物';
  static const String inventoryLockedSealLabel = '已锁定';
  static const String inventoryProtectedSealLabel = '受保护';
  static const String inventoryProtectedSealText = '护';
  static const String inventoryShopEntry = '进商店';
  static String sellConfirmBody(int count, int silver) =>
      '将出售 $count 件装备，获得银两 $silver。';
  static String disassembleConfirmBody(int count, int mojianshi, int xinxue) =>
      '将分解 $count 件装备，获得磨剑石 $mojianshi${xinxue > 0 ? ' / 心血结晶 $xinxue' : ''}。';
  static String sellSingleConfirmBody(String name, int silver) =>
      '出售「$name」，获得银两 $silver。';
  static String disassembleSingleConfirmBody(
    String name,
    int mojianshi,
    int xinxue,
  ) => '分解「$name」，获得磨剑石 $mojianshi${xinxue > 0 ? ' / 心血结晶 $xinxue' : ''}。';
  static String bulkTierLabel(String tierName, int count) =>
      '$tierName（$count 件）';
  static String bulkProtectedSummary({
    required int locked,
    required int equipped,
    required int heritage,
    required int highTier,
    required int story,
  }) {
    final parts = <String>[
      if (locked > 0) '锁定 $locked 件',
      if (equipped > 0) '装备中 $equipped 件',
      if (heritage > 0) '师承遗物 $heritage 件',
      if (highTier > 0) '高阶 $highTier 件',
      if (story > 0) '典故/传承 $story 件',
    ];
    return parts.isEmpty ? '' : '已排除：${parts.join(' / ')}。';
  }

  /// 批量整理对话框按钮（Task 6）。
  static const String bulkSellButton = '一键出售';
  static const String bulkDisposalEmpty = '暂无可整理装备';

  // T11 仓库筛选标签。
  static const String inventoryFilterAll = '全部';
  static const String inventoryFilterEquippable = '可装备';
  static const String inventoryFilterEquipped = '已穿戴';
  static const String inventoryFilterForgeable = '可开锋';
  static const String inventoryFilterRealmLocked = '境界未达';
  static const String inventoryFilterSlotAll = '部位·全部';
  static const String inventoryFilterTierAll = '品阶·全部';
  static const String inventoryFilterSchoolAll = '流派·全部';
  static const String inventoryFilterSchoolNone = '无流派';
  static const String inventoryFilterOwnershipAll = '状态·全部';
  static String inventoryFilterSlotLabel(String name) => '部位·$name';
  static String inventoryFilterTierLabel(String name) => '品阶·$name';
  static String inventoryFilterSchoolLabel(String name) => '流派·$name';
  static const String inventoryFilterFree = '自由';
  static const String inventoryFilterHeritage = '师承遗物';
  static const String inventoryFilterLocked = '已锁定';
  static const String inventoryFilterProtected = '受保护';
  static const String inventorySortTierDesc = '品阶降序';
  static const String inventorySortTierAsc = '品阶升序';
  static const String inventorySortEnhanceDesc = '强化优先';
  static const String inventorySortObtainedDesc = '新获优先';
  static const String inventorySortObtainedAsc = '旧物优先';
  static String inventorySortLabel(String label) => '排序·$label';

  /// T11:仓库格子境界锁封条显具体原因(需 X 境界),替泛化「未达境界」。
  static String inventoryRealmLockBanner(String realmName) => '需$realmName境界';
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

  /// 锻材余量 / 需求：`锻材 X / Y`。
  static String duancaiUsage(int current, int cost) => '锻材 $current / $cost';

  /// 心血结晶余量：`心血结晶 X`。
  static String crystalAvailable(int qty) => '心血结晶 $qty';

  /// 保底所需结晶：`保底 X 颗`。
  static String guaranteeCost(int cost) => '保底 $cost 颗';

  /// 失败提示：`+1 心血结晶`（GDD §6.3 每次失败必给 1 颗）。
  static String crystalGained(int gained) => '+$gained 心血结晶';

  static const String metricSuccessRate = '成功率';
  static const String metricMaterial = '材料';
  static const String metricForgingMaterial = '锻材';
  static const String metricCrystal = '结晶';

  // 开锋（T30）
  static const String tabEnhance = '强化';
  static const String tabForging = '开锋';
  static const String forgingForged = '已开锋';
  static const String forgingNoSpecialSkill = '此装备尚未记载专属锋意';
  static const String forgingNoSpecialSkillHint = '换一件武器,或先打磨前两道锋意。';
  static const String forgingSpecialSkillPickerTitle = '选择专属技能';
  static String forgingSpecialSkillSummary(
    String styleLabel,
    int? tier,
    int power,
  ) => tier == null
      ? '$styleLabel · 威力 $power'
      : '$styleLabel · 第$tier阶 · 威力 $power';
  static const String forgingConfirmTitle = '确认开锋';
  static const String forgingConfirmBody = '开锋一旦下手不能更改。确认在此槽位开锋？';
  static String forgingConfirmBodyWithCost(int cost) =>
      cost > 0 ? '开锋一旦下手不能更改。本次消耗开锋辅材 $cost。确认下手？' : forgingConfirmBody;
  static const String forgingConfirmOk = '确认';
  static const String forgingConfirmCancel = '取消';
  static String forgingFucaiUsage(int current, int cost) =>
      '开锋辅材 $current / $cost';

  /// 槽位标题：`槽 1` / `槽 2` / `槽 3`。
  static String forgingSlotTitle(int slotIndex) => '槽 $slotIndex';

  /// 未解锁文案：`强化到 +N 解锁`。
  static String forgingUnlockHint(int unlockAtLevel) =>
      '强化到 +$unlockAtLevel 解锁';

  /// 已开锋词条：`攻击 +15%`。
  static String forgingBonusLabel(String typeLabel, int bonus) =>
      '$typeLabel +$bonus%';

  static String forgingSpecialSkillLabel(String skillName) => '专属技能：$skillName';
  static const String forgingSpecialSkillDetailTitle = '器物绝招';
  static const String forgingSpecialSkillDetailSubtitle = '第三锋意已定，战斗中随装备带入。';
  static const String forgingSpecialSkillTriggerManual = '触发：手动下发';
  static const String forgingSpecialSkillTriggerInterrupt = '触发：敌方蓄力时优先破招';
  static const String forgingSpecialSkillTriggerAuto = '触发：内力足、冷却就绪时自动出手';
  static const String forgingSpecialSkillTriggerReady = '触发：自动战斗可用';
  static String forgingSpecialSkillSchool(String label) => '流派：$label';
  static String forgingSpecialSkillTarget(String label) => '目标：$label';
  static String forgingSpecialSkillCostCooldown(int cost, int cooldown) =>
      '内力 $cost · 冷却 $cooldown 回合';
  static String forgingSpecialSkillFitCharacters(String school, String names) =>
      '适合：$school 路数 · $names';
  static String forgingSpecialSkillFitSchool(String school) =>
      '适合：$school 路数角色';
  static const String forgingSpecialSkillFitFlexible = '适合：按招式定位搭配';
  static const String forgingSpecialSkillUnknown = '未载入招式配置';

  // 心法面板 / 散功 dialog（T31）
  static const String techniquePanelTitle = '心法面板';
  static const String techniquePanelEmpty = '尚未学习任何心法';
  static const String techniquePanelMainHeroLabel = '主修心法';
  static const String techniqueMeridianOverviewTitle = '经脉总览';
  static String techniqueMeridianMain(String value) => '主脉：$value';
  static String techniqueMeridianAssist(int count, int total) =>
      '辅脉：$count/$total';
  static String techniqueMeridianInsight(int points) => '领悟：$points 点';
  static String techniqueMeridianHighest(String layer, int count) =>
      '火候：$layer · 共$count门';
  static const String techniqueEquipSuggestionTitle = '装配建议';
  static const String techniqueEquipSuggestionEmpty = '暂无可评估角色';
  static const String techniqueEquipSuggestionAlreadyMain = '已主修';
  static const String techniqueEquipSuggestionAlreadyAssist = '已辅修';
  static const String techniqueEquipSuggestionReadyMain = '可修为主修';
  static const String techniqueEquipSuggestionReadyAssist = '可修为辅修';
  static const String techniqueEquipSuggestionRealmLocked = '境界不足';
  static const String techniqueEquipSuggestionAssistFull = '辅修已满';
  static const String techniqueEquipSuggestionInsightLocked = '领悟点不足';
  static const String techniqueEquipReasonSameSchool = '同流派';
  static const String techniqueEquipReasonFillsMain = '补主修';
  static const String techniqueEquipReasonFillsAssist = '补辅修';
  static const String techniqueEquipReasonTierFits = '阶位贴合';
  static const String techniqueEquipReasonHighEnlightenment = '悟性高';
  static const String techniqueEquipReasonAlreadyPracticed = '已习练';
  static const String techniqueEquipNoReason = '泛用';
  static String techniqueEquipBlockRealm(String current, String required) =>
      '当前上限$current,需$required';
  static String techniqueEquipBlockInsight(int current, int required) =>
      '领悟$current/$required';
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
  static String mainMenuMainlineGoalHint(
    String target,
    String reward,
    String reason,
  ) => '目标：打$target · 取$reward · $reason';
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
  static const String stageListTimelineTitle = '章节卷轴';
  static const String stageListTimelineHint = '沿路标推进，朱印为章末首领';
  static const String stageListBoss = 'Boss';
  static String stageListJourneyNodeLabel(int stageIndex) => '第$stageIndex关';
  static String stageListTimelineStopLabel(int stageIndex, String stageName) =>
      '第$stageIndex关 · $stageName';
  static const String chapterFarmSpotsTitle = '通章刷点';
  static const String chapterFarmSpotsHint = '本章已通，可回头刷这些关卡';
  static String chapterFarmSpotStage(int stageIndex) => '第$stageIndex关';
  static const String stageReplayRouteTitle = '重打路线';
  static const String stageReplayRouteEquipment = '刷装备';
  static const String stageReplayRouteMaterial = '刷材料';
  static const String stageReplayRouteProficiency = '练熟练度';
  static const String stageGoalGuidanceTitle = '当前目标';
  static String stageGoalTarget(
    int chapterIndex,
    int stageIndex,
    String name,
  ) => '第$chapterIndex章第$stageIndex关「$name」';
  static String stageGoalGuidanceLine(
    String target,
    String reward,
    String reason,
  ) => '打$target · 取$reward · $reason';
  static const String stageGoalRewardSkillManual = '武学真解';
  static const String stageGoalRewardProgress = '过关线索';
  static const String stageGoalReasonBoss = '章末关会打开下一段江湖路。';
  static const String stageGoalReasonSkill = '首通可学新招，后续战斗多一个解法。';
  static const String stageGoalReasonEquipment = '补上早期装备，推关更稳。';
  static const String stageGoalReasonMaterial = '攒下养成材料，强化与整备都用得上。';
  static const String stageGoalReasonProgress = '先把主线往前推，系统会自然展开。';

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
  static String towerProgressBarLabel(int cleared, int total) =>
      '已通 $cleared / $total 层';
  static String towerCurrentChallengeFloor(int floor) => '当前可挑战：第 $floor 层';
  static const String towerCurrentChallengeComplete = '当前可挑战：已登顶';
  static String towerHighestClearedFloor(int floor) => '最高进度：第 $floor 层';
  static const String towerHighestClearedNone = '最高进度：未破首层';
  static String towerNextMilestoneTarget(int floor, String name) =>
      '下一节点：第 $floor 层 · $name';
  static const String towerNextMilestoneComplete = '下一节点：三十层已尽';
  static const String towerMilestoneSummitBoss = '登顶大 Boss';
  static const String towerSpineLegend = 'Boss 作节点，亮印为当前可挑战层，厚边为最高已通层';

  static String towerFloorLabel(int floorIndex) => '第 $floorIndex 层';
  static String towerFloorEnemies(int count) => '$count 名敌人';
  static String towerRequiredRealm(String realmName) => '推荐 $realmName';

  static const String towerDropSource = '爬塔奖励';
  // 装备掉落默认来历标签(DropService.defaultObtainedFrom · 显于兵器谱/装备详情「个人历程·来历」)。
  static const String dropSourceStageDefault = '关卡掉落';
  static const String dropSourceRareBonus = '稀有彩头'; // 第八阶段 E
  static const String previewRareBonusHint = '稀有彩头：偶可遇高阶利器'; // E·预览浮层提示
  // F1 里程碑装备来历(MilestoneEquipmentGrantService 授予 obtainedFrom)。
  static const String dropSourceMassBattleMerit = '群战军功';
  static const String dropSourceInnerDemonReward = '降服心魔';
  static const String dropSourceAscensionReward = '飞升所得';
  // B2 闭关掉落来历（DropService.defaultObtainedFrom）。
  static const String dropSourceSeclusion = '闭关所得';
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
  static const String stageVictoryReportTitle = '战后卷宗';
  static const String stageVictoryExperienceSection = '经验 / 修为';
  static const String stageVictoryEquipmentSection = '装备';
  static const String stageVictoryManualSection = '秘籍 / 残页';
  static const String stageVictoryBattleSection = '战况';
  static const String stageVictoryInjurySection = '伤势 / 疗伤';

  // === 主线三 · 掉落传闻 UI ===
  static const String lootBucketChangKeDe = '常可得';
  static const String lootBucketOuKeDe = '偶可得';
  static const String lootBucketShaoYouRenDe = '少有人得';
  static const String lootBucketJiangHuChuanWen = '江湖传闻';
  static const String lootBucketShouTongBiDe = '首通必得';
  static const String lootSummaryPrefix = '可能收获：';
  static const String lootRumorDialogTitle = '本关传闻';
  static const String lootNoFixedDrop = '本关无固定收获';
  static const String lootAboveRealmHint = '机缘可遇，火候未到';
  static const String lootTowerFirstClearOnlyFooter = '塔层传闻仅首通可得，错过不补';
  // F2(续48)·主线秘籍逐条首通门控脚注（装备/材料每次可掉，仅秘籍首通必得）。
  static const String lootMainlineScrollFirstClearFooter = '秘籍首通必得，重打不补';
  // 第八阶段 B/C·悬停预览浮层:推荐境界 + 难度判语(对齐 §5.5 境界差档)。
  static const String previewRecommendedRealmLabel = '推荐境界';
  static const String previewHoverHint = '悬停查看';
  static const String difficultyComfortable = '碾压';
  static const String difficultySuitable = '适中';
  static const String difficultyRisky = '偏高';
  static const String difficultyDeadly = '送死';
  static const String prebattleIntelTitle = '战前情报';
  static const String prebattleIntelEnemySection = '敌阵';
  static const String prebattleIntelCycleTraitSection = '周目词条';
  static const String prebattleIntelAllyConditionSection = '我方伤势';
  static const String prebattleIntelResponseSection = '应对';
  static const String prebattleIntelRiskSection = '风险';
  static const String prebattleIntelLootSection = '可能收获';
  static const String prebattleIntelNoEnemy = '未见敌踪';
  static const String prebattleIntelBossTag = '首领';
  static String get prebattleIntelChargeTag =>
      combatTermLabel(CombatTerm.charge);
  static String prebattleIntelDialogTitle(String stageName) =>
      '$prebattleIntelTitle · $stageName';
  static String prebattleEnemyLine(
    String name,
    String realm,
    String school,
    String tags,
  ) => tags.isEmpty
      ? '$name · $realm · $school'
      : '$name · $realm · $school · $tags';
  static String prebattlePrepCounterSchool(String school) =>
      '敌阵偏$school，可备克制路数。';
  static const String prebattlePrepBoss = '首领关宜留足内力，先处理随从再攻坚。';
  static const String prebattlePrepGroup = '敌众时备一门群体招，先清场再压主目标。';
  static String get prebattlePrepCharge =>
      '敌方有${combatTermLabel(CombatTerm.charge)}招，保留${combatTermLabel(CombatTerm.interrupt)}或爆发内力。';
  static const String prebattleRiskBoss = '首领战败会触发额外折损，勿空内力硬拼。';
  static String get prebattleRiskCharge =>
      '${combatTermLabel(CombatTerm.charge)}招若未打断，可能瞬间扭转战局。';
  static const String prebattleRiskOutnumbered = '敌方人数较多，拖久容易被围攻。';
  static const String prebattleRiskNone = '未见明显险兆，按常规节奏推进。';
  static const String stagePrepareLabel = '整备';
  static String stagePrepareRecommended(String realmName) => '推荐 $realmName';
  static const String stagePrepareReady = '火候已到 · 可挑战';
  static const String stagePrepareSteady = '高出推荐 · 可稳刷';
  static String stagePrepareLoadoutGap(int gap) => '低$gap阶 · 装备/心法补强';
  static String stagePrepareRealmGap(int gap) => '低$gap阶 · 闭关突破';
  static const String stagePrepareAssignCharacter = '未派出角色 · 角色面板';

  static String cycleTraitSummary(int cycle, List<String> names) =>
      '第$cycle周目词条：${names.join(' / ')}';
  static String cycleTraitName(String id) => switch (id) {
    'yuti' => combatTermLabel(CombatTerm.yuti),
    'zhenqi' => combatTermLabel(CombatTerm.zhenqi),
    'fanzhen' => '反震',
    'shipo' => '识破',
    'ningjia' => '凝甲',
    _ => '未知词条',
  };
  static String cycleTraitShortYuti(String pct) => '防御 +$pct';
  static String cycleTraitShortZhenqi(String pct) => '内力 +$pct';
  static const String cycleTraitShortFanzhen = '受击反震';
  static const String cycleTraitShortShipo = '补蓄力反制';
  static const String cycleTraitShortNingjia = '暴击减伤';
  static String cycleTraitShortUnknown(String id) => '未识别：$id';
  static String cycleTraitDetailYuti(String pct) =>
      combatTermGloss(CombatTerm.yuti, pct: pct);
  static String cycleTraitDetailZhenqi(String pct) =>
      combatTermGloss(CombatTerm.zhenqi, pct: pct);
  static String cycleTraitDetailFanzhen(int ticks, int damagePerTick) =>
      '反震：命中带词条的敌人后，攻击者会承受 $ticks 回合内伤，每回合 $damagePerTick。';
  static String get cycleTraitDetailShipo =>
      '识破：无${combatTermLabel(CombatTerm.charge)}技的敌人会补一式${combatTermLabel(CombatTerm.charge)}反制，需保留${combatTermLabel(CombatTerm.interrupt)}或爆发内力。';
  static String cycleTraitDetailNingjia(String reductionPct) =>
      '凝甲：敌方受到暴击时，暴击增量降低 $reductionPct，别只押会心一线。';
  static String cycleTraitDetailUnknown(String id) => '未识别的周目词条：$id。';

  // === 第七阶段批二 ② · 弱点/抗性「事后可查」战前提示（通关后才显，§5.7）===
  // X = 流派显示名（EnumL10n.school）。水墨口吻，不写「弱点/抗性」直白词。
  static String weaknessHintWeak(String school) => '似惧「$school」路数';
  static String weaknessHintResist(String school) => '「$school」路难伤';
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
  // D · 共鸣度五要素：下一阶加成 / 阶内战斗进度
  // （原 equipmentDetailResonanceNextHint「距 N 战」由下一阶加成 + 战斗进度取代）
  static String equipmentResonanceNextBonus(int pct) => '下一阶 +$pct%';
  static String equipmentResonanceBattleProgress(int count, int nextMin) =>
      '战斗 $count/$nextMin';
  static const String equipmentDetailBasicSection = '基础信息';
  static const String equipmentDetailGrowthSection = '属性与养成';
  static const String equipmentDetailActionSection = '操作';
  static const String equipmentSourceSectionDivider = '◇ 来源 ◇';
  static const String equipmentSourceEmpty = '来源未明';
  static const String equipmentLoreSectionDivider = '◇ 典故 ◇';
  static String equipmentSourceMainline(
    int chapterIndex,
    String stageName,
    bool isBoss,
  ) => isBoss
      ? '主线·第$chapterIndex章 Boss「$stageName」'
      : '主线·第$chapterIndex章「$stageName」';
  static String equipmentSourceStage(String stageName, bool isBoss) =>
      isBoss ? '支线·Boss「$stageName」' : '支线·「$stageName」';
  static String equipmentSourceTower(int floorIndex, bool isBoss) =>
      isBoss ? '爬塔·第$floorIndex层 Boss' : '爬塔·第$floorIndex层';
  static String equipmentSourceSeclusion(String mapName) => '闭关·$mapName';
  static const String equipmentSourceShop = '江湖商店';
  static const String equipmentSourceUnknown = '来源未明';
  static String equipmentSourceTag(String tag) => switch (tag) {
    'yiLiu_quest' => '一流支线',
    'jueDing_unlock' => '绝顶解锁',
    'zongShi_unlock' => '宗师解锁',
    'wuSheng_unlock' => '武圣解锁',
    'ascension_reward' => '飞升传承',
    'inner_demon_reward' => '心魔试炼',
    'mass_battle_merit' => '群战功勋',
    _ => equipmentSourceUnknown,
  };
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
  static String mainMenuSeclusionCappedStatus(String mapName) =>
      '收益已满 · $mapName';

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
  static const String seclusionMapRealmGateLabel = '境界门槛';
  static const String seclusionMapExpectedOutputLabel = '预期产出';
  static const String seclusionMapStatusLabel = '当前状态';
  static const String seclusionMapReadyHint = '可进入闭关';
  static const String seclusionMapLockedHint = '未达门槛';
  // 地图卡产出加成摘要 / 进行中提示(_mapBonusSummary + _activeHint)。
  static const String seclusionBonusEquipDrop = '兵器掉率 +50%';
  static const String seclusionBonusTechniqueLearn = '心法领悟 +50%';
  static const String seclusionBonusInternalForce = '内力增长 +50%';
  static const String seclusionBonusBalanced = '综合产出';
  static const String seclusionMapActiveDoneHint = '已完成，可收功';
  static String seclusionMapActiveRemainingHint(int remainingMinutes) =>
      '剩余 ${remainingMinutes ~/ 60}h${remainingMinutes % 60}min，可查看';
  static String seclusionMapActiveBannerRemaining(String remaining) =>
      '$seclusionMapActive · 剩余 $remaining';
  static String seclusionMapActiveBannerDone() => '$activeRetreatDone · 可收功';

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
  static const String activeRetreatStatusCardTitle = '闭关状态';
  static String activeRetreatStatusLocation(String mapName) => '地点：$mapName';
  static String activeRetreatElapsed(String elapsed) => '已闭关：$elapsed';
  static String activeRetreatPlannedHours(int hours) => '计划：$hours 小时';
  static const String activeRetreatExpectedTypes = '预计收获';
  static const String activeRetreatRewardMojianshi = '磨剑石';
  static const String activeRetreatRewardExperience = '修为经验';
  static const String activeRetreatRewardSilver = '银两';
  static const String activeRetreatRewardTechnique = '心法领悟';
  static const String activeRetreatRewardInternalForce = '内力沉淀';
  static const String activeRetreatRewardEquipment = '装备机缘';
  static String activeRetreatRewardTypes(String labels) => labels;
  static String activeRetreatProgressPct(int pct) => '$pct%';
  static const String activeRetreatConfirmTitle = '确认提前收功';
  static const String activeRetreatConfirmBody = '现在收功将按实际时间结算，是否确认？';
  static const String activeRetreatConfirm = '确认';
  static const String activeRetreatCancel = '取消';

  static const String seclusionResultTitle = '闭关收获';
  static const String seclusionResultReportTitle = '收功战报';
  static const String seclusionResultRouteTitle = '行迹记录';
  static const String seclusionResultEmpty = '此次收获甚微';
  static const String seclusionResultBack = '返回';

  static String seclusionRequiredRealm(String realmName) => '需要境界：$realmName';
  static String seclusionRequiredRealmWithCurrent(
    String requiredRealm,
    String currentRealm,
  ) => '需要境界：$requiredRealm（当前 $currentRealm）';
  static String seclusionDurationLabel(int hours) => '$hours 小时';
  static String hoursAmountLabel(String value) => '$value 小时';
  static String seclusionMojianshi(int n) => '磨剑石 × $n';
  static String seclusionSilver(int n) => '银两 × $n';
  static String seclusionItemReward(String name, int n) => '$name × $n';
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
  static String seclusionMapEventHour(double h) =>
      '第 ${h.toStringAsFixed(0)} 时';
  static const String seclusionMapEventHarvest = '偶得';
  static const String seclusionMapEventRisk = '险兆';
  static const String seclusionMapEventTrace = '见闻';

  // ── P1 #42 Phase 4 · BaikeScreen 江湖见闻录(GDD §10.2 第 3 方式)──

  static const String mainMenuBaike = '江湖见闻录';
  static const String mainMenuBaikeHint = '记事与典故,永久可查';

  // ── 藏卷阁 Hub ──
  static const String mainMenuZangjuange = '藏卷阁';
  static const String mainMenuZangjuangeHint = '合看战绩、兵器、奇遇与武学缺口';
  static const String zangjuangeTitle = '藏卷阁';
  static const String zangjuangeCluesTitle = '卷中线索';
  static const String zangjuangeCluesEmpty = '卷册暂未显出新的缺口';
  static const String zangjuangeArchiveTitle = '四部卷册';
  static const String zangjuangeClueEquipmentTitle = '兵器谱缺口';
  static String zangjuangeClueEquipmentSummary(int count) =>
      '尚有 $count 件器物未入谱，可循章节与掉落传闻回查。';
  static const String zangjuangeClueFragmentTitle = '武学残页缺口';
  static String zangjuangeClueFragmentSummary(int count) =>
      '尚有 $count 处残页线索未合拢，可回看塔层、首领与奇遇来源。';
  static const String zangjuangeClueBossCycleTitle = '周目异势未破';
  static String zangjuangeClueBossCycleSummary(int count) =>
      '尚有 $count 处首领异势未破，可从战绩册回看形态与出战记录。';

  // 设置面板
  static const String mainMenuSettings = '设置';
  static const String mainMenuSettingsHint = '音量 · 显示 · 舒适性';
  static const String settingsTitle = '设置';
  static const String settingsAudioSection = '音频';
  static const String settingsComfortSection = '战斗舒适性';
  static const String settingsDisplaySection = '窗口与显示';
  static const String settingsSaveSection = '存档与系统';
  static const String settingsMasterVolume = '总音量';
  static const String settingsBgmVolume = '背景音乐';
  static const String settingsSfxVolume = '音效';
  static const String settingsMuted = '静音';
  static const String settingsClose = '关闭';
  // 退出游戏(桌面标配 · 主菜单右上角 + 设置面板双入口 · 带二次确认)。
  static const String settingsQuit = '退出游戏';
  static const String mainMenuQuitTooltip = '退出游戏';
  static const String quitConfirmTitle = '退出游戏';
  static const String quitConfirmMessage = '确定退出挂机武侠?进度已自动保存,关掉之后仍照常挂机,回来照常结算。';
  static const String quitConfirmAction = '退出';
  static const String quitCancelAction = '再想想';
  // 顶栏「回主菜单」:一键从深层子屏返回主菜单(popUntil isFirst,MainMenu 为栈底首路由)。
  static const String titleBarHome = '回主菜单';
  // 设置「关于」:版本号(L2 · 与 pubspec.yaml version 手动同步)。
  static const String settingsAbout = '关于';
  static const String appVersion = '0.1.0';
  static String settingsVersionValue(String v) => '挂机武侠 · v$v';
  // 战斗交互重做 Phase 3:全局战斗模式默认开关(自动连续播放 / 允许拖招干预)。
  static const String settingsAutoPlayDefault = '自动战斗';
  static const String settingsAutoPlayDefaultHint = '战斗自动连续播放(可逐关切「允许拖招」干预)';
  static const String settingsBattleSpeed = '战斗速度';
  static const String settingsBattleSpeedHint = '只调整播放节拍,不影响胜负和收益';
  static const String settingsBattleSpeedRelaxed = '舒缓';
  static const String settingsBattleSpeedNormal = '标准';
  static const String settingsBattleSpeedBrisk = '利落';
  static const String settingsBattleSpeedRapid = '快速';
  static const String settingsTextDensity = '文字密度';
  static const String settingsTextDensityHint = '影响支持该偏好的信息面板排布';
  static const String settingsTextDensityComfortable = '舒展';
  static const String settingsTextDensityStandard = '标准';
  static const String settingsTextDensityCompact = '紧凑';
  static const String settingsReduceFlashing = '减少闪烁';
  static const String settingsReduceFlashingHint = '降低战斗中的闪白与受击闪效果';
  // L1 显示设置（2026-06-15）:全屏 + 窗口分辨率预设。
  static const String settingsFullscreen = '全屏';
  static const String settingsFullscreenHint = '快捷键 F11 / Alt+Enter';
  static const String settingsResolution = '窗口分辨率';
  static const String settingsResolutionHd720 = '1280 × 720';
  static const String settingsResolutionHd900 = '1600 × 900';
  static const String settingsResolutionHd1080 = '1920 × 1080';
  // 设置「存档管理」:当前档状态 + 本地备份快照。
  static const String saveManagementTitle = '存档管理';
  static const String saveManagementLoading = '正在读取存档状态';
  static const String saveManagementCreatedAt = '开档';
  static const String saveManagementLastSavedAt = '保存';
  static const String saveManagementLastOnlineAt = '离线';
  static const String saveManagementLatestBackup = '最近备份';
  static const String saveManagementCreateBackup = '备份当前存档';
  static const String saveManagementRestore = '恢复备份';
  static const String saveManagementDeleteLatest = '删除最近备份';
  static const String saveManagementRestoreTodo =
      '恢复需要关闭当前数据库并重载全局状态，本版先提供安全备份/导出能力。';
  static const String saveManagementDeleteConfirmTitle = '删除备份';
  static const String saveManagementDeleteConfirmAction = '删除备份';
  static String saveManagementSummary(
    int slotId,
    String saveVersion,
    int backupCount,
  ) => 'slot $slotId · v$saveVersion · $backupCount 个备份';
  static String saveManagementDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  static String saveManagementBackupCreated(String fileName) => '已备份：$fileName';
  static String saveManagementBackupDeleted(String fileName) =>
      '已删除备份：$fileName';
  static String saveManagementDeleteConfirmMessage(String fileName) =>
      '只删除备份文件，不影响当前存档：$fileName';

  // ── 多存档槽(spec B 选择/新开/删除/切换)────────────────────────────
  static const String slotSelectTitle = '选择江湖';
  static const String slotSaveEmpty = '空 · 新开江湖';
  static const String slotNewGameTitle = '新开江湖';
  static const String slotNewGameConfirm = '在此卷开启一段全新的江湖路？';
  static const String slotDelete = '删除存档';
  static const String slotDeleteConfirm = '删除此存档？此举不可挽回。';
  static const String slotDeleteProtectionHint = '输入下方存档名后才可删除';
  static const String slotDeleteInputLabel = '存档名';
  static String slotDeleteConfirmFor(String name) => '删除「$name」？此举不可挽回。';
  static String slotDeleteProtectionValue(String name) => '请输入：$name';
  static const String slotRename = '重命名';
  static const String slotRenameTitle = '命名此卷';
  static const String slotRenameInputLabel = '存档名称';
  static const String slotRenameClearHint = '留空则使用默认卷名';
  static const String slotRenameSave = '保存';
  static const String slotRecentBadge = '最近游玩';
  static const String slotFounderLabel = '祖师';
  static const String slotMainlineLabel = '主线';
  static const String slotTowerLabel = '问鼎';
  static const String slotLastPlayedNever = '尚未记录';
  static const String slotSwitch = '切换存档';
  static const String slotSwitchConfirm = '返回存档选择，切换到其它江湖？';
  static const String slotCancel = '取消';
  static const String slotEnter = '入此江湖';
  static String slotChapterProgress(int chapter, int cleared) =>
      '第 $chapter 章 · 已通关 $cleared 关';
  static String slotTowerProgress(int floor) =>
      floor <= 0 ? '未登塔' : '最高第 $floor 层';
  static String slotFounderSummary(String founder, String realm) =>
      '$founder · $realm';
  static String slotLastPlayed(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  static String slotCardTitle(int n) => '第 $n 卷';

  // 祖师开局塑形
  static const String founderCreateTitle = '开派祖师';
  static const String founderCreateSubtitle = '择流派、定出身、观命盘';
  static const String founderCreateSchoolSection = '一 · 定流派';
  static const String founderCreateOriginSection = '二 · 问出身';
  static const String founderCreateFateSection = '三 · 观命盘';
  static const String founderCreatePreviewSection = '资质预览';
  static const String founderCreateConfirm = '立派入世';
  static const String founderCreateBack = '返回存档';
  static const String founderCreateNoConfig = '祖师创建配置未加载';
  static const String founderCreateSelected = '已选';
  static const String founderCreateStartingTechnique = '起手心法';
  static const String founderCreateStartingResource = '起手资源';
  static const String founderCreateGoalHint = '开局建议';
  static const String founderCreateFateFocus = '命盘侧重';
  static String founderCreateAttributeTotal(int total) => '总点 $total';
  static String founderCreateTechniqueName(String name) => '主修「$name」';
  static String founderCreateConfirmLine(
    String school,
    String origin,
    String fate,
  ) => '$school · $origin · $fate';
  static const String founderCreateAttrConstitutionHint = '影响最大生命,久战不溃';
  static const String founderCreateAttrEnlightenmentHint = '影响修炼速度与武学领悟';
  static const String founderCreateAttrAgilityHint = '影响速度、暴击与闪避';
  static const String founderCreateAttrFortuneHint = '影响奇遇与偶得机缘';
  static String founderCreationDeeds(
    String generationText,
    String school,
    String origin,
    String fate,
    String originLine,
  ) => '$generationText · $school · $origin · $fate\n$originLine';
  // 战斗交互重做 Phase 3:选关屏 per-stage「挂机自动 / 允许拖招」开关。
  static const String stageAutoPlayAuto = '自动';
  static const String stageAutoPlayManual = '拖招';
  // 印章 glyph 单字(绛红方印 ·「自」=纯挂机自动 /「拖」=允许拖招;暂用现有字体,真小篆待补字体)。
  static const String stageAutoPlaySealAuto = '自';
  static const String stageAutoPlaySealManual = '拖';
  static const String stageAutoPlayFollowSuffix = '随设置';
  static const String stageAutoPlayMenuFollow = '跟随设置';
  static const String stageAutoPlayMenuAuto = '挂机自动';
  static const String stageAutoPlayMenuManual = '允许拖招';
  // 爬塔重打 dialog 内的开关标签(塔身布局固定高,toggle 走 dialog)。
  static const String stageAutoPlayPickLabel = '战斗方式';

  // ─── 周目选择控件（P1 周目进化 E1）───────────────────────────────────────────
  // 「江湖记招」：敌人已识得玩家路数，高周目进入手动模式的战前提示（E2 wire）。
  static const String jianghuRememberHint = '此敌已识得你的路数，见招拆招。';

  /// 战前周目横幅(cycle≥2):明确标注第几周目 + 敌人识路 flavor + 强化说明,
  /// 让玩家一眼知道在打第几周目、以及本周目敌人更强。
  static String battleCycleHint(int cycle) =>
      '第 $cycle 周目 · 敌人更强（属性提升·额外反制词条）· $jianghuRememberHint';

  /// 第 N 周目标签，如「第1周目」。
  static String cycleNthLabel(int n) => '第$n周目';

  /// 已通关周目重演后缀（自动战斗）：「(自动)」。
  static const String cycleReplayCurrentSuffix = '(自动)';

  /// 挑战下一周目后缀（手动战斗）：「(手动)」。
  static const String cycleChallengeNextSuffix = '(手动)';

  /// 挑战第 N 周目完整标签，如「挑战第2周目」。
  static String cycleChallengeNextLabel(int n) => '挑战第$n周目';

  /// 已达最高周目提示。
  static const String cycleMaxReachedLabel = '已达最高周目';

  // ─── 爬塔轮回（P1 周目进化 E2）───────────────────────────────────────────────
  /// 爬塔当前轮回标签，如「当前：第1轮回」。
  static String towerCurrentCycleLabel(int cycle) => '当前：第$cycle轮回';

  /// 「挑战下一轮回」按钮文案。
  static const String towerAdvanceCycleButton = '挑战下一轮回';

  /// 爬塔周目推进提示（全 30 层已通，可进入下一轮回）。
  static const String towerCycleReadyHint = '已通 30 层，可挑战下一轮回';

  static const String baikeScreenTitle = '江湖见闻录';
  static const String baikeEmptyTitle = '卷册暂空';
  static const String baikeTabFeed = '见闻';
  static const String baikeTabLore = '典故';
  static const String baikeTabCodex = '机制';
  static const String baikeTabEncounter = '奇缘';
  // 奇遇录(江湖见闻录第4tab)
  static String encounterCodexProgress(int got, int total) => '已际遇 $got/$total';
  static String encounterCodexGroupProgress(int got, int total) =>
      '$got/$total 已际遇';
  static const String encounterCodexGroupInsight = '武学领悟';
  static const String encounterCodexGroupFortune = '奇缘际遇';
  static const String encounterCodexGroupFestival = '节庆';
  static const String encounterCodexEmpty = '江湖路远，奇缘未至';
  // 奇遇文案缺失时占位 EncounterContent 的默认选项文案(EncounterContent.placeholder)。
  static const String encounterPlaceholderChoice = '继续';
  static const String encounterCodexLocked = '？？？';
  static const String encounterCodexNotMet = '尚未际遇';
  static const String encounterCodexDetailTitle = '奇缘录';
  static const String encounterCodexNoteLabel = '江湖札记';
  static const String encounterCodexTriggeredStatus = '已收入札记';
  static const String encounterCodexLockedStatus = '未际遇';
  // ── 藏经阁2.0 武学收录图鉴(P4 子项6) ──
  static const String baikeTabSkills = '武学';
  static String skillCodexProgress(int got, int total) => '已习 $got/$total';
  static String skillCodexGroupProgress(int got, int total) => '$got/$total 已习';
  static const String skillCodexGroupHeartArt = '心法绝学';
  static const String skillCodexGroupTrueSolution = '真解';
  static const String skillCodexGroupFragment = '残页';
  static const String skillCodexGroupInterrupt = '破招';
  static const String skillCodexGroupEncounter = '奇遇武学';
  static const String skillCodexEmpty = '武学无涯，尚需修习';
  static const String skillCodexLocked = '？？？';
  static const String skillCodexNotMet = '尚未习得';
  static const String skillCodexDetailTitle = '武学';
  static const String skillCodexSource = '来源';
  static const String skillCodexProficiencyPrefix = '造诣';
  static const String skillCodexProficiencyNone = '未曾习练';
  static const String skillCodexBelongTo = '所属';
  static const String skillCodexMultiplier = '倍率';
  static const String skillCodexCost = '内力';
  static const String skillCodexCooldown = '冷却';
  static const String skillCodexManualSection = '秘本纲要';
  static const String skillCodexSchool = '流派';
  static const String skillCodexSchoolInherited = '承所属心法';
  static const String skillCodexSchoolUnknown = '未记流派';
  static const String skillCodexInterrupt = '破招';
  static const String skillCodexProficiencyBenefit = '熟练收益';
  static const String skillCodexTypicalUse = '典型用途';
  static const String skillCodexInterruptCanBreak = '可打断蓄力';
  static const String skillCodexInterruptCanBreakAndOpenWindow =
      '可打断蓄力 · 命中开破绽';
  static const String skillCodexInterruptOpenWindow = '命中开破绽';
  static const String skillCodexInterruptNone = '不可破招';
  static String skillCodexSchoolValue(String school, bool inherited) =>
      inherited ? '$school · $skillCodexSchoolInherited' : school;
  static String skillCodexProficiencyBenefitValue(
    String current,
    String? next,
  ) => next == null ? current : '$current\n$next';
  static const String skillCodexUseInterrupt = '留作敌方蓄力时截断关键招';
  static const String skillCodexUseAoeUltimate = '群敌压阵时打出整场爆发';
  static const String skillCodexUseSingleUltimate = '锁定首领或残血强敌收束战局';
  static const String skillCodexUseAoePower = '清理多名敌人并压低全场血线';
  static const String skillCodexUsePower = '常规爆发,用于压低关键目标';
  static const String skillCodexUseJoint = '共鸣成形后用于高价值收尾';
  static const String skillCodexUseNormal = '稳定出手,积累熟练与基础伤害';
  static const String skillCodexSectionSkills = '招式';
  static const String skillCodexSectionTechniques = '心法';
  static const String techniqueCodexEmpty = '心法未录，待入藏经。';
  static const String techniqueCodexFilterAll = '全部';
  static String techniqueCodexProgress(int total) => '已录 $total 门';
  static String techniqueCodexRowMeta(String school, String realm) =>
      '$school · $realm 可修';
  static const String techniqueCodexDetailTitle = '心法';
  static const String techniqueCodexTier = '品阶';
  static const String techniqueCodexSchool = '流派';
  static const String techniqueCodexRealmRequirement = '限制';
  static String techniqueCodexRealmRequirementValue(String realm) =>
      '$realm 及以上可修';
  static const String techniqueCodexSource = '来源';
  static const String techniqueCodexSkills = '招式';
  static const String codexUnknownOrPending = '未记录/待补';
  static const String codexValueSeparator = '、';
  static String techniqueCodexSourceTag(String tag) {
    return switch (tag) {
      'starter' => '开局传授',
      'mainline_ch1' => '主线第一章',
      'mainline_ch3' => '主线第三章',
      'tower_15' => '爬塔十五层',
      'tower_25' => '爬塔二十五层',
      'wuxue_lingwu' => '武学领悟',
      'wuxue_lingwu_top' => '高阶武学领悟',
      _ => tag,
    };
  }

  static const String baikeFeedEmpty = '尚无见闻,且看下回。';
  static const String baikeLoreEmpty = '装备尚浅,典故未集。';
  static const String baikeCodexEmpty = '机制百科尚未编纂。';

  // P1 #42 Phase 2 §10 P1.z 机制百科条目状态
  static const String codexLockedTitle = '待解锁';
  static const String codexLockedBody = '修行未至,机缘未到。';
  static const String codexUnlockedHintLabel = '已解锁';
  static String codexUnlockedHint(int unlocked, int total) =>
      '$codexUnlockedHintLabel $unlocked / $total';
  static const String codexMechanicSectionTitle = '机制卷宗';
  static const String codexMechanicSectionSubtitle = '修行、战斗与器用规矩';
  static const String codexLoreSectionSubtitle = '门派、江湖与器物旧闻';
  static String codexMechanicVolumeLabel(int step) => '第$step卷';
  static const String codexLoreVolumeLabel = '书册';
  static const String codexUnlockedStatus = '可翻阅';
  static const String codexLockedStatus = '未启封';
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
  static const String recruitmentCandidatesMissingTitle = '名册未至';
  static const String recruitmentCandidatesMissingBody = '收徒名册尚未载入，稍后再来。';

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
  // 飞升未满足子条件清单(AscensionEligibility.missingReasons · lineage_panel tooltip)。
  // 顺序对应 AscensionScreen 校验提示顺序。
  static const String ascensionReasonNotInActive = '祖师不在出战阵容';
  static const String ascensionReasonNotAtPeak = '祖师未达武圣·登峰';
  static const String ascensionReasonInnerDemonNotCleared = '心魔末关「心魔·真」未通';
  static const String ascensionReasonMainlineNotCleared = '飞升主线「昆仑山顶」未通';
  static const String ascensionReasonNoDiscipleTarget = '无可继承遗物的弟子';
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
  static const String ascensionSubmitting = '飞升中…';
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
  static const String sectDebugSpawnEventTooltip = '[调试]立即生成比武事件';
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
  static const String loreSectionDivider = '◇ 器物志 ◇';
  static String lorePresetTitle(int index) => '旧闻 $index';
  static const String loreHolderMemoryTitle = '持有人记忆';

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

  // ─── 藏经阁（P1b 技能装配）──────────────────
  static const String mainMenuSkillLibrary = '藏经阁';
  static const String mainMenuSkillLibraryHint = '查看武学 / 装配出战招式 / 熟练度 / 残页';
  static const String mainMenuSkillLibraryLockedHint = '修习武学后开启';
  static const String cangjingLoadoutTitle = '出战配置';
  static const String cangjingLoadoutHint = '自动配好 · 点槽位可换';
  static const String cangjingLibraryTitle = '武学';
  static const String cangjingFragmentTitle = '残页';
  static String cangjingSlotMain(int n) => '主修$n';
  static const String cangjingSlotAssist = '辅修';
  static const String cangjingSlotResonance = '共鸣';
  static const String cangjingSlotUltimate = '大招';
  static const String cangjingSlotEncounter = '奇遇';
  static const String cangjingSlotKey = '破招';
  static const String cangjingSlotEmpty = '空';
  static const String cangjingStyleLocked = '流派不合,装配不得';
  static String cangjingProficiencyNeed(int n) => '再用 $n 次→下一阶';
  static String cangjingFragmentProgress(int has, int total) =>
      '$has / $total 页';
  static const String cangjingFragmentEmpty = '暂无残页';
  // 残页来源提示（从 stages/towers 的 dropSkillFragmentId 反查派生）。
  static const String cangjingFragmentSourceUnknown = '来源未明';
  static String cangjingFragmentSourceTower(int floor) => '爬塔·第$floor层';
  static String cangjingFragmentSourceMainline(int chapter) =>
      '主线·第$chapter章重打';
  static const String cangjingTierLocked = '境界不足';
  static const String cangjingNotUnlocked = '未得真传,装配不得';
  static const String cangjingSecretGroupTitle = '秘传 · 真解残页';
  static const String cangjingPickerTitle = '选择招式';
  // 出战槽用途说明（玩家不查文档也懂每个槽的作用）。
  static const String cangjingSlotHintMain1 = '常用输出';
  static const String cangjingSlotHintMain2 = '补位输出';
  static const String cangjingSlotHintAssist = '辅修招式';
  static const String cangjingSlotHintResonance = '人剑合一';
  static const String cangjingSlotHintUltimate = '高内力爆发';
  static const String cangjingSlotHintKey = '打断蓄力';
  static const String cangjingSlotHintEncounter = '江湖奇招';
  static const String cangjingProficiencyMaxStage = '已达化境';
  static const String cangjingProficiencySourceCombat = '战斗放招增长';
  static const String cangjingEquippedTag = '装';
  static String cangjingProficiencyNeedWithSource(int n) =>
      '${cangjingProficiencyNeed(n)} · $cangjingProficiencySourceCombat';
  static String cangjingProficiencyCurrent(String effect) => '当前 $effect';
  static String cangjingProficiencyNext(String effect) => '下阶 $effect';
  static String cangjingProficiencyDamageBonus(int pct) => '伤害 +$pct%';
  static String cangjingProficiencyCooldownReduction(int turns) =>
      '冷却 -$turns回合';
  static String cangjingProficiencyInterruptPower(int pct) => '破招减防 +$pct%';
  static String cangjingProficiencyInterruptWindow(int turns) => '破绽 +$turns回合';
  static String cangjingProficiencyEffectList(List<String> effects) =>
      effects.join(' · ');
  static String skillProficiencyCompact(String stage, String effect) =>
      '熟练度$stage · $effect';
  static String skillProficiencyBestSkillTitle(String skillName) =>
      '招式熟练 · $skillName';
  static String cangjingPickerDamage(int n) => '伤害 $n';
  static const String cangjingPickerCanInterrupt = '可破招';
  // T6 武学库直接装配:选槽面板。
  static const String cangjingEquipToSlotTitle = '装到哪个槽';
  static const String cangjingNoLegalSlot = '此招暂无合适槽位';

  /// 招式熟练度阶段中文名（id → 显示名）。
  ///
  /// id 来自 `numbers.yaml` `combat.skill_proficiency.stages[].id`：
  /// `chuShi` / `shunShou` / `shuLian` / `jingTong` / `huaJing`。
  static String cangjingProficiencyStageName(String stageId) {
    return switch (stageId) {
      'chuShi' => '初识',
      'shunShou' => '顺手',
      'shuLian' => '熟练',
      'jingTong' => '精通',
      'huaJing' => '化境',
      _ => stageId,
    };
  }

  // ── 闭关非阻塞 + 出战锁(2026-06-14 L3)──────────────────────────────
  /// 主菜单闭关横幅行:闭关中 · {地图名} · 剩 {时长}
  static String mainMenuRetreatBannerLine(String mapName, String remaining) =>
      '闭关中 · $mapName · 剩 $remaining';

  /// 主菜单闭关横幅行:收益封顶后直接提示可收功
  static String mainMenuRetreatBannerCappedLine(String mapName) =>
      '收益已满 · $mapName · 点此收功';

  /// 剩余时长格式:有小时显「N 时 M 分」,否则「M 分」
  static String retreatRemainingText(int hours, int minutes) =>
      hours > 0 ? '$hours 时 $minutes 分' : '$minutes 分';

  /// 出战锁弹窗(闭关进行中点战斗入口)
  static const String seclusionBattleLockTitle = '闭关修行中';
  static const String seclusionBattleLockBody = '正自闭关参修,心神内守,此刻不宜出战。';
  static const String seclusionBattleLockStay = '静心继续';
  static const String seclusionBattleLockEndEarly = '提前出关';

  /// 开始闭关题字过场
  static const String seclusionEnterCaption = '闭关';

  // ── M2 离线收益汇总「归来」卡(2026-06-15)──────────────────────────
  /// recap 卡标题
  static const String offlineRecapTitle = '归来';

  /// 离开时长副标题
  static String offlineRecapAwayLine(int hours) => '离去约 $hours 小时';

  /// 闭关已挂满状态行
  static String offlineRecapMapComplete(String mapName) => '「$mapName」闭关已圆满';

  /// 闭关已达系统收益封顶状态行
  static String offlineRecapMapCapped(String mapName) => '「$mapName」闭关收益已满';

  /// P1-6(2026-06-29 审查修复):闭关开始界面前瞻提示——离线最长计入时长。
  /// 消除「挂 24h 回来只算 X h 觉得亏」的预期落差(在线=离线哲学,想玩才玩)。
  static String seclusionCapHint(int capHours) => '本次闭关最长计入 $capHours 小时，超出不计';

  /// P1-6:离线归来已达上限时的温和建议(不制造焦虑·守反留存红线)。
  static const String offlineCappedAdvice = '已达离线上限，可缩短下次闭关间隔';

  /// 闭关进行中状态行（带进度百分比）
  static String offlineRecapMapProgress(String mapName, int pct) =>
      '「$mapName」闭关进行中 · $pct%';

  /// 预计可收产出行
  static String offlineRecapRewardLine(int mojianshi, int experience) =>
      '预计可收 $mojianshi 磨剑石 · $experience 经验';

  /// 离线收益总览（闭关中）
  static String offlineRecapRewardOverview(
    int mojianshi,
    int silver,
    int experience,
  ) => '预计可收 $mojianshi 磨剑石 · $silver 银两 · $experience 经验';

  /// 离线收益明细标题
  static const String offlineRecapBreakdownTitle = '归来小结';

  /// 离线收益明细分组：时间与结算口径
  static const String offlineRecapSettlementGroupTitle = '江湖游历';

  /// 离线收益明细分组：修行成长
  static const String offlineRecapRetreatGainGroupTitle = '修行沉淀';

  /// 离线收益明细分组：被动离线成长
  static const String offlineRecapPassiveGainGroupTitle = '修行沉淀';

  /// 离线收益明细分组：银两与材料类收获
  static const String offlineRecapMaterialGroupTitle = '装备与材料';

  /// 离线收益明细分组：收功时才掷定的内容
  static const String offlineRecapCollectGroupTitle = '收功时揭晓';

  /// 离线收益明细空收益兜底
  static const String offlineRecapNoGainsDetail = '本次没有新的入账';

  /// 离线收益明细：在线离线同口径说明
  static const String offlineRecapParityDetail = '在线离线同源结算，不含加速或额外奖励';

  /// 离线收益明细：真实离线时长
  static String offlineRecapAwayDetail(String hours) => '游历时长：$hours';

  /// 离线收益明细：有效结算时长
  static String offlineRecapSettledDetail(String hours) => '计入收益：$hours';

  /// 离线收益明细：磨剑石
  static String offlineRecapMojianshiDetail(int value) => '磨剑石：$value';

  /// 离线收益明细：材料汇总
  static String offlineRecapMaterialDetail(String value) => '材料入囊：$value';

  /// 离线收益明细：材料子项（磨剑石）
  static String offlineRecapMaterialPartMojianshi(int value) => '磨剑石 $value';

  /// 离线收益明细：材料子项（通用物品）
  static String offlineRecapMaterialPart(String name, int value) =>
      '$name $value';

  /// 离线收益明细：银两
  static String offlineRecapSilverDetail(int value) => '银两入账：$value';

  /// 离线收益明细：经验
  static String offlineRecapExperienceDetail(int value) => '阅历沉淀：$value';

  /// 离线收益明细：心法 / 招式熟练度
  static String offlineRecapTechniqueSkillDetail(
    int techniqueLearn,
    int skillProficiency,
  ) => '心法领悟：$techniqueLearn · 招式熟练度：$skillProficiency';

  /// 离线收益明细：心法领悟点
  static String offlineRecapTechniqueLearnDetail(int value) => '心法领悟：$value';

  /// 离线收益明细：招式熟练度
  static String offlineRecapSkillProficiencyDetail(int value) => '招式熟练度：$value';

  /// 离线收益明细：掉落
  static String offlineRecapDropDetail(String value) => '装备/掉落：$value';

  /// 离线收益明细分隔符
  static const String offlineRecapDetailSeparator = ' · ';

  /// active 闭关掉落尚未实际掷定
  static const String offlineRecapDropPending = '收功时揭晓';

  /// passive 被动离线无装备掉落池
  static const String offlineRecapNoDrop = '无';

  /// 离线收益截断：仍在计划时长内
  static const String offlineRecapLimitInProgress = '未达上限，按已过时长结算';

  /// 离线收益截断：达到本次计划闭关时长
  static const String offlineRecapLimitPlanned = '已达本次闭关计划时长';

  /// 离线收益截断：达到系统封顶
  static const String offlineRecapLimitSystemCap = '已达离线收益封顶';

  /// 已达封顶后的收功按钮
  static const String offlineRecapCollectCapped = '一键收功';

  /// 前去收功按钮
  static const String offlineRecapGoCollect = '前去收功';

  /// 稍后再说按钮（关闭卡片）
  static const String offlineRecapDismiss = '稍后再说';

  // ── M2 范围 B 被动离线告知卡(2026-06-15)──────────────────────────
  /// 被动卡标题（非闭关期间亦有精进）
  static const String passiveRecapTitle = '闭关之外，亦有精进';

  /// 被动卡正文（含离开时长 / 磨剑石 / 修为三项产出）
  static String passiveRecapBody(int hours, int moji, int exp) =>
      '离去约 $hours 时辰。这些时日你未曾松懈，行功走架之间，'
      '得磨剑石 $moji、修为 $exp，已收入囊中。';

  /// 被动卡总览
  static String passiveRecapOverview(int moji, int exp) =>
      '已入库 $moji 磨剑石 · $exp 经验';

  /// 被动卡关闭按钮
  static const String passiveRecapDismiss = '甚好';

  // ── 门派 UI(audit M3 散写中文归集)────────────────────────────────────
  /// 门派声望纯标签
  static const String sectReputationLabel = '声望';

  /// 门派等阶标签：`等阶 N`
  static String sectLevelLabel(int level) => '等阶 $level';

  /// 累计胜场标签：`累计胜场 N`
  static String sectTotalWinsLabel(int wins) => '累计胜场 $wins';

  /// 当前无进行中门派事件占位
  static const String sectNoActiveEvent = '当前无门派事件';

  /// 门派事件触发时间行：`触发 · <日期>`
  static String sectEventTriggeredAt(String date) => '触发 · $date';

  /// 门派历史记录为空占位
  static const String sectNoHistory = '尚无历史记录';

  /// 历史记录声望变化：`声望 <deltaStr>`（deltaStr 含正负号）
  static String sectReputationDelta(String deltaStr) => '声望 $deltaStr';

  /// 门派操作失败提示(promote/dismiss/claim/release 共用)
  static const String sectOperationFailed = '操作失败';

  /// 门派事件类型标签
  static const String sectEventTypeTournament = '比武大会';
  static const String sectEventTypeMission = '弟子任务';
  static const String sectEventTypeCrisis = '门派危机';

  /// 门派事件状态标签
  static const String sectEventStatusPending = '待处理';
  static const String sectEventStatusResolved = '已结算';
  static const String sectEventStatusExpired = '已过期';

  // ── 主线关卡剧情/战败代价(audit M3 散写中文归集)──────────────────────
  /// 战败剧情 fallback 标题：`<关名> · 战败`
  static String stageNarrativeDefeatTitle(String stageName) =>
      '$stageName · 战败';

  /// 胜利剧情 fallback 标题：`<关名> · 胜利`
  static String stageNarrativeVictoryTitle(String stageName) =>
      '$stageName · 胜利';

  /// 战败散功代价卡标题（Boss 关散功惩罚场景）
  static const String defeatLossTitle = '战败 · 散功代价';

  /// 战败心魔反噬卡标题（M6 心魔关余毒场景，与散功 Boss 关互斥）
  static const String defeatLossTitleInnerDemon = '战败 · 心魔反噬';

  /// 战败内力回退段：`内力 <before>→<after>`
  static String defeatInternalForceSegment(int before, int after) =>
      '内力 $before→$after';

  /// 战败武学层数回退段：`<技名> <旧层>→<新层> (-<N>层)`
  static String defeatTechniqueLayerSegment(
    String techniqueName,
    String? oldLayerLabel,
    String? newLayerLabel,
    int layersRolledBack,
  ) => '$techniqueName $oldLayerLabel→$newLayerLabel (-$layersRolledBack层)';

  /// 战败武学修炼度回退段：`<技名> 修炼度回退`
  static String defeatTechniqueProgressSegment(String techniqueName) =>
      '$techniqueName 修炼度回退';

  /// 心魔失败余毒标记段（追加在内力段之后）：`余毒未消`
  static const String innerDemonResidueNote = '余毒未消';

  // ── 双层伤势 UI（第八阶段 Task 9）──────────────────────────────────────────
  /// 心魔余毒状态标签。
  static const String conditionInnerDemonResidueLabel = '心魔余毒';

  /// 心魔余毒来源提示。
  static const String conditionInnerDemonResidueSource = '来源：心魔战败反噬';

  /// 心魔余毒持续影响提示。
  static String conditionInnerDemonResidueEffect({
    required int battleOutputPenaltyPct,
    required int internalForceRecoveryPenaltyPct,
  }) =>
      '影响：战斗输出 -$battleOutputPenaltyPct% · 闭关内力 -$internalForceRecoveryPenaltyPct%';

  /// 心魔余毒清解提示。
  static String conditionInnerDemonResidueRecovery(double hours) =>
      '清解：闭关清调 ${hours.ceil()}h';

  /// 轻伤状态标签：`带伤`（含层数时由调用方拼接，如 `带伤×3`）。
  static const String injuryLightLabel = '带伤';

  /// 重伤状态标签：`重伤`。
  static String get injuryHeavyLabel => combatTermLabel(CombatTerm.heavyInjury);

  /// 重伤疗养剩余提示：`内伤未愈 · 调息 <N>h`（h 向上取整）。
  static String injuryRecoveryHint(double hours) =>
      '内伤未愈 · 调息 ${hours.ceil()}h';

  static const String injuryStatusTitle = '伤势';
  static const String injuryStatusHealthy = '无伤 · 可出战';
  static String injuryStatusLight(int stacks, int speedPenalty) =>
      '带伤×$stacks · 出手速度 -$speedPenalty';
  static String injuryStatusHeavy({
    required double hours,
    required int attackPenaltyPct,
    required int internalForcePenaltyPct,
  }) => combatTermGloss(
    CombatTerm.heavyInjury,
    hours: hours,
    attackPenaltyPct: attackPenaltyPct,
    internalForcePenaltyPct: internalForcePenaltyPct,
  );
  static String injuryStatusLine(String name, String status) => '$name：$status';
  static const String injuryStatusRecoveryHint = '可闭关调息，或服用疗伤丹处理。';
  static const String injuryStatusRecoveryAction = '服用疗伤丹';
  static String injuryStatusRecoveryApplied(String targetName) =>
      '已为$targetName处理伤势';
  static const String injuryStatusRecoveryUnavailable = '暂无可用疗伤丹';
  static const String injuryStatusRecoveryFailed = '未能处理伤势';
  static const String injuryBattleSummaryTitle = '伤势：';
  static const String injuryBattleSummaryNone = '本战无人新增重伤';

  /// 战败 banner 受伤弟子提示：`<N> 名弟子负伤 · 需调息疗养`。
  static String defeatInjuredDisciples(int count) => '$count 名弟子负伤 · 需调息疗养';

  // ── 通用加载失败(audit M3 散写中文归集)──────────────────────────────
  /// 异步加载失败提示：`加载失败：<e>`（全角冒号）
  static String loadFailed(Object e) => '加载失败：$e';

  // ── 百科 UI(audit M3 散写中文归集)──────────────────────────────────
  /// 典故数量标签：`<N> 段典故`
  static String baikeLoreCount(int count) => '$count 段典故';

  // ── 心魔镜像(audit M3 散写中文归集)──────────────────────────────────
  /// 心魔镜像角色名：`心魔·<源名>`
  static String innerDemonMirrorName(String name) => '心魔·$name';

  // ── 战后英雄镜头(第七阶段 批一)──────────────────────────────────────
  /// 英雄镜头击破字幕，参数为 Boss 名。
  static String heroCameraDefeated(String bossName) => '击破 $bossName';

  /// 英雄镜头本场最强标签。
  static const String heroCameraTopOutput = '本场最强';

  // ── 第七阶段批二 ④:技能书珍稀卷轴 overlay(真解首通 / 残页集齐重仪式)──────
  /// 真解首通卷轴题字（manualGranted != null 时展示）。
  static const String skillTreasureManualCaption = '悟得真解';

  /// 残页集齐卷轴题字（fragmentJustUnlocked 时展示）。
  static const String skillTreasureFragmentCaption = '残页集齐 · 神功重现';
  static const String skillTreasureScrollLabel = '得卷';
  static const String skillTreasureManualHint = 'Boss 真解入卷，可入藏经阁研习。';
  static const String skillTreasureFragmentHint = '散页合为一卷，旧招重见全貌。';
  static const String skillTreasureFallbackGlyph = '卷';

  /// 残页轻提示（战后 victory dialog 内小行；Task 11 消费）。
  /// 格式：「得残页 · $skillName($count/$threshold)」
  static String skillFragmentGainedLine(
    String skillName,
    int count,
    int threshold,
  ) => '得残页 · $skillName($count/$threshold)';

  // ── 第七阶段批三 · 弟子拜入英雄镜头题字──────────────────────────────────
  /// 弟子拜入英雄镜头题字(第七阶段批三)。[name]=弟子名(大弟子/二弟子)。
  static String discipleJoinCaption(String name) => '$name 拜入门下';

  // ── P4 战绩册(Task 5)────────────────────────────────────────────────────
  // 主菜单入口
  static const String mainMenuBattleRecord = '战绩册';
  static const String mainMenuBattleRecordHint = '回顾历战，名垂江湖';
  // 屏标题 / 分区 / 占位
  static const String battleRecordTitle = '战绩册';
  static const String battleRecordLockedBoss = '未会之敌';
  static const String battleRecordPreRecord = '此役不详 · 记录之前';
  static const String battleRecordTopContributorTitle = '此战之最';
  static const String battleRecordRosterTitle = '出战';
  static const String battleRecordTreasureTitle = '所获';
  static const String battleRecordStatsTitle = '首胜战绩';
  static String battleRecordDefeatCount(int n) => '击败 $n 次';
  static String battleRecordDamage(int d) => '总伤害 $d';
  static String battleRecordCrits(int c) => '暴击 $c';
  static String battleRecordTurns(int t) => '$t 回合';
  static String battleRecordClearedAt(String date) => '初胜 $date';

  // ── 兵器谱 ──
  static const String mainMenuWeaponCodex = '兵器谱';
  static const String mainMenuWeaponCodexHint = '历观神兵，谱录江湖';
  static const String weaponCodexTitle = '兵器谱';
  static const String weaponCodexEmptyHint = '谱册尚未备妥';
  static const String weaponCodexBackfillSource = '来历不详';
  static const String weaponCodexLockedItem = '未得之器';
  static const String weaponCodexHistoryUnknown = '来历已不可考';
  static const String weaponCodexFilterAll = '全部';
  static const String weaponCodexFilterWeapon = '兵器';
  static const String weaponCodexFilterArmor = '护甲';
  static const String weaponCodexFilterAccessory = '饰品';
  static const String weaponCodexNotObtained = '尚未得手';
  static String weaponCodexProgress(int got, int total) => '已录 $got / $total';
  static String weaponCodexTierProgress(int got, int total) => '$got/$total';
  static String weaponCodexFirstObtainedAt(String date) => '首得 $date';
  static String weaponCodexFirstObtainedFrom(String src) => '得于 $src';
  static String weaponCodexObtainedCount(int n) => '历得 $n 件';
  static String weaponCodexSourceTowerFloor(int floor) => '宝塔第 $floor 层';

  // 兵器谱详情屏（Task 9）。
  static const String weaponCodexDetailArchiveTitle = '器物档案';
  static const String weaponCodexDetailHistoryTitle = '个人历程';
  static const String weaponCodexDetailSlot = '部位';
  static const String weaponCodexDetailAttackRange = '攻击';
  static const String weaponCodexDetailHealthRange = '生命';
  static const String weaponCodexDetailSpeedRange = '速度';
  static const String weaponCodexDetailSpecialSkills = '开锋候选技';
  static const String weaponCodexDetailLineage = '师承遗物·境界相称方可佩用';
  static String weaponCodexDetailRange(int min, int max) =>
      min == max ? '$min' : '$min ~ $max';

  // ── 审查 M-#2 散写中文归集(2026-06-22):空态/信息串/徽章(错误态复用 loadFailed)──
  // 三副本空态(stages 为空时)。
  static const String massBattleEmpty = '守城五处试炼未启';
  static const String lightFootEmpty = '轻功五处试炼未启';
  static const String innerDemonEmpty = '心魔七关未启';

  // 三副本关卡信息行(波数/地形/难度)。difficulty 传已格式化字符串。
  static String massBattleStageInfo(
    int waves,
    int enemies,
    String formation,
    String difficulty,
  ) => '$waves 波 · 共 $enemies 敌 · 阵型 $formation · 难度 $difficulty';
  static String lightFootStageInfo(String terrain, String difficulty) =>
      '$terrain · 难度 $difficulty';
  static String innerDemonStageInfo(String difficulty) => '难度 $difficulty';

  // 爬塔 boss 徽章字:floor_list 小标(大/小)+ floor_card 字形(魁/关)。
  static const String towerBossBadgeMajor = '大';
  static const String towerBossBadgeMinor = '小';
  static const String towerSpineCurrentBadge = '今';
  static const String towerSpineHighestBadge = '至';
  static const String towerFloorGlyphMajor = '魁';
  static const String towerFloorGlyphMinor = '关';

  // 招式列表「当前装配」标。
  static const String currentEquippedBadge = '[当前]';

  // ─── 桃花岛（Phase 2 经营基地）UI 文案 ──────────────────────────────────────
  // §5.6 合法集中 sink：UI 标签/提示集中此处，文案走水墨克制基调。
  // 调用方：TaohuaIslandScreen / BuildingCard / HarvestRecapCard 等（Task 11-13 待引用）。

  /// 主菜单入口标签（江湖分组）。
  static const String mainMenuTaohuaIsland = '桃花岛';

  /// 主菜单入口副文案（解锁后）。
  static const String mainMenuTaohuaIslandHint = '隐世经营 · 挂机产料炼器';

  /// 主菜单入口副文案（未解锁）。
  static const String mainMenuTaohuaIslandLockedHint = '通关第二章后开放';

  /// 桃花岛主屏标题。
  static const String taohuaIslandTitle = '桃花岛';

  /// 桃花岛场景化主屏总览。
  static const String taohuaIslandOverviewTitle = '岛上总览';
  static const String taohuaIslandOverviewBody = '洞府、药圃、炉坊沿岛势分布，物产、加工与疗养一屏可察。';
  static const String taohuaIslandSceneCave = '洞府';
  static const String taohuaIslandSceneCaveBody = '门人调息疗养，出岛前先看伤势。';
  static const String taohuaIslandSceneField = '药圃';
  static const String taohuaIslandSceneFieldBody = '草药、灵泉与木材随时辰积蓄。';
  static const String taohuaIslandSceneWorkshop = '炉坊';
  static const String taohuaIslandSceneWorkshopBody = '精铁入炉，丹药与辅材各守配方。';
  static const String taohuaIslandSceneDock = '渡口';
  static const String taohuaIslandSceneDockBody = '暂作外出整备与后续工程留白。';
  static const String taohuaIslandSceneMapTitle = '岛屿场景';
  static String taohuaIslandSceneMapSummary(
    int rawStored,
    int workshopStored,
  ) => '物产 $rawStored · 成品 $workshopStored';
  static String taohuaIslandSceneHotspotMeta(int level, int stored) =>
      'Lv.$level · $stored';
  static String taohuaIslandSelectedBuildingTitle(String buildingName) =>
      '$buildingName详情';
  static const String taohuaIslandSelectedBuildingBody = '仓储、配方与修缮俱归此处。';

  /// 桃花岛总览状态摘要。
  static const String taohuaIslandStatusRawTitle = '当前物产';
  static String taohuaIslandStatusRawValue(int stored) => '可收 $stored 件';
  static const String taohuaIslandStatusWorkshopTitle = '作坊加工';
  static String taohuaIslandStatusWorkshopValue(
    int stored,
    int active,
    int paused,
  ) => paused > 0
      ? '成品 $stored · $active 动 $paused 停'
      : '成品 $stored · $active 坊运转';
  static const String taohuaIslandStatusHealingTitle = '洞府疗养';
  static const String taohuaIslandStatusHealingNone = '无人重伤';
  static String taohuaIslandStatusHealingValue(int count, double hours) =>
      '$count 名调息 · 余 ${hours.ceil()}h';

  /// 桃花岛据点分区：原料产出。
  static const String taohuaIslandSectionRaw = '物产';

  static const String taohuaIslandSectionRawBody = '药圃、林场与灵泉先蓄源料。';
  static String taohuaIslandSectionRawSummary(int stored) => '当前可收物产 $stored 件';

  /// 桃花岛据点分区：加工建筑。
  static const String taohuaIslandSectionWorkshop = '作坊';

  static const String taohuaIslandSectionWorkshopBody = '炉火、丹鼎与铸台把源料转成整备物。';
  static String taohuaIslandSectionWorkshopSummary(
    int stored,
    int active,
    int paused,
  ) => paused > 0
      ? '成品 $stored 件 · $active 间运转 · $paused 间停工'
      : '成品 $stored 件 · $active 间运转';

  /// 桃花岛据点分区：后续码头面板。
  static const String taohuaIslandSectionDock = '码头';

  static const String taohuaIslandSectionDockBody = '船只未发，先把岛务与补给理顺。';

  /// 建筑等级标签：`第 N 级`。
  static String taohuaIslandLevelLabel(int lv) => '第 $lv 级';

  /// 建筑仓储进度：`cur / cap`。
  static String taohuaIslandStorageLabel(int cur, int cap) => '$cur / $cap';

  /// 建筑升级按钮。
  static const String taohuaIslandUpgrade = '升级';

  /// 建筑选配方按钮。
  static const String taohuaIslandSelectRecipe = '选配方';

  /// 建筑收取按钮。
  static const String taohuaIslandHarvest = '收取';

  /// 全部建筑一并收取按钮。
  static const String taohuaIslandHarvestAll = '一并收取';

  /// 收获 recap 卡标题。
  static const String taohuaIslandRecapTitle = '桃花岛纪事';

  /// recap 空态文案（各坊尚无产出）。
  static const String taohuaIslandRecapEmpty = '岛上诸坊尚无所获，且待时日。';

  /// 建筑/操作境界未到的提示标签（通用兜底，无具体境界名时用）。
  static const String taohuaIslandRealmLocked = '境界未至';

  /// 升级境界 gate 提示（节奏 B 分阶解锁）：告知升下一级所需境界，让灰按钮可读。
  static String taohuaIslandRealmLockedFor(String realmName) =>
      '需$realmName境界方可升级';

  /// 建筑已至最高等级标签。
  static const String taohuaIslandMaxLevel = '已至顶级';

  /// 升级银两不足提示。
  static const String taohuaIslandNotEnoughSilver = '银两不足';

  /// 升级材料不足提示。
  static const String taohuaIslandNotEnoughMaterial = '材料不足';

  /// 升级费用文案：`银两 N · matName ×qty`。
  static String taohuaIslandUpgradeCost(
    int silver,
    String matName,
    int matQty,
  ) => '银两 $silver · $matName ×$matQty';

  /// 建筑生产中状态标签。
  static const String taohuaIslandIdleProducing = '产出中';

  /// 建筑暂停状态标签（未配方或原料不足）。
  static const String taohuaIslandIdlePaused = '已停（择配方/补料）';

  /// 建筑协同提示。
  static String taohuaIslandSynergyLine(List<String> parts) =>
      '协同：${parts.join(' / ')}';

  static String taohuaIslandSynergyPart(String sourceName, int percent) =>
      '$sourceName +$percent%';

  /// 数据读取失败错误提示（§5.6 迁出中文字面量）。
  static String taohuaIslandLoadError(Object e) => '读取失败：$e';

  /// 无存档时的友好态提示（§5.6 迁出中文字面量）。
  static const String taohuaIslandNoSave = '尚无存档，请先进入游戏。';

  /// 产物名前缀：`产出：name`（§5.6 迁出中文字面量）。
  static String taohuaIslandOutputPrefix(String name) => '产出：$name';

  /// 桃花岛生产队列可读化。
  static String taohuaIslandCurrentGathering(String name) => '当前采集：$name';
  static String taohuaIslandCurrentRecipe(String name) => '当前配方：$name';
  static const String taohuaIslandCurrentRecipeNone = '当前配方：未选择';
  static String taohuaIslandNextOutputIn(String duration) => '下一件：约 $duration';
  static const String taohuaIslandNextOutputPaused = '下一件：停产中';
  static const String taohuaIslandNextOutputFull = '下一件：仓满';
  static String taohuaIslandFullStorageIn(String duration) => '满仓：约 $duration';
  static const String taohuaIslandFullStorageNow = '满仓：已满';
  static const String taohuaIslandFullStorageUnknown = '满仓：暂不可估';
  static String taohuaIslandOutputUsage(String usage) => '去向：$usage';
  static const String taohuaIslandOutputUsageNone = '去向：暂未形成消耗';
  static const String taohuaIslandOutputUsageTagCultivation = '用于修炼';
  static const String taohuaIslandOutputUsageTagTechnique = '用于解招';
  static const String taohuaIslandOutputUsageTagEnhancement = '用于强化';
  static const String taohuaIslandOutputUsageTagForging = '用于开锋';
  static const String taohuaIslandOutputUsageTagGuarantee = '用于保底';
  static const String taohuaIslandOutputUsageTagRecovery = '用于疗伤';
  static const String taohuaIslandOutputUsageTagShopping = '用于采买';
  static const String taohuaIslandOutputUsageTagUpgrade = '用于修缮';
  static const String taohuaIslandOutputUsageTagRecipe = '用于加工';
  static const String taohuaIslandOutputUsageTagNone = '暂未消耗';
  static String taohuaIslandOutputUsageTag(
    ItemUsage usage,
  ) => switch (usage.kind) {
    ItemUsageKind.realmProgress => taohuaIslandOutputUsageTagCultivation,
    ItemUsageKind.techniqueUnlock => taohuaIslandOutputUsageTagTechnique,
    ItemUsageKind.equipmentEnhancement => taohuaIslandOutputUsageTagEnhancement,
    ItemUsageKind.equipmentForging => taohuaIslandOutputUsageTagForging,
    ItemUsageKind.equipmentGuarantee => taohuaIslandOutputUsageTagGuarantee,
    ItemUsageKind.injuryRecovery => taohuaIslandOutputUsageTagRecovery,
    ItemUsageKind.shopPurchaseCurrency => taohuaIslandOutputUsageTagShopping,
    ItemUsageKind.islandUpgradeCurrency ||
    ItemUsageKind.islandBuildingUpgrade => taohuaIslandOutputUsageTagUpgrade,
    ItemUsageKind.islandRecipeInput => taohuaIslandOutputUsageTagRecipe,
  };
  static const String taohuaIslandBuildingManualTitle = '建筑志';
  static const String taohuaIslandBuildingManualProduces = '产物';
  static const String taohuaIslandBuildingManualConsumes = '消耗';
  static const String taohuaIslandBuildingManualSynergy = '协同';
  static const String taohuaIslandBuildingManualUsage = '去向';
  static const String taohuaIslandBuildingManualNone = '无';
  static const String taohuaIslandBuildingManualUsageNone = '暂未形成消耗';
  static String taohuaIslandBuildingManualLine(String label, String value) =>
      '$label：$value';
  static String taohuaIslandBuildingManualGatherRate(String itemName) =>
      '采集 $itemName';
  static String taohuaIslandBuildingManualRecipeOutputs(String names) =>
      '配方产出 $names';
  static String taohuaIslandBuildingManualUpgradeMaterial(String itemName) =>
      '升级修缮用 $itemName';
  static String taohuaIslandBuildingManualRecipeCost(
    String recipe,
    String cost,
  ) => '$recipe：$cost';
  static String taohuaIslandBuildingManualSynergyTarget(
    String targetName,
    int percent,
  ) => '助 $targetName 每级 +$percent%';
  static String taohuaIslandBuildingManualSynergySource(
    String sourceName,
    int percent,
  ) => '受 $sourceName 每级 +$percent%';
  static String taohuaIslandBuildingManualOutputUsage(
    String outputName,
    String usage,
  ) => '$outputName：$usage';
  static String taohuaIslandDuration(double hours) {
    if (hours <= 0) return '片刻';
    final minutes = ((hours * 60) - 1e-6).ceil();
    if (minutes < 60) return '$minutes 分';
    final roundedHours = (hours - 1e-6).ceil();
    return '${roundedHours}h';
  }

  /// selectRecipe 不可达路径失败文案（notProcessor / recipeNotFound）。
  static const String taohuaIslandSelectRecipeFailed = '无法择此配方';

  /// 桃花岛整备建议区标题。
  static const String islandPrepSectionTitle = '整备建议';

  /// 缺装备线索转化的整备建议。
  static const String islandPrepEquipmentTitle = '补兵器缺口';
  static const String islandPrepEquipmentBody = '翻检兵器谱缺页，出岛前可预备强化材料与疗伤丹。';

  /// 缺残页线索转化的整备建议。
  static const String islandPrepFragmentTitle = '补武学残页';
  static const String islandPrepFragmentBody = '藏经阁尚有残页未齐，临行前可备开锋辅材与破招余量。';

  /// Boss 周目线索转化的整备建议。
  static const String islandPrepBossCycleTitle = '备异势再战';
  static const String islandPrepBossCycleBody = '有首破周目尚待回看，宜先整顿疗养与补给再登程。';

  /// 岛务工程碑 first slice：只读长期工程占位，不消耗资源、不写存档。
  static const String islandProjectSteleTitle = '岛务工程碑';
  static const String islandProjectSteleLockedLine = '长期工程尚在筹备，只记录此番整备方向。';

  // ── 一键挂机扫荡 ───────────────────────────────────────────────────────
  /// 主线章节扫荡入口主按钮。
  static const String sweepChapterButton = '一键扫荡本章';

  /// 爬塔扫荡入口主按钮。
  static const String sweepTowerButton = '一键扫荡 30 层';

  /// 未达门槛时的灰显提示（需本周目通关全部关卡）。
  static const String sweepLockedHint = '需本周目通关全部关卡后解锁';

  /// 周目徽章（按钮后缀 / recap / HUD 共用）。
  static String sweepCycleBadge(int cycle) => '第 $cycle 周目';

  /// 主线章节扫荡按钮（带周目）。
  static String sweepChapterButtonCycle(int cycle) =>
      '$sweepChapterButton · ${sweepCycleBadge(cycle)}';

  /// 爬塔扫荡按钮（带周目）。
  static String sweepTowerButtonCycle(int cycle) =>
      '$sweepTowerButton · ${sweepCycleBadge(cycle)}';

  /// 未达门槛灰显提示（带周目，§5.7 先手工通关该周目全部关卡）。
  static String sweepLockedHintCycle(int cycle) =>
      '${sweepCycleBadge(cycle)}需先手工通关全部关卡';

  /// recap 行：本次扫荡的周目。
  static String sweepRecapCycle(int cycle) => '扫荡 · ${sweepCycleBadge(cycle)}';

  /// 扫荡屏标题前缀。
  static String sweepTitle(String unitName) => '一键扫荡 · $unitName';

  /// 连播进度：第 X / N 关。
  static String sweepProgress(int current, int total) =>
      '连播中 · $current / $total';

  /// 装配下一关过场提示。
  static const String sweepPreparing = '装配中…';

  /// 醒目停止按钮。
  static const String sweepStopButton = '停止扫荡';

  /// 收尾 recap 标题（全部扫完）。
  static const String sweepRecapCompleted = '扫荡完成';

  /// 收尾 recap 标题（用户中途停）。
  static const String sweepRecapStopped = '已停止扫荡';

  /// 收尾 recap 标题（某关战败 halt）。
  static String sweepRecapDefeated(int floorIndex) => '扫到第 $floorIndex 关战败';

  /// 战败 halt 原因提示（伤势/内力累积）。
  static const String sweepDefeatReason = '战力不济（伤势 / 内力累积），已停在此关';

  /// recap 行：成功扫过关数。
  static String sweepRecapStages(int n) => '通关 · $n 关';

  /// recap 行：掉落装备件数。
  static String sweepRecapEquipment(int n) => '装备 · $n 件';

  static const String sweepLayerRare = '稀有收获';
  static const String sweepLayerEquipment = '装备';
  static const String sweepLayerMaterials = '材料';
  static const String sweepLayerResources = '货币 / 资源';
  static const String sweepLayerIneffective = '无效 / 已满';

  /// recap 行：累计经验。
  static String sweepRecapExp(int n) => '经验 · $n';

  /// recap 行：升层次数。
  static String sweepRecapAdvances(int n) => '升层 · $n 次';

  /// recap 行：技能残页。
  static String sweepRecapFragments(int n) => '残页 · $n 页';

  static String sweepRecapLargePills(int n) => '大还丹 · $n 枚';

  static String sweepRecapPills(int n) => '经验丹 · $n 枚';

  /// recap 行：银两。
  static String sweepRecapSilver(int n) => '银两 · $n';

  /// recap 行：材料（非银两物品合计件数）。
  static String sweepRecapMaterials(int n) => '材料 · $n 件';

  static String sweepRecapIgnored(int n) => '未入账 · $n 项';

  static const String sweepRecapNoGains = '无新增收益';

  /// 爬塔扫荡重打仅掉残页的说明（守 §5.1 防刷）。
  static const String sweepTowerRepeatNote = '爬塔重打仅掉技能残页，不掉装备 / 银两';

  static const String sweepPreviewTitle = '扫荡前预估';
  static const String sweepPreviewDropsPrefix = '可能掉落';
  static const String sweepPreviewProficiencyPrefix = '熟练度方向';
  static const String sweepPreviewMaterialHitsPrefix = '命中缺口';
  static const String sweepPreviewNoDrops = '无明确掉落';
  static const String sweepPreviewNoMaterialHits = '未命中已知材料缺口';
  static const String sweepPreviewSkillManual = '秘籍解招';
  static const String sweepPreviewSkillFragment = '残页积累';
  static String get sweepPreviewChargeSkill =>
      '敌方${combatTermLabel(CombatTerm.charge)}技';

  static String sweepPreviewEquipmentDrops(int count) => '装备 $count 类';

  static String sweepPreviewLine(String prefix, String body) =>
      '$prefix · $body';

  static String sweepPreviewMore(int count) => '另 $count 项';

  static String sweepPreviewMaterialHit(String itemName, String usageSummary) =>
      '$itemName($usageSummary)';

  /// recap 返回按钮。
  static const String sweepRecapBack = '返回';

  // ── Debug · 数值红线审计（§5.6 集中归集 2026-06-27，仅 kDebugMode 工具）──
  // main_menu debug 区两个按钮
  static const String mainMenuSectRecruit = '强制招募 NPC';
  static const String mainMenuSectRecruitHint =
      '走完整 sect recruit flow · 跳过战斗/奇遇触发';
  static const String mainMenuRedlineAudit = '数值红线审计';
  static const String mainMenuRedlineAuditHint = '开发工具 · 查看 PASS/WARN/FAIL 与来源';

  // 审计屏文案
  static const String redlineAuditScreenTitle = '数值红线审计';
  static const String redlineAuditRepoNotLoaded = 'GameRepository 未加载';
  static String redlineAuditSummary(String status, int count) =>
      '总览 $status · $count 项红线';
  static const String redlineAuditMetricObserved = '当前最大值';
  static const String redlineAuditMetricLimit = '红线';
  static const String redlineAuditMetricHeadroom = '余量';
  static String redlineAuditSourceLine(String source) => '来源: $source';

  // markdown 报告头
  static const String redlineAuditMdTitle = '# 数值红线审计报告';
  static const String redlineAuditMdIntro =
      '> 工具生成，入口: `VISUAL_ROUTE=redline_audit`。';
  static const String redlineAuditMdTableHeader =
      '| 项目 | 状态 | 当前最大值 | 红线 | 来源 |';
  static const String redlineAuditMdNotesHeader = '## 备注';

  // 审计项 label
  static const String redlineItemEquipmentAttack = '装备基础攻击';
  static const String redlineItemPlayerHp = '玩家血量';
  static const String redlineItemBossHp = 'Boss 血量';
  static const String redlineItemInternalForce = '内力上限';
  static const String redlineItemSkillMultiplier = '招式倍率';
  static const String redlineItemNormalDamage = '普通伤害';
  static const String redlineItemUltimateCrit = '大招暴击';

  // 审计项 note（带探针参数的用方法）
  static const String redlineNoteEquipmentAttack =
      '只审计配置基础表值；强化、共鸣、开锋后的派生攻击不属于该硬红线。';
  static String redlineNotePlayerHp(int maxLevel) =>
      '使用满 build + L$maxLevel + founder buff 极值探针，走 CharacterDerivedStats.maxHp。';
  static const String redlineNoteBossHp =
      '扫描主线和爬塔 Boss 配置 baseHp；周目 clamp 仍由既有 battle/setup 测试兜底。';
  static String redlineNoteInternalForce(int maxLevel) =>
      '使用满 build + L$maxLevel + founder buff 极值探针，走 CharacterDerivedStats.internalForceMaxWithLineage。';
  static const String redlineNoteSkillMultiplier =
      '扫描 skills.yaml 与 encounter_skills.yaml 合并后的 skillDefs 全池。';
  static String redlineNoteNormalDamage(int typicalTarget) =>
      '软红线：典型目标 $typicalTarget，满 build 极值可越过；唯一硬线是不进百万。';
  static const String redlineNoteUltimateCrit =
      '软红线：使用当前最高 ultimate 倍率和满 build 暴击探针；真实战斗峰值仍由 balance_simulator 兜底。';
}
