import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/game_repository.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/combatant_snapshot.dart';
import '../../../shared/utils/math_random.dart';
import '../../battle/application/phase0a/phase0a_headless_runner.dart';
import '../../battle/application/phase0a/phase0a_player_bot_adapter.dart';
import '../../battle/application/phase0a/phase0a_production_flow_assembler.dart';
import '../../battle/application/phase0a/phase0a_settlement_adapter.dart';
import '../../battle/application/phase0a/phase0a_stage_content_mapper.dart';
import '../../activity/domain/activity_member_snapshot.dart';
import '../../lineup/application/disciple_scheduling_provider.dart';
import '../../../shared/battle_shared/player_combatant_snapshot_assembler.dart';
import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../domain/expedition_node.dart';
import 'expedition_combat.dart';

/// 远征的单角色 Phase 0A combat adapter；离线事务与奖励仍由 ExpeditionService 所有。
final class Phase0aExpeditionCombatRunner implements ExpeditionCombat {
  Phase0aExpeditionCombatRunner(
    this._isar, {
    ActivityMemberSnapshot? expectedMember,
  }) : _expectedCharacterId = expectedMember?.characterId,
       _expectedEquipmentIds = List.unmodifiable(
         expectedMember?.reservedEquipmentIds ?? const <int>[],
       ),
       _expectedTechniqueIds = List.unmodifiable(
         expectedMember?.reservedTechniqueIds ?? const <int>[],
       );

  final Isar _isar;
  final int? _expectedCharacterId;
  final List<int> _expectedEquipmentIds;
  final List<int> _expectedTechniqueIds;
  List<CombatantSnapshot>? _baseTeam;

  static const int _uiYieldEveryTicks = 32;

  Future<List<CombatantSnapshot>> _base(List<int> ids) async {
    await _revalidateExpectedMember(ids);
    return _baseTeam ??= await PlayerCombatantSnapshotAssembler(
      isar: _isar,
    ).loadExactRoster(ids);
  }

  Future<void> _revalidateExpectedMember(List<int> ids) async {
    final expectedId = _expectedCharacterId;
    if (expectedId == null) return;
    if (ids.length != 1 || ids.single != expectedId) {
      throw StateError('Expedition participant snapshot does not match runner');
    }
    final scheduling = await loadDiscipleSchedulingSummary(_isar);
    final scheduled = scheduling.members
        .where((member) => member.characterId == expectedId)
        .toList();
    if (scheduled.length != 1 || !scheduled.single.isAlive) {
      throw StateError('Expedition participant is stale or not current');
    }
    final character = await _isar.characters.get(expectedId);
    if (character == null ||
        !character.isAlive ||
        character.injuryHoursRemaining > 0) {
      throw StateError('Expedition participant is missing, dead, or healing');
    }
    final equipmentIds = <int>[
      ?character.equippedWeaponId,
      ?character.equippedArmorId,
      ?character.equippedAccessoryId,
    ];
    final techniqueIds = <int>[
      ?character.mainTechniqueId,
      ...character.assistTechniqueIds,
    ];
    if (!_sameIds(equipmentIds, _expectedEquipmentIds) ||
        !_sameIds(techniqueIds, _expectedTechniqueIds)) {
      throw StateError('Expedition participant loadout snapshot is stale');
    }
    for (final equipmentId in equipmentIds) {
      final equipment = await _isar.equipments.get(equipmentId);
      if (equipment == null || equipment.ownerCharacterId != expectedId) {
        throw StateError('Expedition participant equipment is dangling');
      }
    }
    for (final techniqueId in techniqueIds) {
      final technique = await _isar.techniques.get(techniqueId);
      if (technique == null || technique.ownerCharacterId != expectedId) {
        throw StateError('Expedition participant technique is dangling');
      }
    }
  }

  static bool _sameIds(List<int> current, List<int> expected) {
    if (current.length != expected.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (current[i] != expected[i]) return false;
    }
    return true;
  }

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
      rng: newMathRandom(seed: nodeSeed),
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
    final settlementOutcome = result.outcome == Phase0aBattleOutcome.ongoing
        ? Phase0aBattleOutcome.defeat
        : result.outcome;
    return outcomeFromTerminal(
      memberId: member.key,
      outcome: result.outcome,
      hp: terminal.currentHealth,
      qi: terminal.qiCurrent,
      combatSettlement: Phase0aSettlementAdapter.fromMapping(
        mapping: mapping,
        outcome: settlementOutcome,
        finalState: result.finalState,
        events: result.events,
      ),
    );
  }

  /// headless 拍数耗尽保持 `ongoing`；远征沿旧 draw→defeat 口径败停。
  @visibleForTesting
  static ExpeditionNodeOutcome outcomeFromTerminal({
    required int memberId,
    required Phase0aBattleOutcome outcome,
    required int hp,
    required int qi,
    CombatSettlementSnapshot? combatSettlement,
  }) {
    return ExpeditionNodeOutcome(
      leftWin: outcome == Phase0aBattleOutcome.victory,
      survivorHp: {memberId: hp},
      survivorQi: {memberId: qi},
      combatSettlement: combatSettlement,
    );
  }
}
