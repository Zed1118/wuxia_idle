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
import '../../activity/application/character_occupancy_service.dart';
import '../../activity/domain/activity_occupancy.dart';
import '../../battle/application/phase0a/phase0a_player_bot_adapter.dart';
import '../../battle/application/phase0a/phase0a_headless_runner.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_settlement_adapter.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';

/// 扫荡消费面的 Phase 0A 同核 headless runner。
///
/// 每个单位开跑前重新从 Isar 装配祖师，确保上一场结算产生的伤势、成长和装备
/// 事实进入下一场；不缓存跨场快照。预算耗尽返回显式 timeout，caller 单独
/// 报告并 halt，不得把 ongoing 伪造成胜利 settlement。
final class Phase0aSweepRunResult {
  const Phase0aSweepRunResult.terminal(this.settlement) : timedOut = false;

  const Phase0aSweepRunResult.timeout() : settlement = null, timedOut = true;

  final CombatSettlementSnapshot? settlement;
  final bool timedOut;
}

final class Phase0aSweepHeadlessRunner {
  const Phase0aSweepHeadlessRunner({
    required this.isar,
    required this.numbers,
    required this.rng,
  });

  final Isar isar;
  final NumbersConfig numbers;
  final Random rng;

  static const int _uiYieldEveryTicks = 32;

  Future<Phase0aSweepRunResult> runMainline({
    required StageDef stage,
    required int cycleIndex,
  }) async {
    final player = await _loadPlayerSnapshot();
    final mapping = Phase0aStageContentMapper.map(
      stage: stage,
      playerSnapshot: player,
      numbers: numbers,
      cycleIndex: cycleIndex,
    );
    return _run(mapping);
  }

  Future<Phase0aSweepRunResult> runTower({
    required TowerFloorDef floor,
    required int cycleIndex,
  }) async {
    final player = await _loadPlayerSnapshot();
    final mapping = Phase0aStageContentMapper.mapTower(
      floor: floor,
      playerSnapshot: player,
      numbers: numbers,
      cycleIndex: cycleIndex,
    );
    return _run(mapping);
  }

  Future<Phase0aSweepRunResult> _run(Phase0aStageMapping mapping) async {
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
      bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
      deltaSeconds: numbers.phase0aArena.fixedDeltaSeconds,
      maxTicks: numbers.phase0aArena.maxSimulationTicks,
      yieldEveryTicks: _uiYieldEveryTicks,
    );
    if (result.timedOut) {
      return const Phase0aSweepRunResult.timeout();
    }
    return Phase0aSweepRunResult.terminal(
      Phase0aSettlementAdapter.fromMapping(
        mapping: mapping,
        outcome: result.outcome,
        finalState: result.finalState,
        events: result.events,
      ),
    );
  }

  Future<CombatantSnapshot> _loadPlayerSnapshot() async {
    final save = await isar.saveDatas.get(0);
    final playerId = await CurrentLeaderResolver.resolve(
      save: save,
      characterExists: (characterId) async =>
          await isar.characters.get(characterId) != null,
    );
    final occupancy = await CharacterOccupancyService(isar).snapshot();
    final activity = occupancy.activityOf(playerId);
    if (activity == ActivityKind.expedition ||
        activity == ActivityKind.bossGauntlet) {
      throw StateError('Phase0a sweep founder is dispatched: $activity');
    }
    final roster = await PlayerCombatantSnapshotAssembler(
      isar: isar,
    ).loadExactRoster([playerId]);
    if (roster.isEmpty) {
      throw StateError('Phase0a 扫荡: 玩家队伍装配为空');
    }
    return roster.first;
  }
}
