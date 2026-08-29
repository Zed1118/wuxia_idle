import 'dart:math';

import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/battle_shared/current_leader_resolver.dart';
import '../../battle/application/phase0a/phase0a_player_bot_adapter.dart';
import '../../battle/application/phase0a/phase0a_bot_tactic.dart';
import '../../battle/application/phase0a/phase0a_headless_runner.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_settlement_adapter.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../battle/domain/phase0a/activity_participation_request.dart';
import '../../mainline/application/mainline_participant_snapshot_service.dart';
import '../../mainline/domain/mainline_participation_policy.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../mainline/application/phase0a_mainline_encounter_host.dart';
import '../../mainline/application/phase0a_mainline_production_encounter_factory.dart';
import '../../mainline/application/phase0a_mainline_repository_runtime_binding_adapter.dart';
import '../../tower/application/tower_automation_admission.dart';

/// 扫荡消费面的 Phase 0A 同核 headless runner。
///
/// 每个单位开跑前重新从 Isar 装配祖师，确保上一场结算产生的伤势、成长和装备
/// 事实进入下一场；不缓存跨场快照。预算耗尽返回显式 timeout，caller 单独
/// 报告并 halt，不得把 ongoing 伪造成胜利 settlement。
final class Phase0aSweepRunResult {
  const Phase0aSweepRunResult.terminal(
    this.settlement, {
    this.expectedParticipantId,
    this.participantName,
    this.towerAutomationAdmission,
  }) : timedOut = false;

  const Phase0aSweepRunResult.timeout({
    this.expectedParticipantId,
    this.participantName,
    this.towerAutomationAdmission,
  }) : settlement = null,
       timedOut = true;

  final CombatSettlementSnapshot? settlement;
  final bool timedOut;
  final int? expectedParticipantId;
  final String? participantName;
  final TowerAutomationAdmission? towerAutomationAdmission;
}

final class Phase0aSweepHeadlessRunner {
  const Phase0aSweepHeadlessRunner({
    required this.isar,
    required this.numbers,
    required this.rng,
    required this.botPolicy,
    this.runtimeBindingSource,
    this.routeAuthority,
  });

  final Isar isar;
  final NumbersConfig numbers;
  final Random rng;
  final Phase0aBotTacticPolicy botPolicy;
  final Phase0aMainlineEncounterRuntimeBindingSource? runtimeBindingSource;
  final Phase0aMainlineEncounterRouteAuthority? routeAuthority;

  static const int _uiYieldEveryTicks = 32;

  Future<Phase0aSweepRunResult> runMainline({
    required StageDef stage,
    required int cycleIndex,
    ActivityEntryKind entryKind = ActivityEntryKind.sweep,
  }) async {
    if (entryKind != ActivityEntryKind.sweep &&
        entryKind != ActivityEntryKind.replay) {
      throw ArgumentError.value(
        entryKind,
        'entryKind',
        'headless mainline supports replay or sweep only',
      );
    }
    final player = await _loadMainlinePlayerSnapshot(
      stageId: stage.id,
      entryKind: entryKind,
    );
    final playerMapping = Phase0aStageContentMapper.mapPlayerOnly(
      contentId: stage.id,
      playerSnapshot: player,
      numbers: numbers,
    );
    final encounterHost = await createFreshPhase0aMainlineEncounter(
      Phase0aMainlineEncounterHostBuildRequest(
        stage: stage,
        playerMapping: playerMapping,
        numbers: numbers,
        cycleIndex: cycleIndex,
        rng: rng,
        runtimeBindingSource:
            runtimeBindingSource ??
            const Phase0aMainlineEncounterRuntimeBindingSourceAdapter(
              loader: loadPhase0aMainlineRuntimeBindingBundleFromRepository,
            ),
        routeAuthority: routeAuthority,
      ),
    );
    if (encounterHost != null) {
      final result = await encounterHost.runHeadlessAsync(
        bot: Phase0aPlayerBotAdapter(
          playerAdapter: encounterHost.mapping!.playerAdapter,
          policy: botPolicy,
          objectiveContinuationCommandBuilder:
              encounterHost.objectiveContinuationCommandBuilder,
        ),
        deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
        maxTicks: numbers.phase0aArena.maxSimulationTicks,
        yieldEveryTicks: _uiYieldEveryTicks,
      );
      if (result.timedOut) {
        return Phase0aSweepRunResult.timeout(
          expectedParticipantId: player.characterId,
          participantName: player.name,
        );
      }
      return Phase0aSweepRunResult.terminal(
        encounterHost
            .settle(
              outcome: result.outcome,
              finalState: result.finalState,
              events: result.events,
            )
            .snapshot,
        expectedParticipantId: player.characterId,
        participantName: player.name,
      );
    }
    final mapping = Phase0aStageContentMapper.map(
      stage: stage,
      playerSnapshot: player,
      numbers: numbers,
      cycleIndex: cycleIndex,
    );
    return _run(
      mapping,
      expectedParticipantId: player.characterId,
      participantName: player.name,
    );
  }

