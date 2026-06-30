import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../application/tower_providers.dart';
import '../domain/tower_progress.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// P0.2 #40 Phase 4 本地排行榜屏(D 方案,Demo 不接 Supabase backend)。
///
/// 直接读 [towerProgressProvider] 真源,3+1 指标:
///   - 最高通关层(highestClearedFloor)
///   - 最佳通关耗时(bestClearTime,首通锁定)
///   - 累计挑战次数(totalAttempts)
///   - 胜率(派生 = (totalAttempts - totalDefeats) / totalAttempts,仅 totalDefeats > 0 显)
///
/// 空态(highestClearedFloor=0)显「尚未通关任何爬塔层」提示。
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(towerProgressProvider);
    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.panel,
        title: const Text(
          UiStrings.leaderboardTitle,
          style: TextStyle(color: WuxiaColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: WuxiaColors.textPrimary),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: InkLoadingIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              '$e',
              style: const TextStyle(color: WuxiaColors.textPrimary),
            ),
          ),
        ),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(TowerProgress p) {
    if (p.highestClearedFloor == 0) {
      return const Center(
        child: Text(
          UiStrings.leaderboardEmpty,
          style: TextStyle(color: WuxiaColors.textSecondary, fontSize: 14),
        ),
      );
    }
    final metrics = [
      _MetricTile(
        icon: Icons.flag_outlined,
        label: UiStrings.leaderboardHighestLayer,
        value: '${p.highestClearedFloor} ${UiStrings.leaderboardLayerSuffix}',
        emphasized: true,
      ),
      _MetricTile(
        icon: Icons.timer_outlined,
        label: UiStrings.leaderboardBestClearTime,
        value: p.bestClearTime == null
            ? UiStrings.leaderboardNoData
            : _formatDuration(p.bestClearTime!),
      ),
      _MetricTile(
        icon: Icons.history_outlined,
        label: UiStrings.leaderboardTotalAttempts,
        value: '${p.totalAttempts}',
      ),
      if (p.totalDefeats > 0)
        _MetricTile(
          icon: Icons.percent_outlined,
          label: UiStrings.leaderboardWinRate,
          value: _formatWinRate(p),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 920
            ? 880.0
            : constraints.maxWidth;
        final tileWidth = constraints.maxWidth >= 760
            ? (maxWidth - 12) / 2
            : maxWidth;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final metric in metrics)
                      SizedBox(width: tileWidth, child: metric),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatDuration(int ms) {
    final totalSeconds = (ms / 1000).round();
    if (totalSeconds < 60) {
      return UiStrings.leaderboardDurationSeconds(totalSeconds);
    }
    return UiStrings.leaderboardDurationMinutes(
      totalSeconds ~/ 60,
      totalSeconds % 60,
    );
  }

  static String _formatWinRate(TowerProgress p) {
    if (p.totalAttempts == 0) {
      return UiStrings.leaderboardWinRatePct(0);
    }
    final wins = p.totalAttempts - p.totalDefeats;
    final pct = (wins * 100 / p.totalAttempts).round();
    return UiStrings.leaderboardWinRatePct(pct);
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final accent = emphasized
        ? WuxiaColors.resultHighlight
        : WuxiaColors.textSecondary;
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            emphasized
                ? WuxiaColors.resultHighlight.withValues(alpha: 0.12)
                : WuxiaColors.panel,
            WuxiaColors.panel,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: emphasized
              ? WuxiaColors.resultHighlight.withValues(alpha: 0.58)
              : WuxiaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: WuxiaColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: emphasized
                  ? WuxiaColors.resultHighlight
                  : WuxiaColors.textPrimary,
              fontSize: emphasized ? 22 : 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
