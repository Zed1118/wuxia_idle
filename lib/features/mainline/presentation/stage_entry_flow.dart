import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../data/defs/stage_def.dart';
import '../../../data/defs/encounter_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/encounter_event_loader.dart';
import '../../../data/isar_setup.dart';
import '../../../core/application/system_clock_provider.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/narrative_loader.dart';
import '../../../shared/utils/math_random.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../combat_shared/application/combat_content_providers.dart';
import '../../combat_shared/application/post_combat_invalidation.dart';
import '../../mass_battle/application/mass_battle_service.dart';
import '../../../data/defs/mass_battle_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../activity/application/durable_activity_automation_service.dart';
import '../../cultivation/domain/skill_drop_result.dart';
import '../../cultivation/presentation/skill_treasure_overlay.dart';
import '../../encounter/presentation/encounter_hook.dart';
import '../../encounter/presentation/encounter_dialog.dart';
import '../../encounter/presentation/sect_recruit_confirm_dialog.dart';
import '../../encounter/application/encounter_service.dart';
import '../../jianghu/application/jianghu_providers.dart';
import '../../jianghu/application/reputation_service.dart';
import '../../festival/application/festival_service_providers.dart';
import '../../lineage/presentation/disciple_join_hook.dart';
import '../../sect/presentation/stage_boss_recruit_hook.dart';
import '../../sect/application/sect_recruit_transaction_service.dart';
import '../../equipment/application/equipment_service.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/utils/rng_provider.dart';
import '../application/mainline_progress_service.dart';
import '../application/mainline_chapter_boundary.dart';
import '../application/mainline_participant_snapshot_service.dart';
import '../application/mainline_pending_jianghu_affair_service.dart';
import '../application/mainline_providers.dart';
import '../application/mainline_run_coordinator.dart';
import '../application/mainline_settlement_journal_service.dart';
import '../application/phase0a_mainline_production_encounter_factory.dart';
import '../domain/chapter_assets.dart';
import '../domain/mainline_pending_jianghu_affair.dart';
import '../domain/mainline_run.dart';
import '../domain/mainline_settlement_journal.dart';
import '../../combat_shared/presentation/victory_ceremony.dart';
import '../../battle_record/application/boss_memory_hook.dart';
import '../../battle_record/domain/boss_memory_key.dart';
import '../../battle_record/domain/boss_memory_source.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import 'phase0a_mainline_battle_host.dart';
import 'chapter_transition_screen.dart';
import 'stage_victory_dialog.dart';
import '../domain/mainline_participation_policy.dart';

import '../application/mainline_settlement.dart'
    hide applyVictoryResolution, applyParticipantDefeatResolution;
import '../application/mainline_settlement.dart'
    as settlement
    show applyVictoryResolution, applyParticipantDefeatResolution;

export '../application/mainline_settlement.dart'
    show
        MainlineDurableSettlementContext,
        DurableActivityCombatSettlementDependencies,
        DefeatLossEntry,
        InjuryBeforeSnapshot,
        buildDefeatLossEntries,
        planMainlinePendingJianghuAffairsInTxn,
        shouldSkipScrollDrop;

typedef MainlineBattleExit = ({
  bool won,
  bool surrendered,
  CombatSettlementSnapshot? settlement,
});

@visibleForTesting
bool shouldAutomaticallyPresentStageNarratives(StageDef stage) =>
    stage.stageType != StageType.mainline;

Future<void> runStageFlow({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
  int targetCycle = 1,
  bool continueFirstClearRun = false,
  int? visibleReplayParticipantId,
  ActivityController visibleReplayController = ActivityController.human,
  CombatantSnapshot? directParticipantSnapshot,
  ActivityController directParticipantController = ActivityController.human,
  @visibleForTesting Future<bool> Function()? battleRunnerForTest,
  @visibleForTesting
  Future<({bool won, bool surrendered})> Function()? battleOutcomeForTest,
  @visibleForTesting
  Future<MainlineBattleExit> Function()? phase0aBattleOutcomeForTest,
  @visibleForTesting Future<bool> Function()? stageRetryDeciderForTest,
  @visibleForTesting
  Future<void> Function(String stageId)? victoryRecorderForTest,
  @visibleForTesting
  Future<List<DefeatLossEntry>> Function(StageDef stage)?
  bossDefeatPenaltyForTest,
}) async {
  if (directParticipantSnapshot != null) {
    if (stage.stageType != StageType.lightFoot &&
        stage.stageType != StageType.massBattle &&
        stage.stageType != StageType.innerDemon) {
      throw ArgumentError.value(
        directParticipantSnapshot.characterId,
        'directParticipantSnapshot',
        'is supported only for a direct special-mode challenge',
      );
    }
    if (visibleReplayParticipantId != null || continueFirstClearRun) {
      throw ArgumentError(
        'Direct participant cannot be combined with a mainline run or replay',
      );
    }
  } else if (directParticipantController != ActivityController.human) {
    throw ArgumentError(
      'Direct participant controller requires a direct participant snapshot',
    );
  }
  if (!continueFirstClearRun ||
      targetCycle != 1 ||
      stage.stageType != StageType.mainline) {
    CombatantSnapshot? visibleReplaySnapshot;
    if (visibleReplayParticipantId != null) {
      if (stage.stageType != StageType.mainline) {
        throw ArgumentError.value(
          visibleReplayParticipantId,
          'visibleReplayParticipantId',
          'is supported only for mainline replay',
        );
      }
      try {
        visibleReplaySnapshot =
            await resolveMainlineVisibleReplayParticipantSnapshot(
              isar: IsarSetup.instance,
              stageId: stage.id,
              requestedParticipantId: visibleReplayParticipantId,
              controller: visibleReplayController,
            );
      } on MainlineParticipationRefusedError {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(UiStrings.mainlineReplayParticipantUnavailable),
            ),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;
    await _runSingleStageFlow(
      context: context,
      ref: ref,
      stage: stage,
      targetCycle: targetCycle,
      playerSnapshot: directParticipantSnapshot ?? visibleReplaySnapshot,
      battleController: directParticipantSnapshot != null
          ? directParticipantController
          : visibleReplaySnapshot == null
          ? ActivityController.human
          : visibleReplayController,
      battleRunnerForTest: battleRunnerForTest,
      battleOutcomeForTest: battleOutcomeForTest,
      phase0aBattleOutcomeForTest: phase0aBattleOutcomeForTest,
      stageRetryDeciderForTest: stageRetryDeciderForTest,
      victoryRecorderForTest: victoryRecorderForTest,
      bossDefeatPenaltyForTest: bossDefeatPenaltyForTest,
    );
    return;
  }

  final settlementService = MainlineSettlementJournalService(
    IsarSetup.instance,
  );
  final scrollResume = await _resumeChapterScrollAtEntry(
    context: context,
    ref: ref,
    service: settlementService,
  );
  if (scrollResume.handled && scrollResume.nextBootstrap == null) return;
  final bootstrap = scrollResume.handled
      ? scrollResume.nextBootstrap
      : await _bootstrapMainlineRun(stage);
  if (bootstrap == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(UiStrings.mainlineRunParticipantUnavailable),
        ),
      );
    }
    return;
  }
  var currentBootstrap = bootstrap;
  while (true) {
    final coordinator = MainlineRunCoordinator(
      executeStage: (launch) async {
        StageVictoryAction? action;
        final nextStage = _nextStageInSameChapter(launch.stage);
        final boundary = resolveMainlineChapterBoundary(
          repository: GameRepository.instance,
          completedStage: launch.stage,
        );
        final identity = MainlineSettlementIdentity(
          runId: launch.run.runId,
          stageId: launch.stage.id,
          loadoutVersion: launch.run.currentLoadoutVersion,
          participantId: launch.run.participantId,
        );
        final journal = await settlementService.prepare(
          saveDataId: IsarSetup.currentSlotId,
          identity: identity,
          loadoutSnapshotId: launch.run.loadoutSnapshots.last.loadoutSnapshotId,
          loadoutSnapshotIds: launch.run.loadoutSnapshots
              .map((snapshot) => snapshot.loadoutSnapshotId)
              .toList(growable: false),
          now: DateTime.now(),
        );
        if (!context.mounted) {
          return MainlineStageFlowDecision.stoppedBeforeVictory;
        }
        await _runSingleStageFlow(
          context: context,
          ref: ref,
          stage: launch.stage,
          targetCycle: targetCycle,
          playerSnapshot: launch.playerSnapshot,
          allowEnterNextStage: nextStage != null,
          completesChapter: boundary != null,
          victoryActionSink: (value) => action = value,
          durableSettlement: (service: settlementService, identity: identity),
          durableJournal: journal,
          battleRunnerForTest: battleRunnerForTest,
          battleOutcomeForTest: battleOutcomeForTest,
          phase0aBattleOutcomeForTest: phase0aBattleOutcomeForTest,
          stageRetryDeciderForTest: stageRetryDeciderForTest,
          victoryRecorderForTest: victoryRecorderForTest,
          bossDefeatPenaltyForTest: bossDefeatPenaltyForTest,
        );
        final resolvedAction = action;
        if (resolvedAction == null) {
          return MainlineStageFlowDecision.stoppedBeforeVictory;
        }
        if (boundary != null) {
          return resolvedAction == StageVictoryAction.showChapterScroll
              ? MainlineStageFlowDecision.enterNextStage
              : MainlineStageFlowDecision.stoppedBeforeVictory;
        }
        if (nextStage == null) {
          throw StateError('Mainline stage has no successor or chapter edge');
        }
        return resolvedAction == StageVictoryAction.enterNextStage
            ? MainlineStageFlowDecision.enterNextStage
            : MainlineStageFlowDecision.returnToMapAfterVictory;
      },
      nextStageOf: _nextStageInSameChapter,
      loadNextSnapshot: ({required run, required nextStage}) =>
          _loadNextMainlineSnapshot(run: run, nextStage: nextStage),
    );
    final result = await coordinator.run(
      initialStage: currentBootstrap.stage,
      initialRun: currentBootstrap.run,
      initialPlayerSnapshot: currentBootstrap.playerSnapshot,
    );
    if (result.reason ==
        MainlineRunCompletionReason.participantNotBattleEligibleForNextStage) {
      final active = await settlementService.activeForSave(
        IsarSetup.currentSlotId,
      );
      if (active != null &&
          active.phase == MainlineSettlementPhase.coreApplied &&
          active.postSettlementAction ==
              MainlinePostSettlementAction.enterNextStage) {
        await settlementService.close(
          identity: active.identity,
          now: DateTime.now(),
        );
      }
    }
    if (result.reason ==
            MainlineRunCompletionReason
                .participantNotBattleEligibleForNextStage &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(UiStrings.mainlineRunParticipantUnavailable),
        ),
      );
    }
    if (result.reason != MainlineRunCompletionReason.chapterCompleted) {
      return;
    }
    final completedStage =
        GameRepository.instance.stageDefs[result.run.currentStageId];
    if (completedStage == null) {
      throw StateError('Completed mainline stage is unavailable');
    }
    final boundary = resolveMainlineChapterBoundary(
      repository: GameRepository.instance,
      completedStage: completedStage,
    );
    if (boundary == null) {
      throw StateError('Coordinator completed outside a chapter boundary');
    }
    final active = await settlementService.activeForSave(
      IsarSetup.currentSlotId,
    );
    if (active == null ||
        active.identity.runId != result.run.runId ||
        active.identity.stageId != completedStage.id ||
        active.postSettlementAction !=
            MainlinePostSettlementAction.showChapterScroll) {
      throw StateError('Chapter scroll recovery cursor is unavailable');
    }
    if (!context.mounted) return;
    final nextBootstrap = await _presentCompletedChapterAndContinue(
      context: context,
      service: settlementService,
      journal: active,
      boundary: boundary,
    );
    if (nextBootstrap == null) return;
    currentBootstrap = nextBootstrap;
  }
}

