import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../domain/chapter_assets.dart';
import '../application/mainline_progress_service.dart';
import '../application/mainline_providers.dart';
import '../domain/mainline_progress.dart';
import 'chapter_transition_screen.dart';
import 'stage_list_screen.dart';
import '../../../shared/widgets/asset_fallback.dart';

/// 主线章节列表（Phase 3 T35,2026-05-22 P2 Ch6 扩 6 章）。
///
/// 列 6 章(学武出山 / 武林初识 / 名扬江湖 / 西出阳关 / 征东 / 飞升),状态:
///   - cleared 已通过:右上 ✓ 标识,可重入
///   - inProgress 进行中:主色边框高亮(章节内仍有未通关卡)
///   - locked 未解锁:灰色 + 锁图标,点击无响应
///
/// 章节解锁规则:
///   - Ch1 永远 unlocked
///   - ChN (N>1) unlocked ⟺ ChN-1 全通
class ChapterListScreen extends ConsumerWidget {
  const ChapterListScreen({super.key});

  static const List<int> _chapters = [1, 2, 3, 4, 5, 6];

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
            final chapterStatuses = {
              for (final ch in _chapters)
                ch: _statusFor(progress: progress, chapterIndex: ch),
            };
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _ChapterRouteMap(
                  statuses: chapterStatuses,
                  stagesByChapter: {
                    for (final ch in _chapters)
                      ch: MainlineProgressService.availableStages(
                        progress: progress,
                        chapterIndex: ch,
                      ),
                  },
                ),
                const SizedBox(height: 12),
                for (final ch in _chapters)
                  _ChapterCardShell(
                    chapterIndex: ch,
                    status: chapterStatuses[ch]!,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static _ChapterStatus _statusFor({
    required MainlineProgress progress,
    required int chapterIndex,
  }) {
    final completed = MainlineProgressService.chapterCompleted(
      progress: progress,
      chapterIndex: chapterIndex,
    );
    final prevCompleted =
        chapterIndex == 1 ||
        MainlineProgressService.chapterCompleted(
          progress: progress,
          chapterIndex: chapterIndex - 1,
        );
    return completed
        ? _ChapterStatus.cleared
        : (prevCompleted ? _ChapterStatus.inProgress : _ChapterStatus.locked);
  }
}

enum _ChapterStatus { locked, inProgress, cleared }

class _ChapterCardShell extends StatelessWidget {
  const _ChapterCardShell({required this.chapterIndex, required this.status});

