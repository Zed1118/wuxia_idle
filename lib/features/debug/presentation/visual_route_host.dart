import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import 'battle_test_menu.dart';
import 'redline_audit_screen.dart';
import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/isar_setup.dart';
import 'package:isar_community/isar.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_app_theme.dart';
import '../../../shared/widgets/wuxia_image.dart';
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
import '../../mainline/presentation/stage_entry_flow.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../onboarding/application/onboarding_service.dart';
import '../../onboarding/application/master_builder.dart';
import '../../lineage/presentation/disciple_join_overlay.dart';
import '../../sect/presentation/sect_screen.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../../tower/application/tower_progress_service.dart';
import '../../tower/domain/tower_progress.dart';
import '../../tower/presentation/tower_floor_list_screen.dart';
import '../../seclusion/domain/retreat_session.dart';
import '../../seclusion/domain/seclusion_map_def.dart';
import '../../seclusion/presentation/active_retreat_screen.dart';
import '../../seclusion/presentation/retreat_result_screen.dart';
import '../../seclusion/presentation/seclusion_map_list_screen.dart';
import '../../seclusion/presentation/seclusion_setup_screen.dart';
import '../../seclusion/presentation/offline_recap_card.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../inventory/presentation/equipment_detail_screen.dart';
import '../application/phase2_seed_service.dart';
import '../../battle/presentation/battle_screen.dart';
import '../../battle/presentation/ultimate_caption_overlay.dart';
import '../../battle/presentation/battle_scene_background.dart';
import '../../battle/presentation/victory_overlay.dart';
import '../../battle/domain/battle_diagnosis.dart';
import '../application/visual_route.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../data/narrative_loader.dart';
import '../../mainline/domain/chapter_assets.dart';
import '../../battle/presentation/character_avatar.dart';
import '../../battle/presentation/hero_camera_overlay.dart';
import '../../battle/domain/enum_localizations.dart' show EnumL10n;
import '../../battle/application/stage_battle_setup.dart';
import '../../battle/domain/battle_state.dart';
import '../../encounter/presentation/encounter_dialog.dart';
import '../../battle_record/domain/boss_memory.dart';
import '../../battle_record/domain/boss_memory_source.dart';
import '../../battle_record/application/boss_memory_service.dart';
import '../../battle_record/presentation/battle_record_screen.dart';
import '../../battle_record/presentation/boss_memory_detail_screen.dart';
import '../../weapon_codex/application/equipment_catalog_providers.dart';
import '../../weapon_codex/domain/equipment_catalog_entry.dart';
import '../../weapon_codex/presentation/weapon_codex_screen.dart';
import '../../weapon_codex/presentation/equipment_catalog_detail_screen.dart';
import '../../shop/presentation/shop_screen.dart';
import '../../../core/domain/inventory_item.dart';
import '../../character_panel/application/lineage_codex_provider.dart';
import '../../character_panel/presentation/lineage_panel_screen.dart';
import '../../baike/application/encounter_codex_provider.dart';
import '../../baike/presentation/encounter_tab.dart';
import '../../baike/presentation/encounter_detail_screen.dart';
import '../../baike/application/martial_codex_provider.dart';
import '../../baike/presentation/martial_arts_tab.dart';
import '../../baike/presentation/skill_codex_detail_screen.dart';
import '../../character_panel/presentation/lineage_character_detail_screen.dart';
import '../../zangjuange/presentation/zangjuange_screen.dart';
import '../../taohua_island/presentation/taohua_island_screen.dart';
import '../../recruitment/presentation/recruitment_dialog.dart';
import 'hitbox_debug_overlay.dart';

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
        theme: wuxiaAppTheme(),
        builder: _wuxiaTextScaleBuilder,
        home: HitboxDebugOverlay.maybeWrap(VisualRouteHost(route: route)),
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
        const Scaffold(body: Center(child: InkLoadingIndicator()));
  }
}

