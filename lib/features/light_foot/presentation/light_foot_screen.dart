import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../combat_shared/application/selected_cycle_provider.dart';
import '../../../shared/battle_shared/enum_localizations.dart' show EnumL10n;
import '../../../shared/widgets/cycle_select_control.dart';
import '../../mainline/application/mainline_providers.dart';
import '../../mainline/presentation/stage_entry_flow.dart';
import '../../activity/application/durable_activity_automation_providers.dart';
import '../../activity/domain/durable_activity_automation_policy.dart';
import '../../activity/domain/durable_activity_combat_run.dart';
import '../../activity/presentation/durable_activity_automation_ui.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../../settings/application/gameplay_settings_provider.dart';
import '../application/light_foot_service.dart';
import '../application/light_foot_participant_service.dart';
import 'light_foot_participant_picker.dart';
import '../../../shared/widgets/wuxia_ui/ink_loading.dart';

/// 轻功试炼 stage list 屏(1.0 P3.1 §12.3,Batch B.3 reactive 三态)。
///
/// 5 轻功关(stage_light_foot_01..05,水面/屋脊/竹海/险崖/长风)按 unlock 链显:
///   - cleared(已通):右侧 ✓ 标识,可重入
///   - available(可挑战):主色显,点击走 [runStageFlow]
///   - locked(未解锁):灰显 + 锁图标,点击 disabled
///
/// **三态判定**(委派 [LightFootService.statusOf]):
///   - stage_06_05 是 light_foot_01 的 prev(Ch6 末关 victory → 自动解 _01)
///   - _01 victory → _02 解;_02 victory → _03 解;... 链式 5 关
///
/// **不接管 wuSheng 突破链**(平行支线 · 沿 inner_demon_screen 体例但不嵌
/// isLayerLocked 路径)。
typedef LightFootStageRunner =
    Future<void> Function({
      required BuildContext context,
      required WidgetRef ref,
      required StageDef stage,
      required int targetCycle,
      required CombatantSnapshot participantSnapshot,
      required ActivityController controller,
    });

typedef LightFootParticipantSnapshotResolver =
    Future<CombatantSnapshot> Function(int requestedParticipantId);

class LightFootScreen extends ConsumerWidget {
  const LightFootScreen({
    super.key,
    this.stageRunnerForTest,
    this.participantSnapshotResolverForTest,
  });

  final LightFootStageRunner? stageRunnerForTest;
  final LightFootParticipantSnapshotResolver?
  participantSnapshotResolverForTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages =
        GameRepository.instance.stageDefs.values
            .where((s) => s.stageType == StageType.lightFoot)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final lightFootDef = GameRepository.instance.numbers.lightFoot;
    final async = ref.watch(mainlineProgressProvider);
    final automationAsync = ref.watch(
      durableActivityRunProvider(DurableActivityKind.lightFoot),
    );

