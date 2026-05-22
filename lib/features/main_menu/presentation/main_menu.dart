import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/application/character_providers.dart';
import '../../baike/presentation/baike_screen.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../character_panel/presentation/lineage_panel_screen.dart';
import '../../debug/presentation/battle_test_menu.dart';
import '../../debug/presentation/phase2_test_menu.dart';
import '../../festival/application/festival_service_providers.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../inner_demon/presentation/inner_demon_screen.dart';
import '../../light_foot/presentation/light_foot_screen.dart';
import '../../mainline/presentation/chapter_list_screen.dart';
import '../../recruitment/presentation/recruitment_dialog.dart';
import '../../seclusion/presentation/seclusion_map_list_screen.dart';
import '../../../shared/strings.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../../../shared/theme/colors.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../../tutorial/domain/tutorial_hint_def.dart';
import '../../tutorial/presentation/tutorial_banner_card.dart';
import '../../tower/presentation/leaderboard_screen.dart';
import '../../tower/presentation/tower_floor_list_screen.dart';

/// 调试主菜单（phase2_tasks.md T32 §492-509 子提交 3b + T56 闭关入口 FutureBuilder 化 + W17 候选 E 师徒名单入口）。
///
/// `main.dart` 的新 `home`，取代 [BattleTestMenu]。9 个按钮串接：
/// - Phase 1 战斗测试 → [BattleTestMenu]（沿用 T17 入口）
/// - Phase 2 调试场景 → [Phase2TestMenu]（T32 子提交 3d 新建）
/// - 角色面板 → [CharacterPanelScreen]，初始 `characterId=1`（T56 内部 Tab 可切换 3 角色）
/// - 师徒名单 → [LineagePanelScreen]（W17 候选 E 全局关系视图）
/// - 闭关修炼 → [SeclusionMapListScreen]，**异步**读 SaveData 首位角色 + 境界（销账 #26）
/// - 装备仓库 → [InventoryScreen]
/// - 心法面板 → [TechniquePanelScreen]，固定 `characterId=1`
///
/// 套用 [BattleTestMenu] 的 `_ScenarioButton` 视觉风格（panel 背景 + 标题 + hint），
/// 不抽 helper 一例一份就够。
class MainMenu extends ConsumerWidget {
  const MainMenu({super.key});

  static const int _defaultCharacterId = 1;
  static const RealmTier _defaultRealmTier = RealmTier.xueTu;