/// 单一职责:route → (seed + 目标屏)。供 [VisualRouteHost] 单路由直达与
/// [_AcceptanceHub] 运行时点选复用——后者 build 一次即可点遍全部路由,
/// 免 dart-define VISUAL_ROUTE 每路由重 flutter run(Codex 验收加速)。
Future<Widget> buildVisualTarget(VisualRoute route, Isar isar) async {
  switch (route) {
    case VisualRoute.mainMenu:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
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
      // 验收意图=门派成员立绘,直达「成员」tab(index 2),否则默认停在空事件态。
      return const SectScreen(initialTabIndex: 2);
    case VisualRoute.characterPanelProfile:
      await Phase2SeedService(
        isar: isar,
      ).seedMasterDiscipleWithMatureMainTechnique();
      return const CharacterPanelScreen(characterId: 1);
    case VisualRoute.characterPanelGrowth:
      await Phase2SeedService(isar: isar).seedCharacterPanelGrowth();
      return const CharacterPanelScreen(characterId: 1);
    case VisualRoute.chapterList:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
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
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      return const TowerFloorListScreen();
    case VisualRoute.towerFloorListAutoPlay:
      // per-floor「挂机自动 / 允许拖招」开关验收:种 1/2 层通关,点已通关层弹的
      // 重打 dialog 内开关:1 层跟随(自动随设置)、2 层 pin 允许拖招。
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      await isar.writeTxn(() => isar.towerProgress.clear());
      final towerSvc = TowerProgressService(isar: isar);
      await towerSvc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
      final towerNow = DateTime.now();
      await towerSvc.recordClear(
        floorIndex: 1,
        now: towerNow,
        elapsedMs: 60000,
      );
      await towerSvc.recordClear(
        floorIndex: 2,
        now: towerNow,
        elapsedMs: 60000,
      );
      final towerPrefSvc = StageAutoPlayPrefService();
      await towerPrefSvc.setOverride(towerBattleKey(1), null);
      await towerPrefSvc.setOverride(towerBattleKey(2), false);
      return const TowerFloorListScreen();
    case VisualRoute.seclusionMapList:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
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
      final note = def.eventNotes.first;
      final result = (
        actualHours: 4.0,
        mojianshi: 18,
        silver: 20,
        itemRewards: const <String, int>{},
        equipmentDrops: <Equipment>[tieJian],
        experiencePoints: 520,
        techniqueLearnPoints: 6,
        internalForcePoints: 42,
        routeSteps: def.routeSteps,
        mapEvents: [
          RetreatMapEventRecord(
            hourMark: note.triggerAfterHours,
            kind: note.kind,
            text: note.text,
          ),
        ],
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
        hint: '长按拖技能下发:单体拖到敌头像指定 · 群体技拖动松手即对全体触发 · 已暂停,点单步推进或继续自动',
        sceneBackgroundPath: 'assets/scenes/battle_citywall.png',
        allowPlayerIntervention: true,
        startPaused: true,
      );
    case VisualRoute.battleDragPreview:
      // 拖招表现层静态验收:冻结画面(autoStart false)预置引导线 + 蓄势光晕 + 悬停高亮,
      // 给 Codex 截新样式(手势鼠标合成无法触发)。主控(id1 绛红刚猛)蓄势/起手,敌 11 悬停。
      return const ScenarioLauncher(
        teamsFactory: BattleScenarioData.scenarioDragLive,
        hint: '拖招表现层静态预置(引导线 / 蓄势脉动 / 悬停高亮)',
        sceneBackgroundPath: 'assets/scenes/battle_citywall.png',
        autoStart: false,
        debugDragPreview: BattleDragPreview(
          dragCharId: 1,
          rushActorId: 1,
          hoveredEnemyId: 11,
          origin: Offset(360, 600),
          pointer: Offset(980, 230),
        ),
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
    case VisualRoute.defeatInnerDemonResidue:
      return const _InnerDemonResidueDefeatPreview();
    case VisualRoute.offlineRecapPassive:
      return const _OfflineRecapPassivePreview();
    case VisualRoute.battleBossPhase:
      // 第七阶段批二目检:真 stage_01_05 Boss(HP抬高给两阶段步数)vs 压低 DPS 玩家队。
      // **startPaused 起手暂停**:用顶栏「单步」逐拍推进,每步看清会心/转阶段/蓄力反扑动效
      // (也可点「继续自动」放掉无聊段);已开干预层可长按拖技能。
      return const ScenarioLauncher(
        teamsFactory: BattleScenarioData.scenarioBossPhase,
        hint:
            '已暂停。点顶栏「单步」逐拍推进:刚猛打 Boss 出「会心」(弱点×1.25)、灵巧伤害偏低(抗性×0.75)、Boss 半血触发「背水一击」转阶段 + 蓄力反扑。也可点继续自动 / 长按拖技能干预',
        sceneBackgroundPath: WuxiaUi.battleBossEntranceBg,
        allowPlayerIntervention: true,
        startPaused: true,
      );
    case VisualRoute.discipleJoinCeremony:
      // 第七阶段批三目检:拜入立绘题字 overlay 动效。读真 lineage_onboarding 配置,
      // 大弟子/二弟子真立绘交替循环重播(GameRepository 已在 _prepare 加载完)。
      return const _DiscipleJoinPreview();
    case VisualRoute.heroCamera:
      // 第七阶段批一目检:Boss 首胜英雄镜头 overlay 动效。生产仅 Boss 首胜触发
      // (stage_entry_flow / tower_entry_flow),老档已通关不重触发 → 走此专属路由
      // 用真数据(祖师立绘 + 真 stage_01_05 Boss 名)组 HeroCameraData 自动循环重播。
      return const _HeroCameraPreview();
    case VisualRoute.battleRecord:
      // P4 战绩册主屏目检:种 3 条 BossMemory(2 完整 + 1 pre-record),
      // 其余 27 槽由 BattleRecordScreen 从 bossCatalogProvider 读出显剩影占位。
      final svc = BossMemoryService(isar: isar);
      final now = DateTime(2026, 6, 19);
      // 完整纪念 1：主线 stage_01_05 风雨渡口 Boss（刚猛队首胜）
      await svc.recordBossVictory(
        saveDataId: IsarSetup.currentSlotId,
        bossKey: 'stage_01_05',
        source: BossMemorySource.mainline,
        groupIndex: 5,
        bossName: '撑伞高人',
        totalDamage: 43280,
        critCount: 12,
        totalTicks: 38,
        topContributorName: '萧远山',
        topContributorDamage: 18540,
        treasureName: '天问剑',
        treasureTier: EquipmentTier.shenWu,
        rosterNames: ['萧远山', '阿朱', '玄冥二老'],
        rosterPortraits: const [],
        now: now,
      );
      // 完整纪念 2：爬塔 10 层（爬塔 Boss 首胜）
      await svc.recordBossVictory(
        saveDataId: IsarSetup.currentSlotId,
        bossKey: 'tower_floor_10',
        source: BossMemorySource.tower,
        groupIndex: 10,
        bossName: '铁掌帮帮主',
        totalDamage: 28910,
        critCount: 7,
        totalTicks: 24,
        topContributorName: '阿朱',
        topContributorDamage: 11320,
        treasureName: '铁掌护甲',
        treasureTier: EquipmentTier.liQi,
        rosterNames: ['萧远山', '阿朱'],
        rosterPortraits: const [],
        now: now.subtract(const Duration(days: 3)),
      );
      // pre-record 骨架：爬塔 5 层（模拟本功能上线前老档回填）
      await isar.writeTxn(() async {
        final m = BossMemory()
          ..saveDataId = IsarSetup.currentSlotId
          ..bossKey = 'tower_floor_5'
          ..source = BossMemorySource.tower
          ..groupIndex = 5
          ..bossName = '白驼山悍匪'
          ..firstClearedAt = null
          ..isPreRecord = true
          ..rosterNames = const []
          ..rosterPortraits = const []
          ..defeatCount = 1;
        await isar.bossMemorys.put(m);
      });
      return const BattleRecordScreen();
    case VisualRoute.bossMemoryDetail:
      // P4 战绩册详情屏目检:完整 + pre-record 两态并排（上下各半）。
      return const _BossMemoryDetailPreview();
    case VisualRoute.weaponCodex:
      // 兵器谱主屏混合态目检：注入混合 entries（4 件点亮跨 tier + 1 件回填骨架），
      // 其余大量 def 不在 entries 里（= 未获得剪影），验点亮/回填/剪影三态混排 + 进度。
      return _buildWeaponCodexVisual();
    case VisualRoute.weaponCodexDetail:
      // 兵器谱详情屏正常态目检：挑一件有 schoolBias 的典型 def + 正常态 entry。
      return _buildWeaponCodexDetailVisual();
    case VisualRoute.lineageCodex:
      // 门派谱主屏世代卷目检：注入假世代（祖师 + 大/二弟子 + 1 件师承遗物），
      // 覆盖 lineageCodexProvider，验进度头 + 祖师卡 + 门人 + 遗物 + 屏底飞升入口。
      return _buildLineageCodexVisual();
    case VisualRoute.lineageCharacterDetail:
      // 门派谱角色详情屏祖师态目检：种祖师 Character 直传 detail 屏。
      // 主修/遗物段 watch 真 provider（host 内 GameRepository 已加载、真 Isar 存在），
      // 祖师恩泽段在 isLoaded && buff.isActive 时渲染（两者 host 内均真）。
      return _buildLineageCharacterDetailVisual();
    case VisualRoute.shop:
      // 江湖商店主屏目检:种银两 80(够买磨剑石 30 两件·不够心血结晶 120),
      // 验货币顶栏 + 固定货架 + 可买(绿)/不可买(红 disabled)两态同屏。
      await _seedInventoryItem(isar, 'item_silver', 80);
      return const ShopScreen();
    case VisualRoute.inventoryCurrency:
      // 背包货币位目检:种银两 + 磨剑石 + 心血结晶,initialTab=1 直开物料 tab,
      // 验顶部货币位顶栏 + 材料网格(银两不重复进网格,仅磨剑石/心血结晶)。
      await _seedInventoryItem(isar, 'item_silver', 360);
      await _seedInventoryItem(isar, 'item_mojianshi', 24);
      await _seedInventoryItem(isar, 'item_xinxuejiejing', 6);
      return const InventoryScreen(initialTab: 1);
    case VisualRoute.mainMenuShop:
      // 主菜单商店入口目检:种银两解锁商店 → 验「江湖商店」隐藏式入口木牌出现(§5.7)。
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      await _seedInventoryItem(isar, 'item_silver', 200);
      return const MainMenu();
    case VisualRoute.itemUseInventory:
      // P2 材料用途目检:建祖师(经验丹 applyExperience / 秘籍 markUnlocked 需 founder
      // + SaveData 真目标,否则结果浮层走 noTarget) + 种经验丹三档 + 秘籍 + 磨剑石,
      // initialTab=1 直开物料 tab。验:三档丹 per-item 名(凝神/培元/大还)不同 +
      // 秘籍名(开碑手·秘籍) + 丹/秘籍显「使用」按钮 / 磨剑石无按钮(仅可用道具显);
      // 运行时点「使用」→PaperDialog 确认→结果三态浮层(经验入账/秘籍解锁/已知晓)。
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      await _seedInventoryItem(isar, 'item_jingyandan_small', 3);
      await _seedInventoryItem(isar, 'item_jingyandan_mid', 2);
      await _seedInventoryItem(isar, 'item_jingyandan_large', 1);
      await _seedInventoryItem(isar, 'item_scroll_kai_bei_shou', 1);
      await _seedInventoryItem(isar, 'item_mojianshi', 12);
      return const InventoryScreen(initialTab: 1);
    case VisualRoute.taohuaIsland:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      await _seedInventoryItem(isar, 'item_silver', 260);
      await _seedInventoryItem(isar, 'item_mojianshi', 90);
      await _seedInventoryItem(isar, 'item_xinxuejiejing', 12);
      await _seedInventoryItem(isar, 'item_jingtie', 60);
      await _seedInventoryItem(isar, 'item_yaocao', 60);
      await _seedInventoryItem(isar, 'item_mucai', 60);
      await _seedInventoryItem(isar, 'item_lingquanshui', 60);
      return const TaohuaIslandScreen();
    case VisualRoute.recruitmentDialog:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      return const RecruitmentDialog();
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
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
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
    case VisualRoute.encounterCodex:
      // 奇遇录 tab 混合态目检：前 2 条 def 标已际遇(带标题)、其余剪影,
      // 覆盖 encounterCodexProvider,验点亮/剪影 3 段分组 + 段内已际遇计数。
      return _buildEncounterCodexVisual();
    case VisualRoute.encounterCodexDetail:
      // 奇遇录详情屏目检：取一条真 def 直传 detail,回看 opening 故事 + 类型标。
      return _buildEncounterCodexDetailVisual();
    case VisualRoute.skillCodex:
      // 武学图鉴 tab 混合态目检：前 6 招点亮、其余剪影,覆盖 martialCodexProvider,
      // 验点亮/剪影 5 来源分组 + 心法小节 + 进度。
      return _buildSkillCodexVisual();
    case VisualRoute.skillCodexDetail:
      // 武学详情屏目检：取收录池首招直传 detail 屏(同步展示,maxStage=null 未曾习练态)。
      return _buildSkillCodexDetailVisual();
    case VisualRoute.zangjuange:
      return const ZangjuangeScreen();
    case VisualRoute.redlineAudit:
      return const RedlineAuditScreen();
    case VisualRoute.hub:
      return _AcceptanceHub(isar: isar);
  }
}

/// 奇遇录 tab 混合态：注入前 2 条已际遇(带标题)+ 其余剪影,覆盖 [encounterCodexProvider]。
/// 走真 [groupEncounters] 纯函数分 3 段,验段标/进度/点亮-剪影混排。
/// debug fixture,中文内联照 host 现有 preview 体例。
Widget _buildEncounterCodexVisual() {
  final defs = GameRepository.instance.allEncounters;
  final triggered = defs.take(2).map((d) => d.id).toSet();
  final titles = {for (final d in defs.take(2)) d.id: '（已际遇）${d.id}'};
  final groups = groupEncounters(
    defs: defs,
    triggeredIds: triggered,
    titles: titles,
  );
  return ProviderScope(
    overrides: [encounterCodexProvider.overrideWith((ref) async => groups)],
    child: const Scaffold(body: EncounterTab()),
  );
}

/// 奇遇录详情屏:取首条真 def 直传 [EncounterDetailScreen](opening 由屏内 async 读 yaml)。
Widget _buildEncounterCodexDetailVisual() {
  final def = GameRepository.instance.allEncounters.first;
  return EncounterDetailScreen(def: def);
}

/// 武学图鉴 tab 混合态：注入前 6 招已点亮 + 其余剪影,覆盖 [martialCodexProvider]。
/// 走真 [groupMartialSkills] 纯函数分 5 来源段,验段标/小节/进度/点亮-剪影混排。
/// debug fixture,中文内联照 host 现有 preview 体例。
Widget _buildSkillCodexVisual() {
  final repo = GameRepository.instance;
  final pool = repo.skillDefs.values.where(isMartialCodexSkill).toList();
  final litIds = pool.take(6).map((d) => d.id).toSet();
  final groups = groupMartialSkills(
    pool: pool,
    litIds: litIds,
    stageById: const {},
    techDefsById: repo.techniqueDefs,
  );
  return ProviderScope(
    overrides: [martialCodexProvider.overrideWith((ref) async => groups)],
    child: const Scaffold(body: MartialArtsTab()),
  );
}

/// 武学详情屏:取收录池首招直传 [SkillCodexDetailScreen](同步展示,maxStage=null 未曾习练态)。
Widget _buildSkillCodexDetailVisual() {
  final repo = GameRepository.instance;
  final def = repo.skillDefs.values.firstWhere(isMartialCodexSkill);
  return SkillCodexDetailScreen(def: def, maxStage: null);
}

/// 材料经济 P1 验收 seed:upsert 一行 [InventoryItem](复用 [ItemType.fromDefId]
/// 真映射,银两走 item_silver→ItemType.silver 同生产入库路径)。已有同 defId 行
/// (hub 重复点选/同 db 多跑)则复用 id 覆盖数量,不撞 unique defId 索引。
Future<void> _seedInventoryItem(Isar isar, String defId, int quantity) async {
  final now = DateTime(2026, 6, 21);
  await isar.writeTxn(() async {
    final existing = await isar.inventoryItems.getByDefId(defId);
    final item = existing ?? InventoryItem();
    item
      ..defId = defId
      ..itemType = ItemType.fromDefId(defId)
      ..quantity = quantity
      ..firstObtainedAt = existing?.firstObtainedAt ?? now
      ..lastObtainedAt = now;
    await isar.inventoryItems.put(item);
  });
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
          Positioned.fill(
            child: TreasureDropContent(highlight: hl, t: t),
          ),
          Positioned.fill(
            child: TreasureGlowLayer(tier: hl.tier, t: t),
          ),
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
                              Shadow(
                                color: WuxiaColors.visualGoldShadow,
                                blurRadius: 14,
                              ),
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
    // 居中仪式浮层真实形态:暗幕 + 放大装帧 CeremonyImagePanel(去掉旧
    // maxWidth:520 假约束,改由 EncounterOutcomeToast 自身 maxWidth:420 收窄)。
    // 静态验收用 onDone no-op,让浮层停在末态供截图。
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: EncounterOutcomeOverlay(
        title: UiStrings.encounterOutcomeSkillTitle,
        message: '领悟新招:听雨剑',
        icon: Icons.auto_awesome,
        color: WuxiaColors.resultHighlight,
        onDone: () {},
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

/// M2 离线被动归来卡静态验收:无 active 闭关时的涓流入库告知卡
/// ([OfflineRecapCard.passive])。纯静态(card 无副作用、文案走 UiStrings),
/// 居中浮于水墨底,模拟弹窗态。onDismiss no-op(纯截图)。
/// 数值取被动 25% 涓流 ~8h 量级示意,纯展示不参与结算。
class _OfflineRecapPassivePreview extends StatelessWidget {
  const _OfflineRecapPassivePreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Center(
        child: OfflineRecapCard.passive(
          mojianshi: 120,
          experience: 860,
          awayHours: 8.0,
          settledHours: 8.0,
          isCapped: false,
          onDismiss: () {},
        ),
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
            diagnosis: const BattleDiagnosis(
              ruleId: 'killed_by_charge',
              shortfall: DefeatShortfall.technique,
              primaryCause: '被 Boss 蓄力大招击溃',
              dataLines: ['致命一击：摧心掌 720', '内力余量：180/500'],
              suggestions: [
                DiagnosisSuggestion('保留内力、装配破招技。', DiagnosisJumpTarget.skills),
              ],
            ),
            onJump: (_) {},
            onContinue: () {},
          ),
        ],
      ),
    );
  }
}

