import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../mainline/application/mainline_providers.dart';
import '../application/pvp_providers.dart';
import 'widgets/pvp_history_list.dart';
import 'widgets/rank_badge_widget.dart';

/// PVP 论剑对决主屏(1.0 P3.3 §12.3 Phase 4 · spec p3_3_pvp_spec_2026-05-24 §5)。
///
/// **三态**:
///   - **locked**:`stage_05_05`(主线 Ch5 末)未通 → 显锁定文案,点击 disabled
///   - **available**:显当前 ELO + [RankBadgeWidget] + 立即论剑 button +
///     [PvpHistoryList](最近 N 场,空态显空文案)
///   - **cleared 无终态**:PVP 不终结(沿 leaderboard 体例),始终 available
///
/// **Match button 行为**(本 Phase shell):snackbar 提示「Phase 5 真战斗 wire」。
/// 真战斗流程(读玩家阵容 + PvpService.match + Isar 持久化 + ELO 持久化)
/// 留 Phase 5 closeout 挂账,本 Phase 不引入 character_providers 依赖避免
/// widget test 难度膨胀(沿 P0.2 #40 leaderboard 体例)。
class PvpScreen extends ConsumerWidget {
  const PvpScreen({super.key});

  static const String _unlockStageId = 'stage_05_05';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(mainlineProgressProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
        title: const Text(UiStrings.pvpTitle),
      ),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              UiStrings.loadFailed(e),
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (progress) {
            final unlocked =
                progress.clearedStageIds.contains(_unlockStageId);
            if (!unlocked) return const _LockedView();
            return const _AvailableView();
          },
        ),
      ),
    );
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                size: 48, color: WuxiaColors.textMuted),
            SizedBox(height: 16),
            Text(
              UiStrings.pvpLockedHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: WuxiaColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableView extends ConsumerWidget {
  const _AvailableView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elo = ref.watch(currentPvpEloProvider);
    final records = ref.watch(pvpRecentRecordsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RankBadgeWidget(currentElo: elo),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WuxiaColors.panel,
              foregroundColor: WuxiaColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: WuxiaColors.border),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(UiStrings.pvpMatchPlaceholder),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text(
              UiStrings.pvpMatchButton,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            UiStrings.pvpHistoryTitle,
            style: TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          PvpHistoryList(records: records, playerId: 1),
        ],
      ),
    );
  }
}