/// 当前 active roster 中可用于可见主线重打的候选。
///
/// 候选阶段只读取明确事实；选择后仍由
/// [resolveMainlineVisibleReplayParticipantSnapshot] 做完整装配并再次 fail closed。
Future<List<Character>> loadEligibleMainlineVisibleReplayParticipants({
  required Isar isar,
}) async {
  final save = await isar.saveDatas.get(0);
  if (save == null || save.activeCharacterIds.isEmpty) return const [];
  final occupancy = await CharacterOccupancyService(isar).snapshot();
  final candidates = <Character>[];
  for (final characterId in save.activeCharacterIds) {
    final character = await isar.characters.get(characterId);
    if (character == null ||
        !character.isAlive ||
        character.injuryHoursRemaining > 0 ||
        character.mainTechniqueId == null ||
        occupancy.isCharacterOccupied(character.id)) {
      continue;
    }
    candidates.add(character);
  }
  return List<Character>.unmodifiable(candidates);
}

/// 使用已冻结的 G0 可见重打参与政策，装配玩家实际选择的角色。
///
/// 不在 active roster、死亡、无主修、被活动占用或装配失败时均拒绝；绝不回退掌门。
Future<CombatantSnapshot> resolveMainlineVisibleReplayParticipantSnapshot({
  required Isar isar,
  required String stageId,
  required int requestedParticipantId,
  ActivityController controller = ActivityController.human,
}) async {
  final resolved = await MainlineParticipantSnapshotService(isar).resolve(
    ActivityParticipationRequest(
      contentId: stageId,
      contentKind: ActivityContentKind.mainline,
      characterId: requestedParticipantId,
      loadoutPlanId: mainlineLoadoutPlanId(
        stageId: stageId,
        characterId: requestedParticipantId,
      ),
      participation: ActivityParticipationMode.direct,
      controller: controller,
      clock: ActivityClock.realtime,
      entryKind: ActivityEntryKind.replay,
    ),
  );
  return resolved.snapshot;
}

Future<int?> showMainlineVisibleReplayParticipantPicker({
  required BuildContext context,
  required List<Character> candidates,
}) {
  return PaperDialog.show<int>(
    context,
    title: UiStrings.mainlineReplayParticipantTitle,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(UiStrings.mainlineReplayParticipantBody),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: candidates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, index) {
              final character = candidates[index];
              return OutlinedButton(
                key: Key('mainline_replay_participant_${character.id}'),
                onPressed: () => Navigator.of(context).pop(character.id),
                child: Text(character.name),
              );
            },
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(UiStrings.commonCancel),
      ),
    ],
  );
}

enum MainlineReplayMode { visible, headless }

