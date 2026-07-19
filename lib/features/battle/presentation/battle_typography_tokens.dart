import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// 战斗屏 T1～T5 字阶的单一真相源。
///
/// 回退链不依赖 macOS 独占字体；数字样式统一使用等宽数字，
/// 避免血量、真气与节拍变化时字面水平跳动。
class BattleTypography {
  BattleTypography._();

  static const double t1 = 24;
  static const double t2 = 17;
  static const double t3 = 14;
  static const double t4 = 11;
  static const double t5 = 9;

  static const String displayFamily = 'Songti SC';
  static const List<String> displayFallback = [
    'STSong',
    'SimSun',
    'Noto Serif CJK SC',
    'serif',
  ];
  static const List<String> uiFallback = [
    'PingFang SC',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
    'sans-serif',
  ];
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];
}
