import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../../../data/game_repository.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../battle/application/phase0a/phase0a_headless_runner.dart';
import '../../battle/application/phase0a/phase0a_player_bot_adapter.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../battle/application/player_combatant_snapshot_assembler.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../domain/expedition_node.dart';
import 'expedition_combat.dart';

/// 远征的单角色 Phase 0A combat adapter；离线事务与奖励仍由 ExpeditionService 所有。
final class Phase0aExpeditionCombatRunner implements ExpeditionCombat {
  Phase0aExpeditionCombatRunner(this._isar);

  final Isar _isar;
  List<CombatantSnapshot>? _baseTeam;

  static const int _uiYieldEveryTicks = 32;

  Future<List<CombatantSnapshot>> _base(List<int> ids) async => _baseTeam ??=
      await PlayerCombatantSnapshotAssembler(isar: _isar).loadExactRoster(ids);

  @override
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(List<int> ids) async {
    if (ids.length != 1) {
      throw StateError('Phase0a expedition requires exactly one member');
    }
    final base = await _base(ids);
    return {
      for (final snapshot in base)
        snapshot.characterId: ExpeditionMemberCaps(
          maxHp: snapshot.maxHp,
          maxQi: snapshot.maxQi,
        ),
    };
  }

  @override
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
    required int cycleIndex,
  }) async {
    if (memberStates.length != 1) {
      throw StateError('Phase0a expedition requires one alive member');
    }
    final member = memberStates.entries.single;
    final snapshots = await _base([member.key]);
    final player = snapshots.single.copyWith(
      currentHp: member.value.hp,
      currentQi: member.value.qi,
    );
    final config = GameRepository.instance.expeditionConfig!;
    final enemies = config.enemiesForNode(
      nodeIndex: node.index,
      nodeSeed: nodeSeed,
      elite: node.type == ExpeditionNodeType.xianGuan,
    );
    final mapping = Phase0aStageContentMapper.mapExpedition(
      contentId: 'expedition_${node.index}',
      enemyTeam: enemies,
      playerSnapshot: player,
      numbers: GameRepository.instance.numbers,
      cycleIndex: cycleIndex,
    );
    final flow = Phase0aProductionFlowAssembler.assemble(
      initialState: mapping.initialState,
      waves: mapping.waves,
      combatants: mapping.combatants,
      moveBindings: mapping.moveBindings,
      numbers: GameRepository.instance.numbers,
      rng: Random(nodeSeed),
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
    );
    final result = await Phase0aHeadlessRunner.runToEndAsync(
      flow: flow,
      bot: Phase0aPlayerBotAdapter(playerAdapter: mapping.playerAdapter),
      deltaSeconds:
          GameRepository.instance.numbers.phase0aArena.fixedDeltaSeconds,
      maxTicks: GameRepository.instance.numbers.phase0aArena.maxSimulationTicks,
      yieldEveryTicks: _uiYieldEveryTicks,
    );
    final terminal = result.finalState.player;
    return outcomeFromTerminal(
      memberId: member.key,
      outcome: result.outcome,
      hp: terminal.currentHealth,
      qi: terminal.qiCurrent,
    );
  }

  /// headless 拍数耗尽保持 `ongoing`；远征沿旧 draw→defeat 口径败停。
  @visibleForTesting
  static ExpeditionNodeOutcome outcomeFromTerminal({
    required int memberId,
    required Phase0aBattleOutcome outcome,
    required int hp,
    required int qi,
  }) {
    return ExpeditionNodeOutcome(
      leftWin: outcome == Phase0aBattleOutcome.victory,
      survivorHp: {memberId: hp},
      survivorQi: {memberId: qi},
    );
  }
}
