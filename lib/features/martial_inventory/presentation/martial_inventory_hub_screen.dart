import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/light_paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../cangjingge/presentation/cangjingge_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../technique_panel/presentation/technique_panel_screen.dart';
import '../../tutorial/application/tutorial_providers.dart';

/// 二阶段 §11.1 “武学与行囊”一级 Hub。
///
/// 只负责把招式、主修、装备、物品四条既有生产路由收拢到同一入口；
/// 不拥有任何学习、散功、装备或物品写入逻辑。
class MartialInventoryHubScreen extends ConsumerWidget {
  const MartialInventoryHubScreen({super.key});

  static const int _martialUnlockStep = 3;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorialStep = ref
        .watch(currentTutorialStepProvider)
        .maybeWhen(data: (step) => step, orElse: () => 0);
    final activeCharacterId = ref
        .watch(activeCharacterIdsProvider)
        .maybeWhen(
          data: (ids) => ids.isEmpty ? null : ids.first,
          orElse: () => null,
        );
    final tutorialLocked = tutorialStep < _martialUnlockStep;
    final martialDisabled = tutorialLocked || activeCharacterId == null;
    final martialHint = tutorialLocked
        ? UiStrings.martialInventoryMartialLockedHint
        : activeCharacterId == null
        ? UiStrings.martialInventoryNoActiveCharacterHint
        : null;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.martialInventoryHubTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                LightPaperPanel(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        UiStrings.martialInventoryHubSectionTitle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        UiStrings.martialInventoryHubSubtitle,
                        style: TextStyle(
                          color: WuxiaUi.muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      WuxiaInkButton(
                        label: UiStrings.martialInventorySkills,
                        hint:
                            martialHint ?? UiStrings.martialInventorySkillsHint,
                        icon: Icons.auto_awesome_outlined,
                        thumbnailPath: WuxiaUi.entryTechnique,
                        disabled: martialDisabled,
                        locked: martialDisabled,
                        onTap: martialDisabled
                            ? null
                            : () => _push(
                                context,
                                CangJingGeScreen(
                                  characterId: activeCharacterId,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.martialInventoryTechniques,
                        hint:
                            martialHint ??
                            UiStrings.martialInventoryTechniquesHint,
                        icon: Icons.auto_stories_outlined,
                        thumbnailPath: WuxiaUi.entryTechnique,
                        disabled: martialDisabled,
                        locked: martialDisabled,
                        onTap: martialDisabled
                            ? null
                            : () => _push(
                                context,
                                TechniquePanelScreen(
                                  characterId: activeCharacterId,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.martialInventoryEquipment,
                        hint: UiStrings.martialInventoryEquipmentHint,
                        icon: Icons.inventory_2_outlined,
                        thumbnailPath: WuxiaUi.entryInventory,
                        onTap: () => _push(
                          context,
                          const InventoryScreen(initialTab: 0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.martialInventoryItems,
                        hint: UiStrings.martialInventoryItemsHint,
                        icon: Icons.backpack_outlined,
                        thumbnailPath: WuxiaUi.entryInventory,
                        onTap: () => _push(
                          context,
                          const InventoryScreen(initialTab: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
