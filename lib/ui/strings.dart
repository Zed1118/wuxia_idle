/// UI 静态中文标签（phase1_tasks.md T14）。
///
/// 与 [lib/combat/enum_localizations.dart] 同性质：Phase 1 把"代码内中文"集中
/// 一处便于以后 i18n 迁出。enum_localizations 负责战斗调试日志，本文件负责 UI
/// 标签（标题 / 按钮 / 占位符等）。
///
/// 不收纳剧情 / 装备典故 / 奇遇文案（那些走 data/narratives, lore, events，
/// 由 DeepSeek 端维护）。
class UiStrings {
  UiStrings._();

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

  /// 战斗结算 dialog 内容：`总伤害 X  暴击 Y 次  用时 Z tick`。
  static String battleSummary(int totalDamage, int critCount, int totalTicks) =>
      '总伤害 $totalDamage    暴击 $critCount 次    用时 $totalTicks tick';

  // 主菜单（T32 子提交 3b）
  static const String mainMenuTitle = '挂机武侠 · 调试主菜单';
  static const String mainMenuPhase1 = 'Phase 1 战斗测试';
  static const String mainMenuPhase1Hint = '4 个 3v3 战斗场景（基础对决 / 流派克制 / 装备影响 / 境界差距）';
  static const String mainMenuPhase2 = 'Phase 2 调试场景';
  static const String mainMenuPhase2Hint = '4 个数据种子场景（强化曲线 / 共鸣触发 / 散功代价 / 全栈对比）';
  static const String mainMenuCharacterPanel = '角色面板';
  static const String mainMenuCharacterPanelHint = '查看角色属性 / 装备 / 心法';
  static const String mainMenuInventory = '装备仓库';
  static const String mainMenuInventoryHint = '查看 / 强化 / 开锋装备';
  static const String mainMenuTechniques = '心法面板';
  static const String mainMenuTechniquesHint = '查看主修 / 辅修 / 散功换主修';

  // Phase 2 调试场景（T32 子提交 3d）
  static const String phase2MenuTitle = 'Phase 2 调试场景';
  static const String scenarioP1 = 'P1 · 强化曲线';
  static const String scenarioP2 = 'P2 · 共鸣触发';
  static const String scenarioP3 = 'P3 · 散功代价';
  static const String scenarioP4 = 'P4 · 全栈对比';
  static const String hintP1 = '+0 利器 + 1000 磨剑石 / 100 结晶，连续强化看成功率分布';
  static const String hintP2 = 'battleCount=99 装备，下场战斗 →100 触发"趁手"+10%';
  static const String hintP3 = '主修 yuanMan/1500 + IF 10000，散功后 daCheng/750 + IF 5000';
  static const String hintP4 = '+0 强化到 +19 + 开锋 + 默契满，对比裸装伤害';

  // 调试菜单（T17）
  static const String testMenuTitle = '战斗测试场景';
  static const String scenarioA = 'A · 同境界基础对决';
  static const String scenarioB = 'B · 流派克制循环';
  static const String scenarioC = 'C · 装备影响伤害';
  static const String scenarioD = 'D · 境界差距碾压';
  static const String hintA = '观察点：基础伤害落在 2000-8000，节奏纯比速度';
  static const String hintB = '观察点：左队全面克制右队（×1.25 攻 / ×0.75 受），差距约 1.67 倍';
  static const String hintC = '观察点：纯武器攻击对比（IF=0），+12强化+默契 = ×1.92 基础攻，伤害约为裸装 1.9 倍';
  static const String hintD = '观察点：低境界（三流）打高境界（绝顶）守方修正 ×0.05，几乎打不动';

  // 角色面板（T28）
  static const String panelAttributes = '基础属性';
  static const String panelDerived = '派生数值';
  static const String panelEquipment = '装备';
  static const String panelTechnique = '心法';

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
  static String cultivationProgress(int current, int next) => '$current / $next';

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

  // 仓库 / 强化对话框（T29）
  static const String inventoryTitle = '装备仓库';
  static const String inventoryEmpty = '仓库空空如也';
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
  static String mojianshiUsage(int current, int cost) =>
      '磨剑石 $current / $cost';

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
  static const String forgingConfirmBody =
      '开锋一旦下手不能更改。确认在此槽位开锋？';
  static const String forgingConfirmOk = '确认';
  static const String forgingConfirmCancel = '取消';

  /// 槽位标题：`槽 1` / `槽 2` / `槽 3`。
  static String forgingSlotTitle(int slotIndex) => '槽 $slotIndex';

  /// 未解锁文案：`强化到 +N 解锁`。
  static String forgingUnlockHint(int unlockAtLevel) => '强化到 +$unlockAtLevel 解锁';

  /// 已开锋词条：`攻击 +15%`。
  static String forgingBonusLabel(String typeLabel, int bonus) =>
      '$typeLabel +$bonus%';

  // 心法面板 / 散功 dialog（T31）
  static const String techniquePanelTitle = '心法面板';
  static const String techniquePanelEmpty = '尚未学习任何心法';
  static const String setAsMainButton = '设为主修';
  static const String dispelDialogTitle = '散功换主修';
  static const String dispelLayerWarning = '修炼度层可能回退';
  static const String dispelConfirm = '确认散功';
  static const String dispelSuccess = '散功完成';

  /// 散功代价 · 内力：`内力 X → Y`。
  static String dispelCostInternalForce(int before, int after) =>
      '内力 $before → $after';

  /// 散功代价 · 修炼度:`修炼度 X → Y`。
  static String dispelCostCultivation(int before, int after) =>
      '修炼度 $before → $after';

  // ── Phase 3 主线（T35）──

  static const String mainMenuMainline = '主线';
  static const String mainMenuMainlineHint = '3 章 6 关，按章节顺序解锁';

  static const String chapterListTitle = '主线 · 章节';
  static const String chapter1Title = '第一章 · 学武出山';
  static const String chapter2Title = '第二章 · 武林初识';
  static const String chapter3Title = '第三章 · 名扬江湖';
  static const String chapter1Hint = '初出茅庐，山道试剑、林间伏击';
  static const String chapter2Hint = '镖局护送、黑风寨剿匪';
  static const String chapter3Hint = '武林会、一战封王';

  static const String chapterStatusLocked = '未解锁';
  static const String chapterStatusInProgress = '进行中';
  static const String chapterStatusCompleted = '已完成';

  static const String stageListLocked = '锁';
  static const String stageListAvailable = '可挑战';
  static const String stageListCleared = '✓ 已通关';
  static const String stageListPrevHint = '通关前一关解锁';
  static const String stageListEmpty = '该章暂无关卡';

  /// 章节标题路由：按 chapterIndex 返回对应中文标题。
  static String chapterTitle(int chapterIndex) {
    return switch (chapterIndex) {
      1 => chapter1Title,
      2 => chapter2Title,
      3 => chapter3Title,
      _ => '第 $chapterIndex 章',
    };
  }

  /// 章节简介路由。
  static String chapterHint(int chapterIndex) {
    return switch (chapterIndex) {
      1 => chapter1Hint,
      2 => chapter2Hint,
      3 => chapter3Hint,
      _ => '',
    };
  }

  // ── Phase 3 爬塔（T42）──

  static const String mainMenuTower = '问鼎九霄';
  static const String mainMenuTowerHint = '30 层，无限重试，永久记录';

  static const String towerTitle = '问鼎九霄';

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
}
