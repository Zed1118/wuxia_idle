import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/tower_floor_def.dart';
import '../../../shared/strings.dart';
import '../../activity/application/durable_activity_automation_coordinator.dart';
import '../../activity/application/durable_activity_automation_providers.dart';
import '../../activity/domain/durable_activity_combat_run.dart';
import '../../combat_shared/application/post_combat_invalidation.dart';
import '../application/tower_providers.dart';
import '../domain/tower_automation_policy.dart';

Future<void> startTowerDurableDispatch({
  required BuildContext context,
  required WidgetRef ref,
  required TowerFloorDef floor,
  required int cycleIndex,
  required int participantId,
}) async {
  final service = ref.read(durableActivityAutomationServiceProvider);
  if (service == null) {
    _showUnavailable(context);
    return;
  }
  final request = towerDurableDispatchRequest(
    floorIndex: floor.floorIndex,
    characterId: participantId,
  );
  try {
    final runId = await service.startTower(
      floor: floor,
      cycleIndex: cycleIndex,
      request: request,
    );
    ref.invalidate(durableActivityRunProvider(DurableActivityKind.tower));
    ref.invalidate(towerParticipantCandidatesProvider);
    if (!context.mounted) return;
    await resumeTowerDurableDispatch(
      context: context,
      ref: ref,
      floor: floor,
      runId: runId,
    );
  } catch (_) {
    if (context.mounted) _showUnavailable(context);
  }
}

Future<void> resumeTowerDurableDispatch({
  required BuildContext context,
  required WidgetRef ref,
  required TowerFloorDef floor,
  required int runId,
}) async {
  final service = ref.read(durableActivityAutomationServiceProvider);
  if (service == null) {
    _showUnavailable(context);
    return;
  }
  try {
    var run = await service.runById(runId);
    if (run == null || run.kind != DurableActivityKind.tower) {
      throw StateError('Tower durable run disappeared');
    }
    if (run.phase == DurableActivityPhase.active) {
      final result = await executeTowerDurableActivityAutomation(
        ref: ref,
        floor: floor,
        runId: runId,
      );
      invalidateAfterCombatSettlement(ref.invalidate);
      ref.invalidate(towerProgressProvider);
      ref.invalidate(durableActivityRunProvider(DurableActivityKind.tower));
      ref.invalidate(towerParticipantCandidatesProvider);
      if (result.outcome == DurableActivityExecutionOutcome.timeout) return;
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
            UiStrings.towerFloorLabel(floor.floorIndex),
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
    ref.invalidate(durableActivityRunProvider(DurableActivityKind.tower));
    ref.invalidate(towerParticipantCandidatesProvider);
  } catch (_) {
    if (context.mounted) _showUnavailable(context);
  }
}

void _showUnavailable(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(UiStrings.discipleSchedulingUnavailable)),
  );
}
