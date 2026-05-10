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
}