    return Scaffold(
      backgroundColor: WuxiaColors.background,
      appBar: AppBar(
        title: const Text(UiStrings.lightFootScreenTitle),
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
          data: (progress) {
            if (stages.isEmpty) {
              return const Center(
                child: Text(
                  UiStrings.lightFootEmpty,
                  style: TextStyle(color: WuxiaColors.textMuted),
                ),
              );
            }
            final cleared = progress.clearedStageIds.toSet();
            final automationRun = automationAsync.value;
            // 周目按章(Phase 2):整个轻功副本视为一章,chapterKey=stageType.name。
            const chapterKey = 'lightFoot';
            int cycleFor() => resolveTargetCycle(
              ref.read(selectedChallengeCycleForCurrentSlot(chapterKey)),
              progress,
              chapterKey,
            );
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: CycleSelectControl(chapterKey: chapterKey),
                ),
                if (automationRun != null)
                  DurableActivityRunCard(
                    run: automationRun,
                    stageName:
                        GameRepository
                            .instance
                            .stageDefs[automationRun.stageId]
                            ?.name ??
                        automationRun.stageId,
                    onPressed: () {
                      final runStage = GameRepository
                          .instance
                          .stageDefs[automationRun.stageId];
                      if (runStage == null) return;
                      resumeDurableActivityAutomation(
                        context: context,
                        ref: ref,
                        stage: runStage,
                        runId: automationRun.id,
                      );
                    },
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: stages.length,
                    itemBuilder: (ctx, i) {
                      final s = stages[i];
                      final status = LightFootService.statusOf(
                        stageId: s.id,
                        config: lightFootDef,
                        clearedStageIds: cleared,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LightFootRow(
                          def: s,
                          status: status,
                          onHeadlessReplay:
                              status == LightFootStageStatus.cleared &&
                                  automationAsync.hasValue &&
                                  automationRun == null
                              ? () async {
                                  final participantId =
                                      await selectLightFootParticipant(
                                        context: context,
                                        ref: ref,
                                      );
                                  if (participantId == null ||
                                      !context.mounted) {
                                    return;
                                  }
                                  await startDurableActivityAutomation(
                                    context: context,
                                    ref: ref,
                                    kind: DurableActivityKind.lightFoot,
                                    stage: s,
                                    cycleIndex: cycleFor(),
                                    participantId: participantId,
                                    mode: DurableActivityAutomationMode
                                        .headlessReplay,
                                  );
                                }
                              : null,
                          onDispatch:
                              status == LightFootStageStatus.cleared &&
                                  automationAsync.hasValue &&
                                  automationRun == null
                              ? () async {
                                  final participantId =
                                      await selectLightFootParticipant(
                                        context: context,
                                        ref: ref,
                                      );
                                  if (participantId == null ||
                                      !context.mounted) {
                                    return;
                                  }
                                  await startDurableActivityAutomation(
                                    context: context,
                                    ref: ref,
                                    kind: DurableActivityKind.lightFoot,
                                    stage: s,
                                    cycleIndex: cycleFor(),
                                    participantId: participantId,
                                  );
                                }
                              : null,
                          onTap: status == LightFootStageStatus.locked
                              ? null
                              : () async {
                                  var controller = ActivityController.human;
                                  if (status == LightFootStageStatus.cleared) {
                                    try {
                                      final settings = await ref.read(
                                        gameplaySettingsProvider.future,
                                      );
                                      if (settings.autoPlayDefault) {
                                        controller =
                                            ActivityController.playerBot;
                                      }
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              UiStrings
                                                  .discipleSchedulingUnavailable,
                                            ),
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  }
                                  if (!context.mounted) return;
                                  await runLightFootChallenge(
                                    context: context,
                                    ref: ref,
                                    stage: s,
                                    targetCycle: cycleFor(),
                                    controller: controller,
                                    stageRunner: stageRunnerForTest,
                                    participantSnapshotResolver:
                                        participantSnapshotResolverForTest,
                                  );
                                },
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

/// 每次路线挑战都先选择参与者，再以 exact snapshot 进入共享生产流程。
Future<void> runLightFootChallenge({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
  required int targetCycle,
  ActivityController controller = ActivityController.human,
  LightFootStageRunner? stageRunner,
  LightFootParticipantSnapshotResolver? participantSnapshotResolver,
}) async {
  final participantId = await selectLightFootParticipant(
    context: context,
    ref: ref,
  );
  if (participantId == null || !context.mounted) return;

  late final CombatantSnapshot participantSnapshot;
  try {
    if (controller == ActivityController.playerBot) {
      final progress = await ref.read(mainlineProgressProvider.future);
      DurableActivityAutomationPolicy.requireAllowed(
        kind: DurableActivityKind.lightFoot,
        stage: stage,
        request: durableActivityAutomationRequest(
          kind: DurableActivityKind.lightFoot,
          stageId: stage.id,
          characterId: participantId,
          mode: DurableActivityAutomationMode.visibleReplay,
        ),
        alreadyCleared: progress.clearedStageIds.contains(stage.id),
        formation: null,
      );
    }
    participantSnapshot = participantSnapshotResolver == null
        ? await resolveLightFootParticipantSnapshot(
            isar: IsarSetup.instance,
            requestedParticipantId: participantId,
          )
        : await participantSnapshotResolver(participantId);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(UiStrings.lightFootParticipantUnavailable),
        ),
      );
    }
    return;
  }
  if (!context.mounted) return;
  await (stageRunner ?? runLightFootStageFlow)(
    context: context,
    ref: ref,
    stage: stage,
    targetCycle: targetCycle,
    participantSnapshot: participantSnapshot,
    controller: controller,
  );
}

Future<void> runLightFootStageFlow({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
  required int targetCycle,
  required CombatantSnapshot participantSnapshot,
  ActivityController controller = ActivityController.human,
}) => runStageFlow(
  context: context,
  ref: ref,
  stage: stage,
  targetCycle: targetCycle,
  directParticipantSnapshot: participantSnapshot,
  directParticipantController: controller,
);

class _LightFootRow extends StatelessWidget {
  const _LightFootRow({
    required this.def,
    required this.status,
    required this.onTap,
    required this.onHeadlessReplay,
    required this.onDispatch,
  });

  final StageDef def;
  final LightFootStageStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onHeadlessReplay;
  final VoidCallback? onDispatch;

  @override
  Widget build(BuildContext context) {
    final locked = status == LightFootStageStatus.locked;
    final cleared = status == LightFootStageStatus.cleared;
    final titleColor = locked ? WuxiaColors.textMuted : WuxiaColors.textPrimary;
    final borderColor = cleared ? WuxiaColors.hpHigh : WuxiaColors.border;
    final terrainLabel = EnumL10n.terrainBiome(def.terrainBiome);
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        UiStrings.lightFootStageInfo(
                          terrainLabel,
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
                if (onHeadlessReplay != null)
                  IconButton(
                    tooltip: UiStrings.mainlineHeadlessReplayMode,
                    onPressed: onHeadlessReplay,
                    icon: const Icon(
                      Icons.fast_forward_outlined,
                      color: WuxiaColors.textPrimary,
                    ),
                  ),
                if (onDispatch != null)
                  IconButton(
                    tooltip: UiStrings.expeditionDispatchTeamSection,
                    onPressed: onDispatch,
                    icon: const Icon(
                      Icons.schedule_send_outlined,
                      color: WuxiaColors.textPrimary,
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
  final LightFootStageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LightFootStageStatus.cleared:
        return const Icon(
          Icons.check_circle,
          size: 20,
          color: WuxiaColors.hpHigh,
        );
      case LightFootStageStatus.available:
        return const Icon(
          Icons.chevron_right,
          size: 20,
          color: WuxiaColors.textMuted,
        );
      case LightFootStageStatus.locked:
        return const Icon(
          Icons.lock_outline,
          size: 20,
          color: WuxiaColors.textMuted,
        );
    }
  }
}