Future<MainlineReplayMode?> showMainlineReplayModePicker(BuildContext context) {
  return PaperDialog.show<MainlineReplayMode>(
    context,
    title: UiStrings.mainlineReplayModeTitle,
    actions: const [],
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          key: const Key('mainline_visible_replay_mode'),
          onPressed: () =>
              Navigator.of(context).pop(MainlineReplayMode.visible),
          child: const Column(
            children: [
              Text(UiStrings.mainlineVisibleReplayMode),
              Text(UiStrings.mainlineVisibleReplayModeHint),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('mainline_headless_replay_mode'),
          onPressed: () =>
              Navigator.of(context).pop(MainlineReplayMode.headless),
          child: const Column(
            children: [
              Text(UiStrings.mainlineHeadlessReplayMode),
              Text(UiStrings.mainlineHeadlessReplayModeHint),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 从当前存档读取候选并展示可见重打参与者选择。
Future<int?> selectMainlineVisibleReplayParticipant({
  required BuildContext context,
}) async {
  final candidates = await loadEligibleMainlineVisibleReplayParticipants(
    isar: IsarSetup.instance,
  );
  if (!context.mounted) return null;
  if (candidates.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(UiStrings.mainlineReplayNoEligibleParticipant),
      ),
    );
    return null;
  }
  return showMainlineVisibleReplayParticipantPicker(
    context: context,
    candidates: candidates,
  );
}

typedef _MainlineRunBootstrap = ({
  StageDef stage,
  MainlineRun run,
  CombatantSnapshot playerSnapshot,
});

typedef _ChapterScrollResume = ({
  bool handled,
  _MainlineRunBootstrap? nextBootstrap,
});

Future<_ChapterScrollResume> _resumeChapterScrollAtEntry({
  required BuildContext context,
  required WidgetRef ref,
  required MainlineSettlementJournalService service,
}) async {
  final active = await service.activeForSave(IsarSetup.currentSlotId);
  if (active == null ||
      active.phase != MainlineSettlementPhase.coreApplied ||
      (active.postSettlementAction != MainlinePostSettlementAction.none &&
          active.postSettlementAction !=
              MainlinePostSettlementAction.showChapterScroll)) {
    return (handled: false, nextBootstrap: null);
  }
  final completedStage = GameRepository.instance.stageDefs[active.stageId];
  if (completedStage == null ||
      completedStage.stageType != StageType.mainline) {
    throw StateError('Chapter scroll stage is unavailable');
  }
  final boundary = resolveMainlineChapterBoundary(
    repository: GameRepository.instance,
    completedStage: completedStage,
  );
  if (boundary == null) {
    return (handled: false, nextBootstrap: null);
  }
  if (active.postSettlementAction == MainlinePostSettlementAction.none) {
    await service.recordPostSettlementAction(
      identity: active.identity,
      action: MainlinePostSettlementAction.showChapterScroll,
      now: DateTime.now(),
    );
  }
  if (!context.mounted) return (handled: true, nextBootstrap: null);
  final drained = await _drainMainlinePendingJianghuAffairs(
    context: context,
    ref: ref,
    stage: completedStage,
    durableSettlement: (service: service, identity: active.identity),
    includeStageBossRecruit: true,
  );
  if (!drained) return (handled: true, nextBootstrap: null);
  final refreshed = await service.journalFor(active.identity);
  if (refreshed == null ||
      refreshed.phase != MainlineSettlementPhase.coreApplied ||
      refreshed.postSettlementAction !=
          MainlinePostSettlementAction.showChapterScroll ||
      !refreshed.allEffectsCompleted) {
    throw StateError('Chapter scroll recovery cursor drifted');
  }
  if (!context.mounted) return (handled: true, nextBootstrap: null);
  final nextBootstrap = await _presentCompletedChapterAndContinue(
    context: context,
    service: service,
    journal: refreshed,
    boundary: boundary,
  );
  return (handled: true, nextBootstrap: nextBootstrap);
}

Future<_MainlineRunBootstrap?> _presentCompletedChapterAndContinue({
  required BuildContext context,
  required MainlineSettlementJournalService service,
  required MainlineSettlementJournal journal,
  required MainlineChapterBoundary boundary,
}) async {
  if (journal.phase != MainlineSettlementPhase.coreApplied ||
      journal.postSettlementAction !=
          MainlinePostSettlementAction.showChapterScroll ||
      !journal.allEffectsCompleted ||
      journal.stageId != boundary.completedStageId) {
    throw StateError('Chapter scroll is not ready to present');
  }
  if (!context.mounted) return null;
  final action = await Navigator.of(context).push<ChapterTransitionAction>(
    MaterialPageRoute(
      builder: (_) => ChapterTransitionScreen(
        chapterIndex: boundary.completedChapterIndex,
        showEpilogue: true,
        isRunCompletion: true,
        nextChapterIndex: boundary.nextChapterIndex,
      ),
    ),
  );
  if (!context.mounted) return null;
  if (action != ChapterTransitionAction.enterNextChapter ||
      boundary.isFinalChapter) {
    await service.close(identity: journal.identity, now: DateTime.now());
    return null;
  }
  final nextStage = boundary.nextChapterFirstStage;
  if (nextStage == null ||
      nextStage.chapterIndex != boundary.nextChapterIndex) {
    throw StateError('Next chapter first stage is unavailable');
  }
  final nextBootstrap = await _createFreshMainlineRunBootstrap(nextStage);
  if (nextBootstrap == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(UiStrings.mainlineRunParticipantUnavailable),
        ),
      );
    }
    return null;
  }
  final nextIdentity = MainlineSettlementIdentity(
    runId: nextBootstrap.run.runId,
    stageId: nextStage.id,
    loadoutVersion: nextBootstrap.run.currentLoadoutVersion,
    participantId: nextBootstrap.run.participantId,
  );
  final prepared = await service.beginNextChapter(
    previousIdentity: journal.identity,
    nextIdentity: nextIdentity,
    nextLoadoutSnapshotId:
        nextBootstrap.run.loadoutSnapshots.last.loadoutSnapshotId,
    now: DateTime.now(),
  );
  if (prepared.identity != nextIdentity ||
      prepared.phase != MainlineSettlementPhase.prepared ||
      prepared.loadoutSnapshotIds.length != 1) {
    throw StateError('Next chapter transaction did not prepare the exact run');
  }
  return nextBootstrap;
}

Future<_MainlineRunBootstrap?> _bootstrapMainlineRun(StageDef stage) async {
  final isar = IsarSetup.instance;
  final active = await MainlineSettlementJournalService(
    isar,
  ).activeForSave(IsarSetup.currentSlotId);
  if (active != null) {
    final resumedStage = GameRepository.instance.stageDefs[active.stageId];
    if (resumedStage == null || resumedStage.stageType != StageType.mainline) {
      throw StateError('Active mainline settlement stage is unavailable');
    }
    final playerSnapshot = await _loadMainlineParticipantSnapshot(
      active.participantId,
    );
    if (playerSnapshot == null) {
      if (active.phase == MainlineSettlementPhase.coreApplied &&
          active.postSettlementAction ==
              MainlinePostSettlementAction.enterNextStage) {
        await MainlineSettlementJournalService(
          isar,
        ).close(identity: active.identity, now: DateTime.now());
      }
      return null;
    }
    return (
      stage: resumedStage,
      run: MainlineRun.restore(
        runId: active.runId,
        participantId: active.participantId,
        stageId: active.stageId,
        loadoutSnapshotIds: active.loadoutSnapshotIds,
      ),
      playerSnapshot: playerSnapshot,
    );
  }
  return _createFreshMainlineRunBootstrap(stage);
}

Future<_MainlineRunBootstrap?> _createFreshMainlineRunBootstrap(
  StageDef stage,
) async {
  final isar = IsarSetup.instance;
  final save = await isar.saveDatas.get(0);
  final participantId = await CurrentLeaderResolver.resolve(
    save: save,
    characterExists: (characterId) async =>
        await isar.characters.get(characterId) != null,
  );
  late final CombatantSnapshot playerSnapshot;
  try {
    playerSnapshot = (await MainlineParticipantSnapshotService(isar).resolve(
      ActivityParticipationRequest(
        contentId: stage.id,
        contentKind: ActivityContentKind.mainline,
        characterId: participantId,
        loadoutPlanId: mainlineLoadoutPlanId(
          stageId: stage.id,
          characterId: participantId,
        ),
        participation: ActivityParticipationMode.direct,
        controller: ActivityController.human,
        clock: ActivityClock.realtime,
        entryKind: ActivityEntryKind.firstClear,
      ),
    )).snapshot;
  } on MainlineParticipationRefusedError {
    return null;
  }
  final runId =
      'mainline:${IsarSetup.currentSlotId}:${stage.id}:'
      '${DateTime.now().microsecondsSinceEpoch}';
  return (
    stage: stage,
    run: MainlineRun.begin(
      runId: runId,
      participantId: participantId,
      stageId: stage.id,
      loadoutSnapshotId: '$runId:loadout:1',
    ),
    playerSnapshot: playerSnapshot,
  );
}

Future<PreparedMainlineLoadoutSnapshot?> _loadNextMainlineSnapshot({
  required MainlineRun run,
  required StageDef nextStage,
}) async {
  final snapshot = await _loadMainlineParticipantSnapshot(run.participantId);
  if (snapshot == null) return null;
  final nextVersion = run.currentLoadoutVersion + 1;
  return PreparedMainlineLoadoutSnapshot(
    playerSnapshot: snapshot,
    loadoutSnapshotId: '${run.runId}:loadout:$nextVersion',
  );
}

Future<CombatantSnapshot?> _loadMainlineParticipantSnapshot(
  int participantId,
) => _loadMainlineParticipantSnapshotFromIsar(
  isar: IsarSetup.instance,
  participantId: participantId,
);

Future<CombatantSnapshot?> _loadMainlineParticipantSnapshotFromIsar({
  required Isar isar,
  required int participantId,
}) async {
  final character = await isar.characters.get(participantId);
  if (character == null ||
      !character.isAlive ||
      character.mainTechniqueId == null) {
    return null;
  }
  for (final equipmentId in [
    character.equippedWeaponId,
    character.equippedArmorId,
    character.equippedAccessoryId,
  ]) {
    if (equipmentId != null && await isar.equipments.get(equipmentId) == null) {
      throw StateError(
        'Mainline participant $participantId has a dangling equipment '
        'reference: $equipmentId',
      );
    }
  }
  final occupancy = await CharacterOccupancyService(isar).snapshot();
  if (occupancy.isCharacterOccupied(participantId)) return null;
  final roster = await PlayerCombatantSnapshotAssembler(
    isar: isar,
  ).loadExactRoster([participantId]);
  if (roster.length != 1 || roster.single.characterId != participantId) {
    throw StateError('Mainline run snapshot participant mismatch');
  }
  return roster.single;
}

StageDef? _nextStageInSameChapter(StageDef currentStage) {
  final repository = GameRepository.instance;
  final nextStageId = nextMainlineStageId(repository, currentStage.id);
  if (nextStageId == null) return null;
  final currentChapter = _mainlineChapterOf(currentStage.id);
  if (currentChapter == null ||
      currentChapter != _mainlineChapterOf(nextStageId)) {
    return null;
  }
  return repository.getStage(nextStageId);
}

String? _mainlineChapterOf(String stageId) =>
    RegExp(r'^stage_(\d{2})_\d{2}$').firstMatch(stageId)?.group(1);

/// Phase 3 T37 关卡进入流程串联。
///
/// 状态机（async 串联，无中间 widget）：
///   1. opening：特殊模式若 [StageDef.narrativeOpeningId] 非空，push
///      NarrativeReaderScreen → wait its pop；主线 opening 搬到章节卷轴主动阅读。
///   2. battle：装配单主角 Phase0A 战斗 → wait onVictory / onDefeat
///      回调（Completer 转 Future）
///   3a. victory：异步 recordVictory + invalidate progress provider；特殊模式
///       若 narrativeVictoryId 非空 → push 第二段剧情，主线不自动 push。
///   3b. defeat：Boss 惩罚照常结算；主线以事实弹层展示损失且不自动 push
///       narrativeDefeatId，特殊模式保留旧 defeat reader。
///
/// **不嵌套 widget**：每段结束后栈上仅剩 stage_list_screen，避免多层 pop。
///
/// [phase0aBattleOutcomeForTest] 仅供 widget test 注入，生产端始终使用
/// [Phase0aMainlineBattleHost]。
/// D1: [targetCycle] 默认 1（零回归）。Task E 加 UI 后从 caller 传入。
Future<void> _runSingleStageFlow({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
  int targetCycle = 1,
  CombatantSnapshot? playerSnapshot,
  ActivityController battleController = ActivityController.human,
  bool allowEnterNextStage = false,
  bool completesChapter = false,
  ValueChanged<StageVictoryAction>? victoryActionSink,
  MainlineDurableSettlementContext? durableSettlement,
  MainlineSettlementJournal? durableJournal,
  @visibleForTesting Future<bool> Function()? battleRunnerForTest,
  @visibleForTesting
  Future<({bool won, bool surrendered})> Function()? battleOutcomeForTest,
  @visibleForTesting
  Future<MainlineBattleExit> Function()? phase0aBattleOutcomeForTest,
  @visibleForTesting Future<bool> Function()? stageRetryDeciderForTest,
  @visibleForTesting
  Future<void> Function(String stageId)? victoryRecorderForTest,
  @visibleForTesting
  Future<List<DefeatLossEntry>> Function(StageDef stage)?
  bossDefeatPenaltyForTest,
}) async {
  if ((durableSettlement == null) != (durableJournal == null)) {
    throw StateError('Durable settlement context must be complete');
  }
  if (allowEnterNextStage && completesChapter) {
    throw StateError('A stage cannot continue within and complete a chapter');
  }
  if (durableJournal?.phase == MainlineSettlementPhase.coreApplied) {
    final drained = await _drainMainlinePendingJianghuAffairs(
      context: context,
      ref: ref,
      stage: stage,
      durableSettlement: durableSettlement!,
      includeStageBossRecruit: true,
    );
    if (!drained) return;
    var action = switch (durableJournal!.postSettlementAction) {
      MainlinePostSettlementAction.returnToMap =>
        StageVictoryAction.returnToMap,
      MainlinePostSettlementAction.enterNextStage =>
        StageVictoryAction.enterNextStage,
      MainlinePostSettlementAction.showChapterScroll =>
        StageVictoryAction.showChapterScroll,
      MainlinePostSettlementAction.none => null,
    };
    if (action == null) {
      if (completesChapter) {
        action = StageVictoryAction.showChapterScroll;
      } else {
        if (!context.mounted) return;
        action = await showRecoveredStageSettlementDialog(
          context: context,
          stage: stage,
          allowEnterNextStage: allowEnterNextStage,
        );
      }
      await durableSettlement.service.recordPostSettlementAction(
        identity: durableSettlement.identity,
        action: switch (action) {
          StageVictoryAction.returnToMap =>
            MainlinePostSettlementAction.returnToMap,
          StageVictoryAction.enterNextStage =>
            MainlinePostSettlementAction.enterNextStage,
          StageVictoryAction.showChapterScroll =>
            MainlinePostSettlementAction.showChapterScroll,
        },
        now: DateTime.now(),
      );
    }
    if (action == StageVictoryAction.returnToMap ||
        (!allowEnterNextStage && !completesChapter)) {
      await durableSettlement.service.close(
        identity: durableSettlement.identity,
        now: DateTime.now(),
      );
    }
    victoryActionSink?.call(action);
    return;
  }
  final automaticallyPresentsNarratives =
      shouldAutomaticallyPresentStageNarratives(stage);
  // 特殊亲战均使用逐次准入的 exact participant；主线连续 run
  // 仍走原掌门锁定。
  final usesExactParticipant =
      stage.stageType == StageType.lightFoot ||
      stage.stageType == StageType.massBattle ||
      stage.stageType == StageType.innerDemon;
  final expectedParticipantId = playerSnapshot?.characterId;
  final participantName = playerSnapshot?.name;

  // ── opening ──
  if (automaticallyPresentsNarratives && stage.narrativeOpeningId != null) {
    final opening = await NarrativeLoader.load(stage.narrativeOpeningId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: opening,
          fallbackTitle: stage.name,
          backgroundImagePath: stageNarrativePath(stage.id),
        ),
      ),
    );
  }

  // ── battle ──（M3:普通关战败可「立即重试」,opening 已在循环外播过一次,
  // 重试只重打本场不重看剧情。Boss 关不重试 —— 已实时结算散功,回滚复杂）。
  CombatSettlementSnapshot? completedSettlement;
  while (true) {
    if (!context.mounted) return;
    final MainlineBattleExit battleExit;
    String? defeatReason;
    if (phase0aBattleOutcomeForTest != null) {
      battleExit = await phase0aBattleOutcomeForTest();
    } else if (battleOutcomeForTest != null) {
      final result = await battleOutcomeForTest();
      battleExit = (
        won: result.won,
        surrendered: result.surrendered,
        settlement: null,
      );
    } else if (battleRunnerForTest != null) {
      battleExit = (
        won: await battleRunnerForTest(),
        surrendered: false,
        settlement: null,
      );
    } else {
      battleExit = await _runBattle(
        context: context,
        stage: stage,
        targetCycle: targetCycle,
        playerSnapshot: playerSnapshot,
        controller: battleController,
        onDefeatReason: (reason) => defeatReason = reason,
      );
    }

    // H3 投降:host 已 pop 战斗屏,跳过所有战败结算直接返回,不记进度。
    if (battleExit.surrendered) return;
    if (battleExit.won) {
      completedSettlement = battleExit.settlement;
      break; // 胜利 → 跳出循环走 victory 流程
    }

    // ── defeat ──
    Widget? lossBanner;
    if (stage.isBossStage) {
      // Phase 4 W10: Boss 关战败结算（被动散功 + battleCount + skillUsage 落地）。
      final summary = bossDefeatPenaltyForTest != null
          ? await bossDefeatPenaltyForTest(stage)
          : await applyParticipantDefeatResolution(
              ref: ref,
              stage: stage,
              settlementSnapshot: battleExit.settlement,
              expectedParticipantId: expectedParticipantId,
            );
      if (summary.isNotEmpty) {
        // W13-v3 fix: writeTxn 写回 character.internalForce / mainTech.layer
        // 后必须 invalidate provider 缓存,否则下次进角色面板/心法面板仍读旧值
        // (Codex v3 截图 15 暴露:banner 显 3800→1900,但面板仍 3800)
        invalidateAfterCombatSettlement(ref.invalidate);
        if (!automaticallyPresentsNarratives) {
          if (!context.mounted) return;
          await _showMainlineDefeatLossDialog(context, summary);
          if (!context.mounted) return;
        } else {
          lossBanner = _DefeatLossBanner(entries: summary);
        }
      }
    } else {
      // M3:普通关战败立即重试(试错免费,无惩罚)。选「再战」→ 回循环头重打。
      final retry = stageRetryDeciderForTest != null
          ? await stageRetryDeciderForTest()
          : (context.mounted
                ? await _showStageRetryDialog(
                    context,
                    stage,
                    participantName: participantName,
                    defeatReason: defeatReason,
                  )
                : false);
      if (retry) continue;
      if (usesExactParticipant && expectedParticipantId != null) {
        final summary = await applyParticipantDefeatResolution(
          ref: ref,
          stage: stage,
          settlementSnapshot: battleExit.settlement,
          expectedParticipantId: expectedParticipantId,
        );
        invalidateAfterCombatSettlement(ref.invalidate);
        if (summary.isNotEmpty && context.mounted) {
          await _showMainlineDefeatLossDialog(context, summary);
          if (!context.mounted) return;
        }
      }
    }

    // 不重试(Boss 关 / 普通关放弃)→ 特殊模式战败剧情 + 收降,返回。
    // 主线所有 defeat 旧卷只在章节 timeline 主动阅读。
    if (automaticallyPresentsNarratives &&
        stage.narrativeDefeatId != null &&
        context.mounted) {
      final defeat = await NarrativeLoader.load(stage.narrativeDefeatId!);
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => NarrativeReaderScreen(
            content: defeat,
            fallbackTitle: UiStrings.stageNarrativeDefeatTitle(stage.name),
            topBanner: lossBanner,
            backgroundImagePath: stageNarrativePath(stage.id),
          ),
        ),
      );
    }
    // 1.1 战败收降 hook(stageBossFailRecoverProb 0.30 · 沿 victory recruit 体例)
    if (context.mounted) {
      await runStageBossFailRecoverHookAfterDefeat(
        context: context,
        ref: ref,
        stage: stage,
      );
    }
    return; // 战败不记录主线进度、不推 victory 剧情
  }

  // ── victory ──
  // Phase 4 W11 #32 销账：装备 battleCount / 心法 skillUsage / 主修升层 + 关卡 drop 落地
  final clearedBeforeVictory = <String>{};
  if (IsarSetup.instanceOrNull != null) {
    final progress = await MainlineProgressService(
      isar: IsarSetup.instance,
    ).getOrCreate(saveDataId: IsarSetup.currentSlotId);
    clearedBeforeVictory.addAll(progress.clearedStageIds);
  }
  final outcome = await applyVictoryResolution(
    ref: ref,
    stage: stage,
    cycle: targetCycle,
    settlementSnapshot: completedSettlement,
    durableSettlement: durableSettlement,
    expectedParticipantId: expectedParticipantId,
    rewardOccurrenceId:
        durableSettlement?.identity.canonical ??
        'stage:${stage.id}:${completedSettlement?.playerCharacterId ?? expectedParticipantId ?? 0}:'
            '${DateTime.now().microsecondsSinceEpoch}',
  );
  // W13-v3 fix: 同 defeat 分支,invalidate character/equipment/technique family
  // + 主菜单隐藏入口门控 / 银两(体检批3 P0-5),统一走共享 helper。
  invalidateAfterCombatSettlement(ref.invalidate);

  // W12 fix: provider 副作用 getOrCreate 与 recordVictory 存在 race（W6 重构遗留），
  // 主动 ensure 避免 MainlineProgress 未初始化时抛 StateError
  // 可玩性 P1a:技能书首通判定需"写 clearedStageIds 之前"的快照。
  // 第七阶段批二④:捕获技能掉落结果供战后仪式分层(test stub 路径留 .none)。
  SkillDropResult skillDrop = SkillDropResult.none;
  if (durableSettlement != null) {
    skillDrop = outcome?.skillDrop ?? SkillDropResult.none;
    ref.invalidate(mainlineProgressProvider);
    ref.invalidate(currentTutorialStepProvider);
  } else if (victoryRecorderForTest != null) {
    await victoryRecorderForTest(stage.id);
  } else {
    skillDrop = outcome?.skillDrop ?? SkillDropResult.none;
    ref.invalidate(mainlineProgressProvider);
    ref.invalidate(currentTutorialStepProvider);

    // P4 战绩册:Boss 胜利 → 留档(纯数据写;test stub 路径不进 else,天然跳过,同 recordVictory/skillDrop)。
    if (stage.isBossStage && outcome != null) {
      final boss = stage.enemyTeam.isNotEmpty
          ? stage.enemyTeam.last.name
          : stage.name;
      await runBossMemoryHookAfterVictory(
        source: BossMemorySource.mainline,
        bossKey: mainlineBossKey(stage.id),
        groupIndex: mainlineGroupIndex(stage.id),
        bossName: boss,
        stats: outcome.stats,
        drops: outcome.drops,
        topContributorName: outcome.heroCamera?.heroName,
        topContributorDamage: outcome.heroCamera?.topDamage,
      );
    }
  }

  // W15 #30 P3 后续 A:victory dialog 显 drop + 升层 banner;outcome=null 时
  // (Isar 未 ready / characters 空)兜底跳过 dialog 不阻塞剧情流。
  // 第七阶段 批一:Boss 首胜先弹英雄镜头，再走胜利仪式。
  StageVictoryAction? durableVictoryAction;
  if (outcome != null && context.mounted) {
    final isFirstClear = !clearedBeforeVictory.contains(stage.id);
    if (shouldShowHeroCamera(
      isBoss: stage.isBossStage,
      isFirstClear: isFirstClear,
      data: outcome.heroCamera,
    )) {
      await presentHeroCamera(context, outcome.heroCamera!);
      if (!context.mounted) return;
    }
    // 第七阶段批二④:技能珍稀重仪式(真解首通 / 残页集齐)夹在英雄镜头与装备
    // treasure 之间。非重仪式(isMajor=false)时 presentSkillTreasure no-op。
    if (skillDrop.isMajor && context.mounted) {
      await presentSkillTreasure(context, skillDrop);
      if (!context.mounted) return;
    }
    await presentVictoryCeremony(
      context,
      outcome.drops,
      treasureGate: true,
      extraDisplayTiers: outcome.extraDisplayTiers,
    );
    if (!context.mounted) return;
    final dialogAction = await showStageVictoryDialog(
      context: context,
      stage: stage,
      participantName: participantName,
      drops: outcome.drops,
      advancements: outcome.advancements,
      resonanceUpgrades: outcome.resonanceUpgrades,
      stats: outcome.stats,
      injurySummaryCharacters: outcome.characters,
      equipmentHintCharacters: outcome.characters,
      skillFragmentLine: skillFragmentLineFor(skillDrop),
      onEquipmentLockToggle: (equipment, locked) async {
        final result = await EquipmentService(
          isar: IsarSetup.instance,
        ).setLocked(equipmentId: equipment.id, locked: locked);
        return result == EquipOutcome.success;
      },
      allowEnterNextStage: allowEnterNextStage,
    );
    if (durableSettlement != null) {
      final victoryAction = completesChapter
          ? StageVictoryAction.showChapterScroll
          : dialogAction;
      durableVictoryAction = victoryAction;
      await durableSettlement.service.recordPostSettlementAction(
        identity: durableSettlement.identity,
        action: switch (victoryAction) {
          StageVictoryAction.returnToMap =>
            MainlinePostSettlementAction.returnToMap,
          StageVictoryAction.enterNextStage =>
            MainlinePostSettlementAction.enterNextStage,
          StageVictoryAction.showChapterScroll =>
            MainlinePostSettlementAction.showChapterScroll,
        },
        now: DateTime.now(),
      );
    } else {
      victoryActionSink?.call(dialogAction);
    }
  }

  // 胜利仪式 + 结算在战斗界面之上播完,退回关卡列表(再走胜利剧情)。
  if (context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }

  if (automaticallyPresentsNarratives && stage.narrativeVictoryId != null) {
    if (!context.mounted) return;
    final victory = await NarrativeLoader.load(stage.narrativeVictoryId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: victory,
          fallbackTitle: UiStrings.stageNarrativeVictoryTitle(stage.name),
          backgroundImagePath: stageNarrativePath(stage.id),
        ),
      ),
    );
  }

  // Phase 4 W14-1 C-1 / W14-2:奇遇/武学领悟触发检查。
  // 放在 victory narrative 之后:通关剧情是这关的收尾,奇遇作为下一段开端。
  // W14-2 抽到 encounter_hook.dart,与爬塔共享。
  if (!context.mounted) return;
  if (durableSettlement == null) {
    await runEncounterHookAfterVictory(
      context: context,
      ref: ref,
      defeatedSchools: stage.enemyTeam
          .map((e) => e.school)
          .toList(growable: false),
    );
  } else {
    final drained = await _drainMainlinePendingJianghuAffairs(
      context: context,
      ref: ref,
      stage: stage,
      durableSettlement: durableSettlement,
      includeStageBossRecruit: false,
    );
    if (!drained) return;
  }

  // 第七阶段批三:命名弟子拜入 hook(过 join 触发关 → 拜师叙事 + 最小立绘题字)。
  // 在 encounter hook 之后、boss 招降 hook 之前;service 内 gate 决定是否真触发,
  // 非 join 关 / 已触发为 no-op。
  if (context.mounted) {
    await runDiscipleJoinHookAfterVictory(
      context: context,
      ref: ref,
      stageId: stage.id,
    );
  }

  // P4.1 1.1 Q6B · Boss 战胜后招降 hook(spec p4_1_q6b_stage_boss_recruit_spec
  // _2026-05-26.md §3.2)· 在 encounter hook 之后顺序执行 · isBossStage +
  // bossRecruit 非 null + rng 命中 + markTriggered 守通过才弹 confirm dialog。
  if (!context.mounted) return;
  if (durableSettlement == null) {
    await runStageBossRecruitHookAfterVictory(
      context: context,
      ref: ref,
      stage: stage,
    );
  } else {
    final drained = await _drainMainlinePendingJianghuAffairs(
      context: context,
      ref: ref,
      stage: stage,
      durableSettlement: durableSettlement,
      includeStageBossRecruit: true,
    );
    if (!drained) return;
    final action = durableVictoryAction;
    if (action == null) {
      throw StateError('Durable settlement victory action was not recorded');
    }
    if (action == StageVictoryAction.returnToMap ||
        (!allowEnterNextStage && !completesChapter)) {
      await durableSettlement.service.close(
        identity: durableSettlement.identity,
        now: DateTime.now(),
      );
    }
    victoryActionSink?.call(action);
  }

  // P1.2 Boss 击杀 → 声望 delta(boss 所属派系 -delta · 对立阵营 +rivalDelta)。
  if (durableSettlement == null) {
    await _applyBossKillReputation(ref: ref, stage: stage);
  }

  // 后置 hook（技能掉落、战绩册、里程碑装备、招降等）发生在主结算 helper 之后。
  // 返回关卡列表前再刷一次最终态，避免主菜单门控 / 仓库 / 资源数量读到旧缓存。
  invalidateAfterCombatSettlement(ref.invalidate);
}

