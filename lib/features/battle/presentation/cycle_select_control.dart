import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/battle_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/application/mainline_providers.dart';
import '../application/selected_cycle_provider.dart';

/// 周目按章选择控件(战斗交互重做 Phase 2,从 per-stage 上移到章层)。
///
/// 给定 [chapterKey](主线 `ch{N}` / 副本 `stageType.name`),读
/// [mainlineProgressProvider] + [numbersConfigProvider] 算该章已通最高周目,
/// 渲染选择 UI 并写 [selectedChallengeCycleProvider]——本控件只「设状态」,真正
/// 进入战斗由该章的关卡 tile 点击读回选定周目(见各选关屏)。
///
/// 状态说明:
/// - highestCleared == 0(整章未通,章末 Boss 未过)→ 空占位(首通走 cycle 1,
///   无周目可选)。
/// - highestCleared ≥ 1 且 < maxCycle → 双选项:「回放第N周目」/「挑战第(N+1)周目」,
///   选中项高亮。
/// - highestCleared == maxCycle → 仅「已达最高周目」标签 + 回放当前周目。
class CycleSelectControl extends ConsumerWidget {
  const CycleSelectControl({super.key, required this.chapterKey});

  /// 章 key:主线 `ch{chapterIndex}`,副本 `stageType.name`。
  final String chapterKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(mainlineProgressProvider);
    final numbers = ref.watch(numbersConfigProvider);

    final progress = progressAsync.maybeWhen(
      data: (d) => d,
      orElse: () => null,
    );
    if (progress == null) return const SizedBox.shrink();

    final highest = MainlineProgressService.highestClearedCycleForChapter(
      progress,
      chapterKey,
    );
    // 整章未通:不渲染(首通走 cycle 1,无周目选择)。
    if (highest == 0) return const SizedBox.shrink();

    final maxCycle = numbers.cycleEvolution.maxCycleMainline;
    final atMax = highest >= maxCycle;
    final selected =
        ref.watch(selectedChallengeCycleProvider(chapterKey)) ?? highest;

    void choose(int cycle) => ref
        .read(selectedChallengeCycleProvider(chapterKey).notifier)
        .select(cycle);

    return _CycleSelectLayout(
      highestCleared: highest,
      maxCycle: maxCycle,
      atMax: atMax,
      selected: selected,
      onChoose: choose,
    );
  }
}

// ─── Internal Layout ─────────────────────────────────────────────────────────

class _CycleSelectLayout extends StatelessWidget {
  const _CycleSelectLayout({
    required this.highestCleared,
    required this.maxCycle,
    required this.atMax,
    required this.selected,
    required this.onChoose,
  });

  final int highestCleared;
  final int maxCycle;
  final bool atMax;
  final int selected;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (atMax) ...[
          const _CycleStatusRow(
            label: UiStrings.cycleMaxReachedLabel,
            color: WuxiaColors.resultHighlight,
          ),
          const SizedBox(height: 6),
          _CycleButton(
            cycleLabel: UiStrings.cycleNthLabel(highestCleared),
            suffix: UiStrings.cycleReplayCurrentSuffix,
            isChallenge: false,
            selected: selected == highestCleared,
            onTap: () => onChoose(highestCleared),
          ),
        ] else ...[
          _CycleButton(
            cycleLabel: UiStrings.cycleNthLabel(highestCleared),
            suffix: UiStrings.cycleReplayCurrentSuffix,
            isChallenge: false,
            selected: selected == highestCleared,
            onTap: () => onChoose(highestCleared),
          ),
          const SizedBox(height: 6),
          _CycleButton(
            cycleLabel: UiStrings.cycleChallengeNextLabel(highestCleared + 1),
            suffix: UiStrings.cycleChallengeNextSuffix,
            isChallenge: true,
            selected: selected == highestCleared + 1,
            onTap: () => onChoose(highestCleared + 1),
          ),
        ],
      ],
    );
  }
}

/// 状态标签行（如「已达最高周目」）。
class _CycleStatusRow extends StatelessWidget {
  const _CycleStatusRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// 周目选择按钮（回放 / 挑战）。选中态加粗边框 + 勾标。
class _CycleButton extends StatelessWidget {
  const _CycleButton({
    required this.cycleLabel,
    required this.suffix,
    required this.isChallenge,
    required this.selected,
    required this.onTap,
  });

  final String cycleLabel;
  final String suffix;
  final bool isChallenge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isChallenge
        ? WuxiaColors.resultHighlight
        : WuxiaColors.textSecondary;
    final labelColor = selected ? WuxiaColors.textPrimary : accent;
    final suffixColor = isChallenge
        ? WuxiaColors.gangMeng
        : WuxiaColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.22)
              : (isChallenge ? WuxiaColors.panel : WuxiaColors.background),
          border: Border.all(
            color: selected
                ? accent
                : (isChallenge
                    ? WuxiaColors.resultHighlight.withValues(alpha: 0.5)
                    : WuxiaColors.border),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check,
                    size: 13,
                    color: WuxiaColors.textPrimary,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  cycleLabel,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: (isChallenge || selected)
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            Text(
              suffix,
              style: TextStyle(
                color: suffixColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
