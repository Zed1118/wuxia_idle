import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ink_button.dart';
import '../../../shared/widgets/wuxia_ui/paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../baike/presentation/baike_screen.dart';
import '../../battle_record/presentation/battle_record_screen.dart';
import '../../cangjingge/presentation/cangjingge_screen.dart';
import '../../weapon_codex/presentation/weapon_codex_screen.dart';
import '../application/zangjuange_providers.dart';
import '../domain/archive_clue.dart';

class ZangjuangeScreen extends ConsumerWidget {
  const ZangjuangeScreen({super.key});

  static const int _defaultCharacterId = 1;

  void _push(BuildContext context, Widget child) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => child));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cluesAsync = ref.watch(zangjuangeCluesProvider);
    final clues = cluesAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <ArchiveClue>[],
    );

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.zangjuangeTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _CluePanel(clues: clues),
                const SizedBox(height: 16),
                PaperPanel(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(UiStrings.zangjuangeArchiveTitle),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        icon: Icons.military_tech_outlined,
                        label: UiStrings.mainMenuBattleRecord,
                        hint: UiStrings.mainMenuBattleRecordHint,
                        onTap: () =>
                            _push(context, const BattleRecordScreen()),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        icon: Icons.hardware_outlined,
                        label: UiStrings.mainMenuWeaponCodex,
                        hint: UiStrings.mainMenuWeaponCodexHint,
                        onTap: () =>
                            _push(context, const WeaponCodexScreen()),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        icon: Icons.travel_explore_outlined,
                        label: UiStrings.mainMenuBaike,
                        hint: UiStrings.mainMenuBaikeHint,
                        onTap: () => _push(context, const BaikeScreen()),
                      ),
                      const SizedBox(height: 12),
                      WuxiaInkButton(
                        icon: Icons.auto_stories_outlined,
                        label: UiStrings.mainMenuSkillLibrary,
                        hint: UiStrings.mainMenuSkillLibraryHint,
                        onTap: () => _push(
                          context,
                          const CangJingGeScreen(
                            characterId: _defaultCharacterId,
                          ),
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

class _CluePanel extends StatelessWidget {
  const _CluePanel({required this.clues});

  final List<ArchiveClue> clues;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(UiStrings.zangjuangeCluesTitle),
          const SizedBox(height: 10),
          if (clues.isEmpty)
            const Text(
              UiStrings.zangjuangeCluesEmpty,
              style: TextStyle(color: WuxiaColors.textMuted, fontSize: 13),
            )
          else
            for (final clue in clues) ...[
              _ClueTile(clue: clue),
              if (clue != clues.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _ClueTile extends StatelessWidget {
  const _ClueTile({required this.clue});

  final ArchiveClue clue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x2214181D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: WuxiaColors.textMuted.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clue.title,
              style: const TextStyle(
                color: WuxiaColors.resultHighlight,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              clue.summary,
              style: const TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
