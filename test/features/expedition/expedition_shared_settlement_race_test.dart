import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/application/phase0a_expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_rules.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../support/isar_test_support.dart';
import '../../support/phase0a_ch1_founder_profile.dart';

/// A shared-settlement transaction fixture, not a natural combat defeat or a
/// performance sample. Preparation uses real combat; only the contested node
/// receives this deterministic terminal record through the production seam.
final class _SharedDefeatFixture implements ExpeditionCombat {
  _SharedDefeatFixture({
    required this.runner,
    required this.nodeIndex,
    required this.characterId,
    required this.skillId,
  });

  final Phase0aExpeditionCombatRunner runner;
  final int nodeIndex;
  final int characterId;
  final String skillId;
  var calls = 0;

  @override
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(List<int> ids) =>
      runner.memberCaps(ids);

  @override
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
    required int cycleIndex,
  }) async {
    expect(node.index, nodeIndex);
    expect(node.isBattle, isTrue);
    expect(memberStates.keys, [characterId]);
    expect(memberStates[characterId]!.hp, greaterThan(0));
    calls++;
    final caps = (await runner.memberCaps([characterId]))[characterId]!;
    return ExpeditionNodeOutcome(
      leftWin: false,
      survivorHp: {characterId: 0},
      survivorQi: {characterId: 0},
      combatSettlement: CombatSettlementSnapshot(
        result: BattleResult.rightWin,
        totalTicks: 1,
        hadActions: true,
        playerCharacterId: characterId,
        participants: [
          CombatParticipantSnapshot(
            characterId: characterId,
            currentHp: 0,
            maxHp: caps.maxHp,
          ),
        ],
        skillCasts: [
          CombatSkillCastSnapshot(
            tick: 1,
            characterId: characterId,
            skillId: skillId,
          ),
        ],
        totalDamage: 0,
        criticalCount: 0,
        damageByCharacterId: {characterId: 0},
      ),
    );
  }
}

// All 26 collections opened by the current production IsarSetup. Keep every
// row and field, including timestamps and receipts, in the stale-write check.
const _collectionNames = [
  'SaveData',
  'Character',
  'Equipment',
  'Technique',
  'InventoryItem',
  'GameEvent',
  'MainlineProgress',
  'MainlineSettlementJournal',
  'TowerProgress',
  'TowerPersonalRecord',
  'RetreatSession',
  'EncounterProgress',
  'Reputation',
  'NpcRelation',
  'Sect',
  'SectEvent',
  'PvpRecord',
  'PvpSnapshot',
  'BossMemory',
  'EquipmentCatalogEntry',
  'ExpeditionRun',
  'ExpeditionMilestoneRecord',
  'BossGauntletRun',
  'DurableActivityCombatRun',
  'RewardClaimReceipt',
  'ProgressiveUnlockReceipt',
];

Future<Map<String, Object?>> _storedFacts() async {
  final result = <String, Object?>{};
  for (final name in _collectionNames) {
    // Enumerate every opened schema for this test's full-store no-write check.
    // ignore: invalid_use_of_protected_member
    final collection = IsarSetup.instance.getCollectionByNameInternal(name);
    expect(
      collection,
      isNotNull,
      reason: 'Missing production collection $name',
    );
    result[name] = await collection!.where().exportJson();
  }
  return result;
}

