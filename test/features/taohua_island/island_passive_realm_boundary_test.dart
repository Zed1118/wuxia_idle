import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/island_building_state.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_action_service.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_settle_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 10);
  final t20 = t0.add(const Duration(minutes: 20));
  final t60 = t0.add(const Duration(hours: 1));
  late Directory tempDir;

  Future<SaveData> saved() async =>
      (await IsarSetup.instance.saveDatas.get(0))!;
  IslandBuildingState forge(SaveData save) => save.islandBuildings.firstWhere(
    (state) => state.type == BuildingType.daZaoTai,
  );
  Future<Character> founder() async => (await IsarSetup.instance.characters.get(
    (await saved()).founderCharacterId!,
  ))!;

  // A retained recipe after succession is temporarily realm-locked. Enough
  // source material and free capacity isolate the realm boundary from the
  // island's separate source/cap partitioning behavior.
  Future<void> seed({bool initialized = true, DateTime? islandAnchor}) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final character =
          Character.create(
              name: 'Successor',
              realmTier: RealmTier.xueTu,
              realmLayer: RealmLayer.dengFeng,
              attributes: Attributes(),
              rarity: RarityTier.biaoZhun,
              lineageRole: LineageRole.founder,
              createdAt: t0.subtract(const Duration(days: 1)),
            )
            ..id = 10
            ..isFounder = true
            ..experience =
                GameRepository.instance
                    .getRealm(RealmTier.xueTu, RealmLayer.dengFeng)
                    .experienceToNext -
                1;
      await isar.characters.put(character);
      final save = await saved();
      save.founderCharacterId = character.id;
      save.activeCharacterIds = [character.id];
      save.createdAt = t0.subtract(const Duration(days: 1));
      save.lastOnlineAt = t0;
      save.passiveLastSettledAt = t0;
      save.passiveMojianshiRemainder = 0;
      save.totalPassiveExperience = 0;
      save.totalPassiveMojianshi = 0;
      save.islandLastSettledAt = initialized ? islandAnchor ?? t0 : null;
      save.islandBuildings = initialized
          ? [
              IslandBuildingState()
                ..type = BuildingType.tieJiangChang
                ..stored = 100,
              IslandBuildingState()
                ..type = BuildingType.daZaoTai
                ..activeRecipeId = 'forge_duancai',
            ]
          : [];
      await isar.saveDatas.put(save);
      final stages = GameRepository.instance.stageDefs.keys.toList();
      await isar.mainlineProgress.put(
        MainlineProgress()
          ..id = 1
          ..saveDataId = save.slotId
          ..clearedStageIds = stages
          ..clearedAt = List.filled(stages.length, t0),
      );
    });
  }

  Future<void> passive(DateTime now, {bool beforeGrowth = false}) async {
    await OfflinePassiveService.settleWindow(
      isar: IsarSetup.instance,
      now: now,
      settleIslandBeforeGrowth: beforeGrowth,
    );
  }

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_island_realm_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await seed();
  });
  tearDown(() async {
    if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
    await tempDir.delete(recursive: true);
  });

  test(
    'actual passive realm boundary preserves production across island visits',
    () async {
      // Current data: one missing exp / 3 exp per hour => tier changes at t20.
      // Forge rate 0.8 * L1 source synergy 1.02 = 0.816 per hour; only the
      // final 40 minutes are unlocked, hence 0.544, never 0.816 or 0.68.
      expect(GameRepository.instance.numbers.passiveIdle.baseExpPerHour, 3);
      await passive(t60);
      expect((await founder()).realmTier, RealmTier.sanLiu);
      expect((await saved()).islandLastSettledAt!.toUtc(), t20);
      expect(forge(await saved()).productStored('item_duancai'), 0);
      await IslandSettleService.settle(await saved(), t60);
      final once = forge(await saved()).productStored('item_duancai');
      expect(once, closeTo(0.544, 1e-9));

      await seed();
      final t10 = t0.add(const Duration(minutes: 10));
      await passive(t10);
      await IslandSettleService.settle(await saved(), t10);
      await passive(t60);
      await IslandSettleService.settle(await saved(), t60);
      expect(
        forge(await saved()).productStored('item_duancai'),
        closeTo(once, 1e-9),
      );
    },
  );

  test(
    'island visit before the next heartbeat cannot overtake the realm boundary',
    () async {
      final visitAt = t20.add(const Duration(seconds: 30));
      await IslandSettleService.settle(await saved(), visitAt);
      expect((await founder()).realmTier, RealmTier.sanLiu);
      expect(
        forge(await saved()).productStored('item_duancai'),
        closeTo(0.0068, 1e-9),
      );
      await passive(t0.add(const Duration(minutes: 21)));
      await IslandSettleService.settle(await saved(), t60);
      expect(
        forge(await saved()).productStored('item_duancai'),
        closeTo(0.544, 1e-9),
      );
    },
  );

  test(
    'older island anchor settles under the old realm before passive advancement',
    () async {
      await seed(islandAnchor: t0.subtract(const Duration(hours: 2)));
      await passive(t60);
      expect((await saved()).islandLastSettledAt!.toUtc(), t20);
      expect(forge(await saved()).productStored('item_duancai'), 0);
      await IslandSettleService.settle(await saved(), t60);
      expect(
        forge(await saved()).productStored('item_duancai'),
        closeTo(0.544, 1e-9),
      );
    },
  );

  test(
    'ordinary heartbeats do not partition the island when the realm is unchanged',
    () async {
      await passive(t0.add(const Duration(minutes: 10)));
      expect((await saved()).islandLastSettledAt!.toUtc(), t0);
      expect(forge(await saved()).totalStored, 0);
    },
  );

  test(
    'passive tier changes and external growth never initialize an unopened island',
    () async {
      await seed(initialized: false);
      await passive(t60, beforeGrowth: true);
      expect((await founder()).realmTier, RealmTier.sanLiu);
      expect((await saved()).islandLastSettledAt, isNull);
      expect((await saved()).islandBuildings, isEmpty);
    },
  );

  test(
    'first island opening synchronizes the founder without backdating island production',
    () async {
      await seed(initialized: false);
      await IslandSettleService.ensureInitialized(await saved(), t60);
      expect((await founder()).realmTier, RealmTier.sanLiu);
      expect((await saved()).islandLastSettledAt!.toUtc(), t60);
      expect((await saved()).passiveLastSettledAt!.toUtc(), t60);
      expect((await saved()).islandBuildings, isNotEmpty);
      expect(
        (await saved()).islandBuildings.every(
          (state) => state.totalStored == 0,
        ),
        isTrue,
      );
    },
  );

  test(
    'external growth flag settles an active retreat island without passive rewards',
    () async {
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final save = await saved();
        forge(save).activeRecipeId = 'forge_mojianshi';
        await isar.saveDatas.put(save);
        await isar.retreatSessions.put(
          RetreatSession()
            ..saveDataId = save.slotId
            ..mapType = RetreatMapType.shanLin
            ..startedAt = t0
            ..realmTierAtStart = RealmTier.xueTu,
        );
      });
      final before = (await founder()).experience;
      await passive(t60, beforeGrowth: true);
      expect((await founder()).experience, before);
      expect((await saved()).totalPassiveExperience, 0);
      expect((await saved()).islandLastSettledAt!.toUtc(), t60);
      expect(
        forge(await saved()).productStored('item_mojianshi'),
        closeTo(1.53, 1e-9),
      );
    },
  );

  test(
    'harvest and recipe selection settle pending passive advancement first',
    () async {
      await IslandSettleService.harvest(await saved(), t60);
      expect((await founder()).realmTier, RealmTier.sanLiu);
      expect(
        forge(await saved()).productStored('item_duancai'),
        closeTo(0.544, 1e-9),
      );
      await seed();
      expect(
        await IslandActionService.selectRecipe(
          save: await saved(),
          buildingType: BuildingType.daZaoTai,
          recipeId: 'forge_duancai',
          founderRealmIndex: RealmTier.xueTu.index,
          now: t60,
        ),
        SelectRecipeResult.ok,
      );
      expect((await founder()).realmTier, RealmTier.sanLiu);
      expect(
        forge(await saved()).productStored('item_duancai'),
        closeTo(0.544, 1e-9),
      );
    },
  );

  test(
    'upgrade commits passive growth and settles the old building level atomically',
    () async {
      final isar = IsarSetup.instance;
      final config = GameRepository.instance.numbers.taohuaIsland.buildingOf(
        BuildingType.daZaoTai,
      );
      await isar.writeTxn(() async {
        for (final entry in {
          'item_silver': config.upgradeSilverFor(1),
          config.upgradeMaterialItem: config.upgradeMaterialFor(1),
        }.entries) {
          await isar.inventoryItems.put(
            InventoryItem()
              ..defId = entry.key
              ..itemType = ItemType.fromDefId(entry.key)
              ..quantity = entry.value
              ..firstObtainedAt = t0
              ..lastObtainedAt = t0,
          );
        }
      });
      expect(
        await IslandActionService.upgrade(
          save: await saved(),
          buildingType: BuildingType.daZaoTai,
          founderRealmIndex: RealmTier.xueTu.index,
          now: t60,
        ),
        UpgradeResult.ok,
      );
      expect((await founder()).realmTier, RealmTier.sanLiu);
      expect((await saved()).totalPassiveExperience, 4);
      expect((await saved()).passiveLastSettledAt!.toUtc(), t60);
      expect((await saved()).islandLastSettledAt!.toUtc(), t60);
      expect(forge(await saved()).level, 2);
      expect(
        forge(await saved()).productStored('item_duancai'),
        closeTo(0.544, 1e-9),
      );
      expect(
        (await isar.inventoryItems.getByDefId('item_silver'))!.quantity,
        0,
      );
      expect(
        (await isar.inventoryItems.getByDefId(
          config.upgradeMaterialItem,
        ))!.quantity,
        0,
      );
      await IslandSettleService.settle(
        await saved(),
        t60.add(const Duration(hours: 1)),
      );
      expect(
        forge(await saved()).productStored('item_duancai'),
        closeTo(2.176, 1e-9),
      );
    },
  );

  test(
    'failed action rolls back pending passive and island settlement together',
    () async {
      final before = await founder();
      expect(
        await IslandActionService.selectRecipe(
          save: await saved(),
          buildingType: BuildingType.daZaoTai,
          recipeId: 'forge_xinxue',
          founderRealmIndex: RealmTier.wuSheng.index,
          now: t60,
        ),
        SelectRecipeResult.realmLocked,
      );
      expect((await founder()).experience, before.experience);
      expect((await founder()).realmTier, before.realmTier);
      expect((await saved()).passiveLastSettledAt!.toUtc(), t0);
      expect((await saved()).islandLastSettledAt!.toUtc(), t0);
      expect(forge(await saved()).productStored('item_duancai'), 0);
      expect(
        await IsarSetup.instance.inventoryItems.getByDefId('item_mojianshi'),
        isNull,
      );
    },
  );
}
