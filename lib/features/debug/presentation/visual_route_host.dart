import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import 'battle_test_menu.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/isar_setup.dart';
import 'package:isar_community/isar.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../../shared/utils/rng.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../cultivation/presentation/advancement_summary.dart';
import '../../equipment/application/equipment_factory.dart';
import '../../equipment/application/drop_service.dart';
import '../../equipment/presentation/treasure_drop_overlay.dart';
import '../../equipment/domain/treasure_highlight.dart';
import '../../battle/application/stage_auto_play_pref.dart';
import '../../mainline/presentation/chapter_list_screen.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../mainline/presentation/stage_victory_dialog.dart';
import '../../mainline/presentation/stage_list_screen.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../onboarding/application/onboarding_service.dart';
import '../../sect/presentation/sect_screen.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../../tower/application/tower_progress_service.dart';
import '../../tower/domain/tower_progress.dart';
import '../../tower/presentation/tower_floor_list_screen.dart';
import '../../seclusion/domain/retreat_session.dart';
import '../../seclusion/presentation/active_retreat_screen.dart';
import '../../seclusion/presentation/retreat_result_screen.dart';
import '../../seclusion/presentation/seclusion_map_list_screen.dart';
import '../../seclusion/presentation/seclusion_setup_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../inventory/presentation/equipment_detail_screen.dart';
import '../application/phase2_seed_service.dart';
import '../../battle/presentation/ultimate_caption_overlay.dart';
import '../../battle/presentation/battle_scene_background.dart';
import '../../battle/presentation/victory_overlay.dart';
import '../application/visual_route.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../data/narrative_loader.dart';
import '../../mainline/domain/chapter_assets.dart';
import '../../battle/presentation/character_avatar.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../../battle/domain/battle_state.dart';
import '../../encounter/presentation/encounter_dialog.dart';

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
        builder: _wuxiaTextScaleBuilder,
        home: VisualRouteHost(route: route),
      ),
    );
  }
}

Widget _wuxiaTextScaleBuilder(BuildContext context, Widget? child) {
  final mediaQuery = MediaQuery.of(context);
  return MediaQuery(
    data: mediaQuery.copyWith(
      textScaler: const TextScaler.linear(WuxiaUi.textScale),
    ),
    child: child ?? const SizedBox.shrink(),
  );
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

      // 2. 按 route 构造目标屏(逻辑抽到顶层 buildVisualTarget,供 hub 运行时复用)
      final target = await buildVisualTarget(widget.route, isar);

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
      return Scaffold(body: Center(child: Text('VISUAL_ROUTE_ERROR: $_error')));
    }
    return _target ??
        const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// 单一职责:route → (seed + 目标屏)。供 [VisualRouteHost] 单路由直达与
