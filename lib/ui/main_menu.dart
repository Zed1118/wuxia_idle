import 'package:flutter/material.dart';

import 'character_panel/character_panel_screen.dart';
import 'debug/battle_test_menu.dart';
import 'debug/phase2_test_menu.dart';
import 'inventory/inventory_screen.dart';
import 'mainline/chapter_list_screen.dart';
import 'strings.dart';
import 'technique_panel/technique_panel_screen.dart';
import 'theme/colors.dart';

/// 调试主菜单（phase2_tasks.md T32 §492-509 子提交 3b）。
///
/// `main.dart` 的新 `home`，取代 [BattleTestMenu]。5 个按钮串接：
/// - Phase 1 战斗测试 → [BattleTestMenu]（沿用 T17 入口）
/// - Phase 2 调试场景 → [Phase2TestMenu]（T32 子提交 3d 新建）
/// - 角色面板 → [CharacterPanelScreen]，固定 `characterId=1`（与 [Phase2SeedService] 种子 id 对齐）
/// - 装备仓库 → [InventoryScreen]
/// - 心法面板 → [TechniquePanelScreen]，固定 `characterId=1`
///
/// 套用 [BattleTestMenu] 的 `_ScenarioButton` 视觉风格（panel 背景 + 标题 + hint），
/// 不抽 helper 一例一份就够。
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  static const int _defaultCharacterId = 1;

  void _push(BuildContext context, Widget child) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => child));
  }

  @override
  Widget build(BuildContext context) {
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

class _MenuButton extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
    );
  }
}
