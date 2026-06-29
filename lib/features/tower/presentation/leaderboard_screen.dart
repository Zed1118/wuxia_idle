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
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      children: [
        _MetricTile(
          label: UiStrings.leaderboardHighestLayer,
          value: '${p.highestClearedFloor} ${UiStrings.leaderboardLayerSuffix}',
        ),
        const SizedBox(height: 12),
        _MetricTile(
          label: UiStrings.leaderboardBestClearTime,
          value: p.bestClearTime == null
              ? UiStrings.leaderboardNoData
              : _formatDuration(p.bestClearTime!),
        ),
        const SizedBox(height: 12),
        _MetricTile(
          label: UiStrings.leaderboardTotalAttempts,
          value: '${p.totalAttempts}',
        ),
        if (p.totalDefeats > 0) ...[
          const SizedBox(height: 12),
          _MetricTile(
            label: UiStrings.leaderboardWinRate,
            value: _formatWinRate(p),
          ),
        ],
      ],
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
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: WuxiaColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
