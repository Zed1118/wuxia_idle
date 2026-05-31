import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/stage_def.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../application/mainline_progress_service.dart';
import '../application/mainline_providers.dart';
import '../domain/chapter_assets.dart';
import 'stage_entry_flow.dart';

/// 章节内关卡列表（Phase 3 T35）。
///
/// 按 [MainlineProgressService.availableStages] 返回的 prev 链顺序渲染：
///   - cleared 绿勾，可重玩（T37 接 StageEntryFlow 后再决定重玩流程）
///   - available 主色按钮，点击进入关卡（T37 接 StageEntryFlow）
///   - locked 灰色 + 「通关前一关解锁」提示
///
/// T35 阶段：available/cleared 点击仅弹 SnackBar 占位，T37 接入流程后改 push。
class StageListScreen extends ConsumerWidget {
  const StageListScreen({super.key, required this.chapterIndex});

  final int chapterIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chapterStagesProvider(chapterIndex));
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: Text(UiStrings.chapterTitle(chapterIndex)),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
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
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(
                child: Text(
                  UiStrings.stageListEmpty,
                  style: TextStyle(color: WuxiaColors.textMuted),
                ),
              );
            }
            return Column(
              children: [
                // 关卡列表顶部章节封面(出版美术 §5.3「关卡场景感」):
                // 复用 chapterCoverPath,无图 errorBuilder shrink 折叠。
                Image.asset(
                  chapterCoverPath(chapterIndex),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                final entry = entries[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StageRow(
                    def: entry.def,
                    status: entry.status,
                    onTap: entry.status == StageStatus.locked
                        ? null
                        : () => runStageFlow(
                              context: context,
                              ref: ref,
                              stage: entry.def,
                            ),
                  ),
                );
              },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.def,
    required this.status,
    required this.onTap,
  });

  final StageDef def;
  final StageStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = status == StageStatus.locked;
    final cleared = status == StageStatus.cleared;
    final borderColor = cleared
        ? WuxiaColors.hpHigh
        : (locked ? WuxiaColors.border : WuxiaColors.resultHighlight);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: locked ? WuxiaColors.avatarFill : WuxiaColors.panel,
            border: Border(left: BorderSide(color: borderColor, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name,
                      style: TextStyle(
                        color: locked
                            ? WuxiaColors.textMuted
                            : WuxiaColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleFor(def, status),
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StageStatusBadge(status: status),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitleFor(StageDef def, StageStatus status) {
    if (status == StageStatus.locked) return UiStrings.stageListPrevHint;
    final enemyCount = def.enemyTeam.length;
    return '$enemyCount 名敌人';
  }
}

class _StageStatusBadge extends StatelessWidget {
  const _StageStatusBadge({required this.status});

  final StageStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      StageStatus.cleared => const Text(
          UiStrings.stageListCleared,
          style: TextStyle(
            color: WuxiaColors.hpHigh,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      StageStatus.available => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: WuxiaColors.resultHighlight.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            UiStrings.stageListAvailable,
            style: TextStyle(
              color: WuxiaColors.resultHighlight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      StageStatus.locked => const Icon(
          Icons.lock,
          color: WuxiaColors.textMuted,
          size: 18,
        ),
    };
  }
}
