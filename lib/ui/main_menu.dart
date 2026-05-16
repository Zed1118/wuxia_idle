import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/domain/enums.dart';
import '../providers/character_providers.dart';
import '../features/character_panel/presentation/character_panel_screen.dart';
import 'debug/battle_test_menu.dart';
import 'debug/phase2_test_menu.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/mainline/presentation/chapter_list_screen.dart';
import '../features/seclusion/presentation/seclusion_map_list_screen.dart';
import 'strings.dart';
import '../features/technique_panel/presentation/technique_panel_screen.dart';
import 'theme/colors.dart';
import '../features/tower/presentation/tower_floor_list_screen.dart';

/// 调试主菜单（phase2_tasks.md T32 §492-509 子提交 3b + T56 闭关入口 FutureBuilder 化）。
///
/// `main.dart` 的新 `home`，取代 [BattleTestMenu]。8 个按钮串接：
/// - Phase 1 战斗测试 → [BattleTestMenu]（沿用 T17 入口）
/// - Phase 2 调试场景 → [Phase2TestMenu]（T32 子提交 3d 新建）
/// - 角色面板 → [CharacterPanelScreen]，初始 `characterId=1`（T56 内部 Tab 可切换 3 角色）
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      body: SafeArea(
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
                _SeclusionMenuButton(
                  defaultCharacterId: _defaultCharacterId,
                  defaultRealmTier: _defaultRealmTier,
                  onPush: (screen) => _push(context, screen),
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
                  label: UiStrings.mainMenuInventory,
                  hint: UiStrings.mainMenuInventoryHint,
                  onTap: () => _push(context, const InventoryScreen()),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  label: UiStrings.mainMenuTechniques,
                  hint: UiStrings.mainMenuTechniquesHint,
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
  });

  final int defaultCharacterId;
  final RealmTier defaultRealmTier;
  final void Function(Widget screen) onPush;

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

    return _MenuButton(
      label: UiStrings.mainMenuSeclusion,
      hint: UiStrings.mainMenuSeclusionHint,
      disabled: loading,
      onTap: loading
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