/// [_AcceptanceHub] 运行时点选复用——后者 build 一次即可点遍全部路由,
/// 免 dart-define VISUAL_ROUTE 每路由重 flutter run(Codex 验收加速)。
Future<Widget> buildVisualTarget(VisualRoute route, Isar isar) async {
  switch (route) {
    case VisualRoute.mainMenu:
      await OnboardingService(isar: isar).ensureFoundingMasters();
      return const MainMenu();
    case VisualRoute.techniquePanelTierAll:
      await Phase2SeedService(isar: isar).seedVisualMasterAllTiers();
      return const TechniquePanelScreen(characterId: 1);
    case VisualRoute.techniquePanelHero:
      await Phase2SeedService(isar: isar).seedRefineInsight();
      return const TechniquePanelScreen(characterId: 1);
    case VisualRoute.techniqueRefineInsightDialog:
      return const _RefineInsightDialogPreview();
    case VisualRoute.encounterOutcomeSkillBanner:
      return const _EncounterOutcomeBannerPreview();
    case VisualRoute.sectScreenNpc:
      await Phase2SeedService(isar: isar).seedSectWithFullNpc();
      return const SectScreen();
    case VisualRoute.characterPanelProfile:
      await Phase2SeedService(
        isar: isar,
      ).seedMasterDiscipleWithMatureMainTechnique();
      return const CharacterPanelScreen(characterId: 1);
    case VisualRoute.characterPanelGrowth:
      await Phase2SeedService(isar: isar).seedCharacterPanelGrowth();
      return const CharacterPanelScreen(characterId: 1);
    case VisualRoute.chapterList:
      await OnboardingService(isar: isar).ensureFoundingMasters();
      return const ChapterListScreen();
    case VisualRoute.stageList:
      await isar.writeTxn(() => isar.mainlineProgress.clear());
      await Phase2SeedService(isar: isar).seedVisualCheckW7W11();
      return const StageListScreen(chapterIndex: 1);
    case VisualRoute.stageListAutoPlay:
      // per-stage「挂机自动 / 允许拖招」开关验收:01_01..04 已通关
      // (seedVisualCheckW7W11),01_01 跟随全局(自动随设置)、01_02 pin 允许拖招,
      // 让 Codex 看 toggle 三选项菜单 + 跟随 vs pin 两态。
      await isar.writeTxn(() => isar.mainlineProgress.clear());
      await Phase2SeedService(isar: isar).seedVisualCheckW7W11();
      final prefSvc = StageAutoPlayPrefService();
      await prefSvc.setOverride(stageBattleKey('stage_01_01'), null);
      await prefSvc.setOverride(stageBattleKey('stage_01_02'), false);
      return const StageListScreen(chapterIndex: 1);
    case VisualRoute.towerFloorList:
      await OnboardingService(isar: isar).ensureFoundingMasters();
      return const TowerFloorListScreen();
    case VisualRoute.towerFloorListAutoPlay:
      // per-floor「挂机自动 / 允许拖招」开关验收:种 1/2 层通关,点已通关层弹的
      // 重打 dialog 内开关:1 层跟随(自动随设置)、2 层 pin 允许拖招。
      await OnboardingService(isar: isar).ensureFoundingMasters();
      await isar.writeTxn(() => isar.towerProgress.clear());
      final towerSvc = TowerProgressService(isar: isar);
      await towerSvc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
      final towerNow = DateTime.now();
      await towerSvc.recordClear(floorIndex: 1, now: towerNow, elapsedMs: 60000);
      await towerSvc.recordClear(floorIndex: 2, now: towerNow, elapsedMs: 60000);
      final towerPrefSvc = StageAutoPlayPrefService();
      await towerPrefSvc.setOverride(towerBattleKey(1), null);
      await towerPrefSvc.setOverride(towerBattleKey(2), false);
      return const TowerFloorListScreen();
    case VisualRoute.seclusionMapList:
      await OnboardingService(isar: isar).ensureFoundingMasters();
      final def = GameRepository.instance.getSeclusionMap(
        RetreatMapType.cangJingGe,
      );
      final session = RetreatSession()
        ..saveDataId = IsarSetup.currentSlotId
        ..mapType = def.mapType
        ..durationHours = 4
        ..startedAt = DateTime.now().subtract(const Duration(minutes: 82))
        ..completedAt = null
        ..status = RetreatStatus.active
        ..actualRewards = [];
      await isar.writeTxn(() async {
        await isar.retreatSessions.clear();
        await isar.retreatSessions.put(session);
      });
      return const SeclusionMapListScreen(
        charRealmTier: RealmTier.erLiu,
        characterId: 1,
      );
    case VisualRoute.seclusionSetup:
      final def = GameRepository.instance.getSeclusionMap(
        RetreatMapType.xuanYaPuBu,
      );
      return SeclusionSetupScreen(
        mapDef: def,
        charRealmTier: RealmTier.zongShi,
        characterId: 1,
      );
    case VisualRoute.seclusionActive:
      final def = GameRepository.instance.getSeclusionMap(
        RetreatMapType.cangJingGe,
      );
      final session = RetreatSession()
        ..id = 1
        ..saveDataId = IsarSetup.currentSlotId
        ..mapType = def.mapType
        ..durationHours = 4
        ..startedAt = DateTime.now().subtract(const Duration(minutes: 96))
        ..completedAt = null
        ..status = RetreatStatus.active
        ..actualRewards = [];
      return ActiveRetreatScreen(
        session: session,
        mapDef: def,
        characterId: 1,
        charRealmTier: RealmTier.zongShi,
      );
    case VisualRoute.seclusionResult:
      final def = GameRepository.instance.getSeclusionMap(
        RetreatMapType.guJianZhong,
      );
      final tieJian = EquipmentFactory.fromDef(
        GameRepository.instance.getEquipment('weapon_xunchang_tie_jian'),
        rng: DefaultRng(seed: 606),
        obtainedAt: DateTime(2026, 6, 6),
        obtainedFrom: '闭关',
      );
      final result = (
        actualHours: 4.0,
        mojianshi: 18,
        equipmentDrops: <Equipment>[tieJian],
        experiencePoints: 520,
        techniqueLearnPoints: 6,
        internalForcePoints: 42,
        advancement: const AdvancementResult(
          layersGained: 1,
          tierBefore: RealmTier.sanLiu,
          layerBefore: RealmLayer.dengFeng,
          tierAfter: RealmTier.erLiu,
          layerAfter: RealmLayer.qiMeng,
          internalForceMaxBefore: 1800,
          internalForceMaxAfter: 2400,
        ),
      );
      return RetreatResultScreen(mapDef: def, result: result);
    case VisualRoute.battleScene:
      // hub 点选时无 VISUAL_SCENE → 默认 citywall;需指定 biome 仍可用单路由 dart-define。
      const envScene = String.fromEnvironment('VISUAL_SCENE');
      final sceneName = envScene.isEmpty ? 'citywall' : envScene;
      return ScenarioLauncher(
        teamsFactory: BattleScenarioData.scenarioB,
        hint: null,
        sceneBackgroundPath: 'assets/scenes/battle_$sceneName.png',
      );
    case VisualRoute.battleUltimateCaption:
      return const _UltimateCaptionPreview();
    case VisualRoute.battleBossFrame:
      return const ScenarioLauncher(
        teamsFactory: BattleScenarioData.scenarioBoss,
        hint: null,
        sceneBackgroundPath: WuxiaUi.battleBossEntranceBg,
      );
    case VisualRoute.battleChargeBreak:
      return const ScenarioLauncher(
        teamsFactory: BattleScenarioData.scenarioChargeBreak,
        hint: null,
        sceneBackgroundPath: WuxiaUi.battleBossEntranceBg,
        autoStart: false,
      );
    case VisualRoute.battleDragLive:
      // 拖招真玩/验收:真战斗 + 干预层挂上 + 高血耐久敌久撑(够时间拖)。
      return const ScenarioLauncher(
        teamsFactory: BattleScenarioData.scenarioDragLive,
        hint: '长按拖技能到敌人头像指定目标 · 点大招群体直发',
        sceneBackgroundPath: 'assets/scenes/battle_citywall.png',
        allowPlayerIntervention: true,
      );
    case VisualRoute.battleVictoryFirstClear:
      return const _VictoryFirstClearPreview();
    case VisualRoute.enemyGallery:
      return const _EnemyGallery();
    case VisualRoute.equipmentDetailScreen:
      final def = GameRepository.instance.getEquipment(
        'weapon_shenwu_tian_wen_jian',
      );
      final eq = Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime(2026, 6, 6),
        obtainedFrom: 'visual_route',
        baseAttack: def.baseAttackMin,
        baseHealth: def.baseHealthMin,
        baseSpeed: def.baseSpeedMin,
        enhanceLevel: 12,
        battleCount: 1240,
      )..id = 1;
      return EquipmentDetailScreen(equipment: eq, def: def);
    case VisualRoute.equipmentDetailGallery:
      return const _EquipmentDetailGallery();
    case VisualRoute.narrativeScene:
      const envStage = String.fromEnvironment('VISUAL_STAGE');
      final stageId = envStage.isEmpty ? 'stage_01_05' : envStage;
      final opening = await NarrativeLoader.load('${stageId}_opening');
      return NarrativeReaderScreen(
        content: opening,
        fallbackTitle: stageId,
        backgroundImagePath: stageNarrativePath(stageId),
      );
    case VisualRoute.inventory:
      await Phase2SeedService(isar: isar).seedInventoryShowcase();
      return const InventoryScreen();
    case VisualRoute.battleInterruptCaption:
      return const _InterruptCaptionPreview();
    case VisualRoute.battleDefeat:
      return const _DefeatCeremonyPreview();
    case VisualRoute.battleTreasureGlowPeak:
      return const _TreasureGlowPreview(
        defId: 'weapon_shenwu_tian_wen_jian',
        t: 0.32,
      );
    case VisualRoute.battleTreasureGlowRest:
      return const _TreasureGlowPreview(
        defId: 'weapon_shenwu_tian_wen_jian',
        t: 1.0,
      );
    case VisualRoute.battleTreasureZhongqi:
      return const _TreasureGlowPreview(
        defId: 'weapon_zhongqi_qing_xu_jian',
        t: 1.0,
      );
    case VisualRoute.stageListCycle:
      // 周目按章验收(Phase 2):整章 Ch1(含章末 Boss 01_05)cycle1 全通 →
      // clearedChapterCycleKeys 含 'ch1#1' → StageListScreen 章头(journey map
      // 下方)显 CycleSelectControl「回放第1周目 / 挑战第2周目」,选中态高亮。
      await isar.writeTxn(() => isar.mainlineProgress.clear());
      await Phase2SeedService(isar: isar).seedChapterCycleVisualCheck();
      return const StageListScreen(chapterIndex: 1);
    case VisualRoute.towerCycle:
      // 问鼎轮回验收:种 30 层 cycle1 全通关 → maxClearedCycle=1,显「挑战下一轮回」入口。
      await OnboardingService(isar: isar).ensureFoundingMasters();
      await isar.writeTxn(() => isar.towerProgress.clear());
      final towerSvc = TowerProgressService(isar: isar);
      await towerSvc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
      final towerNow = DateTime.now();
      for (var floor = 1; floor <= 30; floor++) {
        await towerSvc.recordClear(
          floorIndex: floor,
          now: towerNow,
          elapsedMs: 60000,
        );
      }
      return const TowerFloorListScreen();
    case VisualRoute.hub:
      return _AcceptanceHub(isar: isar);
  }
}

