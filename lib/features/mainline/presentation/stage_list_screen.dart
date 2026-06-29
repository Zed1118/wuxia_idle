import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/game_repository.dart';
import '../../../data/defs/stage_def.dart';
import '../../../core/application/character_providers.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/glossary_tip.dart';
import '../../battle/application/selected_cycle_provider.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../battle/domain/cycle_trait_intel.dart';
import '../../battle/presentation/cycle_select_control.dart';
import '../../loot_preview/domain/drop_rumor.dart';
import '../../loot_preview/domain/stage_difficulty.dart';
import '../../loot_preview/presentation/loot_summary_line.dart';
import '../../loot_preview/presentation/stage_intel_dialog.dart';
import '../../loot_preview/presentation/stage_preview_card.dart'
    show difficultyLabelColor;
import '../../loot_preview/presentation/weakness_hint_line.dart';
import '../../sweep/application/sweep_unit.dart';
import '../../sweep/domain/sweep_eligibility.dart';
import '../../sweep/domain/sweep_reward_preview.dart';
import '../../sweep/presentation/sweep_screen.dart';
import '../application/mainline_progress_service.dart';
import '../application/mainline_providers.dart';
import '../application/new_save_goal_guidance.dart';
import '../domain/chapter_assets.dart';
import '../domain/mainline_replay_reward_route.dart';
import 'new_save_goal_guidance_view.dart';
import 'stage_entry_flow.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

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
          loading: () => const Center(child: InkLoadingIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              UiStrings.loadFailed(e),
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
            // 周目按章(Phase 2):章 key + 该章已通最高周目决定进入周目。
            final chapterKey = 'ch$chapterIndex';
            final progress = ref
                .watch(mainlineProgressProvider)
                .maybeWhen(data: (d) => d, orElse: () => null);
            // watch(非 read):玩家在 CycleSelectControl 切周目时本屏须重建,
            // 使扫荡按钮标签/门槛、各关卡按周目状态都随选定周目刷新。
            final selectedCycle = ref.watch(
              selectedChallengeCycleProvider(chapterKey),
            );
            int cycleFor() {
              if (progress == null) return 1;
              return resolveTargetCycle(selectedCycle, progress, chapterKey);
            }

            // 按选定周目算关卡显示状态:cycle 1 用原解锁链状态;cycle≥2 时全关已由
            // 首周目解锁→该周目通过该关(clearedStageCycleKeys 含 id#cycle)显「已通关」,
            // 否则显「可挑战」。修正旧 bug:二周目视图沿用首周目 clearedStageIds 全显
            // 「已通关」误导玩家以为本周目已打完。
            StageStatus statusFor(StageEntry e) {
              final c = cycleFor();
              if (c <= 1 || progress == null) return e.status;
              final clearedThisCycle = progress.clearedStageCycleKeys.contains(
                '${e.def.id}#$c',
              );
              return clearedThisCycle
                  ? StageStatus.cleared
                  : StageStatus.available;
            }

            // 主战角色当前境界（用于掉落传闻弹窗 above-realm 提示）。
            // 任一层 async 未就绪 → null（dialog 宽容 null，仅跳过超境提示）。
            final activeIds = ref
                .watch(activeCharacterIdsProvider)
                .maybeWhen(data: (ids) => ids, orElse: () => const <int>[]);
            final activeCharacters = <Character>[
              for (final id in activeIds)
                if (ref
                        .watch(characterByIdProvider(id))
                        .maybeWhen(data: (c) => c, orElse: () => null)
                    case final Character c)
                  c,
            ];
            final currentRealm = activeCharacters.isEmpty
                ? null
                : activeCharacters.first.realmTier;
            final currentGoal = NewSaveGoalGuidance.fromChapterEntries(
              chapterIndex: chapterIndex,
              entries: [
                for (final entry in entries)
                  (def: entry.def, status: statusFor(entry)),
              ],
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _StageJourneyMap(chapterIndex: chapterIndex, entries: entries),
                _ChapterFarmSpotsPanel(entries: entries),
                const SizedBox(height: 12),
                // 章级周目选择控件(整章已通才显)。置于扫荡按钮上方:先选周目、
                // 再扫荡,扫荡按钮随选定周目刷新标签与门槛。
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: CycleSelectControl(chapterKey: chapterKey),
                ),
                // 一键扫荡本章入口:本周目全关已通→醒目金按钮;未通→灰显+提示
                // (§5.7 灰掉,告知玩家需先手工通关该周目全部关卡)。
                _ChapterSweepButton(
                  chapterIndex: chapterIndex,
                  entries: entries,
                  eligible:
                      progress != null &&
                      SweepEligibility.forChapter(
                        clearedStageCycleKeys: progress.clearedStageCycleKeys,
                        cycle: cycleFor(),
                        chapterStageIds: [for (final e in entries) e.def.id],
                      ),
                  // 灰显门槛提示仅在本章至少通关过一次后出现;全新未通章仍隐藏
                  // (不在每章顶堆砌锁定按钮)。覆盖用户真实困惑:通过一次后切周目不能扫。
                  everCleared:
                      progress != null &&
                      MainlineProgressService.highestClearedCycleForChapter(
                            progress,
                            chapterKey,
                          ) >=
                          1,
                  cycle: cycleFor(),
                ),
                for (var i = 0; i < entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StageRow(
                      stageIndex: i + 1,
                      def: entries[i].def,
                      status: statusFor(entries[i]),
                      targetCycle: cycleFor(),
                      currentRealm: currentRealm,
                      activeCharacters: activeCharacters,
                      goalGuidance: currentGoal?.stage.id == entries[i].def.id
                          ? currentGoal
                          : null,
                      onTap: statusFor(entries[i]) == StageStatus.locked
                          ? null
                          : () => runStageFlow(
                              context: context,
                              ref: ref,
                              stage: entries[i].def,
                              targetCycle: cycleFor(),
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

class _ChapterFarmSpotsPanel extends StatelessWidget {
  const _ChapterFarmSpotsPanel({required this.entries});

  final List<StageEntry> entries;

  @override
  Widget build(BuildContext context) {
    final spots = MainlineChapterFarmSpotSelector.fromEntries(entries);
    if (spots.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: [
        UiStrings.chapterFarmSpotsTitle,
        for (final spot in spots)
          [
            UiStrings.chapterFarmSpotStage(spot.stageIndex),
            spot.stage.name,
            ...spot.route.kinds.map(_labelFor),
          ].join(' · '),
      ].join(' · '),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: WuxiaColors.panel.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: WuxiaColors.resultHighlight.withValues(alpha: 0.30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.travel_explore,
                  size: 15,
                  color: WuxiaColors.resultHighlight,
                ),
                SizedBox(width: 5),
                Text(
                  UiStrings.chapterFarmSpotsTitle,
                  style: TextStyle(
                    color: WuxiaColors.resultHighlight,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    UiStrings.chapterFarmSpotsHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: WuxiaColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final spot in spots) _ChapterFarmSpotChip(spot: spot),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterFarmSpotChip extends StatelessWidget {
  const _ChapterFarmSpotChip({required this.spot});

  final MainlineChapterFarmSpot spot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WuxiaColors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              UiStrings.chapterFarmSpotStage(spot.stageIndex),
              style: const TextStyle(
                color: WuxiaColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 128),
              child: Text(
                spot.stage.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WuxiaColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            for (final kind in spot.route.kinds) _ReplayRewardChip(kind: kind),
          ],
        ),
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
    required this.targetCycle,
    required this.onTap,
    this.currentRealm,
    this.activeCharacters = const [],
    this.goalGuidance,
  });

  final int stageIndex;
  final StageDef def;
  final StageStatus status;
  final int targetCycle;
  final VoidCallback? onTap;
  final RealmTier? currentRealm;
  final List<Character> activeCharacters;
  final NewSaveGoalGuidance? goalGuidance;

  @override
  Widget build(BuildContext context) {
    final locked = status == StageStatus.locked;
    final cleared = status == StageStatus.cleared;
    final available = status == StageStatus.available;
    final boss = def.isBossStage;
    final borderColor = cleared
        ? WuxiaColors.hpHigh
        : (locked ? WuxiaColors.border : WuxiaColors.resultHighlight);
    // 主线逐条门控(F2)：仅秘籍(item_scroll_*)首通必得，装备/材料每次胜利可掉，
    // 镜像 runtime shouldSkipScrollDrop。爬塔走 wholeChannel(见 tower 接入)。
    final rumor = DropRumorTable.fromDropTable(
      def.dropTable,
      gating: FirstClearGating.scrollOnly,
    );
    final cycleTraits = CycleTraitIntel.entriesFor(
      config: GameRepository.instance.numbers.cycleEvolution,
      cycle: targetCycle,
      isBoss: def.isBossStage,
      isTower: false,
    );
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 460;
                        final title = Row(
                          mainAxisSize: MainAxisSize.min,
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
                        );
                        final inlineLoot = InlineLootSummaryLine(
                          table: rumor,
                          recommendedRealm: def.requiredRealm,
                          alignment: compact
                              ? WrapAlignment.start
                              : WrapAlignment.end,
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const SizedBox(height: 3),
                              inlineLoot,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: title),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: inlineLoot,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleFor(def, status),
                      style: const TextStyle(
                        color: WuxiaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StagePreparationBar(
                      recommendedRealm: def.requiredRealm,
                      playerRealm: currentRealm,
                    ),
                    if (goalGuidance != null)
                      NewSaveGoalHintLine(guidance: goalGuidance!),
                    if (cycleTraits.isNotEmpty)
                      _CycleTraitSummaryLine(
                        cycle: targetCycle,
                        entries: cycleTraits,
                      ),
                    // 批二②:通关后战前可查 Boss 弱点/抗性(未通关 / 无配置 → shrink)。
                    WeaknessHintLine(
                      enemyTeam: def.enemyTeam,
                      cleared: cleared,
                    ),
                    if (cleared)
                      _ReplayRewardRouteLine(
                        route: MainlineReplayRewardRoute.fromStage(def),
                      ),
                    // 逐关「战斗方式」覆盖 chip 已移除(2026-06-26):全局「自动战斗」
                    // 开关在设置面板,逐关覆盖冗余且挤占列表。首通仍强制拖招,
                    // 重打按全局设置(resolveAutoPlayModeWithFirstClear override=null→globalDefault)。
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: UiStrings.prebattleIntelTitle,
                color: WuxiaColors.textMuted,
                onPressed: () => showStageIntelDialog(
                  context,
                  stage: def,
                  rumorTable: rumor,
                  currentRealm: currentRealm,
                  targetCycle: targetCycle,
                  activeCharacters: activeCharacters,
                  goalGuidance: goalGuidance,
                ),
              ),
              const SizedBox(width: 8),
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

class _CycleTraitSummaryLine extends StatelessWidget {
  const _CycleTraitSummaryLine({required this.cycle, required this.entries});

  final int cycle;
  final List<CycleTraitIntelEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: CycleTraitIntel.summaryLabel(cycle, entries),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_fix_high,
                  size: 13,
                  color: WuxiaColors.textMuted,
                ),
                const SizedBox(width: 3),
                Text(
                  UiStrings.cycleNthLabel(cycle),
                  style: const TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            for (final entry in entries) _CycleTraitChip(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _CycleTraitChip extends StatelessWidget {
  const _CycleTraitChip({required this.entry});

  final CycleTraitIntelEntry entry;

  @override
  Widget build(BuildContext context) {
    return GlossaryTip(
      definition: entry.detailText,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WuxiaColors.internalForce.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: WuxiaColors.internalForce.withValues(alpha: 0.42),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            '${entry.name} · ${entry.shortText}',
            style: const TextStyle(
              color: WuxiaColors.internalForce,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _StagePreparationBar extends StatelessWidget {
  const _StagePreparationBar({
    required this.recommendedRealm,
    required this.playerRealm,
  });

  final RealmTier recommendedRealm;
  final RealmTier? playerRealm;

  @override
  Widget build(BuildContext context) {
    final summary = StagePreparationSummary.assess(
      recommended: recommendedRealm,
      playerTier: playerRealm,
    );
    final verdict = summary.verdict;
    final (verdictLabel, verdictColor) = verdict == null
        ? ('', WuxiaColors.textMuted)
        : difficultyLabelColor(verdict);
    final actionText = _actionText(summary);

    return Semantics(
      label: [
        UiStrings.stagePrepareLabel,
        UiStrings.stagePrepareRecommended(EnumL10n.realmTier(recommendedRealm)),
        if (verdictLabel.isNotEmpty) verdictLabel,
        actionText,
      ].join(' · '),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: WuxiaColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: WuxiaColors.textMuted,
                ),
                SizedBox(width: 3),
                Text(UiStrings.stagePrepareLabel),
              ],
            ),
            Text(
              UiStrings.stagePrepareRecommended(
                EnumL10n.realmTier(recommendedRealm),
              ),
            ),
            if (verdictLabel.isNotEmpty)
              Text(verdictLabel, style: TextStyle(color: verdictColor)),
            Text(
              actionText,
              style: TextStyle(
                color: _actionColor(summary),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _actionText(StagePreparationSummary summary) {
    return switch (summary.focus) {
      StagePreparationFocus.ready =>
        summary.realmGap < 0
            ? UiStrings.stagePrepareSteady
            : UiStrings.stagePrepareReady,
      StagePreparationFocus.polishLoadout => UiStrings.stagePrepareLoadoutGap(
        summary.realmGap,
      ),
      StagePreparationFocus.realmBreakthrough => UiStrings.stagePrepareRealmGap(
        summary.realmGap,
      ),
      StagePreparationFocus.assignCharacter =>
        UiStrings.stagePrepareAssignCharacter,
    };
  }

  Color _actionColor(StagePreparationSummary summary) {
    return switch (summary.focus) {
      StagePreparationFocus.ready => WuxiaColors.hpHigh,
      StagePreparationFocus.polishLoadout => WuxiaColors.resultHighlight,
      StagePreparationFocus.realmBreakthrough => WuxiaColors.hpLow,
      StagePreparationFocus.assignCharacter => WuxiaColors.textMuted,
    };
  }
}

class _ReplayRewardRouteLine extends StatelessWidget {
  const _ReplayRewardRouteLine({required this.route});

  final MainlineReplayRewardRoute route;

  @override
  Widget build(BuildContext context) {
    if (route.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: [
        UiStrings.stageReplayRouteTitle,
        ...route.kinds.map(_labelFor),
      ].join(' · '),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.replay_circle_filled_outlined,
                  size: 13,
                  color: WuxiaColors.textMuted,
                ),
                SizedBox(width: 3),
                Text(
                  UiStrings.stageReplayRouteTitle,
                  style: TextStyle(
                    color: WuxiaColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            for (final kind in route.kinds) _ReplayRewardChip(kind: kind),
          ],
        ),
      ),
    );
  }
}

class _ReplayRewardChip extends StatelessWidget {
  const _ReplayRewardChip({required this.kind});

  final MainlineReplayRewardKind kind;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(kind);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          _labelFor(kind),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

String _labelFor(MainlineReplayRewardKind kind) {
  return switch (kind) {
    MainlineReplayRewardKind.equipment => UiStrings.stageReplayRouteEquipment,
    MainlineReplayRewardKind.material => UiStrings.stageReplayRouteMaterial,
    MainlineReplayRewardKind.proficiency =>
      UiStrings.stageReplayRouteProficiency,
  };
}

Color _colorFor(MainlineReplayRewardKind kind) {
  return switch (kind) {
    MainlineReplayRewardKind.equipment => WuxiaColors.resultHighlight,
    MainlineReplayRewardKind.material => WuxiaColors.internalForce,
    MainlineReplayRewardKind.proficiency => WuxiaColors.lingQiao,
  };
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

/// 一键扫荡本章入口（醒目主按钮）。本周目全关已通 → 高亮可点；否则灰显 + 门槛提示。
class _ChapterSweepButton extends StatelessWidget {
  const _ChapterSweepButton({
    required this.chapterIndex,
    required this.entries,
    required this.eligible,
    required this.everCleared,
    required this.cycle,
  });

  final int chapterIndex;
  final List<StageEntry> entries;
  final bool eligible;

  /// 本章是否至少通关过一次（任一周目）。false 且未达门槛 → 整块隐藏。
  final bool everCleared;
  final int cycle;

  @override
  Widget build(BuildContext context) {
    // 从未通过本章 → 不显（避免在每章顶堆砌锁定按钮，保持全新章干净）。
    if (!eligible && !everCleared) return const SizedBox.shrink();
    // §5.7：通关过、但当前选定周目未全手工通关 → 灰显 + 提示（不再整块隐藏），
    // 让玩家知道扫的是哪个周目、以及为何还不能扫（需先手工通关该周目全部关卡）。
    if (!eligible) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
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
          label: Text(UiStrings.sweepLockedHintCycle(cycle)),
        ),
      );
    }
    final preview = GameRepository.isLoaded
        ? SweepRewardPreview.fromMainlineStages(
            stages: entries.map((e) => e.def),
            repo: GameRepository.instance,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (preview != null && !preview.isEmpty)
          _SweepRewardPreviewPanel(preview: preview),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: WuxiaColors.bossFrame,
              foregroundColor: WuxiaColors.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              final units = [
                for (final e in entries)
                  MainlineSweepUnit(stage: e.def, cycle: cycle),
              ];
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => SweepScreen(
                    units: units,
                    unitName: UiStrings.chapterTitle(chapterIndex),
                    cycle: cycle,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.fast_forward, size: 22),
            label: Text(UiStrings.sweepChapterButtonCycle(cycle)),
          ),
        ),
      ],
    );
  }
}

class _SweepRewardPreviewPanel extends StatelessWidget {
  const _SweepRewardPreviewPanel({required this.preview});

  final SweepRewardPreview preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WuxiaColors.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WuxiaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            UiStrings.sweepPreviewTitle,
            style: TextStyle(
              color: WuxiaColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (preview.primaryKinds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final kind in preview.primaryKinds)
                  _SweepPreviewChip(label: _labelFor(kind)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _PreviewLine(
            text: UiStrings.sweepPreviewLine(
              UiStrings.sweepPreviewDropsPrefix,
              _dropSummary(preview),
            ),
          ),
          if (preview.proficiencyHints.isNotEmpty)
            _PreviewLine(
              text: UiStrings.sweepPreviewLine(
                UiStrings.sweepPreviewProficiencyPrefix,
                preview.proficiencyHints.map(_proficiencyHintLabel).join(' / '),
              ),
            ),
          _PreviewLine(
            text: UiStrings.sweepPreviewLine(
              UiStrings.sweepPreviewMaterialHitsPrefix,
              _materialHitSummary(preview.materialHits),
            ),
          ),
        ],
      ),
    );
  }
}

class _SweepPreviewChip extends StatelessWidget {
  const _SweepPreviewChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: WuxiaColors.resultHighlight.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: WuxiaColors.resultHighlight.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: WuxiaColors.resultHighlight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(color: WuxiaColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

String _dropSummary(SweepRewardPreview preview) {
  final parts = <String>[
    if (preview.equipmentDropCount > 0)
      UiStrings.sweepPreviewEquipmentDrops(preview.equipmentDropCount),
    ..._limited(preview.possibleItemNames),
  ];
  return parts.isEmpty ? UiStrings.sweepPreviewNoDrops : parts.join(' / ');
}

String _materialHitSummary(List<SweepMaterialHit> hits) {
  if (hits.isEmpty) return UiStrings.sweepPreviewNoMaterialHits;
  return _limited(
    hits.map((hit) {
      return UiStrings.sweepPreviewMaterialHit(
        hit.itemName,
        UiStrings.materialUsageSummary(hit.usages),
      );
    }),
  ).join(' / ');
}

Iterable<String> _limited(Iterable<String> values, {int max = 3}) sync* {
  var emitted = 0;
  final iterator = values.iterator;
  while (emitted < max && iterator.moveNext()) {
    emitted++;
    yield iterator.current;
  }
  var rest = 0;
  while (iterator.moveNext()) {
    rest++;
  }
  if (rest > 0) yield UiStrings.sweepPreviewMore(rest);
}

String _proficiencyHintLabel(SweepProficiencyHint hint) {
  return switch (hint) {
    SweepProficiencyHint.skillManual => UiStrings.sweepPreviewSkillManual,
    SweepProficiencyHint.skillFragment => UiStrings.sweepPreviewSkillFragment,
    SweepProficiencyHint.chargeSkill => UiStrings.sweepPreviewChargeSkill,
  };
}