Future<bool> _drainMainlinePendingJianghuAffairs({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
  required MainlineDurableSettlementContext durableSettlement,
  required bool includeStageBossRecruit,
}) async {
  final isar = IsarSetup.instance;
  final affairs = MainlinePendingJianghuAffairService(
    durableSettlement.service,
  );
  final numbers = GameRepository.instance.numbers;
  final encounterService = EncounterService(
    isar: isar,
    attributeGainCap: numbers.adventureAttributeLifetimeCap,
    attributeEffects: numbers.attributeEffects,
  );

  while (true) {
    final affair = await affairs.firstPending(
      identity: durableSettlement.identity,
    );
    if (affair == null) return true;
    if (affair.kind == MainlinePendingJianghuAffairKind.stageBossRecruit &&
        !includeStageBossRecruit) {
      return true;
    }
    if (!context.mounted) return false;

    switch (affair.kind) {
      case MainlinePendingJianghuAffairKind.encounterChoice:
        final encounter = _encounterForPendingAffair(affair);
        final founderId = durableSettlement.identity.participantId;
        final founder = await isar.characters.get(founderId);
        if (founder == null) {
          throw StateError('Pending encounter founder is unavailable');
        }
        final content = await EncounterEventLoader.load(encounter.id);
        if (!context.mounted) return false;
        final outcomeId = await showEncounterDialog(
          context: context,
          def: encounter,
          content: content,
          fortune: founder.attributes.fortune,
        );
        if (outcomeId == null) return false;

        final membership = encounter.affectsSectMembership;
        if (membership == null || outcomeId != 'accept_recruit') {
          late OutcomeApplied applied;
          final claimed = await affairs.apply(
            identity: durableSettlement.identity,
            affair: affair,
            now: DateTime.now(),
            applyInTxn: () async {
              applied = await _applyPendingEncounterOutcomeInTxn(
                encounterService: encounterService,
                reputationService: ref.read(reputationServiceProvider),
                encounter: encounter,
                outcomeId: outcomeId,
                founderId: founderId,
                encounterTitle: content.title ?? encounter.id,
                resolutionSeed: affair.resolutionSeed,
                seededRngFactory: ref.read(seededRngFactoryProvider),
                now: DateTime.now(),
              );
              await encounterService.markTriggeredInTxn(
                saveDataId: IsarSetup.currentSlotId,
                encounterId: encounter.id,
              );
            },
          );
          if (!claimed) {
            throw StateError('Pending encounter claim was not applied');
          }
          if (!context.mounted) return false;
          await showEncounterOutcomeBanner(context: context, applied: applied);
          continue;
        }

        final candidate =
            GameRepository.instance.sectCandidates[membership.candidateRef];
        if (candidate == null) {
          throw StateError(
            'Pending encounter candidate is unavailable: '
            '${membership.candidateRef}',
          );
        }
        if (!context.mounted) return false;
        final confirmed = await showSectRecruitConfirmDialog(
          context,
          candidate,
        );
        if (!context.mounted) return false;
        SectRecruitTransactionResult? recruitResult;
        OutcomeApplied? fallbackApplied;
        final claimed = await affairs.apply(
          identity: durableSettlement.identity,
          affair: affair,
          now: DateTime.now(),
          applyInTxn: () async {
            final recruitService = SectRecruitTransactionService(isar);
            await recruitService.ensureDefaultSectInTxn(
              defaultSectName: UiStrings.sectLazyInitName,
              now: DateTime.now(),
            );
            await _applyPendingEncounterOutcomeInTxn(
              encounterService: encounterService,
              reputationService: ref.read(reputationServiceProvider),
              encounter: encounter,
              outcomeId: outcomeId,
              founderId: founderId,
              encounterTitle: content.title ?? encounter.id,
              resolutionSeed: affair.resolutionSeed,
              seededRngFactory: ref.read(seededRngFactoryProvider),
              now: DateTime.now(),
            );
            if (confirmed) {
              recruitResult = await recruitService.recruitInTxn(
                candidate: candidate,
                defaultSectName: UiStrings.sectLazyInitName,
                now: DateTime.now(),
              );
              if (recruitResult == SectRecruitTransactionResult.success) {
                await encounterService.markTriggeredInTxn(
                  saveDataId: IsarSetup.currentSlotId,
                  encounterId: encounter.id,
                );
              }
            }
            if (!confirmed ||
                recruitResult == SectRecruitTransactionResult.fullCap) {
              final fallbackId = membership.fallbackOutcomeId;
              if (fallbackId != null) {
                fallbackApplied = await _applyPendingEncounterOutcomeInTxn(
                  encounterService: encounterService,
                  reputationService: ref.read(reputationServiceProvider),
                  encounter: encounter,
                  outcomeId: fallbackId,
                  founderId: founderId,
                  encounterTitle: content.title ?? encounter.id,
                  resolutionSeed: affair.resolutionSeed ^ 0x5f3759df,
                  seededRngFactory: ref.read(seededRngFactoryProvider),
                  now: DateTime.now(),
                );
              }
            }
          },
        );
        if (!claimed) {
          throw StateError('Pending sect encounter claim was not applied');
        }
        if (!context.mounted) return false;
        if (fallbackApplied != null) {
          await showEncounterOutcomeBanner(
            context: context,
            applied: fallbackApplied!,
          );
        }
        if (!context.mounted) return false;
        if (recruitResult == SectRecruitTransactionResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                UiStrings.sectEncounterRecruitSuccess(candidate.name),
              ),
            ),
          );
        } else if (recruitResult == SectRecruitTransactionResult.fullCap) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                UiStrings.sectEncounterRecruitCapFull(candidate.name),
              ),
            ),
          );
        }

      case MainlinePendingJianghuAffairKind.stageBossRecruit:
        if (affair.stageId != stage.id ||
            affair.candidateRef != stage.bossRecruit?.candidateRef) {
          throw StateError(
            'Pending Boss recruit source no longer matches stage',
          );
        }
        final candidate =
            GameRepository.instance.sectCandidates[affair.candidateRef];
        if (candidate == null) {
          throw StateError(
            'Pending Boss recruit candidate is unavailable: '
            '${affair.candidateRef}',
          );
        }
        final narrative = await NarrativeLoader.load(
          '${stage.id}_boss_recruit',
        );
        if (!narrative.isPlaceholder) {
          if (!context.mounted) return false;
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => NarrativeReaderScreen(
                content: narrative,
                fallbackTitle: UiStrings.stageBossRecruitFallbackTitle(
                  stage.name,
                ),
              ),
            ),
          );
        }
        if (!context.mounted) return false;
        final confirmed = await showSectRecruitConfirmDialog(
          context,
          candidate,
        );
        if (!context.mounted) return false;
        SectRecruitTransactionResult? recruitResult;
        final claimed = await affairs.apply(
          identity: durableSettlement.identity,
          affair: affair,
          now: DateTime.now(),
          applyInTxn: () async {
            final recruitService = SectRecruitTransactionService(isar);
            await recruitService.ensureDefaultSectInTxn(
              defaultSectName: UiStrings.sectLazyInitName,
              now: DateTime.now(),
            );
            if (!confirmed) return;
            recruitResult = await recruitService.recruitInTxn(
              candidate: candidate,
              defaultSectName: UiStrings.sectLazyInitName,
              now: DateTime.now(),
            );
            if (recruitResult != SectRecruitTransactionResult.success) return;
            final save = await isar.saveDatas.get(0);
            if (save == null) {
              throw StateError('Pending Boss recruit save is unavailable');
            }
            if (!save.triggeredBossRecruitStageIds.contains(stage.id)) {
              save.triggeredBossRecruitStageIds = List.of(
                save.triggeredBossRecruitStageIds,
              )..add(stage.id);
              await isar.saveDatas.put(save);
            }
          },
        );
        if (!claimed) {
          throw StateError('Pending Boss recruit claim was not applied');
        }
        if (!context.mounted) return false;
        if (recruitResult == SectRecruitTransactionResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(UiStrings.stageBossRecruitSuccess(candidate.name)),
            ),
          );
        } else if (recruitResult == SectRecruitTransactionResult.fullCap) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(UiStrings.stageBossRecruitCapFull(candidate.name)),
            ),
          );
        }
    }
  }
}