/// 验收总入口:build 一次,运行时点按钮 push 各路由目标屏,返回再点下一个。
/// 解决 dart-define VISUAL_ROUTE 编译期切换需每路由重 flutter run 的慢问题。
class _AcceptanceHub extends StatelessWidget {
  const _AcceptanceHub({required this.isar});

  final Isar isar;

  @override
  Widget build(BuildContext context) {
    final routes = VisualRoute.values
        .where((r) => r != VisualRoute.hub)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFF14181D),
      appBar: AppBar(title: Text('验收总入口 · ${routes.length} 路由(build 一次点选)')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: routes.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = routes[i];
          return ListTile(
            title: Text(
              r.id,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(r.label, style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final target = await buildVisualTarget(r, isar);
                navigator.push(MaterialPageRoute<void>(builder: (_) => target));
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('路由 ${r.id} 失败: $e')),
                );
              }
            },
          );
        },
      ),
    );
  }
}

/// 爆品金光视觉验收预览:固定动画时间轴 [t] 渲染「背景 + 暗幕 + 爆品内容 + 金光层」。
/// 复现 TreasureDropOverlay 真实叠加顺序但冻结在指定 t,便于单帧截图验金光强度 / tier-gate。
class _TreasureGlowPreview extends StatelessWidget {
  const _TreasureGlowPreview({required this.defId, required this.t});

