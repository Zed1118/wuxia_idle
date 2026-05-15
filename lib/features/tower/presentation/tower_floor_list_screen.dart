import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../ui/strings.dart';
import '../../../ui/theme/colors.dart';
import '../application/tower_progress_service.dart';
import '../application/tower_providers.dart';
import '../domain/tower_floor_def.dart';
import '../domain/tower_progress.dart';
import 'tower_entry_flow.dart';
import 'tower_floor_card.dart';

/// 爬塔层列表屏幕（Phase 3 T42）。
///
/// 顶部进度卡显示已通层数 / 总尝试 / 失败次数。
/// 主体 30 行 [TowerFloorCard]，首次进入自动滚到 available 层（一次性）。
/// 点 available 弹 SnackBar 占位（T43 落地后改 push TowerEntryFlow）。
class TowerFloorListScreen extends ConsumerStatefulWidget {
  const TowerFloorListScreen({super.key});

  @override
  ConsumerState<TowerFloorListScreen> createState() =>
      _TowerFloorListScreenState();
}

class _TowerFloorListScreenState extends ConsumerState<TowerFloorListScreen> {
  final _scrollController = ScrollController();
  bool _hasScrolled = false;

  // 每行约 80px（padding 10 × 2 + content 60）
  static const double _kCardHeight = 80.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeScrollToAvailable(List<TowerFloorEntry> entries) {
    if (_hasScrolled) return;
    _hasScrolled = true;
    final idx = entries.indexWhere(
      (e) => e.status == TowerFloorStatus.available,
    );
    if (idx <= 0) return; // 已在顶部或无 available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (!pos.hasContentDimensions) return;
      _scrollController.jumpTo(
        (idx * _kCardHeight).clamp(0.0, pos.maxScrollExtent),
      );
    });
  }

  void _onChallenge(BuildContext context, TowerFloorDef def) {
    // ignore: discarded_futures - fire-and-forget 导航模式，与 runStageFlow 一致
    runTowerFlow(context: context, ref: ref, floor: def);
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(towerProgressProvider);
    final floorListAsync = ref.watch(towerFloorListProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.towerTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              '加载失败：$e',
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (progress) => floorListAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: SelectableText(
                '加载失败：$e',
                style: const TextStyle(color: WuxiaColors.hpLow),
              ),
            ),
            data: (entries) {
              _maybeScrollToAvailable(entries);
              return Column(
                children: [
                  _ProgressCard(progress: progress),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: entries.length,
                      itemBuilder: (ctx, i) => TowerFloorCard(
                        key: ValueKey(entries[i].def.floorIndex),
                        entry: entries[i],
                        onChallenge: () =>
                            _onChallenge(context, entries[i].def),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final TowerProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(
          bottom: BorderSide(color: WuxiaColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: UiStrings.towerProgressCleared(
              progress.highestClearedFloor,
            ),
          ),
          _StatItem(
            label: UiStrings.towerProgressAttempts(progress.totalAttempts),
          ),
          _StatItem(
            label: UiStrings.towerProgressDefeats(progress.totalDefeats),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: WuxiaColors.textSecondary,
        fontSize: 13,
      ),
    );
  }
}
