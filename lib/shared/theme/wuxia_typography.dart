import 'package:flutter/material.dart';

/// 全局 UI 的语义字阶。
///
/// 首批数值等值收拢自已获认可的共享组件，不改现有字号、字重或布局；后续页面
/// 迁移只按语义取值，避免继续散写相近魔数。战斗 HUD 的紧凑字阶仍由
/// `BattleTypography` 独立管理，不与普通页面强行合并。
abstract final class WuxiaTypography {
  static const double pageTitle = 19;
  static const double featureTitle = 22;
  static const double dialogTitle = 18;
  static const double emptyStateTitle = 17;
  static const double compactTitle = 15;
  static const double sectionTitle = 14;
  static const double body = 13;
  static const double supporting = 12;
  static const double metadata = 11;

  static const double pageTitleLetterSpacing = 6;
  static const double dialogTitleLetterSpacing = 4;
  static const double sectionTitleLetterSpacing = 2;
  static const double emptyTitleLetterSpacing = 1.8;
  static const double compactTitleLetterSpacing = 1.2;
  static const double supportingHeight = 1.35;

  static TextStyle pageTitleStyle(Color color) => TextStyle(
    color: color,
    fontSize: pageTitle,
    fontWeight: FontWeight.bold,
    letterSpacing: pageTitleLetterSpacing,
  );

  static TextStyle featureTitleStyle(Color color) => TextStyle(
    color: color,
    fontSize: featureTitle,
    fontWeight: FontWeight.w900,
    letterSpacing: sectionTitleLetterSpacing,
  );

  static TextStyle dialogTitleStyle(Color color) => TextStyle(
    color: color,
    fontSize: dialogTitle,
    fontWeight: FontWeight.bold,
    letterSpacing: dialogTitleLetterSpacing,
  );

  static TextStyle sectionTitleStyle(Color color) => TextStyle(
    color: color,
    fontSize: sectionTitle,
    fontWeight: FontWeight.bold,
    letterSpacing: sectionTitleLetterSpacing,
  );

  static TextStyle emptyTitleStyle(Color color, {required bool compact}) =>
      TextStyle(
        color: color,
        fontSize: compact ? compactTitle : emptyStateTitle,
        fontWeight: FontWeight.w800,
        letterSpacing: compact
            ? compactTitleLetterSpacing
            : emptyTitleLetterSpacing,
      );

  static TextStyle bodyStyle(Color color) =>
      TextStyle(color: color, fontSize: body);

  static TextStyle supportingStyle(Color color) =>
      TextStyle(color: color, fontSize: supporting, height: supportingHeight);

  static TextStyle statusStyle(Color color, {required bool dense}) => TextStyle(
    color: color,
    fontSize: dense ? metadata : supporting,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
}
