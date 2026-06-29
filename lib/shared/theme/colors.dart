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
  // 装备/仓库对比状态色：比 HP 红绿更克制，避免 UI 读成强告警。
  static const Color statIncrease = Color(0xFF79A889);
  static const Color statDecrease = Color(0xFFC27A70);
  static const Color statNeutral = Color(0xFF8A93A0);

  static const Color internalForce = Color(0xFF4682B4);

  static const Color background = Color(0xFF14181D);
  static const Color panel = Color(0xFF1B2128);
  static const Color sidebar = Color(0xFF181D23);
  static const Color border = Color(0xFF2F363D);
  static const Color barTrack = Color(0xFF3A3A3A);
  static const Color avatarFill = Color(0xFF1F1F1F);
  // ⚠️ 红线(2026-06-29):以下三个文字色是【深色 UI 专用浅灰】(white / #CCCCCC / #8A93A0),
  // 只在深底(battle / inkPanel / background 等)上可读。
  // 【禁用于浅宣纸底】(WuxiaUi.paper / panelFill / slotFill / WuxiaPaperPanel / PaperPanel /
  // PaperDialog / CeremonyImagePanel 浅 veil)——浅底浅字会糊成一片(已多次发生)。
  // 浅宣纸底的文字一律用墨色:正文/主标题 → WuxiaUi.ink,次要/副描述 → WuxiaUi.muted。
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFF8A93A0);
  static const Color resultHighlight = Color(0xFFE8C547);
  static const Color cycleHintText = Color(0xFFD4A800);
  // P2-3(2026-06-29 审查修复):战斗提示横幅色收入 token,替 battle_screen 散写魔数。
  static const Color hintBannerBg = Color(0xFF2A3A2A); // 通用提示条墨绿底
  static const Color hintBannerText = Color(0xFF8BC28B); // 通用提示条淡绿字
  static const Color cycleHintBg = Color(0xFF3A2E00); // 周目记招提示条暗琥珀底
  static const Color visualGoldShadow = Color(0x88B99A3B);
  static const Color treasureAuraInner = Color(0x00F0CC72);
  static const Color treasureAuraMid = Color(0x44F0CC72);
  static const Color treasureAuraEdge = Color(0xCCE8B84A);

  static const Color auditPass = Color(0xFF2E7D32);
  static const Color auditWarn = Color(0xFFB26A00);
  static const Color auditFail = Color(0xFF9D2F2F);

  /// 警示色（T2 蓄力危险条 / 敌方威胁提示）：绛红，与 hpLow 同调表"危险"。
  static const Color danger = Color(0xFFB22222);

  /// 出版美术 B2:Boss 头像专属金色描边(深金,区别于 resultHighlight 浅金 + 流派色)。
  static const Color bossFrame = Color(0xFFD4A017);

  /// 爆品印章专用深绛红(区别 gangMeng 刚猛红,落款庄重)。
  static const Color sealCrimson = Color(0xFF9E2B25);

  /// 战斗背景图上的压暗遮罩(出版美术 B1):保证偏亮背景不抢前景。
  static const Color battleSceneScrim = Color(0x66000000); // black 40%
  static const Color narrativeSceneScrim = Color(
    0x80000000,
  ); // black 50%(正文长文需更重压暗)

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
