import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';

/// 战斗 UI 颜色（phase1_tasks.md T14 §799）。
///
/// 流派色锁死 GDD §4.4：刚猛红 / 灵巧金 / 阴柔紫。
/// HP 色三段：> 50% 绿、25–50% 黄、< 25% 红（phase1_tasks T14 §797）。
class WuxiaColors {
  WuxiaColors._();

  static const Color gangMeng = Color(0xFFC23A2A);
  static const Color lingQiao = Color(0xFFD4A12C);
  static const Color yinRou = Color(0xFF8B5BB2);

  static const Color hpHigh = Color(0xFF2E8B57);
  static const Color hpMid = Color(0xFFC9A227);
  static const Color hpLow = Color(0xFFB22222);

  static const Color internalForce = Color(0xFF4682B4);

  static const Color background = Color(0xFF14181D);
  static const Color panel = Color(0xFF1B2128);
  static const Color sidebar = Color(0xFF181D23);
  static const Color border = Color(0xFF2F363D);
  static const Color barTrack = Color(0xFF3A3A3A);
  static const Color avatarFill = Color(0xFF1F1F1F);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFF8A93A0);
  static const Color resultHighlight = Color(0xFFE8C547);
  static const Color buttonDisabled = Color(0xFF3A3A3A);

  // 木牌入口(Phase A 出版美术):牌面上浅下深渐变 + 暖褐木边,替冷色卡片感。
  static const Color inkPanelTop = Color(0xFF232B33);
  static const Color inkPanelBottom = Color(0xFF161B21);
  static const Color inkPanelEdge = Color(0xFF4A4038);
  // 宣纸面板暖兜底(WuxiaPaperPanel):内容不满屏时空白区呈暖宣纸调,非冷黑。
  static const Color paperUnderlay = Color(0xFF241C13);

  // 伤害飘字色（T15）
  static const Color popupNormal = Color(0xFFFFFFFF); // 普通伤害：白
  static const Color popupCritical = Color(0xFFFFD700); // 暴击：金
  static const Color popupDodge = Color(0xFF9E9E9E); // 闪避：灰

  static Color schoolColor(TechniqueSchool s) => switch (s) {
    TechniqueSchool.gangMeng => gangMeng,
    TechniqueSchool.lingQiao => lingQiao,
    TechniqueSchool.yinRou => yinRou,
  };

  static Color hpColor(double ratio) {
    if (ratio > 0.5) return hpHigh;
    if (ratio > 0.25) return hpMid;
    return hpLow;
  }
}
