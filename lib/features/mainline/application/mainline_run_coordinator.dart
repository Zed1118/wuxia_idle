import '../../../data/defs/stage_def.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../domain/mainline_run.dart';

enum MainlineStageFlowDecision {
  stoppedBeforeVictory,
  returnToMapAfterVictory,
  enterNextStage,
}

enum MainlineRunCompletionReason {
  stageFlowStopped,
  chapterCompleted,
  participantNotBattleEligibleForNextStage,
}

final class MainlineRunStageLaunch {
  const MainlineRunStageLaunch({
    required this.stage,
    required this.run,
    required this.playerSnapshot,
  });

  final StageDef stage;
  final MainlineRun run;
  final CombatantSnapshot playerSnapshot;
}

final class PreparedMainlineLoadoutSnapshot {
  PreparedMainlineLoadoutSnapshot({
    required this.playerSnapshot,
    required String loadoutSnapshotId,
  }) : loadoutSnapshotId = loadoutSnapshotId.trim() {
    if (this.loadoutSnapshotId.isEmpty) {
      throw ArgumentError.value(
        loadoutSnapshotId,
        'loadoutSnapshotId',
        'must not be empty',
      );
    }
  }

  final CombatantSnapshot playerSnapshot;
  final String loadoutSnapshotId;
}

final class MainlineRunCoordinatorResult {
  const MainlineRunCoordinatorResult({
    required this.run,
    required this.reason,
    required this.completedStageIds,
  });

  final MainlineRun run;
  final MainlineRunCompletionReason reason;
  final List<String> completedStageIds;
}

typedef MainlineStageFlowExecutor =
    Future<MainlineStageFlowDecision> Function(MainlineRunStageLaunch launch);
typedef MainlineNextStageResolver = StageDef? Function(StageDef currentStage);
typedef MainlineNextLoadoutSnapshotLoader =
    Future<PreparedMainlineLoadoutSnapshot?> Function({
      required MainlineRun run,
      required StageDef nextStage,
    });

/// 第一章首次推进的外层非递归协调器。
///
/// 战斗、结算和 UI 仍由 caller 的 [executeStage] 负责；只有 caller 在完整
/// 成功后返回 [MainlineStageFlowDecision.enterNextStage]，本类才准备下一关。
final class MainlineRunCoordinator {
  const MainlineRunCoordinator({
    required this.executeStage,
    required this.nextStageOf,
    required this.loadNextSnapshot,
  });

  final MainlineStageFlowExecutor executeStage;
  final MainlineNextStageResolver nextStageOf;
  final MainlineNextLoadoutSnapshotLoader loadNextSnapshot;

  Future<MainlineRunCoordinatorResult> run({
    required StageDef initialStage,
    required MainlineRun initialRun,
    required CombatantSnapshot initialPlayerSnapshot,
  }) async {
    if (initialRun.currentStageId != initialStage.id) {
      throw StateError('Mainline run initial stage does not match');
    }
    if (initialRun.participantId != initialPlayerSnapshot.characterId) {
      throw StateError('Mainline run initial participant does not match');
    }

    var stage = initialStage;
    var currentRun = initialRun;
    var playerSnapshot = initialPlayerSnapshot;
    final completedStageIds = <String>[];

    while (true) {
      final decision = await executeStage(
        MainlineRunStageLaunch(
          stage: stage,
          run: currentRun,
          playerSnapshot: playerSnapshot,
        ),
      );
      if (decision == MainlineStageFlowDecision.stoppedBeforeVictory) {
        return MainlineRunCoordinatorResult(
          run: currentRun,
          reason: MainlineRunCompletionReason.stageFlowStopped,
          completedStageIds: List.unmodifiable(completedStageIds),
        );
      }

      completedStageIds.add(stage.id);
      if (decision == MainlineStageFlowDecision.returnToMapAfterVictory) {
        return MainlineRunCoordinatorResult(
          run: currentRun,
          reason: MainlineRunCompletionReason.stageFlowStopped,
          completedStageIds: List.unmodifiable(completedStageIds),
        );
      }

      final nextStage = nextStageOf(stage);
      if (nextStage == null) {
        return MainlineRunCoordinatorResult(
          run: currentRun,
          reason: MainlineRunCompletionReason.chapterCompleted,
          completedStageIds: List.unmodifiable(completedStageIds),
        );
      }
      final prepared = await loadNextSnapshot(
        run: currentRun,
        nextStage: nextStage,
      );
      if (prepared == null) {
        return MainlineRunCoordinatorResult(
          run: currentRun,
          reason: MainlineRunCompletionReason
              .participantNotBattleEligibleForNextStage,
          completedStageIds: List.unmodifiable(completedStageIds),
        );
      }
      if (prepared.playerSnapshot.characterId != currentRun.participantId) {
        throw StateError('Mainline next-stage participant does not match');
      }
      currentRun = currentRun.proceedToNext(
        stageId: nextStage.id,
        loadoutSnapshotId: prepared.loadoutSnapshotId,
        participantBattleEligibleForNextStage: true,
      );
      stage = nextStage;
      playerSnapshot = prepared.playerSnapshot;
    }
  }
}
