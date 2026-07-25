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
  // 青灰在深墨底上的同色相可读版本。用于空状态等“可行动但尚无内容”的弱强调，
  // 避免直接把浅宣纸用 qing 放到深底后误读成禁用态。
  static const Color qingOnDark = Color(0xFF94AFA4);
  static const Color jiang = Color(0xFF8A2B21); // 绛红（点缀/主行动）
  static const Color battleStatusPaperTop = Color(0xB85A4B3D);
  static const Color battleStatusPaperBottom = Color(0xCC2E2821);
  static const Color battleStatusTrack = Color(0xA62A241D);
  static const Color gold = Color(0xFFB08A47); // 金线（仅高阶装帧）
  static const Color muted = Color(
    0xFF6A5E4C,
  ); // 柔灰（浅底次要/副描述文字 sink · 2026-07-06 从 #7D7160 深一档，浅底小字对比 ~3:1→~4:1）
  static const Color woodLight = Color(0xFF6E5532); // 木牌亮边
  static const Color woodDark = Color(0xFF4F3C22); // 木牌暗边

  // —— 面（宣纸表面填充：纸色半透铺在墨边内）——
  // 2026-06-29:原 55%/70% 叠深色 scaffold 渲染成偏暗茶褐(~#978D78),墨色次要文字(muted)
  // 对比不足看不清(商店等 LightPaperPanel 页)。提到 86%/91% 让面板真正呈浅宣纸色(贴合「宣纸浅色面板」
  // 设计意图),muted 恢复可读;纸纹理仍由上层 paperOpacity 叠出。
  static const Color panelFill = Color(0xDBE9DCC0); // paper @ 86%
  static const Color slotFill = Color(0xE8E9DCC0); // paper @ 91%

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
  static const String battleFounderFallback =
      'assets/characters/battle_founder_v2.png';
  static const String battleMountainPassStage =
      'assets/scenes/battle_mountain_pass_stage_v2.png';
  static const String battleMountainPassStageCool =
      'assets/scenes/battle_mountain_pass_stage_cool_v3.png';
  static const String battleInnerRealmCool =
      'assets/scenes/battle_innerrealm_cool_v2.png';
  static const String battleFirstDiscipleFallback =
      'assets/characters/battle_first_disciple.png';
  static const String battleSecondDiscipleFallback =
      'assets/characters/battle_second_disciple.png';
  static const String battleThugStandee = 'assets/enemies/battle_thug_a.png';
  static const String battleBlackKillerStandee =
      'assets/enemies/battle_black_killer.png';
  static const String battleHiddenElderStandee =
      'assets/enemies/battle_hidden_elder.png';
  static const String battleBanditBladeStandee =
      'assets/enemies/battle_bandit_blade.png';
  static const String battleBanditArcherStandee =
      'assets/enemies/battle_bandit_archer.png';
  static const String battleYoungRuffianStandee =
      'assets/enemies/battle_thug_b.png';
  static const String battleGauntCutpurseStandee =
      'assets/enemies/battle_thug_c.png';
  static const String battleVillageRuffianStandee =
      'assets/enemies/battle_ruffian_a.png';
  static const String battleBanditHeadStandee =
      'assets/enemies/battle_bandit_head.png';
  static const String battleQingshanStandee =
      'assets/enemies/battle_qingshan.png';
  static const String battleGreyElderStandee =
      'assets/enemies/battle_elder_grey.png';
  static const String battleSpringHallYouthStandee =
      'assets/enemies/battle_shaonian.png';
  static const String battleBaldStaffFighterStandee =
      'assets/enemies/battle_guntou.png';
  static const String battleArenaChampionStandee =
      'assets/enemies/battle_guntou_zhu.png';
  static const String battleGreyMonkStandee =
      'assets/enemies/battle_seng_huiyi.png';
  static const String battleScarredBossStandee =
      'assets/enemies/battle_balian.png';
  static const String battleGreySwordsmanStandee =
      'assets/enemies/battle_huiyi.png';
  static const String battleFerryBanditStandee =
      'assets/enemies/battle_lightfoot_shuikou_a.png';
  static const String battleFerryBoatmanStandee =
      'assets/enemies/battle_lightfoot_shuikou_b.png';
  static const String battleFerrySaberStandee =
      'assets/enemies/battle_lightfoot_shuikou_c.png';
  static const String battleNightPatrolStandee =
      'assets/enemies/battle_lightfoot_yexun_a.png';
  static const String battleRooftopConstableStandee =
      'assets/enemies/battle_lightfoot_yexun_b.png';
  static const String battleRooftopAssassinStandee =
      'assets/enemies/battle_lightfoot_yexun_c.png';
  static const String battleJiangnanSwordsmanStandee =
      'assets/enemies/battle_lightfoot_zhuke_a.png';
  static const String battleBambooSaberStandee =
      'assets/enemies/battle_lightfoot_zhuke_b.png';
  static const String battleBambooWandererStandee =
      'assets/enemies/battle_lightfoot_zhuke_c.png';
  static const String battleMountainStreamSwordStandee =
      'assets/enemies/battle_lightfoot_pubu_a.png';
  static const String battleWaterfallSaberStandee =
      'assets/enemies/battle_lightfoot_pubu_b.png';
  static const String battleCliffWandererStandee =
      'assets/enemies/battle_lightfoot_pubu_c.png';
  static const String battleGateCommanderStandee =
      'assets/enemies/battle_lightfoot_changfeng_a.png';
  static const String battleLongWindSwordStandee =
      'assets/enemies/battle_lightfoot_changfeng_b.png';
  static const String battleLongRoadSaberStandee =
      'assets/enemies/battle_lightfoot_changfeng_c.png';
  static const String battleVillageBanditLeaderStandee =
      'assets/enemies/battle_massbattle_cunfei_a.png';
  static const String battleVillageBanditArcherStandee =
      'assets/enemies/battle_massbattle_cunfei_b.png';
  static const String battleVillageBanditSaberStandee =
      'assets/enemies/battle_massbattle_cunfei_c.png';
  static const String battleTownBanditLeaderStandee =
      'assets/enemies/battle_massbattle_zhenkou_a.png';
  static const String battleTownBanditWandererStandee =
      'assets/enemies/battle_massbattle_zhenkou_b.png';
  static const String battleTownBanditAssassinStandee =
      'assets/enemies/battle_massbattle_zhenkou_c.png';
  static const String battleRivalSectMasterStandee =
      'assets/enemies/battle_massbattle_xianjie_a.png';
  static const String battleRivalSectProtectorStandee =
      'assets/enemies/battle_massbattle_xianjie_b.png';
  static const String battleRivalSectDiscipleStandee =
      'assets/enemies/battle_massbattle_xianjie_c.png';
  static const String battleFrontierCommanderStandee =
      'assets/enemies/battle_massbattle_guanqi_a.png';
  static const String battleFrontierOutriderStandee =
      'assets/enemies/battle_massbattle_guanqi_b.png';
  static const String battleFrontierIronGuardStandee =
      'assets/enemies/battle_massbattle_guanqi_c.png';
  static const String battleWesternRemnantGeneralStandee =
      'assets/enemies/battle_massbattle_canbu_a.png';
  static const String battleWesternFrenziedRiderStandee =
      'assets/enemies/battle_massbattle_canbu_b.png';
  static const String battleWesternRemnantAssassinStandee =
      'assets/enemies/battle_massbattle_canbu_c.png';
  static const String battleUmbrellaStandee =
      'assets/enemies/battle_umbrella.png';
  static const String battleSwordStoneElderStandee =
      'assets/enemies/battle_tower_boss_05.png';
  static const String battleBlackWindChiefStandee =
      'assets/enemies/battle_tower_boss_10.png';
  static const String battleNightPavilionMasterStandee =
      'assets/enemies/battle_tower_boss_15.png';
  static const String battleTowerBoss20Standee =
      'assets/enemies/battle_tower_boss_20.png';
  static const String battleSummitSwordDemonStandee =
      'assets/enemies/battle_tower_boss_25.png';
  static const String battleWesternMartialSeniorStandee =
      'assets/enemies/battle_xiliangboss.png';
  static const String battleWesternOverlordStandee =
      'assets/enemies/battle_xiliangbazhu.png';
  static const String battleCentralPlainsVanguardStandee =
      'assets/enemies/battle_zhongzhou_lunjian_xianfeng.png';
  static const String battleWesternThirdDiscipleStandee =
      'assets/enemies/battle_xiliang_sandizi.png';
  static const String battleKunlunGateGuardianStandee =
      'assets/enemies/battle_kunlun_waimen_shouguan.png';
  static const String battleWesternOverlordSaintStandee =
      'assets/enemies/battle_xiliang_bazhu.png';
  static const String battleWanderingPalmFighterStandee =
      'assets/enemies/battle_jianghu_a.png';
  static const String battleEstablishedSectDiscipleStandee =
      'assets/enemies/battle_mingmen_a.png';
  static const String battleLowRankSaberFighterStandee =
      'assets/enemies/battle_bandit_b.png';
  static const String battleBlackWindUnderlingStandee =
      'assets/enemies/battle_bandit_c.png';
  static const String battleIndependentWandererStandee =
      'assets/enemies/battle_jianghu_b.png';
  static const String battleRaiderLeaderStandee =
      'assets/enemies/battle_liukou_a.png';
  static const String battleYumenGarrisonOfficerStandee =
      'assets/enemies/battle_guard_a.png';
  static const String battleDesertBanditLeaderStandee =
      'assets/enemies/battle_shafei_a.png';
  static const String battleTongguanDefenderStandee =
      'assets/enemies/battle_tongguan_shoujiang.png';
  static const String battleSongshanDaoistDiscipleStandee =
      'assets/enemies/battle_songshan_daozong_dizi.png';
  static const String battleCanalGangHelmsmanStandee =
      'assets/enemies/battle_caobang_duozhu.png';
  static const String battleArenaPatrolStandee =
      'assets/enemies/battle_lunjian_sanchang_xunluo.png';
  static const String battleSongshanGatekeeperStandee =
      'assets/enemies/battle_songshan_shouguan.png';
  static const String battleYellowRiverFisherStandee =
      'assets/enemies/battle_huanghe_yuantou_yufu.png';
  static const String battleLeftGuardianStandee =
      'assets/enemies/battle_zuo_hufa.png';
  static const String battleRightGuardianStandee =
      'assets/enemies/battle_you_hufa.png';
  static const String battleTowerBoss30Standee =
      'assets/enemies/battle_tower_boss_30_v2.png';
  static const String battleJianghuSeniorStandee =
      'assets/enemies/battle_jianghu_qianbei.png';
  static const String battleWulinOverlordStandee =
      'assets/enemies/battle_wulin_bazhu.png';
  static const String battleNightSwordsmanStandee =
      'assets/enemies/battle_anye.png';
  static const String battleAdviserStandee = 'assets/enemies/battle_shiye.png';
  static const String battleFuChiefStandee =
      'assets/enemies/battle_fu_zhaizhu.png';
  static const String battleGauntletSuWujiuStandee =
      'assets/enemies/enemy_gauntlet_su_wujiu.png';
  static const String battleGauntletQingyiGuardAStandee =
      'assets/enemies/enemy_gauntlet_qingyi_hu_a.png';
  static const String battleGauntletQingyiGuardBStandee =
      'assets/enemies/enemy_gauntlet_qingyi_hu_b.png';
  static const String battleGauntletShiZhenyueStandee =
      'assets/enemies/enemy_gauntlet_shi_zhenyue.png';
  static const String battleGauntletStaffRetainerAStandee =
      'assets/enemies/enemy_gauntlet_zhizhang_a.png';
  static const String battleGauntletStaffRetainerBStandee =
      'assets/enemies/enemy_gauntlet_zhizhang_b.png';
  static const String battleGauntletWenJiuzhenStandee =
      'assets/enemies/enemy_gauntlet_wen_jiuzhen.png';
  static const String battleBaicaoShanjiaStandee =
      'assets/enemies/enemy_baicao_shanjia.png';
  static const String battleBaicaoFenghouStandee =
      'assets/enemies/enemy_baicao_fenghou.png';
  static const String battleBaicaoPoisonHerbalistStandee =
      'assets/enemies/enemy_baicao_duwu.png';
  static const String battleBaicaoFogLeaderStandee =
      'assets/enemies/enemy_baicao_fog_leader.png';
  static const String battleBaicaoFogGuardStandee =
      'assets/enemies/enemy_baicao_fog_guard.png';
  static const String battleBaicaoFogScoutStandee =
      'assets/enemies/enemy_baicao_fog_scout.png';
  static const String battleBaicaoRidgeLeaderStandee =
      'assets/enemies/enemy_baicao_ridge_leader.png';
  static const String battleBaicaoRidgeNeedlerStandee =
      'assets/enemies/enemy_baicao_ridge_needler.png';
  static const String battleBaicaoRidgeRunnerStandee =
      'assets/enemies/enemy_baicao_ridge_runner.png';
  static const String battleBossEntranceBg =
      'assets/scenes/mj/battle_boss_entrance_bg_01.png';
}