@visibleForTesting
Future<bool> drainMainlinePendingJianghuAffairsForTest({
  required BuildContext context,
  required WidgetRef ref,
  required StageDef stage,
  required MainlineDurableSettlementContext durableSettlement,
  required bool includeStageBossRecruit,
}) => _drainMainlinePendingJianghuAffairs(
  context: context,
  ref: ref,
  stage: stage,
  durableSettlement: durableSettlement,
  includeStageBossRecruit: includeStageBossRecruit,
);

EncounterDef _encounterForPendingAffair(
  MainlinePendingJianghuAffairRef affair,
) {
  final matches = GameRepository.instance.allEncounters
      .where((encounter) => encounter.id == affair.encounterId)
      .toList(growable: false);
  if (matches.length != 1) {
    throw StateError(
      'Pending encounter source is missing or ambiguous: '
      '${affair.encounterId}',
    );
  }
  return matches.single;
}

Future<OutcomeApplied> _applyPendingEncounterOutcomeInTxn({
  required EncounterService encounterService,
  required ReputationService? reputationService,
  required EncounterDef encounter,
  required String outcomeId,
  required int founderId,
  required String encounterTitle,
  required int resolutionSeed,
  required SeededRngFactory seededRngFactory,
  required DateTime now,
}) async {
  final applied = await encounterService.applyOutcomeInTxn(
    saveDataId: IsarSetup.currentSlotId,
    encounter: encounter,
    outcomeId: outcomeId,
    founderCharacterId: founderId,
    encounterTitle: encounterTitle,
    skillNameLookup: (skillId) =>
        GameRepository.instance.skillDefs[skillId]?.name ?? skillId,
  );
  final affects = encounter.affectsReputation;
  if (affects != null && reputationService != null) {
    final rng = seededRngFactory(seed: resolutionSeed);
    final span = affects.deltaMax - affects.deltaMin;
    final delta = affects.deltaMin + (span > 0 ? rng.nextInt(span + 1) : 0);
    await reputationService.applyDeltaInTxn(
      1,
      affects.factionId,
      delta,
      now: now,
    );
  }
  return applied;
}