/// M6 心魔关战败损失摘要·余毒未消段排版静态验收。
/// 复用真实 [NarrativeReaderScreen] + topBanner 渲染路径(战败剧情屏顶 banner),
/// 以两条样例余毒 entry 还原排版:第 1 条含主修(内力段·修炼度回退段·余毒未消段
/// 三段拼接=最长行,验换行),第 2 条仅内力+余毒未消。样例为 debug fixture,
/// 同 [_DefeatCeremonyPreview] 内联中文体例。
class _InnerDemonResidueDefeatPreview extends StatelessWidget {
  const _InnerDemonResidueDefeatPreview();

  @override
  Widget build(BuildContext context) {
    return NarrativeReaderScreen(
      content: const NarrativeContent(
        id: 'visual_inner_demon_defeat',
        title: '心魔反噬',
        paragraphs: ['你一时心神动摇,为心魔所乘。功体受损,一缕余毒缠身,需闭关静养方能涤净。'],
        isPlaceholder: false,
        mandatory: true,
      ),
      fallbackTitle: '心魔反噬',
      topBanner: buildDefeatLossBanner(const [
        DefeatLossEntry(
          characterName: '萧远山',
          internalForceBefore: 1480,
          internalForceAfter: 1258,
          techniqueName: '伏魔禅功',
          residueApplied: true,
        ),
        DefeatLossEntry(
          characterName: '阿朱',
          internalForceBefore: 760,
          internalForceAfter: 646,
          residueApplied: true,
        ),
      ]),
      backgroundImagePath: 'assets/scenes/battle_citywall.png',
    );
  }
}

