import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_participant_service.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_participation_policy.dart';
import 'package:wuxia_idle/features/light_foot/application/light_foot_participant_service.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_participant_snapshot_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_participation_policy.dart';
import 'package:wuxia_idle/features/mass_battle/application/mass_battle_participant_service.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// M6 顶层占用 Gate 的跨模式生产守卫。
///
/// 单项 feature 测试不能证明各入口仍共享同一个 canonical occupancy。这里用同一
/// 个真实 Isar 角色依次穿过主线、塔、轻功、守城、心魔、远征和断魂庄的生产
/// admission API，并用闭关事实对七条路径做同源破坏约束。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_m6_gate_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<Character> seedLeader() async {
    final isar = IsarSetup.instance;
    final leader = Character.create(
      name: '当代掌门',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime.utc(2026, 9, 1),
      internalForce: 3000,
      school: TechniqueSchool.gangMeng,
      isFounder: true,
      isAlive: true,
    );
    await isar.writeTxn(() => isar.characters.put(leader));
    final technique = Technique.create(
      defId: 'tech_gangmeng_jichu',
      ownerCharacterId: leader.id,
      tier: TechniqueTier.values.first,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime.utc(2026, 9, 1),
    );
    await isar.writeTxn(() async {
      leader.mainTechniqueId = await isar.techniques.put(technique);
      await isar.characters.put(leader);
      final save = (await isar.saveDatas.get(0))!;
      save
        ..founderCharacterId = leader.id
        ..activeCharacterIds = [leader.id];
      await isar.saveDatas.put(save);
    });
    return leader;
  }

  ActivityParticipationRequest mainlineRequest(int characterId) =>
      ActivityParticipationRequest(
        contentId: 'stage_01_01',
        contentKind: ActivityContentKind.mainline,
        characterId: characterId,
        loadoutPlanId: mainlineLoadoutPlanId(
          stageId: 'stage_01_01',
          characterId: characterId,
        ),
        participation: ActivityParticipationMode.direct,
        controller: ActivityController.human,
        clock: ActivityClock.realtime,
        entryKind: ActivityEntryKind.firstClear,
      );

  ActivityParticipationRequest innerDemonRequest(int characterId) =>
      ActivityParticipationRequest(
        contentId: 'stage_inner_demon_01',
        contentKind: ActivityContentKind.innerDemon,
        characterId: characterId,
        loadoutPlanId: innerDemonLoadoutPlanId(
          stageId: 'stage_inner_demon_01',
          characterId: characterId,
        ),
        participation: ActivityParticipationMode.direct,
        controller: ActivityController.human,
        clock: ActivityClock.realtime,
        entryKind: ActivityEntryKind.firstClear,
      );

  Future<void> seedGauntletTicket() async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = GauntletService.ticketDefId
          ..itemType = ItemType.ticket
          ..quantity = 1
          ..firstObtainedAt = DateTime.utc(2026, 9, 1)
          ..lastObtainedAt = DateTime.utc(2026, 9, 1),
      );
    });
  }

  test('空闲掌门可经七类生产 admission 使用同一本人快照', () async {
    final leader = await seedLeader();
    final isar = IsarSetup.instance;

    final mainline = await MainlineParticipantSnapshotService(
      isar,
    ).resolve(mainlineRequest(leader.id));
    expect(mainline.snapshot.characterId, leader.id);
    expect(
      (await resolveTowerParticipantSnapshot(
        isar: isar,
        requestedParticipantId: leader.id,
      )).characterId,
      leader.id,
    );
    expect(
      (await resolveLightFootParticipantSnapshot(
        isar: isar,
        requestedParticipantId: leader.id,
      )).characterId,
      leader.id,
    );
    expect(
      (await resolveMassBattleParticipantSnapshot(
        isar: isar,
        requestedParticipantId: leader.id,
      )).characterId,
      leader.id,
    );
    expect(
      (await resolveInnerDemonParticipantSnapshot(
        isar: isar,
        request: innerDemonRequest(leader.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: leader.id,
      )).characterId,
      leader.id,
    );

    final expeditionRunId = await ExpeditionService(isar).dispatchRequest(
      request: ExpeditionService.dispatchRequestFor(characterId: leader.id),
      policy: ExpeditionPolicy.yanJingCaiYao,
      now: DateTime.utc(2026, 9, 1),
    );
    expect(
      (await isar.expeditionRuns.get(
        expeditionRunId,
      ))!.members.single.characterId,
      leader.id,
    );
    await isar.writeTxn(isar.expeditionRuns.clear);

    await seedGauntletTicket();
    final gauntletRunId = await GauntletService(
      isar,
    ).enter(characterIds: [leader.id], supplyCap: 3);
    expect(
      (await isar.bossGauntletRuns.get(
        gauntletRunId,
      ))!.members.single.characterId,
      leader.id,
    );
  });

  test('掌门闭关时七类生产 admission 全部 fail closed 且不建活动', () async {
    final leader = await seedLeader();
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      leader.currentRetreatSessionId = 91;
      await isar.characters.put(leader);
    });
    await seedGauntletTicket();

    await expectLater(
      MainlineParticipantSnapshotService(
        isar,
      ).resolve(mainlineRequest(leader.id)),
      throwsA(isA<MainlineParticipationRefusedError>()),
    );
    await expectLater(
      resolveTowerParticipantSnapshot(
        isar: isar,
        requestedParticipantId: leader.id,
      ),
      throwsStateError,
    );
    await expectLater(
      resolveLightFootParticipantSnapshot(
        isar: isar,
        requestedParticipantId: leader.id,
      ),
      throwsStateError,
    );
    await expectLater(
      resolveMassBattleParticipantSnapshot(
        isar: isar,
        requestedParticipantId: leader.id,
      ),
      throwsStateError,
    );
    await expectLater(
      resolveInnerDemonParticipantSnapshot(
        isar: isar,
        request: innerDemonRequest(leader.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: leader.id,
      ),
      throwsStateError,
    );
    await expectLater(
      ExpeditionService(isar).dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(characterId: leader.id),
        policy: ExpeditionPolicy.yanJingCaiYao,
      ),
      throwsStateError,
    );
    await expectLater(
      GauntletService(isar).enter(characterIds: [leader.id], supplyCap: 3),
      throwsStateError,
    );

    expect(await isar.expeditionRuns.count(), 0);
    expect(await isar.bossGauntletRuns.count(), 0);
    expect(
      (await isar.inventoryItems.getByDefId(
        GauntletService.ticketDefId,
      ))!.quantity,
      1,
    );
  });
}
