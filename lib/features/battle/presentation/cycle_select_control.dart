import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/battle_providers.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/application/mainline_providers.dart';

/// P1 周目进化 E1：选关屏「周目选择」控件。
///
/// 给定 [stageId]，读 [mainlineProgressProvider] + [numbersConfigProvider]，
/// 计算该关已通最高周目与可挑战周目，渲染选择 UI。
///
/// 状态说明：
/// - highestCleared == 0（从未通关）→ 返回空占位（caller 门控：只对已通关关卡渲染本控件）。
/// - highestCleared ≥ 1 且 < maxCycle → 双选项：
///   「第N周目 (自动)」回放已通关周目；「挑战第(N+1)周目 (手动)」进手动挑战。
/// - highestCleared == maxCycle（已达最高）→ 仅展示「已达最高周目」+ 重演按钮。
///
/// E2 负责将 [onSelectCycle] 接入实际战斗跳转逻辑（含江湖记招提示）；
/// E1 只负责控件渲染 + 回调，不持久化、不跳转。
class CycleSelectControl extends ConsumerWidget {
  const CycleSelectControl({
    super.key,
    required this.stageId,
    this.onSelectCycle,
  });

  /// 关卡 id（与 `data/stages.yaml` 的 id 字段对应）。
  final String stageId;

  /// 周目选择回调：玩家选择目标周目编号后触发。
  ///
  /// 回放已通关周目 → targetCycle = highestCleared；
  /// 挑战下一周目   → targetCycle = highestCleared + 1。
  /// E2 通过此回调接入战斗跳转逻辑。
  final ValueChanged<int>? onSelectCycle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(mainlineProgressProvider);
    final numbers = ref.watch(numbersConfigProvider);

    final progress = progressAsync.maybeWhen(
      data: (d) => d,
      orElse: () => null,
    );
    if (progress == null) return const SizedBox.shrink();

    final highest = MainlineProgressService.highestClearedCycle(
      progress,
      stageId,
    );
    // 从未通关：不渲染（caller 门控，防御性兜底）
    if (highest == 0) return const SizedBox.shrink();

    final maxCycle = numbers.cycleEvolution.maxCycleMainline;
    final atMax = highest >= maxCycle;

    return _CycleSelectLayout(
      highestCleared: highest,
      maxCycle: maxCycle,
      atMax: atMax,
      onSelectCycle: onSelectCycle,
    );
  }
}

// ─── Internal Layout ─────────────────────────────────────────────────────────

class _CycleSelectLayout extends StatelessWidget {
  const _CycleSelectLayout({
    required this.highestCleared,
    required this.maxCycle,
    required this.atMax,
    required this.onSelectCycle,
  });

  final int highestCleared;
  final int maxCycle;
  final bool atMax;
  final ValueChanged<int>? onSelectCycle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (atMax) ...[
          // 已达最高周目提示行
          const _CycleStatusRow(
            label: UiStrings.cycleMaxReachedLabel,
            color: WuxiaColors.resultHighlight,
          ),
          const SizedBox(height: 6),
          // 重演最高周目按钮
          _CycleButton(
            cycleLabel: UiStrings.cycleNthLabel(highestCleared),
            suffix: UiStrings.cycleReplayCurrentSuffix,
            isChallenge: false,
            onTap: () => onSelectCycle?.call(highestCleared),
          ),
        ] else ...[
          // 回放已通关周目按钮
          _CycleButton(
            cycleLabel: UiStrings.cycleNthLabel(highestCleared),
            suffix: UiStrings.cycleReplayCurrentSuffix,
            isChallenge: false,
            onTap: () => onSelectCycle?.call(highestCleared),
          ),
          const SizedBox(height: 6),
          // 挑战下一周目按钮
          _CycleButton(
            cycleLabel: UiStrings.cycleChallengeNextLabel(highestCleared + 1),
            suffix: UiStrings.cycleChallengeNextSuffix,
            isChallenge: true,
            onTap: () => onSelectCycle?.call(highestCleared + 1),
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

/// 周目选择按钮（回放 / 挑战）。
class _CycleButton extends StatelessWidget {
  const _CycleButton({
    required this.cycleLabel,
    required this.suffix,
    required this.isChallenge,
    required this.onTap,
  });

  final String cycleLabel;
  final String suffix;
  final bool isChallenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = isChallenge
        ? WuxiaColors.resultHighlight
        : WuxiaColors.textSecondary;
    final suffixColor = isChallenge
        ? WuxiaColors.gangMeng
        : WuxiaColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isChallenge
              ? WuxiaColors.panel
              : WuxiaColors.background,
          border: Border.all(
            color: isChallenge
                ? WuxiaColors.resultHighlight.withValues(alpha: 0.5)
                : WuxiaColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              cycleLabel,
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: isChallenge
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
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