/// 推 Phase0A 主线战斗宿主并 wait 胜/败/系统返回回调。
Future<MainlineBattleExit> _runBattle({
  required BuildContext context,
  required StageDef stage,
  int targetCycle = 1,
  CombatantSnapshot? playerSnapshot,
  ActivityController controller = ActivityController.human,
  ValueChanged<String>? onDefeatReason,
}) async {
  return _runPhase0aBattle(
    context: context,
    stage: stage,
    targetCycle: targetCycle,
    playerSnapshot: playerSnapshot,
    controller: controller,
    onDefeatReason: onDefeatReason,
  );
}

/// 推 0A 主线战斗宿主并 wait 胜/败回调。
///
/// 0A 屏无投降按钮(0C 键盘面只有 Esc 暂停):系统返回致 pop 而未触发
/// 回调 → then 兜底记 surrendered=true,外层直接返回；中途退出不走
/// Boss 战败惩罚、奖励或进度写入，保持零存档污染。
/// 胜利时 host 不自 pop(与旧宿主一致),由胜利段收尾统一 pop。
Future<MainlineBattleExit> _runPhase0aBattle({
  required BuildContext context,
  required StageDef stage,
  required int targetCycle,
  CombatantSnapshot? playerSnapshot,
  ActivityController controller = ActivityController.human,
  ValueChanged<String>? onDefeatReason,
}) async {
  final massBattleFormation = stage.stageType == StageType.massBattle
      ? await pickMassBattleFormation(
          context,
          stage,
          GameRepository.instance.numbers.massBattle,
        )
      : null;
  if (!context.mounted) {
    return (won: false, surrendered: true, settlement: null);
  }
  final completer = Completer<MainlineBattleExit>();
  Navigator.of(context)
      .push<void>(
        MaterialPageRoute(
          builder: (_) => Phase0aMainlineBattleHost(
            stage: stage,
            cycleIndex: targetCycle,
            playerSnapshot: playerSnapshot,
            controller: controller,
            massBattleFormation: massBattleFormation,
            onDefeatReason: onDefeatReason,
            onVictory: (settlement) {
              if (!completer.isCompleted) {
                completer.complete((
                  won: true,
                  surrendered: false,
                  settlement: settlement,
                ));
              }
            },
            onDefeat: (settlement) {
              if (!completer.isCompleted) {
                completer.complete((
                  won: false,
                  surrendered: false,
                  settlement: settlement,
                ));
              }
            },
          ),
        ),
      )
      .then((_) {
        // 兜底:只有系统返回会在无回调时 pop；按中途退出旁路所有结算。
        if (!completer.isCompleted) {
          completer.complete((won: false, surrendered: true, settlement: null));
        }
      });
  return completer.future;
}

