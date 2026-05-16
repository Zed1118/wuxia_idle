import 'package:flutter/material.dart';

import '../../../data/isar_setup.dart';
import '../application/phase2_seed_service.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../../shared/strings.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../../../shared/theme/colors.dart';
import 'encounter_debug_picker.dart';

/// Phase 2 调试场景菜单（phase2_tasks.md T32 §492-509 子提交 3b/3d）。
///
/// 4 个按钮 P1-P4：onTap → `Phase2SeedService.seedPx()` writeTxn 写种子 → push
/// 对应 UI。子提交 3 范围内 P2/P4 战斗按钮 stub 为跳 [InventoryScreen]（让玩家
/// 看 battleCount 字段），完整 ScenarioLauncher 接 Isar 等 Phase 3 接
/// character_to_battle 转换 helper 再补。
///
/// **错误兜底**：种子失败弹 SnackBar 显示原因。共用 `_seedAndPush` 帮手把
/// `await seed → if-mounted push` 串起来，避免在 callback 里散写。
class Phase2TestMenu extends StatefulWidget {
  const Phase2TestMenu({super.key});

  @override
  State<Phase2TestMenu> createState() => _Phase2TestMenuState();
}

class _Phase2TestMenuState extends State<Phase2TestMenu> {
  static const int _defaultCharacterId = 1;

  bool _busy = false;

  Future<void> _seedAndPush(
    Future<void> Function() seed,
    Widget Function() targetBuilder,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await seed();
      if (!mounted) return;
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => targetBuilder()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('种子失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.phase2MenuTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            // W12 fix: 6 个按钮在 800x600 surface 下高度临界，SingleChildScrollView
            // 包裹兜底；正常窗口下视觉不变（仍居中）
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                _ScenarioButton(
                  label: UiStrings.scenarioP1,
                  hint: UiStrings.hintP1,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance).seedP1(),
                    () => const InventoryScreen(),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioP2,
                  hint: UiStrings.hintP2,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance).seedP2(),
                    () => const InventoryScreen(),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioP3,
                  hint: UiStrings.hintP3,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance).seedP3(),
                    () => const TechniquePanelScreen(
                      characterId: _defaultCharacterId,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioP4,
                  hint: UiStrings.hintP4,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance).seedP4(),
                    () => const CharacterPanelScreen(
                      characterId: _defaultCharacterId,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioP5,
                  hint: UiStrings.hintP5,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance).seedMasterDisciple(),
                    () => const CharacterPanelScreen(
                      characterId: _defaultCharacterId,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioVc,
                  hint: UiStrings.hintVc,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance).seedVisualCheckW7W11(),
                    () => const CharacterPanelScreen(
                      characterId: _defaultCharacterId,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioVc14_3,
                  hint: UiStrings.hintVc14_3,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance)
                        .seedVisualCheckW14_3(),
                    () => const CharacterPanelScreen(
                      characterId: _defaultCharacterId,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioVcEvent,
                  hint: UiStrings.hintVcEvent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EncounterDebugPickerScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioVc15R2,
                  hint: UiStrings.hintVc15R2,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance)
                        .seedVisualCheckW15R2(),
                    () => const InventoryScreen(),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioVc15Resonance,
                  hint: UiStrings.hintVc15Resonance,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance)
                        .seedVisualCheckW15Resonance(),
                    () => const InventoryScreen(),
                  ),
                ),
                const SizedBox(height: 16),
                _ScenarioButton(
                  label: UiStrings.scenarioVc15Fresh,
                  hint: UiStrings.hintVc15Fresh,
                  onTap: () => _seedAndPush(
                    () => Phase2SeedService(isar: IsarSetup.instance)
                        .seedVisualCheckW15Fresh(),
                    () => const CharacterPanelScreen(
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

class _ScenarioButton extends StatelessWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _ScenarioButton({
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
