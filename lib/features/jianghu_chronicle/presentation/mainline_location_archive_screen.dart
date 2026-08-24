import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/ink_empty_state.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';
import '../../../shared/widgets/wuxia_ui/light_paper_panel.dart';
import '../../../shared/widgets/wuxia_ui/section_header.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_title_bar.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mainline/domain/mainline_progress.dart';

typedef MainlineLocationArchiveChapter = ({
  int chapterIndex,
  List<StageEntry> locations,
});

/// Resolves only cleared and currently available locations.
///
/// Chapter admission mirrors ChapterListScreen: Ch1 is open; later chapters
/// require the previous chapter to be complete. Locked stage names never leave
/// this function.
List<MainlineLocationArchiveChapter> resolveMainlineLocationArchive(
  MainlineProgress progress,
) {
  if (!GameRepository.isLoaded) return const [];
  final indexes =
      GameRepository.instance.stageDefs.values
          .where((stage) => stage.stageType == StageType.mainline)
          .map((stage) => stage.chapterIndex)
          .whereType<int>()
          .toSet()
          .toList(growable: false)
        ..sort();
  final result = <MainlineLocationArchiveChapter>[];
  for (final chapterIndex in indexes) {
    final chapterUnlocked =
        chapterIndex == 1 ||
        MainlineProgressService.chapterCompleted(
          progress: progress,
          chapterIndex: chapterIndex - 1,
        );
    if (!chapterUnlocked) continue;
    final locations =
        MainlineProgressService.availableStages(
              progress: progress,
              chapterIndex: chapterIndex,
            )
            .where((entry) => entry.status != StageStatus.locked)
            .toList(growable: false);
    if (locations.isNotEmpty) {
      result.add((chapterIndex: chapterIndex, locations: locations));
    }
  }
  return List.unmodifiable(result);
}

class MainlineLocationArchiveScreen extends ConsumerWidget {
  const MainlineLocationArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(mainlineProgressProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: WuxiaTitleBar(
        title: UiStrings.jianghuChronicleLocations,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (_, _) => const _LocationState(
            text: UiStrings.jianghuChronicleLocationsUnavailable,
          ),
          data: (progress) {
            final chapters = resolveMainlineLocationArchive(progress);
            if (chapters.isEmpty) {
              return const _LocationState(
                text: UiStrings.jianghuChronicleLocationsEmpty,
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: chapters.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) =>
                      _ChapterLocations(chapter: chapters[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChapterLocations extends StatelessWidget {
  const _ChapterLocations({required this.chapter});

  final MainlineLocationArchiveChapter chapter;

  @override
  Widget build(BuildContext context) {
    return LightPaperPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(UiStrings.chapterTitle(chapter.chapterIndex)),
          const SizedBox(height: 8),
          for (var index = 0; index < chapter.locations.length; index++) ...[
            _LocationRow(entry: chapter.locations[index]),
            if (index + 1 < chapter.locations.length)
              const Divider(height: 14, color: WuxiaColors.border),
          ],
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.entry});

  final StageEntry entry;

  @override
  Widget build(BuildContext context) {
    final cleared = entry.status == StageStatus.cleared;
    return Row(
      children: [
        Icon(
          cleared ? Icons.check_circle_outline : Icons.place_outlined,
          size: 18,
          color: cleared ? WuxiaUi.goldOnPaper : WuxiaColors.textMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            entry.def.name,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          cleared
              ? UiStrings.jianghuChronicleLocationCleared
              : UiStrings.jianghuChronicleLocationAvailable,
          style: const TextStyle(color: WuxiaUi.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _LocationState extends StatelessWidget {
  const _LocationState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: InkEmptyState(
          variant: InkEmptyStateVariant.empty,
          title: UiStrings.jianghuChronicleLocations,
          body: text,
          icon: Icons.place_outlined,
        ),
      ),
    );
  }
}