void main() {
  late Directory directory;
  late GameRepository repository;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'expedition_shared_race_',
    );
    await IsarSetup.init(directory: directory, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  test('same-time concurrent shared defeat commits growth only once', () async {
    final isar = IsarSetup.instance;
    final profile = await seedPhase0aCh1FounderProfile(
      isar: isar,
      schoolId: 'gang_meng',
      originId: 'mountain_wanderer',
      fateId: 'balanced_seed',
      rngSeed: 20260820,
    );
    final id = profile.snapshot.characterId;
    final service = ExpeditionService(isar, rng: DefaultRng(seed: 73));
    final departedAt = DateTime.utc(2026, 9, 14);
    Future<int> dispatch() => service.dispatchRequest(
      request: ExpeditionService.dispatchRequestFor(characterId: id),
      policy: ExpeditionPolicy.yiZhanLiXing,
      now: departedAt,
    );

    // Obtain serial 2 by a real immediate recall, not by changing the serial or
    // recording any clear. This legal route has two ordinary combat nodes.
    await dispatch();
    final recalled = await service.recall(now: departedAt);
    expect(recalled.returned, isTrue);
    expect(recalled.deepestNode, 0);
    expect(recalled.grantedRewards, isEmpty);
    await dispatch();
    final entry = (await service.activeRun())!;
    expect(entry.seed, 2);
    final config = repository.expeditionConfig!;
    final now = departedAt.add(
      Duration(
        minutes: ExpeditionRules.cumulativeMinutesToCompleteNode(
          4,
          normalMinutes: config.normalNodeMinutes,
          eliteMinutes: config.eliteNodeMinutes,
        ),
      ),
    );
    final runner = Phase0aExpeditionCombatRunner(
      isar,
      expectedMember: entry.members.single,
    );

    // Advance only through the actual service and production combat. Stop
    // immediately before the later ordinary battle; no milestone is cleared.
    var before = entry;
    while (before.currentNode < 4) {
      final next = ExpeditionRules.generateNode(
        saveId: before.saveDataId,
        runSerial: before.seed,
        node: before.currentNode + 1,
        policy: before.policy,
        normalMinutes: config.normalNodeMinutes,
        eliteMinutes: config.eliteNodeMinutes,
      );
      if (before.currentNode > 0 && next.isBattle) break;
      final prepared = await service.settle(
        combat: runner,
        config: config,
        now: now,
        maxNodesPerBatch: 1,
      );
      expect(prepared.defeated, isFalse);
      expect(prepared.manualMilestoneGate, isNull);
      expect(prepared.nodesSettled, 1);
      before = (await service.activeRun())!;
    }
    expect(before.currentNode, inInclusiveRange(1, 3));
    expect(before.defeated, isFalse);
    expect(before.lastSettledAt!.toUtc(), now);
    final character = (await isar.characters.get(id))!;
    final main = (await isar.techniques.get(character.mainTechniqueId!))!;
    final skillId = repository
        .getTechnique(main.defId)
        .skillIds
        .firstWhere(
          (skill) => profile.snapshot.availableSkills.any(
            (entry) => entry.id == skill,
          ),
        );
    final usesBefore = main.skillUsageCount.countOf(skillId);
    Future<int> skillUses() async =>
        (await isar.techniques.get(main.id))!.skillUsageCount.countOf(skillId);
    Future<Map<int, int>> equipmentCounts() async => {
      for (final equipmentId in before.members.single.reservedEquipmentIds)
        equipmentId: (await isar.equipments.get(equipmentId))!.battleCount,
    };
    final countsBefore = await equipmentCounts();
    expect(countsBefore, isNotEmpty);
    final beforeFacts = await _storedFacts();
    final fixture = _SharedDefeatFixture(
      runner: runner,
      nodeIndex: before.currentNode + 1,
      characterId: id,
      skillId: skillId,
    );
    late Map<String, Object?> innerFacts;
    final outer = await service.settle(
      combat: fixture,
      config: config,
      now: now,
      beforeCommitForTest: () async {
        // The outer caller has already simulated from the live snapshot. The
        // inner caller commits a defeat before the outer write transaction.
        final inner = await service.settle(
          combat: fixture,
          config: config,
          now: now,
        );
        expect(inner.defeated, isTrue);
        expect(inner.nodesSettled, 0);
        final committed = (await service.activeRun())!;
        expect(committed.currentNode, before.currentNode);
        expect(committed.lastSettledAt, before.lastSettledAt);
        expect(committed.defeated, isTrue);
        expect(committed.members.single.currentHp, 0);
        expect(committed.members.single.currentQi, 0);
        expect(committed.members.single.isDowned, isTrue);
        expect(await skillUses(), usesBefore + 1);
        expect(await equipmentCounts(), {
          for (final entry in countsBefore.entries) entry.key: entry.value + 1,
        });
        innerFacts = await _storedFacts();
        expect(innerFacts, isNot(equals(beforeFacts)));
      },
    );
    final countsAfter = await equipmentCounts();
    final usesAfter = await skillUses();
    final afterFacts = await _storedFacts();
    stdout.writeln(
      'expedition-shared-settlement-race ${jsonEncode({
        'fixture': 'shared defeat transaction only; not natural combat evidence',
        'contestedNode': fixture.nodeIndex,
        'simulations': fixture.calls,
        'equipmentBefore': {for (final entry in countsBefore.entries) '${entry.key}': entry.value},
        'equipmentAfter': {for (final entry in countsAfter.entries) '${entry.key}': entry.value},
        'skill': skillId,
        'usesBefore': usesBefore,
        'usesAfter': usesAfter,
      })}',
    );
    expect(fixture.calls, 2);
    expect(
      countsAfter,
      {for (final entry in countsBefore.entries) entry.key: entry.value + 1},
      reason: 'The stale outer defeat must not apply equipment growth twice',
    );
    expect(usesAfter, usesBefore + 1);
    expect(
      afterFacts,
      innerFacts,
      reason: 'Discarded outer batch must not change any stored row',
    );
    expect(outer.nodesSettled, 0);
    expect(outer.caughtUp, isFalse);
  });
}
