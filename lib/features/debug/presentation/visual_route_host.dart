import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import 'battle_test_menu.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../mainline/presentation/chapter_list_screen.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../onboarding/application/onboarding_service.dart';
import '../../sect/presentation/sect_screen.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../application/phase2_seed_service.dart';
import '../../battle/presentation/ultimate_caption_overlay.dart';
import '../application/visual_route.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../data/narrative_loader.dart';
import '../../mainline/domain/chapter_assets.dart';

/// 出版美术验收入口 App。
/// Task 4 直接 `runApp(VisualRouteApp(route: route))` 调用。
class VisualRouteApp extends StatelessWidget {
  const VisualRouteApp({super.key, required this.route});

  final VisualRoute route;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: UiStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: VisualRouteHost(route: route),
      ),
    );
  }
}

/// 按 [VisualRoute] 做 seed + 导航到目标验收屏。
/// 首帧就绪后打印 `VISUAL_ROUTE_READY: <id>` 供截图脚本 grep。
class VisualRouteHost extends ConsumerStatefulWidget {
  const VisualRouteHost({super.key, required this.route});

  final VisualRoute route;

  @override
  ConsumerState<VisualRouteHost> createState() => _VisualRouteHostState();
}

class _VisualRouteHostState extends ConsumerState<VisualRouteHost> {
  Widget? _target;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    try {
      // 1. 照 splash bootstrap:加载 defs + 初始化 Isar
      await GameRepository.loadAllDefs();
      await IsarSetup.init();
      final isar = IsarSetup.instance;

      // 2. 按 route seed + 选目标屏
      Widget target;
      switch (widget.route) {
        case VisualRoute.mainMenu:
          await OnboardingService(isar: isar).ensureFoundingMasters();
          target = const MainMenu();

        case VisualRoute.techniquePanelTierAll:
          await Phase2SeedService(isar: isar).seedVisualMasterAllTiers();
          target = const TechniquePanelScreen(characterId: 1);

        case VisualRoute.techniquePanelHero:
          await Phase2SeedService(isar: isar).seedRefineInsight();
          target = const TechniquePanelScreen(characterId: 1);

        case VisualRoute.sectScreenNpc:
          await Phase2SeedService(isar: isar).seedSectWithFullNpc();
          target = const SectScreen();

        case VisualRoute.characterPanelProfile:
          // seedMasterDisciple 已 _clearAll + 建祖师(id=1)+大/二弟子(带 portraitPath)
          // + 写 activeCharacterIds → 档案头立绘 + 3 Tab 切弟子立绘可验。
          await Phase2SeedService(isar: isar).seedMasterDisciple();
          target = const CharacterPanelScreen(characterId: 1);

        case VisualRoute.chapterList:
          // 章节封面条验收:任意 seed 即可(封面随 index 渲染,不依赖进度)。
          await OnboardingService(isar: isar).ensureFoundingMasters();
          target = const ChapterListScreen();

        case VisualRoute.battleScene:
          // 真实可自动播放的克制场景(scenarioB:左队稳胜)→ 自动推进到 leftWin →
          // VictoryOverlay 金「胜」仪式。背景用 citywall 验 scrim + 背景对位。
          target = const ScenarioLauncher(
            teamsFactory: BattleScenarioData.scenarioB,
            hint: '出版美术验收·战斗屏背景 scrim + 胜负仪式',
            sceneBackgroundPath: 'assets/scenes/battle_citywall.png',
          );

        case VisualRoute.battleUltimateCaption:
          target = const _UltimateCaptionPreview();

        case VisualRoute.battleBossFrame:
          target = const ScenarioLauncher(
            teamsFactory: BattleScenarioData.scenarioBoss,
            hint: '出版美术验收·Boss 头像金色加粗边框(右队首位)',
            sceneBackgroundPath: 'assets/scenes/battle_citywall.png',
          );

        case VisualRoute.narrativeScene:
          {
            // `--dart-define=VISUAL_STAGE=stage_04_03` 抽样任意主线关卡;
            // 未传默认 stage_01_05(风雨渡口)。加载真实开场正文压在对应背景图上。
            const envStage = String.fromEnvironment('VISUAL_STAGE');
            final stageId = envStage.isEmpty ? 'stage_01_05' : envStage;
            final opening = await NarrativeLoader.load('${stageId}_opening');
            target = NarrativeReaderScreen(
              content: opening,
              fallbackTitle: stageId,
              backgroundImagePath: stageNarrativePath(stageId),
            );
          }
      }

      // 3. 挂载目标屏
      if (!mounted) return;
      setState(() => _target = target);

      // 4. 目标屏首帧后打就绪信号
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('VISUAL_ROUTE_READY: ${widget.route.id}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      debugPrint('VISUAL_ROUTE_ERROR: ${widget.route.id} :: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text('VISUAL_ROUTE_ERROR: $_error'),
        ),
      );
    }
    return _target ??
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
  }
}

/// B2 题字静态验收:玩家暖金(上) + 敌方绛红(下)两态同屏,便于截图。
class _UltimateCaptionPreview extends StatelessWidget {
  const _UltimateCaptionPreview();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF14181D),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: UltimateCaptionContent(name: '天问归一', isEnemy: false)),
          Expanded(child: UltimateCaptionContent(name: '血煞噬魂', isEnemy: true)),
        ],
      ),
    );
  }
}
