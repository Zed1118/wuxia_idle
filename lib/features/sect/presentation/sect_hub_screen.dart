import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/character.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/light_paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../expedition/presentation/expedition_overview_screen.dart';
import '../../lineup/presentation/team_lineup_screen.dart';
import '../../seclusion/presentation/seclusion_map_list_screen.dart';
import '../../taohua_island/presentation/taohua_island_screen.dart';
import 'sect_screen.dart';

/// 二阶段 §11.1 “宗门”一级 Hub。
///
/// 只把角色、调度、闭关、疗伤、远征、生产和门派事务的既有生产入口
/// 收拢到同一处；不拥有任何子系统业务写入。
class SectHubScreen extends ConsumerWidget {
  const SectHubScreen({
    super.key,
    required this.seclusionLocked,
    required this.taohuaLocked,
    required this.sectLocked,
    required this.expeditionUnlocked,
    @visibleForTesting this.routeObserverForTest,
  });

  final bool seclusionLocked;
  final bool taohuaLocked;
  final bool sectLocked;
  final bool expeditionUnlocked;
  final void Function(Widget screen)? routeObserverForTest;

  void _push(BuildContext context, Widget screen) {
    final observer = routeObserverForTest;
    if (observer != null) {
      observer(screen);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = ref.watch(activeCharacterIdsProvider);
    final activeId = idsAsync.maybeWhen(
      data: (ids) => ids.isEmpty ? null : ids.first,
      orElse: () => null,
    );

    Character? activeCharacter;
    var identityLoading = idsAsync.isLoading;
    if (activeId != null) {
      final characterAsync = ref.watch(characterByIdProvider(activeId));
      identityLoading = identityLoading || characterAsync.isLoading;
      activeCharacter = characterAsync.maybeWhen(
        data: (character) => character,
        orElse: () => null,
      );
    }

    final identityAvailable =
        !identityLoading && activeId != null && activeCharacter != null;
    final identityHint = identityLoading
        ? UiStrings.sectHubCharacterLoadingHint
        : UiStrings.sectHubNoActiveCharacterHint;
    final seclusionDisabled = seclusionLocked || !identityAvailable;

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.sectHubTitle,
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
                      const SectionHeader(UiStrings.sectHubSectionTitle),
                      const SizedBox(height: 8),
                      const Text(
                        UiStrings.sectHubSubtitle,
                        style: TextStyle(
                          color: WuxiaUi.muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      WuxiaInkButton(
                        label: UiStrings.sectHubCharacters,
                        hint: identityAvailable
                            ? UiStrings.sectHubCharactersHint
                            : identityHint,
                        icon: Icons.person_outline,
                        thumbnailPath: WuxiaUi.entryCharacter,
                        disabled: !identityAvailable,
                        locked: !identityAvailable,
                        onTap: !identityAvailable
                            ? null
                            : () => _push(
                                context,
                                CharacterPanelScreen(characterId: activeId),
                              ),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.sectHubLineup,
                        hint: UiStrings.sectHubLineupHint,
                        icon: Icons.groups_2_outlined,
                        thumbnailPath: WuxiaUi.entryCharacter,
                        onTap: () => _push(context, const TeamLineupScreen()),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.sectHubSeclusion,
                        hint: seclusionLocked
                            ? UiStrings.mainMenuSeclusionLockedHint
                            : identityAvailable
                            ? UiStrings.sectHubSeclusionHint
                            : identityHint,
                        icon: Icons.landscape_outlined,
                        thumbnailPath: WuxiaUi.entrySeclusion,
                        disabled: seclusionDisabled,
                        locked: seclusionDisabled,
                        onTap: seclusionDisabled
                            ? null
                            : () => _push(
                                context,
                                SeclusionMapListScreen(
                                  charRealmTier: activeCharacter!.realmTier,
                                  characterId: activeId,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.sectHubHealing,
                        hint: identityAvailable
                            ? UiStrings.sectHubHealingHint
                            : identityHint,
                        icon: Icons.healing_outlined,
                        thumbnailPath: WuxiaUi.entryCharacter,
                        disabled: !identityAvailable,
                        locked: !identityAvailable,
                        onTap: !identityAvailable
                            ? null
                            : () => _push(
                                context,
                                CharacterPanelScreen(characterId: activeId),
                              ),
                      ),
                      if (expeditionUnlocked) ...[
                        const SizedBox(height: 12),
                        WuxiaInkButton(
                          label: UiStrings.sectHubExpedition,
                          hint: UiStrings.sectHubExpeditionHint,
                          icon: Icons.travel_explore_outlined,
                          thumbnailPath: WuxiaUi.entryJianghu,
                          onTap: () =>
                              _push(context, const ExpeditionOverviewScreen()),
                        ),
                      ],
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.sectHubProduction,
                        hint: taohuaLocked
                            ? UiStrings.mainMenuTaohuaIslandLockedHint
                            : UiStrings.sectHubProductionHint,
                        icon: Icons.cottage_outlined,
                        thumbnailPath: WuxiaUi.entryJianghu,
                        disabled: taohuaLocked,
                        locked: taohuaLocked,
                        onTap: taohuaLocked
                            ? null
                            : () => _push(context, const TaohuaIslandScreen()),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        label: UiStrings.sectHubAffairs,
                        hint: sectLocked
                            ? UiStrings.mainMenuSocialLockedHint
                            : UiStrings.sectHubAffairsHint,
                        icon: Icons.home_work_outlined,
                        thumbnailPath: WuxiaUi.entryJianghu,
                        disabled: sectLocked,
                        locked: sectLocked,
                        onTap: sectLocked
                            ? null
                            : () => _push(context, const SectScreen()),
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
