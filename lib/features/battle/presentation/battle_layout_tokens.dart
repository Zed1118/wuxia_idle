/// 战斗舞台与武学案台的布局尺寸。
///
/// 视觉数值集中在此，避免案台后续换立绘/动作模板时在多个
/// widget 中散改魔法数。
abstract final class BattleLayoutTokens {
  static const double headerHeight = 58;
  static const double commandDeskHeight = 188;
  static const double commandDeskHorizontalPadding = 28;
  static const double commandDeskVerticalPadding = 12;
  static const double actorRailWidth = 222;
  static const double actorChipHeight = 36;
  static const double skillSlotHeight = 150;
  static const double skillSlotGap = 8;
  static const double sectionGap = 16;
  static const double sectionDividerHeight = 148;
  static const double pouchWidth = 222;
  static const double pouchSlotSize = 54;
  static const double pouchSlotGap = 8;
  static const double stageHorizontalPadding = 10;
  static const double stageVerticalPadding = 0;
  static const double stageMaxStandeeWidth = 282;
  static const double stageMaxStandeeHeight = 392;
  static const double stageWidthFraction = 0.19;
  static const double stageHeightFraction = 0.78;
  static const double bossStageScale = 1.22;
}
