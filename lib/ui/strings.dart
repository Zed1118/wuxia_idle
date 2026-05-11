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
}