  Future<Phase0aSweepRunResult> runTower({
    required TowerFloorDef floor,
    required int cycleIndex,
    required ActivityParticipationRequest request,
  }) async {
    final admission = await TowerAutomationAdmissionService(isar).admit(
      request: request,
      floorIndex: floor.floorIndex,
      cycleIndex: cycleIndex,
    );
    final mapping = Phase0aStageContentMapper.mapTower(
      floor: floor,
      playerSnapshot: admission.snapshot,
      numbers: numbers,
      cycleIndex: cycleIndex,
    );
    return _run(
      mapping,
      expectedParticipantId: admission.participantCharacterId,
      participantName: admission.snapshot.name,
      towerAutomationAdmission: admission,
    );
  }

  Future<Phase0aSweepRunResult> _run(
    Phase0aStageMapping mapping, {
    int? expectedParticipantId,
    String? participantName,
    TowerAutomationAdmission? towerAutomationAdmission,
  }) async {
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: mapping.initialState,
      waves: mapping.waves,
      combatants: mapping.combatants,
      moveBindings: mapping.moveBindings,
      numbers: numbers,
      rng: rng,
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
      waveTransitionPolicy: mapping.waveTransitionPolicy,
    );
    final result = await Phase0aHeadlessRunner.runToEndAsync(
      flow: flow,
      bot: Phase0aPlayerBotAdapter(
        playerAdapter: mapping.playerAdapter,
        policy: botPolicy,
      ),
      deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
      maxTicks: numbers.phase0aArena.maxSimulationTicks,
      yieldEveryTicks: _uiYieldEveryTicks,
    );
    if (result.timedOut) {
      return Phase0aSweepRunResult.timeout(
        expectedParticipantId: expectedParticipantId,
        participantName: participantName,
        towerAutomationAdmission: towerAutomationAdmission,
      );
    }
    return Phase0aSweepRunResult.terminal(
      Phase0aSettlementAdapter.fromMapping(
        mapping: mapping,
        outcome: result.outcome,
        finalState: result.finalState,
        events: result.events,
      ),
      expectedParticipantId: expectedParticipantId,
      participantName: participantName,
      towerAutomationAdmission: towerAutomationAdmission,
    );
  }

  Future<CombatantSnapshot> _loadMainlinePlayerSnapshot({
    required String stageId,
    required ActivityEntryKind entryKind,
  }) async {
    final save = await isar.saveDatas.get(0);
    final progress = save == null
        ? null
        : await isar.mainlineProgress
              .filter()
              .saveDataIdEqualTo(save.slotId)
              .findFirst();
    if (progress == null || !progress.clearedStageIds.contains(stageId)) {
      throw StateError(
        'Phase0a mainline headless requires an already-cleared stage: $stageId',
      );
    }
    final playerId = await CurrentLeaderResolver.resolve(
      save: save,
      characterExists: (characterId) async =>
          await isar.characters.get(characterId) != null,
    );
    try {
      final resolved = await MainlineParticipantSnapshotService(isar).resolve(
        ActivityParticipationRequest(
          contentId: stageId,
          contentKind: ActivityContentKind.mainline,
          characterId: playerId,
          loadoutPlanId: mainlineLoadoutPlanId(
            stageId: stageId,
            characterId: playerId,
          ),
          participation: ActivityParticipationMode.direct,
          controller: ActivityController.playerBot,
          clock: ActivityClock.headless,
          entryKind: entryKind,
        ),
      );
      return resolved.snapshot;
    } on MainlineParticipationRefusedError catch (error) {
      throw StateError('Phase0a mainline headless refused: ${error.message}');
    }
  }
}
