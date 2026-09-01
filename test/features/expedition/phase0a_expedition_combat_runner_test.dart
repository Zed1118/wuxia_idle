import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/shared/battle_shared/player_combatant_snapshot_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat_selector.dart';
import 'package:wuxia_idle/features/expedition/application/phase0a_expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_seed.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_phase0a_expedition_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    await IsarSetup.instance.writeTxn(() async {
      final character = (await IsarSetup.instance.characters.get(1))!
        ..isFounder = false
        ..lineageRole = LineageRole.disciple
        ..currentRetreatSessionId = null;
      await IsarSetup.instance.characters.put(character);
    });
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('路线 C selector 只允许单成员 Phase 0A', () {
    final member = ActivityMemberSnapshot()..characterId = 1;
    expect(
      expeditionCombatFor(IsarSetup.instance, memberCount: 1, member: member),
      isA<Phase0aExpeditionCombatRunner>(),
    );
    expect(
      () => expeditionCombatFor(
        IsarSetup.instance,
        memberCount: 2,
        member: member,
      ),
      throwsStateError,
    );
  });

  test('单角色真实节点同 seed 确定，且战后 HP/真气写回合法区间', () async {
    final firstRunner = Phase0aExpeditionCombatRunner(IsarSetup.instance);
    final secondRunner = Phase0aExpeditionCombatRunner(IsarSetup.instance);
    final caps = (await firstRunner.memberCaps([1]))[1]!;
    final memberStates = {
      1: ExpeditionMemberVital(hp: caps.maxHp, qi: caps.maxQi ~/ 2),
    };
    const node = ExpeditionNode(
      index: 5,
      type: ExpeditionNodeType.xianGuan,
      durationMinutes: 180,
    );

    final first = await firstRunner.fight(
      node: node,
      memberStates: memberStates,
      nodeSeed: 820225,
      cycleIndex: 1,
    );
    final replay = await secondRunner.fight(
      node: node,
      memberStates: memberStates,
      nodeSeed: 820225,
      cycleIndex: 1,
    );

    expect(replay.leftWin, first.leftWin);
    expect(replay.survivorHp, first.survivorHp);
    expect(replay.survivorQi, first.survivorQi);
    expect(first.survivorHp.keys, [1]);
    expect(first.survivorQi.keys, [1]);
    expect(first.survivorHp[1], inInclusiveRange(0, caps.maxHp));
    expect(first.survivorQi[1], inInclusiveRange(0, caps.maxQi));
    expect(first.combatSettlement, isNotNull);
    expect(first.combatSettlement!.participantCharacterIds, contains(1));
    expect(
      first.combatSettlement!.participantFor(1)!.currentHp,
      first.survivorHp[1],
      reason: '真实 headless 终局须以实际参与者进入共享 settlement snapshot',
    );
  });

  test('runner 拒绝多成员误入 Phase 0A 路径', () async {
    final runner = Phase0aExpeditionCombatRunner(IsarSetup.instance);

    await expectLater(runner.memberCaps([1, 2]), throwsA(isA<StateError>()));
  });

  test('真实自动节点把实际参与者终局写入共享战斗账本', () async {
    final departed = DateTime(2026, 8, 25, 10);
    await IsarSetup.instance.writeTxn(() async {
      final equipmentId = await IsarSetup.instance.equipments.put(
        Equipment.create(
          defId: 'equipment_expedition_ledger_test',
          tier: EquipmentTier.xunChang,
          slot: EquipmentSlot.weapon,
          obtainedAt: departed,
          obtainedFrom: 'test',
          ownerCharacterId: 1,
          baseAttack: 10,
        ),
      );
      final character = (await IsarSetup.instance.characters.get(1))!
        ..isFounder = true
        ..lineageRole = LineageRole.founder
        ..currentRetreatSessionId = null
        ..equippedWeaponId = equipmentId;
      await IsarSetup.instance.characters.put(character);
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..founderCharacterId = 1;
      await IsarSetup.instance.saveDatas.put(save);
    });
    final equipmentBefore = {
      for (final equipment
          in await IsarSetup.instance.equipments
              .filter()
              .ownerCharacterIdEqualTo(1)
              .findAll())
        equipment.id: equipment.battleCount,
    };
    final service = ExpeditionService(IsarSetup.instance);
    final runId = await service.dispatchRequest(
      request: ExpeditionService.dispatchRequestFor(characterId: 1),
      policy: ExpeditionPolicy.yiZhanLiXing,
      now: departed,
    );
    final run = (await IsarSetup.instance.expeditionRuns.get(runId))!;

    final result = await service.settle(
      combat: Phase0aExpeditionCombatRunner(
        IsarSetup.instance,
        expectedMember: run.members.single,
      ),
      config: GameRepository.instance.expeditionConfig!,
      now: departed.add(
        Duration(
          minutes: GameRepository.instance.expeditionConfig!.normalNodeMinutes,
        ),
      ),
    );

    expect(result.nodesSettled, 1);
    final equipmentAfter = await IsarSetup.instance.equipments
        .filter()
        .ownerCharacterIdEqualTo(1)
        .findAll();
    expect(
      equipmentAfter.any(
        (equipment) =>
            equipment.battleCount > (equipmentBefore[equipment.id] ?? -1),
      ),
      isTrue,
      reason: '实际参与者装备 battleCount 必须由共享 CombatResolutionService 递增',
    );
  });

  test('headless 超时 ongoing 沿旧 draw 口径映射为败停', () {
    final outcome = Phase0aExpeditionCombatRunner.outcomeFromTerminal(
      memberId: 1,
      outcome: Phase0aBattleOutcome.ongoing,
      hp: 9,
      qi: 3,
    );

    expect(outcome.leftWin, isFalse);
    expect(outcome.survivorHp, {1: 9});
    expect(outcome.survivorQi, {1: 3});
  });

  test('远征 mapper 保留 cycle 境界段推进', () async {
    final player = (await PlayerCombatantSnapshotAssembler(
      isar: IsarSetup.instance,
    ).loadExactRoster([1])).single;
    final config = GameRepository.instance.expeditionConfig!;
    final enemies = config.enemiesForNode(
      nodeIndex: 5,
      nodeSeed: 820225,
      elite: true,
    );

    final firstCycle = Phase0aStageContentMapper.mapExpedition(
      contentId: 'expedition_cycle_1',
      enemyTeam: enemies,
      playerSnapshot: player,
      numbers: GameRepository.instance.numbers,
      cycleIndex: 1,
    );
    final secondCycle = Phase0aStageContentMapper.mapExpedition(
      contentId: 'expedition_cycle_2',
      enemyTeam: enemies,
      playerSnapshot: player,
      numbers: GameRepository.instance.numbers,
      cycleIndex: 2,
    );
    final firstEnemy = firstCycle.combatants[1].snapshot;
    final secondEnemy = secondCycle.combatants[1].snapshot;

    expect(
      secondEnemy.realmTier.index * RealmLayer.values.length +
          secondEnemy.realmLayer.index,
      greaterThan(
        firstEnemy.realmTier.index * RealmLayer.values.length +
            firstEnemy.realmLayer.index,
      ),
    );
  });

  test('可见真人险关胜利才写 route+milestone 解锁并与奖励 receipt 同事务', () async {
    final config = GameRepository.instance.expeditionConfig!;
    final nodeSeed = ExpeditionSeed.forNode(saveId: 0, runSerial: 1, node: 5);
    final milestoneId = config.teamForNode(nodeSeed: nodeSeed, elite: true).id;
    final recordKey = ExpeditionMilestoneRecord.canonicalKey(
      saveDataId: 1,
      routeId: ExpeditionService.contentId,
      milestoneId: milestoneId,
    );
    await IsarSetup.instance.writeTxn(() async {
      final character = (await IsarSetup.instance.characters.get(1))!
        ..isFounder = true
        ..lineageRole = LineageRole.founder;
      await IsarSetup.instance.characters.put(character);
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..founderCharacterId = 1;
      await IsarSetup.instance.saveDatas.put(save);
      await IsarSetup.instance.expeditionMilestoneRecords.put(
        ExpeditionMilestoneRecord()
          ..recordKey = recordKey
          ..saveDataId = 1
          ..routeId = ExpeditionService.contentId
          ..milestoneId = milestoneId
          ..nodeIndex = 5
          ..nodeSeed = nodeSeed
          ..cycleIndex = 1
          ..sourceRunId = 99
          ..sourceParticipantId = 1
          ..discoveredAt = DateTime.utc(2026, 9, 1),
      );
    });
    final service = ExpeditionService(IsarSetup.instance);
    final plan = await service.prepareManualMilestone(
      request: ExpeditionService.manualMilestoneRequestFor(
        milestoneId: milestoneId,
        characterId: 1,
      ),
    );
    final lost = await service.completeManualMilestone(
      plan: plan,
      settlement: CombatSettlementSnapshot(
        result: BattleResult.rightWin,
        totalTicks: 20,
        hadActions: true,
        playerCharacterId: 1,
        participants: [
          CombatParticipantSnapshot(
            characterId: 1,
            currentHp: 0,
            maxHp: plan.playerSnapshot.maxHp,
          ),
        ],
        skillCasts: const [],
        totalDamage: 1,
        criticalCount: 0,
        damageByCharacterId: const {1: 1},
      ),
      now: DateTime.utc(2026, 9, 1, 0, 30),
    );
    expect(lost, isFalse);
    expect(
      (await IsarSetup.instance.expeditionMilestoneRecords.getByRecordKey(
        recordKey,
      ))?.manualClearedAt,
      isNull,
    );
    expect(await IsarSetup.instance.rewardClaimReceipts.count(), 0);

    final winningSettlement = CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 20,
      hadActions: true,
      playerCharacterId: 1,
      participants: [
        CombatParticipantSnapshot(
          characterId: 1,
          currentHp: plan.playerSnapshot.maxHp,
          maxHp: plan.playerSnapshot.maxHp,
        ),
      ],
      skillCasts: const [],
      totalDamage: 10,
      criticalCount: 0,
      damageByCharacterId: const {1: 10},
    );
    await expectLater(
      service.completeManualMilestone(
        plan: plan,
        settlement: winningSettlement,
        now: DateTime.utc(2026, 9, 1, 0, 45),
        afterRewardsInTxnForTest: () async => throw StateError('crash'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      (await IsarSetup.instance.expeditionMilestoneRecords.getByRecordKey(
        recordKey,
      ))?.manualClearedAt,
      isNull,
    );
    expect(await IsarSetup.instance.rewardClaimReceipts.count(), 0);
    expect((await IsarSetup.instance.saveDatas.get(0))!.baicaoMaxDepth, 0);

    final won = await service.completeManualMilestone(
      plan: plan,
      settlement: winningSettlement,
      now: DateTime.utc(2026, 9, 1, 1),
    );

    expect(won, isTrue);
    final stored = await IsarSetup.instance.expeditionMilestoneRecords
        .getByRecordKey(recordKey);
    expect(
      stored?.manualClearedAt?.millisecondsSinceEpoch,
      DateTime.utc(2026, 9, 1, 1).millisecondsSinceEpoch,
    );
    expect(await IsarSetup.instance.rewardClaimReceipts.count(), 3);
    expect((await IsarSetup.instance.saveDatas.get(0))!.baicaoMaxDepth, 5);
  });
}
