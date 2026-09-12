import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;
  const kCharId = 10;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_passive_settle_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final ch =
        Character.create(
            name: 'hero',
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            attributes: Attributes(),
            rarity: RarityTier.biaoZhun,
            lineageRole: LineageRole.founder,
            createdAt: DateTime(2026, 1, 1),
            internalForce: 500,
          )
          ..id = kCharId
          ..level = 77
          ..levelExp = 4321;
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.characters.put(ch);
      final save = (await IsarSetup.currentSaveData())!;
      save.founderCharacterId = kCharId;
      save.activeCharacterIds = [kCharId];
      save.createdAt = DateTime(2026, 6, 14);
      save.lastOnlineAt = DateTime(2026, 6, 15, 2);
      save.passiveLastSettledAt = save.lastOnlineAt;
      await IsarSetup.instance.saveDatas.put(save);
    });
  });

  tearDown(() async => await IsarSetup.close());

  test('settle 发放磨剑石入包 + 经验入角色 + 累计 +=', () async {
    final result = await OfflinePassiveService.settleWindow(
      isar: IsarSetup.instance,
      updatePresence: true,
      now: DateTime(2026, 6, 15, 12),
    );
    expect(result!.mojianshi, 2);
    expect(result.experience, 30);

    final item = await IsarSetup.instance.inventoryItems.getByDefId(
      'item_mojianshi',
    );
    expect(item?.quantity, 2);

    final save = (await IsarSetup.currentSaveData())!;
    expect(save.totalPassiveMojianshi, 2);
    expect(save.totalPassiveExperience, 30);
    expect(save.lastOnlineAt, DateTime(2026, 6, 15, 12)); // 重置基准

    final character = await IsarSetup.instance.characters.get(kCharId);
    expect(character!.experience, greaterThan(0));
    expect(character.level, 77);
    expect(character.levelExp, 4321);

    final silver = await IsarSetup.instance.inventoryItems.getByDefId(
      'item_silver',
    );
    expect(silver, isNull, reason: '被动离线只产经验/磨剑石,不可新建银两行');
  });

  test(
    'successive settlements preserve fractional material across windows',
    () async {
      await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        updatePresence: true,
        now: DateTime(2026, 6, 15, 12),
      );
      await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        updatePresence: true,
        now: DateTime(2026, 6, 15, 22),
      );
      final item = await IsarSetup.instance.inventoryItems.getByDefId(
        'item_mojianshi',
      );
      expect(item?.quantity, 5);
      final save = (await IsarSetup.currentSaveData())!;
      expect(save.totalPassiveMojianshi, 5);
      expect(save.totalPassiveExperience, 60);
      expect(save.lastOnlineAt, DateTime(2026, 6, 15, 22));
    },
  );

  test('settle 不改动既有 item_silver 数量', () async {
    final silver = InventoryItem()
      ..defId = 'item_silver'
      ..itemType = ItemType.silver
      ..quantity = 123
      ..firstObtainedAt = DateTime(2026, 6, 1)
      ..lastObtainedAt = DateTime(2026, 6, 1);
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.inventoryItems.put(silver),
    );

    await OfflinePassiveService.settleWindow(
      isar: IsarSetup.instance,
      updatePresence: true,
      now: DateTime(2026, 6, 15, 12),
    );

    final saved = await IsarSetup.instance.inventoryItems.getByDefId(
      'item_silver',
    );
    expect(saved, isNotNull);
    expect(saved!.quantity, 123, reason: '被动离线结算不应提供或扣减银两');
  });

  test(
    'repeated timestamps and clock rollback cannot issue a second grant',
    () async {
      final at = DateTime(2026, 6, 15, 10);
      await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: at,
      );
      expect(
        await OfflinePassiveService.settleWindow(
          isar: IsarSetup.instance,
          now: at,
        ),
        isNull,
      );
      expect(
        await OfflinePassiveService.settleWindow(
          isar: IsarSetup.instance,
          now: at.subtract(const Duration(hours: 1)),
        ),
        isNull,
      );
      final save = (await IsarSetup.currentSaveData())!;
      expect(save.totalPassiveExperience, 24);
      expect(save.totalPassiveMojianshi, 2);
      expect(save.passiveLastSettledAt, at);
    },
  );

  test('a presence timestamp write cannot erase ordinary yield time', () async {
    final presence = DateTime(2026, 6, 15, 6);
    await IsarSetup.touchOnlineNow(now: presence);
    final result = await OfflinePassiveService.settleWindow(
      isar: IsarSetup.instance,
      now: DateTime(2026, 6, 15, 10),
    );
    expect(result?.experience, 24);
    expect(result?.mojianshi, 2);
    expect((await IsarSetup.currentSaveData())!.lastOnlineAt, presence);
  });

  test(
    'a missing current leader preserves time until the pointer is repaired',
    () async {
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.currentSaveData())!;
        save.founderCharacterId = 999;
        await IsarSetup.instance.saveDatas.put(save);
      });
      final at = DateTime(2026, 6, 15, 10);
      expect(
        await OfflinePassiveService.settleWindow(
          isar: IsarSetup.instance,
          now: at,
          updatePresence: true,
        ),
        isNull,
      );
      var save = (await IsarSetup.currentSaveData())!;
      expect(save.passiveLastSettledAt, DateTime(2026, 6, 15, 2));
      expect(save.lastOnlineAt, DateTime(2026, 6, 15, 2));
      expect(save.totalPassiveExperience, 0);
      await IsarSetup.instance.writeTxn(() async {
        save = (await IsarSetup.currentSaveData())!;
        save.founderCharacterId = kCharId;
        await IsarSetup.instance.saveDatas.put(save);
      });
      final result = await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: at,
      );
      expect(result?.experience, 24);
      expect(result?.mojianshi, 2);
    },
  );

  test(
    'a failed enclosing transaction rolls back grant, fractions and timestamp',
    () async {
      final at = DateTime(2026, 6, 15, 10, 10);
      await expectLater(
        IsarSetup.instance.writeTxn(() async {
          await OfflinePassiveService.settleWithinTxn(
            isar: IsarSetup.instance,
            now: at,
          );
          throw StateError('enclosing action failed');
        }),
        throwsStateError,
      );
      final save = (await IsarSetup.currentSaveData())!;
      final character = (await IsarSetup.instance.characters.get(kCharId))!;
      expect(save.passiveLastSettledAt, DateTime(2026, 6, 15, 2));
      expect(save.totalPassiveExperience, 0);
      expect(save.passiveMojianshiRemainder, 0);
      expect(character.experience, 0);
      expect(character.passiveExperienceRemainder, 0);
      expect(
        await IsarSetup.instance.inventoryItems.getByDefId('item_mojianshi'),
        isNull,
      );
      final retry = await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: at,
      );
      expect(retry?.experience, 24);
      expect(retry?.mojianshi, 2);
    },
  );

  test(
    'new injury boundary and heartbeat preserve injuries; return recovers only time since injury',
    () async {
      await IsarSetup.instance.writeTxn(() async {
        await OfflinePassiveService.settleWithinTxn(
          isar: IsarSetup.instance,
          now: DateTime(2026, 6, 15, 10),
          updatePresence: true,
        );
        final character = (await IsarSetup.instance.characters.get(kCharId))!;
        character.lightInjuryStacks = 3;
        character.injuryHoursRemaining = 6;
        character.innerBreathDisorderHoursRemaining = 6;
        await IsarSetup.instance.characters.put(character);
      });
      await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: DateTime(2026, 6, 15, 10),
        updatePresence: true,
      );
      var character = (await IsarSetup.instance.characters.get(kCharId))!;
      expect(character.lightInjuryStacks, 3);
      expect(character.injuryHoursRemaining, 6);
      expect(character.innerBreathDisorderHoursRemaining, 6);

      // An ordinary reward boundary may already settle all product time. Recovery
      // must still use the independent presence boundary when the app returns.
      await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: DateTime(2026, 6, 15, 11),
      );
      await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: DateTime(2026, 6, 15, 11),
        recoverInjuries: true,
        updatePresence: true,
      );
      character = (await IsarSetup.instance.characters.get(kCharId))!;
      expect(character.lightInjuryStacks, 0);
      expect(character.injuryHoursRemaining, 5);
      expect(character.innerBreathDisorderHoursRemaining, 5);
    },
  );

  test(
    'fractional experience stays with its owner when the leader changes',
    () async {
      const nextId = 11;
      await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: DateTime(2026, 6, 15, 2, 10),
      );
      await IsarSetup.instance.writeTxn(() async {
        await OfflinePassiveService.settleWithinTxn(
          isar: IsarSetup.instance,
          now: DateTime(2026, 6, 15, 2, 10),
        );
        await IsarSetup.instance.characters.put(
          Character.create(
            name: 'new leader',
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            attributes: Attributes(),
            rarity: RarityTier.biaoZhun,
            lineageRole: LineageRole.founder,
            createdAt: DateTime(2026, 6, 15),
          )..id = nextId,
        );
        final save = (await IsarSetup.currentSaveData())!;
        save.founderCharacterId = nextId;
        // Keep the old active roster to prove the authoritative pointer is used.
        await IsarSetup.instance.saveDatas.put(save);
      });
      await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: DateTime(2026, 6, 15, 2, 20),
      );
      final previous = (await IsarSetup.instance.characters.get(kCharId))!;
      final next = (await IsarSetup.instance.characters.get(nextId))!;
      expect(previous.experience, 0);
      expect(previous.passiveExperienceRemainder, closeTo(0.5, 1e-9));
      expect(next.experience, 0);
      expect(next.passiveExperienceRemainder, closeTo(0.5, 1e-9));
    },
  );

  test(
    'active retreat excludes ordinary accrual and preserves earlier fractions',
    () async {
      await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: DateTime(2026, 6, 15, 2, 10),
      );
      final session = RetreatSession()
        ..saveDataId = 1
        ..mapType = RetreatMapType.shanLin
        ..startedAt = DateTime(2026, 6, 15, 2, 10);
      await IsarSetup.instance.writeTxn(() async {
        session.id = await IsarSetup.instance.retreatSessions.put(session);
      });
      expect(
        await OfflinePassiveService.settleWindow(
          isar: IsarSetup.instance,
          now: DateTime(2026, 6, 20, 2, 10),
        ),
        isNull,
      );
      expect((await IsarSetup.currentSaveData())!.totalPassiveExperience, 0);
      await IsarSetup.instance.writeTxn(() async {
        session.status = RetreatStatus.completed;
        await IsarSetup.instance.retreatSessions.put(session);
        await OfflinePassiveService.resumeAfterRetreatWithinTxn(
          isar: IsarSetup.instance,
          now: DateTime(2026, 6, 20, 2, 10),
        );
      });
      final resumed = await OfflinePassiveService.settleWindow(
        isar: IsarSetup.instance,
        now: DateTime(2026, 6, 20, 2, 20),
      );
      expect(resumed?.experience, 1);
      expect(resumed?.mojianshi, 0);
    },
  );
}