  void _push(BuildContext context, Widget child) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => child));
  }

  static const int _techniquesUnlockStep = 3;
  static const int _seclusionUnlockStep = 5;

  /// P1.y · 取 [TutorialHintDef.all] 中第 1 个 `step <= currentStep` 且
  /// `step ∉ hintsRead` 的 hint。无未读 hint → null(spec R3 风险处置:
  /// 避免 step 已到 8 但 6/7/8 都未读时同时显 3 banner)。
  static TutorialHintDef? _firstUnreadHint(int currentStep, List<int> hintsRead) {
    for (final def in TutorialHintDef.all) {
      if (def.step <= currentStep && !hintsRead.contains(def.step)) {
        return def;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // P1 #42 Phase 2 §10 P1.x:tutorialStep 门槛 wire(loading 时按 0 兜底)。
    final stepAsync = ref.watch(currentTutorialStepProvider);
    final step = stepAsync.maybeWhen(data: (s) => s, orElse: () => 0);
    // P1 #42 Phase 2 §10 P1.y:取第 1 个未读 hint(R3 风险处置,避免同时显多 banner)。
    final hintsReadAsync = ref.watch(currentTutorialHintsReadProvider);
    final hintsRead =
        hintsReadAsync.maybeWhen(data: (l) => l, orElse: () => const <int>[]);
    final activeHint = _firstUnreadHint(step, hintsRead);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/ui/mountain_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const Text(
                  UiStrings.mainMenuTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const _TodayFestivalChip(),
                if (activeHint != null)
                  TutorialBannerCard(
                    hint: activeHint,
                    // P1.1 A1 E.1:step 6 收徒 banner 点击 → push RecruitmentDialog
                    // (而非默认 markHintRead 关 banner)。dialog 内部完成
                    // markHintRead + markOffered + invalidate(无论拜师/谢绝)。
                    // recruitmentOffered=true 时 banner 不会再显(见 _firstUnreadHint)。
                    onTapOverride: activeHint.step == 6
                        ? () async {
                            if (!context.mounted) return;
                            await Navigator.of(context)
                                .push<void>(MaterialPageRoute(
                              builder: (_) => const RecruitmentDialog(),
                            ));
                          }
                        : null,
                  ),
                const SizedBox(height: 48),
                _MenuButton(
                  label: UiStrings.mainMenuMainline,
                  hint: UiStrings.mainMenuMainlineHint,
                  onTap: () => _push(context, const ChapterListScreen()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuTower,
                  hint: UiStrings.mainMenuTowerHint,
                  onTap: () => _push(context, const TowerFloorListScreen()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuInnerDemon,
                  hint: UiStrings.mainMenuInnerDemonHint,
                  onTap: () => _push(context, const InnerDemonScreen()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuLightFoot,
                  hint: UiStrings.mainMenuLightFootHint,
                  onTap: () => _push(context, const LightFootScreen()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuLeaderboard,
                  hint: UiStrings.mainMenuLeaderboardHint,
                  onTap: () => _push(context, const LeaderboardScreen()),
                ),
                const SizedBox(height: 16),
                _SeclusionMenuButton(
                  defaultCharacterId: _defaultCharacterId,
                  defaultRealmTier: _defaultRealmTier,
                  onPush: (screen) => _push(context, screen),
                  tutorialLocked: step < _seclusionUnlockStep,
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuPhase1,
                  hint: UiStrings.mainMenuPhase1Hint,
                  onTap: () => _push(context, const BattleTestMenu()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuPhase2,
                  hint: UiStrings.mainMenuPhase2Hint,
                  onTap: () => _push(context, const Phase2TestMenu()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuCharacterPanel,
                  hint: UiStrings.mainMenuCharacterPanelHint,
                  onTap: () => _push(
                    context,
                    const CharacterPanelScreen(
                      characterId: _defaultCharacterId,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuLineage,
                  hint: UiStrings.mainMenuLineageHint,
                  onTap: () => _push(context, const LineagePanelScreen()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuBaike,
                  hint: UiStrings.mainMenuBaikeHint,
                  onTap: () => _push(context, const BaikeScreen()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuInventory,
                  hint: UiStrings.mainMenuInventoryHint,
                  onTap: () => _push(context, const InventoryScreen()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuTechniques,
                  hint: step < _techniquesUnlockStep
                      ? UiStrings.mainMenuTechniquesLockedHint
                      : UiStrings.mainMenuTechniquesHint,
                  disabled: step < _techniquesUnlockStep,
                  onTap: () => _push(
                    context,
                    const TechniquePanelScreen(
                      characterId: _defaultCharacterId,
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}

/// 闭关入口（销账 #26）。
///
/// 异步读 [activeCharacterIdsProvider] 首位 + [characterByIdProvider] 解析境界。
/// 加载中 → 按钮置灰不可点；空 / 错误 → 兜底 `id=1 / RealmTier.xueTu`（与
/// 旧逻辑等价，保证不可达分支不破坏游戏体验）。
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

  /// P1 #42 Phase 2 §10 P1.x:tutorialStep < 5 时显示灰显 + 引导文案,
  /// 与 [loading] 并联灰显(任一为真即禁用)。
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
    final character = charAsync.maybeWhen(
      data: (c) => c,
      orElse: () => null,
    );
    final realmTier = character?.realmTier ?? defaultRealmTier;
    final characterId = character?.id ?? defaultCharacterId;
    final disabled = loading || tutorialLocked;

    return _MenuButton(
      label: UiStrings.mainMenuSeclusion,
      hint: tutorialLocked
          ? UiStrings.mainMenuSeclusionLockedHint
          : UiStrings.mainMenuSeclusionHint,
      disabled: disabled,
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
}

/// 今日节日 chip（W16 GDD §12.4）。
///
/// 今日是节日 → 标题下方显示「今日：春节」chip；非节日 → 渲染零高度
/// `SizedBox.shrink()`（不占空间，不影响既有 layout test）。
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

class _MenuButton extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback? onTap;
  final bool disabled;

  const _MenuButton({
    required this.label,
    required this.hint,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: WuxiaColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WuxiaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                style: const TextStyle(
                  color: WuxiaColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