/// 第七阶段批三目检·拜入立绘题字 overlay 动效预览。
/// 真 [DiscipleJoinOverlay] 叠在战场背景上,读 `lineage_onboarding.disciple_joins`
/// 真配置(masterSlotIndex → masters 立绘 + [defaultMasterName] 题字),大弟子/二弟子
/// 交替循环滑入(overlay onDone → 短暂停 → 切下一位换 key 重播),便于真机连看两段动效。
/// 纯展示:不碰 BattleState / 不建弟子 / 不写 Isar(配置只读)。
class _DiscipleJoinPreview extends StatefulWidget {
  const _DiscipleJoinPreview();

  @override
  State<_DiscipleJoinPreview> createState() => _DiscipleJoinPreviewState();
}

class _DiscipleJoinPreviewState extends State<_DiscipleJoinPreview> {
  late final List<({String portrait, String caption})> _entries;
  int _index = 0;
  int _replay = 0; // 递增作 key 种子,强制 overlay 重建重播动效
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    final repo = GameRepository.instance;
    final masters = repo.masters;
    _entries = [
      for (final j in repo.numbers.lineageOnboarding.discipleJoins)
        if (j.masterSlotIndex < masters.length)
          (
            portrait: masters[j.masterSlotIndex].portraitPath ?? '',
            caption: UiStrings.discipleJoinCaption(
              defaultMasterName(masters[j.masterSlotIndex]),
            ),
          ),
    ];
  }

  void _next() {
    if (_switching || _entries.isEmpty) return;
    _switching = true;
    // 短暂停后切下一位(单条配置则原地重播),换 key 触发滑入动效重跑。
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _entries.length;
        _replay++;
        _switching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return const Scaffold(
        backgroundColor: WuxiaColors.background,
        body: Center(
          child: Text('无拜入配置(lineage_onboarding.disciple_joins 为空)'),
        ),
      );
    }
    final e = _entries[_index];
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BattleSceneBackground(
            path: 'assets/scenes/battle_citywall.png',
          ),
          DiscipleJoinOverlay(
            key: ValueKey('disciple_join_$_replay'),
            portraitPath: e.portrait,
            caption: e.caption,
            onDone: _next,
          ),
        ],
      ),
    );
  }
}

