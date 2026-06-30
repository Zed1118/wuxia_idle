import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/application/character_providers.dart';
import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../baike/presentation/baike_screen.dart';
import '../../battle_record/application/boss_memory_providers.dart';
import '../../battle_record/presentation/battle_record_screen.dart';
import '../../weapon_codex/application/equipment_catalog_providers.dart';
import '../../weapon_codex/presentation/weapon_codex_screen.dart';
import '../../cangjingge/presentation/cangjingge_screen.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../character_panel/presentation/lineage_panel_screen.dart';
import '../../debug/presentation/battle_test_menu.dart';
import '../../debug/presentation/phase2_test_menu.dart';
import '../../debug/presentation/redline_audit_screen.dart';
import '../../debug/presentation/sect_recruit_debug_screen.dart';
import '../../festival/application/festival_service_providers.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../inner_demon/presentation/inner_demon_screen.dart';
import '../../jianghu/presentation/reputation_panel_screen.dart';
import '../../light_foot/presentation/light_foot_screen.dart';
import '../../mass_battle/presentation/mass_battle_screen.dart';
import '../../resource_overview/presentation/resource_overview_screen.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/application/new_save_goal_guidance.dart';
import '../../mainline/presentation/chapter_list_screen.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../mainline/presentation/new_save_goal_guidance_view.dart';
import '../../seclusion/application/seclusion_service_providers.dart';
import '../../taohua_island/presentation/taohua_island_screen.dart';
import '../../seclusion/domain/retreat_session.dart';
import '../../seclusion/presentation/seclusion_gate.dart';
import '../../recruitment/presentation/recruitment_dialog.dart';
import '../../seclusion/presentation/seclusion_map_list_screen.dart';
import '../../sect/presentation/sect_screen.dart';
import '../../settings/presentation/settings_panel.dart';
import '../../../shared/app_exit.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/bgm_scope.dart';
import '../../../shared/strings.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_image.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../../tutorial/domain/tutorial_hint_def.dart';
import '../../tutorial/presentation/tutorial_banner_card.dart';
import '../../tower/presentation/leaderboard_screen.dart';
import 'main_menu_retreat_banner.dart';
import '../../tower/application/tower_progress_service.dart';
import '../../tower/application/tower_providers.dart';
import '../../tower/domain/tower_progress.dart';
import '../../tower/presentation/tower_floor_list_screen.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../shop/application/shop_providers.dart';
import '../../shop/presentation/shop_screen.dart';
import '../../zangjuange/presentation/zangjuange_screen.dart';
import 'main_menu_status_summary.dart';

