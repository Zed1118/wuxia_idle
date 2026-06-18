import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../core/application/character_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/wuxia_ui.dart';
import '../../../data/isar_setup.dart';
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
/// 点 available push 进入 TowerEntryFlow。
@Dependencies([towerProgress])
class TowerFloorListScreen extends ConsumerStatefulWidget {
  const TowerFloorListScreen({super.key});

  @override
  ConsumerState<TowerFloorListScreen> createState() =>
      _TowerFloorListScreenState();
}

class _TowerFloorListScreenState extends ConsumerState<TowerFloorListScreen> {
  final _scrollController = ScrollController();
  bool _hasScrolled = false;

  // 石阶行约 112px（含掉落传闻行）；用于首次进入时滚到可挑战层附近。
  static const double _kCardHeight = 112.0;

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

  /// P1 周目进化 E2：推进到下一轮回（TowerProgressService.advanceCycle）。
  Future<void> _onAdvanceCycle() async {
    final maxCycleTower =
        GameRepository.instance.numbers.cycleEvolution.maxCycleTower;
    await TowerProgressService(isar: IsarSetup.instance).advanceCycle(
      saveDataId: IsarSetup.currentSlotId,
      maxCycleCap: maxCycleTower,
    );
    ref.invalidate(towerProgressProvider);
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
              final maxCycleTower =
                  GameRepository.instance.numbers.cycleEvolution.maxCycleTower;
              final canAdvance =
                  progress.maxClearedCycle >= progress.currentCycleIndex &&
                      progress.currentCycleIndex < maxCycleTower;
              // 主战角色当前境界（用于掉落传闻弹窗 above-realm 提示）。
              final currentRealm = ref
                  .watch(activeCharacterIdsProvider)
                  .maybeWhen(
                    data: (ids) => ids.isEmpty
                        ? null
                        : ref
                              .watch(characterByIdProvider(ids.first))
                              .maybeWhen(
                                data: (c) => c?.realmTier,
                                orElse: () => null,
                              ),
                    orElse: () => null,
                  );
              return Column(
                children: [
                  _ProgressCard(progress: progress),
                  // P1 周目进化 E2：爬塔轮回推进卡（30 层全通 + 未达上限时显示）。
                  if (canAdvance)
                    _TowerAdvanceCycleCard(onAdvance: _onAdvanceCycle),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _TowerSpineOverview(entries: entries),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: entries.length,
                      itemBuilder: (ctx, i) => TowerFloorCard(
                        key: ValueKey(entries[i].def.floorIndex),
                        entry: entries[i],
                        stepSide: i.isEven
                            ? TowerFloorStepSide.left
                            : TowerFloorStepSide.right,
                        onChallenge: () =>
                            _onChallenge(context, entries[i].def),
                        currentRealm: currentRealm,
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

class _TowerSpineOverview extends StatelessWidget {
  const _TowerSpineOverview({required this.entries});

  final List<TowerFloorEntry> entries;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(UiStrings.towerSpineTitle),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in entries) ...[
                  _TowerSpineNode(entry: entry),
                  if (entry.def.floorIndex != entries.last.def.floorIndex)
                    Container(
                      width: 12,
                      height: 2,
                      color: WuxiaUi.ink.withValues(alpha: 0.18),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TowerSpineNode extends StatelessWidget {
  const _TowerSpineNode({required this.entry});

  final TowerFloorEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.status) {
      TowerFloorStatus.cleared => WuxiaColors.hpHigh,
      TowerFloorStatus.available => WuxiaColors.resultHighlight,
      TowerFloorStatus.locked => WuxiaUi.muted,
    };
    final isBoss = entry.def.isBoss;
    final isMajorBoss = entry.def.bossKind == TowerBossKind.major;
    return SizedBox(
      width: isBoss ? 36 : 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isBoss ? 32 : 22,
            height: isBoss ? 32 : 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isBoss ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(isBoss ? 5 : 11),
              border: Border.all(color: color, width: isBoss ? 1.6 : 1.1),
              boxShadow: entry.status == TowerFloorStatus.available
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '${entry.def.floorIndex}',
              style: TextStyle(
                color: color,
                fontSize: isBoss ? 11 : 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 10,
            child: isBoss
                ? Text(
                    isMajorBoss ? '大' : '小',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
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
        border: Border(bottom: BorderSide(color: WuxiaColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: UiStrings.towerProgressCleared(progress.highestClearedFloor),
          ),
          _StatItem(
            label: UiStrings.towerProgressAttempts(progress.totalAttempts),
          ),
          _StatItem(
            label: UiStrings.towerProgressDefeats(progress.totalDefeats),
          ),
          // P1 周目进化 E2：当前轮回标签。
          _StatItem(
            label: UiStrings.towerCurrentCycleLabel(progress.currentCycleIndex),
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
      style: const TextStyle(color: WuxiaColors.textSecondary, fontSize: 13),
    );
  }
}

// ─── P1 周目进化 E2：爬塔轮回推进卡 ──────────────────────────────────────────

/// 30 层全通 + 未达 maxCycleTower 时显示的「挑战下一轮回」入口。
///
/// 点击后调用 [onAdvance]（委派 [TowerProgressService.advanceCycle]），
/// 成功后 invalidate towerProgressProvider，页面自动刷新进入新周目（第 1 层）。
class _TowerAdvanceCycleCard extends StatelessWidget {
  const _TowerAdvanceCycleCard({required this.onAdvance});

  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: WuxiaColors.resultHighlight.withValues(alpha: 0.08),
        border: const Border(
          bottom: BorderSide(color: WuxiaColors.resultHighlight, width: 0.6),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.loop, color: WuxiaColors.resultHighlight, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              UiStrings.towerCycleReadyHint,
              style: TextStyle(
                color: WuxiaColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onAdvance,
            style: TextButton.styleFrom(
              foregroundColor: WuxiaColors.resultHighlight,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              UiStrings.towerAdvanceCycleButton,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