/// M3:普通关战败「立即重试」对话框。返回 true=再战(回 runStageFlow 循环头重打本场)。
Future<bool> _showStageRetryDialog(
  BuildContext context,
  StageDef stage, {
  String? participantName,
  String? defeatReason,
}) async {
  final retry = await PaperDialog.show<bool>(
    context,
    title: UiStrings.stageRetryTitle,
    body: StageRetryDialogBody(
      participantName: participantName,
      defeatReason: defeatReason,
    ),
    actions: [
      Builder(
        builder: (ctx) => TextButton(
          style: TextButton.styleFrom(foregroundColor: WuxiaUi.muted),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(UiStrings.stageRetryBackAction),
        ),
      ),
      Builder(
        builder: (ctx) => TextButton(
          style: TextButton.styleFrom(foregroundColor: WuxiaUi.jiang),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(UiStrings.stageRetryAction),
        ),
      ),
    ],
  );
  return retry ?? false;
}

/// Mainline Boss losses remain visible after automatic defeat narratives are
/// removed. This dialog is deliberately factual: it reuses settlement entries,
/// carries no story paragraphs, and offers no build or combat advice.
Future<void> _showMainlineDefeatLossDialog(
  BuildContext context,
  List<DefeatLossEntry> entries,
) async {
  await PaperDialog.show<void>(
    context,
    title: _defeatSummaryTitle(entries),
    showSeal: false,
    barrierDismissible: false,
    body: _DefeatLossBanner(
      entries: entries,
      paperSurface: true,
      showTitle: false,
    ),
    actions: [
      Builder(
        builder: (dialogContext) => TextButton(
          style: TextButton.styleFrom(foregroundColor: WuxiaUi.jiang),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(UiStrings.mainlineDefeatLossAcknowledge),
        ),
      ),
    ],
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Phase 4 W10: Boss 战败结算
// ──────────────────────────────────────────────────────────────────────────

/// 以给定 [entries] 渲染战败损失摘要 banner（[_DefeatLossBanner] 的公开入口）。
///
/// 私有 widget 的薄暴露，供 widget 测复用，**不改任何运行时行为**
/// （真实流程仍直接 new [_DefeatLossBanner]）。
Widget buildDefeatLossBanner(List<DefeatLossEntry> entries) =>
    _DefeatLossBanner(entries: entries);

/// 展示入口只解析结算依赖，业务写入由应用层统一处理。
Future<MainlineVictorySettlement?> applyVictoryResolution({
  WidgetRef? ref,
  required StageDef stage,
  int cycle = 1,
  CombatSettlementSnapshot? settlementSnapshot,
  MainlineDurableSettlementContext? durableSettlement,
  DurableActivitySettlementContext? durableActivitySettlement,
  DurableActivityCombatSettlementDependencies? durableActivityDependencies,
  int? expectedParticipantId,
  String? rewardOccurrenceId,
  DateTime? settlementAt,
  @visibleForTesting Future<void> Function()? afterRewardWritesInTxnForTest,
}) async {
  if (durableSettlement != null && durableActivitySettlement != null) {
    throw ArgumentError(
      'Mainline and activity durable settlement contexts are exclusive',
    );
  }
  if (ref == null && durableActivityDependencies == null) {
    throw ArgumentError(
      'Settlement requires WidgetRef or durable activity dependencies',
    );
  }
  return settlement.applyVictoryResolution(
    dependencies: _mainlineSettlementDependencies(
      ref,
      durableActivityDependencies,
    ),
    stage: stage,
    cycle: cycle,
    settlementSnapshot: settlementSnapshot,
    durableSettlement: durableSettlement,
    durableActivitySettlement: durableActivitySettlement,
    expectedParticipantId: expectedParticipantId,
    rewardOccurrenceId: rewardOccurrenceId,
    settlementAt: settlementAt,
    afterRewardWritesInTxn: afterRewardWritesInTxnForTest,
  );
}

/// 展示入口保留原调用面，战败业务写入委托应用层。
Future<List<DefeatLossEntry>> applyParticipantDefeatResolution({
  WidgetRef? ref,
  required StageDef stage,
  CombatSettlementSnapshot? settlementSnapshot,
  int? expectedParticipantId,
  DateTime? settlementAt,
  DurableActivitySettlementContext? durableActivitySettlement,
  DurableActivityCombatSettlementDependencies? durableActivityDependencies,
}) async {
  if (ref == null && durableActivityDependencies == null) {
    throw ArgumentError(
      'Defeat settlement requires WidgetRef or durable activity dependencies',
    );
  }
  return settlement.applyParticipantDefeatResolution(
    dependencies: _mainlineSettlementDependencies(
      ref,
      durableActivityDependencies,
    ),
    stage: stage,
    settlementSnapshot: settlementSnapshot,
    expectedParticipantId: expectedParticipantId,
    settlementAt: settlementAt,
    durableActivitySettlement: durableActivitySettlement,
  );
}

MainlineSettlementDependencies _mainlineSettlementDependencies(
  WidgetRef? ref,
  DurableActivityCombatSettlementDependencies? durableActivityDependencies,
) {
  if (durableActivityDependencies != null) {
    return durableActivityDependencies.asMainlineDependencies(
      readPendingAffairRng: () => ref!.read(rngProvider),
      readFestivalToday: () => ref!.read(todayFestivalProvider),
    );
  }
  return MainlineSettlementDependencies(
    readClock: () => ref!.read(systemClockProvider),
    readNumbers: () => ref!.read(numbersConfigProvider),
    readDropService: () => ref!.read(dropServiceProvider),
    readRng: () => ref!.read(rngProvider),
    readMathRandom: () => ref!.read(mathRandomProvider),
    readTutorialService: () => ref!.read(tutorialServiceProvider),
    readReputationService: () => ref!.read(reputationServiceProvider),
    readFestivalToday: () => ref!.read(todayFestivalProvider),
  );
}

/// 战败损失摘要 banner（Phase 4 W10）。
///
/// 特殊模式渲染于 [NarrativeReaderScreen] 顶部；主线 Boss 事实弹层
/// 复用同一损失列表。Boss entry 显示内力与心法损失；心魔 entry
/// 仅显示角色名与内息紊乱。
class _DefeatLossBanner extends StatelessWidget {
  const _DefeatLossBanner({
    required this.entries,
    this.paperSurface = false,
    this.showTitle = true,
  });

  final List<DefeatLossEntry> entries;
  final bool paperSurface;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    // 上下文感知标题：心魔关余毒 entry 与 Boss 散功 entry 按关卡互斥，
    // 全为余毒 → 心魔反噬标题；否则（Boss 散功）→ 散功代价标题。
    final title = _defeatSummaryTitle(entries);
    final primaryColor = paperSurface ? WuxiaUi.ink : WuxiaColors.textPrimary;
    final accentColor = paperSurface ? WuxiaUi.jiang : WuxiaColors.hpLow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: paperSurface
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: WuxiaColors.hpLow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: WuxiaColors.hpLow.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          for (final e in entries) _entryLine(e, primaryColor),
          // 伤势汇总行（Task 9）：有任一 entry 重伤时追加「N 名弟子负伤」提示。
          Builder(
            builder: (context) {
              final injuredCount = entries.where((e) => e.injuryApplied).length;
              if (injuredCount == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  UiStrings.defeatInjuredDisciples(injuredCount),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _entryLine(DefeatLossEntry e, Color primaryColor) {
    if (e.residueApplied) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          [e.characterName, UiStrings.innerDemonResidueNote].join('  ·  '),
          style: TextStyle(color: primaryColor, fontSize: 12.5, height: 1.4),
        ),
      );
    }

    final injurySegment = UiStrings.defeatInjuryFacts(
      lightStacks: e.lightInjuryStacksAdded,
      heavyHours: e.heavyInjuryHoursAdded,
    );
    if (!e.hasDefeatPenalty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          UiStrings.defeatFactLine(e.characterName, injurySegment),
          style: TextStyle(color: primaryColor, fontSize: 12.5, height: 1.4),
        ),
      );
    }

    final ifSegment = UiStrings.defeatInternalForceSegment(
      e.internalForceBefore,
      e.internalForceAfter,
    );
    String? techSegment;
    if (e.techniqueName != null && e.layersRolledBack > 0) {
      techSegment = UiStrings.defeatTechniqueLayerSegment(
        e.techniqueName!,
        e.oldLayerLabel,
        e.newLayerLabel,
        e.layersRolledBack,
      );
    } else if (e.techniqueName != null) {
      techSegment = UiStrings.defeatTechniqueProgressSegment(e.techniqueName!);
    }
    // 拼接完整行文本
    final parts = [
      '${e.characterName}  $ifSegment',
      ?techSegment,
      if (e.injuryApplied) injurySegment,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        parts.join('  ·  '),
        style: TextStyle(color: primaryColor, fontSize: 12.5, height: 1.4),
      ),
    );
  }
}