  final int chapterIndex;
  final _ChapterStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ChapterCard(
        chapterIndex: chapterIndex,
        status: status,
        onTap: status == _ChapterStatus.locked
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StageListScreen(chapterIndex: chapterIndex),
                ),
              ),
        // H2 C1:解锁章节加「卷」入口 → 翻篇过场(卷首/卷尾)。
        // 卷尾仅 cleared 解锁。锁定章节不给入口。
        onViewScroll: status == _ChapterStatus.locked
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChapterTransitionScreen(
                    chapterIndex: chapterIndex,
                    showEpilogue: status == _ChapterStatus.cleared,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ChapterRouteMap extends StatelessWidget {
  const _ChapterRouteMap({
    required this.statuses,
    required this.stagesByChapter,
  });

  final Map<int, _ChapterStatus> statuses;
  final Map<int, List<StageEntry>> stagesByChapter;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(UiStrings.mainlineRouteMapTitle),
          const SizedBox(height: 6),
          const Text(
            UiStrings.mainlineRouteMapSubtitle,
            style: TextStyle(
              color: WuxiaUi.ink2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1040;
              final entries = statuses.entries.toList(growable: false);
              final route = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (compact)
                      SizedBox(
                        width: 196,
                        child: _RouteChapterPanel(
                          chapterIndex: entries[i].key,
                          status: entries[i].value,
                          stages: stagesByChapter[entries[i].key] ?? const [],
                        ),
                      )
                    else
                      Expanded(
                        child: _RouteChapterPanel(
                          chapterIndex: entries[i].key,
                          status: entries[i].value,
                          stages: stagesByChapter[entries[i].key] ?? const [],
                        ),
                      ),
                    if (i != entries.length - 1) const _RouteConnector(),
                  ],
                ],
              );
              if (!compact) return route;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: route,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: Center(
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: WuxiaUi.ink.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

class _RouteChapterPanel extends StatelessWidget {
  const _RouteChapterPanel({
    required this.chapterIndex,
    required this.status,
    required this.stages,
  });

  final int chapterIndex;
  final _ChapterStatus status;
  final List<StageEntry> stages;

  @override
  Widget build(BuildContext context) {
    final locked = status == _ChapterStatus.locked;
    final active = status == _ChapterStatus.inProgress;
    final borderColor = switch (status) {
      _ChapterStatus.cleared => WuxiaColors.hpHigh,
      _ChapterStatus.inProgress => WuxiaColors.resultHighlight,
      _ChapterStatus.locked => WuxiaUi.muted,
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: locked ? 0.58 : 1,
      child: Container(
        height: 162,
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(alpha: locked ? 0.42 : 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor.withValues(alpha: active ? 0.95 : 0.58),
            width: active ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: active ? 0.24 : 0.14),
              blurRadius: active ? 10 : 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 82,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    chapterCoverPath(chapterIndex),
                    fit: BoxFit.cover,
                    errorBuilder: wuxiaAssetErrorBuilder(
                      () => Container(color: WuxiaColors.avatarFill),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          UiStrings.chapterRouteNodeLabel(chapterIndex),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          UiStrings.chapterTitle(chapterIndex),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _RouteStatusStamp(status: status),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < stages.length; i++) ...[
                          Expanded(
                            child: _RouteStageNode(
                              stageIndex: i + 1,
                              entry: stages[i],
                              chapterLocked: locked,
                            ),
                          ),
                          if (i != stages.length - 1)
                            Container(
                              width: 8,
                              height: 1.5,
                              color: WuxiaUi.ink.withValues(alpha: 0.22),
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        UiStrings.chapterHint(chapterIndex),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locked ? WuxiaUi.muted : WuxiaUi.ink2,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStatusStamp extends StatelessWidget {
  const _RouteStatusStamp({required this.status});

  final _ChapterStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _ChapterStatus.cleared => (
        UiStrings.mainlineRouteCleared,
        WuxiaColors.hpHigh,
      ),
      _ChapterStatus.inProgress => (
        UiStrings.mainlineRouteCurrent,
        WuxiaColors.resultHighlight,
      ),
      _ChapterStatus.locked => (UiStrings.mainlineRouteLocked, WuxiaUi.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RouteStageNode extends StatelessWidget {
  const _RouteStageNode({
    required this.stageIndex,
    required this.entry,
    required this.chapterLocked,
  });

  final int stageIndex;
  final StageEntry entry;
  final bool chapterLocked;

  @override
  Widget build(BuildContext context) {
    final status = chapterLocked ? StageStatus.locked : entry.status;
    final boss = entry.def.isBossStage;
    final color = switch (status) {
      StageStatus.cleared => WuxiaColors.hpHigh,
      StageStatus.available => WuxiaColors.resultHighlight,
      StageStatus.locked => WuxiaUi.muted,
    };
    final fill = color.withValues(
      alpha: status == StageStatus.locked ? 0.10 : 0.20,
    );
    final borderWidth = status == StageStatus.available ? 1.6 : 1.0;

    final marker = Container(
      width: boss ? 26 : 23,
      height: boss ? 26 : 23,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(boss ? 3 : 12),
        border: Border.all(color: color, width: borderWidth),
      ),
      alignment: Alignment.center,
      child: boss
          ? Icon(Icons.military_tech, size: 14, color: color)
          : Text(
              UiStrings.mainlineRouteStageNode(stageIndex),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
    );

    return Tooltip(
      message:
          '${entry.def.name}${boss ? ' · ${UiStrings.mainlineRouteBoss}' : ''}',
      child: Center(
        child: boss ? Transform.rotate(angle: 0.785, child: marker) : marker,
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapterIndex,
    required this.status,
    required this.onTap,
    this.onViewScroll,
  });

  final int chapterIndex;
  final _ChapterStatus status;
  final VoidCallback? onTap;

  /// H2 C1:章节卷首/卷尾翻篇入口(锁定章节为 null)。
  final VoidCallback? onViewScroll;

  @override
  Widget build(BuildContext context) {
    final locked = status == _ChapterStatus.locked;
    final cleared = status == _ChapterStatus.cleared;
    final inProgress = status == _ChapterStatus.inProgress;
    final borderColor = inProgress
        ? WuxiaColors.resultHighlight
        : (cleared ? WuxiaColors.hpHigh : WuxiaColors.border);
    final titleColor = locked ? WuxiaColors.textMuted : WuxiaColors.textPrimary;
    final hintColor = locked
        ? WuxiaColors.buttonDisabled
        : WuxiaColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: locked ? WuxiaColors.avatarFill : WuxiaColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: inProgress ? 2 : 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 章节封面条(出版美术):固定高 96 + BoxFit.cover 裁宽幅封面;
                // 无图 errorBuilder 弱占位 avatarFill 不破布局,MJ 图落位即显。
                SizedBox(
                  height: 96,
                  child: Opacity(
                    // 锁章调暗保留「锁」信号(卡片另有锁图标+灰标题),但 0.35
                    // 过暗把封面美术埋成黑泥(Codex Ch5 验收反馈) → 0.5 让封面可辨。
                    opacity: locked ? 0.5 : 1.0,
                    child: Image.asset(
                      chapterCoverPath(chapterIndex),
                      fit: BoxFit.cover,
                      errorBuilder: wuxiaAssetErrorBuilder(
                        () => Container(color: WuxiaColors.avatarFill),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
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
                              style: TextStyle(color: hintColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (onViewScroll != null) ...[
                        IconButton(
                          icon: const Icon(Icons.auto_stories),
                          color: WuxiaColors.textSecondary,
                          iconSize: 20,
                          tooltip: UiStrings.chapterScrollTooltip,
                          onPressed: onViewScroll,
                        ),
                      ],
                      const SizedBox(width: 4),
                      _StatusChip(status: status),
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