  final String defId;
  final double t;

  @override
  Widget build(BuildContext context) {
    final def = GameRepository.instance.getEquipment(defId);
    final eq = EquipmentFactory.fromDef(
      def,
      rng: DefaultRng(seed: 612),
      obtainedAt: DateTime(2026, 6, 13),
      obtainedFrom: 'visual_treasure_glow',
    );
    final hl = TreasureHighlight(
      defId: def.id,
      name: def.name,
      tier: def.tier,
      slot: def.slot,
      iconPath: def.iconPath,
      attack: eq.baseAttack,
      health: eq.baseHealth,
      speed: eq.baseSpeed,
      tagline: def.tagline,
    );
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BattleSceneBackground(
            path: 'assets/scenes/battle_citywall.png',
          ),
          // 复现 overlay 半透明暗幕底
          const ColoredBox(color: Color(0xB3000000)),
          Positioned.fill(child: TreasureDropContent(highlight: hl, t: t)),
          Positioned.fill(child: TreasureGlowLayer(tier: hl.tier, t: t)),
        ],
      ),
    );
  }
}

class _VictoryFirstClearPreview extends StatelessWidget {
  const _VictoryFirstClearPreview();

  @override
  Widget build(BuildContext context) {
    final eq = EquipmentFactory.fromDef(
      GameRepository.instance.getEquipment('weapon_shenwu_tian_wen_jian'),
      rng: DefaultRng(seed: 607),
      obtainedAt: DateTime(2026, 6, 7),
      obtainedFrom: 'Boss 首胜',
    );
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BattleSceneBackground(
            path: 'assets/scenes/battle_citywall.png',
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.72,
                colors: [
                  WuxiaColors.background.withValues(alpha: 0.10),
                  WuxiaColors.background.withValues(alpha: 0.64),
                ],
              ),
            ),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _VictorySealMark(),
                    const SizedBox(height: 12),
                    AlertDialog(
                      title: const Text('風雨渡口 · 戰鬥勝利'),
                      content: StageVictoryContent(
                        firstClearTitle: UiStrings.stageVictoryBossFirstClear(
                          '风雨渡口',
                        ),
                        drops: DropResult(
                          equipments: [eq],
                          items: const [
                            ItemDropResult(
                              defId: 'item_mojianshi',
                              quantity: 8,
                            ),
                          ],
                        ),
                        advancements: const [
                          AdvancementEntry(
                            chName: '阴柔丙',
                            result: AdvancementResult(
                              layersGained: 1,
                              tierBefore: RealmTier.xueTu,
                              layerBefore: RealmLayer.qiMeng,
                              tierAfter: RealmTier.xueTu,
                              layerAfter: RealmLayer.ruMen,
                              internalForceMaxBefore: 500,
                              internalForceMaxAfter: 650,
                            ),
                          ),
                        ],
                        resonanceUpgrades: const [
                          ResonanceUpgradeNotice(
                            equipmentName: '天问剑',
                            newStage: ResonanceStage.moQi,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {},
                          child: const Text(UiStrings.stageVictoryConfirm),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VictorySealMark extends StatefulWidget {
  const _VictorySealMark();

  @override
  State<_VictorySealMark> createState() => _VictorySealMarkState();
}

class _VictorySealMarkState extends State<_VictorySealMark>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final introCurve = CurvedAnimation(
      parent: _intro,
      curve: Curves.easeOutCubic,
    );
    final breathCurve = CurvedAnimation(
      parent: _breath,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([introCurve, breathCurve]),
      builder: (context, child) {
        final intro = introCurve.value;
        final breath = breathCurve.value;
        return Opacity(
          opacity: intro.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - intro) * -18),
            child: Transform.scale(
              scale: 0.86 + intro * 0.14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: WuxiaUi.paper.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: WuxiaColors.popupCritical.withValues(
                          alpha: 0.64,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: WuxiaColors.resultHighlight.withValues(
                            alpha: 0.18 + breath * 0.08,
                          ),
                          blurRadius: 8 + breath * 5,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      '武',
                      style: TextStyle(
                        color: WuxiaColors.popupCritical,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Songti SC',
                        fontFamilyFallback: ['KaiTi', 'SimSun', 'serif'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(132, 112),
                        painter: _VictoryBrushAuraPainter(
                          alpha: 0.18 + breath * 0.08,
                        ),
                      ),
                      Transform.scale(
                        scale: 1 + breath * 0.025,
                        child: const Text(
                          '勝',
                          style: TextStyle(
                            color: WuxiaColors.resultHighlight,
                            fontSize: 96,
                            height: 0.92,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Songti SC',
                            fontFamilyFallback: ['KaiTi', 'SimSun', 'serif'],
                            shadows: [
                              Shadow(
                                color: Color(0xAA000000),
                                blurRadius: 16,
                                offset: Offset(0, 5),
                              ),
                              Shadow(color: Color(0x88B99A3B), blurRadius: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VictoryBrushAuraPainter extends CustomPainter {
  const _VictoryBrushAuraPainter({required this.alpha});

  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = WuxiaColors.resultHighlight.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.74,
      height: size.height * 0.72,
    );
    canvas.drawArc(rect, -0.42, 1.76, false, paint);
    canvas.drawArc(
      rect.inflate(8),
      2.48,
      1.34,
      false,
      paint..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _VictoryBrushAuraPainter oldDelegate) {
    return oldDelegate.alpha != alpha;
  }
}

class _RefineInsightDialogPreview extends StatelessWidget {
  const _RefineInsightDialogPreview();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Center(
        child: PaperDialog(
          title: UiStrings.refineInsightTitle,
          body: RefineInsightDialogBody(points: 50),
          actions: [
            PlaqueButton(label: UiStrings.commonCancel, onTap: null),
            PlaqueButton(
              label: UiStrings.refineInsightConfirm,
              primary: true,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _EncounterOutcomeBannerPreview extends StatelessWidget {
  const _EncounterOutcomeBannerPreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const EncounterOutcomeToast(
            title: UiStrings.encounterOutcomeSkillTitle,
            message: '领悟新招:听雨剑',
            icon: Icons.auto_awesome,
            color: WuxiaColors.resultHighlight,
          ),
        ),
      ),
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

/// B3 破招题字静态验收:破招方暖金「破！」+ 敌方绛红「破！」两态同屏。
/// 照 [_UltimateCaptionPreview] 体例,复用 [UltimateCaptionContent]。
class _InterruptCaptionPreview extends StatelessWidget {
  const _InterruptCaptionPreview();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF14181D),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: UltimateCaptionContent(
              name: UiStrings.interruptCaption,
              isEnemy: false,
            ),
          ),
          Expanded(
            child: UltimateCaptionContent(
              name: UiStrings.interruptCaption,
              isEnemy: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// B5 败北页静态验收:战场背景 + 径向暗角 + [VictoryOverlay] 战败态
/// (敗 大题字 + 败北 + 破招提示 + 战报)。照 [_VictoryFirstClearPreview] 体例,
/// onContinue no-op(纯静态截图)。
class _DefeatCeremonyPreview extends StatelessWidget {
  const _DefeatCeremonyPreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BattleSceneBackground(
            path: 'assets/scenes/battle_citywall.png',
          ),
          VictoryOverlay(
            result: BattleResult.rightWin,
            totalDamage: 18640,
            critCount: 7,
            totalTicks: 42,
            onContinue: () {},
          ),
        ],
      ),
    );
  }
}

/// 敌人立绘 gallery:枚举全 stageDefs 敌人(按 iconPath 去重),走生产
/// [StageBattleSetup.buildEnemyTeam] 真转换 → [CharacterAvatar] 圆形头像滚动,
/// 验全敌人图加载 + 圆形裁切 + 流派/Boss 边框(补 battle_scene 只 6 个的盲区)。
class _EnemyGallery extends StatelessWidget {
  const _EnemyGallery();

  @override
  Widget build(BuildContext context) {
    final repo = GameRepository.instance;
    final seen = <String>{};
    final chars = <BattleCharacter>[];
    for (final stage in repo.stageDefs.values) {
      for (final e in stage.enemyTeam) {
        if (e.iconPath.isEmpty || !seen.add(e.iconPath)) continue;
        chars.add(StageBattleSetup.buildEnemyTeam([e]).first);
      }
    }
    chars.sort((a, b) => (a.iconPath ?? '').compareTo(b.iconPath ?? ''));
    return Scaffold(
      backgroundColor: const Color(0xFF14181D),
      appBar: AppBar(title: Text('敌人立绘 gallery (${chars.length})')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: chars.length,
        itemBuilder: (_, i) => FittedBox(
          fit: BoxFit.scaleDown,
          child: CharacterAvatar(
            character: chars[i],
            avatarSize: 88,
            barWidth: 130,
          ),
        ),
      ),
    );
  }
}

/// 装备 detail gallery:枚举全 equipmentDefs 有 detailPath 的(按阶排序),
/// 同款 [Image.asset] contain 滚动,验全 detail 大图(含神物)加载 + 风格统一
/// (补 InventoryScreen 需持有装备才进得去详情的盲区)。
class _EquipmentDetailGallery extends StatelessWidget {
  const _EquipmentDetailGallery();

  @override
  Widget build(BuildContext context) {
    final repo = GameRepository.instance;
    final defs =
        repo.equipmentDefs.values
            .where((d) => d.detailPath != null && d.detailPath!.isNotEmpty)
            .toList()
          ..sort((a, b) {
            final t = a.tier.index.compareTo(b.tier.index);
            return t != 0 ? t : a.id.compareTo(b.id);
          });
    return Scaffold(
      backgroundColor: const Color(0xFF14181D),
      appBar: AppBar(title: Text('装备 detail gallery (${defs.length})')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: defs.length,
        itemBuilder: (_, i) {
          final d = defs[i];
          return Column(
            children: [
              Expanded(
                child: Image.asset(
                  d.detailPath!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFF22272E),
                    child: Center(child: Icon(Icons.broken_image, size: 32)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${d.id}\n${d.tier.name}',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          );
        },
      ),
    );
  }
}
