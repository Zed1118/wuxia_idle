import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../character_panel/presentation/character_panel_screen.dart';
import '../../mainline/presentation/chapter_list_screen.dart';
import '../../seclusion/presentation/seclusion_map_list_screen.dart';
import '../../taohua_island/presentation/taohua_island_screen.dart';
import '../application/main_menu_status_summary_provider.dart';

class MainMenuStatusSummaryPanel extends ConsumerWidget {
  const MainMenuStatusSummaryPanel({super.key});

  static const int _defaultCharacterId = 1;
  static const RealmTier _defaultRealmTier = RealmTier.xueTu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(mainMenuStatusSummaryProvider);
    return asyncItems.maybeWhen(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WuxiaUi.paper.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  UiStrings.mainMenuStatusSummaryTitle,
                  style: TextStyle(
                    color: WuxiaUi.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: wide
                                ? (constraints.maxWidth - 16) / 3
                                : constraints.maxWidth,
                            child: _SummaryTile(
                              item: item,
                              onTap: () => _open(context, item.route),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  void _open(BuildContext context, MainMenuStatusRoute route) {
    final screen = switch (route) {
      MainMenuStatusRoute.retreat => const SeclusionMapListScreen(
        charRealmTier: _defaultRealmTier,
        characterId: _defaultCharacterId,
      ),
      MainMenuStatusRoute.island => const TaohuaIslandScreen(),
      MainMenuStatusRoute.character => const CharacterPanelScreen(
        characterId: _defaultCharacterId,
      ),
      MainMenuStatusRoute.mainline => const ChapterListScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.item, required this.onTap});

  final MainMenuStatusSummaryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _color(item.kind);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(_icon(item.kind), color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WuxiaColors.textSecondary,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(MainMenuStatusKind kind) => switch (kind) {
    MainMenuStatusKind.retreat => Icons.self_improvement,
    MainMenuStatusKind.island => Icons.cottage_outlined,
    MainMenuStatusKind.injury => Icons.healing_outlined,
    MainMenuStatusKind.breakthrough => Icons.military_tech_outlined,
    MainMenuStatusKind.mainline => Icons.map_outlined,
  };

  Color _color(MainMenuStatusKind kind) => switch (kind) {
    MainMenuStatusKind.retreat => WuxiaUi.jiang,
    MainMenuStatusKind.island => WuxiaColors.resultHighlight,
    MainMenuStatusKind.injury => WuxiaColors.hpLow,
    MainMenuStatusKind.breakthrough => WuxiaColors.lingQiao,
    MainMenuStatusKind.mainline => WuxiaUi.ink,
  };
}
