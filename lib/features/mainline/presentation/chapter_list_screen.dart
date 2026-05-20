import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../application/mainline_progress_service.dart';
import '../application/mainline_providers.dart';
import 'stage_list_screen.dart';

/// 主线章节列表（Phase 3 T35）。
///
/// 列 3 章（学武出山 / 武林初识 / 名扬江湖），状态：
///   - cleared 已通过：右上 ✓ 标识，可重入
///   - inProgress 进行中：主色边框高亮（章节内仍有未通关卡）
///   - locked 未解锁：灰色 + 锁图标，点击无响应
///
/// 章节解锁规则：
///   - Ch1 永远 unlocked
///   - ChN (N>1) unlocked ⟺ ChN-1 全通
class ChapterListScreen extends ConsumerWidget {
  const ChapterListScreen({super.key});

  static const List<int> _chapters = [1, 2, 3];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mainlineProgressProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.chapterListTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Image.asset(
              'assets/ui/scroll_horizontal.png',
              height: 28,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              '加载失败：$e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (progress) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _chapters.length,
              itemBuilder: (ctx, i) {
                final ch = _chapters[i];
                final completed = MainlineProgressService.chapterCompleted(
                  progress: progress,
                  chapterIndex: ch,
                );
                final prevCompleted = ch == 1 ||
                    MainlineProgressService.chapterCompleted(
                      progress: progress,
                      chapterIndex: ch - 1,
                    );
                final unlocked = prevCompleted;
                final status = completed
                    ? _ChapterStatus.cleared
                    : (unlocked
                        ? _ChapterStatus.inProgress
                        : _ChapterStatus.locked);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChapterCard(
                    chapterIndex: ch,
                    status: status,
                    onTap: status == _ChapterStatus.locked
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    StageListScreen(chapterIndex: ch),
                              ),
                            ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

enum _ChapterStatus { locked, inProgress, cleared }

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapterIndex,
    required this.status,
    required this.onTap,
  });

  final int chapterIndex;
  final _ChapterStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = status == _ChapterStatus.locked;
    final cleared = status == _ChapterStatus.cleared;
    final inProgress = status == _ChapterStatus.inProgress;
    final borderColor = inProgress
        ? WuxiaColors.resultHighlight
        : (cleared ? WuxiaColors.hpHigh : WuxiaColors.border);
    final titleColor =
        locked ? WuxiaColors.textMuted : WuxiaColors.textPrimary;
    final hintColor =
        locked ? WuxiaColors.buttonDisabled : WuxiaColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: locked
                ? WuxiaColors.avatarFill
                : WuxiaColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: inProgress ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UiStrings.chapterTitle(chapterIndex),
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      UiStrings.chapterHint(chapterIndex),
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _ChapterStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _ChapterStatus.cleared => const Icon(
          Icons.check_circle,
          color: WuxiaColors.hpHigh,
          size: 22,
        ),
      _ChapterStatus.inProgress => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: WuxiaColors.resultHighlight.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            UiStrings.chapterStatusInProgress,
            style: TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      _ChapterStatus.locked => const Icon(
          Icons.lock,
          color: WuxiaColors.textMuted,
          size: 20,
        ),
    };
  }
}
