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
}
