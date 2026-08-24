import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../data/defs/stage_def.dart';
import '../../../data/defs/encounter_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/encounter_event_loader.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../data/narrative_loader.dart';
import '../../../shared/utils/math_random.dart';
import '../../../shared/utils/rng.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../combat_shared/application/combat_resolution_service.dart'
    show BattleResolutionResult, CombatResolutionService;
import '../../combat_shared/application/combat_content_providers.dart';
import '../../combat_shared/application/combat_progression_settlement_service.dart';
import '../../combat_shared/application/post_combat_invalidation.dart';
import '../../../shared/battle_shared/enum_localizations.dart' show EnumL10n;
import '../../mass_battle/application/mass_battle_service.dart';
import '../../../data/defs/mass_battle_def.dart';
import '../../../shared/strings.dart';
import '../../../shared/battle_shared/derived_stats.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../activity/application/character_occupancy_service.dart';
import '../../cultivation/domain/advancement_entry.dart';
import '../../cultivation/domain/skill_drop_result.dart';
import '../../cultivation/domain/skill_unlock_service.dart';
import '../../cultivation/presentation/skill_treasure_overlay.dart';
import '../../cultivation/presentation/stage_skill_drop_hook.dart';
import '../../encounter/presentation/encounter_hook.dart';
import '../../encounter/presentation/encounter_dialog.dart';
import '../../encounter/presentation/sect_recruit_confirm_dialog.dart';
import '../../encounter/application/encounter_service.dart';
import '../../equipment/presentation/milestone_grant_hook.dart';
import '../../jianghu/application/jianghu_providers.dart';
import '../../jianghu/application/reputation_service.dart';
import '../../festival/application/festival_service_providers.dart';
import '../../lineage/presentation/disciple_join_hook.dart';
import '../../sect/presentation/stage_boss_recruit_hook.dart';
import '../../sect/application/sect_recruit_transaction_service.dart';
import '../../equipment/application/drop_service.dart';
import '../../equipment/application/equipment_service.dart';
import '../../equipment/application/first_acquisition_tiers.dart';
import '../../equipment/domain/resonance_upgrade_notice.dart';
import '../../event/application/game_event_service.dart';
import '../../tutorial/application/tutorial_providers.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/utils/rng_provider.dart';
import '../application/mainline_progress_service.dart';
import '../application/mainline_pending_jianghu_affair_service.dart';
import '../application/mainline_providers.dart';
import '../application/mainline_run_coordinator.dart';
import '../application/mainline_settlement_journal_service.dart';
import '../application/phase0a_mainline_production_encounter_factory.dart';
import '../domain/chapter_assets.dart';
import '../domain/mainline_progress.dart';
import '../domain/mainline_pending_jianghu_affair.dart';
import '../domain/mainline_run.dart';
import '../domain/mainline_settlement_journal.dart';
import '../../combat_shared/domain/combat_stats_summary.dart';
import '../../combat_shared/presentation/hero_camera_overlay.dart'
    show HeroCameraData;
import '../../combat_shared/presentation/victory_ceremony.dart';
import '../../battle_record/application/boss_memory_hook.dart';
import '../../battle_record/application/boss_memory_service.dart';
import '../../weapon_codex/application/equipment_catalog_hook.dart';
import '../../weapon_codex/application/equipment_catalog_service.dart';
import '../../battle_record/domain/boss_memory_key.dart';
import '../../battle_record/domain/boss_memory_source.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import 'phase0a_mainline_battle_host.dart';
import 'stage_victory_dialog.dart';
import '../domain/mainline_participation_policy.dart';

typedef MainlineBattleExit = ({
  bool won,
  bool surrendered,
  CombatSettlementSnapshot? settlement,
});

