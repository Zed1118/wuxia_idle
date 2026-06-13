import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/stage_def.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/application/battle_replay_record_service.dart';
import '../../battle/presentation/stage_auto_play_control.dart';
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _StageJourneyMap(chapterIndex: chapterIndex, entries: entries),
                const SizedBox(height: 12),
                for (var i = 0; i < entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StageRow(
                      stageIndex: i + 1,
                      def: entries[i].def,
                      status: entries[i].status,
                      onTap: entries[i].status == StageStatus.locked
                          ? null
                          : () => runStageFlow(
                              context: context,
                              ref: ref,
                              stage: entries[i].def,
                            ),
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

class _StageJourneyMap extends StatelessWidget {
  const _StageJourneyMap({required this.chapterIndex, required this.entries});

  final int chapterIndex;
  final List<StageEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            chapterCoverPath(chapterIndex),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: WuxiaColors.avatarFill),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            UiStrings.stageListJourneyTitle,
                            style: TextStyle(
                              color: WuxiaColors.resultHighlight,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            UiStrings.chapterTitle(chapterIndex),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WuxiaColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Text(
                        UiStrings.chapterHint(chapterIndex),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: WuxiaColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      Expanded(
                        child: _StageJourneyNode(
                          stageIndex: i + 1,
                          entry: entries[i],
                        ),
                      ),
                      if (i != entries.length - 1)
                        Container(
                          width: 28,
                          height: 2,
                          color: WuxiaColors.textMuted.withValues(alpha: 0.45),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageJourneyNode extends StatelessWidget {
  const _StageJourneyNode({required this.stageIndex, required this.entry});

  final int stageIndex;
  final StageEntry entry;

  @override
  Widget build(BuildContext context) {
    final status = entry.status;
    final boss = entry.def.isBossStage;
    final color = switch (status) {
      StageStatus.cleared => WuxiaColors.hpHigh,
      StageStatus.available => WuxiaColors.resultHighlight,
      StageStatus.locked => WuxiaColors.textMuted,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: boss ? 46 : 38,
          height: boss ? 46 : 38,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(boss ? 6 : 19),
            border: Border.all(
              color: color,
              width: status == StageStatus.available ? 2 : 1.4,
            ),
          ),
          alignment: Alignment.center,
          child: boss
              ? Icon(Icons.military_tech, color: color, size: 22)
              : Text(
                  UiStrings.mainlineRouteStageNode(stageIndex),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          boss
              ? UiStrings.stageListBoss
              : UiStrings.stageListJourneyNodeLabel(stageIndex),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: status == StageStatus.locked
                ? WuxiaColors.textMuted
                : WuxiaColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stageIndex,
    required this.def,
    required this.status,
    required this.onTap,
  });

  final int stageIndex;
  final StageDef def;
  final StageStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = status == StageStatus.locked;
    final cleared = status == StageStatus.cleared;
    final available = status == StageStatus.available;
    final boss = def.isBossStage;
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
            color: locked
                ? WuxiaColors.avatarFill
                : WuxiaColors.panel.withValues(alpha: boss ? 0.96 : 0.88),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: boss
                  ? WuxiaColors.resultHighlight.withValues(alpha: 0.55)
                  : WuxiaColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              _StageMarker(
                stageIndex: stageIndex,
                boss: boss,
                color: borderColor,
                active: available,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            def.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: locked
                                  ? WuxiaColors.textMuted
                                  : WuxiaColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (boss) ...[
                          const SizedBox(width: 8),
                          const Text(
                            UiStrings.stageListBoss,
                            style: TextStyle(
                              color: WuxiaColors.resultHighlight,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleFor(def, status),
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    // 半手动 P0 步骤5-G3:已通关关卡可逐关切自动/手动。
                    if (cleared) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StageAutoPlayControl(
                          battleKey: BattleReplayRecordService.stageBattleKey(
                            def.id,
                          ),
                        ),
                      ),
                    ],
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
    return UiStrings.stageListEnemyCount(def.enemyTeam.length);
  }
}

class _StageMarker extends StatelessWidget {
  const _StageMarker({
    required this.stageIndex,
    required this.boss,
    required this.color,
    required this.active,
  });

  final int stageIndex;
  final bool boss;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(boss ? 6 : 19),
        border: Border.all(color: color, width: active ? 2 : 1.3),
      ),
      alignment: Alignment.center,
      child: boss
          ? Icon(Icons.military_tech, color: color, size: 20)
          : Text(
              UiStrings.mainlineRouteStageNode(stageIndex),
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
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
