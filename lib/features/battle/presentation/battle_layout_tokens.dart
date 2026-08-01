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
  static const double commandDeskHorizontalPadding = 48;
  static const double commandDeskRightPadding = 51;
  static const double commandDeskVerticalPadding = 9;
  static const double focusRailFraction = 0.1585;
  static const double pouchRailFraction = 0.20;
  static const double actorChipHeight = 40;
  static const double skillSlotHeight = 150;
  static const double skillSlotGap = 28;
  static const double sampleSkillSlipTopInset = 2;
  static const double sampleSkillSlipHeightReduction = 2;
  static const double sampleStyleCompactSlotHeight = 162;
  static const double sampleStyleExpandedSlotHeight = 206;
  static const double focusDividerGap = 20;
  static const double dividerSkillGap = 32;
  static const double skillPouchGap = 31;
  static const List<int> sampleSkillFlex = [100, 120, 120, 100, 92, 94, 95];
  static const double sectionDividerHeight = 148;
  static const double pouchSlotSize = 92;
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
  static const double emptySkillPaperOpacity = 0.42;
}

/// 案台子组件共用的连续尺寸预算。
///
/// 名帖、技能签和行囊以前各自在 190px 做二元换皮，导致窗口
/// 只变 1px 就同时跳字号、间距和装饰。现在它们都从同一签位高度区间
/// 取 0～1 进度；样板材质不变，只连续压缩几何。
final class BattleDeskResponsiveStyle {
  const BattleDeskResponsiveStyle._(this.progress);

  factory BattleDeskResponsiveStyle.fromSlotHeight(double height) {
    final progress =
        ((height - BattleLayoutTokens.sampleStyleCompactSlotHeight) /
                (BattleLayoutTokens.sampleStyleExpandedSlotHeight -
                    BattleLayoutTokens.sampleStyleCompactSlotHeight))
            .clamp(0.0, 1.0)
            .toDouble();
    return BattleDeskResponsiveStyle._(progress);
  }

  factory BattleDeskResponsiveStyle.fromSlipHeight(double height) =>
      BattleDeskResponsiveStyle.fromSlotHeight(
        height + BattleLayoutTokens.sampleSkillSlipHeightReduction,
      );

  final double progress;

  double value(double compact, double expanded) =>
      lerpDouble(compact, expanded, progress)!;
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
      BattleLayoutTokens.commandDeskHorizontalPadding -
      BattleLayoutTokens.commandDeskRightPadding -
      BattleLayoutTokens.focusDividerGap -
      BattleLayoutTokens.dividerSkillGap -
      BattleLayoutTokens.skillPouchGap -
      1 -
      focusRailWidth -
      pouchRailWidth;
  double get sampleSkillSlotHeight =>
      (commandDeskHeight * 0.88).clamp(146.0, 206.0);
  double get sampleSkillSlipHeight =>
      sampleSkillSlotHeight - BattleLayoutTokens.sampleSkillSlipHeightReduction;
  BattleDeskResponsiveStyle get sampleDeskStyle =>
      BattleDeskResponsiveStyle.fromSlotHeight(sampleSkillSlotHeight);
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
