import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../battle_record/application/boss_memory_providers.dart';
import '../../weapon_codex/application/equipment_catalog_providers.dart';
import '../../../shared/battle_shared/enum_localizations.dart';
import '../../debug/presentation/phase2_test_menu.dart';
import '../../debug/presentation/redline_audit_screen.dart';
import '../../debug/presentation/sect_recruit_debug_screen.dart';
import '../../festival/application/festival_service_providers.dart';
import '../../jianghu_chronicle/presentation/jianghu_chronicle_hub_screen.dart';
import '../../jianghu_map/presentation/jianghu_map_screen.dart';
import '../../jianghu/presentation/reputation_panel_screen.dart';
import '../../light_foot/presentation/light_foot_screen.dart';
import '../../boss_gauntlet/presentation/gauntlet_loadout_screen.dart';
import '../../mass_battle/presentation/mass_battle_screen.dart';
import '../../martial_inventory/presentation/martial_inventory_hub_screen.dart';
import '../../resource_overview/presentation/resource_overview_screen.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/application/new_save_goal_guidance.dart';
import '../../mainline/presentation/chapter_list_screen.dart';
import '../../mainline/presentation/stage_entry_flow.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../mainline/presentation/new_save_goal_guidance_view.dart';
import '../../seclusion/presentation/seclusion_gate.dart';
import '../../recruitment/presentation/recruitment_dialog.dart';
import '../../sect/presentation/sect_hub_screen.dart';
import '../../settings/presentation/settings_panel.dart';
import '../../sweep/presentation/sweep_readiness_status.dart';
import '../../../shared/app_exit.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/bgm_scope.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/asset_fallback.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/currency_pill.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_icon_button.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../../tutorial/domain/tutorial_hint_def.dart';
import '../../tutorial/presentation/tutorial_banner_card.dart';
import 'main_menu_retreat_banner.dart';
import 'sect_banner.dart';
import '../application/main_menu_status_summary_provider.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../shop/application/shop_providers.dart';
import '../../shop/presentation/shop_screen.dart';
import 'main_menu_status_summary.dart';
import 'main_menu_startup_gate.dart';

const double _mainMenuContentMaxWidth = 1088;
const double _entryColumnGap = 16;
const double _entryRowGap = 16;

typedef ContinueJianghuRunner =
    Future<void> Function(BuildContext context, WidgetRef ref, StageDef stage);

List<int> _mainlineChapterIndexes() {
  final indexes =
      GameRepository.instance.stageDefs.values
          .where((stage) => stage.stageType == StageType.mainline)
          .map((stage) => stage.chapterIndex)
          .whereType<int>()
          .toSet()
          .toList(growable: false)
        ..sort();
  return indexes;
}

/// 按生产主线链解析仍待首次推进的当前关；全通返回 null。
@visibleForTesting
StageDef? resolveContinueJianghuStage(MainlineProgress progress) {
  for (final chapterIndex in _mainlineChapterIndexes()) {
    for (final entry in MainlineProgressService.availableStages(
      progress: progress,
      chapterIndex: chapterIndex,
    )) {
      if (entry.def.stageType == StageType.mainline &&
          entry.status == StageStatus.available) {
        return entry.def;
      }
    }
  }
  return null;
}

/// 入口列表布局成 2 列(Phase A 出版美术 · 解菜单纵向过长)。
/// 奇数末项左对齐 + 右侧空格;同行用 IntrinsicHeight+stretch 等高。
List<Widget> _twoColumn(List<Widget> items) {
  final rows = <Widget>[];
  for (var i = 0; i < items.length; i += 2) {
    final right = i + 1 < items.length ? items[i + 1] : null;
    rows.add(
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: items[i]),
            const SizedBox(width: _entryColumnGap),
            Expanded(child: right ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
    if (i + 2 < items.length) rows.add(const SizedBox(height: _entryRowGap));
  }
  return rows;
}

List<Widget> _oneColumn(List<Widget> items) {
  final rows = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    rows.add(items[i]);
    if (i + 1 < items.length) rows.add(const SizedBox(height: 12));
  }
  return rows;
}

