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
import '../../cangjingge/presentation/cangjingge_screen.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../character_panel/presentation/lineage_panel_screen.dart';
import '../../debug/presentation/battle_test_menu.dart';
import '../../debug/presentation/phase2_test_menu.dart';
import '../../debug/presentation/sect_recruit_debug_screen.dart';
import '../../festival/application/festival_service_providers.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../inner_demon/presentation/inner_demon_screen.dart';
import '../../jianghu/presentation/reputation_panel_screen.dart';
import '../../light_foot/presentation/light_foot_screen.dart';
import '../../mass_battle/presentation/mass_battle_screen.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/presentation/chapter_list_screen.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../pvp/presentation/pvp_screen.dart';
import '../../seclusion/application/seclusion_service_providers.dart';
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
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../../tutorial/domain/tutorial_hint_def.dart';
import '../../tutorial/presentation/tutorial_banner_card.dart';
import '../../tower/presentation/leaderboard_screen.dart';
import '../../tower/application/tower_progress_service.dart';
import '../../tower/application/tower_providers.dart';
import '../../tower/domain/tower_progress.dart';
import '../../tower/presentation/tower_floor_list_screen.dart';
import '../../mainline/application/mainline_providers.dart';

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
            const SizedBox(width: 12),
            Expanded(child: right ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
    if (i + 2 < items.length) rows.add(const SizedBox(height: 12));
  }
  return rows;
}

List<Widget> _oneColumn(List<Widget> items) {
  final rows = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    rows.add(items[i]);
    if (i + 1 < items.length) rows.add(const SizedBox(height: 10));
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
  static const String _pvpUnlockStage = 'stage_05_05';
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
    final pvpLocked = !cleared.contains(_pvpUnlockStage);
    final socialLocked = !cleared.contains(_socialUnlockStage);

    final coreItems = <Widget>[
      WuxiaInkButton(
        label: UiStrings.mainMenuMainline,
        hint: UiStrings.mainMenuMainlineHint,
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
    ];

    final battleItems = <Widget>[
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
      WuxiaInkButton(
        label: UiStrings.mainMenuPvp,
        hint: pvpLocked ? UiStrings.pvpLockedHint : UiStrings.mainMenuPvpHint,
        icon: Icons.gavel_outlined,
        thumbnailPath: WuxiaUi.entryJianghu,
        disabled: pvpLocked,
        locked: pvpLocked,
        onTap: () => _push(context, const PvpScreen()),
      ),
    ];

    final jianghuItems = <Widget>[
      WuxiaInkButton(
        label: UiStrings.mainMenuLineage,
        hint: UiStrings.mainMenuLineageHint,
        icon: Icons.account_tree_outlined,
        thumbnailPath: WuxiaUi.entryCharacter,
        onTap: () => _push(context, const LineagePanelScreen()),
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
        label: UiStrings.mainMenuBaike,
        hint: UiStrings.mainMenuBaikeHint,
        icon: Icons.menu_book_outlined,
        thumbnailPath: WuxiaUi.entryCodex,
        onTap: () => _push(context, const BaikeScreen()),
      ),
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
              label: '强制招募 NPC',
              hint: '走完整 sect recruit flow · 跳过战斗/奇遇触发',
              icon: Icons.person_add_alt_1_outlined,
              onTap: () => _push(context, const SectRecruitDebugScreen()),
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
            child: Image.asset(
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
                constraints: const BoxConstraints(maxWidth: 1120),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 16,
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
                                      builder: (_) => const RecruitmentDialog(),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      const SizedBox(height: 24),
                      _MenuSectionsLayout(
                        coreItems: coreItems,
                        battleItems: battleItems,
                        jianghuItems: jianghuItems,
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

/// 入口分组标签(Phase A · 主/次分组):小字 + 分隔线。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: WuxiaColors.textMuted,
              fontSize: 13,
              letterSpacing: 6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Divider(color: WuxiaColors.border, thickness: 1),
          ),
        ],
      ),
    );
  }
}

class _MenuSectionsLayout extends StatelessWidget {
  const _MenuSectionsLayout({
    required this.coreItems,
    required this.battleItems,
    required this.jianghuItems,
    required this.debugItems,
  });

  final List<Widget> coreItems;
  final List<Widget> battleItems;
  final List<Widget> jianghuItems;
  final List<Widget> debugItems;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MenuSection(
                title: UiStrings.mainMenuGroupCore,
                items: coreItems,
                compact: true,
              ),
              _MenuSection(
                title: UiStrings.mainMenuGroupBattle,
                items: battleItems,
                compact: true,
              ),
              _MenuSection(
                title: UiStrings.mainMenuGroupJianghu,
                items: jianghuItems,
                compact: true,
              ),
              if (debugItems.isNotEmpty)
                _MenuSection(
                  title: UiStrings.mainMenuGroupDebug,
                  items: debugItems,
                  compact: true,
                ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MenuSection(
                    title: UiStrings.mainMenuGroupCore,
                    items: coreItems,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MenuSection(
                    title: UiStrings.mainMenuGroupBattle,
                    items: battleItems,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MenuSection(
                    title: UiStrings.mainMenuGroupJianghu,
                    items: jianghuItems,
                  ),
                ),
              ],
            ),
            if (debugItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              _MenuSection(
                title: UiStrings.mainMenuGroupDebug,
                items: debugItems,
                compact: true,
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
    required this.items,
    this.compact = false,
  });

  final String title;
  final List<Widget> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(title),
        ...compact ? _twoColumn(items) : _oneColumn(items),
      ],
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
