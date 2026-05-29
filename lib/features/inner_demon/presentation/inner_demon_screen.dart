import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mainline/presentation/stage_entry_flow.dart';
import '../domain/inner_demon_def.dart';

/// 心魔关 stage list 屏(1.0 P2.2 §12.1,Batch 2.5.B reactive 三态)。
///
/// 7 心魔关(stage_inner_demon_01..07,贪/嗔/痴/慢/疑/空/真)按 unlock 链显:
///   - cleared(已通):右侧 ✓ 标识,可重入
///   - available(可挑战):主色显,点击走 [runStageFlow]
///   - locked(未解锁):灰显 + 锁图标,点击 disabled
///
/// **三态判定**(`InnerDemonDef.unlockTriggers` reverse 查 prev stage):
///   - stage_06_05 是 _01 的 prev(Ch6 末关 victory → 自动解 _01)
///   - _01 victory → _02 解;_02 victory → _03 解;... 链式
///   - _07 victory → A1 飞升(P2.3 留接口,本 widget 不涉)
class InnerDemonScreen extends ConsumerWidget {
  const InnerDemonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = GameRepository.instance.stageDefs.values
        .where((s) => s.stageType == StageType.innerDemon)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final innerDemonDef = GameRepository.instance.numbers.innerDemon;
    final async = ref.watch(mainlineProgressProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.innerDemonScreenTitle),
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
          data: (progress) {
            if (stages.isEmpty) {
              return const Center(
                child: Text(
                  '心魔七关未启',
                  style: TextStyle(color: WuxiaColors.textMuted),
                ),
              );
            }
            final cleared = progress.clearedStageIds.toSet();
            return ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: stages.length,
              itemBuilder: (ctx, i) {
                final s = stages[i];
                final status = _statusOf(
                  stageId: s.id,
                  clearedStageIds: cleared,
                  innerDemonDef: innerDemonDef,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InnerDemonRow(
                    def: s,
                    status: status,
                    onTap: status == _InnerDemonStageStatus.locked
                        ? null
                        : () => runStageFlow(
                              context: context,
                              ref: ref,
                              stage: s,
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

  /// 三态判定:cleared(已通过)/ available(可挑战)/ locked(未解锁)。
  ///
  /// `unlockTriggers` 字典是 `prev_stage_id → next_stage_id` 链;反查
  /// `prev = where(e => e.value == stageId).key`,若 `prev ∈ clearedStageIds`
  /// 则 available;若 `stageId ∈ clearedStageIds` 则 cleared(可重入);
  /// 否则 locked。
  static _InnerDemonStageStatus _statusOf({
    required String stageId,
    required Set<String> clearedStageIds,
    required InnerDemonDef innerDemonDef,
  }) {
    if (clearedStageIds.contains(stageId)) {
      return _InnerDemonStageStatus.cleared;
    }
    for (final e in innerDemonDef.unlockTriggers.entries) {
      if (e.value == stageId) {
        return clearedStageIds.contains(e.key)
            ? _InnerDemonStageStatus.available
            : _InnerDemonStageStatus.locked;
      }
    }
    return _InnerDemonStageStatus.locked;
  }
}

enum _InnerDemonStageStatus { cleared, available, locked }

class _InnerDemonRow extends StatelessWidget {
  const _InnerDemonRow({
    required this.def,
    required this.status,
    required this.onTap,
  });

  final StageDef def;
  final _InnerDemonStageStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = status == _InnerDemonStageStatus.locked;
    final cleared = status == _InnerDemonStageStatus.cleared;
    final titleColor =
        locked ? WuxiaColors.textMuted : WuxiaColors.textPrimary;
    final borderColor =
        cleared ? WuxiaColors.hpHigh : WuxiaColors.border;
    return Opacity(
      opacity: locked ? 0.45 : 1.0,
      child: Material(
        color: WuxiaColors.sidebar,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        style: TextStyle(color: titleColor, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '难度 ${def.difficultyMultiplier.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusIcon(status: status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final _InnerDemonStageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _InnerDemonStageStatus.cleared:
        return const Icon(Icons.check_circle,
            size: 20, color: WuxiaColors.hpHigh);
      case _InnerDemonStageStatus.available:
        return const Icon(Icons.chevron_right,
            size: 20, color: WuxiaColors.textMuted);
      case _InnerDemonStageStatus.locked:
        return const Icon(Icons.lock_outline,
            size: 20, color: WuxiaColors.textMuted);
    }
  }
}