/// 主菜单(Phase A 出版美术重排 · 2026-05-31 · 双列迭代)。
///
/// 全屏水墨背景 + 渐变 scrim + 题字标题 + 入口主/次分组(修行 / 演武 / 江湖 +
/// debug)+ [WuxiaInkButton] 木牌入口 2 列 + §5.7 锁印。导航/门控逻辑不变。
class MainMenu extends ConsumerWidget {
  const MainMenu({
    super.key,
    @visibleForTesting this.continueJianghuRunnerForTest,
  });

  final ContinueJianghuRunner? continueJianghuRunnerForTest;

  void _push(BuildContext context, Widget child) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => child));
  }

  static const int _seclusionUnlockStep = 5;

  // H1 批1 §5.7:未解锁系统门控 — 镜像各屏 clearedStageIds prereq(单一真相源)。
  static const String _lateGameUnlockStage = 'stage_06_05'; // 心魔/轻功/群战
  static const String _socialUnlockStage = 'stage_01_05'; // 江湖/门派/排行榜

  static TutorialHintDef? _firstUnreadHint(
    int currentStep,
    List<int> hintsRead,
  ) {
    for (final def in TutorialHintDef.all) {
      if (def.step <= currentStep && !hintsRead.contains(def.step)) {
        return def;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepAsync = ref.watch(currentTutorialStepProvider);
    final step = stepAsync.maybeWhen(data: (s) => s, orElse: () => 0);

    final clearedAsync = ref.watch(mainlineProgressProvider);
    final mainlineProgress = clearedAsync.maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );
    final cleared = clearedAsync.maybeWhen(
      data: (p) => p.clearedStageIds.toSet(),
      orElse: () => <String>{},
    );
    final mainlineStatus = _mainlineMenuStatus(mainlineProgress);
    final mainlineGoal = _mainlineGoalGuidance(mainlineProgress);
    final continueJianghuStage = mainlineProgress == null
        ? null
        : resolveContinueJianghuStage(mainlineProgress);

    final inventoryStatus = ref
        .watch(allEquipmentsProvider)
        .maybeWhen(data: _inventoryMenuStatus, orElse: () => null);

    final hintsReadAsync = ref.watch(currentTutorialHintsReadProvider);
    final hintsRead = hintsReadAsync.maybeWhen(
      data: (l) => l,
      orElse: () => const <int>[],
    );
    final activeHint = _firstUnreadHint(step, hintsRead);

    final lateLocked = !cleared.contains(_lateGameUnlockStage);
    final socialLocked = !cleared.contains(_socialUnlockStage);

    // 桃花岛入口门控：unlock_chapter_index(=1,0-based)对应第二章(chapterIndex=2)通关。
    // 门槛从 config 读，不硬编码。GameRepository 未加载时（轻量 test）视为锁定。
    final taohuaUnlockChIdx =
        GameRepository.instanceOrNull?.numbers.taohuaIsland.unlockChapterIndex;
    final taohuaLocked =
        taohuaUnlockChIdx == null ||
        mainlineProgress == null ||
        !MainlineProgressService.chapterCompleted(
          progress: mainlineProgress,
          chapterIndex: taohuaUnlockChIdx + 1, // 0-based → stages.yaml 1-based
        );

    // 门派名横幅(读当前存档 sectName;轻量 test / 无档时为 null 不显)。
    final sectName = ref
        .watch(mainMenuSaveSnapshotProvider)
        .maybeWhen(data: (s) => s?.sectName, orElse: () => null);

    // 江湖远行入口门控（§7.1 · §5.7 隐藏式）：任一角色首达 Lv100 后
    // SaveData.jianghuJourneyUnlocked 永久置真。**Lv100→解锁触发**归耦合里程碑批
    // （随发布上限 10→17 一并拍板，见 design §3.1/§9），本批只消费标志、不写触发。
    final jianghuJourneyUnlocked = ref
        .watch(mainMenuSaveSnapshotProvider)
        .maybeWhen(
          data: (s) => s?.jianghuJourneyUnlocked ?? false,
          orElse: () => false,
        );

    // P4 战绩册入口门控：首次击败任一 Boss 后解锁（§5.7 隐藏式）。
    final bossCount = ref
        .watch(bossMemoryCountProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);
    final battleRecordUnlocked = bossCount > 0;

    // 兵器谱入口门控：获得过任一装备后解锁（§5.7 隐藏式）。
    final weaponCodexCount = ref
        .watch(equipmentCatalogCountProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);
    final weaponCodexUnlocked = weaponCodexCount > 0;

    // 江湖商店入口门控：曾获得银两后解锁（§5.7 隐藏式，沿兵器谱体例）。
    final shopUnlocked = ref
        .watch(shopUnlockedProvider)
        .maybeWhen(data: (b) => b, orElse: () => false);

    final journeyItems = _journeyItems(
      context,
      ref,
      mainlineStatus: mainlineStatus,
      mainlineGoal: mainlineGoal,
      continueJianghuStage: continueJianghuStage,
      lateLocked: lateLocked,
      jianghuJourneyUnlocked: jianghuJourneyUnlocked,
    );
    final growthItems = _growthItems(
      context,
      inventoryStatus: inventoryStatus,
      seclusionLocked: step < _seclusionUnlockStep,
      taohuaLocked: taohuaLocked,
      socialLocked: socialLocked,
      jianghuJourneyUnlocked: jianghuJourneyUnlocked,
      shopUnlocked: shopUnlocked,
    );
    final archiveItems = _archiveItems(
      context,
      battleRecordUnlocked: battleRecordUnlocked,
      weaponCodexUnlocked: weaponCodexUnlocked,
    );
    final debugItems = _debugItems(context);

    return MainMenuStartupGate(
      key: const ValueKey('main-menu-startup-gate'),
      child: BgmScope(
        track: BgmTrack.mainMenu,
        child: Scaffold(
          backgroundColor: WuxiaColors.background,
          body: Stack(
            children: [
              // A2 全屏水墨门面背景(占位 mountain_bg · 精修 bg 后补)。
              Positioned.fill(
                child: WuxiaImage(
                  WuxiaUi.mainMenuBg,
                  fit: BoxFit.cover,
                  errorBuilder: wuxiaAssetErrorBuilder(
                    () => const ColoredBox(color: WuxiaColors.background),
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x6614181D), Color(0xF014181D)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    key: const ValueKey('main-menu-content'),
                    constraints: const BoxConstraints(
                      maxWidth: _mainMenuContentMaxWidth,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            UiStrings.mainMenuTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: WuxiaColors.textPrimary,
                              fontSize: 40,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            UiStrings.mainMenuSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: WuxiaColors.resultHighlight,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 4,
                            ),
                          ),
                          if (sectName != null && sectName.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SectBanner(sectName: sectName),
                          ],
                          const _TodayFestivalChip(),
                          if (activeHint != null)
                            TutorialBannerCard(
                              hint: activeHint,
                              onTapOverride: activeHint.step == 6
                                  ? () async {
                                      if (!context.mounted) return;
                                      await Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RecruitmentDialog(),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          const MainMenuRetreatBanner(),
                          const MainMenuStatusSummaryPanel(),
                          const SizedBox(height: 24),
                          _MenuSectionsLayout(
                            journeyItems: journeyItems,
                            growthItems: growthItems,
                            archiveItems: archiveItems,
                            debugItems: debugItems,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 退出游戏:右上角常驻入口(桌面标配)。置于最上层确保可点。
              const _TopRightActions(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _journeyItems(
    BuildContext context,
    WidgetRef ref, {
    required String? mainlineStatus,
    required NewSaveGoalGuidance? mainlineGoal,
    required StageDef? continueJianghuStage,
    required bool lateLocked,
    required bool jianghuJourneyUnlocked,
  }) {
    return <Widget>[
      _ContinueJianghuEntry(
        primary: WuxiaInkButton(
          label: UiStrings.mainMenuMainline,
          hint: mainlineGoal == null
              ? UiStrings.mainMenuMainlineHint
              : NewSaveGoalText.mainMenuHint(mainlineGoal),
          icon: Icons.map_outlined,
          thumbnailPath: WuxiaUi.entryMainline,
          status: mainlineStatus,
          onTap: () => guardBattleEntry(
            context: context,
            ref: ref,
            onAllowed: () {
              if (continueJianghuStage == null) {
                _push(context, const ChapterListScreen());
                return;
              }
              unawaited(
                _launchContinueJianghu(context, ref, continueJianghuStage),
              );
            },
          ),
        ),
        onOpenMap: () => _push(context, const JianghuMapScreen()),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuLightFoot,
        hint: lateLocked
            ? UiStrings.mainMenuLateGameLockedHint
            : UiStrings.mainMenuLightFootHint,
        icon: Icons.directions_run,
        thumbnailPath: WuxiaUi.entryLightFoot,
        disabled: lateLocked,
        locked: lateLocked,
        onTap: () => guardBattleEntry(
          context: context,
          ref: ref,
          onAllowed: () => _push(context, const LightFootScreen()),
        ),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuMassBattle,
        hint: lateLocked
            ? UiStrings.mainMenuLateGameLockedHint
            : UiStrings.mainMenuMassBattleHint,
        icon: Icons.groups_2_outlined,
        thumbnailPath: WuxiaUi.entryJianghu,
        disabled: lateLocked,
        locked: lateLocked,
        onTap: () => guardBattleEntry(
          context: context,
          ref: ref,
          onAllowed: () => _push(context, const MassBattleScreen()),
        ),
      ),
      // 断魂庄（江湖远行 Phase C·同 jianghuJourneyUnlocked gate·§5.7 未解锁隐藏）。
      if (jianghuJourneyUnlocked)
        WuxiaInkButton(
          label: UiStrings.gauntletName,
          hint: UiStrings.gauntletSubtitle,
          icon: Icons.whatshot_outlined,
          thumbnailPath: WuxiaUi.entryJianghu,
          onTap: () => _push(context, const GauntletLoadoutScreen()),
        ),
    ];
  }

  Future<void> _launchContinueJianghu(
    BuildContext context,
    WidgetRef ref,
    StageDef stage,
  ) async {
    final testRunner = continueJianghuRunnerForTest;
    if (testRunner != null) {
      await testRunner(context, ref, stage);
      return;
    }
    await runStageFlow(
      context: context,
      ref: ref,
      stage: stage,
      targetCycle: 1,
      continueFirstClearRun: true,
    );
  }

  List<Widget> _growthItems(
    BuildContext context, {
    required String? inventoryStatus,
    required bool seclusionLocked,
    required bool taohuaLocked,
    required bool socialLocked,
    required bool jianghuJourneyUnlocked,
    required bool shopUnlocked,
  }) {
    return <Widget>[
      WuxiaInkButton(
        label: UiStrings.mainMenuSectHub,
        hint: UiStrings.mainMenuSectHubHint,
        icon: Icons.home_work_outlined,
        thumbnailPath: WuxiaUi.entryJianghu,
        onTap: () => _push(
          context,
          SectHubScreen(
            seclusionLocked: seclusionLocked,
            taohuaLocked: taohuaLocked,
            sectLocked: socialLocked,
            expeditionUnlocked: jianghuJourneyUnlocked,
          ),
        ),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuMartialInventory,
        hint: UiStrings.mainMenuMartialInventoryHint,
        icon: Icons.menu_book_outlined,
        thumbnailPath: WuxiaUi.entryTechnique,
        status: inventoryStatus,
        onTap: () => _push(context, const MartialInventoryHubScreen()),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuJianghu,
        hint: socialLocked
            ? UiStrings.mainMenuSocialLockedHint
            : UiStrings.mainMenuJianghuHint,
        icon: Icons.handshake_outlined,
        thumbnailPath: WuxiaUi.entryJianghu,
        disabled: socialLocked,
        locked: socialLocked,
        onTap: () => _push(context, const ReputationPanelScreen()),
      ),
      if (shopUnlocked)
        WuxiaInkButton(
          label: UiStrings.mainMenuShop,
          hint: UiStrings.mainMenuShopHint,
          icon: Icons.storefront_outlined,
          onTap: () => _push(context, const ShopScreen()),
        ),
    ];
  }

  List<Widget> _archiveItems(
    BuildContext context, {
    required bool battleRecordUnlocked,
    required bool weaponCodexUnlocked,
  }) {
    return <Widget>[
      WuxiaInkButton(
        label: UiStrings.mainMenuJianghuChronicle,
        hint: UiStrings.mainMenuJianghuChronicleHint,
        icon: Icons.auto_stories_outlined,
        thumbnailPath: WuxiaUi.entryCodex,
        onTap: () => _push(
          context,
          JianghuChronicleHubScreen(
            battleRecordUnlocked: battleRecordUnlocked,
            equipmentLoreUnlocked: weaponCodexUnlocked,
          ),
        ),
      ),
    ];
  }

  List<Widget> _debugItems(BuildContext context) {
    return kDebugMode
        ? <Widget>[
            WuxiaInkButton(
              label: UiStrings.mainMenuPhase2,
              hint: UiStrings.mainMenuPhase2Hint,
              icon: Icons.construction_outlined,
              onTap: () => _push(context, const Phase2TestMenu()),
            ),
            WuxiaInkButton(
              label: UiStrings.mainMenuSectRecruit,
              hint: UiStrings.mainMenuSectRecruitHint,
              icon: Icons.person_add_alt_1_outlined,
              onTap: () => _push(context, const SectRecruitDebugScreen()),
            ),
            WuxiaInkButton(
              label: UiStrings.mainMenuRedlineAudit,
              hint: UiStrings.mainMenuRedlineAuditHint,
              icon: Icons.rule_outlined,
              onTap: () => _push(context, const RedlineAuditScreen()),
            ),
          ]
        : const <Widget>[];
  }

  static String? _mainlineMenuStatus(MainlineProgress? progress) {
    if (progress == null || !GameRepository.isLoaded) return null;
    for (final chapterIndex in _mainlineChapterIndexes()) {
      final stages = MainlineProgressService.availableStages(
        progress: progress,
        chapterIndex: chapterIndex,
      );
      for (final entry in stages) {
        if (entry.status == StageStatus.available) {
          return UiStrings.mainMenuMainlineStatus(chapterIndex, entry.def.name);
        }
      }
    }
    return UiStrings.mainMenuMainlineCompleteStatus;
  }

  static NewSaveGoalGuidance? _mainlineGoalGuidance(
    MainlineProgress? progress,
  ) {
    if (progress == null || !GameRepository.isLoaded) return null;
    for (final chapterIndex in _mainlineChapterIndexes()) {
      final entries = MainlineProgressService.availableStages(
        progress: progress,
        chapterIndex: chapterIndex,
      );
      final guidance = NewSaveGoalGuidance.fromChapterEntries(
        chapterIndex: chapterIndex,
        entries: entries,
      );
      if (guidance != null) return guidance;
    }
    return null;
  }

  static String _inventoryMenuStatus(List<Equipment> equipments) {
    if (equipments.isEmpty) {
      return UiStrings.mainMenuInventoryStatus(0, '');
    }
    final top = equipments.reduce(
      (a, b) => a.tier.index >= b.tier.index ? a : b,
    );
    return UiStrings.mainMenuInventoryStatus(
      equipments.length,
      EnumL10n.equipmentTier(top.tier),
    );
  }
}

class _ContinueJianghuEntry extends StatelessWidget {
  const _ContinueJianghuEntry({required this.primary, required this.onOpenMap});

  final Widget primary;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primary,
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            button: true,
            label: UiStrings.mainMenuJianghuMapAction,
            hint: UiStrings.mainMenuJianghuMapActionHint,
            child: TextButton.icon(
              key: const ValueKey('main-menu-jianghu-map-action'),
              onPressed: onOpenMap,
              style: TextButton.styleFrom(
                foregroundColor: WuxiaColors.resultHighlight,
                backgroundColor: WuxiaUi.ink.withValues(alpha: 0.48),
                side: BorderSide(
                  color: WuxiaColors.resultHighlight.withValues(alpha: 0.42),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              icon: const Icon(Icons.public_outlined, size: 17),
              label: const Text(UiStrings.mainMenuJianghuMapAction),
            ),
          ),
        ),
      ],
    );
  }
}

/// 入口分组标签:篆印图标 + 标题 + 短说明,用于水墨分区版式。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: WuxiaUi.jiang.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: WuxiaUi.jiang.withValues(alpha: 0.58)),
          ),
          child: Icon(icon, size: 18, color: WuxiaUi.paper),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 15,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WuxiaColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuSectionsLayout extends StatelessWidget {
  const _MenuSectionsLayout({
    required this.journeyItems,
    required this.growthItems,
    required this.archiveItems,
    required this.debugItems,
  });

  final List<Widget> journeyItems;
  final List<Widget> growthItems;
  final List<Widget> archiveItems;
  final List<Widget> debugItems;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final canUseTwoColumns = constraints.maxWidth >= 680;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MenuSection(
                title: UiStrings.mainMenuGroupJourney,
                subtitle: UiStrings.mainMenuGroupJourneyHint,
                icon: Icons.explore_outlined,
                items: journeyItems,
                twoColumn: canUseTwoColumns,
              ),
              const SizedBox(height: 18),
              _MenuSection(
                title: UiStrings.mainMenuGroupGrowth,
                subtitle: UiStrings.mainMenuGroupGrowthHint,
                icon: Icons.spa_outlined,
                items: growthItems,
                twoColumn: canUseTwoColumns,
              ),
              const SizedBox(height: 18),
              _MenuSection(
                title: UiStrings.mainMenuGroupArchive,
                subtitle: UiStrings.mainMenuGroupArchiveHint,
                icon: Icons.article_outlined,
                items: archiveItems,
                twoColumn: canUseTwoColumns,
              ),
              if (debugItems.isNotEmpty) ...[
                const SizedBox(height: 18),
                _MenuSection(
                  title: UiStrings.mainMenuGroupDebug,
                  subtitle: UiStrings.mainMenuGroupDebugHint,
                  icon: Icons.bug_report_outlined,
                  items: debugItems,
                  twoColumn: canUseTwoColumns,
                ),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MenuSection(
              title: UiStrings.mainMenuGroupJourney,
              subtitle: UiStrings.mainMenuGroupJourneyHint,
              icon: Icons.explore_outlined,
              items: journeyItems,
              twoColumn: true,
              featured: true,
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _MenuSection(
                    title: UiStrings.mainMenuGroupGrowth,
                    subtitle: UiStrings.mainMenuGroupGrowthHint,
                    icon: Icons.spa_outlined,
                    items: growthItems,
                    twoColumn: true,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: _MenuSection(
                    title: UiStrings.mainMenuGroupArchive,
                    subtitle: UiStrings.mainMenuGroupArchiveHint,
                    icon: Icons.article_outlined,
                    items: archiveItems,
                    twoColumn: false,
                  ),
                ),
              ],
            ),
            if (debugItems.isNotEmpty) ...[
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 720,
                  child: _MenuSection(
                    title: UiStrings.mainMenuGroupDebug,
                    subtitle: UiStrings.mainMenuGroupDebugHint,
                    icon: Icons.bug_report_outlined,
                    items: debugItems,
                    twoColumn: true,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    this.twoColumn = false,
    this.featured = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> items;
  final bool twoColumn;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final body = twoColumn ? _twoColumn(items) : _oneColumn(items);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaColors.panel.withValues(alpha: featured ? 0.78 : 0.68),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: featured
              ? WuxiaUi.gold.withValues(alpha: 0.52)
              : WuxiaColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: featured ? 0.12 : 0.08,
                child: WuxiaImage(
                  WuxiaUi.paperBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionLabel(title: title, subtitle: subtitle, icon: icon),
                  const SizedBox(height: 14),
                  ...body,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 今日节日 chip(W16 GDD §12.4)。非节日 → 零高度 SizedBox.shrink()。
class _TodayFestivalChip extends ConsumerWidget {
  const _TodayFestivalChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final festival = ref.watch(todayFestivalProvider);
    if (festival == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: WuxiaColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WuxiaColors.border),
          ),
          child: Text(
            UiStrings.mainMenuTodayFestival(EnumL10n.festival(festival)),
            style: const TextStyle(
              color: WuxiaColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// 右上角常驻工具区：资源、设置、退出与既有状态 pill。
class _TopRightActions extends StatelessWidget {
  const _TopRightActions();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SweepReadinessPill(
                tone: CurrencyPillTone.dark,
                compact: true,
              ),
              const SizedBox(width: 8),
              const SilverBalancePill(
                tone: CurrencyPillTone.dark,
                compact: true,
              ),
              const SizedBox(width: 8),
              WuxiaIconButton(
                tooltip: UiStrings.mainMenuResourceOverview,
                icon: Icons.account_balance_wallet_outlined,
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const ResourceOverviewScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              WuxiaIconButton(
                tooltip: UiStrings.mainMenuSettings,
                icon: Icons.settings_outlined,
                onPressed: () => SettingsPanel.show(context),
              ),
              const SizedBox(width: 8),
              WuxiaIconButton(
                tooltip: UiStrings.mainMenuQuitTooltip,
                icon: Icons.power_settings_new,
                destructive: true,
                onPressed: () => AppExit.confirmAndQuit(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
