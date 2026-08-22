import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../data/game_repository.dart';
import '../../../data/defs/equipment_def.dart';
import 'redline_audit_screen.dart';
import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/isar_setup.dart';
import '../application/visual_route_isar_directory.dart';
import 'package:isar_community/isar.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_app_theme.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../../shared/utils/rng.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../cultivation/application/character_advancement_service.dart';
import '../../equipment/application/equipment_factory.dart';
import '../../mainline/presentation/chapter_list_screen.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../mainline/presentation/stage_list_screen.dart';
import '../../mainline/presentation/stage_entry_flow.dart';
import '../../main_menu/presentation/main_menu.dart';
import '../../save_slot/application/slot_list_provider.dart';
import '../../save_slot/presentation/save_select_screen.dart';
import '../../settings/application/display_settings_providers.dart';
import '../../settings/domain/display_settings.dart';
import '../../settings/presentation/settings_panel.dart';
import '../../splash/presentation/splash_screen.dart';
import '../../../data/slot_summary.dart';
import '../../onboarding/application/onboarding_service.dart';
import '../../onboarding/application/master_builder.dart';
import '../../onboarding/presentation/founder_creation_screen.dart';
import '../../lineage/presentation/disciple_join_overlay.dart';
import '../../lineup/presentation/team_lineup_screen.dart';
import '../../sect/presentation/sect_screen.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../../tower/application/tower_progress_service.dart';
import '../../tower/domain/tower_progress.dart';
import '../../tower/presentation/tower_floor_list_screen.dart';
import '../../seclusion/domain/retreat_session.dart';
import '../../../data/defs/seclusion_map_def.dart';
import '../../seclusion/presentation/active_retreat_screen.dart';
import '../../seclusion/presentation/retreat_result_screen.dart';
import '../../seclusion/presentation/seclusion_map_list_screen.dart';
import '../../seclusion/presentation/seclusion_setup_screen.dart';
import '../../seclusion/application/offline_recap_service.dart';
import '../../seclusion/presentation/offline_recap_card.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../inventory/presentation/equipment_detail_screen.dart';
import '../../resource_overview/presentation/resource_overview_screen.dart';
import '../application/phase2_seed_service.dart';
import '../application/battle_frame_profile.dart';
import '../application/visual_route.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../data/narrative_loader.dart';
import '../../mainline/domain/chapter_assets.dart';
import '../../combat_shared/presentation/hero_camera_overlay.dart';
import '../../../shared/battle_shared/enum_localizations.dart' show EnumL10n;
import '../../battle/presentation/phase0a/phase0a_battle_controller.dart';
import '../../battle/presentation/phase0a/phase0a_battle_screen.dart';
import '../../battle/presentation/phase0a/phase0a_presentation_tokens.dart';
import '../../battle/application/phase0a/phase0a_player_bot_adapter.dart';
import '../../battle/application/phase0a/phase0a_player_input_adapter.dart';
import '../../battle/application/phase0a/phase0a_wave_battle_flow.dart';
import '../../battle/domain/phase0a/phase0a_combat_events.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../application/phase0a_debug_battle_fixture.dart';
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
import '../../shop/application/shop_service.dart';
import '../../../core/domain/inventory_item.dart';
import '../../character_panel/application/lineage_codex_provider.dart';
import '../../character_panel/presentation/lineage_panel_screen.dart';
import '../../baike/application/encounter_codex_provider.dart';
import '../../baike/presentation/encounter_detail_screen.dart';
import '../../baike/presentation/baike_screen.dart';
import '../../baike/application/martial_codex_provider.dart';
import '../../baike/presentation/skill_codex_detail_screen.dart';
import '../../character_panel/presentation/lineage_character_detail_screen.dart';
import '../../zangjuange/presentation/zangjuange_screen.dart';
import '../../../core/domain/island_building_type.dart';
import '../../taohua_island/presentation/taohua_island_screen.dart';
import '../../recruitment/presentation/recruitment_dialog.dart';
import '../../boss_gauntlet/application/gauntlet_service.dart';
import '../../boss_gauntlet/presentation/gauntlet_defeat_screen.dart';
import '../../boss_gauntlet/presentation/gauntlet_interlude_screen.dart';
import '../../boss_gauntlet/presentation/gauntlet_loadout_screen.dart';
import '../../boss_gauntlet/presentation/gauntlet_reward_screen.dart';
import '../../expedition/application/expedition_service.dart';
import '../../expedition/presentation/expedition_overview_screen.dart';
import '../../expedition/presentation/expedition_recap_screen.dart';
import '../../../core/domain/reward_entry.dart';
import 'hitbox_debug_overlay.dart';
import 'visual_fidelity_region_probe.dart';

/// 出版美术验收入口 App。
/// Task 4 直接 `runApp(VisualRouteApp(route: route))` 调用。
class VisualRouteApp extends StatelessWidget {
  const VisualRouteApp({super.key, required this.route, this.routeId});

  final VisualRoute route;
  final String? routeId;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        if (route == VisualRoute.settingsPanelDisabled)
          displaySettingsProvider.overrideWith(
            (ref) async => const DisplaySettings(fullscreen: true),
          ),
      ],
      child: MaterialApp(
        title: UiStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: wuxiaAppTheme(),
        builder: _wuxiaTextScaleBuilder,
        home: BattleFrameProfileProbe.maybeWrap(
          HitboxDebugOverlay.maybeWrap(
            VisualRouteHost(route: route, routeId: routeId),
          ),
        ),
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
  const VisualRouteHost({super.key, required this.route, this.routeId});

  final VisualRoute route;
  final String? routeId;

  @override
  ConsumerState<VisualRouteHost> createState() => _VisualRouteHostState();
}

class _VisualRouteHostState extends ConsumerState<VisualRouteHost> {
  Widget? _target;
  Object? _error;
  late final VisualRouteReadyGate _readyGate;

