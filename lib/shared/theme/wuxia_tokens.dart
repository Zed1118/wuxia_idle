import 'package:flutter/material.dart';

/// UI 包装改造方案 v1 母题 token（色/边/面/形/资产）。
///
/// 区别于 [WuxiaColors]（`colors.dart`，战斗 UI 深色调）：本类是「宣纸笺」包装层的
/// 浅色母题。9 组件 kit（`lib/shared/widgets/wuxia_ui/`）与后续逐页改造统一引用此处，
/// **禁散写魔数**。色值锚定 demo `docs/handoff/ui_mockup_v1/index.html` 的 :root CSS。
/// 红线：金线 [gold] 仅限高阶装帧（ItemSlot 高阶框 / 详情 hero），不滥用。
class WuxiaUi {
  WuxiaUi._();

  // —— 色 ——
  static const Color ink = Color(0xFF241F1A); // 墨黑（边/正文）
  static const Color ink2 = Color(0xFF3A332B);
  static const Color paper = Color(0xFFE9DCC0); // 宣纸黄（面）
  static const Color paper2 = Color(0xFFDDCAA3);
  static const Color qing = Color(0xFF566B63); // 青灰（内息/辅）
  static const Color jiang = Color(0xFF8A2B21); // 绛红（点缀/主行动）
  static const Color gold = Color(0xFFB08A47); // 金线（仅高阶装帧）
  static const Color muted = Color(0xFF7D7160); // 柔灰（次要文字）
  static const Color woodLight = Color(0xFF6E5532); // 木牌亮边
  static const Color woodDark = Color(0xFF4F3C22); // 木牌暗边

  // —— 面（宣纸表面填充：纸色半透铺在墨边内）——
  static const Color panelFill = Color(0x8CE9DCC0); // paper @ 55%
  static const Color slotFill = Color(0xB3E9DCC0); // paper @ 70%

  // —— 形 ——
  static const double radius = 6.0;
  static const double borderWidth = 1.5;

  // —— 资产 ——
  static const String paperBg = 'assets/ui/paper_bg.png';
  static const String sealRed = 'assets/ui/seal_red.png';
  static const String inkDivider = 'assets/ui/ink_divider.png';
  static const String scrollHorizontal = 'assets/ui/scroll_horizontal.png';
  static const String scrollVertical = 'assets/ui/scroll_vertical.png';
  static const String mountainBg = 'assets/ui/mountain_bg.png';
}
