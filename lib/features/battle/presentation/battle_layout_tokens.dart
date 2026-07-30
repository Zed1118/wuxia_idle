import 'dart:ui';

/// 战斗舞台与武学案台的布局尺寸。
///
/// 视觉数值集中在此，避免案台后续换立绘/动作模板时在多个
/// widget 中散改魔法数。
abstract final class BattleLayoutTokens {
  static const double headerFraction = 0.065;
  static const double commandDeskFraction = 0.256;
  static const double headerMinHeight = 44;
  static const double headerMaxHeight = 60;
  static const double headerHorizontalPadding = 34;
  static const double headerRightPadding = 70;
  static const double headerSealMinWidth = 46;
  static const double headerSealHeight = 42;
  static const double headerSealGap = 10;
  static const double commandDeskMinHeight = 172;
  static const double commandDeskMaxHeight = 241;
  static const double commandDeskHorizontalPadding = 38;
  static const double commandDeskVerticalPadding = 9;
  static const double focusRailFraction = 0.16;
  static const double pouchRailFraction = 0.20;
  static const double actorChipHeight = 30;
  static const double skillSlotHeight = 150;
  static const double skillSlotGap = 22;
  static const double sectionGap = 22;
  static const double sectionDividerHeight = 148;
  static const double pouchSlotSize = 64;
  static const double pouchSlotGap = 8;
  static const double stageHorizontalPadding = 10;
  static const double stageVerticalPadding = 0;
  static const double stageMaxStandeeWidth = 282;
  static const double stageMaxStandeeHeight = 392;
  static const double stageWidthFraction = 0.19;
  static const double stageHeightFraction = 0.78;
  static const double bossStageScale = 1.16;
  static const double stageStatusHpHeight = 11;
  static const double stageStatusQiHeight = 10;
  static const double emptySkillPaperOpacity = 0.30;
  static const double emptySkillTextureOpacity = 0.10;
}

/// 同一视口下的战斗三段式布局量测。
///
/// 顶栏与案台以比例为主，极端窗口再由上下限守住点击区；战场吃掉精确余量，
/// 因而三段永远闭合，不由自动/点选模式各自决定高度。
final class BattleLayoutMetrics {
  const BattleLayoutMetrics._({
    required this.viewport,
    required this.headerHeight,
    required this.battlefieldHeight,
    required this.commandDeskHeight,
  });

  final Size viewport;
  final double headerHeight;
  final double battlefieldHeight;
  final double commandDeskHeight;

  double get autoRotationDeskHeight => commandDeskHeight;
  double get focusRailWidth =>
      viewport.width * BattleLayoutTokens.focusRailFraction;
  double get pouchRailWidth =>
      viewport.width * BattleLayoutTokens.pouchRailFraction;
  double get skillRailWidth =>
      viewport.width -
      BattleLayoutTokens.commandDeskHorizontalPadding * 2 -
      BattleLayoutTokens.sectionGap * 3 -
      1 -
      focusRailWidth -
      pouchRailWidth;
  double get sampleSkillSlotHeight =>
      (commandDeskHeight * 0.88).clamp(146.0, 200.0);
  double get sampleSectionDividerHeight =>
      (commandDeskHeight * 0.88).clamp(144.0, 200.0);
  double get stageTopSafetyInset =>
      ((800 - viewport.height) * 0.5).clamp(0.0, 40.0);

  static BattleLayoutMetrics resolve(Size viewport) {
    final headerHeight = (viewport.height * BattleLayoutTokens.headerFraction)
        .clamp(
          BattleLayoutTokens.headerMinHeight,
          BattleLayoutTokens.headerMaxHeight,
        )
        .toDouble();
    final commandDeskHeight =
        (viewport.height * BattleLayoutTokens.commandDeskFraction)
            .clamp(
              BattleLayoutTokens.commandDeskMinHeight,
              BattleLayoutTokens.commandDeskMaxHeight,
            )
            .toDouble();
    return BattleLayoutMetrics._(
      viewport: viewport,
      headerHeight: headerHeight,
      battlefieldHeight: viewport.height - headerHeight - commandDeskHeight,
      commandDeskHeight: commandDeskHeight,
    );
  }
}