const double _mainMenuContentMaxWidth = 1088;
const double _entryColumnGap = 16;
const double _entryRowGap = 16;

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
  const MainMenu({super.key});

  static const int _defaultCharacterId = 1;
  static const RealmTier _defaultRealmTier = RealmTier.xueTu;

  void _push(BuildContext context, Widget child) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => child));
  }

  static const int _techniquesUnlockStep = 3;
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

    final towerStatus = ref
        .watch(towerProgressProvider)
        .maybeWhen(data: _towerMenuStatus, orElse: () => null);
    final inventoryStatus = ref
        .watch(allEquipmentsProvider)
        .maybeWhen(data: _inventoryMenuStatus, orElse: () => null);

    final hintsReadAsync = ref.watch(currentTutorialHintsReadProvider);
    final hintsRead = hintsReadAsync.maybeWhen(
      data: (l) => l,
      orElse: () => const <int>[],
    );
    final activeHint = _firstUnreadHint(step, hintsRead);

    final techLocked = step < _techniquesUnlockStep;
    final skillLibLocked = step < _techniquesUnlockStep; // §5.7：修了心法才有技能可装
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

    final journeyItems = <Widget>[
      WuxiaInkButton(
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
          onAllowed: () => _push(context, const ChapterListScreen()),
        ),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuTower,
        hint: UiStrings.mainMenuTowerHint,
        icon: Icons.filter_hdr_outlined,
        thumbnailPath: WuxiaUi.entryTower,
        status: towerStatus,
        onTap: () => guardBattleEntry(
          context: context,
          ref: ref,
          onAllowed: () => _push(context, const TowerFloorListScreen()),
        ),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuInnerDemon,
        hint: lateLocked
            ? UiStrings.mainMenuLateGameLockedHint
            : UiStrings.mainMenuInnerDemonHint,
        icon: Icons.psychology_alt_outlined,
        thumbnailPath: WuxiaUi.entryTechnique,
        disabled: lateLocked,
        locked: lateLocked,
        onTap: () => _push(context, const InnerDemonScreen()),
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
    ];

    final growthItems = <Widget>[
      WuxiaInkButton(
        label: UiStrings.mainMenuCharacterPanel,
        hint: UiStrings.mainMenuCharacterPanelHint,
        icon: Icons.person_outline,
        thumbnailPath: WuxiaUi.entryCharacter,
        onTap: () => _push(
          context,
          const CharacterPanelScreen(characterId: _defaultCharacterId),
        ),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuInventory,
        hint: UiStrings.mainMenuInventoryHint,
        icon: Icons.inventory_2_outlined,
        thumbnailPath: WuxiaUi.entryInventory,
        status: inventoryStatus,
        onTap: () => _push(context, const InventoryScreen()),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuResourceOverview,
        hint: UiStrings.mainMenuResourceOverviewHint,
        icon: Icons.account_balance_wallet_outlined,
        thumbnailPath: WuxiaUi.entryInventory,
        onTap: () => _push(context, const ResourceOverviewScreen()),
      ),
      _TechniqueMenuButton(
        characterId: _defaultCharacterId,
        tutorialLocked: techLocked,
        onPush: (screen) => _push(context, screen),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuSkillLibrary,
        hint: skillLibLocked
            ? UiStrings.mainMenuSkillLibraryLockedHint
            : UiStrings.mainMenuSkillLibraryHint,
        icon: Icons.menu_book_outlined,
        thumbnailPath: WuxiaUi.entryTechnique,
        disabled: skillLibLocked,
        locked: skillLibLocked,
        onTap: skillLibLocked
            ? null
            : () => _push(
                context,
                const CangJingGeScreen(characterId: _defaultCharacterId),
              ),
      ),
      _SeclusionMenuButton(
        defaultCharacterId: _defaultCharacterId,
        defaultRealmTier: _defaultRealmTier,
        onPush: (screen) => _push(context, screen),
        tutorialLocked: step < _seclusionUnlockStep,
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuTaohuaIsland,
        hint: taohuaLocked
            ? UiStrings.mainMenuTaohuaIslandLockedHint
            : UiStrings.mainMenuTaohuaIslandHint,
        icon: Icons.cottage_outlined,
        thumbnailPath: WuxiaUi.entryJianghu,
        disabled: taohuaLocked,
        locked: taohuaLocked,
        onTap: () => _push(context, const TaohuaIslandScreen()),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuSect,
        hint: socialLocked
            ? UiStrings.mainMenuSocialLockedHint
            : UiStrings.mainMenuSectHint,
        icon: Icons.home_work_outlined,
        thumbnailPath: WuxiaUi.entryJianghu,
        disabled: socialLocked,
        locked: socialLocked,
        onTap: () => _push(context, const SectScreen()),
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

    final archiveItems = <Widget>[
      WuxiaInkButton(
        label: UiStrings.mainMenuLineage,
        hint: UiStrings.mainMenuLineageHint,
        icon: Icons.account_tree_outlined,
        thumbnailPath: WuxiaUi.entryCharacter,
        onTap: () => _push(context, const LineagePanelScreen()),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuLeaderboard,
        hint: socialLocked
            ? UiStrings.mainMenuSocialLockedHint
            : UiStrings.mainMenuLeaderboardHint,
        icon: Icons.emoji_events_outlined,
        thumbnailPath: WuxiaUi.entryTower,
        disabled: socialLocked,
        locked: socialLocked,
        onTap: () => _push(context, const LeaderboardScreen()),
      ),
      WuxiaInkButton(
        label: UiStrings.mainMenuZangjuange,
        hint: socialLocked
            ? UiStrings.mainMenuSocialLockedHint
            : UiStrings.mainMenuZangjuangeHint,
        icon: Icons.library_books_outlined,
        thumbnailPath: WuxiaUi.entryCodex,
        disabled: socialLocked,
        locked: socialLocked,
        onTap: () => _push(context, const ZangjuangeScreen()),
      ),
      if (battleRecordUnlocked)
        WuxiaInkButton(
          label: UiStrings.mainMenuBattleRecord,
          hint: UiStrings.mainMenuBattleRecordHint,
          icon: Icons.history_edu_outlined, // 美术待补专属 thumbnail
          onTap: () => _push(context, const BattleRecordScreen()),
        ),
      if (weaponCodexUnlocked)
        WuxiaInkButton(
          label: UiStrings.mainMenuWeaponCodex,
          hint: UiStrings.mainMenuWeaponCodexHint,
          icon: Icons.auto_stories_outlined,
          onTap: () => _push(context, const WeaponCodexScreen()),
        ),
      WuxiaInkButton(
        label: UiStrings.mainMenuBaike,
        hint: UiStrings.mainMenuBaikeHint,
        icon: Icons.menu_book_outlined,
        thumbnailPath: WuxiaUi.entryCodex,
        onTap: () => _push(context, const BaikeScreen()),
      ),
    ];

    final settingsItems = <Widget>[
      WuxiaInkButton(
        label: UiStrings.mainMenuSettings,
        hint: UiStrings.mainMenuSettingsHint,
        icon: Icons.settings_outlined,
        onTap: () => SettingsPanel.show(context),
      ),
    ];

    final debugItems = kDebugMode
        ? <Widget>[
            WuxiaInkButton(
              label: UiStrings.mainMenuPhase1,
              hint: UiStrings.mainMenuPhase1Hint,
              icon: Icons.bug_report_outlined,
              onTap: () => _push(context, const BattleTestMenu()),
            ),
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

    return BgmScope(
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
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
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
                          settingsItems: settingsItems,
                          debugItems: debugItems,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 退出游戏:右上角常驻入口(桌面标配)。置于最上层确保可点。
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    tooltip: UiStrings.mainMenuQuitTooltip,
                    icon: const Icon(
                      Icons.power_settings_new,
                      color: WuxiaColors.textMuted,
                    ),
                    onPressed: () => AppExit.confirmAndQuit(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _mainlineMenuStatus(MainlineProgress? progress) {
    if (progress == null || !GameRepository.isLoaded) return null;
    for (var chapterIndex = 1; chapterIndex <= 6; chapterIndex++) {
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
    for (var chapterIndex = 1; chapterIndex <= 6; chapterIndex++) {
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

  static String _towerMenuStatus(TowerProgress progress) {
    final highest = progress.highestClearedFloor;
    if (highest >= 30) return UiStrings.mainMenuTowerCompleteStatus;
    final next = TowerProgressService.availableFloor(progress);
    final nextIsBoss =
        GameRepository.isLoaded &&
        GameRepository.instance.towerFloors.any(
          (f) => f.floorIndex == next && f.isBoss,
        );
    if (nextIsBoss) return UiStrings.mainMenuTowerBossStatus(highest, next);
    return UiStrings.mainMenuTowerStatus(highest, next);
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
    required this.settingsItems,
    required this.debugItems,
  });

  final List<Widget> journeyItems;
  final List<Widget> growthItems;
  final List<Widget> archiveItems;
  final List<Widget> settingsItems;
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
              const SizedBox(height: 18),
              _MenuSection(
                title: UiStrings.mainMenuGroupSettings,
                subtitle: UiStrings.mainMenuGroupSettingsHint,
                icon: Icons.tune_outlined,
                items: settingsItems,
                twoColumn: false,
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
            const SizedBox(height: 18),
            if (debugItems.isEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 420,
                  child: _MenuSection(
                    title: UiStrings.mainMenuGroupSettings,
                    subtitle: UiStrings.mainMenuGroupSettingsHint,
                    icon: Icons.tune_outlined,
                    items: settingsItems,
                    twoColumn: false,
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MenuSection(
                      title: UiStrings.mainMenuGroupSettings,
                      subtitle: UiStrings.mainMenuGroupSettingsHint,
                      icon: Icons.tune_outlined,
                      items: settingsItems,
                      twoColumn: false,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 2,
                    child: _MenuSection(
                      title: UiStrings.mainMenuGroupDebug,
                      subtitle: UiStrings.mainMenuGroupDebugHint,
                      icon: Icons.bug_report_outlined,
                      items: debugItems,
                      twoColumn: true,
                    ),
                  ),
                ],
              ),
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

class _TechniqueMenuButton extends ConsumerWidget {
  const _TechniqueMenuButton({
    required this.characterId,
    required this.tutorialLocked,
    required this.onPush,
  });

  final int characterId;
  final bool tutorialLocked;
  final void Function(Widget screen) onPush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chAsync = ref.watch(characterByIdProvider(characterId));
    final character = chAsync.maybeWhen(data: (c) => c, orElse: () => null);
    final techs = ref.watch(characterAllTechniquesProvider(characterId));
    final status = tutorialLocked
        ? UiStrings.mainMenuTechniquesLockedStatus
        : _techniqueStatus(character, techs.value);

    return WuxiaInkButton(
      label: UiStrings.mainMenuTechniques,
      hint: tutorialLocked
          ? UiStrings.mainMenuTechniquesLockedHint
          : UiStrings.mainMenuTechniquesHint,
      icon: Icons.auto_stories_outlined,
      thumbnailPath: WuxiaUi.entryTechnique,
      status: status,
      disabled: tutorialLocked,
      locked: tutorialLocked,
      onTap: tutorialLocked
          ? null
          : () => onPush(TechniquePanelScreen(characterId: characterId)),
    );
  }

  static String? _techniqueStatus(
    Character? character,
    List<Technique>? techniques,
  ) {
    if (character == null) return null;
    if (character.insightPoints > 0) {
      return UiStrings.mainMenuTechniquesInsightStatus(character.insightPoints);
    }
    if (character.mainTechniqueId == null) {
      return UiStrings.mainMenuTechniquesNoMainStatus;
    }
    final count = techniques?.length;
    if (count == null || count <= 0) return null;
    return UiStrings.mainMenuTechniquesKnownStatus(count);
  }
}

/// 闭关入口(销账 #26)。异步读首位角色 + 境界;加载中置灰;空/错误兜底 id=1。
class _SeclusionMenuButton extends ConsumerWidget {
  const _SeclusionMenuButton({
    required this.defaultCharacterId,
    required this.defaultRealmTier,
    required this.onPush,
    this.tutorialLocked = false,
  });

  final int defaultCharacterId;
  final RealmTier defaultRealmTier;
  final void Function(Widget screen) onPush;
  final bool tutorialLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = ref.watch(activeCharacterIdsProvider);

    final firstId = idsAsync.maybeWhen(
      data: (ids) => ids.isNotEmpty ? ids.first : defaultCharacterId,
      orElse: () => defaultCharacterId,
    );

    final charAsync = ref.watch(characterByIdProvider(firstId));

    final loading = idsAsync.isLoading || charAsync.isLoading;
    final character = charAsync.maybeWhen(data: (c) => c, orElse: () => null);
    final realmTier = character?.realmTier ?? defaultRealmTier;
    final characterId = character?.id ?? defaultCharacterId;
    final disabled = loading || tutorialLocked;
    final baseStatus = tutorialLocked
        ? UiStrings.mainMenuSeclusionLockedStatus
        : UiStrings.mainMenuSeclusionReadyStatus;
    final svc = ref.watch(seclusionServiceProvider);

    if (svc != null && !tutorialLocked && !loading) {
      return FutureBuilder<RetreatSession?>(
        future: svc.getActiveSession(IsarSetup.currentSlotId),
        builder: (context, snapshot) {
          final session = snapshot.data;
          final status = session == null
              ? baseStatus
              : _activeRetreatStatus(session);
          return _button(
            status: status,
            disabled: disabled,
            realmTier: realmTier,
            characterId: characterId,
          );
        },
      );
    }

    return _button(
      status: baseStatus,
      disabled: disabled,
      realmTier: realmTier,
      characterId: characterId,
    );
  }

  Widget _button({
    required String status,
    required bool disabled,
    required RealmTier realmTier,
    required int characterId,
  }) {
    return WuxiaInkButton(
      label: UiStrings.mainMenuSeclusion,
      hint: tutorialLocked
          ? UiStrings.mainMenuSeclusionLockedHint
          : UiStrings.mainMenuSeclusionHint,
      icon: Icons.landscape_outlined,
      thumbnailPath: WuxiaUi.entrySeclusion,
      status: status,
      disabled: disabled,
      locked: tutorialLocked,
      onTap: disabled
          ? null
          : () => onPush(
              SeclusionMapListScreen(
                charRealmTier: realmTier,
                characterId: characterId,
              ),
            ),
    );
  }

  static String _activeRetreatStatus(RetreatSession session) {
    final mapDef = GameRepository.instance.getSeclusionMap(session.mapType);
    final elapsed = DateTime.now().difference(session.startedAt).inSeconds;
    final planned = session.durationHours * 3600;
    final cap = (GameRepository.instance.numbers.retreat.capHours * 3600)
        .round();
    if (cap <= planned && elapsed >= cap) {
      return UiStrings.mainMenuSeclusionCappedStatus(mapDef.mapName);
    }
    if (elapsed >= planned) {
      return UiStrings.mainMenuSeclusionDoneStatus(mapDef.mapName);
    }
    return UiStrings.mainMenuSeclusionActiveStatus(mapDef.mapName);
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
