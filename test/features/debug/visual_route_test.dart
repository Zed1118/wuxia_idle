import 'dart:convert';
import 'dart:ffi';
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
  });

  // route 枚举 → buildVisualTarget → ScenarioLauncher 胶水回归。
  group('buildVisualTarget · 战斗静态验收路由透传', () {
    setUpAll(() async {
      await _initializeIsarCoreForFlutterTest();
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
      await _initializeIsarCoreForFlutterTest();
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

Future<void> _initializeIsarCoreForFlutterTest() async {
  await Isar.initializeIsarCore(
    libraries: {Abi.current(): _resolveBundledIsarCorePath()},
  );
}

String _resolveBundledIsarCorePath() {
  final packageConfigFile = File('.dart_tool/package_config.json');
  final packageConfigUri = packageConfigFile.absolute.uri;
  final packageConfig =
      jsonDecode(packageConfigFile.readAsStringSync()) as Map<String, dynamic>;
  final packages = packageConfig['packages'] as List<dynamic>;

  Uri? packageRootUri;
  for (final package in packages) {
    final packageMap = package as Map<String, dynamic>;
    if (packageMap['name'] == 'isar_community_flutter_libs') {
      final rootUri = Uri.parse(packageMap['rootUri'] as String);
      packageRootUri = rootUri.isAbsolute
          ? rootUri
          : packageConfigUri.resolveUri(rootUri);
      break;
    }
  }

  if (packageRootUri == null) {
    throw StateError('isar_community_flutter_libs not found in package config');
  }
  packageRootUri = packageRootUri.replace(
    path: packageRootUri.path.endsWith('/')
        ? packageRootUri.path
        : '${packageRootUri.path}/',
  );

  final libraryPath = switch (Abi.current()) {
    Abi.macosArm64 || Abi.macosX64 => 'macos/libisar.dylib',
    Abi.linuxX64 => 'linux/libisar.so',
    Abi.windowsX64 || Abi.windowsArm64 => 'windows/libisar.dll',
    _ => throw UnsupportedError('Unsupported Isar test ABI: ${Abi.current()}'),
  };
  final libraryFile = File.fromUri(packageRootUri.resolve(libraryPath));
  if (!libraryFile.existsSync()) {
    throw StateError('Bundled IsarCore library not found: ${libraryFile.path}');
  }
  return libraryFile.path;
}