typedef MainlineDurableSettlementContext = ({
  MainlineSettlementJournalService service,
  MainlineSettlementIdentity identity,
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
      playerSnapshot: visibleReplaySnapshot,
      battleRunnerForTest: battleRunnerForTest,
      battleOutcomeForTest: battleOutcomeForTest,
      phase0aBattleOutcomeForTest: phase0aBattleOutcomeForTest,
      stageRetryDeciderForTest: stageRetryDeciderForTest,
      victoryRecorderForTest: victoryRecorderForTest,
      bossDefeatPenaltyForTest: bossDefeatPenaltyForTest,
    );
    return;
  }

  final bootstrap = await _bootstrapMainlineRun(stage);
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
  final coordinator = MainlineRunCoordinator(
    executeStage: (launch) async {
      StageVictoryAction? action;
      final nextStage = _nextStageInSameChapter(launch.stage);
      final settlementService = MainlineSettlementJournalService(
        IsarSetup.instance,
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
      if (nextStage == null) {
        return MainlineStageFlowDecision.enterNextStage;
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
    initialStage: bootstrap.stage,
    initialRun: bootstrap.run,
    initialPlayerSnapshot: bootstrap.playerSnapshot,
  );
  if (result.reason ==
      MainlineRunCompletionReason.participantNotBattleEligibleForNextStage) {
    final service = MainlineSettlementJournalService(IsarSetup.instance);
    final active = await service.activeForSave(IsarSetup.currentSlotId);
    if (active != null &&
        active.phase == MainlineSettlementPhase.coreApplied &&
        active.postSettlementAction ==
            MainlinePostSettlementAction.enterNextStage) {
      await service.close(identity: active.identity, now: DateTime.now());
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
}) async {
  final save = await isar.saveDatas.get(0);
  late final int currentLeaderId;
  try {
    currentLeaderId = await CurrentLeaderResolver.resolve(
      save: save,
      characterExists: (characterId) async =>
          await isar.characters.get(characterId) != null,
    );
  } on StateError {
    // 领队指针失效是旧档/损坏态，不能绕过已冻结的领队迁移门禁继续开战。
    throw const MainlineParticipationRefusedError(
      'Current leader pointer is invalid for visible replay',
    );
  }
  final requestedIsActive =
      save?.activeCharacterIds.contains(requestedParticipantId) ?? false;
  CombatantSnapshot? snapshot;
  if (requestedIsActive) {
    try {
      snapshot = await _loadMainlineParticipantSnapshotFromIsar(
        isar: isar,
        participantId: requestedParticipantId,
      );
    } on StateError {
      // 旧档/损坏态可出现主修、装备或技能引用悬空；可见重打把该角色视为
      // 不可用并由参与政策统一拒绝，不能泄漏装配异常或回退掌门。
      snapshot = null;
    }
  }
  final selection = MainlineParticipationPolicy.resolveParticipant(
    request: ActivityParticipationRequest(
      contentId: stageId,
      contentKind: ActivityContentKind.mainline,
      characterId: requestedParticipantId,
      loadoutPlanId: 'mainline:$stageId:character:$requestedParticipantId',
      participation: ActivityParticipationMode.direct,
      controller: ActivityController.human,
      clock: ActivityClock.realtime,
      entryKind: ActivityEntryKind.replay,
    ),
    currentLeaderId: currentLeaderId,
    requestedIdleEligible: snapshot != null,
  );
  if (snapshot == null || snapshot.characterId != selection.participantId) {
    throw const MainlineParticipationRefusedError(
      'Visible replay snapshot does not match the selected participant',
    );
  }
  return snapshot;
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
  final save = await isar.saveDatas.get(0);
  final participantId = await CurrentLeaderResolver.resolve(
    save: save,
    characterExists: (characterId) async =>
        await isar.characters.get(characterId) != null,
  );
  final playerSnapshot = await _loadMainlineParticipantSnapshot(participantId);
  if (playerSnapshot == null) return null;
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

/// 在主结算事务内决定本关待处理江湖事。
///
/// caller 必须持有 `isar.writeTxn`；返回的 typed refs 由结算
/// journal 与核心结算同事务持久化。顺序与旧生产链一致：
/// 奇遇在前，Boss 招降在后。
@visibleForTesting
Future<List<MainlinePendingJianghuAffairRef>>
planMainlinePendingJianghuAffairsInTxn({
  required Isar isar,
  required MainlineSettlementIdentity identity,
  required StageDef stage,
  required int saveDataId,
  required EncounterService encounterService,
  required List<EncounterDef> encounters,
  required Rng rng,
  Festival? festivalToday,
}) async {
  final refs = <MainlinePendingJianghuAffairRef>[];
  final save = await isar.saveDatas.get(0);
  final founder = await isar.characters.get(identity.participantId);

  if (stage.enemyTeam.isNotEmpty && founder != null && encounters.isNotEmpty) {
    final encounter = await encounterService.evaluateTriggers(
      saveDataId: saveDataId,
      attributes: founder.attributes,
      encounters: encounters,
      rng: rng,
      festivalToday: festivalToday,
    );
    if (encounter != null) {
      final sourceId = 'encounter:${encounter.id}';
      refs.add(
        MainlinePendingJianghuAffairRef.encounterChoice(
          settlementId: identity.canonical,
          encounterId: encounter.id,
          ordinal: refs.length + 1,
          resolutionSeed: _stablePendingAffairSeed(
            '${identity.canonical}|$sourceId',
          ),
        ),
      );
    }
  }

  final bossRecruit = stage.bossRecruit;
  final bossAlreadyTriggered =
      save?.triggeredBossRecruitStageIds.contains(stage.id) ?? false;
  if (stage.isBossStage &&
      bossRecruit != null &&
      save != null &&
      !bossAlreadyTriggered &&
      GameRepository.instance.sectCandidates.containsKey(
        bossRecruit.candidateRef,
      ) &&
      rng.nextDouble() < bossRecruit.baseProbability) {
    final sourceId =
        'stage-boss-recruit:${stage.id}:${bossRecruit.candidateRef}';
    refs.add(
      MainlinePendingJianghuAffairRef.stageBossRecruit(
        settlementId: identity.canonical,
        stageId: stage.id,
        candidateRef: bossRecruit.candidateRef,
        ordinal: refs.length + 1,
        resolutionSeed: _stablePendingAffairSeed(
          '${identity.canonical}|$sourceId',
        ),
      ),
    );
  }
  return List.unmodifiable(refs);
}

int _stablePendingAffairSeed(String value) {
  var hash = 0x811c9dc5;
  for (final byte in value.codeUnits) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final positive = hash & 0x7fffffff;
  return positive == 0 ? 1 : positive;
}

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
  bool allowEnterNextStage = false,
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
      MainlinePostSettlementAction.none => null,
    };
    if (action == null) {
      if (!context.mounted) return;
      action = await showRecoveredStageSettlementDialog(
        context: context,
        stage: stage,
        allowEnterNextStage: allowEnterNextStage,
      );
      await durableSettlement.service.recordPostSettlementAction(
        identity: durableSettlement.identity,
        action: action == StageVictoryAction.enterNextStage
            ? MainlinePostSettlementAction.enterNextStage
            : MainlinePostSettlementAction.returnToMap,
        now: DateTime.now(),
      );
    }
    if (action == StageVictoryAction.returnToMap || !allowEnterNextStage) {
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
          : await _applyBossDefeatPenalty(
              ref: ref,
              stage: stage,
              settlementSnapshot: battleExit.settlement,
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
                ? await _showStageRetryDialog(context, stage)
                : false);
      if (retry) continue;
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
  if (durableSettlement != null) {
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
    final svc = MainlineProgressService(isar: IsarSetup.instance);
    final progress = await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
    clearedBeforeVictory.addAll(progress.clearedStageIds);
    await svc.recordVictory(
      stageId: stage.id,
      now: DateTime.now(),
      tutorialService: ref.read(tutorialServiceProvider),
      cycle: targetCycle,
    );
    ref.invalidate(mainlineProgressProvider);
    ref.invalidate(currentTutorialStepProvider);

    // 可玩性 P1a:Boss 胜利掉技能书(真解首通/残页概率)· spec §二。
    // 纯数据写(无 UI);随生产进度记录路径执行(test stub 路径 victoryRecorderForTest
    // 跳过,与 recordVictory 一致 —— 不依赖未初始化的 IsarSetup)。
    skillDrop = await runStageSkillDropHookAfterVictory(
      stage: stage,
      svc: SkillUnlockService(
        IsarSetup.instance,
        fragmentThreshold:
            GameRepository.instance.numbers.skillUnlock.fragmentThreshold,
      ),
      clearedStageIds: clearedBeforeVictory,
      towerFragmentDropProb:
          GameRepository.instance.numbers.skillUnlock.towerFragmentDropProb,
      rng: ref.read(mathRandomProvider),
    );

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
    final victoryAction = await showStageVictoryDialog(
      context: context,
      stage: stage,
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
      durableVictoryAction = victoryAction;
      await durableSettlement.service.recordPostSettlementAction(
        identity: durableSettlement.identity,
        action: victoryAction == StageVictoryAction.enterNextStage
            ? MainlinePostSettlementAction.enterNextStage
            : MainlinePostSettlementAction.returnToMap,
        now: DateTime.now(),
      );
    } else {
      victoryActionSink?.call(victoryAction);
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

  // F1 里程碑装备授予 hook:群战/心魔首通终点关 → 授 special 装备进背包。
  // 在 recordVictory(clearedStageIds 写入)之后;service 内幂等防重,
  // 非里程碑关 / 已授予 no-op。静默入袋无特效。
  await runMilestoneGrantHookAfterVictory(stageId: stage.id);

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
    if (action == StageVictoryAction.returnToMap || !allowEnterNextStage) {
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
          showEncounterOutcomeBanner(context: context, applied: applied);
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
          showEncounterOutcomeBanner(
            context: context,
            applied: fallbackApplied!,
          );
        }
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
}) async {
  return _runPhase0aBattle(
    context: context,
    stage: stage,
    targetCycle: targetCycle,
    playerSnapshot: playerSnapshot,
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
}) async {
  final massBattleFormation = stage.stageType == StageType.massBattle
      ? await _pickFormation(
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
            massBattleFormation: massBattleFormation,
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
Future<bool> _showStageRetryDialog(BuildContext context, StageDef stage) async {
  final retry = await PaperDialog.show<bool>(
    context,
    title: UiStrings.stageRetryTitle,
    body: const StageRetryDialogBody(),
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
    title: UiStrings.defeatLossTitle,
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

/// 损失摘要 entry：用于 [_DefeatLossBanner] 渲染单角色一行。
class DefeatLossEntry {
  final String characterName;
  final int internalForceBefore;
  final int internalForceAfter;
  final String? techniqueName;
  final String? oldLayerLabel;
  final String? newLayerLabel;
  final int layersRolledBack;

  /// 心魔惩罚标记：true 表示角色遭受心魔失败后的内息紊乱，
  /// UI 仅陈述角色名与该状态。
  /// Boss 散功 entry 默认 false。
  final bool residueApplied;

  /// 双层伤势重伤标记（Task 9）：战败后该角色是否获得重伤（injuryHoursRemaining>0）。
  /// 用于 [_DefeatLossBanner] 汇总显示受伤弟子数量。
  final bool injuryApplied;

  const DefeatLossEntry({
    required this.characterName,
    required this.internalForceBefore,
    required this.internalForceAfter,
    this.techniqueName,
    this.oldLayerLabel,
    this.newLayerLabel,
    this.layersRolledBack = 0,
    this.residueApplied = false,
    this.injuryApplied = false,
  });
}

/// 从 [BattleResolutionResult] 构造损失摘要 entry 列表（纯函数，不访问 Isar）。
///
/// 处理两类惩罚（互斥但共享同一函数以便测试）：
///   1. Boss 散功（[BattleResolutionResult.defeatPenaltyByCharacter]）→
///      显示内力回退 + 层数回退，residueApplied=false。
///   2. 心魔惩罚（[BattleResolutionResult.innerDemonPenaltyByCharacter]）→
///      保留领域结算证据，摘要仅显示角色名与内息紊乱，
///      不声称内力区间或修炼度回退，residueApplied=true。
///   3. 双层伤势重伤（Task 9）：仅普通 Boss entry 投影本次伤势；
///      心魔 entry 不把入场前既有伤势算成本次后果。
@visibleForTesting
List<DefeatLossEntry> buildDefeatLossEntries({
  required List<Character> characters,
  required Map<int, List<Technique>> techsByCh,
  required BattleResolutionResult result,
}) {
  final entries = <DefeatLossEntry>[];

  // Boss 散功 entries
  for (final ch in characters) {
    final p = result.defeatPenaltyByCharacter[ch.id];
    if (p == null) continue;
    final techName = _resolveTechName(ch, techsByCh);
    entries.add(
      DefeatLossEntry(
        characterName: ch.name,
        internalForceBefore: p.internalForceBefore,
        internalForceAfter: p.internalForceAfter,
        techniqueName: techName,
        oldLayerLabel: p.didRollback
            ? EnumL10n.cultivationLayer(p.oldLayer)
            : null,
        newLayerLabel: p.didRollback
            ? EnumL10n.cultivationLayer(p.newLayer)
            : null,
        layersRolledBack: p.layersRolledBack,
        residueApplied: false,
        injuryApplied: ch.injuryHoursRemaining > 0,
      ),
    );
  }

  // 心魔惩罚 entries（不掉层，仅陈述本次新增的内息紊乱）
  for (final ch in characters) {
    final ip = result.innerDemonPenaltyByCharacter[ch.id];
    if (ip == null) continue;
    final techName = _resolveTechName(ch, techsByCh);
    entries.add(
      DefeatLossEntry(
        characterName: ch.name,
        internalForceBefore: ip.internalForceBefore,
        internalForceAfter: ip.internalForceAfter,
        techniqueName: techName,
        oldLayerLabel: null,
        newLayerLabel: null,
        layersRolledBack: 0,
        residueApplied: true,
        // 心魔失败不会新增伤势。角色入场前已有的伤势不能被误报为
        // 本次失败后果；普通 Boss 的伤势投影仍由上方独立分支处理。
        injuryApplied: false,
      ),
    );
  }

  return entries;
}

/// 以给定 [entries] 渲染战败损失摘要 banner（[_DefeatLossBanner] 的公开入口）。
///
/// 私有 widget 的薄暴露，供 widget 测复用，**不改任何运行时行为**
/// （真实流程仍直接 new [_DefeatLossBanner]）。
Widget buildDefeatLossBanner(List<DefeatLossEntry> entries) =>
    _DefeatLossBanner(entries: entries);

/// 从 [techsByCh] 中解析角色主修心法的 defId 对应名称。
/// 找不到或 GameRepository 未载入时返回 null（安全兜底）。
String? _resolveTechName(Character ch, Map<int, List<Technique>> techsByCh) {
  final mainTechId = ch.mainTechniqueId;
  if (mainTechId == null) return null;
  final techs = techsByCh[ch.id];
  if (techs == null || techs.isEmpty) return null;
  final mainTech = techs.firstWhere(
    (t) => t.id == mainTechId,
    orElse: () => techs.first,
  );
  try {
    return GameRepository.instance.getTechnique(mainTech.defId).name;
  } catch (e, st) {
    debugPrint('resolve main technique name failed: $e\n$st');
    return null;
  }
}

/// Phase 4 W11 #32 销账：主线 victory 路径战斗结算。
///
/// 从 Isar 拉玩家方角色 + 心法 + 装备 → 跑 [BattleResolutionService.resolve]
/// （胜负由 `finalState.result` 派生）→ in-place battleCount/skillUsage/cultivationProgress 累积 +
/// stage.dropTable roll 出装备/物品 → writeTxn putAll + 装备 owner=null 入背包 +
/// items 写/更新 inventoryItems。
///
/// **错误兜底**：Isar 未 ready / 角色为空 / finalState 异常 → 返回 null，
/// caller 跳过 victory dialog（与 _applyBossDefeatPenalty 一致风格）。
///
/// W15 #30 P3 后续 A:返回 `(drops, advancements)` 供 caller push
/// [showStageVictoryDialog] 显 drop + 升层 banner。
/// P1.1 候选 3-a:record 加 `resonanceUpgrades` 供 dialog 显共鸣度晋阶 sub-row。
Future<
  ({
    DropResult drops,
    List<AdvancementEntry> advancements,
    List<ResonanceUpgradeNotice> resonanceUpgrades,
    CombatStatsSummary stats,
    HeroCameraData? heroCamera,
    Set<EquipmentTier> extraDisplayTiers,
    List<Character> characters,
    SkillDropResult skillDrop,
  })?
>
applyVictoryResolution({
  required WidgetRef ref,
  required StageDef stage,
  int cycle = 1,
  CombatSettlementSnapshot? settlementSnapshot,
  MainlineDurableSettlementContext? durableSettlement,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return null;
  final combatSettlement = settlementSnapshot;
  if (combatSettlement == null) return null;
  if (!combatSettlement.isFinished) return null;
  final stats = CombatStatsSummary.fromSettlement(combatSettlement);

  final save = await isar.saveDatas.get(0);
  final participantIds = combatSettlement.participantCharacterIds;
  final ids = (save?.activeCharacterIds ?? const <int>[])
      .where(participantIds.contains)
      .toList(growable: false);
  if (ids.isEmpty) return null;

  final characters = <Character>[];
  final equipsByCh = <int, List<Equipment>>{};
  final techsByCh = <int, List<Technique>>{};
  for (final cid in ids) {
    final c = await isar.characters.get(cid);
    if (c == null) continue;
    characters.add(c);

    final eqs = <Equipment>[];
    for (final eqId in [
      c.equippedWeaponId,
      c.equippedArmorId,
      c.equippedAccessoryId,
    ]) {
      if (eqId == null) continue;
      final e = await isar.equipments.get(eqId);
      if (e != null) eqs.add(e);
    }
    equipsByCh[c.id] = eqs;

    final ts = await isar.techniques
        .where()
        .filter()
        .ownerCharacterIdEqualTo(c.id)
        .findAll();
    // W13 fix: Isar @embedded list 反序列化为 fixed-length,
    // skillUsageCount.increment 走 add 分支会抛 UnsupportedError。
    // 转 growable copy 让后续 _accumulateSkillUsage 可写。
    for (final t in ts) {
      t.skillUsageCount = List.of(t.skillUsageCount);
    }
    techsByCh[c.id] = ts;
  }
  if (characters.isEmpty) return null;

  final numbers = ref.read(numbersConfigProvider);
  final dropSvc = ref.read(dropServiceProvider);

  if (durableSettlement != null) {
    await MainlineProgressService(
      isar: isar,
    ).getOrCreate(saveDataId: IsarSetup.currentSlotId);
    await EncounterService(
      isar: isar,
      attributeGainCap: numbers.adventureAttributeLifetimeCap,
      attributeEffects: numbers.attributeEffects,
    ).getOrCreate(saveDataId: IsarSetup.currentSlotId);
  }

  final result = CombatResolutionService.resolveSnapshot(
    settlement: combatSettlement,
    participatingCharacters: characters,
    equipmentsByCharacter: equipsByCh,
    techniquesByCharacter: techsByCh,
    stageDef: stage,
    // 随机源走 rngProvider(不 inline new):稀有彩头 roll 在此链路上,
    // inline 的 DefaultRng 测试 override 不到,会把精确掉落数断言打成随机红。
    rng: ref.read(rngProvider),
    progressToNextMap: numbers.cultivationProgressToNext,
    techniqueDefLookup: GameRepository.instance.getTechnique,
    dropService: dropSvc,
    numbersConfig: numbers,
    // 双层伤势：Boss/心魔关算硬仗，resolve 内部据此判定伤势 mutate character。
    // 受影响 character 经下方 writeTxn putAll(characters) 自然落库，无需额外 txn。
    isHardFight: stage.isBossStage,
    // 第八阶段 E·稀有彩头:阶池 + realm→装备阶映射注入(本关固定掉落外额外 roll)。
    equipmentPoolByTier: (tier) => GameRepository.instance.equipmentDefs.values
        .where((e) => e.tier == tier)
        .toList(growable: false),
    equipmentTierForRealm: RealmUtils.equipmentTierCapOf,
    // 周目平衡 2026-06-26:二周目起提高稀有彩头概率 + 普通掉落材料加成。
    cycle: cycle,
  );

  // P1 #42 Phase 2:isFirstClear snapshot(writeTxn 之前 read MainlineProgress,
  // 含 stageId 即 repeat,不含即首通 → bossDefeated 防刷)。
  final mainlineProgressSnapshot = await isar.mainlineProgress
      .filter()
      .saveDataIdEqualTo(IsarSetup.currentSlotId)
      .findFirst();
  final clearedSet =
      mainlineProgressSnapshot?.clearedStageIds.toSet() ?? <String>{};
  final settlement = CombatProgressionSettlementService(
    GameRepository.instance,
  );
  // 主线重打仍发经验；首通门控只约束掉落与 Boss 事件。
  final advancements = settlement.applyExperience(
    characters: characters,
    experienceReward: stage.baseExpReward,
    clearedStageIds: clearedSet,
  );
  final isFirstClearStage =
      !(mainlineProgressSnapshot?.clearedStageIds.contains(stage.id) ?? false);
  final founderId = save?.founderCharacterId;
  final battleEventOwnerId = characters.length == 1
      ? characters.single.id
      : founderId;

  // P1.1 候选 3-a:writeTxn 内 push notice,函数末 return 给 caller 传 dialog。
  var resonanceUpgrades = const <ResonanceUpgradeNotice>[];
  var skillDrop = SkillDropResult.none;

  final bossName = stage.enemyTeam.isNotEmpty
      ? stage.enemyTeam.last.name
      : stage.name;
  final heroCamera = deriveHeroCameraDataFromDamageTotals(
    damageByCharacterId: combatSettlement.damageByCharacterId,
    characters: characters,
    bossName: bossName,
  );

  final now = DateTime.now();
  final durableTutorialService = durableSettlement == null
      ? null
      : ref.read(tutorialServiceProvider);
  final durableSkillDropRng = durableSettlement == null
      ? null
      : ref.read(mathRandomProvider);
  final durableReputation = durableSettlement == null
      ? null
      : ref.read(reputationServiceProvider);
  Future<void> persistResolutionInTxn() async {
    // in-place 副作用（battleCount / skillUsage / 主修 progress + layer + EXP）
    await isar.characters.putAll(characters);
    for (final list in techsByCh.values) {
      if (list.isNotEmpty) await isar.techniques.putAll(list);
    }
    for (final list in equipsByCh.values) {
      if (list.isNotEmpty) await isar.equipments.putAll(list);
    }
    // drops：装备 owner=null 入背包 + items 写/更新 inventoryItems
    if (result.dropResult.equipments.isNotEmpty) {
      await isar.equipments.putAll(result.dropResult.equipments);
    }
    for (final item in result.dropResult.items) {
      // T5 首通必得门控：秘籍(item_scroll_*) 仅首通写入背包，重打跳过。
      // 银两/经验丹等其余 item 继续每次掉落，不受此 gate 影响。
      // isFirstClearStage 在 writeTxn 之前快照(本函数 L~800)，首通语义正确；
      // 勿将此 continue 挪到 recordVictory/clearedStageIds 写入之后，否则首通亦被 gate。
      if (shouldSkipScrollDrop(item.defId, isFirstClear: isFirstClearStage)) {
        continue;
      }
      final existing = await isar.inventoryItems.getByDefId(item.defId);
      if (existing != null) {
        existing.quantity += item.quantity;
        existing.lastObtainedAt = now;
        await isar.inventoryItems.put(existing);
      } else {
        await isar.inventoryItems.put(
          InventoryItem()
            ..defId = item.defId
            ..itemType = _itemTypeOfMainline(item.defId)
            ..quantity = item.quantity
            ..firstObtainedAt = now
            ..lastObtainedAt = now,
        );
      }
    }

    // 主线专属 equipmentObtained 与公共成长事件在同一事务写入。
    final events = GameEventService(isar);
    for (final drop in result.dropResult.equipments) {
      final def = GameRepository.instance.getEquipment(drop.defId);
      await events.recordEquipmentObtained(
        characterId: battleEventOwnerId,
        equipmentId: drop.id,
        equipmentDefId: drop.defId,
        equipmentName: def.name,
        source: stage.name,
        equipment: drop,
      );
    }
    resonanceUpgrades = await settlement.recordCommonEvents(
      isar: isar,
      characters: characters,
      equipmentsByCharacter: equipsByCh,
      resonanceUpgradedEquipmentIds: result.resonanceUpgradedEquipmentIds,
      advancements: advancements,
      founderId: founderId,
      bossVictory: stage.isBossStage && isFirstClearStage
          ? BossVictoryEventContext(
              stageId: stage.id,
              stageName: stage.name,
              bossName: stage.enemyTeam.isNotEmpty
                  ? stage.enemyTeam.last.name
                  : stage.name,
              warbornEquipment: founderId == null
                  ? const []
                  : equipsByCh[founderId] ?? const [],
            )
          : null,
    );

    if (durableSettlement == null) return;

    await MainlineProgressService(isar: isar).recordVictoryInTxn(
      saveDataId: IsarSetup.currentSlotId,
      stageId: stage.id,
      now: now,
      tutorialService: durableTutorialService,
      cycle: cycle,
    );
    skillDrop = await runStageSkillDropHookAfterVictoryInTxn(
      stage: stage,
      svc: SkillUnlockService(
        isar,
        fragmentThreshold: numbers.skillUnlock.fragmentThreshold,
      ),
      clearedStageIds: clearedSet,
      towerFragmentDropProb: numbers.skillUnlock.towerFragmentDropProb,
      rng: durableSkillDropRng!,
    );
    await EquipmentCatalogService(isar: isar).recordAcquisitionsInTxn(
      saveDataId: IsarSetup.currentSlotId,
      defIds: [
        for (final equipment in result.dropResult.equipments) equipment.defId,
      ],
      from: stage.name,
      now: now,
    );
    await EncounterService(
      isar: isar,
      attributeGainCap: numbers.adventureAttributeLifetimeCap,
      attributeEffects: numbers.attributeEffects,
    ).recordKillInTxn(
      saveDataId: IsarSetup.currentSlotId,
      defeatedSchools: stage.enemyTeam
          .map((enemy) => enemy.school)
          .toList(growable: false),
    );

    if (stage.isBossStage) {
      final rosterNames = <String>[];
      final rosterPortraits = <String>[];
      for (final characterId in save?.activeCharacterIds ?? const <int>[]) {
        final character = await isar.characters.get(characterId);
        if (character == null) continue;
        rosterNames.add(character.name);
        rosterPortraits.add(character.portraitPath ?? '');
      }
      String? treasureName;
      EquipmentTier? treasureTier;
      if (result.dropResult.equipments.isNotEmpty) {
        final best = result.dropResult.equipments.reduce(
          (left, right) => left.tier.index >= right.tier.index ? left : right,
        );
        treasureTier = best.tier;
        treasureName =
            GameRepository.instance.equipmentDefs[best.defId]?.name ??
            best.defId;
      }
      await BossMemoryService(isar: isar).recordBossVictoryInTxn(
        saveDataId: IsarSetup.currentSlotId,
        bossKey: mainlineBossKey(stage.id),
        source: BossMemorySource.mainline,
        groupIndex: mainlineGroupIndex(stage.id),
        bossName: bossName,
        totalDamage: stats.totalDamage,
        critCount: stats.critCount,
        totalTicks: stats.totalTicks,
        topContributorName: heroCamera?.heroName,
        topContributorDamage: heroCamera?.topDamage,
        treasureName: treasureName,
        treasureTier: treasureTier,
        rosterNames: rosterNames,
        rosterPortraits: rosterPortraits,
        now: now,
      );
    }

    final reputation = durableReputation;
    if (stage.isBossStage && stage.factionId != null && reputation != null) {
      final triggers = numbers.jianghu.triggers;
      await reputation.applyDeltaInTxn(
        1,
        stage.factionId!,
        -triggers.stageBossKillDelta,
        now: now,
      );
      for (final rival in GameRepository.instance.rivalFactionIds(
        stage.factionId!,
      )) {
        await reputation.applyDeltaInTxn(
          1,
          rival,
          triggers.stageBossKillRivalDelta,
          now: now,
        );
      }
    }
  }

  if (durableSettlement == null) {
    await isar.writeTxn(persistResolutionInTxn);
  } else {
    final disposition =
        await MainlinePendingJianghuAffairService(
          durableSettlement.service,
        ).commitCore(
          identity: durableSettlement.identity,
          now: now,
          applyInTxn: () async {
            await persistResolutionInTxn();
            return planMainlinePendingJianghuAffairsInTxn(
              isar: isar,
              identity: durableSettlement.identity,
              stage: stage,
              saveDataId: IsarSetup.currentSlotId,
              encounterService: EncounterService(
                isar: isar,
                attributeGainCap: numbers.adventureAttributeLifetimeCap,
                attributeEffects: numbers.attributeEffects,
              ),
              encounters: GameRepository.instance.allEncounters,
              rng: ref.read(rngProvider),
              festivalToday: ref.read(todayFestivalProvider),
            );
          },
        );
    if (disposition != MainlineCoreCommitDisposition.applied) {
      throw StateError('Mainline settlement core was already applied');
    }
  }

  // 第七阶段 批一 Task 6:计算利器首次获得的 extraDisplayTiers
  // (须在 putAll 入库后调用,判据:库存总数 ≤ 本次掉落件数)。
  final extraDisplayTiers = await computeFirstAcquisitionTiers(
    isar,
    result.dropResult,
  );

  // 兵器谱：新掉落装备已落库(上方 writeTxn putAll(result.dropResult.equipments)
  // 已 commit),留册图鉴(best-effort)。
  if (durableSettlement == null) {
    await runEquipmentCatalogHookAfterObtain(
      defIds: [for (final e in result.dropResult.equipments) e.defId],
      from: stage.name,
    );
  }

  return (
    drops: result.dropResult,
    advancements: advancements,
    resonanceUpgrades: resonanceUpgrades,
    stats: stats,
    heroCamera: heroCamera,
    extraDisplayTiers: extraDisplayTiers,
    characters: List<Character>.unmodifiable(characters),
    skillDrop: skillDrop,
  );
}

/// 主线 victory drop items 的 ItemType 推断。
/// 委托 [ItemType.fromDefId]，避免双真相源；新增 defId 只需在 fromDefId 维护。
ItemType _itemTypeOfMainline(String defId) => ItemType.fromDefId(defId);

/// Boss 关战败：从 Isar 拉玩家方角色 + 心法 + 装备，跑
/// [BattleResolutionService.resolve]（败北由 `finalState.result` 派生），写回 Isar，返回
/// 用于 UI 损失摘要展示的轻量结构。
///
/// **错误兜底**：Isar 未 ready / 角色为空 / finalState 异常 → 返回空 list，
/// caller 不展示 banner（不阻塞剧情流）。
Future<List<DefeatLossEntry>> _applyBossDefeatPenalty({
  required WidgetRef ref,
  required StageDef stage,
  CombatSettlementSnapshot? settlementSnapshot,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return const [];
  final combatSettlement = settlementSnapshot;
  if (combatSettlement == null) return const [];
  if (!combatSettlement.isFinished) return const [];

  final save = await isar.saveDatas.get(0);
  final participantIds = combatSettlement.participantCharacterIds;
  final ids = (save?.activeCharacterIds ?? const <int>[])
      .where(participantIds.contains)
      .toList(growable: false);
  if (ids.isEmpty) return const [];

  final characters = <Character>[];
  final equipsByCh = <int, List<Equipment>>{};
  final techsByCh = <int, List<Technique>>{};
  for (final cid in ids) {
    final c = await isar.characters.get(cid);
    if (c == null) continue;
    characters.add(c);

    final eqs = <Equipment>[];
    for (final eqId in [
      c.equippedWeaponId,
      c.equippedArmorId,
      c.equippedAccessoryId,
    ]) {
      if (eqId == null) continue;
      final e = await isar.equipments.get(eqId);
      if (e != null) eqs.add(e);
    }
    equipsByCh[c.id] = eqs;

    final ts = await isar.techniques
        .where()
        .filter()
        .ownerCharacterIdEqualTo(c.id)
        .findAll();
    // W13 fix: Isar @embedded list 反序列化为 fixed-length（同 _applyVictoryResolution）
    for (final t in ts) {
      t.skillUsageCount = List.of(t.skillUsageCount);
    }
    techsByCh[c.id] = ts;
  }
  if (characters.isEmpty) return const [];

  final numbers = ref.read(numbersConfigProvider);
  final dropSvc = ref.read(dropServiceProvider);

  final result = CombatResolutionService.resolveSnapshot(
    settlement: combatSettlement,
    participatingCharacters: characters,
    equipmentsByCharacter: equipsByCh,
    techniquesByCharacter: techsByCh,
    stageDef: stage,
    // 同胜利路径:随机源走 rngProvider,保持可注入(战败结算亦有 rng 消费)。
    rng: ref.read(rngProvider),
    progressToNextMap: numbers.cultivationProgressToNext,
    techniqueDefLookup: GameRepository.instance.getTechnique,
    dropService: dropSvc,
    numbersConfig: numbers,
    // 双层伤势：Boss/心魔关算硬仗，战败同样可累伤势。
    // 受影响 character 经下方 writeTxn putAll(characters) 自然落库。
    isHardFight: stage.isBossStage,
  );

  // 写回 Isar：受影响的 character + 所有 technique + 所有装备
  await isar.writeTxn(() async {
    await isar.characters.putAll(characters);
    for (final list in techsByCh.values) {
      if (list.isNotEmpty) await isar.techniques.putAll(list);
    }
    for (final list in equipsByCh.values) {
      if (list.isNotEmpty) await isar.equipments.putAll(list);
    }
  });

  // 构造损失摘要（Boss 散功 + 心魔惩罚）
  return buildDefeatLossEntries(
    characters: characters,
    techsByCh: techsByCh,
    result: result,
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
    final title = entries.every((e) => e.residueApplied)
        ? UiStrings.defeatLossTitleInnerDemon
        : UiStrings.defeatLossTitle;
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
    final parts = ['${e.characterName}  $ifSegment', ?techSegment];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        parts.join('  ·  '),
        style: TextStyle(color: primaryColor, fontSize: 12.5, height: 1.4),
      ),
    );
  }
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

Future<Formation> _pickFormation(
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

/// 秘籍(item_scroll_*)首通必得：重打(非首通)跳过写入，避免重复掉。
/// 银两/装备/经验丹不受此 gate 影响（前缀不匹配，返回 false）。
@visibleForTesting
bool shouldSkipScrollDrop(String defId, {required bool isFirstClear}) =>
    isTechniqueScrollDefId(defId) && !isFirstClear;

// ─────────────────────────────────────────────────────────────────────────────
// S3 新手体验打磨：普通关战败弹框正文 widget
// ─────────────────────────────────────────────────────────────────────────────

/// 普通关战败弹框正文：提示 + 非教学化补强短诊断（S3 新手打磨）。
/// 抽成公开 widget 便于单测（对话框本体私有、测试 harness 注入替换）。
class StageRetryDialogBody extends StatelessWidget {
  const StageRetryDialogBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(UiStrings.stageRetryPrompt),
        SizedBox(height: 8),
        Text(
          UiStrings.stageRetryHintLine,
          style: TextStyle(color: WuxiaUi.muted, fontSize: 13),
        ),
      ],
    );
  }
}
