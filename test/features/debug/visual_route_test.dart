import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/presentation/hero_camera_overlay.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';
import 'package:wuxia_idle/features/debug/application/visual_acceptance_plan.dart';
import 'package:wuxia_idle/features/debug/presentation/battle_test_menu.dart';
import 'package:wuxia_idle/features/debug/presentation/visual_route_host.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/features/taohua_island/presentation/taohua_island_screen.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

import '../../support/isar_test_support.dart';

void main() {
  group('parseVisualRoute', () {
    test('已知 id → 对应枚举', () {
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
      expect(parseVisualRoute('battle_scene'), VisualRoute.battleScene);
      expect(
        parseVisualRoute('equipment_detail_screen'),
        VisualRoute.equipmentDetailScreen,
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

    test('M2 离线被动归来卡路由 parse', () {
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
        launcher.sceneBackgroundPath,
        'assets/scenes/battle_innerrealm.png',
      );
    });

    test('battle suite 70个动态路由全部可构造真敌队', () async {
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
        expect(right.length, lessThanOrEqualTo(3), reason: spec.id);
        expect(launcher.startPaused, isTrue, reason: spec.id);
        expect(launcher.sceneBackgroundPath, isNotNull, reason: spec.id);

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

    test('battle_tap_live → allowPlayerIntervention:true + autoStart:true '
        '(两段点选干预层必须挂,守 ScenarioLauncher 透传缺口)', () async {
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
      expect(launcher.autoStart, isTrue, reason: '真战斗自动播放,点选随时干预');
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
