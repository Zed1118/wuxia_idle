/// 战斗舞台与武学案台的布局尺寸。
///
/// 视觉数值集中在此，避免案台后续换立绘/动作模板时在多个
/// widget 中散改魔法数。
abstract final class BattleLayoutTokens {
  static const double headerHeight = 48;
  static const double commandDeskHeight = 154;
  static const double commandDeskHorizontalPadding = 14;
  static const double commandDeskVerticalPadding = 9;
  static const double actorRailWidth = 166;
  static const double actorChipHeight = 34;
  static const double skillSlotHeight = 116;
  static const double skillSlotGap = 6;
  static const double sectionGap = 12;
  static const double sectionDividerHeight = 116;
  static const double pouchWidth = 184;
  static const double pouchSlotSize = 44;
  static const double pouchSlotGap = 6;
}
