import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen_config.dart';
import 'package:wuxia_idle/features/combat_shared/presentation/hero_camera_overlay.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';
import 'package:wuxia_idle/features/debug/application/visual_acceptance_plan.dart';
import 'package:wuxia_idle/features/debug/presentation/battle_test_menu.dart';
import 'package:wuxia_idle/features/debug/presentation/visual_route_host.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/features/taohua_island/presentation/taohua_island_screen.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

import '../../support/isar_test_support.dart';

void main() {
  group('parseVisualRoute', () {
    test('已知 id → 对应枚举', () {
      expect(parseVisualRoute('splash'), VisualRoute.splash);
      expect(
        parseVisualRoute('save_select_empty'),
        VisualRoute.saveSelectEmpty,
      );
      expect(
        parseVisualRoute('save_select_filled'),
        VisualRoute.saveSelectFilled,
      );
      expect(parseVisualRoute('main_menu_clean'), VisualRoute.mainMenuClean);
      expect(parseVisualRoute('main_menu'), VisualRoute.mainMenu);
      expect(
        parseVisualRoute('technique_panel_tier_all'),
        VisualRoute.techniquePanelTierAll,
      );
      expect(
        parseVisualRoute('technique_panel_hero'),
        VisualRoute.techniquePanelHero,
      );
      expect(
        parseVisualRoute('technique_refine_insight_dialog'),
        VisualRoute.techniqueRefineInsightDialog,
      );
      expect(
        parseVisualRoute('encounter_outcome_skill_banner'),
        VisualRoute.encounterOutcomeSkillBanner,
      );
      expect(
        parseVisualRoute('character_panel'),
        VisualRoute.characterPanelProfile,
      );
      expect(parseVisualRoute('chapter_list'), VisualRoute.chapterList);
      expect(parseVisualRoute('settings_panel'), VisualRoute.settingsPanel);
      expect(
        parseVisualRoute('settings_panel_bottom'),
        VisualRoute.settingsPanelBottom,
      );
      expect(
        parseVisualRoute('settings_panel_disabled'),
        VisualRoute.settingsPanelDisabled,
      );
      expect(parseVisualRoute('battle_scene'), VisualRoute.battleScene);
      expect(
        parseVisualRoute('equipment_detail_screen'),
        VisualRoute.equipmentDetailScreen,
      );
      expect(
        parseVisualRoute('equipment_detail_repair_gallery'),
        VisualRoute.equipmentDetailRepairGallery,
      );
      expect(
        parseVisualRoute('equipment_detail_gauntlet_reward'),
        VisualRoute.equipmentDetailGauntletReward,
      );
      expect(parseVisualRoute('team_lineup'), VisualRoute.teamLineup);
    });

    test('未知 id → null', () {
      expect(parseVisualRoute('nope'), isNull);
    });

    test('空串 → null', () {
      expect(parseVisualRoute(''), isNull);
    });

    test('动态全关卡战斗验收 id 可解析并还原真关卡参数', () {
      expect(
        parseVisualRoute('battle_audit_stage_03_05'),
        VisualRoute.battleStageAudit,
      );
      expect(
        battleAuditStageId('battle_audit_stage_light_foot_04'),
        'stage_light_foot_04',
      );
      expect(
        parseVisualRoute('battle_audit_tower_30'),
        VisualRoute.battleTowerAudit,
      );
      expect(battleAuditTowerFloor('battle_audit_tower_30'), 30);
    });

    test('预构建验收包可从运行时参数读取动态 route id', () {
      expect(
        visualRouteIdFromInputs(const [
          '--visual-route=battle_audit_stage_02_03',
        ]),
        'battle_audit_stage_02_03',
      );
      expect(visualRouteIdFromInputs(const []), isEmpty);
    });

    test('每个枚举 id 往返一致', () {
      for (final r in VisualRoute.values) {
        expect(parseVisualRoute(r.id), r);
      }
    });

    test('B2 新路由 parse', () {
      expect(
        parseVisualRoute('battle_ultimate_caption'),
        VisualRoute.battleUltimateCaption,
      );
      expect(
        parseVisualRoute('battle_boss_frame'),
        VisualRoute.battleBossFrame,
      );
    });

    test('B3/B5 新路由 parse(破招题字 + 败北页)', () {
      expect(
        parseVisualRoute('battle_interrupt_caption'),
        VisualRoute.battleInterruptCaption,
      );
      expect(parseVisualRoute('battle_defeat'), VisualRoute.battleDefeat);
    });

    test('剧情背景路由 parse', () {
      expect(parseVisualRoute('narrative_scene'), VisualRoute.narrativeScene);
    });

    test('M2 active / 被动归来卡路由 parse', () {
      expect(
        parseVisualRoute('offline_recap_active'),
        VisualRoute.offlineRecapActive,
      );
      expect(
        parseVisualRoute('offline_recap_passive'),
        VisualRoute.offlineRecapPassive,
      );
    });

    test('批三拜入立绘题字 overlay 路由 parse', () {
      expect(
        parseVisualRoute('disciple_join_ceremony'),
        VisualRoute.discipleJoinCeremony,
      );
    });

    test('批一英雄镜头 overlay 路由 parse', () {
      expect(parseVisualRoute('hero_camera'), VisualRoute.heroCamera);
    });
    test('两段点选双路由 parse', () {
      expect(parseVisualRoute('battle_tap_live'), VisualRoute.battleTapLive);
      expect(
        parseVisualRoute('battle_tap_preview'),
        VisualRoute.battleTapPreview,
      );
    });
    test('P4 战绩册路由 parse', () {
      expect(parseVisualRoute('battle_record'), VisualRoute.battleRecord);
      expect(
        parseVisualRoute('boss_memory_detail'),
        VisualRoute.bossMemoryDetail,
      );
    });
    test('门派谱1.1 双路由 parse', () {
      expect(parseVisualRoute('lineage_codex'), VisualRoute.lineageCodex);
      expect(
        parseVisualRoute('lineage_character_detail'),
        VisualRoute.lineageCharacterDetail,
      );
    });
    test('奇遇录双路由 parse', () {
      expect(parseVisualRoute('encounter_codex'), VisualRoute.encounterCodex);
      expect(
        parseVisualRoute('encounter_codex_detail'),
        VisualRoute.encounterCodexDetail,
      );
    });
    test('藏卷阁 Hub 路由 parse', () {
      expect(parseVisualRoute('zangjuange'), VisualRoute.zangjuange);
    });
    test('批次3系统页路由 parse', () {
      expect(parseVisualRoute('taohua_island'), VisualRoute.taohuaIsland);
      expect(
        parseVisualRoute('taohua_building_popup'),
        VisualRoute.taohuaBuildingPopup,
      );
      expect(
        parseVisualRoute('recruitment_dialog'),
        VisualRoute.recruitmentDialog,
      );
    });
    test('动态态 dedicated 路由 parse(确认弹窗 / 使用弹窗 / 未解锁 snackbar)', () {
      expect(parseVisualRoute('shop_buy_confirm'), VisualRoute.shopBuyConfirm);
      expect(
        parseVisualRoute('item_use_confirm_dialog'),
        VisualRoute.itemUseConfirmDialog,
      );
      expect(
        parseVisualRoute('skill_codex_locked_snackbar'),
        VisualRoute.skillCodexLockedSnackbar,
      );
    });
    test('resource overview route parse', () {
      expect(
        parseVisualRoute('resource_overview'),
        VisualRoute.resourceOverview,
      );
    });
    test('battle_tap_preview route parse', () {
      expect(
        parseVisualRoute('battle_tap_preview'),
        VisualRoute.battleTapPreview,
      );
    });

    test('主线首通真战斗验收 route parse', () {
      expect(
        parseVisualRoute('mainline_first_clear_battle'),
        VisualRoute.mainlineFirstClearBattle,
      );
      expect(
        parseVisualRoute('mainline_first_clear_battle_auto'),
        VisualRoute.mainlineFirstClearBattleAuto,
      );
    });

    test('V2 与人物素材门禁的确定性战斗验收 route parse', () {
      expect(
        parseVisualRoute('battle_v2_casualty_replacement'),
        VisualRoute.battleV2CasualtyReplacement,
      );
      expect(
        parseVisualRoute('battle_v2_fast_forward_peak'),
        VisualRoute.battleV2FastForwardPeak,
      );
      expect(
        parseVisualRoute('battle_v2_pre_result'),
        VisualRoute.battleV2PreResult,
      );
      expect(
        parseVisualRoute('battle_v2_neutral_3v3'),
        VisualRoute.battleV2Neutral3v3,
      );
      expect(
        parseVisualRoute('battle_identity_silhouette'),
        VisualRoute.battleIdentitySilhouette,
      );
      expect(
        parseVisualRoute('battle_v2_resource_pressure'),
        VisualRoute.battleV2ResourcePressure,
      );
      expect(
        parseVisualRoute('battle_v2_auto_rotation_first'),
        VisualRoute.battleV2AutoRotationFirst,
      );
      expect(
        parseVisualRoute('battle_v2_auto_rotation_second'),
        VisualRoute.battleV2AutoRotationSecond,
      );
    });
  });

  group('VisualRouteReadyGate', () {
    test('普通 route 挂载后首帧即可 READY', () {
      final emitted = <String>[];
      final gate = VisualRouteReadyGate(
        controlled: false,
        onReady: emitted.add,
      );

      gate.markMounted();

      expect(emitted, <String>['mounted']);
    });

    test('状态 route 在目标成立前不得 READY,成立后只发一次摘要', () {
      final emitted = <String>[];
      final gate = VisualRouteReadyGate(controlled: true, onReady: emitted.add);

      gate.markMounted();
      expect(emitted, isEmpty);

      gate.markTarget('seed=20260719 tick=12 left=3 right=5 casualty=1');
      gate.markTarget('duplicate');

      expect(emitted, <String>[
        'seed=20260719 tick=12 left=3 right=5 casualty=1',
      ]);
    });
  });

  // route 枚举 → buildVisualTarget → ScenarioLauncher 胶水回归。
  group('buildVisualTarget · 战斗静态验收路由透传', () {
    setUpAll(() async {
      await initializeTestIsarCore();
      await GameRepository.loadAllDefs();
    });

    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_visual_route_');
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('battle_charge_break → autoStart:false(静态冻结蓄力/破招帧)', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleChargeBreak,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.autoStart, isFalse);
      expect(
        launcher.allowPlayerIntervention,
        isTrue,
        reason: '破招高亮验收路由必须挂载点选干预案台',
      );
      final (left, right) = launcher.teamsFactory();
      expect(left.first.actionPoint, greaterThan(0), reason: '主控必须真正可下发破招技');
      expect(
        right.any((enemy) => enemy.staggerTicksRemaining > 0),
        isTrue,
        reason: '路由必须能同帧验收破绽爆发提示',
      );
      expect(launcher.sceneBackgroundPath, WuxiaUi.battleMountainPassStage);
      expect(launcher.seed, battleV2VisualSeed);
    });

    test('battle_boss_frame → 统一全人物山口舞台', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleBossFrame,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.sceneBackgroundPath, WuxiaUi.battleMountainPassStage);
    });

    test('battle_guardian_ward → 真实塔境轨道 + 异境背景', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleGuardianWard,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.bgmTrack, BgmTrack.tower);
      expect(
        launcher.hint,
        UiStrings.towerTitle,
        reason: '用户终拍应显示正式塔名，不应把调试操作长句塞进战斗标题',
      );
      expect(
        launcher.previewHeaderControls,
        isTrue,
        reason: '代表生产终拍不应暴露“继续/单步”审计控件',
      );
      expect(
        launcher.sceneBackgroundPath,
        'assets/scenes/battle_innerrealm.png',
      );
    });

    test('battle suite 73个动态路由与6个确定性素材/状态路由全部可构造', () async {
      final targets = visualAcceptanceRoutes(VisualAcceptanceSuite.battle);
      for (final spec in targets) {
        final target = await buildVisualTarget(
          spec.route,
          IsarSetup.instance,
          routeId: spec.id,
        );
        expect(target, isA<ScenarioLauncher>(), reason: spec.id);
        final launcher = target as ScenarioLauncher;
        final (left, right) = launcher.teamsFactory();
        expect(left, hasLength(3), reason: spec.id);
        expect(right, isNotEmpty, reason: spec.id);
        expect(right.length, lessThanOrEqualTo(4), reason: spec.id);
        expect(launcher.startPaused, isTrue, reason: spec.id);

        if (spec.route == VisualRoute.battleGauntletAudit) {
          // 断魂庄生产入口 `gauntlet_entry_flow` 不传 sceneBackgroundPath,
          // audit 必须照样传 null——补一张背景就等于在验玩家看不到的画面。
          // 【顺带发现·2026-08-01】断魂庄是全项目唯一不叠场景美术的战斗
          // (mainline/tower/sweep 三入口都传背景)。`BattleSceneBackground`
          // 在 path==null 时只跳过 `WuxiaImage` 与 image scrim 两层,
          // 程序化层反而全开满强度(天空渐变 + `_DistantMountainPainter` 远山 +
          // mist/ground 两 painter intensity=1 + 晕影),故画面并不残缺——
          // 720p 实拍(build/visual_acceptance/gauntlet_audit_20260801)观感成立。
          // 即:这是「唯一纯靠程序化兜底」而非「画面缺失」,补不补场景美术是内容层
          // 决定,不在本批范围;此前无人注意到也正因它从未进过任何 audit 路由。
          expect(launcher.sceneBackgroundPath, isNull, reason: spec.id);
          expect(launcher.bgmTrack, BgmTrack.boss, reason: spec.id);
        } else {
          expect(launcher.sceneBackgroundPath, isNotNull, reason: spec.id);
        }

        if (spec.route == VisualRoute.battleTowerAudit) {
          expect(launcher.bgmTrack, BgmTrack.tower, reason: spec.id);
        } else if (spec.id.contains('_light_foot_')) {
          expect(launcher.bgmTrack, BgmTrack.lightFoot, reason: spec.id);
        } else if (spec.id.contains('_mass_battle_')) {
          expect(launcher.bgmTrack, BgmTrack.massBattle, reason: spec.id);
        }
      }
    });

    test('高复用敌人四个塔层路由 → 真塔境冻结帧', () async {
      for (final route in const [
        VisualRoute.battleTowerFloor13,
        VisualRoute.battleTowerFloor14,
        VisualRoute.battleTowerFloor19,
        VisualRoute.battleTowerFloor22,
      ]) {
        final target = await buildVisualTarget(route, IsarSetup.instance);
        expect(target, isA<ScenarioLauncher>());
        final launcher = target as ScenarioLauncher;
        expect(launcher.bgmTrack, BgmTrack.tower);
        expect(launcher.startPaused, isTrue);
        expect(
          launcher.sceneBackgroundPath,
          'assets/scenes/battle_innerrealm.png',
        );
      }
    });

    test('早期主线与低层塔验收路由 → 真关卡冻结帧', () async {
      for (final route in const [
        VisualRoute.battleStage0102,
        VisualRoute.battleStage0103,
        VisualRoute.battleStage0104,
      ]) {
        final target = await buildVisualTarget(route, IsarSetup.instance);
        expect(target, isA<ScenarioLauncher>());
        final launcher = target as ScenarioLauncher;
        expect(launcher.startPaused, isTrue);
        expect(launcher.sceneBackgroundPath, WuxiaUi.battleMountainPassStage);
      }

      for (final route in const [
        VisualRoute.battleTowerFloor02,
        VisualRoute.battleTowerFloor03,
        VisualRoute.battleTowerFloor08,
        VisualRoute.battleTowerFloor06,
        VisualRoute.battleTowerFloor07,
        VisualRoute.battleTowerFloor12,
      ]) {
        final target = await buildVisualTarget(route, IsarSetup.instance);
        expect(target, isA<ScenarioLauncher>());
        final launcher = target as ScenarioLauncher;
        expect(launcher.bgmTrack, BgmTrack.tower);
        expect(launcher.startPaused, isTrue);
        expect(
          launcher.sceneBackgroundPath,
          'assets/scenes/battle_innerrealm.png',
        );
      }

      for (final (route, expectedBackground) in const [
        (
          VisualRoute.battleStage0401,
          'assets/scenes/battle_mountainforest.png',
        ),
        (VisualRoute.battleStage0402, 'assets/scenes/battle_frontier.png'),
        (VisualRoute.battleStage0403, 'assets/scenes/battle_desert.png'),
        (VisualRoute.battleStage0404, 'assets/scenes/battle_drillground.png'),
        (VisualRoute.battleStage0405, 'assets/scenes/battle_frontier.png'),
        (
          VisualRoute.battleStage0501,
          'assets/scenes/battle_mountainforest.png',
        ),
        (VisualRoute.battleStage0502, 'assets/scenes/battle_temple.png'),
        (VisualRoute.battleStage0503, 'assets/scenes/battle_dock.png'),
        (VisualRoute.battleStage0504, 'assets/scenes/battle_drillground.png'),
        (VisualRoute.battleStage0505, 'assets/scenes/battle_citywall.png'),
        (VisualRoute.battleStage0601, 'assets/scenes/battle_citywall.png'),
        (
          VisualRoute.battleStage0602,
          'assets/scenes/battle_mountainforest.png',
        ),
        (VisualRoute.battleStage0603, 'assets/scenes/battle_dock.png'),
        (VisualRoute.battleStage0604, 'assets/scenes/battle_desert.png'),
        (
          VisualRoute.battleStage0605,
          'assets/scenes/battle_mountainforest.png',
        ),
      ]) {
        final target = await buildVisualTarget(route, IsarSetup.instance);
        expect(target, isA<ScenarioLauncher>());
        final launcher = target as ScenarioLauncher;
        expect(launcher.startPaused, isTrue);
        expect(launcher.sceneBackgroundPath, expectedBackground);
      }
    });

    test('battle_tap_live → 起手暂停 + 单步控件 + 玩家干预', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleTapLive,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(
        launcher.allowPlayerIntervention,
        isTrue,
        reason: '两段点选验收路由必须开干预,否则技能按钮不接收点选',
      );
      expect(launcher.autoStart, isTrue);
      expect(launcher.startPaused, isTrue);
      expect(launcher.seed, battleV2VisualSeed);
      expect(
        launcher.previewHeaderControls,
        isFalse,
        reason: '对照段必须显示真实暂停态和单步键，不得伪装为正在播放',
      );
    });

    test('battle_tap_live → 黄金样板敌方立绘与蓄势 2 拍固定', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleTapLive,
        IsarSetup.instance,
      );
      final launcher = target as ScenarioLauncher;
      final (_, right) = launcher.teamsFactory();

      expect(right.map((character) => character.iconPath), [
        WuxiaUi.battleSampleHiddenElderStandee,
        WuxiaUi.battleSampleBanditBladeStandee,
        WuxiaUi.battleSampleBanditArcherStandee,
      ]);
      expect(right.first.isBoss, isTrue);
      expect(right.first.chargingSkill, isNotNull);
      expect(right.first.chargeTicksRemaining, 2);
      expect(launcher.hint, UiStrings.battleSampleSceneTitle);
      expect(right.map((character) => character.name), [
        UiStrings.battleSampleHiddenElder,
        UiStrings.battleSampleBanditBlade,
        UiStrings.battleSampleBanditArcher,
      ]);

      final (left, _) = launcher.teamsFactory();
      expect(left.map((character) => character.name), [
        UiStrings.battleSampleFounder,
        UiStrings.battleSampleFirstDisciple,
        UiStrings.battleSampleSecondDisciple,
      ]);
      expect(left.map((character) => character.iconPath), [
        isNull,
        WuxiaUi.battleSampleFirstDiscipleStandee,
        isNull,
      ]);
      final visibleSkills = left.first.availableSkills.skip(1).toList();
      expect(
        visibleSkills.map((skill) => skill.name),
        UiStrings.battleSampleSkillNames,
      );
      expect(visibleSkills.map((skill) => skill.qiCost), [
        20,
        30,
        35,
        60,
        15,
        25,
        30,
      ]);
      expect(
        WuxiaUi.battleSamplePouchGourd,
        'assets/ui/mj/battle_pouch_gourd_sample_v2.png',
      );
      expect(
        WuxiaUi.battleSamplePouchManual,
        'assets/ui/mj/battle_pouch_manual_sample_v2.png',
      );
      expect(launcher.previewPouchItems, const [
        BattlePouchPreviewItem(
          assetPath: WuxiaUi.battleSamplePouchGourd,
          count: 3,
        ),
        BattlePouchPreviewItem(
          assetPath: WuxiaUi.battleSamplePouchManual,
          count: 2,
        ),
      ]);
    });

    test('battle_tap_preview → 冻结态 + 纯 presentation 待发预览', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleTapPreview,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.allowPlayerIntervention, isTrue);
      expect(launcher.autoStart, isFalse, reason: 'preview 必须冻结在预置态');
      expect(launcher.startPaused, isTrue);
      expect(launcher.previewPendingCharacterId, 1);
      expect(launcher.previewPendingSkillId, 'dl_single_1');
      expect(launcher.sceneBackgroundPath, WuxiaUi.battleMountainPassStage);
      expect(launcher.seed, battleV2VisualSeed);
    });

    test('battle_tap_preview → 复用点选冻结预置态', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleTapPreview,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.autoStart, isFalse);
      expect(launcher.allowPlayerIntervention, isTrue);
      expect(launcher.startPaused, isTrue);
      expect(launcher.previewPendingCharacterId, 1);
      expect(launcher.previewPendingSkillId, 'dl_single_1');
    });

    test('V2 中性 3v3 → 静态冻结且无待发/自动/结算遮挡', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleV2Neutral3v3,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.autoStart, isFalse);
      expect(launcher.startPaused, isTrue);
      expect(launcher.previewPendingCharacterId, isNull);
      expect(launcher.previewPendingSkillId, isNull);
      expect(launcher.readyTarget, VisualBattleReadyTarget.initialized);
      final (left, right) = launcher.teamsFactory();
      expect(left, hasLength(3));
      expect(right, hasLength(3));
    });

    test('V2 多敌蓄势 → 三敌同帧保留 3/1/2 拍真实状态', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleV2MultiCharge,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(
        launcher.teamsFactory,
        same(BattleScenarioData.scenarioV2MultiCharge),
      );
      expect(launcher.autoStart, isFalse);
      expect(launcher.startPaused, isTrue);
      expect(launcher.allowPlayerIntervention, isTrue);
      expect(launcher.previewHeaderControls, isTrue);
      expect(launcher.previewPouchItems, hasLength(2));
      expect(launcher.readyTarget, VisualBattleReadyTarget.initialized);
      final (_, right) = launcher.teamsFactory();
      expect(right.map((character) => character.chargeTicksRemaining), [
        3,
        1,
        2,
      ]);
      expect(
        right.every((character) => character.chargingSkill != null),
        isTrue,
      );
    });

    test('V2 资源压力 → 同帧含冷却签与真气不足签', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleV2ResourcePressure,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.autoStart, isFalse);
      expect(launcher.startPaused, isTrue);
      expect(launcher.allowPlayerIntervention, isTrue);
      expect(launcher.readyTarget, VisualBattleReadyTarget.resourcePressure);
      final (left, _) = launcher.teamsFactory();
      final focus = left.first;
      expect(focus.skillCooldowns.values.any((turns) => turns > 0), isTrue);
      expect(
        focus.availableSkills.any(
          (skill) =>
              skill.internalForceCost > focus.currentQi &&
              (focus.skillCooldowns[skill.id] ?? 0) == 0,
        ),
        isTrue,
      );
    });

    test('V2 动态 route 固定 seed、目标谓词与暂停接线', () async {
      for (final (route, readyTarget) in const [
        (
          VisualRoute.battleV2CasualtyReplacement,
          VisualBattleReadyTarget.casualtyReplacement,
        ),
        (
          VisualRoute.battleV2FastForwardPeak,
          VisualBattleReadyTarget.fastForwardPeak,
        ),
        (VisualRoute.battleV2PreResult, VisualBattleReadyTarget.preResult),
        (
          VisualRoute.battleV2AutoRotationFirst,
          VisualBattleReadyTarget.autoRotationFirst,
        ),
        (
          VisualRoute.battleV2AutoRotationSecond,
          VisualBattleReadyTarget.autoRotationSecond,
        ),
      ]) {
        final target = await buildVisualTarget(route, IsarSetup.instance);
        expect(target, isA<ScenarioLauncher>());
        final launcher = target as ScenarioLauncher;
        expect(launcher.seed, battleV2VisualSeed, reason: route.id);
        expect(launcher.startPaused, isTrue, reason: route.id);
        expect(launcher.readyTarget, readyTarget, reason: route.id);
        expect(route.controlsReadiness, isTrue, reason: route.id);
        if (route == VisualRoute.battleV2AutoRotationFirst ||
            route == VisualRoute.battleV2AutoRotationSecond) {
          expect(
            launcher.teamsFactory,
            same(BattleScenarioData.scenarioV2AutoRotation),
            reason: route.id,
          );
        }
      }
    });

    test('V2 动态 route 两次回放得到一致 tick、状态摘要且未越过目标', () {
      VisualBattleReplayResult replay(
        VisualBattleReadyTarget target,
        (List<BattleCharacter>, List<BattleCharacter>) Function() factory,
      ) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        return VisualBattleReplay.run(
          notifier: container.read(battleProvider.notifier),
          readState: () => container.read(battleProvider),
          teams: factory(),
          seed: battleV2VisualSeed,
          target: target,
        );
      }

      for (final (target, factory)
          in <
            (
              VisualBattleReadyTarget,
              (List<BattleCharacter>, List<BattleCharacter>) Function(),
            )
          >[
            (
              VisualBattleReadyTarget.casualtyReplacement,
              BattleScenarioData.scenarioV2CasualtyReplacement,
            ),
            (
              VisualBattleReadyTarget.fastForwardPeak,
              BattleScenarioData.scenarioV2FastForwardPeak,
            ),
            (
              VisualBattleReadyTarget.preResult,
              BattleScenarioData.scenarioV2PreResult,
            ),
            (
              VisualBattleReadyTarget.autoRotationFirst,
              BattleScenarioData.scenarioV2AutoRotation,
            ),
            (
              VisualBattleReadyTarget.autoRotationSecond,
              BattleScenarioData.scenarioV2AutoRotation,
            ),
          ]) {
        final first = replay(target, factory);
        final second = replay(target, factory);
        expect(first.summary, second.summary, reason: target.name);
        expect(first.state.tick, second.state.tick, reason: target.name);
        expect(VisualBattleReplay.matches(target, first.state), isTrue);
        expect(first.state.isFinished, isFalse, reason: target.name);
      }
    });

    test('mainline_first_clear_battle → 主线首通 preview 接线', () async {
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
      final target = await buildVisualTarget(
        VisualRoute.mainlineFirstClearBattle,
        IsarSetup.instance,
      );
      expect(target.runtimeType.toString(), '_MainlineFirstClearBattlePreview');
    });

    test('mainline_first_clear_battle_auto → 主线首通自动播放 preview 接线', () async {
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
      final target = await buildVisualTarget(
        VisualRoute.mainlineFirstClearBattleAuto,
        IsarSetup.instance,
      );
      expect(target.runtimeType.toString(), '_MainlineFirstClearBattlePreview');
      expect((target as dynamic).allowPlayerIntervention, isFalse);
    });

    test('taohua_building_popup → 桃花岛自动打开打造台菜单', () async {
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
      final target = await buildVisualTarget(
        VisualRoute.taohuaBuildingPopup,
        IsarSetup.instance,
      );
      expect(target, isA<TaohuaIslandScreen>());
      final screen = target as TaohuaIslandScreen;
      expect(screen.initialBuildingMenu, BuildingType.daZaoTai);
    });

    test('skill_codex_locked_snackbar → snackbar preview route 接线', () async {
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
      final target = await buildVisualTarget(
        VisualRoute.skillCodexLockedSnackbar,
        IsarSetup.instance,
      );
      expect(target.runtimeType.toString(), '_SkillCodexLockedSnackbarPreview');
    });
  });

  // 批一英雄镜头 preview：真数据(祖师 + 真 stage_01_05 Boss 名)接线回归。
  group('hero_camera preview · 真数据接线', () {
    setUpAll(() async {
      await initializeTestIsarCore();
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
    });

    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_hero_camera_');
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('hero_camera → HeroCameraOverlay 弹出 + 祖师名号题字(真数据组装不抛异常)', (
      tester,
    ) async {
      final target = await buildVisualTarget(
        VisualRoute.heroCamera,
        IsarSetup.instance,
      );
      await tester.pumpWidget(MaterialApp(home: target));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.byType(HeroCameraOverlay),
        findsOneWidget,
        reason: '专属路由必须弹英雄镜头 overlay,否则批一动效仍无法目检',
      );
      expect(find.text('祖师'), findsOneWidget, reason: '出镜英雄名号取祖师占位名');
    });
  });
}
