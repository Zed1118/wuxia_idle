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
import '../../sweep/application/sweep_unit.dart';
import '../../sweep/domain/sweep_eligibility.dart';
import '../../sweep/presentation/sweep_screen.dart';
import '../application/tower_progress_service.dart';
import '../application/tower_progress_summary.dart';
import '../application/tower_providers.dart';
import '../domain/tower_floor_def.dart';
import '../domain/tower_progress.dart';
import 'tower_entry_flow.dart';
import 'tower_floor_card.dart';

/// 爬塔层列表屏幕（Phase 3 T42）。
///
/// 顶部进度卡显示进度条 / 当前可挑战层 / 最高进度 / 下一节点。
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

  // 上次已滚动到的 available 层 index。2026-06-25:从一次性 `_hasScrolled` 改为
  // 跟踪 available index——通关一层后 available 推进到下一层(index 变化)即重新滚到
  // 新 available 层,玩家不必再从头往下滑找下一层。null=尚未滚过。
  int? _lastAvailableIndex;

  // 滚动偏移估算用的单卡高度(含 Padding vertical:6 → 卡片外高 ≈ 内容高+12)。
  // 时间线模式卡片已改 IntrinsicHeight 高度可变,这里取保守估值:普通层 ~108、
  // Boss 层 ~124(已通关 Boss 含弱点行更高)。仅用于滚动落点估算,±1 卡可接受
  // (skipLoadingOnReload 已保住既有 offset,本估算只负责把新 available 带进视野)。
  static const double _kCardHeightNormal = 108.0;
  static const double _kCardHeightBoss = 124.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// available 层 index 变化时(首次进入 / 通关推进)滚到该层附近。
  void _maybeScrollToAvailable(List<TowerFloorEntry> entries) {
    final idx = entries.indexWhere(
      (e) => e.status == TowerFloorStatus.available,
    );
    if (idx == _lastAvailableIndex) return; // available 未变 → 不重复滚
    _lastAvailableIndex = idx;
    if (idx <= 0) return; // 已在顶部或无 available
    // Boss-aware 累加估算偏移(取代旧的 idx×96 等距估算,后者随楼层累积越偏越多)。
    var offset = 0.0;
    for (var j = 0; j < idx && j < entries.length; j++) {
      offset += entries[j].def.isBoss ? _kCardHeightBoss : _kCardHeightNormal;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (!pos.hasContentDimensions) return;
      _scrollController.jumpTo(offset.clamp(0.0, pos.maxScrollExtent));
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
        // skipLoadingOnReload:通关后 invalidate(towerProgressProvider) 重载时
        // 不退回 loading 占位 → ListView 不被销毁、滚动 offset 不复位到顶部(第1层)。
        // 这是「通关后复位到最底层、要往下滑半天」的根因修复;配合 _maybeScrollToAvailable
        // 在 available 推进时把下一层带进视野。
        child: progressAsync.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              UiStrings.loadFailed(e),
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (progress) => floorListAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: InkLoadingIndicator()),
            error: (e, _) => Center(
              child: SelectableText(
                UiStrings.loadFailed(e),
                style: const TextStyle(color: WuxiaColors.hpLow),
              ),
            ),
            data: (entries) {
              _maybeScrollToAvailable(entries);
              final summary = TowerProgressSummary.from(
                progress: progress,
                entries: entries,
              );
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
                  _ProgressCard(progress: progress, summary: summary),
                  // 一键扫荡 30 层入口（醒目主按钮·本周目整塔已通才亮）。
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _TowerSweepButton(
                      entries: entries,
                      cycleIndex: progress.currentCycleIndex,
                      eligible: SweepEligibility.forTower(
                        highestClearedFloor: progress.highestClearedFloor,
                        floorCount: entries.length,
                      ),
                      // 灰显门槛提示仅在整塔至少通关过一次后出现;全新塔仍隐藏。
                      everCleared: progress.maxClearedCycle >= 1,
                    ),
                  ),
                  // P1 周目进化 E2：爬塔轮回推进卡（30 层全通 + 未达上限时显示）。
                  if (canAdvance)
                    _TowerAdvanceCycleCard(onAdvance: _onAdvanceCycle),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _TowerSpineOverview(
                      entries: entries,
                      summary: summary,
                    ),
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
  const _TowerSpineOverview({required this.entries, required this.summary});

  final List<TowerFloorEntry> entries;
  final TowerProgressSummary summary;

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
                  _TowerSpineNode(entry: entry, summary: summary),
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
          const SizedBox(height: 8),
          const Text(
            UiStrings.towerSpineLegend,
            style: TextStyle(color: WuxiaColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TowerSpineNode extends StatelessWidget {
  const _TowerSpineNode({required this.entry, required this.summary});

  final TowerFloorEntry entry;
  final TowerProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final isCurrent =
        !summary.isComplete && entry.def.floorIndex == summary.currentFloor;
    final isHighest =
        summary.hasAnyClear &&
        entry.def.floorIndex == summary.highestClearedFloor;
    final color = switch (entry.status) {
      TowerFloorStatus.cleared => WuxiaColors.hpHigh,
      TowerFloorStatus.available => WuxiaColors.resultHighlight,
      TowerFloorStatus.locked => WuxiaUi.muted,
    };
    final isBoss = entry.def.isBoss;
    final isMajorBoss = entry.def.bossKind == TowerBossKind.major;
    final borderWidth = isCurrent
        ? 2.2
        : isHighest
        ? 1.8
        : isBoss
        ? 1.6
        : 1.1;
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
              border: Border.all(color: color, width: borderWidth),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.34),
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
          SizedBox(
            height: 14,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                isBoss
                    ? (isMajorBoss
                          ? UiStrings.towerBossBadgeMajor
                          : UiStrings.towerBossBadgeMinor)
                    : isCurrent
                    ? UiStrings.towerSpineCurrentBadge
                    : isHighest
                    ? UiStrings.towerSpineHighestBadge
                    : '',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.summary});

  final TowerProgress progress;
  final TowerProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: WuxiaColors.panel,
        border: Border(bottom: BorderSide(color: WuxiaColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  UiStrings.towerProgressBarLabel(
                    summary.highestClearedFloor,
                    summary.totalFloors,
                  ),
                  style: const TextStyle(
                    color: WuxiaColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatItem(
                label: UiStrings.towerCurrentCycleLabel(
                  progress.currentCycleIndex,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MeridianBar(ratio: summary.progressRatio, height: 10),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProgressPill(
                label: summary.isComplete
                    ? UiStrings.towerCurrentChallengeComplete
                    : UiStrings.towerCurrentChallengeFloor(
                        summary.currentFloor,
                      ),
                emphasized: !summary.isComplete,
              ),
              _ProgressPill(
                label: summary.hasAnyClear
                    ? UiStrings.towerHighestClearedFloor(
                        summary.highestClearedFloor,
                      )
                    : UiStrings.towerHighestClearedNone,
              ),
              _ProgressPill(label: _nextMilestoneLabel(summary)),
              _ProgressPill(
                label: UiStrings.towerProgressAttempts(progress.totalAttempts),
              ),
              _ProgressPill(
                label: UiStrings.towerProgressDefeats(progress.totalDefeats),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _nextMilestoneLabel(TowerProgressSummary summary) {
    final milestone = summary.nextMilestone;
    if (milestone == null) return UiStrings.towerNextMilestoneComplete;
    final name = milestone.floorIndex == summary.totalFloors
        ? UiStrings.towerMilestoneSummitBoss
        : milestone.bossKind == TowerBossKind.major
        ? UiStrings.towerBossMajor
        : UiStrings.towerBossMinor;
    return UiStrings.towerNextMilestoneTarget(milestone.floorIndex, name);
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

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized
        ? WuxiaColors.resultHighlight
        : WuxiaColors.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasized ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.42), width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
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
              style: TextStyle(color: WuxiaColors.textSecondary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onAdvance,
            style: TextButton.styleFrom(
              foregroundColor: WuxiaColors.resultHighlight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

/// 一键扫荡 30 层入口（醒目主按钮）。本周目整塔已通 → 高亮可点；否则灰显 + 门槛提示。
class _TowerSweepButton extends StatelessWidget {
  const _TowerSweepButton({
    required this.entries,
    required this.cycleIndex,
    required this.eligible,
    required this.everCleared,
  });

  final List<TowerFloorEntry> entries;
  final int cycleIndex;
  final bool eligible;

  /// 整塔是否至少通关过一次（任一周目）。false 且未达门槛 → 整块隐藏。
  final bool everCleared;

  @override
  Widget build(BuildContext context) {
    // 从未通过整塔 → 不显（保持全新塔干净）。
    if (!eligible && !everCleared) return const SizedBox.shrink();
    // §5.7：通关过、但本周目整塔未手工通关 → 灰显 + 提示（不再整块隐藏），
    // 让玩家知道扫的是哪个周目、以及为何还不能扫（需先手工通关本周目整塔）。
    if (!eligible) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: WuxiaColors.panel,
            foregroundColor: WuxiaColors.textMuted,
            disabledBackgroundColor: WuxiaColors.panel,
            disabledForegroundColor: WuxiaColors.textMuted,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: null,
          icon: const Icon(Icons.lock_outline, size: 18),
          label: Text(UiStrings.sweepLockedHintCycle(cycleIndex)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: WuxiaColors.bossFrame,
          foregroundColor: WuxiaColors.background,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          final units = [
            for (final e in entries)
              TowerSweepUnit(floor: e.def, cycleIndex: cycleIndex),
          ];
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => SweepScreen(
                units: units,
                unitName: UiStrings.towerTitle,
                cycle: cycleIndex,
                towerRepeatNote: true,
              ),
            ),
          );
        },
        icon: const Icon(Icons.fast_forward, size: 22),
        label: Text(UiStrings.sweepTowerButtonCycle(cycleIndex)),
      ),
    );
  }
}
