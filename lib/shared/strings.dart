import '../core/domain/item_source.dart';
import '../core/domain/item_usage.dart';
import '../core/domain/resource_overview_display.dart';

enum CombatTerm { charge, interrupt, zhenqi, yuti, phase, heavyInjury }

/// UI 静态中文标签（phase1_tasks.md T14）。
///
/// 与 [lib/shared/battle_shared/enum_localizations.dart] 同性质：Phase 1 把"代码内中文"集中
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

  static const String tickPrefix = '节拍';

  // ── surviveTicks 型胜负条件的玩家可见面(2026-07-29 Ch21 主线首用补) ──
  // 此前该条件只有战斗逻辑(schema + strategy 逐 tick 判定),表现层零呈现:
  // 玩家看到的是「打不死的对手忽然赢了」。心魔 07 靠独立呈现路径兜底,主线不可复用。
  /// 战斗顶栏条件条：`守住 N 拍 · 还差 M`。M 为剩余拍数。
  static String surviveConditionRemaining(int required, int remaining) =>
      '守住 $required 拍 · 还差 $remaining';

  /// 战斗顶栏条件条(已达成)：`守住 N 拍 · 已守满`。
  static String surviveConditionMet(int required) => '守住 $required 拍 · 已守满';

  /// 结算标题(surviveTicks 型胜利)：与「击败」区分——赢法不同,说法就不同。
  static const String battleResultSurvived = '守住了';

  static const String battleLog = '战斗日志';
  static const String battleLogShort = '日志';
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
      '确定认输撤退？本场不计掉落，首领关也不折损修为，只是退回去重整旗鼓。';
  static const String surrenderConfirmAction = '撤退';
  static const String surrenderCancelAction = '再打打';
  // M3:普通关战败立即重试(Boss 关不给 · 试错免费无惩罚)。
  static const String stageRetryTitle = '功亏一篑';
  static const String stageRetryPrompt = '这一战未能取胜。要再试一次吗？';
  static const String stageRetryHintLine = '可回行囊换装备，或先去别处历练再来。';
  static const String stageRetryAction = '再战';
  static const String stageRetryBackAction = '返回';
  static const String emptyLog = '（无动作）';
  static const String ultimate = '大招';
  static const String fastForward = '快进';
  static const String battleSpeedNormal = '一倍';
  static const String battleSpeedFast = '急速';
  static const String battleAutoMode = '自动战斗';
  static const String battleAutoIntervention = '可点选';
  static const String battleAutoModeShort = '自动';
  static const String battleAutoInterventionShort = '点选';
  static const String battleAutoModeHint = '全程托管，角色按招式轮转谱自行出手。';
  static const String battleAutoInterventionHint =
      '战斗持续自动；点武学签可预支该角色下一次行动，出手后重新回势。';
  static const String battleAutoRotation = '招式轮转谱';
  static const String battleAutoObserve = '托管推演';
  static const String skillReady = '可用';
  static const String skillReservedForInterrupt = '候破';
  static const String skillGatheringQi = '蓄气';
  static const String battleNoEquippedSkills = '只运周天';
  static const String battleFallen = '力竭';
  static String skillCooldownRemaining(int turns) => '息 $turns';
  static const String battleCommandDesk = '武学案台';
  static const String battlePouch = '战备行囊';
  static const String battlePouchShort = '行囊';
  static const String battlePouchReserved = '待装配';
  static const String battleEmptySkillSlot = '空招式位';
  static const String battlePouchEmptySlot = '空囊位';

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
    CombatTerm.phase => '相位：首领血量跌破阈值后的阶段变化，会切换招式节奏或触发蓄力反扑。',
    CombatTerm.heavyInjury =>
      '重伤：硬仗战败或惨胜后的伤势。'
          '调息 ${hours?.ceil() ?? 0} 小时，输出 -${attackPenaltyPct ?? 0}%，'
          '内力上限 -${internalForcePenaltyPct ?? 0}%。',
  };

  // P0 破招
  static const String battleInterruptSkill = '破招';
  // T2 蓄力危险条：敌人正在蓄力大招的顶部警示（招名 + 剩余节拍）。
  static String battleDangerCharging(
    String enemyName,
    String skillName,
    int ticks,
  ) =>
      '$enemyName 正在${combatTermLabel(CombatTerm.charge)}：$skillName（还有 $ticks 拍发动）';
  static const String battleDangerChargeLabel = '蓄势';
  static String battleDangerTicks(int ticks) => '$ticks拍';
  static const String battleDangerPrefix = '⚠ ';

  // 战斗指挥案台黄金样板 fixture：集中维护，避免 debug 路由散写文案。
  static const String battleSampleSceneTitle = '山道伏击';
  static const String battleSampleFounder = '祖师';
  static const String battleSampleFirstDisciple = '弟子·凌风';
  static const String battleSampleSecondDisciple = '弟子·云舟';
  static const String battleSampleHiddenElder = '隐世老者';
  static const String battleSampleBanditBlade = '山贼刀客';
  static const String battleSampleBanditArcher = '山贼弓手';
  static const String phase0aDebugBanditB = '黑风打手';
  static const String phase0aDebugBanditC = '黑风喽啰';
  static const String battleSampleSkillOpenMountain = '开山掌';
  static const String battleSampleSkillBreakCurrent = '断流';
  static const String battleSampleSkillSnowStep = '踏雪';
  static const String battleSampleSkillReturnOne = '归一式';
  static const String battleSampleSkillSwallowReturn = '燕回';
  static const String battleSampleSkillMeridianCut = '截脉';
  static const String battleSampleSkillHiddenEdge = '藏锋';
  static const List<String> battleSampleSkillNames = [
    battleSampleSkillOpenMountain,
    battleSampleSkillBreakCurrent,
    battleSampleSkillSnowStep,
    battleSampleSkillReturnOne,
    battleSampleSkillSwallowReturn,
    battleSampleSkillMeridianCut,
    battleSampleSkillHiddenEdge,
  ];

  // T1 战斗指令台：技能分组标签 + 状态印 + 内力/冷却短标。
  static const String skillGroupPower = '强力';
  static const String skillGroupJoint = '共鸣';
  static const String skillSealPower = '强';
  static const String skillSealInterrupt = '破';
  static const String skillSealGroup = '群';
  static const String skillSealUltimate = '绝';
  static const String skillSealAssist = '辅';
  static const String skillSealEncounter = '奇';
  // 破招用 [battleInterruptSkill]='破招'、大招用 [ultimate]='大招'。
  static const String skillPendingStamp = '待发';
  static const String skillAwaitingAction = '回势中';
  static const String skillCharging = '蓄力中';
  static const String skillStaggered = '踉跄中';
  static const String skillTargetable = '可选';
  static const String skillTargetLocked = '锁定';

  // ── Phase 0A 技能印(单角色竞技场 · Q 聚怪 / R 清场)──
  /// 印章主 glyph:单字题字感,区别于完整技能名。
  static const String phase0aSealGatherGlyph = '聚';
  static const String phase0aSealClearGlyph = '清';

  /// 键位角标(gather=Q / clear=R,与模拟核输入映射一致)。
  static const String phase0aSealGatherKey = 'Q';
  static const String phase0aSealClearKey = 'R';

  /// cooldown 态状态行:`冷却 N.N 秒`(保留一位小数,跟模拟核剩余拍精度)。
  static String phase0aSealCooldown(double seconds) =>
      '冷却 ${seconds.toStringAsFixed(1)} 秒';

  /// qi 态状态行:`真气 当前/所需`。
  static String phase0aSealQiShort(int current, int cost) =>
      '真气 $current/$cost';

  /// casting 态状态行(明确禁用原因:正在施放)。
  static const String phase0aSealCasting = '施放中';

  /// down 态状态行(明确禁用原因:倒地无法出手)。
  static const String phase0aSealDown = '倒地';
  static String phase0aWaveBanner(int index, int total) =>
      '第 $index 波 · 共 $total 波';
  static const String phase0aVictorySeal = '破阵';
  static const String phase0aDefeatSeal = '败退';
  static const String phase0aRetryLabel = '再战';
  static const String phase0aBossChargeWarning = '蓄力可破';
  static const String phase0aBossChargeInterrupted = '破！';
  static const String phase0aDefenseStarted = '守势';
  static const String phase0aDefenseResolved = '化解';
  static const String phase0aDefenseSemantics = '防御动作：E 护盾，F 化解，Z 闪避';
  static const String phase0aDefenseShieldKey = '守势 E';
  static const String phase0aDefenseParryKey = '化解 F';
  static const String phase0aDefenseDodgeKey = '闪避 Z';
  static const String phase0aDefenseAbsorbPrefix = '吸收';
  static const String phase0aDefenseCooldownPrefix = '冷却';
  static const String phase0aVulnerabilityOpen = '破绽 · 全力';
  static const String phase0aVulnerabilityGuarded = '护体 · 减伤';
  static const String phase0aStaggered = '踉跄';
  static const String phase0aGuardianIntercepted = '护法截招';

  /// Esc 暂停横幅(0C):暂停时世界零推进,再按 Esc 继续。
  static const String phase0aPausedBanner = '稍歇 · Esc 继续';
  static const String phase0aPlayerHealth = '气血';
  static const String phase0aPlayerQi = '真气';

  // 可用态：耗气 N · CD M。
  static String skillCostShort(int cost, int cooldown) =>
      '耗气$cost · CD$cooldown';
  static String skillQiChange(int delta) => delta > 0
      ? '产气 +$delta'
      : delta < 0
      ? '耗气 ${-delta}'
      : '中性';
  static String techniqueQiProfile({
    required int openingBonus,
    required int maxBonus,
    required double gainPct,
    required double costReductionPct,
  }) {
    final parts = <String>[
      if (openingBonus > 0) '开场真气 +$openingBonus',
      if (maxBonus > 0) '气海 +$maxBonus',
      if (gainPct > 0) '产气 +${(gainPct * 100).round()}%',
      if (costReductionPct > 0) '减耗 ${(costReductionPct * 100).round()}%',
    ];
    return parts.isEmpty ? '真气倾向：中性' : '真气倾向：${parts.join(' · ')}';
  }

  static String skillCooldownShort(int turns) => '冷却$turns';
  // 真气不足态短标。
  static const String skillInsufficientForce = '真气不足';
  static const String battleMomentumSeal = '势';
  // 批次 1.3 技能简介浮层：点击技能方块弹出，直接读 SkillDef 活数据。
  // 字段标签（左列），值由活数据 / EnumL10n 填。
  static const String skillInfoType = '类型';
  static const String skillInfoTarget = '目标';
  static const String skillInfoPower = '威力';
  static const String skillInfoCost = '真气';
  static const String skillInfoCooldown = '冷却';
  static const String skillInfoTrait = '特性';
  // 特性值：可打断 → 破招（命中蓄力中目标可打断其招牌技）。
  static String get skillTraitInterrupt =>
      '${combatTermLabel(CombatTerm.interrupt)} · 可打断${combatTermLabel(CombatTerm.charge)}';
  // 无特殊特性时的占位（普通技无可打断等标签）。
  static const String skillTraitNone = '无';
  // 冷却值单位（战斗节拍）。
  static String skillInfoCooldownTurns(int turns) => '$turns 拍';
  // 浮层底部操作提示：点选交互说明。
  static const String skillInfoTapHint = '轻点招式：单体技再点敌人出手，群体技一键即放';
  // 技能按钮角标：区分单体 / 群体目标类型。
  static const String skillBadgeSingle = '单';
  static const String skillBadgeAoe = '群';
  // Debug visual routes:两段点选验收提示。
  static const String battleTapLiveHint =
      '两段点选技能下发:单体技先点技能进入待发,再点敌头像指定目标 · 群体技点技能即对全体触发 · 已暂停,点单步推进或继续自动';
  static const String battleTapPreviewHint =
      '两段点选预览:单体技能已待发,敌头像为可选目标,技能角标区分单体/群体';
  static const String battleBossPhaseHint =
      '已暂停。点顶栏「单步」逐拍推进:刚猛打 Boss 出「会心」(弱点×1.25)、灵巧伤害偏低(抗性×0.75)、Boss 半血触发「背水一击」转阶段 + 蓄力反扑。也可点继续自动 / 点选技能干预';
  static const String battleGuardianWardHint =
      '已暂停在护罩生效帧:九霄魔尊头像旁「护法结界」pill(护法存活时刀枪不入)。点顶栏「单步」逐拍推进,先手清完左使/右使 → 结界破「结界破！」题字 + 破界闪白,主 Boss 恢复满承伤。也可点继续自动 / 点选技能干预';
  // 浮层关闭按钮。
  static const String skillInfoClose = '知道了';
  // 角色头像真气条标签前缀。
  static const String internalForceShortLabel = '气 ';
  // B3 破招成功「破！」题字 overlay 文案(破招方暖金/敌方绛红)。
  static const String interruptCaption = '破！';

  /// 第八阶段 §2.2:双护法合击题字(敌方绛红,沿 interruptCaption 体例)。
  static const String coopStrikeCaption = '合击！';
  // 玩法评估 §十三 #2 首通展示帧题字:开局亮相 / 敌方首次蓄力教学提示。
  static const String firstClearOpening = '初战';
  static const String firstClearChargeCue = '蓄力可破';
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

  // floor30 护法结界（Task 6）：结界生效中头像旁小标签 + hover 释义。
  // 沿用 statusSwordSongLabel/Gloss 惯例：短 label 上药丸，长 gloss 走 tooltip。
  // 破界瞬间走 UltimateCaptionOverlay 题字通道（复用转阶段题字机制，不另起平行系统）。
  static const String guardianWardActiveLabel = '护法结界';
  static const String guardianWardActiveGloss = '护法结界·刀枪不入';
  static const String guardianWardBroken = '结界破！';

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
  // 暴击飘字由 damage_popup 按「标签 / 数字 / 后缀」三段各自排版(字号字色不同),
  // 故此处只出标签与后缀两个常量,不再提供拼好整句的格式化函数——整句版本会与
  // 飘字层的分段组合形成同一句文案的两处定义,曾诱发下游正则反解析(BACKLOG §二#4)。
  static const String criticalLabel = '暴击';
  static const String damageSuffix = '伤害';

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

  /// 战斗结算 dialog 内容：`总伤害 X  暴击 Y 次  用时 Z 拍`。
  static String battleSummary(int totalDamage, int critCount, int totalTicks) =>
      '总伤害 $totalDamage    暴击 $critCount 次    用时 $totalTicks 拍';

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
  static const String diagCauseCharge = '被首领蓄力大招击溃';
  static const String diagCauseCounter = '主力流派被对面克住';
  static const String diagCauseInternalWound = '被内伤层层拖垮';
  static const String diagCauseMob = '被群敌围殴拖死';
  static const String diagCauseGuardianWard = '首领仍受护法结界庇护';
  static const String diagCauseFrontline = '前排太脆，过早倒下';
  static const String diagCauseSupplies = '续航不足，伤势拖到见底';
  static const String diagCauseDps = '输出不足，未能速决';
  static const String diagCauseGeneric = '惜败，调整战术后再战';

  // 关键数据（2 条/规则）
  static String diagPlayerTopRealm(String realm) => '己方最高境界：$realm';
  static String diagEnemyTopRealm(String realm) => '敌方最高境界：$realm';
  static String diagLethalHit(String skill, int dmg) => '致命一击：$skill $dmg';
  static String diagInternalForceLeft(int cur, int max) => '真气余量：$cur/$max';
  static String diagCounteredDamageRatio(int pct) => '受克制伤害占比：$pct%';
  static String diagDominantEnemySchool(String school) => '敌方主攻流派：$school';
  static String diagInternalWoundRatio(int pct) => '内伤占比：$pct%';
  static String diagDamageTaken(int dmg) => '受到总伤：$dmg';
  static String diagMinionRatio(int pct) => '小怪伤害占比：$pct%';
  static String diagGuardianAliveCount(int count) => '存活护法：$count 名';
  static String diagGuardianWardDamageTaken(int pct) => '首领当前承伤：$pct%';
  static String diagFrontlineDeath(String name, int tick) =>
      '$name 在第 $tick 拍倒下';
  static String diagFrontlineMaxHp(int hp) => '其最大血量：$hp';
  static String diagRecoveryDone(int hp) => '战中回复：$hp';
  static String diagTotalTicks(int tick) => '总节拍：$tick';
  static String diagSurvivorHp(int pct) => '敌方残血：平均 $pct%';
  static String diagTotalDamage(int dmg) => '总伤害：$dmg';

  // 建议（1 条/规则）
  static const String diagSuggestRealm = '先闭关推境界，再回来碰硬仗。';
  static const String diagSuggestCharge = '保留真气、装配破招技，看准蓄力时机破招。';
  static const String diagSuggestCounter = '换一名主修不被克的门人上阵，或调整主修流派。';
  static const String diagSuggestInternalWound = '备好回复，或换能压住内伤的心法。';
  static const String diagSuggestMob = '补一名清场手，先清场再攻坚。';
  static const String diagSuggestGuardianWard = '先集火护法，破掉结界后再攻首领。';
  static const String diagSuggestFrontline = '强化护具、以虚弱/回复护住前排。';
  static const String diagSuggestSupplies = '查看药囊、疗伤丹与带回复的装备。';
  static const String diagSuggestDps = '提升招式熟练度，使用破防技提速。';
  static const String diagSuggestGeneric = '检视招式装配，调整后再战。';

  // 跳转按钮 label
  static const String diagJumpSkills = '查看招式装配';
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
  static String mainMenuStatusRetreatDetail(
    String mapName,
    String elapsedHours,
  ) => '$mapName · 已闭关 $elapsedHours 小时';
  static String mainMenuStatusIslandDetail(int count) => '约$count 件产物待收';
  static String mainMenuStatusInjuryDetail(int count, double maxHours) {
    if (maxHours <= 0) return '$count 名角色需调息';
    return '$count 名角色需疗养 · 最长 ${maxHours.toStringAsFixed(1)} 小时';
  }

  static String mainMenuStatusBreakthroughDetail(String name) =>
      '$name 经验已满，查看瓶颈';
  static String mainMenuStatusMainlineDetail(int chapterIndex, String stage) =>
      '前往第$chapterIndex章 · $stage';

  static const String mainMenuPhase2 = 'Phase 2 调试场景';
  static const String mainMenuPhase2Hint =
      '4 个数据种子场景（强化曲线 / 共鸣触发 / 散功代价 / 全栈对比）';
  static const String mainMenuCharacterPanel = '角色面板';
  static const String mainMenuCharacterPanelHint = '查看角色属性 / 装备 / 心法';
  static const String mainMenuSectHub = '宗门';
  static const String mainMenuSectHubHint = '角色、调度、闭关、疗伤、远征与生产';
  static const String sectHubTitle = '宗门';
  static const String sectHubSectionTitle = '安顿门中诸事';
  static const String sectHubSubtitle = '看人、调度、疗养与经营皆归此处，各项仍循原有门槛。';
  static const String sectHubCharacters = '角色档案';
  static const String sectHubCharactersHint = '查看当前角色属性、成长与状态';
  static const String sectHubLineup = '门人调度';
  static const String sectHubLineupHint = '安排出战席位与空闲门人';
  static const String sectHubSeclusion = '闭关修炼';
  static const String sectHubSeclusionHint = '择地闭关，按真实时长修行疗养';
  static const String sectHubHealing = '伤势疗养';
  static const String sectHubHealingHint = '查看伤势、调息时长与疗伤丹';
  static const String sectHubExpedition = '江湖远行';
  static const String sectHubExpeditionHint = '派遣空闲角色远征百草岭';
  static const String sectHubProduction = '桃花生产';
  static const String sectHubProductionHint = '经营桃花岛并收取宗门产物';
  static const String sectHubAffairs = '门派事务';
  static const String sectHubAffairsHint = '处理门派事件、成员与领地';
  static const String sectHubCharacterLoadingHint = '角色名册仍在载入';
  static const String sectHubNoActiveCharacterHint = '暂无可用的出战角色';
  static const String mainMenuMartialInventory = '武学与行囊';
  static const String mainMenuMartialInventoryHint = '招式、主修、装备与物品';
  static const String martialInventoryHubTitle = '武学与行囊';
  static const String martialInventoryHubSectionTitle = '整备所学所藏';
  static const String martialInventoryHubSubtitle = '招式与主修归于个人，装备与物品归于宗门行囊。';
  static const String martialInventorySkills = '招式配置';
  static const String martialInventorySkillsHint = '装配招式、查看熟练度与残页';
  static const String martialInventoryTechniques = '主修心法';
  static const String martialInventoryTechniquesHint = '查看主修、辅修与散功换修';
  static const String martialInventoryEquipment = '装备';
  static const String martialInventoryEquipmentHint = '查看、强化、开锋与穿戴装备';
  static const String martialInventoryItems = '物品';
  static const String martialInventoryItemsHint = '查看材料、丹药、秘籍与杂项';
  static const String martialInventoryMartialLockedHint = '通过第三关后开放武学整备';
  static const String martialInventoryNoActiveCharacterHint = '暂无可用的出战角色';
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
  static const String equipProtectedCurrent = '装备受保护，请先手动卸下后再更换';
  static const String equipReservedByActivity = '该角色或装备远行/断魂庄在途保留，返程后方可操作';
  static const String equipDirectActionEquip = '装备';
  static const String equipDirectActionUnequip = '卸下';
  static const String inventoryEquipActionEquip = '装备';
  static const String inventoryEquipActionUnequip = '卸下';
  static const String equipNoActiveCharacter = '暂无可装备角色';
  static const String equipDirectSuccess = '已装备';
  static const String equipDirectUnequipSuccess = '已卸下';
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
  static const String inventoryEquipCompareTitle = '装备对比';
  static const String inventoryEquipCompareNoCurrent = '当前未装备';
  static String inventoryEquipCompareCurrent(String name) => '当前：$name';
  static String inventoryEquipCompareCandidate(String name) => '换上：$name';
  static String inventoryEquipCompareDelta(int delta) => delta == 0
      ? '±0'
      : delta > 0
      ? '+$delta'
      : '$delta';
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
  static const String currencySilverTooltip = '当前银两';
  static const String currencySilverUnit = '两';
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
  static String profileLevelValue(int level) => 'Lv$level';
  static String profileLevelProgress(int current, int next) =>
      '$current / $next';
  static const String profileCultivationLevelLabel = '修为等级';
  static String profileCultivationLevel(int level) => 'Lv$level';
  static String profileCultivationExperience(int current, int next) =>
      '经验 $current / $next';
  static const String profileWaitingForInnerDemon = '经验已满 · 待破心魔';
  static const String profileCultivationPeak = '修为巅峰';
  static const String levelUpCeremonyTitle = '修为精进'; // 第八阶段 D·Lv 升级 banner 标题
  static String cultivationLevelChanged(
    String name,
    int levelBefore,
    int levelAfter,
  ) => '$name · 修为等级 Lv$levelBefore → Lv$levelAfter';
  static String cultivationExperienceGained(String name, int amount) =>
      '$name · 修为经验 +$amount';
  static String cultivationRealmAndLevelChanged(
    String realmText,
    int levelBefore,
    int levelAfter,
  ) => '$realmText · Lv$levelBefore → Lv$levelAfter';
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

  /// 种子师徒的占位名(`defaultMasterName`;slot 1/2 复用上面的大弟子/二弟子)。
  static const String masterDefaultNameFounder = '祖师';
  static String masterDefaultNameFallback(String defId) => '师徒_$defId';
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

  /// 资质档位前缀（GDD §4.1）。角色档案页与招募候选卡共用。
  static const String rarityTierLabel = '资质';

  /// 资质档位后缀的总点数括注。招募候选卡把「资质」「档名」「总点数」拆成
  /// 三段独立着色，无法整串走 [rarityTierWithTotal]，故括注单独出一个入口，
  /// 避免全角括号散写进 widget（§8.2 Gate ⓐ）。
  static String rarityTotalParen(int total) => '（$total）';

  /// 资质档位 chip（GDD §4.1）：档名由 `EnumL10n.rarityTier` 提供，
  /// 总点数为**出生点数** `CharacterBirthAttributes.birthAttributeTotal`
  /// （非当前 `Attributes.total`，BACKLOG 一#16）。例:「资质 绝世（24）」。
  static String rarityTierWithTotal(String tierName, int total) =>
      '$rarityTierLabel $tierName（$total）';

  /// 资质谱牒印鉴的无障碍读法与印面字。
  static String rarityTierSemantics(String label, int total) =>
      '$label，出生点数 $total';
  static const String rarityTierSealGlyph = '鉴';

  static const String attrConstitution = '根骨';
  static const String attrEnlightenment = '悟性';
  static const String attrAgility = '身法';
  static const String attrFortune = '机缘';

  static const String statHp = '生命';
  static const String statInternalForce = '内力';
  static const String statQi = '真气';
  static const String statSpeed = '速度';
  static const String statCriticalRate = '暴击率';
  static const String statEvasionRate = '闪避率';
  static const String statEffectiveEquipmentAttack = '实战装备攻击';
  static const String statBaseDefenseRate = '基础防御';

  // M4 术语释义气泡（GlossaryTip）：四项属性 + 派生数值 + 养成进度术语。
  // §5.7 框架下用悬停/长按气泡，非教程弹窗。文案水墨克制、不用网游词汇。
  static const String glossaryConstitution =
      '根骨：体魄根基，决定血量上限；根骨深厚还能缩短新受重伤的疗养时长。';
  static const String glossaryEnlightenment =
      '悟性：资质灵慧，影响修炼速度与武学领悟概率。悟性高者，一点即通。';
  static const String glossaryAgility = '身法：轻灵敏捷，决定出手速度与闪避。身法高者，快人一步。';
  static const String glossaryFortune = '机缘：缘法深浅，影响普通奇遇触发率，并可解锁少量特殊选择。';
  static const String glossaryHp = '生命：可承受的伤害总量，归零即败。由境界、根骨与装备共同撑起。';
  static const String glossaryInternalForce =
      '内力：闭关积累的永久功力，受当前境界上限约束，决定招式威能，战斗中不消耗。';
  static const String glossaryQi = '真气：每场战斗独立运转的资源。普攻与流派条件产气，强力招式耗气，溢出部分不保留。';
  static const String glossarySpeed = '出手速度：决定行动快慢，速度越高出手越频。由身法、装备与心法共同加成。';
  static const String glossaryCriticalRate = '暴击率：触发暴击的概率，暴击会额外提高伤害；基础值不受身法影响。';
  static const String glossaryEvasionRate = '闪避率：完全避开来袭的概率。身法越高，越易闪躲。';
  static const String glossaryEffectiveEquipmentAttack =
      '实战装备攻击：当前全身装备经过强化、共鸣与开锋后的攻击总和。';
  static const String glossaryBaseDefenseRate =
      '基础防御：当前境界提供的减伤比例，战斗中的心法与其他效果会在此基础上叠加。';
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
      '主修：当前主修心法，定招式、流派根基与真气倾向。换主修会损失修炼度并引发临时内息紊乱。';
  static const String glossaryAssistTechnique =
      '辅修：旁修的心法，添额外加成而不动根基。换辅修无散功之痛，可放手尝试。';
  static const String glossarySchool = '流派：刚猛克阴柔、阴柔克灵巧、灵巧克刚猛，循环相克。顺克加伤，逆克减伤。';
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

  /// 踉跄 debuff(staggerTicksRemaining):被破招后阵脚大乱,数拍内任人宰割。
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
  static String contextHelpSemanticLabel(String label) => '查看“$label”帮助';
  static String glossarySemanticLabel(String label) => '查看“$label”释义';
  static String semanticDetails(Iterable<String?> details) =>
      details.whereType<String>().where((text) => text.isNotEmpty).join('，');
  static String battleTargetHealth(int current, int max) =>
      '$statHp $current / $max';
  static String battleRecordMemorySemanticLabel(String name) => '查看“$name”战绩';
  static String treasureDropContinueSemanticLabel(String name) =>
      '获得“$name”，继续';

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

  /// 相生 buff 摘要的属性标签(`SynergyMultipliers.summary()` 拼装 → chip 显示)。
  static const String synergyStatAttack = '攻';
  static const String synergyStatDefense = '防';
  static const String synergyStatSpeed = '速';
  static const String synergyStatHp = '血';
  static const String synergyStatInternalForceMax = '内力上限';
  static const String synergyStatInternalForceGrowth = '内力增长';

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
  static String inventoryConditionSegment(String group, String value) =>
      '$group：$value';
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
    final summary = materialSourceLabelsSummary(sources);
    return summary.isEmpty ? '' : '$materialSourcePrefix$summary';
  }

  /// 物料来源名称摘要，不含标题前缀，供已有独立「来源」标签的页面消费。
  static String materialSourceLabelsSummary(List<ItemSource> sources) {
    final labels = <String>{
      for (final source in sources) itemSourceLabel(source),
    }..remove('');
    return labels.take(6).join(' / ');
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
  static const String inventoryFilterPanelTitle = '筛选';
  static String inventoryFilterPanelSummary({
    required String condition,
    required String sort,
    required int activeCount,
  }) => activeCount == 0 ? '当前：全部 · $sort' : '当前：$condition · $sort';
  static const String inventoryFilterReset = '清空';
  static const String inventoryFilterGroupSlot = '部位';
  static const String inventoryFilterGroupTier = '品阶';
  static const String inventoryFilterGroupSchool = '流派';
  static const String inventoryFilterGroupStatus = '状态';
  static const String inventoryFilterGroupSort = '排序';
  static const String inventoryFilterAll = '全部';
  static const String inventoryFilterEquippable = '可装备';
  static const String inventoryFilterEquipped = '已穿戴';
  static const String inventoryFilterForgeable = '可开锋';
  static const String inventoryFilterRealmLocked = '境界未达';
  static const String inventoryFilterSchoolNone = '无流派';
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

  /// [ItemSlot.lockText] 的泛化默认值(调用方未给具体原因时兜底)。
  static const String itemSlotRealmLockedDefault = '未达境界';

  /// 资产缺失兜底:debug 角标 + 装备缺图占位的字形兜底。
  static const String assetMissingBadge = '缺图';
  static const String equipmentGlyphFallback = '器';
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
  static const String forgingSpecialSkillPickerTitle = '选择专属招式';
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

  static String forgingSpecialSkillLabel(String skillName) => '专属招式：$skillName';
  static const String forgingSpecialSkillDetailTitle = '器物绝招';
  static const String forgingSpecialSkillDetailSubtitle = '第三锋意已定，战斗中随装备带入。';
  static const String forgingSpecialSkillTriggerManual = '触发：手动下发';
  static const String forgingSpecialSkillTriggerInterrupt = '触发：敌方蓄力时优先破招';
  static const String forgingSpecialSkillTriggerAuto = '触发：真气足、冷却就绪时自动出手';
  static const String forgingSpecialSkillTriggerReady = '触发：自动战斗可用';
  static String forgingSpecialSkillSchool(String label) => '流派：$label';
  static String forgingSpecialSkillTarget(String label) => '目标：$label';
  static String forgingSpecialSkillCostCooldown(int cost, int cooldown) =>
      '真气 $cost · 冷却 $cooldown 拍';
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
  static String techniqueTierCount(int count) => 'x$count';
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
  static const String dispelOccupiedSnack = '该门人闭关/远行/断魂庄在途，归队后方可散功换修';

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

  // ── 研习新心法（学习闭环 · 2026-07-14）──────────────────────────────
  /// 面板入口常驻态：有领悟点显点数，0 点灰显（承凝练入口体例，§5.7 不推销）。
  static String learnTechniqueEntryWithPoints(int points) =>
      '研习新心法 · $points 点领悟';
  static const String learnTechniqueEntryEmpty = '研习新心法 · 暂无领悟点';
  static const String learnTechniqueTitle = '研习新心法';

  /// dialog 副标：说明消耗领悟点、境界不足者可观摩不可修（§5.3）。
  static const String learnTechniqueSubtitle =
      '静心参悟已知心法，消耗领悟点习得。境界未至者可观摩，不可修习。';
  static const String learnTechniqueEmptyList = '暂无可研习的心法（已习尽当前所见）。';
  static String learnTechniqueCost(int cost, {required bool asMain}) =>
      asMain ? '立为主修 · $cost 点' : '纳为辅修 · $cost 点';

  /// 无主修首学候选行双价预览(择路 dialog 内再按余额禁用单项)。
  static String learnTechniqueCostFirstChoice(int mainCost, int assistCost) =>
      '主修 $mainCost / 辅修 $assistCost 点';
  static const String learnTechniqueLockedByRealm = '境界不足';
  static const String learnTechniqueAsMain = '立为主修';
  static const String learnTechniqueAsAssist = '纳为辅修';

  /// 二确 dialog 正文与反馈。
  static String learnTechniqueConfirmBody(String techniqueName, int cost) =>
      '习得「$techniqueName」将消耗 $cost 点领悟。';
  static const String learnTechniqueConfirm = '研习';
  static String learnTechniqueSuccess(String techniqueName) =>
      '已习得「$techniqueName」';
  static const String learnTechniqueFailed = '研习未成，条件未满足';

  /// 首门心法择路 dialog(出战编成批并入 PR #36 观察① · 2026-07-14):
  /// 无主修时研习弹「立为主修/纳为辅修」选择;有主修维持仅辅修。
  static const String learnTechniqueFirstChoiceBody = '此为首门心法，请择修行之路。';

  // ── 出战编成(玩法评估 §十三 #4 · 2026-07-14)──────────────────────────
  static const String lineupTitle = '出战编成';
  static const String lineupActiveSection = '出战席位';
  static String lineupReserveSection(int count) => '替补门人（$count）';
  static const String lineupFrontRowTag = '前排';
  static const String lineupFrontRowHint = '首席居前排，同血量时更易被集火。';
  static const String lineupEmptySlotLabel = '空席';
  static const String lineupEmptySlotHint = '点替补门人入席';
  static const String lineupReserveEmptyGuide = '门下暂无替补。行走江湖、收徒招贤后，此处自会有人。';
  static const String lineupRetreatLockedTag = '闭关中';
  static const String lineupWeakTag = '境界偏低';
  static const String lineupNoMainTag = '未修主修';
  static const String lineupAiControl = '控场·压制蓄力';
  static const String lineupAiFocus = '破绽集火';
  static String lineupEquipAttack(int value) => '装备攻击 $value';

  /// 席位序号:slot 0-2 → 第一/二/三席。
  static String lineupSlotLabel(int index) =>
      '第${const ['一', '二', '三'][index]}席';
  static String lineupSwapInTitle(String name) => '「$name」入席';
  static const String lineupChooseSlotBody = '择一席位换防：';
  static String lineupReplaceSlot(String slotLabel, String occupantName) =>
      '$slotLabel · 换下「$occupantName」';
  static String lineupTakeEmptySlot(String slotLabel) => '$slotLabel · 入空席';
  static String lineupActiveActionTitle(String name) => '「$name」调度';

  /// 可下场时(非祖师·出战>1人·非闭关)的调度说明:含「下场歇息」。
  static const String lineupActiveActionBody = '下场歇息或与他席互换。';

  /// 不可下场时(祖师坐镇 / 仅剩 1 人出战 / 闭关中)的调度说明:仅换防,
  /// 不提「下场歇息」——该情形下场按钮隐藏,说明行须同步(否则提到不存在的按钮)。
  static const String lineupActiveActionBodySwapOnly = '与他席互换。';
  static const String lineupActionRetire = '下场歇息';
  static String lineupActionSwapWith(String slotLabel, String occupantName) =>
      '与$slotLabel「$occupantName」互换';
  static const String lineupApplySuccess = '编成已定';
  static const String lineupRetreatLockedSnack = '闭关中门人不可调整';
  static const String lineupNoMainSnack = '未修主修心法，研习立为主修后方可上场';
  static const String lineupActivityOccupiedSnack = '该门人远行/断魂庄在途，返程后方可上场';
  static const String lineupFounderMustStay = '祖师须坐镇出战席';
  static const String lineupApplyFailed = '编成未成，条件未满足';

  /// 散功代价 · 永久内力不变。
  static String dispelCostInternalForce(int before, int after) =>
      before == after ? '永久内力 $before（不变）' : '永久内力 $before → $after';

  /// 散功代价 · 内息紊乱累计时长（受配置上限约束）。
  static String dispelCostInnerBreathDisorder(
    double before,
    double after,
    double max,
  ) =>
      '内息紊乱 ${before.toStringAsFixed(1)} → ${after.toStringAsFixed(1)} 小时'
      '（累计上限 ${max.toStringAsFixed(1)} 小时）';

  /// 散功代价 · 原主修修炼度：`原主修修炼度 X → Y`。
  static String dispelCostCultivation(int before, int after) =>
      '原主修修炼度 $before → $after';
  static const String dispelIncomingCultivationUnchanged = '换入主修原修炼度不变';

  // ── Phase 3 主线（T35）──

  static const String mainMenuMainline = '继续江湖';
  static const String mainMenuMainlineHint = '21 章 105 关，按章节顺序解锁';
  static const String mainMenuJianghuMapAction = '江湖地图';
  static const String mainMenuJianghuMapActionHint = '查看已知地点与支线去处';
  static const String jianghuMapTitle = '江湖地图';
  static const String jianghuMapSubtitle = '循迹而行，各处机缘自有门槛';
  static const String jianghuMapKnownLocations = '已知地点';
  static const String jianghuMapKnownLocationsHint = '山河辽阔，未闻之处尚隐于烟岚';
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
  static const String mainlineRouteMapSubtitle = '二十一章江湖路 · 每章五关，朱印为首领';
  static const String mainlineRouteMapA11yHint = '可横向滚动，使用左右方向键查看各章';
  static const String mainlineRouteCurrent = '当前';
  static const String mainlineRouteCleared = '已通';
  static const String mainlineRouteLocked = '未至';
  static const String mainlineRouteBoss = '首领';
  static const String chapter1Title = '第一章 · 学武出山';
  static const String chapter2Title = '第二章 · 武林初识';
  static const String chapter3Title = '第三章 · 名扬江湖';
  static const String chapter4Title = '第四章 · 西出阳关';
  static const String chapter5Title = '第五章 · 征东';
  static const String chapter6Title = '第六章 · 飞升';
  static const String chapter7Title = '第七章 · 北望';
  static const String chapter8Title = '第八章 · 出塞';
  static const String chapter9Title = '第九章 · 碛北';
  static const String chapter10Title = '第十章 · 中州';
  static const String chapter11Title = '第十一章 · 名门之虚';
  static const String chapter12Title = '第十二章 · 名下之实';
  static const String chapter13Title = '第十三章 · 山外青山';
  static const String chapter14Title = '第十四章 · 山外来客';
  static const String chapter15Title = '第十五章 · 关山一程';
  static const String chapter16Title = '第十六章 · 凉州词';
  static const String chapter17Title = '第十七章 · 沙海纵深';
  static const String chapter18Title = '第十八章 · 阳关故人';
  static const String chapter19Title = '第十九章 · 旧路照人';
  static const String chapter20Title = '第二十章 · 东入阳关';
  static const String chapter21Title = '第二十一章 · 绝顶交程';
  static const String chapter1Hint = '初出茅庐，山道试剑、林间伏击';
  static const String chapter2Hint = '镖局护送、黑风寨剿匪';
  static const String chapter3Hint = '武林会、一战封王';
  static const String chapter4Hint = '潼关西行,玉门古道、大漠迷踪、嘉峪关一决';
  static const String chapter5Hint = '东归长安、嵩山道观、中州论剑大会';
  static const String chapter6Hint = '论剑散场、嵩山再访、黄河之源、昆仑山顶';
  static const String chapter7Hint = '北地风寒、雪压关城、山道伏影、灰衣重现、千钧压顶';
  static const String chapter8Hint = '塞外风急、瀚海孤烟、沙夜袭影、孤城闭雪、残照回风';
  static const String chapter9Hint = '符引出关、瀚海无路、蜃楼幻影、黑水绝壁、符尽之处';
  static const String chapter10Hint = '河套渡口、雁门古道、洛水照影、嵩阳雄关、止水深潭';
  static const String chapter11Hint = '许都剑会、金鼎山门、洛阳榷场、玉京华阁、问鼎高台';
  static const String chapter12Hint = '寒江野渡、槐花陋巷、秋山鸟道、山坳铁铺、荒村客店';
  static const String chapter13Hint = '山脚茶棚、半山古寺、云间竹林、断崖飞瀑、绝顶平台';
  static const String chapter14Hint = '山道马蹄、驿馆递帖、林间西剑、演武旧坪、绝顶一战';
  static const String chapter15Hint = '官道送行、黄河夜渡、古窟明王、沙海故道、长烟孤城';
  static const String chapter16Hint = '驿道送行、黑石铜镜、孤驿论武、大漠游骑、门户接关';
  static const String chapter17Hint = '砂丘初程、黑风迷道、沙埋古城、深沙卷手、腹地门前';
  static const String chapter18Hint = '碛口守哨、沿烟一线、西凉城下、演武三子、火堆之前';
  static const String chapter19Hint = '东望回身、旧沙重涉、风口听风、关城再叩、黑石重照';
  static const String chapter20Hint = '旧驿东行、烽下望关、墙前走门、门外接程、孤城为开';
  static const String chapter21Hint = '潼关认人、黄河过秤、旧坪取答、樵径受拦、绝顶交程';

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
  static const String stageListTimelineHint = '沿路标推进，已解锁旧事可主动翻阅';
  static const String mainlineNarrativeOptionalLabel = '旧事可阅';
  static const String mainlineNarrativeOpeningLabel = '开场';
  static const String mainlineNarrativeVictoryLabel = '胜利';
  static const String mainlineNarrativeDefeatLabel = '战败';
  static String mainlineNarrativeReadSemantics(
    String stageName,
    String section,
  ) => '翻阅$stageName的$section旧事';
  static const String stageListBoss = '首领';
  static const String stageListJourneyMinorBoss = '强敌';
  static const String stageListJourneyFinalBoss = '章末';
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
  static String stageListEnemyWaves(int waveCount, int enemyCount) =>
      '$waveCount 波 · 共 $enemyCount 名敌人';
  static String prebattleMainlineWaveSummary(
    int waveCount,
    int enemyCount, {
    required bool bossFinal,
  }) => bossFinal
      ? '$waveCount 波 · 共 $enemyCount 名敌人 · 主敌收尾'
      : '$waveCount 波 · 共 $enemyCount 名敌人';

  /// 章节标题路由：按 chapterIndex 返回对应中文标题。
  static String chapterTitle(int chapterIndex) {
    return switch (chapterIndex) {
      1 => chapter1Title,
      2 => chapter2Title,
      3 => chapter3Title,
      4 => chapter4Title,
      5 => chapter5Title,
      6 => chapter6Title,
      7 => chapter7Title,
      8 => chapter8Title,
      9 => chapter9Title,
      10 => chapter10Title,
      11 => chapter11Title,
      12 => chapter12Title,
      13 => chapter13Title,
      14 => chapter14Title,
      15 => chapter15Title,
      16 => chapter16Title,
      17 => chapter17Title,
      18 => chapter18Title,
      19 => chapter19Title,
      20 => chapter20Title,
      21 => chapter21Title,
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
      7 => chapter7Hint,
      8 => chapter8Hint,
      9 => chapter9Hint,
      10 => chapter10Hint,
      11 => chapter11Hint,
      12 => chapter12Hint,
      13 => chapter13Hint,
      14 => chapter14Hint,
      15 => chapter15Hint,
      16 => chapter16Hint,
      17 => chapter17Hint,
      18 => chapter18Hint,
      19 => chapter19Hint,
      20 => chapter20Hint,
      21 => chapter21Hint,
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
  static const String mainMenuTowerHint = '49 层，无限重试，永久记录';
  static String mainMenuTowerStatus(int highest, int next) =>
      highest <= 0 ? '未登塔 · 1层' : '已至$highest层 · 下$next层';
  static String mainMenuTowerBossStatus(int highest, int next) =>
      highest <= 0 ? '未登塔 · 1层' : '已至$highest层 · 下$next层首领';
  static const String mainMenuTowerCompleteStatus = '四十九层已通';

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

  static const String towerBossMinor = '小首领';
  static const String towerBossMajor = '大首领';

  static const String towerFloorLocked = '通关前一层解锁';
  static const String towerFloorChallenge = '挑战';

  static const String towerReplayTitle = '已通关';
  static const String towerReplayBody = '已通关，是否重打？（重打不发奖）';
  static const String towerReplayConfirm = '重打';
  static const String towerReplayCancel = '取消';

  static const String towerEntryPlaceholder = '爬塔进入流程待 T43 接入';

  static String towerProgressCleared(int cleared) => '已通 $cleared / 49 层';
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
  static const String towerNextMilestoneComplete = '下一节点：四十九层已尽';
  static const String towerMilestoneSummitBoss = '登顶大首领';
  static const String towerSpineLegend = '首领作节点，亮印为当前可挑战层，厚边为最高已通层';

  static String towerFloorLabel(int floorIndex) => '第 $floorIndex 层';

  /// 爬塔战报 fallback 标题(胜利)。
  static String towerFloorVictoryTitle(int floorIndex) =>
      '${towerFloorLabel(floorIndex)} · 胜利';
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
  }) => isBoss ? '破阵 · 第 $floorIndex 层首领' : '首通 · 第 $floorIndex 层';

  // ─── 主线 victory dialog（W15 #30 P3 后续 A 任务）────────────────────────

  static const String stageVictoryTitle = '战斗胜利';
  static const String stageVictoryConfirm = '继续';
  static const String stageVictoryReturnToMap = '返回江湖地图';
  static const String stageVictoryEnterNextStage = '进入下一关';
  static const String mainlineRunParticipantUnavailable = '掌门当前不可继续出战，已结束连续闯关。';
  static const String mainlineReplayParticipantTitle = '选择出战角色';
  static const String mainlineReplayParticipantBody = '本次重打的战绩、成长与伤势均归实际出战角色。';
  static const String mainlineReplayNoEligibleParticipant = '当前没有可参与重打的空闲角色。';
  static const String mainlineReplayParticipantUnavailable =
      '所选角色当前无法出战，请重新选择。';
  static const String mainlineSettlementRecoveredTitle = '前战已结';
  static const String mainlineSettlementRecoveredBody =
      '本关权威结算已保存；继续前行不会重复发放奖励、成长或伤势。';
  static const String stageVictoryDropLabel = '掉落：';
  static const String stageVictoryNoDrop = '本战无固定掉落';
  static const String stageVictoryReportTitle = '战后卷宗';
  static const String stageVictoryExperienceSection = '经验 / 修为';
  static const String stageVictoryEquipmentSection = '装备';
  static const String stageVictoryEquipmentHint = '可回行囊查看 / 整备新装备。';
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
      '反震：命中带词条的敌人后，攻击者会承受 $ticks 拍内伤，每拍 $damagePerTick。';
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
      ? '主线·第$chapterIndex章首领「$stageName」'
      : '主线·第$chapterIndex章「$stageName」';
  static String equipmentSourceStage(String stageName, bool isBoss) =>
      isBoss ? '支线·首领「$stageName」' : '支线·「$stageName」';
  static String equipmentSourceTower(int floorIndex, bool isBoss) =>
      isBoss ? '爬塔·第$floorIndex层首领' : '爬塔·第$floorIndex层';
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
  static const String mainMenuSeclusionHint = '5 张地图 · 开放式闭关 · 挂机无上限';
  static const String mainMenuSeclusionLockedHint = '通关第一章后开放';
  static const String mainMenuSeclusionReadyStatus = '可择地图';
  static const String mainMenuSeclusionLockedStatus = '未开放';
  static String mainMenuSeclusionActiveStatus(String mapName) =>
      '闭关中 · $mapName';
  static String mainMenuSeclusionPassiveStatus(String mapName) =>
      '挂机接续 · $mapName';

  // ─── 心魔境（1.0 P2.2 §12.1,Batch 2.5.B 入口）─────────────────────────────
  static const String mainMenuInnerDemon = '心魔境';
  static const String mainMenuInnerDemonHint = '7 关克己 · 武圣突破前置';

  // ─── 轻功对决（1.0 P3.1 §12.3,Batch B.3 入口）────────────────────────────
  static const String mainMenuLightFoot = '轻功试炼';
  static const String mainMenuLightFootHint = '5 关地形 · 一寸余地';
  static String jianghuMapLightFootProgress(int cleared, int total) =>
      '已过 $cleared / $total';

  // ─── 群战守城（1.0 P3.2 §12.3,Batch 2.4 入口）────────────────────────────
  static const String mainMenuMassBattle = '守城试炼';
  static const String mainMenuMassBattleHint = '5 关守城 · 以少胜多';

  // ─── 江湖远行（百草岭远征 · Phase B2.4 入口，§7.1 Lv100 解锁）─────────────
  static const String mainMenuExpedition = '江湖远行';
  static const String mainMenuExpeditionHint = '整队远征百草岭 · 挂机采药历练';
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
      '剩余 ${durationHoursMinutes(remainingMinutes ~/ 60, remainingMinutes % 60)}，可查看';
  static String seclusionMapActiveBannerRemaining(String remaining) =>
      '$seclusionMapActive · 剩余 $remaining';
  static String seclusionMapActiveBannerDone() => '$activeRetreatDone · 可收功';
  static String seclusionMapActiveElapsedHint(String elapsed) =>
      '已闭关 $elapsed 小时，可随时查看或收功';

  static const String seclusionSetupTitle = '闭关安排';
  static const String seclusionSetupStartButton = '开始闭关';
  static const String seclusionOpenEndedTitle = '此行不设归期';
  static String seclusionOpenEndedRule(int fullRateHours) =>
      '开始后将持续修炼，由你上线后主动收功。前 $fullRateHours 小时按当前地图完整结算。';
  static String seclusionOpenEndedOverflowRule(
    int intervalHours,
    int maxRolls,
  ) => '之后的时间继续累积普通挂机收益，不设上限。每满 $intervalHours 小时获得一次装备判定，最多 $maxRolls 次。';
  static String seclusionHourlyPreview(double materialScale, double expScale) =>
      '每小时预估产出（材料境界加成 ×${materialScale.toStringAsFixed(2)} · '
      '经验 ×${expScale.toStringAsFixed(2)}）';
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
      '$start → $end（$hours 小时）';
  static const String activeRetreatStatusCardTitle = '闭关状态';
  static String activeRetreatStatusLocation(String mapName) => '地点：$mapName';
  static String activeRetreatElapsed(String elapsed) => '已闭关：$elapsed';
  static String activeRetreatStartedAt(String start) => '入定于 $start';
  static String activeRetreatFullRateProgress(String hours, int cap) =>
      '地图收益：$hours / $cap 小时';
  static const String activeRetreatFullRateComplete = '地图收益已圆满';
  static String activeRetreatPassiveOverflow(String hours) =>
      '普通挂机接续：$hours 小时';
  static String activeRetreatEquipmentRolls(int count, int max) =>
      '装备机缘：$count / $max 次';
  static String activeRetreatNextEquipmentNode(String hours) =>
      '距下次装备判定：$hours 小时';
  static String activeRetreatGuaranteedPreview(
    int mojianshi,
    int silver,
    int experience,
  ) => '当前必得：磨剑石 $mojianshi · 银两 $silver · 修为经验 $experience';
  static String activeRetreatTierWeights(
    int hour,
    int base,
    int current,
    int above1,
    int above2,
  ) => '$hour 小时节点品阶：基准 $base% · 当前 $current% · +1 $above1% · +2 $above2%';
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
  static const String activeRetreatConfirmTitle = '确认收功';
  static const String activeRetreatConfirmBody = '现在收功将按实际时间结算，是否确认？';
  static const String activeRetreatConfirm = '确认';
  static const String activeRetreatCancel = '取消';

  static const String seclusionResultTitle = '闭关收获';
  static const String seclusionResultReportTitle = '收功战报';
  static const String seclusionResultRetreatSection = '地图闭关收益';
  static const String seclusionResultPassiveSection = '普通挂机接续';
  static String seclusionResultPhaseHours(String hours) => '结算 $hours 小时';
  static String seclusionEquipmentNode(int hour, String name) =>
      '$hour 小时机缘 · $name';
  static String equipmentLockedUntilRealm(String realmName) =>
      '需达 $realmName 境界方可装备';
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
      '$key：${perHour.toStringAsFixed(1)} / 小时';
  static String seclusionMapEventHour(double h) =>
      '第 ${h.toStringAsFixed(0)} 小时';
  static const String seclusionMapEventHarvest = '偶得';
  static const String seclusionMapEventRisk = '险兆';
  static const String seclusionMapEventTrace = '见闻';

  // ── P1 #42 Phase 4 · BaikeScreen 江湖见闻录(GDD §10.2 第 3 方式)──

  static const String mainMenuBaike = '江湖见闻录';
  static const String mainMenuBaikeHint = '记事与典故,永久可查';

  // ── 二阶段 §11.1 江湖纪事一级 Hub ──
  static const String mainMenuJianghuChronicle = '江湖纪事';
  static const String mainMenuJianghuChronicleHint = '卷轴、人物、地点与未了江湖事';
  static const String jianghuChronicleTitle = '江湖纪事';
  static const String jianghuChronicleSectionTitle = '江湖留痕';
  static const String jianghuChronicleSubtitle = '旧事可翻，已行之地可查，未了之事仍从原处续接。';
  static const String jianghuChronicleChapters = '章节卷轴';
  static const String jianghuChronicleChaptersHint = '按章节回看已开放的关前关后文字';
  static const String jianghuChronicleCharacters = '人物';
  static const String jianghuChronicleCharactersHint = '查看祖师、门人与历代传承';
  static const String jianghuChronicleLocations = '地点';
  static const String jianghuChronicleLocationsHint = '只记录已踏足或当前可达之地';
  static const String jianghuChronicleEnemies = '敌手';
  static const String jianghuChronicleEnemiesHint = '回看已经留下战绩的首领';
  static const String jianghuChronicleEquipmentLore = '装备典故';
  static const String jianghuChronicleEquipmentLoreHint = '按阶查阅器物与既有典故';
  static const String jianghuChroniclePendingAffairs = '待处理江湖事';
  static const String jianghuChroniclePendingAffairsHint = '续接结算后尚未完成的抉择与招降';
  static const String jianghuChronicleLocationCleared = '已踏足';
  static const String jianghuChronicleLocationAvailable = '可前往';
  static const String jianghuChronicleLocationsEmpty = '尚未留下可查的行迹';
  static const String jianghuChronicleLocationsUnavailable = '主线行迹暂不可读取';
  static const String pendingJianghuAffairsTitle = '未了之事';
  static const String pendingJianghuAffairsEmpty = '眼下没有待处理的江湖事';
  static const String pendingJianghuAffairsUnavailable = '待处理事项暂不可读取';
  static String pendingJianghuAffairsSource(String stageName) =>
      '起于：$stageName';
  static const String pendingJianghuAffairEncounterChoice = '奇遇抉择';
  static const String pendingJianghuAffairBossRecruit = '首领招降';
  static const String pendingJianghuAffairsResume = '继续处理';
  static const String pendingJianghuAffairsResumeHint = '返回原结算流程，按既有顺序逐项处理';

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
  // 顶栏导航动作。
  static const String titleBarBack = '返回';
  static const String titleBarHome = '回主菜单';
  // 设置「关于」:版本号(L2 · 与 pubspec.yaml version 手动同步)。
  static const String settingsAbout = '关于';
  static const String appVersion = '0.1.0';
  static String settingsVersionValue(String v) => '挂机武侠 · v$v';
  // 战斗交互重做 Phase 3:全局战斗模式默认开关(自动连续播放 / 允许拖招干预)。
  static const String settingsAutoPlayDefault = '自动战斗';
  static const String settingsAutoPlayDefaultHint = '战斗自动连续播放(可逐关切「允许点选」干预)';
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
  static const String saveManagementSelectBackupTitle = '选择历史备份';
  static const String saveManagementRestoreConfirmTitle = '确认恢复存档';
  static const String saveManagementRestoreConfirmAction = '恢复并关闭游戏';
  static const String saveManagementRestoringTitle = '正在恢复存档';
  static const String saveManagementRestoringMessage = '正在校验备份并保存当前进度，请勿关闭游戏。';
  static const String saveManagementRestoreSucceededTitle = '存档恢复完成';
  static const String saveManagementRestoreFailedTitle = '无法恢复此备份';
  static const String saveManagementRestoreRestartRequiredTitle = '恢复未能完成';
  static const String saveManagementCloseGame = '关闭游戏';
  static const String saveManagementAcknowledge = '知道了';
  static const String saveManagementDeleteConfirmTitle = '删除备份';
  static const String saveManagementDeleteConfirmAction = '删除备份';
  static String saveManagementSummary(
    int slotId,
    String saveVersion,
    int backupCount,
  ) => '槽位 $slotId · 版本 $saveVersion · $backupCount 个备份';
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
  static String saveManagementBackupDetail(DateTime createdAt, int sizeBytes) =>
      '${saveManagementDateTime(createdAt)} · ${(sizeBytes / 1024).ceil()} KB';
  static String saveManagementRestoreConfirmMessage(String fileName) =>
      '将恢复：$fileName\n\n当前进度会先自动备份。恢复完成后游戏将关闭，请重新打开。';
  static String saveManagementRestoreSucceededMessage(String safetyFileName) =>
      '历史存档已经恢复。恢复前的当前进度已另存为：\n$safetyFileName\n\n请关闭并重新打开游戏。';
  static const String saveManagementRestoreFailedMessage = '备份未通过校验，当前存档没有改变。';
  static const String saveManagementRestoreRestartRequiredMessage =
      '数据库已经关闭。恢复前存档仍有安全备份，请关闭并重新打开游戏。';

  // ── 多存档槽(spec B 选择/新开/删除/切换)────────────────────────────
  static const String slotSelectTitle = '选择江湖';
  static const String slotSaveEmpty = '空 · 新开江湖';
  static const String slotNewGameTitle = '新开江湖';
  static const String slotNewGameConfirm = '在此卷开启一段全新的江湖路？';
  static const String slotQuickStartAvailable = '已解锁老江湖开局';
  static const String slotDelete = '删除存档';
  static const String slotDeleteConfirm = '删除此存档？此举不可挽回。';
  static const String slotDeleteProtectionHint = '输入下方存档名后才可删除';
  static const String slotDeleteInputLabel = '存档名';
  static const String slotDeleteRiskNotice = '将永久删除本卷全部角色、装备、心法、进度与离线记录。';
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
  static const String founderCreateStartModeSection = '开局方式';
  static const String founderCreateGuidedMode = '循序入门';
  static const String founderCreateQuickMode = '老江湖开局';
  static const String founderCreateGuidedModeHint = '按主线逐步开放心法与闭关';
  static const String founderCreateQuickModeHint = '立即开放心法与闭关，主线与奖励仍从头开始';
  static const String founderCreateSchoolSection = '一 · 定流派';
  static const String founderCreateOriginSection = '二 · 问出身';
  static const String founderCreateFateSection = '三 · 观命盘';
  static const String founderCreatePreviewSection = '资质预览';
  static const String founderCreateConfirm = '立派入世';
  static const String founderCreateBack = '返回存档';
  static const String founderCreateNameSection = '四 · 立名号';
  static const String founderCreateFounderNameLabel = '祖师名';
  static const String founderCreateSectNameLabel = '门派名';
  static const String founderCreateRollName = '掷个名号';
  static const String founderCreateFounderNameHint = '留空则称「祖师」';
  static const String founderCreateSectNameHint = '留空则称「我的门派」';
  static const String founderCreateNoConfig = '祖师创建配置未加载';
  static const String founderCreateSelected = '已选';
  static const String founderCreateStartingTechnique = '起手心法';
  static const String founderCreateStartingEquipment = '起手装备';
  static const String founderCreateStartingResource = '起手资源';
  static const String founderCreateGoalHint = '开局建议';
  static const String founderCreateFateFocus = '命盘侧重';
  static String founderCreateAttributeTotal(int total) => '总点 $total';
  static String founderCreateTechniqueName(String name) => '主修「$name」';
  static String founderCreateEquipmentNames(List<String> names) =>
      names.join(' / ');
  static const String founderCreateReversibleHint =
      '起手选择只影响开局手感,日后可用装备、修炼补足,不必纠结。';
  static String founderCreateConfirmLine(
    String school,
    String origin,
    String fate,
  ) => '$school · $origin · $fate';
  static const String founderStarterGearDialogTitle = '开局行装';
  static const String founderStarterGearDialogIntro = '门中旧匣启封，获得三件基础装备：';
  static const String founderStarterGearEquippedHint = '已收入装备仓库，并为祖师穿戴。';
  static const String founderStarterGearConfirm = '收下';
  static const String founderCreateAttrConstitutionHint = '影响最大生命与新受重伤时长';
  static const String founderCreateAttrEnlightenmentHint = '影响修炼速度与武学领悟';
  static const String founderCreateAttrAgilityHint = '影响速度与闪避';
  static const String founderCreateAttrFortuneHint = '影响普通奇遇与特殊选择';
  static String founderCreationDeeds(
    String generationText,
    String school,
    String origin,
    String fate,
    String originLine,
  ) => '$generationText · $school · $origin · $fate\n$originLine';
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
  static const String towerCycleReadyHint = '已通 49 层，可挑战下一轮回';

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
  static const String skillCodexMultiplier = '威力';
  static const String skillCodexCost = '真气';
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

  /// GameEvent occurredAt 相对时间格式。
  ///
  /// 阈值:
  /// - < 5 分钟:"刚才"
  /// - 5-59 分钟:"$N 分钟前"
  /// - 1-23 小时:"$N 小时前"
  /// - 同一日:"今日 HH:MM"
  /// - 1 日前:"昨日 HH:MM"
  /// - 2-6 日前:"$N 日前"
  /// - > 7 日:"MM-DD"
  static String gameEventRelativeTime(DateTime occurredAt, DateTime now) {
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
  ) => '$charName 于「$mapName」闭关 $actualHours 小时，今晨收功。';

  // #2 adventureTriggered
  static String gameEventAdventureSummary(String encounterTitle) =>
      '江湖偶遇：$encounterTitle。';

  // #3 equipmentObtained
  static String gameEventEquipmentTitle(String equipName) => '得 $equipName';
  static String gameEventEquipmentSummary(String equipName, String source) =>
      '于「$source」得 $equipName，藏入囊中。';

  // #4 techniqueLearned
  static String gameEventTechniqueTitle(String techniqueName) =>
      '习得「$techniqueName」';
  static String gameEventTechniqueSummary(String techniqueName) =>
      '静心参悟，习得心法「$techniqueName」。';

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
  static String stageBossRecruitFallbackTitle(String stageName) =>
      '$stageName · 招降';
  static String stageBossRecruitSuccess(String name) =>
      '$name 折服于你的剑下,入门派任 [初入] 阶';
  static String stageBossRecruitCapFull(String name) => '门派人数已满,$name 婉言告别';
  static String stageBossRecruitNoSect(String name) => '尚未建派,$name 不知归处';

  // 1.1 战败收降 SnackBar(stageBossFailRecoverProb 0.30 · 沿 stageBossRecruit 体例)
  static String stageBossFailRecoverFallbackTitle(String stageName) =>
      '$stageName · 收降';
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
  static String encounterSkillEquipFailed(Object _) => '装备失败，请稍后重试';
  static String encounterSkillUnequipFailed(Object _) => '卸下失败，请稍后重试';
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
      '境界不足：需第 $requiredTier 阶，当前 $current';
  static String encounterSkillEquipFailedReason(String reason) =>
      '装备失败：$reason';

  /// `equipEncounterSkill` 的失败原因(经上面的 [encounterSkillEquipFailedReason]
  /// 呈现给玩家,故不是纯诊断串)。
  static String encounterSkillNotEncounterSkill(String _) => '此招并非奇遇武学，无法装配';
  static const String encounterSkillEquipUninitialized = '未初始化';
  static String encounterSkillCharacterMissing(int _) => '角色资料暂不可用';
  static String encounterSkillDefMissing(String _) => '招式资料暂不可用';

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
  static String encounterFortuneRequirement(int required) => '机缘 $required';
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
  static const String cangjingGrowthLocked = '心法火候未到,此招尚不可用';
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
      '冷却 -$turns拍';
  static String cangjingProficiencyInterruptPower(int pct) => '破招减防 +$pct%';
  static String cangjingProficiencyInterruptWindow(int turns) => '破绽 +$turns拍';
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
  static String mainMenuRetreatBannerLine(
    String mapName,
    String elapsedHours,
    String phase,
  ) => '闭关中 · $mapName · 已 $elapsedHours 小时 · $phase';
  static String mainMenuRetreatFullRatePhase(String hours, int cap) =>
      '地图收益 $hours/$cap';
  static String mainMenuRetreatPassivePhase(String hours) =>
      '地图圆满 · 挂机接续 $hours 小时';

  /// 剩余时长格式:有小时显「N 小时 M 分」,否则「M 分」
  static String retreatRemainingText(int hours, int minutes) =>
      durationHoursMinutes(hours, minutes);

  /// 出战锁弹窗(闭关进行中点战斗入口)
  static const String seclusionBattleLockTitle = '闭关修行中';
  static const String seclusionBattleLockBody = '正自闭关参修,心神内守,此刻不宜出战。';
  static const String seclusionBattleLockStay = '静心继续';
  static const String seclusionBattleLockEndEarly = '前去收功';

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
  static String offlineRecapMapCapped(String mapName) => '「$mapName」地图收益已圆满';

  /// 真实时长紧凑写法:整小时不显示多余小数(168.0 → 168),非整数保留一位。
  /// 与 offlineRecapAwayLine 的整数口径对齐,避免同一张归来卡里出现
  /// 「240 小时」与「168.0 小时」两种格式(2026-07-26 合并后视觉抽查发现)。
  static String compactHours(double hours) {
    final rounded = double.parse(hours.toStringAsFixed(1));
    if (rounded == rounded.roundToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toStringAsFixed(1);
  }

  static String offlineRecapPassiveContinues(String hours) =>
      '超出时间已按普通挂机接续 $hours 小时';

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

  static const String offlineRecapLimitInProgress = '地图收益仍在积累';
  static const String offlineRecapLimitSystemCap = '地图收益已圆满，普通挂机继续';

  /// 前去收功按钮
  static const String offlineRecapGoCollect = '前去收功';

  /// 稍后再说按钮（关闭卡片）
  static const String offlineRecapDismiss = '稍后再说';

  // ── M2 范围 B 被动离线告知卡(2026-06-15)──────────────────────────
  /// 被动卡标题（非闭关期间亦有精进）
  static const String passiveRecapTitle = '闭关之外，亦有精进';

  /// 被动卡正文（含离开时长 / 磨剑石 / 修为三项产出）
  // 单位为「小时」：hours 传入即小时数，与 offlineRecapAwayLine / 总览「游历时长」
  // 统一（旧文案误写「时辰」，1 时辰=2 小时，与同卡总览的小时数矛盾，2026-07-06 修）。
  static String passiveRecapBody(int hours, int moji, int exp) =>
      '离去约 $hours 小时。这些时日你未曾松懈，行功走架之间，'
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

  /// 主线 Boss 事实损失弹层确认动作。
  static const String mainlineDefeatLossAcknowledge = '知道了';

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

  /// 心魔失败摘要状态段：`内息紊乱`
  static const String innerDemonResidueNote = '内息紊乱';

  // ── 双层伤势 UI（第八阶段 Task 9）──────────────────────────────────────────
  /// 内息紊乱状态标签。
  static const String conditionInnerDemonResidueLabel = '内息紊乱';

  /// 心魔余毒来源提示。
  static const String conditionInnerDemonResidueSource = '来源：战败、散功或心魔反噬';

  /// 心魔余毒持续影响提示。
  static String conditionInnerDemonResidueEffect({
    required int battleOutputPenaltyPct,
    required int internalForceRecoveryPenaltyPct,
  }) => '影响：战斗有效内力与开场真气暂时降低';

  /// 心魔余毒清解提示。
  static String conditionInnerDemonResidueRecovery(double hours) =>
      '调息：闭关或离线 ${hours.ceil()} 小时，或完成有效战斗';
  static String conditionInnerBreathEffective({
    required int actual,
    required int effective,
  }) => '内力：$actual · 当前有效 $effective';

  /// 轻伤状态标签：`带伤`（含层数时由调用方拼接，如 `带伤×3`）。
  static const String injuryLightLabel = '带伤';

  /// 重伤状态标签：`重伤`。
  static String get injuryHeavyLabel => combatTermLabel(CombatTerm.heavyInjury);

  /// 重伤疗养剩余提示，小时向上取整。
  static String injuryRecoveryHint(double hours) =>
      '内伤未愈 · 调息 ${hours.ceil()} 小时';

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
  static const String skillTreasureManualHint = '首领真解入卷，可入藏经阁研习。';
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
  static String battleRecordTurns(int t) => '$t 拍';
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
  static const String weaponCodexDetailSpecialSkills = '开锋候选';
  static String weaponCodexDetailSpecialSkillsCount(int count) => '$count 式';
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
  static const String taohuaIslandOverviewTitle = '岛务概览';
  static const String taohuaIslandOverviewBody = '先看三项：可收物产、加工成品、伤员疗养。';
  static const String taohuaIslandSceneCave = '洞府';
  static const String taohuaIslandSceneCaveBody = '疗伤与调息';
  static const String taohuaIslandSceneField = '药圃';
  static const String taohuaIslandSceneFieldBody = '原料自然积蓄';
  static const String taohuaIslandSceneWorkshop = '炉坊';
  static const String taohuaIslandSceneWorkshopBody = '配方加工成品';
  static const String taohuaIslandSceneDock = '渡口';
  static const String taohuaIslandSceneDockBody = '外出工程预留';
  static const String taohuaIslandSceneDutyTitle = '分区职能';
  static const String taohuaIslandSceneMapTitle = '岛屿场景';
  static String taohuaIslandSceneMapSummary(
    int rawStored,
    int workshopStored,
  ) => '物产 $rawStored · 成品 $workshopStored';
  static String taohuaIslandSceneHotspotMeta(int level, int stored) =>
      'Lv$level · $stored';
  static const String taohuaIslandSceneProgressLabel = '产出进度';
  static const String taohuaIslandSceneFullShort = '仓储已满';
  static const String taohuaIslandScenePausedShort = '暂停';
  static String taohuaIslandSelectedBuildingTitle(String buildingName) =>
      '$buildingName详情';
  static const String taohuaIslandSelectedBuildingBody = '仓储、配方与修缮俱归此处。';

  /// 桃花岛总览状态摘要。
  static const String taohuaIslandStatusRawTitle = '可收物产';
  static String taohuaIslandStatusRawValue(int stored) => '可收 $stored 件';
  static const String taohuaIslandStatusWorkshopTitle = '成品加工';
  static String taohuaIslandStatusWorkshopValue(
    int stored,
    int active,
    int paused,
  ) => paused > 0
      ? '成品 $stored · $active 动 $paused 停'
      : '成品 $stored · $active 坊运转';
  static const String taohuaIslandStatusHealingTitle = '伤员疗养';
  static const String taohuaIslandStatusHealingNone = '无人重伤';
  static String taohuaIslandStatusHealingValue(int count, double hours) =>
      '$count 名调息 · 余 ${hours.ceil()} 小时';

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
  static const String semanticSelected = '已选中';

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
    return '$roundedHours 小时';
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
  static const String sweepTowerButton = '一键扫荡 49 层';

  /// 扫荡开跑前的本次战术选择。不写存档，不改变角色装配与结算规则。
  static const String botTacticSelectionTitle = '选择自动战术';
  static const String botTacticSelectionHint = '本次扫荡沿用同一角色装配与同核规则，只改变出手取舍。';
  static const String botTacticSeekGap = '寻隙';
  static const String botTacticSeekGapHint = '保留资源，等待破绽再出手。';
  static const String botTacticAssault = '强攻';
  static const String botTacticAssaultHint = '优先聚怪、爆发与追击。';
  static const String botTacticSteadyGuard = '稳守';
  static const String botTacticSteadyGuardHint = '优先打断与保守出手。';

  /// 未达门槛时的灰显提示（需本周目通关全部关卡）。
  static const String sweepLockedHint = '需本周目通关全部关卡后解锁';

  /// 周目徽章（按钮后缀 / recap / HUD 共用）。
  static String sweepCycleBadge(int cycle) => '第 $cycle 周目';

  /// 主线章节扫荡按钮（带周目）。
  static String sweepChapterButtonCycle(int cycle) =>
      '$sweepChapterButton · ${sweepCycleBadge(cycle)}';

  static const String sweepReadinessLoading = '战备校验中';
  static String sweepReadinessLoadingWithCost(int cost) =>
      '$sweepReadinessLoading · 本章消耗 $cost';
  static const String sweepReadinessUnavailable = '战备暂不可用';
  static const String sweepReadinessInsufficientButton = '战备不足，暂缓扫荡';
  static const String sweepReadinessPanelTitle = '扫荡战备';
  static const String sweepReadinessPanelBody =
      '只限制已通关主线的重复扫荡；首通、普通战斗与离线收益不消耗战备';
  static const String sweepReadinessFull = '战备已满';

  static String sweepReadinessShort(int current, int max) =>
      '战备 $current / $max';

  static String sweepReadinessLine({
    required int current,
    required int max,
    required int chapterCost,
  }) => '战备 $current / $max · 本章消耗 $chapterCost';

  static String sweepReadinessMissing(int missing) => '还需 $missing 点';

  static String sweepReadinessNextRecoveryMinutes(int minutes) =>
      '下点恢复约 $minutes 分钟';

  /// 爬塔轮回徽章。爬塔循环按 docs/UI_TERMINOLOGY.md 用「轮回」,不与主线
  /// 「周目」混用(2026-07-26 合并后视觉抽查:扫荡按钮曾与同屏「第1轮回」矛盾)。
  static String sweepTowerCycleBadge(int cycle) => '第 $cycle 轮回';

  /// 爬塔扫荡按钮（带轮回）。
  static String sweepTowerButtonCycle(int cycle) =>
      '$sweepTowerButton · ${sweepTowerCycleBadge(cycle)}';

  /// 爬塔未达门槛灰显提示（带轮回·§5.7 先手工通关该轮回全部层）。
  static String sweepTowerLockedHintCycle(int cycle) =>
      '${sweepTowerCycleBadge(cycle)}需先手工通关全部关卡';

  /// 爬塔 recap 行：本次扫荡的轮回。
  static String sweepTowerRecapCycle(int cycle) =>
      '扫荡 · ${sweepTowerCycleBadge(cycle)}';

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

  /// 无头模拟达到预算仍未分胜负。
  static String sweepRecapTimedOut(int floorIndex) => '扫到第 $floorIndex 关未分胜负';

  static const String sweepTimeoutReason = '本关达到演算时限，未结算胜负与收益';

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
  static const String sweepTowerRepeatNote = '爬塔重打仅掉招式残页，不掉装备 / 银两';

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
  static const String redlineNotePlayerHp =
      '使用全境界满 build + founder buff 极值探针，走 CharacterDerivedStats.maxHp。';
  static const String redlineNoteBossHp =
      '扫描主线和爬塔 Boss 配置 baseHp；周目 clamp 仍由既有 battle/setup 测试兜底。';
  static const String redlineNoteInternalForce =
      '使用全境界满 build + founder buff 极值探针，走 CharacterDerivedStats.internalForceMaxWithLineage。';
  static const String redlineNoteSkillMultiplier =
      '扫描 skills.yaml 与 encounter_skills.yaml 合并后的 skillDefs 全池。';
  static String redlineNoteNormalDamage(int typicalTarget) =>
      '软红线：典型目标 $typicalTarget，满 build 极值可越过；唯一硬线是不进百万。';
  static const String redlineNoteUltimateCrit =
      '软红线：使用当前最高 ultimate 倍率和满 build calculator 暴击探针；Phase 0A 真实路径现仅覆盖 Ch1 起手画像，满 build 真实路径极值待补。';

  // ── 材料来源反查一期（MaterialSourceSheet · 夜间批 L 2026-07-05）──────────
  static const String materialSourceSheetSourcesTitle = '来源';
  static const String materialSourceSheetUsagesTitle = '用途';
  static const String materialSourceSheetEmptySources = '来源未明，且待日后探寻。';
  static const String materialSourceSheetEmptyUsages = '暂无既定用途。';
  static String materialSourceSheetOwned(int qty) => '当前持有 ×$qty';

  /// 来源行：`来源类别 · 具体明细`；无明细时只显类别。
  static String materialSourceLine(String kindLabel, String? detail) =>
      (detail == null || detail.isEmpty) ? kindLabel : '$kindLabel · $detail';
  static String materialSourceMainlineDetail(
    int chapterIndex,
    String stageName,
  ) => '第$chapterIndex章 $stageName';
  static String materialSourceTowerDetail(int floorIndex) => '第$floorIndex层';
  static const String materialSourceBossSuffix = '（首领）';

  /// 分解确认弹窗返还材料旁的小来源按钮：`磨剑石来源`。
  static String materialSourceLinkNamed(String name) => '$name来源';

  // ── 百草岭远征 · 返程行记（§4.7 · Phase B2.4）────────────────────────
  static const String expeditionRecapTitle = '返程行记';
  static const String expeditionRecapReturnedTitle = '百草岭远征 · 归';
  static const String expeditionRecapDefeatedTitle = '败走百草岭';
  static String expeditionRecapDeepest(int node) => '最深抵达第 $node 处险境';
  static const String expeditionRecapResultSection = '此行战果';
  static String expeditionRecapCompletedNodes(int node) => '踏平节点 $node 处';
  static const String expeditionRecapRewardSection = '主要奖获';
  static const String expeditionRecapNoReward = '未及采获，空手而归。';
  static String expeditionRecapExp(int amount) => '修为 +$amount';
  static String expeditionRecapRewardItem(String name, int qty) =>
      '$name ×$qty';
  static String expeditionRecapTicket(int count) => '断魂帖 ×$count';
  static const String expeditionRecapInjurySection = '伤势';
  static String expeditionRecapDefeatedInjury(int downed) =>
      '力战不敌，$downed 人重伤而返，需静养多时。';
  static String expeditionRecapDownedInjury(int downed) =>
      '$downed 人力竭负伤，回山调息即可。';
  static const String expeditionRecapSafeReturn = '全员安然归返，毫发无伤。';
  static const String expeditionRecapBack = '返回';

  // ── 百草岭远征 · 江湖远行总览（§7.1 · Phase B2.4）────────────────────
  static const String expeditionOverviewTitle = '江湖远行';
  static const String expeditionBaicaoName = '百草岭';
  static const String expeditionBaicaoSubtitle = '整队远征，深入无尽药径';
  // 派遣态
  static const String expeditionDispatchTeamSection = '择人出征';
  static const String expeditionDispatchTeamHint = '选 1 名门人独行；祖师坐镇门中，不亲赴远征。';
  static const String expeditionDispatchPolicySection = '出发方针';
  static const String expeditionDispatchButton = '拔营出发';
  static String expeditionSelectedCountWithMax(int n, int max) =>
      '已择 $n / $max 人';
  static const String expeditionCandidateOccupiedTag = '在外';
  static const String expeditionCandidateNoMainTag = '未修主修';
  static const String expeditionNoCandidates = '暂无可出征门人。招收弟子、研习主修之后再来。';
  static const String expeditionDispatchFailed = '出征受阻，稍后再试。';
  // active 态
  static const String expeditionActiveSection = '远征在途';
  static String expeditionActiveDepth(int node) => '当前深入第 $node 处险境';
  static String expeditionActiveCompleted(int node) => '已踏平 $node 处节点';
  static const String expeditionActivePolicyLabel = '本次方针';
  static String expeditionNextNodeIn(String remaining) => '下一处约 $remaining 后抵达';
  static const String expeditionNextNodeReady = '下一处将至……';
  static const String expeditionDefeatedBanner = '全队战败，滞留待归——召回后结算伤势返程。';
  static String expeditionRemainingText(int hours, int minutes) =>
      durationHoursMinutes(hours, minutes);
  static const String expeditionRecallButton = '召回队伍';
  static const String expeditionRecallConfirmTitle = '召回远征队伍';
  static const String expeditionRecallConfirmBody =
      '召回后本次远征结束：已踏平节点的奖励照常入账，当前未完成的节点作废。';
  static const String expeditionRecallConfirm = '召回';
  static const String expeditionRecallRacedSnack = '召回恰逢结算入账，队伍未动——请再试一次';

  // ── 断魂庄三关 · 装载 / 整备（§7.1/§7.2 · C2.5）──────────────────────
  static const String gauntletName = '断魂庄';

  /// 战败结算里成员名缺失时的兜底称谓。
  static const String gauntletMemberFallbackName = '门人';
  static const String gauntletSubtitle = '三关连战，一气呵成；持帖入庄，生死自负。';
  static const String gauntletLoadoutTitle = '断魂庄';
  // 顶部信息
  static String gauntletTicket(int n) => '断魂帖 · $n 张';
  static const String gauntletNoTicketHint = '尚无断魂帖，暂不可入庄。';
  static const String gauntletEnemiesSection = '庄中三关';
  static String gauntletStageOrdinal(int stage) => '第 $stage 关';
  static String gauntletRecommendedRealm(String realm) => '推荐境界 · $realm 上下';
  // 择人
  static const String gauntletTeamSection = '择人入庄';
  static const String gauntletTeamHint = '选 1 名弟子闯庄；祖师坐镇门中，不亲入庄。';
  static String gauntletSelectedCount(int n) => '已择 $n / 1 人';
  static const String gauntletCandidateOccupiedTag = '在外';
  static const String gauntletCandidateNoMainTag = '未修主修';
  static const String gauntletNoCandidates = '暂无可入庄弟子。招收弟子、研习主修之后再来。';
  // 补给装载
  static const String gauntletSupplySection = '整备补给';
  static String gauntletSupplyHint(int cap) => '至多携 $cap 份，庄内两次整备时用；未用者出庄原数奉还。';
  static String gauntletSupplyOwned(int n) => '库存 $n';
  static String gauntletSupplyBudget(int used, int cap) => '已装 $used / $cap 份';
  // 入庄
  static const String gauntletEnterButton = '持帖入庄';
  static const String gauntletEnterFailed = '入庄受阻，请核对队伍与补给。';
  // 断线续战（§5.6/§10 · C2.5 恢复分支）
  static const String gauntletResumeTitle = '庄局未了';
  static String gauntletResumeHint(int stage, String phase) =>
      '残局停在第 $stage 关 · $phase';
  static const String gauntletResumeButton = '续战';
  static const String gauntletResumeFailed = '续战受阻，稍后再试。';
  static const String gauntletResumeRefunded = '庄局配置有异，已退帖闭局。';
  static const String gauntletPhaseInBattle = '战事未决';
  static const String gauntletPhaseInterlude = '整备待战';
  static const String gauntletPhaseAwaitingReward = '待择战利';
  static const String gauntletPhaseSettled = '已了结';

  // 庄内整备（§7.2）
  static const String gauntletInterludeTitle = '庄内整备';
  static String gauntletInterludeSection(int stage) => '第 $stage 关 · 整备待战';
  static const String gauntletMemberSection = '当前队伍';
  static String gauntletMemberHp(int cur, int max) => '气血 $cur / $max';
  static String gauntletMemberQi(int cur, int max) => '真气 $cur / $max';
  static const String gauntletMemberDownedTag = '倒下';
  static String gauntletMemberCooldownTag(int n) => '$n 招冷却';
  static const String gauntletSupplyRemainSection = '随身补给';
  static String gauntletSupplyRemain(String name, int remaining) =>
      '$name · 余 $remaining 份';
  static const String gauntletSupplyUseButton = '使用';
  static const String gauntletSupplyExhausted = '已用尽';
  static const String gauntletNoInterludeSupply = '未携补给，径直闯关。';
  static const String gauntletHealTargetTitle = '择疗伤目标';
  static const String gauntletContinueButton = '继续闯关';
  static const String gauntletConcedeButton = '认输离庄';
  static const String gauntletConcedeConfirmTitle = '认输离庄';
  static const String gauntletConcedeConfirmBody =
      '认输即止步本次闯庄：已击败精英的经验照常入账，按实际战况结算轻重伤（不损永久内力）；'
      '断魂帖与已用补给不退还。';
  static const String gauntletConcedeConfirm = '认输离庄';

  // 通关三选一奖励（§6.2 · #1 wiring Task 2）
  static const String gauntletRewardTitle = '断魂庄 · 论功行赏';
  static const String gauntletRewardSection = '通庄战利 · 三选一';
  static const String gauntletRewardFirstClearBadge = '首通 · 全奖';
  static const String gauntletRewardRepeatBadge = '再通 · 减半';
  static const String gauntletRewardFirstClearHint =
      '首克庄门：择一件命名兵刃随身，另赠庄门秘籍、参战弟子经验与领悟点。';
  static const String gauntletRewardRepeatHint =
      '再克庄门：择一件命名兵刃随身；经验与领悟减半奉送，秘籍不再重赠。';
  static String gauntletRewardTierSlot(String tier, String slot) =>
      '$tier · $slot';
  static String gauntletRewardAtk(int min, int max) => '攻 $min–$max';
  static String gauntletRewardHp(int min, int max) => '血 $min–$max';
  static String gauntletRewardSpd(int min, int max) => '速 $min–$max';
  static const String gauntletRewardSelectHint = '点选择取';
  static const String gauntletRewardConfirmTitle = '择取战利';
  static String gauntletRewardConfirmBody(String name) =>
      '确认择取「$name」？三选一仅取其一，余者不留。';
  static const String gauntletRewardConfirm = '确认择取';
  static const String gauntletNoReward = '暂无待领战利，庄门未克。';

  // 战败结算（§6.3 · #1 wiring Task 3）
  static const String gauntletDefeatTitle = '断魂庄 · 铩羽';
  static const String gauntletDefeatSection = '闯庄失利';
  static const String gauntletDefeatHint =
      '止步于此。已破精英的经验照常入账，按战况结算轻重伤（不损永久内力）；'
      '断魂帖与已用补给不退。';
  static String gauntletDefeatEliteLine(int count, int exp) =>
      '已破 $count 关精英 · 各得经验 $exp';
  static const String gauntletDefeatNoElite = '未破一关精英，无经验入账。';
  static const String gauntletDefeatMemberSection = '弟子伤势';
  static const String gauntletDefeatHeavyTag = '重伤';
  static const String gauntletDefeatLightTag = '轻伤';
  static const String gauntletLeaveButton = '离庄';

  // 战斗驱动编排（#1 wiring Task 4）
  static const String gauntletSessionNotReady = '断魂庄会话未就绪';

  /// 正式界面的真实时长格式。整小时不补「0 分」，避免 `79h00min`
  /// 一类内部式缩写；叙事世界的「时辰」不走此方法。
  static String durationHoursMinutes(int hours, int minutes) {
    final safeHours = hours < 0 ? 0 : hours;
    final safeMinutes = minutes < 0 ? 0 : minutes;
    final totalMinutes = safeHours * 60 + safeMinutes;
    final normalizedHours = totalMinutes ~/ 60;
    final normalizedMinutes = totalMinutes % 60;
    if (normalizedHours <= 0) return '$normalizedMinutes 分';
    if (normalizedMinutes <= 0) return '$normalizedHours 小时';
    return '$normalizedHours 小时 $normalizedMinutes 分';
  }
}
