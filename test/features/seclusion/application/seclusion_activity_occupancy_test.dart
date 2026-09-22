import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/application/character_occupancy_service.dart';
import 'package:wuxia_idle/features/activity/domain/activity_occupancy.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/lineup/application/disciple_scheduling_provider.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/phase0a_ch1_founder_profile.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory directory;
  late Isar isar;
  late int leaderId;
  final now = DateTime(2026, 9, 22, 12);

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('seclusion_occupancy_');
    await IsarSetup.init(directory: directory, inspector: false);
    isar = IsarSetup.instance;
    final profile = await seedPhase0aCh1FounderProfile(
      isar: isar,
      schoolId: 'yin_rou',
      originId: 'mountain_wanderer',
      fateId: 'balanced_seed',
      rngSeed: 20260922,
    );
    leaderId = profile.snapshot.characterId;
    await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      save.createdAt = now;
      save.lastOnlineAt = now;
      save.passiveLastSettledAt = now;
      await isar.saveDatas.put(save);
      await isar.inventoryItems.put(
        InventoryItem()
          ..defId = GauntletService.ticketDefId
          ..itemType = ItemType.ticket
          ..quantity = 1
          ..firstObtainedAt = now
          ..lastObtainedAt = now,
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    await directory.delete(recursive: true);
  });

  Future<RetreatSession> startRetreat(int characterId) async {
    final character = (await isar.characters.get(characterId))!;
    return SeclusionService(isar: isar).startRetreat(
      mapType: RetreatMapType.shanLin,
      saveDataId: 1,
      characterId: characterId,
      charRealmTier: character.realmTier,
      maps: GameRepository.instance.seclusionMaps,
      now: now,
    );
  }

  Future<int> dispatchLeader() => ExpeditionService(isar).dispatchRequest(
    request: ExpeditionService.dispatchRequestFor(characterId: leaderId),
    policy: ExpeditionPolicy.yanJingCaiYao,
    now: now,
  );

  Future<int> enterGauntlet() =>
      GauntletService(isar).enter(characterIds: [leaderId], supplyCap: 0);

  test('真实远征派遣后拒绝同角色闭关，原占用与调度保持可读', () async {
    final runId = await dispatchLeader();
    final saveBefore = (await isar.saveDatas.get(0))!;

    await expectLater(
      startRetreat(leaderId),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          UiStrings.seclusionCharacterOccupied,
        ),
      ),
    );

    expect(await isar.retreatSessions.count(), 0);
    expect(
      (await isar.characters.get(leaderId))!.currentRetreatSessionId,
      isNull,
    );
    final run = (await isar.expeditionRuns.get(runId))!;
    expect(run.members.single.characterId, leaderId);
    expect(run.currentNode, 0);
    expect(
      (await isar.saveDatas.get(0))!.expeditionRunSerial,
      saveBefore.expeditionRunSerial,
    );
    final occupancy = await CharacterOccupancyService(isar).snapshot();
    expect(occupancy.entries.single.kind, ActivityKind.expedition);
    await loadDiscipleSchedulingSummary(isar);
  });

  test('真实断魂庄入场后拒绝同角色闭关，不重复扣帖或改会话', () async {
    final runId = await enterGauntlet();
    final saveBefore = (await isar.saveDatas.get(0))!;

    await expectLater(
      startRetreat(leaderId),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          UiStrings.seclusionCharacterOccupied,
        ),
      ),
    );

    expect(await isar.retreatSessions.count(), 0);
    expect(
      (await isar.characters.get(leaderId))!.currentRetreatSessionId,
      isNull,
    );
    expect(
      (await isar.bossGauntletRuns.get(runId))!.members.single.characterId,
      leaderId,
    );
    expect(
      (await isar.inventoryItems.getByDefId(
        GauntletService.ticketDefId,
      ))!.quantity,
      0,
    );
    expect(
      (await isar.saveDatas.get(0))!.gauntletRunSerial,
      saveBefore.gauntletRunSerial,
    );
    final occupancy = await CharacterOccupancyService(isar).snapshot();
    expect(occupancy.entries.single.kind, ActivityKind.bossGauntlet);
    await loadDiscipleSchedulingSummary(isar);
  });

  test('空闲掌门仍正常开始闭关', () async {
    final session = await startRetreat(leaderId);
    expect(
      (await isar.characters.get(leaderId))!.currentRetreatSessionId,
      session.id,
    );
    expect(session.status, RetreatStatus.active);
    await loadDiscipleSchedulingSummary(isar);
  });

  test('占用只约束实际角色，不阻止另一名空闲门人闭关', () async {
    await dispatchLeader();
    final disciple = Character.create(
      name: '休养门人',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      createdAt: now,
    )..masterId = leaderId;
    await isar.writeTxn(() => isar.characters.put(disciple));

    final session = await startRetreat(disciple.id);
    expect(
      (await isar.characters.get(disciple.id))!.currentRetreatSessionId,
      session.id,
    );
    expect(
      (await isar.characters.get(leaderId))!.currentRetreatSessionId,
      isNull,
    );
    await loadDiscipleSchedulingSummary(isar);
  });

  test('反向顺序：闭关后两个真实活动入口均拒绝且不消耗资源', () async {
    final session = await startRetreat(leaderId);
    final saveBefore = (await isar.saveDatas.get(0))!;

    await expectLater(dispatchLeader(), throwsStateError);
    await expectLater(enterGauntlet(), throwsStateError);

    expect(await isar.expeditionRuns.count(), 0);
    expect(await isar.bossGauntletRuns.count(), 0);
    expect(
      (await isar.inventoryItems.getByDefId(
        GauntletService.ticketDefId,
      ))!.quantity,
      1,
    );
    final saveAfter = (await isar.saveDatas.get(0))!;
    expect(saveAfter.expeditionRunSerial, saveBefore.expeditionRunSerial);
    expect(saveAfter.gauntletRunSerial, saveBefore.gauntletRunSerial);
    expect(
      (await isar.characters.get(leaderId))!.currentRetreatSessionId,
      session.id,
    );
  });
}
