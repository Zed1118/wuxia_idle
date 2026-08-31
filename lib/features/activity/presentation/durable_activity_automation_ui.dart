import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/stage_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../../light_foot/application/light_foot_participant_service.dart';
import '../../mass_battle/application/mass_battle_participant_service.dart';
import '../application/durable_activity_automation_coordinator.dart';
import '../application/durable_activity_automation_providers.dart';
import '../domain/durable_activity_automation_policy.dart';
import '../domain/durable_activity_combat_run.dart';

Future<void> startDurableActivityAutomation({
  required BuildContext context,
  required WidgetRef ref,
  required DurableActivityKind kind,
  required StageDef stage,
  required int cycleIndex,
  required int participantId,
  Formation? formation,
}) async {
  final service = ref.read(durableActivityAutomationServiceProvider);
  if (service == null) {
    _showUnavailable(context);
    return;
  }
  final request = ActivityParticipationRequest(
    contentId: stage.id,
    contentKind: switch (kind) {
      DurableActivityKind.lightFoot => ActivityContentKind.lightFoot,
      DurableActivityKind.massBattle => ActivityContentKind.massBattle,
    },
    characterId: participantId,
    loadoutPlanId: durableActivityLoadoutPlanId(
      kind: kind,
      stageId: stage.id,
      characterId: participantId,
    ),
    participation: ActivityParticipationMode.dispatch,
    controller: ActivityController.playerBot,
    clock: ActivityClock.headless,
    entryKind: ActivityEntryKind.offlineResume,
  );
  try {
    final runId = await service.start(
      kind: kind,
      stage: stage,
      cycleIndex: cycleIndex,
      request: request,
      formation: formation,
    );
    ref.invalidate(durableActivityRunProvider(kind));
    ref.invalidate(lightFootParticipantCandidatesProvider);
    ref.invalidate(massBattleParticipantCandidatesProvider);
    if (!context.mounted) return;
    await resumeDurableActivityAutomation(
      context: context,
      ref: ref,
      stage: stage,
      runId: runId,
    );
  } catch (_) {
    if (context.mounted) _showUnavailable(context);
  }
}

Future<void> resumeDurableActivityAutomation({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
  required int runId,
}) async {
  final service = ref.read(durableActivityAutomationServiceProvider);
  if (service == null) {
    _showUnavailable(context);
    return;
  }
  try {
    var run = await service.runById(runId);
    if (run == null) throw StateError('Durable activity run disappeared');
    if (run.phase == DurableActivityPhase.active) {
      final result = await executeDurableActivityAutomation(
        ref: ref,
        stage: stage,
        runId: runId,
      );
      if (result.outcome == DurableActivityExecutionOutcome.timeout) {
        // 在途 run 保持可恢复；列表卡片继续提供“继续”入口。
        return;
      }
      run = result.run;
    }
    if (run.phase != DurableActivityPhase.settlementApplied ||
        !context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(UiStrings.stageVictoryReportTitle),
        content: Text(
          [
            stage.name,
            UiStrings.stageReportParticipant(run!.participantName),
            run.outcome == DurableActivityOutcome.victory
                ? UiStrings.mainlineNarrativeVictoryLabel
                : UiStrings.mainlineNarrativeDefeatLabel,
          ].join(UiStrings.offlineRecapDetailSeparator),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(UiStrings.stageVictoryConfirm),
          ),
        ],
      ),
    );
    await service.close(runId: run.id);
    ref.invalidate(durableActivityRunProvider(run.kind));
    ref.invalidate(lightFootParticipantCandidatesProvider);
    ref.invalidate(massBattleParticipantCandidatesProvider);
  } catch (_) {
    if (context.mounted) _showUnavailable(context);
  }
}

void _showUnavailable(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(UiStrings.discipleSchedulingUnavailable)),
  );
}

class DurableActivityRunCard extends StatelessWidget {
  const DurableActivityRunCard({
    super.key,
    required this.run,
    required this.stageName,
    required this.onPressed,
  });

  final DurableActivityCombatRun run;
  final String stageName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final settled = run.phase == DurableActivityPhase.settlementApplied;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: WuxiaColors.sidebar,
        border: Border.all(color: WuxiaColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              [
                stageName,
                UiStrings.stageReportParticipant(run.participantName),
                settled
                    ? UiStrings.stageVictoryReportTitle
                    : UiStrings.expeditionActiveSection,
              ].join(UiStrings.offlineRecapDetailSeparator),
              style: const TextStyle(
                color: WuxiaColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: Text(
              settled
                  ? UiStrings.stageVictoryReportTitle
                  : UiStrings.battleResume,
            ),
          ),
        ],
      ),
    );
  }
}
