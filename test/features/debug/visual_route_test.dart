import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
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
  });

  // 半手动 P0 步骤5 验收回归:补「route 枚举 → buildVisualTarget → ScenarioLauncher
  // 透传 manualStep/seed」这段胶水的盲区。既有 battle_manual_step_ui_test 8 测直接
  // new BattleScreen(manualStep:true),绕过了路由层;Codex 首轮验收 FAIL 的全部症状
  // (快进按钮 / 技能直接待发 / picker 不弹 / 冻结 seed)恰好等于相邻 battle_charge_break
  // 路由(manualStep 默认 false + autoStart:false)的表现,故锁两路由的关键 flag 区分。
  group('buildVisualTarget · 半手动 manualStep 路由透传', () {
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

    test('battle_manual_step → ScenarioLauncher 带 manualStep:true + seed:3', () async {
      final target = await buildVisualTarget(
        VisualRoute.battleManualStep,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.manualStep, isTrue, reason: '半手动单步入口必须 manualStep:true');
      expect(launcher.seed, 3, reason: 'manualStep 验收走固定 seed 确定性');
    });

    test('battle_charge_break → manualStep:false + autoStart:false(对照:不是单步)',
        () async {
      // 这是 Codex 首轮误验的相邻路由:静态冻结帧、非单步。锁住区分,防再次混淆。
      final target = await buildVisualTarget(
        VisualRoute.battleChargeBreak,
        IsarSetup.instance,
      );
      expect(target, isA<ScenarioLauncher>());
      final launcher = target as ScenarioLauncher;
      expect(launcher.manualStep, isFalse);
      expect(launcher.autoStart, isFalse);
    });
  });
}
