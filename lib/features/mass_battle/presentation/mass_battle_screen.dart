import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../battle/application/selected_cycle_provider.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../battle/presentation/cycle_select_control.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mainline/presentation/stage_entry_flow.dart';
import '../application/mass_battle_service.dart';

/// 群战守城 stage list 屏(1.0 P3.2 §12.3,Batch 2.4 reactive 三态)。
///
/// 5 守城关(stage_mass_battle_01..05,守村/守镇/守县/守关/守城)按 unlock 链显:
///   - cleared(已通):右侧 ✓ 标识,可重入
///   - available(可挑战):主色显,点击走 [runStageFlow]
///   - locked(未解锁):灰显 + 锁图标,点击 disabled
///
/// **三态判定**(委派 [MassBattleService.statusOf]):
///   - stage_06_05 是 mass_battle_01 的 prev(Ch6 末关 victory → 自动解 _01)
///   - _01 victory → _02 解;_02 victory → _03 解;... 链式 5 关
///
/// **不接管 wuSheng 突破链**(平行支线 · 沿 light_foot_screen 体例)。
///
/// **额外信息**(与 LightFoot 关键差异):每关显 wave / 敌数 + 默认阵型,玩家可
/// 一眼看清「守 N 波 × M 敌 / 阵型 X」(stage list 紧凑视图;阵型选择 dialog
/// 留 Batch 2.4 末段 + 2.5 wiring)。
class MassBattleScreen extends ConsumerWidget {
  const MassBattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = GameRepository.instance.stageDefs.values
        .where((s) => s.stageType == StageType.massBattle)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final massBattleDef = GameRepository.instance.numbers.massBattle;
    final async = ref.watch(mainlineProgressProvider);

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.massBattleScreenTitle),
        backgroundColor: WuxiaColors.sidebar,
        foregroundColor: WuxiaColors.textPrimary,
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SelectableText(
              UiStrings.loadFailed(e),
              style: const TextStyle(color: WuxiaColors.hpLow),
            ),
          ),
          data: (progress) {
            if (stages.isEmpty) {
              return const Center(
                child: Text(
                  UiStrings.massBattleEmpty,
                  style: TextStyle(color: WuxiaColors.textMuted),
                ),
              );
            }
            final cleared = progress.clearedStageIds.toSet();
            // 周目按章(Phase 2):整个群战副本视为一章,chapterKey=stageType.name。
            const chapterKey = 'massBattle';
            int cycleFor() => resolveTargetCycle(
                  ref.read(selectedChallengeCycleProvider(chapterKey)),
                  progress,
                  chapterKey,
                );
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: CycleSelectControl(chapterKey: chapterKey),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: stages.length,
                    itemBuilder: (ctx, i) {
                      final s = stages[i];
                      final status = MassBattleService.statusOf(
                        stageId: s.id,
                        config: massBattleDef,
                        clearedStageIds: cleared,
                      );
                      final formation = MassBattleService.formationFor(
                        stageId: s.id,
                        config: massBattleDef,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MassBattleRow(
                          def: s,
                          status: status,
                          formation: formation,
                          onTap: status == MassBattleStageStatus.locked
                              ? null
                              : () => runStageFlow(
                                    context: context,
                                    ref: ref,
                                    stage: s,
                                    targetCycle: cycleFor(),
                                  ),
                        ),
                      );
                    },
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

class _MassBattleRow extends StatelessWidget {
  const _MassBattleRow({
    required this.def,
    required this.status,
    required this.formation,
    required this.onTap,
  });

  final StageDef def;
  final MassBattleStageStatus status;
  final Formation formation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = status == MassBattleStageStatus.locked;
    final cleared = status == MassBattleStageStatus.cleared;
    final titleColor =
        locked ? WuxiaColors.textMuted : WuxiaColors.textPrimary;
    final borderColor =
        cleared ? WuxiaColors.hpHigh : WuxiaColors.border;
    final waveCount = def.massBattleWaveCount ?? 0;
    final enemyCounts = def.massBattleEnemyCounts ?? const <int>[];
    final enemyTotal =
        enemyCounts.fold<int>(0, (sum, n) => sum + n);
    final formationLabel = EnumL10n.formation(formation);
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
                        UiStrings.massBattleStageInfo(
                          waveCount,
                          enemyTotal,
                          formationLabel,
                          def.difficultyMultiplier.toStringAsFixed(1),
                        ),
                        style: const TextStyle(
                          color: WuxiaColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      // 逐关「战斗方式」覆盖 chip 已移除(2026-06-26):全局
                      // 「自动战斗」开关在设置面板,逐关覆盖冗余且挤占列表。
                      // 与主线/爬塔一致(commit 9231e4ae)。周目选择上移到章层。
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
  final MassBattleStageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MassBattleStageStatus.cleared:
        return const Icon(Icons.check_circle,
            size: 20, color: WuxiaColors.hpHigh);
      case MassBattleStageStatus.available:
        return const Icon(Icons.chevron_right,
            size: 20, color: WuxiaColors.textMuted);
      case MassBattleStageStatus.locked:
        return const Icon(Icons.lock_outline,
            size: 20, color: WuxiaColors.textMuted);
    }
  }
}
