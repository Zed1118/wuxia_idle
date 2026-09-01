import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/expedition_config.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_combat.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/application/phase0a_expedition_combat_runner.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_node.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/shared/battle_shared/battle_result.dart';
import 'package:wuxia_idle/shared/battle_shared/combat_settlement_snapshot.dart';

import '../../support/isar_test_support.dart';

final class _WrongParticipantCombat implements ExpeditionCombat {
  @override
  Future<Map<int, ExpeditionMemberCaps>> memberCaps(List<int> ids) async => {
    for (final id in ids) id: const ExpeditionMemberCaps(maxHp: 100, maxQi: 50),
  };

  @override
  Future<ExpeditionNodeOutcome> fight({
    required ExpeditionNode node,
    required Map<int, ExpeditionMemberVital> memberStates,
    required int nodeSeed,
    required int cycleIndex,
  }) async => ExpeditionNodeOutcome(
    leftWin: true,
    survivorHp: {memberStates.keys.single: 80},
    survivorQi: {memberStates.keys.single: 40},
    combatSettlement: CombatSettlementSnapshot(
      result: BattleResult.leftWin,
      totalTicks: 1,
      hadActions: true,
      playerCharacterId: 999,
      participants: const [
        CombatParticipantSnapshot(characterId: 999, currentHp: 80, maxHp: 100),
      ],
      skillCasts: const [],
      totalDamage: 1,
      criticalCount: 0,
      damageByCharacterId: const {999: 1},
    ),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() => initializeTestIsarCore());

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_expedition_manual_dispatch_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.saveDatas.put(
        SaveData()
          ..id = 0
          ..saveVersion = '0.38.0'
          ..createdAt = DateTime(2026, 8, 25)
          ..lastSavedAt = DateTime(2026, 8, 25)
          ..lastOnlineAt = DateTime(2026, 8, 25),
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<int> putFounder({bool healing = false}) async {
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      id = await IsarSetup.instance.characters.put(
        Character()
          ..name = '沈砚'
          ..realmTier = RealmTier.sanLiu
          ..realmLayer = RealmLayer.qiMeng
          ..attributes = Attributes()
          ..rarity = RarityTier.biaoZhun
          ..lineageRole = LineageRole.founder
          ..createdAt = DateTime(2026, 8, 25)
          ..isFounder = true
          ..isAlive = true
          ..injuryHoursRemaining = healing ? 2 : 0,
      );
      final techniqueId = await IsarSetup.instance.techniques.put(
        Technique.create(
          defId: 'tech_manual_dispatch',
          ownerCharacterId: id,
          tier: TechniqueTier.ruMenGong,
          school: TechniqueSchool.gangMeng,
          role: TechniqueRole.main,
          learnedAt: DateTime(2026, 8, 25),
        ),
      );
      final founder = (await IsarSetup.instance.characters.get(id))!
        ..mainTechniqueId = techniqueId;
      await IsarSetup.instance.characters.put(founder);
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..founderCharacterId = id;
      await IsarSetup.instance.saveDatas.put(save);
    });
    return id;
  }

  test('真实差遣请求显式冻结百草岭、实际参与者与 headless bot 语义', () {
    final request = ExpeditionService.dispatchRequestFor(characterId: 7);

    expect(request.contentId, ExpeditionService.contentId);
    expect(request.contentKind, ActivityContentKind.expedition);
    expect(request.characterId, 7);
    expect(request.loadoutPlanId, 'expedition:baicao:character:7');
    expect(request.participation, ActivityParticipationMode.dispatch);
    expect(request.controller, ActivityController.playerBot);
    expect(request.clock, ActivityClock.headless);
    expect(request.entryKind, ActivityEntryKind.firstClear);
  });

  test('返程结果必须承载实际参与者身份，禁止生成无身份假行记', () {
    const result = ExpeditionReturnResult(
      returned: true,
      participantCharacterId: 7,
      participantName: '沈砚',
      deepestNode: 3,
      grantedRewards: [],
      downedCount: 0,
      defeated: false,
    );

    expect(result.participantCharacterId, 7);
    expect(result.participantName, '沈砚');
  });

  test('typed request 落 durable participant snapshot 并占用实际参与者', () async {
    final id = await putFounder();
    final runId = await ExpeditionService(IsarSetup.instance).dispatchRequest(
      request: ExpeditionService.dispatchRequestFor(characterId: id),
      policy: ExpeditionPolicy.yiZhanLiXing,
      now: DateTime(2026, 8, 25, 10),
    );

    final run = await IsarSetup.instance.expeditionRuns.get(runId);
    expect(run, isNotNull);
    expect(run!.members.single.characterId, id);
    expect(run.members.single.reservedTechniqueIds, hasLength(1));
  });

  test('待亲战险关未处理时 production dispatch 原子拒绝且不消费 serial', () async {
    final id = await putFounder();
    final recordKey = ExpeditionMilestoneRecord.canonicalKey(
      saveDataId: IsarSetup.currentSlotId,
      routeId: ExpeditionService.contentId,
      milestoneId: 'expedition_elite_blade_v1',
    );
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.expeditionMilestoneRecords.put(
        ExpeditionMilestoneRecord()
          ..recordKey = recordKey
          ..saveDataId = IsarSetup.currentSlotId
          ..routeId = ExpeditionService.contentId
          ..milestoneId = 'expedition_elite_blade_v1'
          ..nodeIndex = 5
          ..nodeSeed = 15
          ..cycleIndex = 1
          ..sourceRunId = 9
          ..sourceParticipantId = id
          ..discoveredAt = DateTime(2026, 8, 25, 9),
      );
    });

    await expectLater(
      ExpeditionService(IsarSetup.instance).dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(characterId: id),
        policy: ExpeditionPolicy.yiZhanLiXing,
      ),
      throwsStateError,
    );
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);
    expect((await IsarSetup.instance.saveDatas.get(0))!.expeditionRunSerial, 0);

    await IsarSetup.instance.writeTxn(() async {
      final cleared =
          (await IsarSetup.instance.expeditionMilestoneRecords.getByRecordKey(
            recordKey,
          ))!..manualClearedAt = DateTime(2026, 8, 25, 10);
      await IsarSetup.instance.expeditionMilestoneRecords.put(cleared);
    });
    final runId = await ExpeditionService(IsarSetup.instance).dispatchRequest(
      request: ExpeditionService.dispatchRequestFor(characterId: id),
      policy: ExpeditionPolicy.yiZhanLiXing,
    );
    expect(await IsarSetup.instance.expeditionRuns.get(runId), isNotNull);
    expect((await IsarSetup.instance.saveDatas.get(0))!.expeditionRunSerial, 1);
  });

  test('伪造 request 语义 fail closed 且不消费 serial', () async {
    final id = await putFounder();
    final forged = ActivityParticipationRequest(
      contentId: ExpeditionService.contentId,
      contentKind: ActivityContentKind.expedition,
      characterId: id,
      loadoutPlanId: 'expedition:baicao:character:$id',
      participation: ActivityParticipationMode.dispatch,
      controller: ActivityController.human,
      clock: ActivityClock.headless,
      entryKind: ActivityEntryKind.firstClear,
    );

    await expectLater(
      ExpeditionService(
        IsarSetup.instance,
      ).dispatchRequest(request: forged, policy: ExpeditionPolicy.yiZhanLiXing),
      throwsStateError,
    );
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);
    expect((await IsarSetup.instance.saveDatas.get(0))!.expeditionRunSerial, 0);
  });

  test('死亡、历史祖师与悬空装备均不得进入 production dispatch', () async {
    final currentId = await putFounder();
    final service = ExpeditionService(IsarSetup.instance);
    await IsarSetup.instance.writeTxn(() async {
      final current = (await IsarSetup.instance.characters.get(currentId))!
        ..isAlive = false;
      await IsarSetup.instance.characters.put(current);
    });
    await expectLater(
      service.dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(characterId: currentId),
        policy: ExpeditionPolicy.yiZhanLiXing,
      ),
      throwsStateError,
    );

    await IsarSetup.instance.writeTxn(() async {
      final current = (await IsarSetup.instance.characters.get(currentId))!
        ..isAlive = true
        ..equippedWeaponId = 999;
      await IsarSetup.instance.characters.put(current);
    });
    await expectLater(
      service.dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(characterId: currentId),
        policy: ExpeditionPolicy.yiZhanLiXing,
      ),
      throwsStateError,
    );

    late int historicalId;
    await IsarSetup.instance.writeTxn(() async {
      historicalId = await IsarSetup.instance.characters.put(
        Character()
          ..name = '前代掌门'
          ..realmTier = RealmTier.sanLiu
          ..realmLayer = RealmLayer.qiMeng
          ..attributes = Attributes()
          ..rarity = RarityTier.biaoZhun
          ..lineageRole = LineageRole.founder
          ..createdAt = DateTime(2026, 8, 25)
          ..isFounder = true
          ..isAlive = true,
      );
      final techniqueId = await IsarSetup.instance.techniques.put(
        Technique.create(
          defId: 'tech_historical_founder',
          ownerCharacterId: historicalId,
          tier: TechniqueTier.ruMenGong,
          school: TechniqueSchool.gangMeng,
          role: TechniqueRole.main,
          learnedAt: DateTime(2026, 8, 25),
        ),
      );
      final historical = (await IsarSetup.instance.characters.get(
        historicalId,
      ))!..mainTechniqueId = techniqueId;
      await IsarSetup.instance.characters.put(historical);
    });
    await expectLater(
      service.dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(
          characterId: historicalId,
        ),
        policy: ExpeditionPolicy.yiZhanLiXing,
      ),
      throwsStateError,
    );
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);
  });

  test('疗养、悬空心法与重复占用均 fail closed 且不建 run', () async {
    final healingId = await putFounder(healing: true);
    final originalTechniqueId = (await IsarSetup.instance.characters.get(
      healingId,
    ))!.mainTechniqueId!;
    final service = ExpeditionService(IsarSetup.instance);
    await expectLater(
      service.dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(characterId: healingId),
        policy: ExpeditionPolicy.yiZhanLiXing,
      ),
      throwsStateError,
    );
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);

    await IsarSetup.instance.writeTxn(() async {
      final founder = (await IsarSetup.instance.characters.get(healingId))!
        ..injuryHoursRemaining = 0
        ..mainTechniqueId = 999;
      await IsarSetup.instance.characters.put(founder);
    });
    await expectLater(
      service.dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(characterId: healingId),
        policy: ExpeditionPolicy.yiZhanLiXing,
      ),
      throwsStateError,
    );

    await IsarSetup.instance.writeTxn(() async {
      final founder = (await IsarSetup.instance.characters.get(healingId))!;
      founder
        ..mainTechniqueId = originalTechniqueId
        ..currentRetreatSessionId = 42;
      await IsarSetup.instance.characters.put(founder);
    });
    await expectLater(
      service.dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(characterId: healingId),
        policy: ExpeditionPolicy.yiZhanLiXing,
      ),
      throwsStateError,
    );
    expect(await IsarSetup.instance.expeditionRuns.count(), 0);
  });

  test('reserved loadout 改变后真实 runner 在开战前拒绝 stale participant', () async {
    final id = await putFounder();
    final service = ExpeditionService(IsarSetup.instance);
    final runId = await service.dispatchRequest(
      request: ExpeditionService.dispatchRequestFor(characterId: id),
      policy: ExpeditionPolicy.yiZhanLiXing,
    );
    final run = (await IsarSetup.instance.expeditionRuns.get(runId))!;
    await IsarSetup.instance.writeTxn(() async {
      final replacementId = await IsarSetup.instance.techniques.put(
        Technique.create(
          defId: 'tech_stale_replacement',
          ownerCharacterId: id,
          tier: TechniqueTier.ruMenGong,
          school: TechniqueSchool.gangMeng,
          role: TechniqueRole.main,
          learnedAt: DateTime(2026, 8, 25),
        ),
      );
      final founder = (await IsarSetup.instance.characters.get(id))!
        ..mainTechniqueId = replacementId;
      await IsarSetup.instance.characters.put(founder);
    });

    await expectLater(
      Phase0aExpeditionCombatRunner(
        IsarSetup.instance,
        expectedMember: run.members.single,
      ).memberCaps([id]),
      throwsStateError,
    );
  });

  test('错人 combat settlement 在游标、奖励和共享账本落库前被拒绝', () async {
    final id = await putFounder();
    final service = ExpeditionService(IsarSetup.instance);
    final departed = DateTime(2026, 8, 25, 10);
    final runId = await service.dispatchRequest(
      request: ExpeditionService.dispatchRequestFor(characterId: id),
      policy: ExpeditionPolicy.yiZhanLiXing,
      now: departed,
    );

    await expectLater(
      service.settle(
        combat: _WrongParticipantCombat(),
        config: const ExpeditionConfig(
          normalNodeMinutes: 90,
          eliteNodeMinutes: 180,
          hpRecoverPctPerNode: 0.1,
          qiRecoverPctPerNode: 0.1,
          zhangshiPctPerLayer: 0.05,
          baseExpPerBattle: 100,
        ),
        now: departed.add(const Duration(minutes: 540)),
      ),
      throwsStateError,
    );
    final run = (await IsarSetup.instance.expeditionRuns.get(runId))!;
    expect(run.currentNode, 0);
    expect(run.stagedRewards, isEmpty);
  });
}