  @override
  void initState() {
    super.initState();
    _readyGate = VisualRouteReadyGate(
      controlled: widget.route.controlsReadiness,
      onReady: _emitReady,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  void _emitReady(String summary) {
    final routeId = widget.routeId ?? widget.route.id;
    if (summary != 'mounted') {
      debugPrint('VISUAL_ROUTE_STATE: route=$routeId $summary');
    }
    debugPrint('VISUAL_ROUTE_READY: $routeId');
  }

  Future<void> _prepare() async {
    try {
      // 1. 照 splash bootstrap:加载 defs + 初始化 Isar
      //    视觉路由一律开隔离空库(systemTemp 下,每次启动清空重建),
      //    绝不碰生产存档——否则打开即可能迁移 saveVersion 顶到未来版本,
      //    且 seed 的 _clearAll() 会清掉玩家全部业务表。
      await GameRepository.loadAllDefs();
      await IsarSetup.init(directory: await visualRouteIsarDirectory());
      final isar = IsarSetup.instance;

      // 2. 按 route 构造目标屏(逻辑抽到顶层 buildVisualTarget,供 hub 运行时复用)
      final target = await buildVisualTarget(
        widget.route,
        isar,
        routeId: widget.routeId,
        onTargetReady: _readyGate.markTarget,
      );

      // 3. 挂载目标屏
      if (!mounted) return;
      setState(() => _target = target);

      // 4. 目标屏首帧后打就绪信号
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _readyGate.markMounted();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      debugPrint(
        'VISUAL_ROUTE_ERROR: ${widget.routeId ?? widget.route.id} :: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Text('VISUAL_ROUTE_ERROR: $_error')));
    }
    return VisualFidelityRegionProbe.maybeWrap(
      _target ?? const Scaffold(body: Center(child: InkLoadingIndicator())),
    );
  }
}

/// 普通 route 维持首帧 READY；状态 route 必须同时满足挂载和目标状态。
class VisualRouteReadyGate {
  VisualRouteReadyGate({required this.controlled, required this.onReady});

  final bool controlled;
  final ValueChanged<String> onReady;
  bool _mounted = false;
  bool _emitted = false;
  String? _targetSummary;

  void markMounted() {
    _mounted = true;
    _tryEmit();
  }

  void markTarget(String summary) {
    _targetSummary ??= summary;
    _tryEmit();
  }

  void _tryEmit() {
    if (_emitted || !_mounted) return;
    if (controlled && _targetSummary == null) return;
    _emitted = true;
    onReady(controlled ? _targetSummary! : 'mounted');
  }
}

/// 单一职责:route → (seed + 目标屏)。供 [VisualRouteHost] 单路由直达与
/// [_AcceptanceHub] 运行时点选复用——后者 build 一次即可点遍全部路由,
/// 免 dart-define VISUAL_ROUTE 每路由重 flutter run(Codex 验收加速)。
Future<Widget> buildVisualTarget(
  VisualRoute route,
  Isar isar, {
  String? routeId,
  ValueChanged<String>? onTargetReady,
}) async {
  switch (route) {
    case VisualRoute.splash:
      return const SplashScreen(
        minDisplay: Duration(days: 1),
        loadDefinitions: _neverCompleteVisualSplashLoad,
      );
    case VisualRoute.saveSelectEmpty:
      return ProviderScope(
        overrides: [
          slotListProvider.overrideWith(
            (ref) async => [
              SlotSummary.empty(1),
              SlotSummary.empty(2),
              SlotSummary.empty(3),
            ],
          ),
        ],
        child: const SaveSelectScreen(),
      );
    case VisualRoute.saveSelectFilled:
      return ProviderScope(
        overrides: [
          slotListProvider.overrideWith(
            (ref) async => _visualSaveSlotSummaries(),
          ),
        ],
        child: const SaveSelectScreen(),
      );
    case VisualRoute.mainMenu:
      await _seedCleanMainMenu(isar);
      return const MainMenu();
    case VisualRoute.mainMenuClean:
      await _seedCleanMainMenu(isar);
      return const MainMenu();
    case VisualRoute.settingsPanel:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      return _SettingsPanelPreview(
        position: _SettingsPanelPreviewPosition.top,
        onReady: onTargetReady,
      );
    case VisualRoute.settingsPanelBottom:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      return _SettingsPanelPreview(
        position: _SettingsPanelPreviewPosition.bottom,
        onReady: onTargetReady,
      );
    case VisualRoute.settingsPanelDisabled:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      return _SettingsPanelPreview(
        position: _SettingsPanelPreviewPosition.display,
        onReady: onTargetReady,
      );
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
    case VisualRoute.towerFloorList:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
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
        ..realmTierAtStart = RealmTier.zongShi
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
        ..durationHours = 0
        ..realmTierAtStart = RealmTier.zongShi
        ..startedAt = DateTime.now().subtract(const Duration(hours: 79))
        ..completedAt = null
        ..status = RetreatStatus.active
        ..actualRewards = [];
      return ActiveRetreatScreen(session: session, mapDef: def, characterId: 1);
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
        elapsedHours: 90.0,
        retreatHours: 72.0,
        passiveHours: 18.0,
        passive: (
          mojianshi: 18,
          experience: 360,
          awayHours: 18.0,
          settledHours: 18.0,
          isCapped: false,
        ),
        actualHours: 72.0,
        mojianshi: 324,
        silver: 360,
        itemRewards: const <String, int>{},
        equipmentDrops: <Equipment>[tieJian],
        equipmentDropNodeHours: const [12],
        realmTierAtStart: RealmTier.sanLiu,
        experiencePoints: 9360,
        techniqueLearnPoints: 108,
        internalForcePoints: 756,
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
    case VisualRoute.phase0aBattlePlayable:
    case VisualRoute.phase0aBattleAttackFeedback:
    case VisualRoute.phase0aBattleGatherFeedback:
    case VisualRoute.phase0aBattleClearFeedback:
      final fixture = await Phase0aDebugBattleFixture.load(
        assetLoader: rootBundle.loadString,
        numbers: GameRepository.instance.numbers,
      );
      final controller = Phase0aBattleController(
        flow: fixture.flow,
        roster: fixture.roster,
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );
      final command = switch (route) {
        VisualRoute.phase0aBattleAttackFeedback => const Phase0aPlayerCommand(
          attack: true,
        ),
        VisualRoute.phase0aBattleGatherFeedback => const Phase0aPlayerCommand(
          gather: true,
        ),
        VisualRoute.phase0aBattleClearFeedback => const Phase0aPlayerCommand(
          clear: true,
        ),
        _ => null,
      };
      return _Phase0aFeedbackPreview(
        controller: controller,
        initialCommand: command,
        // 仅可玩路由接终局「再战」(9B);三条首拍静态验收路由保持纯展示。
        retryFlowBuilder: command == null
            ? () async {
                final fresh = await Phase0aDebugBattleFixture.load(
                  assetLoader: rootBundle.loadString,
                  numbers: GameRepository.instance.numbers,
                );
                return fresh.flow;
              }
            : null,
      );
    case VisualRoute.phase0aBattleProfile:
      final fixture = await Phase0aDebugBattleFixture.load(
        assetLoader: rootBundle.loadString,
        numbers: GameRepository.instance.numbers,
      );
      return _Phase0aProfilePreview(initialFixture: fixture);
    case VisualRoute.phase0aBattleBossMechanics:
      final fixture = await Phase0aDebugBattleFixture.load(
        assetLoader: rootBundle.loadString,
        numbers: GameRepository.instance.numbers,
        assetPath: 'data/phase0a_debug_boss_battle.yaml',
      );
      return _Phase0aBossMechanicsPreview(
        controller: Phase0aBattleController(
          flow: fixture.flow,
          roster: fixture.roster,
          fixedDeltaSeconds: fixture.fixedDeltaSeconds,
        ),
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );
    case VisualRoute.phase0aBattleGuardianMechanics:
      final fixture = await Phase0aDebugBattleFixture.load(
        assetLoader: rootBundle.loadString,
        numbers: GameRepository.instance.numbers,
        assetPath: 'data/phase0a_debug_guardian_mechanics.yaml',
      );
      return _Phase0aGuardianMechanicsPreview(
        controller: Phase0aBattleController(
          flow: fixture.flow,
          roster: fixture.roster,
          fixedDeltaSeconds: fixture.fixedDeltaSeconds,
        ),
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );
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
    case VisualRoute.equipmentDetailRepairGallery:
      return const _EquipmentDetailRepairGallery();
    case VisualRoute.equipmentDetailGauntletReward:
      final def = GameRepository.instance.getEquipment(
        'weapon_haojiahuo_suo_mai_nang',
      );
      final eq = Equipment.create(
        defId: def.id,
        tier: def.tier,
        slot: def.slot,
        obtainedAt: DateTime(2026, 7, 26),
        obtainedFrom: 'visual_route',
        baseAttack: def.baseAttackMin,
        baseHealth: def.baseHealthMin,
        baseSpeed: def.baseSpeedMin,
      )..id = 2;
      return EquipmentDetailScreen(equipment: eq, def: def);
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
    case VisualRoute.offlineRecapActive:
      return const _OfflineRecapActivePreview();
    case VisualRoute.offlineRecapPassive:
      return const _OfflineRecapPassivePreview();
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
    case VisualRoute.shopBuyConfirm:
      // 商店购买确认弹窗打开态:种银两 80 让货架正常渲染,叠真 ShopScreen 背景 +
      // 复刻 _handleBuy 的 PaperDialog 确认弹窗(磨剑石 ×1 · 定价取真 def),冻结打开态供截图。
      await _seedInventoryItem(isar, 'item_silver', 80);
      return const _ShopBuyConfirmPreview();
    case VisualRoute.inventoryCurrency:
      // 背包货币位目检:种银两 + 磨剑石 + 心血结晶,initialTab=1 直开物料 tab,
      // 验顶部货币位顶栏 + 材料网格(银两不重复进网格,仅磨剑石/心血结晶)。
      await _seedInventoryItem(isar, 'item_silver', 360);
      await _seedInventoryItem(isar, 'item_mojianshi', 24);
      await _seedInventoryItem(isar, 'item_xinxuejiejing', 6);
      return const InventoryScreen(initialTab: 1);
    case VisualRoute.resourceOverview:
      // 资源总览目检:只种 debug 库存行,由 ResourceOverviewScreen 走真 provider
      // 派生五类资源的来源/用途/近期去向。不改业务系统数值或结算路径。
      await _seedInventoryItem(isar, 'item_silver', 360);
      await _seedInventoryItem(isar, 'item_mojianshi', 90);
      await _seedInventoryItem(isar, 'item_xinxuejiejing', 12);
      await _seedInventoryItem(isar, 'item_jingtie', 60);
      await _seedInventoryItem(isar, 'item_yaocao', 36);
      await _seedInventoryItem(isar, 'item_jingyandan_small', 3);
      await _seedInventoryItem(isar, 'item_scroll_kai_bei_shou', 1);
      return const ResourceOverviewScreen();
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
    case VisualRoute.itemUseConfirmDialog:
      // 道具使用确认弹窗打开态:照 itemUseInventory 种祖师 + 经验丹三档/秘籍/磨剑石,
      // 物料 tab(initialTab=1)真 InventoryScreen 背景 + 复刻 _onUse 的 PaperDialog
      // 使用确认弹窗(凝神丹 · 道具名取真 ItemDef),冻结打开态供截图。
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      await _seedInventoryItem(isar, 'item_jingyandan_small', 3);
      await _seedInventoryItem(isar, 'item_jingyandan_mid', 2);
      await _seedInventoryItem(isar, 'item_jingyandan_large', 1);
      await _seedInventoryItem(isar, 'item_scroll_kai_bei_shou', 1);
      await _seedInventoryItem(isar, 'item_mojianshi', 12);
      return const _ItemUseConfirmPreview();
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
    case VisualRoute.taohuaBuildingPopup:
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
      return const TaohuaIslandScreen(
        initialBuildingMenu: BuildingType.daZaoTai,
      );
    case VisualRoute.recruitmentDialog:
      await OnboardingService(
        isar: isar,
      ).ensureFoundingMasters(soloStart: false);
      return const RecruitmentDialog();
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
      final towerMax = GameRepository.instance.towerMaxFloor;
      for (var floor = 1; floor <= towerMax; floor++) {
        await towerSvc.recordClear(
          floorIndex: floor,
          now: towerNow,
          elapsedMs: 60000,
          maxFloor: towerMax,
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
    case VisualRoute.skillCodexLockedSnackbar:
      // 武学图鉴点剪影 snackbar 态:复用 _buildSkillCodexVisual 混态(前6点亮+其余剪影)
      // 为背景,post-frame 触发与 _SilhouetteRow 一致的 ScaffoldMessenger snackbar
      // (UiStrings.skillCodexNotMet),仅延长 duration 让 SnackBar 驻留供截图。
      return _SkillCodexLockedSnackbarPreview(child: _buildSkillCodexVisual());
    case VisualRoute.skillCodexDetail:
      // 武学详情屏目检：取收录池首招直传 detail 屏(同步展示,maxStage=null 未曾习练态)。
      return _buildSkillCodexDetailVisual();
    case VisualRoute.zangjuange:
      return const ZangjuangeScreen();
    case VisualRoute.redlineAudit:
      return const RedlineAuditScreen();
    case VisualRoute.founderCreation:
      // S1 目检：祖师塑形创建页确认区决策可逆说明(深底 textMuted 提示行)。
      return const FounderCreationScreen(allowQuickStart: true);
    case VisualRoute.stageRetryDialog:
      // S3 目检：普通关战败重试弹框非教学化短诊断(浅纸底 muted 提示行)。
      // 静态复刻 _showStageRetryDialog 的 PaperDialog 开态(body=StageRetryDialogBody)。
      return const _StageRetryDialogPreview();
    case VisualRoute.teamLineup:
      // 出战编成屏目检(§十三 #4):真种子三席梯度境界 + 替补三态
      // (无标/境界偏低/闭关中),屏走真 provider 链验点选交换入口与标签。
      await Phase2SeedService(isar: isar).seedTeamLineup();
      return const TeamLineupScreen();
    case VisualRoute.expeditionRecap:
      // 百草岭远征返程行记目检(§4.7):纯只读屏,直接注入一份丰奖获 + 1 人负伤的
      // 主动召回结果(GameRepository 已在 _prepare 加载 → 物料名正常渲染)。
      return _buildExpeditionRecapVisual();
    case VisualRoute.expeditionOverview:
      // 江湖远行总览·派遣态(§7.1):复用 team_lineup 种子(founder + 带主修弟子 +
      // 降将无主修 + 闭关行者占用),无 active run → 派遣态显候选三态 + 三方针 + 拔营。
      await Phase2SeedService(isar: isar).seedTeamLineup();
      return const ExpeditionOverviewScreen();
    case VisualRoute.expeditionActive:
      // 江湖远行·派遣中(§7.1):种子 + 派遣两人 + 推进到第 8 节点,显在途态
      // (深度/完成/方针/下一节点剩余/召回)。
      await Phase2SeedService(isar: isar).seedExpeditionActive();
      return const ExpeditionOverviewScreen();
    case VisualRoute.gauntletLoadout:
      // 断魂庄装载屏(§7.1):team_lineup 种子 + 库存补帖/补给,无 active 会话 → 装载态
      // (帖库存/三关 Boss/推荐境界/择人/补给装载/入庄)。
      await Phase2SeedService(isar: isar).seedGauntletLoadout();
      return const GauntletLoadoutScreen();
    case VisualRoute.gauntletLoadoutCycle:
      // 批 C 周目选择区目检:装载态种子 + 种断魂庄已通 cycle1(批 B §B5「已通 cycle1
      // 起显」)+ 抬一名可入场弟子到绝顶过 cycle2 境界门槛(推进后敌 zongShi − margin 1
      // = jueDing)→ 同屏拍到「cycle1 已通✓ + cycle2 可选」完整选择态(主线式自由回选)。
      await Phase2SeedService(isar: isar).seedGauntletLoadout();
      await isar.writeTxn(() async {
        final save = await isar.saveDatas.get(0) ?? (SaveData()..id = 0);
        save.duanhunClearedCyclesMax = 1;
        await isar.saveDatas.put(save);
        final chars = await isar.characters
            .filter()
            .isFounderEqualTo(false)
            .findAll();
        final lead = chars.firstWhere(
          (c) => c.mainTechniqueId != null && c.currentRetreatSessionId == null,
        );
        lead.realmTier = RealmTier.jueDing;
        await isar.characters.put(lead);
      });
      return const GauntletLoadoutScreen();
    case VisualRoute.expeditionOverviewCycle:
      // 批 C 周目选择区目检:派遣态种子 + 种 baicaoMaxDepth=25(≥首里程碑 20 折算
      // 已通 cycle1,批 B §B5 远征无终点绑深度;25 兼验「已达 20 未达 40」中间态)
      // + 抬一名可派遣弟子到绝顶过境界门槛 → 拍「cycle1✓ + cycle2 可选」完整态。
      await Phase2SeedService(isar: isar).seedTeamLineup();
      await isar.writeTxn(() async {
        final save = await isar.saveDatas.get(0) ?? (SaveData()..id = 0);
        save.baicaoMaxDepth = 25;
        await isar.saveDatas.put(save);
        final chars = await isar.characters
            .filter()
            .isFounderEqualTo(false)
            .findAll();
        final lead = chars.firstWhere(
          (c) => c.mainTechniqueId != null && c.currentRetreatSessionId == null,
        );
        lead.realmTier = RealmTier.jueDing;
        await isar.characters.put(lead);
      });
      return const ExpeditionOverviewScreen();
    case VisualRoute.gauntletInterlude:
      // 断魂庄庄内整备(§7.2):造单角色 active 会话推进到 interlude
      // (第 2 关·存活带冷却 + 托管补给余量),显角色状态 + 补给 + 使用/继续/认输。
      await Phase2SeedService(isar: isar).seedGauntletInterlude();
      return const GauntletInterludeScreen();
    case VisualRoute.gauntletReward:
      // 断魂庄通关三选一(§6.2):造 active 会话推进到 awaitingRewardChoice(Boss 终关胜·
      // 首通待领·三件好家伙候选),显三选一卡 + 首通标 + 择取。
      await Phase2SeedService(isar: isar).seedGauntletReward();
      return const GauntletRewardScreen();
    case VisualRoute.gauntletDefeat:
      // 断魂庄战败结算(§6.3):直传摘要 fixture(已破 1 关精英 + 一轻伤一重伤),
      // 显精英经验 + 逐弟子伤势 + 离庄。屏纯只读摘要·无需 Isar 会话。
      return const GauntletDefeatScreen(
        summary: GauntletDefeatSummary(
          elitesDefeated: 1,
          eliteExpPerMember: 50,
          members: [
            GauntletDefeatMember(name: '沈青', downed: false),
            GauntletDefeatMember(name: '楚河', downed: true),
          ],
        ),
      );
    case VisualRoute.hub:
      return _AcceptanceHub(isar: isar);
  }
}

Future<void> _neverCompleteVisualSplashLoad() => Completer<void>().future;

List<SlotSummary> _visualSaveSlotSummaries() => [
  SlotSummary(
    slotId: 1,
    isEmpty: false,
    slotName: '夜雨江湖',
    founderName: '沈孤鸿',
    realmDisplay: '武圣登峰',
    chapterIndex: 16,
    clearedStageCount: 80,
    completedFirstCycle: true,
    highestTowerFloor: 30,
    lastPlayed: DateTime(2026, 7, 25, 18, 30),
    isMostRecent: true,
  ),
  SlotSummary.empty(2),
  SlotSummary.empty(3),
];

Future<void> _seedCleanMainMenu(Isar isar) async {
  await OnboardingService(isar: isar).ensureFoundingMasters(soloStart: false);
  final now = DateTime.now();
  await isar.writeTxn(() async {
    await isar.retreatSessions.clear();
    final save = await isar.saveDatas.get(0);
    if (save == null) return;
    save.lastOnlineAt = now;
    await isar.saveDatas.put(save);
  });
}

/// 设置弹窗验收：以既有水墨门面为中性背景，并通过 [SettingsPanel.show] 打开
/// 生产弹窗。避免主菜单根据本机存档自动叠加「归来」等一次性流程，污染验收帧。
/// READY 延迟到弹窗过渡完成，避免截图命中半透明动画中间帧。
enum _SettingsPanelPreviewPosition { top, display, bottom }

class _Phase0aFeedbackPreview extends StatefulWidget {
  const _Phase0aFeedbackPreview({
    required this.controller,
    required this.initialCommand,
    this.retryFlowBuilder,
  });

  final Phase0aBattleController controller;
  final Phase0aPlayerCommand? initialCommand;
  final Future<Phase0aWaveBattleFlow> Function()? retryFlowBuilder;

  @override
  State<_Phase0aFeedbackPreview> createState() =>
      _Phase0aFeedbackPreviewState();
}

class _Phase0aFeedbackPreviewState extends State<_Phase0aFeedbackPreview> {
  @override
  void initState() {
    super.initState();
    final command = widget.initialCommand;
    if (command != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.step(command);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Phase0aBattleScreen(
    controller: widget.controller,
    autoStep: widget.initialCommand == null,
    retryFlowBuilder: widget.retryFlowBuilder,
    feedbackHoldSeconds: widget.initialCommand == null
        ? Phase0aPresentationTokens.feedbackHoldSeconds
        : Phase0aPresentationTokens.visualRouteFeedbackHoldSeconds,
  );
}

/// Route C 物理机 Profile 专用负载：与生产 headless 共用 bot 指令，
/// 但每拍仍经真实 controller/reducer 并由生产 [Phase0aBattleScreen] 渲染。
/// 终局同 seed 重建 fixture，避免长矩阵在结算页空跑。
class _Phase0aProfilePreview extends StatefulWidget {
  const _Phase0aProfilePreview({required this.initialFixture});

  final Phase0aDebugBattleFixture initialFixture;

  @override
  State<_Phase0aProfilePreview> createState() => _Phase0aProfilePreviewState();
}

class _Phase0aProfilePreviewState extends State<_Phase0aProfilePreview> {
  late final Phase0aBattleController _controller;
  late Phase0aPlayerBotAdapter _bot;
  Timer? _timer;
  bool _restarting = false;

  @override
  void initState() {
    super.initState();
    _controller = _controllerFor(widget.initialFixture);
    _bot = Phase0aPlayerBotAdapter(
      playerAdapter: widget.initialFixture.playerAdapter,
    );
    _timer = Timer.periodic(
      Duration(
        milliseconds:
            (_controller.fixedDeltaSeconds * Duration.millisecondsPerSecond)
                .round(),
      ),
      (_) => _advance(),
    );
  }

  Phase0aBattleController _controllerFor(Phase0aDebugBattleFixture fixture) =>
      Phase0aBattleController(
        flow: fixture.flow,
        roster: fixture.roster,
        fixedDeltaSeconds: fixture.fixedDeltaSeconds,
      );

  void _advance() {
    if (!mounted || _restarting) return;
    if (_controller.outcome == Phase0aBattleOutcome.ongoing) {
      _controller.step(_bot.commandFor(_controller.state));
      return;
    }
    _restarting = true;
    _restart();
  }

  void _restart() {
    try {
      final fixture = widget.initialFixture.fresh();
      if (!mounted) return;
      _bot = Phase0aPlayerBotAdapter(playerAdapter: fixture.playerAdapter);
      _controller.restart(fixture.flow);
    } finally {
      _restarting = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Phase0aBattleScreen(controller: _controller, autoStep: false);
}

/// Boss fixture driver:先让真实敌方 AI 起蓄力,观察到 charging 后立即发
/// typed R 破招,并冻结在 stagger/vulnerability 窗口供目检。
class _Phase0aBossMechanicsPreview extends StatefulWidget {
  const _Phase0aBossMechanicsPreview({
    required this.controller,
    required this.fixedDeltaSeconds,
  });

  final Phase0aBattleController controller;
  final double fixedDeltaSeconds;

  @override
  State<_Phase0aBossMechanicsPreview> createState() =>
      _Phase0aBossMechanicsPreviewState();
}

class _Phase0aBossMechanicsPreviewState
    extends State<_Phase0aBossMechanicsPreview> {
  Timer? _timer;
  int _guardedHoldTicks = 0;
  int _chargeHoldTicks = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      Duration(
        milliseconds:
            (widget.fixedDeltaSeconds * Duration.millisecondsPerSecond).round(),
      ),
      (_) => _advanceBossFixture(),
    );
  }

  void _advanceBossFixture() {
    if (!mounted || widget.controller.outcome != Phase0aBattleOutcome.ongoing) {
      _timer?.cancel();
      return;
    }
    final boss = widget.controller.state.enemies.first;
    if (boss.staggerTicksRemaining > 0) {
      _timer?.cancel();
      return;
    }
    if (widget.controller.events.isEmpty) {
      final requiredGuardedTicks =
          (Phase0aPresentationTokens.bossFixtureGuardedHoldSeconds /
                  widget.fixedDeltaSeconds)
              .ceil();
      if (_guardedHoldTicks++ < requiredGuardedTicks) return;
    }
    if (boss.chargingCast != null) {
      final requiredHoldTicks =
          (Phase0aPresentationTokens.bossFixtureChargeHoldSeconds /
                  widget.fixedDeltaSeconds)
              .ceil();
      if (_chargeHoldTicks++ < requiredHoldTicks) return;
    }
    widget.controller.step(
      boss.chargingCast == null
          ? null
          : const Phase0aPlayerCommand(clear: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Phase0aBattleScreen(
    controller: widget.controller,
    autoStep: false,
    feedbackHoldSeconds:
        Phase0aPresentationTokens.visualRouteFeedbackHoldSeconds,
  );
}

/// Guardian fixture driver: hold the ward, let the Boss enter charge, spend
/// the player's real clear action so the reducer redirects the break to a
/// guardian, then advance until the reducer emits the two-guardian strike.
class _Phase0aGuardianMechanicsPreview extends StatefulWidget {
  const _Phase0aGuardianMechanicsPreview({
    required this.controller,
    required this.fixedDeltaSeconds,
  });

  final Phase0aBattleController controller;
  final double fixedDeltaSeconds;

  @override
  State<_Phase0aGuardianMechanicsPreview> createState() =>
      _Phase0aGuardianMechanicsPreviewState();
}

class _Phase0aGuardianMechanicsPreviewState
    extends State<_Phase0aGuardianMechanicsPreview> {
  Timer? _timer;
  bool _breakSent = false;
  bool _interceptSeen = false;
  bool _coopSeen = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      Duration(
        milliseconds:
            (widget.fixedDeltaSeconds * Duration.millisecondsPerSecond).round(),
      ),
      (_) => _advanceGuardianFixture(),
    );
  }

  void _advanceGuardianFixture() {
    if (!mounted || widget.controller.outcome != Phase0aBattleOutcome.ongoing) {
      _timer?.cancel();
      return;
    }
    _interceptSeen =
        _interceptSeen ||
        widget.controller.lastEvents.any(
          (event) => event is Phase0aGuardIntercepted,
        );
    _coopSeen =
        _coopSeen ||
        widget.controller.lastEvents.any(
          (event) => event is Phase0aGuardianCoopStrike,
        );
    if (_interceptSeen && _coopSeen) {
      _timer?.cancel();
      return;
    }
    final boss = widget.controller.state.enemies.first;
    if (!_breakSent && boss.chargingCast != null) {
      _breakSent = true;
      widget.controller.step(const Phase0aPlayerCommand(clear: true));
      return;
    }
    widget.controller.step();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Phase0aBattleScreen(
    controller: widget.controller,
    autoStep: false,
    feedbackHoldSeconds:
        Phase0aPresentationTokens.visualRouteFeedbackHoldSeconds,
  );
}

class _SettingsPanelPreview extends StatefulWidget {
  const _SettingsPanelPreview({required this.position, this.onReady});

  final _SettingsPanelPreviewPosition position;
  final ValueChanged<String>? onReady;

  @override
  State<_SettingsPanelPreview> createState() => _SettingsPanelPreviewState();
}

class _SettingsPanelPreviewState extends State<_SettingsPanelPreview> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _displaySectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      unawaited(
        SettingsPanel.show(
          context,
          scrollController: _scrollController,
          displaySectionKey: _displaySectionKey,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await _positionScroll();
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) {
        widget.onReady?.call(
          'dialog=settings_panel_open position=${widget.position.name}',
        );
      }
    });
  }

  Future<void> _positionScroll() async {
    if (!_scrollController.hasClients) return;
    switch (widget.position) {
      case _SettingsPanelPreviewPosition.top:
        _scrollController.jumpTo(0);
      case _SettingsPanelPreviewPosition.display:
        final targetContext = _displaySectionKey.currentContext;
        if (targetContext != null) {
          await Scrollable.ensureVisible(targetContext, alignment: 0);
        }
      case _SettingsPanelPreviewPosition.bottom:
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          WuxiaImage(WuxiaUi.mainMenuBg, fit: BoxFit.cover),
          ColoredBox(color: Color(0x660F0D0B)),
        ],
      ),
    );
  }
}

/// 百草岭远征返程行记验收 fixture:构造一份主动召回结果(最深 14 处·奖获修为/
/// 药草/灵泉/银两·断魂帖 ×1 里程碑·1 人负伤),直传只读 [ExpeditionRecapScreen]。
Widget _buildExpeditionRecapVisual() {
  RewardEntry r(String key, int qty) => RewardEntry()
    ..rewardKey = key
    ..quantity = qty;
  return ExpeditionRecapScreen(
    result: ExpeditionReturnResult(
      returned: true,
      deepestNode: 14,
      grantedRewards: [
        r('exp', 1200),
        r('item_yaocao', 4),
        r('item_lingquanshui', 2),
        r('item_silver', 180),
        r('item_duanhuntie', 1),
      ],
      downedCount: 1,
      defeated: false,
    ),
  );
}

class _StageRetryDialogPreview extends StatelessWidget {
  const _StageRetryDialogPreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const WuxiaImage(WuxiaUi.battleMountainPassStage, fit: BoxFit.cover),
        const ModalBarrier(color: Color(0x99000000)),
        Center(
          child: PaperDialog(
            title: UiStrings.stageRetryTitle,
            body: const StageRetryDialogBody(),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: WuxiaUi.muted),
                onPressed: () {},
                child: const Text(UiStrings.stageRetryBackAction),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: WuxiaUi.jiang),
                onPressed: () {},
                child: const Text(UiStrings.stageRetryAction),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 奇遇录 tab 混合态：注入前 2 条已际遇(带标题)+ 其余剪影,覆盖 [encounterCodexProvider]。
/// 走真 [groupEncounters] 纯函数分 3 段,验段标/进度/点亮-剪影混排。
/// debug fixture,中文内联照 host 现有 preview 体例。
Widget _buildEncounterCodexVisual() {
  final defs = GameRepository.instance.allEncounters;
  final triggered = defs.take(2).map((d) => d.id).toSet();
  final titles = <String, String>{};
  for (final (index, def) in defs.take(2).indexed) {
    final kind = labelForEncounterGroupKind(encounterGroupKindOf(def));
    titles[def.id] =
        '$kind · ${UiStrings.encounterCodexNoteLabel} ${index + 1}';
  }
  final groups = groupEncounters(
    defs: defs,
    triggeredIds: triggered,
    titles: titles,
  );
  return ProviderScope(
    overrides: [encounterCodexProvider.overrideWith((ref) async => groups)],
    child: const BaikeScreen(initialTab: 3),
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
    child: const BaikeScreen(initialTab: 4),
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

/// 商店购买确认弹窗打开态静态验收:真 [ShopScreen] 货架为背景 + 暗幕 + 复刻
/// shop_screen `_handleBuy` 的 [PaperDialog] 确认弹窗(磨剑石 ×1 · 定价取真 def),
/// 冻结在弹窗打开态供截图。文案/定价全走既有 UiStrings / EnumL10n / 真 def,不新写文案。
class _ShopBuyConfirmPreview extends StatelessWidget {
  const _ShopBuyConfirmPreview();

  @override
  Widget build(BuildContext context) {
    final def = GameRepository.instance.shopItemDefs['shop_mojianshi']!;
    final price = ShopService.effectivePrice(def, 0);
    return Stack(
      fit: StackFit.expand,
      children: [
        const ShopScreen(),
        const ModalBarrier(color: Color(0x99000000)),
        Center(
          child: PaperDialog(
            title: UiStrings.shopBuy,
            body: Text(
              '${EnumL10n.itemType(def.itemType)}  ×1\n'
              '${UiStrings.shopItemPrice(price)}',
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 14,
                height: 1.8,
                letterSpacing: 1,
              ),
            ),
            actions: [
              PlaqueButton(label: UiStrings.commonCancel, onTap: () {}),
              PlaqueButton(
                label: UiStrings.shopBuy,
                primary: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 道具使用确认弹窗打开态静态验收:真 [InventoryScreen](物料 tab)为背景 + 暗幕 +
/// 复刻 inventory `_onUse` 的 [PaperDialog] 使用确认弹窗(道具名取真 [ItemDef] name),
/// 冻结打开态供截图。文案全走既有 UiStrings,不新写文案。
class _ItemUseConfirmPreview extends StatelessWidget {
  const _ItemUseConfirmPreview();

  @override
  Widget build(BuildContext context) {
    final displayName =
        GameRepository.instance.itemDefs['item_jingyandan_small']!.name;
    return Stack(
      fit: StackFit.expand,
      children: [
        const InventoryScreen(initialTab: 1),
        const ModalBarrier(color: Color(0x99000000)),
        Center(
          child: PaperDialog(
            title: UiStrings.itemUseConfirmTitle,
            body: Text(
              UiStrings.itemUseConfirmBody(displayName),
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 14,
                height: 1.8,
                letterSpacing: 1,
              ),
            ),
            actions: [
              PlaqueButton(label: UiStrings.commonCancel, onTap: () {}),
              PlaqueButton(
                label: UiStrings.itemUseButton,
                primary: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 武学图鉴点剪影 snackbar 态静态验收:渲染真混态图鉴([_buildSkillCodexVisual])为
/// 背景,首帧后 post-frame 触发与 [_SilhouetteRow] 一致的 [ScaffoldMessenger] snackbar
/// (UiStrings.skillCodexNotMet),仅延长 duration 让 SnackBar 驻留供截图(文案/样式不变)。
class _SkillCodexLockedSnackbarPreview extends StatefulWidget {
  const _SkillCodexLockedSnackbarPreview({required this.child});

  final Widget child;

  @override
  State<_SkillCodexLockedSnackbarPreview> createState() =>
      _SkillCodexLockedSnackbarPreviewState();
}

class _SkillCodexLockedSnackbarPreviewState
    extends State<_SkillCodexLockedSnackbarPreview> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(UiStrings.skillCodexNotMet),
          duration: Duration(minutes: 5),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
class _OfflineRecapActivePreview extends StatelessWidget {
  const _OfflineRecapActivePreview();

  @override
  Widget build(BuildContext context) {
    const recap = (
      awayHours: 240.0,
      retreatHours: 72.0,
      passiveHours: 168.0,
      passiveMojianshi: 420,
      passiveExperience: 6800,
      equipmentRollCount: 6,
      nextEquipmentNodeHours: null,
      fullRateComplete: true,
      mapName: '断崖绝壁',
      isComplete: true,
      progressPct: 1.0,
      estimatedMojianshi: 920,
      estimatedExperience: 12800,
      estimatedItemRewards: <String, int>{
        'item_yaocao': 36,
        'item_lingquanshui': 18,
        'item_duancai': 12,
        'item_kaifeng_fucai': 6,
      },
      estimatedTechniqueLearnPoints: 36,
      estimatedSilver: 576,
      settledHours: 240.0,
      limitReason: OfflineRecapLimitReason.systemCap,
    );
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: OfflineRecapCard(
          recap: recap,
          onGoCollect: () {},
          onDismiss: () {},
        ),
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
          onDismiss: () {},
        ),
      ),
    );
  }
}

/// B5 败北页静态验收:战场背景 + 径向暗角 + [VictoryOverlay] 战败态
/// (敗 大题字 + 败北 + 破招提示 + 战报)。照 [_VictoryFirstClearPreview] 体例,
/// onContinue no-op(纯静态截图)。
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
          const WuxiaImage(
            'assets/scenes/battle_citywall.png',
            fit: BoxFit.cover,
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
    final bossName = stage.enemyTeam.first.name;
    _data = HeroCameraData(
      portraitPath: founder.portraitPath,
      heroName: defaultMasterName(founder),
      realmLabel: EnumL10n.realmTier(founder.defaultRealm),
      bossName: bossName,
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
          const WuxiaImage(
            'assets/scenes/battle_citywall.png',
            fit: BoxFit.cover,
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

/// 装备详情图册：按阶展示所有具有 detailPath 的装备素材。
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

/// 断魂庄三件修复素材的聚焦验收：左看原 icon，右看专用 detail 在深/浅底的边缘表现。
/// 伤害飘字图册:各型飘字同屏冻结在起始帧,补上「飘字只在命中瞬间闪现、
/// 静态 route 截不到」的长期验收盲区(2026-07-26 phase2 抽查暴露:暴击语义色
/// 从 #B72218 改成 battleCrimson 却无处复看观感)。
///
/// 不动生产代码:用公共参数 [DamagePopup.durationMsOverride] 把时长拉到远超
/// 截图等待窗口,画面就停在满不透明、零位移的起始帧;背景用真战斗场景层,
/// 保证暴击色是对着真实深底判读而非白底。
class _EquipmentDetailRepairGallery extends StatelessWidget {
  const _EquipmentDetailRepairGallery();

  static const _ids = <String>[
    'weapon_haojiahuo_suo_mai_nang',
    'armor_haojiahuo_zhen_yue_tie_yi',
    'accessory_haojiahuo_she_hun_ling',
  ];

  @override
  Widget build(BuildContext context) {
    final repo = GameRepository.instance;
    final defs = _ids.map(repo.getEquipment).toList();
    return Scaffold(
      backgroundColor: const Color(0xFF14181D),
      appBar: AppBar(title: const Text('装备详情修复 · icon / detail')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < defs.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: _EquipmentDetailRepairCard(def: defs[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _EquipmentDetailRepairCard extends StatelessWidget {
  const _EquipmentDetailRepairCard({required this.def});

  final EquipmentDef def;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF20262D),
        border: Border.all(color: const Color(0xFF5A4B3A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              def.name,
              style: const TextStyle(
                color: Color(0xFFD2AA55),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              def.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 138,
              child: _EquipmentRepairArtPanel(
                label: 'ICON',
                imagePath: def.iconPath,
                splitSurface: false,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _EquipmentRepairArtPanel(
                label: 'DETAIL · 深/浅底',
                imagePath: def.detailPath!,
                splitSurface: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentRepairArtPanel extends StatelessWidget {
  const _EquipmentRepairArtPanel({
    required this.label,
    required this.imagePath,
    required this.splitSurface,
  });

  final String label;
  final String imagePath;
  final bool splitSurface;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (splitSurface)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF11161A), Color(0xFFE8DDBF)],
                        stops: [0.5, 0.5],
                      ),
                    ),
                  )
                else
                  const ColoredBox(color: Color(0xFF11161A)),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: WuxiaImage(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: WuxiaColors.danger,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
