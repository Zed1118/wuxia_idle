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
  // 浅宣纸底的【正文/主标题】sink = ink；【次要/副描述】sink = muted（下方）。
  // 浅底文字勿用 WuxiaColors.textPrimary/textSecondary/textMuted（那是深底专用浅灰，叠浅底会糊）。
  static const Color ink = Color(0xFF241F1A); // 墨黑（边/正文 · 浅底正文 sink）
  static const Color ink2 = Color(0xFF3A332B);
  static const Color paper = Color(0xFFE9DCC0); // 宣纸黄（面）
  static const Color paper2 = Color(0xFFDDCAA3);
  static const Color qing = Color(0xFF566B63); // 青灰（内息/辅）
  static const Color jiang = Color(0xFF8A2B21); // 绛红（点缀/主行动）
  static const Color gold = Color(0xFFB08A47); // 金线（仅高阶装帧）
  static const Color muted = Color(0xFF7D7160); // 柔灰（浅底次要/副描述文字 sink）
  static const Color woodLight = Color(0xFF6E5532); // 木牌亮边
  static const Color woodDark = Color(0xFF4F3C22); // 木牌暗边

  // —— 面（宣纸表面填充：纸色半透铺在墨边内）——
  static const Color panelFill = Color(0x8CE9DCC0); // paper @ 55%
  static const Color slotFill = Color(0xB3E9DCC0); // paper @ 70%

  // —— 形 ——
  static const double radius = 6.0;
  static const double borderWidth = 1.5;

  // —— 字 ——
  static const double textScale = 1.12;

  // —— 资产 ——
  static const String paperBg = 'assets/ui/paper_bg.png';
  static const String sealRed = 'assets/ui/seal_red.png';
  static const String inkDivider = 'assets/ui/ink_divider.png';
  static const String scrollHorizontal = 'assets/ui/scroll_horizontal.png';
  static const String scrollVertical = 'assets/ui/scroll_vertical.png';
  static const String mountainBg = 'assets/ui/mountain_bg.png';
  static const String mainMenuBg =
      'assets/ui/mj/menu_mountain_gate_clean_01.png';
  static const String mainMenuPierBg = 'assets/ui/mj/menu_splash_pier_01.png';
  static const String mainMenuPierAltBg =
      'assets/ui/mj/menu_splash_pier_02.png';
  static const String mainMenuMountainBg =
      'assets/ui/mj/menu_mountain_gate_01.png';
  static const String mainMenuMountainWideBg =
      'assets/ui/mj/menu_mountain_gate_wide_01.png';
  static const String entryMainline =
      'assets/ui/mj/entry_mainline_story_01.png';
  static const String entryCharacter =
      'assets/ui/mj/entry_character_profile_01.png';
  static const String entryInventory = 'assets/ui/mj/entry_equipment_01.png';
  static const String entryTechnique =
      'assets/ui/mj/entry_technique_panel_01.png';
  static const String entrySeclusion =
      'assets/ui/mj/entry_seclusion_retreat_01.png';
  static const String entryTower = 'assets/ui/mj/entry_tower_challenge_01.png';
  static const String entryLightFoot =
      'assets/ui/mj/entry_lightfoot_trial_01.png';
  static const String entryJianghu = 'assets/ui/mj/entry_city_defense_01.png';
  static const String entryCodex = 'assets/ui/mj/entry_jianghu_codex_01.png';
  static const String ceremonyRealmBreakthrough =
      'assets/ui/mj/ceremony_realm_breakthrough_01.png';
  static const String ceremonyBossFirstVictory =
      'assets/ui/mj/ceremony_boss_first_victory_01.png';
  static const String ceremonyVictoryTag =
      'assets/ui/mj/ceremony_victory_tag_01.png';
  static const String ceremonyRedSeal =
      'assets/ui/mj/ceremony_red_seal_blend.png';
  static const String ceremonyEquipmentResonance =
      'assets/ui/mj/ceremony_equipment_resonance_01.png';
  static const String ceremonyTechniqueScroll =
      'assets/ui/mj/ceremony_technique_scroll_01.png';
  static const String ceremonyRetreatResult =
      'assets/ui/mj/ceremony_offline_retreat_result_01.png';
  static const String ceremonyInsightBamboo =
      'assets/ui/mj/ceremony_insight_bamboo_01.png';
  static const String ceremonyFailureInk =
      'assets/ui/mj/ceremony_failure_ink_01.png';
  static const String fxGangmengStrike =
      'assets/ui/mj/fx_gangmeng_strike_blend.png';
  static const String fxGangmengUltimate =
      'assets/ui/mj/fx_gangmeng_ultimate_blend.png';
  static const String fxLingqiaoSlash =
      'assets/ui/mj/fx_lingqiao_slash_blend.png';
  static const String fxLingqiaoUltimate =
      'assets/ui/mj/fx_lingqiao_ultimate_blend.png';
  static const String fxYinrouPalm = 'assets/ui/mj/fx_yinrou_palm_blend.png';
  static const String fxYinrouUltimate =
      'assets/ui/mj/fx_yinrou_ultimate_blend.png';
  static const String fxCriticalHit = 'assets/ui/mj/fx_critical_hit_blend.png';
  static const String fxArmorBreak = 'assets/ui/mj/fx_armor_break_blend.png';
  static const String fxDodgeShadow = 'assets/ui/mj/fx_dodge_shadow_blend.png';
  static const String fxInternalInjury =
      'assets/ui/mj/fx_internal_injury_blend.png';
  static const String overlayMistLayer =
      'assets/ui/mj/overlay_mist_layer_blend.png';
  static const String overlayInkCloud =
      'assets/ui/mj/overlay_ink_cloud_blend.png';
  static const String overlayLanternGlow =
      'assets/ui/mj/overlay_lantern_glow_blend.png';
  static const String overlayLowHealth =
      'assets/ui/mj/overlay_low_health_blend.png';
  static const String bossFrame = 'assets/ui/mj/ui_boss_frame_blend.png';
  static const String bossFrameLarge =
      'assets/ui/mj/ui_big_boss_frame_blend.png';
  static const String battleBossEntranceBg =
      'assets/scenes/mj/battle_boss_entrance_bg_01.png';
}