/// 第七阶段批一目检:Boss 首胜英雄镜头 overlay 动效(对称 [_DiscipleJoinPreview])。
///
/// 英雄镜头生产仅在 Boss 首胜触发(stage_entry_flow / tower_entry_flow,gate
/// `isBoss && isFirstClear`),老档 Boss 已通关不会重触发 → 单帧也截不出滑入+放大
/// 运动,故走此专属路由。用真数据组 [HeroCameraData]:祖师立绘/名号/境界 +
/// 真 stage_01_05 章末 Boss 名,自动循环重播看动效。
class _HeroCameraPreview extends StatefulWidget {
  const _HeroCameraPreview();

  @override
  State<_HeroCameraPreview> createState() => _HeroCameraPreviewState();
}

class _HeroCameraPreviewState extends State<_HeroCameraPreview> {
  HeroCameraData? _data;
  int _replay = 0; // 递增作 key 种子,强制 overlay 重建重播滑入动效。
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    final repo = GameRepository.instance;
    final masters = repo.masters;
    if (masters.isEmpty) return;
    // 祖师(slot 0)作出镜英雄:真立绘 + 占位名号 + 开局境界(学徒,与 Ch1 章末 Boss 同阶)。
    final founder = masters.first;
    // 真 stage_01_05 章末 Boss(slot 0)名,经生产 buildEnemyTeam 转换取显示名。
    final stage = repo.getStage('stage_01_05');
    final boss = StageBattleSetup.buildEnemyTeam(stage.enemyTeam).first;
    _data = HeroCameraData(
      portraitPath: founder.portraitPath,
      heroName: defaultMasterName(founder),
      realmLabel: EnumL10n.realmTier(founder.defaultRealm),
      bossName: boss.name,
      // 代表性出镜伤害值(仅 debug 展示验题字排版,不参战;Ch1 章末量级)。
      topDamage: 4800,
    );
  }

  void _next() {
    if (_switching || _data == null) return;
    _switching = true;
    // 短暂停后换 key 触发滑入动效重跑(单英雄→原地重播,对称 _DiscipleJoinPreview)。
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _replay++;
        _switching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const Scaffold(
        backgroundColor: WuxiaColors.background,
        body: Center(child: Text('无祖师配置(masters 为空)')),
      );
    }
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BattleSceneBackground(
            path: 'assets/scenes/battle_citywall.png',
          ),
          HeroCameraOverlay(
            key: ValueKey('hero_camera_$_replay'),
            data: data,
            onDone: _next,
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
                child: WuxiaImage(
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

/// P4 战绩册详情屏两态预览：完整纪念（上半）+ pre-record 骨架（下半）并排。
///
/// 完整态：totalDamage/critCount/totalTicks/topContributor/treasure/rosterNames 全填。
/// pre-record 态：isPreRecord=true，战绩数字区整块替换为「此役不详·记录之前」。
/// 纯 debug fixture，中文内联照 host 现有 preview 体例（合法，不算散写）。
class _BossMemoryDetailPreview extends StatelessWidget {
  const _BossMemoryDetailPreview();

  @override
  Widget build(BuildContext context) {
    // 完整纪念 fixture
    final full = BossMemory()
      ..id = 1
      ..saveDataId = 1
      ..bossKey = 'stage_01_05'
      ..source = BossMemorySource.mainline
      ..groupIndex = 5
      ..bossName = '撑伞高人'
      ..firstClearedAt = DateTime(2026, 6, 19)
      ..isPreRecord = false
      ..totalDamage = 43280
      ..critCount = 12
      ..totalTicks = 38
      ..topContributorName = '萧远山'
      ..topContributorDamage = 18540
      ..treasureName = '天问剑'
      ..treasureTier = EquipmentTier.shenWu
      ..rosterNames = ['萧远山', '阿朱', '玄冥二老']
      ..rosterPortraits = const []
      ..defeatCount = 3;

    // pre-record 骨架 fixture（老档回填，战绩不详）
    final pre = BossMemory()
      ..id = 2
      ..saveDataId = 1
      ..bossKey = 'tower_floor_5'
      ..source = BossMemorySource.tower
      ..groupIndex = 5
      ..bossName = '白驼山悍匪'
      ..firstClearedAt = null
      ..isPreRecord = true
      ..rosterNames = const []
      ..rosterPortraits = const []
      ..defeatCount = 1;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Column(
        children: [
          // 上半：完整纪念
          Expanded(child: BossMemoryDetailScreen(memory: full)),
          const Divider(height: 2, thickness: 2, color: WuxiaColors.textMuted),
          // 下半：pre-record 骨架
          Expanded(child: BossMemoryDetailScreen(memory: pre)),
        ],
      ),
    );
  }
}

/// 兵器谱主屏混合态：注入假 entries，覆盖 [equipmentCatalogListProvider]。
///
/// 混合态说明：
///   - 4 件点亮（取 values 前 4 件，尽量跨不同 tier）
///       - 3 件正常态（firstObtainedAt 非 null + firstObtainedFrom='黑风寨之战'，obtainedCount 1~3）
///       - 1 件 pre-record 回填骨架（isPreRecord=true / firstObtainedAt=null）
///   - 其余 def 不在 entries 里 → WeaponCodexScreen 渲染为剪影占位
/// GameRepository 已在 _prepare 加载（无需额外 isar）。
Widget _buildWeaponCodexVisual() {
  final defs = GameRepository.instance.equipmentDefs.values.toList();
  // 取前 4 件 def 构造 entries（至少 1 件回填，其余正常态）
  final seed = defs.take(4).toList();
  final now = DateTime(2026, 6, 20);
  int idCounter = 1;

  final entries = <EquipmentCatalogEntry>[
    // 正常态 1
    EquipmentCatalogEntry()
      ..id = idCounter++
      ..saveDataId = 1
      ..defId = seed[0].id
      ..firstObtainedAt = now.subtract(const Duration(days: 12))
      ..firstObtainedFrom = '黑风寨之战'
      ..obtainedCount = 2
      ..isPreRecord = false,
    // 正常态 2
    if (seed.length > 1)
      EquipmentCatalogEntry()
        ..id = idCounter++
        ..saveDataId = 1
        ..defId = seed[1].id
        ..firstObtainedAt = now.subtract(const Duration(days: 5))
        ..firstObtainedFrom = '黑风寨之战'
        ..obtainedCount = 1
        ..isPreRecord = false,
    // 正常态 3
    if (seed.length > 2)
      EquipmentCatalogEntry()
        ..id = idCounter++
        ..saveDataId = 1
        ..defId = seed[2].id
        ..firstObtainedAt = now.subtract(const Duration(days: 2))
        ..firstObtainedFrom = '黑风寨之战'
        ..obtainedCount = 3
        ..isPreRecord = false,
    // 回填骨架（isPreRecord=true）
    if (seed.length > 3)
      EquipmentCatalogEntry()
        ..id = idCounter
        ..saveDataId = 1
        ..defId = seed[3].id
        ..firstObtainedAt = null
        ..firstObtainedFrom = '来历不详'
        ..obtainedCount = 1
        ..isPreRecord = true,
  ];

  return ProviderScope(
    overrides: [
      equipmentCatalogListProvider.overrideWith((ref) async => entries),
    ],
    child: const WeaponCodexScreen(),
  );
}

/// 兵器谱详情屏正常态目检：挑一件有 schoolBias 的典型 def + 正常态 entry。
/// 优先选有 schoolBias 的，fallback 取 values.first。
Widget _buildWeaponCodexDetailVisual() {
  final defs = GameRepository.instance.equipmentDefs.values;
  final def = defs.firstWhere(
    (d) => d.schoolBias != null,
    orElse: () => defs.first,
  );
  final entry = EquipmentCatalogEntry()
    ..id = 1
    ..saveDataId = 1
    ..defId = def.id
    ..firstObtainedAt = DateTime(2026, 6, 15)
    ..firstObtainedFrom = '黑风寨之战'
    ..obtainedCount = 2
    ..isPreRecord = false;
  return EquipmentCatalogDetailScreen(def: def, entry: entry);
}

/// 门派谱主屏世代卷混合态：注入假世代覆盖 [lineageCodexProvider]。
///
/// 世代构造：祖师（武圣登峰）+ 大弟子（一流）+ 二弟子（二流）+ 1 件师承遗物
/// （宝物阶，owner=祖师，含 1 段传承链）。验进度头 + 祖师卡 + 门人列 + 师承遗物列 +
/// 屏底飞升入口。GameRepository / Isar 已在 _prepare 加载（遗物名走真 def，飞升段读真配置）。
/// debug fixture，中文内联照 host 现有 preview 体例。
Widget _buildLineageCodexVisual() {
  final founder = Character()
    ..id = 1
    ..name = '林青崖'
    ..realmTier = RealmTier.wuSheng
    ..realmLayer = RealmLayer.dengFeng
    ..lineageRole = LineageRole.founder
    ..isFounder = true
    ..isActive = true
    ..attributes = Attributes();
  final d1 = Character()
    ..id = 2
    ..name = '叶清'
    ..realmTier = RealmTier.yiLiu
    ..realmLayer = RealmLayer.ruMen
    ..lineageRole = LineageRole.senior
    ..isActive = true
    ..attributes = Attributes();
  final d2 = Character()
    ..id = 3
    ..name = '陆沉'
    ..realmTier = RealmTier.erLiu
    ..realmLayer = RealmLayer.ruMen
    ..lineageRole = LineageRole.junior
    ..isActive = true
    ..attributes = Attributes();
  final relic = Equipment()
    ..id = 9
    ..isLineageHeritage = true
    ..ownerCharacterId = 1
    ..tier = EquipmentTier.baoWu
    ..defId = GameRepository.isLoaded
        ? GameRepository.instance.equipmentDefs.values.first.id
        : 'placeholder'
    ..previousOwnerCharacterIds = [0, 1];
  final gen = LineageGeneration(
    founder: founder,
    disciples: [d1, d2],
    heritageEquipments: [relic],
    isCurrent: true,
  );
  return ProviderScope(
    overrides: [
      lineageCodexProvider.overrideWith((ref) async => [gen]),
    ],
    child: const LineagePanelScreen(),
  );
}

/// 门派谱角色详情屏祖师态：种祖师 Character（武圣登峰）直传 detail 屏。
/// 主修/遗物段 watch 真 provider（host 内 GameRepository 已加载、真 Isar 存在 →
/// 查真数据，祖师 id=1 有无遗物均可目检）；祖师恩泽段在 isLoaded && buff.isActive
/// 时渲染（host 内两者均真）。debug fixture，中文内联照 host 现有 preview 体例。
Widget _buildLineageCharacterDetailVisual() {
  final founder = Character()
    ..id = 1
    ..name = '林青崖'
    ..realmTier = RealmTier.wuSheng
    ..realmLayer = RealmLayer.dengFeng
    ..lineageRole = LineageRole.founder
    ..isFounder = true
    ..isActive = true
    ..attributes = Attributes();
  return LineageCharacterDetailScreen(character: founder);
}
