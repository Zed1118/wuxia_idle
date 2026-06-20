import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/presentation/hero_camera_overlay.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';
import 'package:wuxia_idle/features/debug/presentation/battle_test_menu.dart';
import 'package:wuxia_idle/features/debug/presentation/visual_route_host.dart';

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
    });

    test('未知 id → null', () {
      expect(parseVisualRoute('nope'), isNull);
    });

    test('空串 → null', () {
      expect(parseVisualRoute(''), isNull);
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
  });

  // route 枚举 → buildVisualTarget → ScenarioLauncher 胶水回归。
  group('buildVisualTarget · 战斗静态验收路由透传', () {
    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
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
    });

    test('battle_drag_live → allowPlayerIntervention:true + autoStart:true '
        '(拖招干预层必须挂,守 ScenarioLauncher 透传缺口)', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleDragLive,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.allowPlayerIntervention, isTrue,
          reason: '拖招验收路由必须开干预,否则技能按钮不挂拖手势(本次 FAIL 根因)');
      expect(launcher.autoStart, isTrue, reason: '真战斗自动播放,拖招随时干预');
    });

    test('battle_drag_preview → autoStart:false + debugDragPreview 预置 '
        '(拖招表现层静态验收;手势鼠标合成不出,守预置态透传)', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleDragPreview,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.autoStart, isFalse, reason: '冻结画面,蓄势光晕脉动常驻不被 tick 推掉');
      final preview = launcher.debugDragPreview;
      expect(preview, isNotNull, reason: '静态验收必须预置拖招态,否则截图无引导线/光晕');
      expect(preview!.rushActorId, 1, reason: '主控蓄势脉动');
      expect(preview.hoveredEnemyId, 11, reason: '敌 11 悬停浅金高亮');
    });
  });

  // 批一英雄镜头 preview：真数据(祖师 + 真 stage_01_05 Boss 名)接线回归。
  group('hero_camera preview · 真数据接线', () {
    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
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

    testWidgets('hero_camera → HeroCameraOverlay 弹出 + 祖师名号题字(真数据组装不抛异常)',
        (tester) async {
      final target = await buildVisualTarget(
        VisualRoute.heroCamera,
        IsarSetup.instance,
      );
      await tester.pumpWidget(MaterialApp(home: target));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(HeroCameraOverlay), findsOneWidget,
          reason: '专属路由必须弹英雄镜头 overlay,否则批一动效仍无法目检');
      expect(find.text('祖师'), findsOneWidget, reason: '出镜英雄名号取祖师占位名');
    });
  });
}