String _defeatSummaryTitle(List<DefeatLossEntry> entries) {
  if (entries.every((entry) => entry.residueApplied)) {
    return UiStrings.defeatLossTitleInnerDemon;
  }
  if (entries.every((entry) => !entry.hasDefeatPenalty)) {
    return UiStrings.defeatFactTitle;
  }
  return UiStrings.defeatLossTitle;
}

Future<void> _applyBossKillReputation({
  required WidgetRef ref,
  required StageDef stage,
}) async {
  if (!stage.isBossStage || stage.factionId == null) return;
  final svc = ref.read(reputationServiceProvider);
  if (svc == null) return;
  final repo = GameRepository.instance;
  final triggers = repo.numbers.jianghu.triggers;
  final factionId = stage.factionId!;

  // Boss 所属派系 -delta
  await svc.applyDelta(1, factionId, -triggers.stageBossKillDelta);

  // 对立阵营 +rivalDelta
  final rivals = repo.rivalFactionIds(factionId);
  for (final rival in rivals) {
    await svc.applyDelta(1, rival, triggers.stageBossKillRivalDelta);
  }

  ref.invalidate(reputationsForCurrentPlayerProvider);
}

Future<Formation> pickMassBattleFormation(
  BuildContext context,
  StageDef stage,
  MassBattleDef config,
) async {
  final defaultFormation = MassBattleService.formationFor(
    stageId: stage.id,
    config: config,
  );
  if (!context.mounted) return defaultFormation;
  final picked = await showDialog<Formation>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FormationPickerDialog(defaultFormation: defaultFormation),
  );
  return picked ?? defaultFormation;
}

class _FormationPickerDialog extends StatelessWidget {
  final Formation defaultFormation;
  const _FormationPickerDialog({required this.defaultFormation});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(UiStrings.massBattleFormationTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tile(
            context,
            Formation.yanXing,
            UiStrings.massBattleFormationYanXing,
            UiStrings.massBattleFormationYanXingHint,
          ),
          _tile(
            context,
            Formation.baGua,
            UiStrings.massBattleFormationBaGua,
            UiStrings.massBattleFormationBaGuaHint,
          ),
          _tile(
            context,
            Formation.fengShi,
            UiStrings.massBattleFormationFengShi,
            UiStrings.massBattleFormationFengShiHint,
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Formation f, String label, String hint) {
    return ListTile(
      title: Text(label),
      subtitle: Text(hint, style: const TextStyle(fontSize: 12)),
      selected: f == defaultFormation,
      onTap: () => Navigator.of(context).pop(f),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// T5 首通门控纯函数（顶层，供测试锚定 production 逻辑）
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// S3 新手体验打磨：普通关战败弹框正文 widget
// ─────────────────────────────────────────────────────────────────────────────

/// 普通关战败弹框正文：提示 + 非教学化补强短诊断（S3 新手打磨）。
/// 抽成公开 widget 便于单测（对话框本体私有、测试 harness 注入替换）。
class StageRetryDialogBody extends StatelessWidget {
  const StageRetryDialogBody({
    super.key,
    this.participantName,
    this.defeatReason,
  });

  final String? participantName;
  final String? defeatReason;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (participantName != null) ...[
          Text(UiStrings.stageReportParticipant(participantName!)),
          const SizedBox(height: 8),
        ],
        if (defeatReason != null) ...[
          Text(defeatReason!, style: const TextStyle(color: WuxiaUi.jiang)),
          const SizedBox(height: 8),
        ],
        const Text(UiStrings.stageRetryPrompt),
      ],
    );
  }
}
