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
import 'package:wuxia_idle/features/taohua_island/application/island_action_service.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_production_service.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_settle_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 10);
  late Directory tempDir;

  Future<SaveData> saved() async =>
      (await IsarSetup.instance.saveDatas.get(0))!;
  IslandBuildingState building(SaveData save, BuildingType type) =>
      save.islandBuildings.firstWhere((state) => state.type == type);
  Future<int> inventory(String output) async =>
      (await IsarSetup.instance.inventoryItems.getByDefId(output))?.quantity ??
      0;

  Future<SelectRecipeResult> select(
    BuildingType type,
    String recipe,
    DateTime now, {
    SaveData? stale,
  }) async => IslandActionService.selectRecipe(
    save: stale ?? await saved(),
    buildingType: type,
    recipeId: recipe,
    founderRealmIndex: RealmTier.yiLiu.index,
    now: now,
  );

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_island_identity_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final founder = Character.create(
        name: 'Founder',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: t0,
      )..isFounder = true;
      final id = await isar.characters.put(founder);
      final save = await saved();
      save.founderCharacterId = id;
      save.activeCharacterIds = [id];
      await isar.saveDatas.put(save);
    });
    await IslandSettleService.ensureInitialized(await saved(), t0);
  });
  tearDown(() async {
    if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
    await tempDir.delete(recursive: true);
  });

  for (final scenario in [
    (
      type: BuildingType.daZaoTai,
      oldItem: 'item_mojianshi',
      newRecipe: 'forge_xinxue',
      newItem: 'item_xinxuejiejing',
    ),
    (
      type: BuildingType.danFang,
      oldItem: 'item_jingyandan_small',
      newRecipe: 'brew_liaoshang',
      newItem: 'item_liaoshangdan',
    ),
  ]) {
    test(
      '${scenario.type.name}: recipe change preserves produced item identity',
      () async {
        final t8 = t0.add(const Duration(hours: 8));
        await IslandSettleService.settle(await saved(), t8);
        final original = building(await saved(), scenario.type);
        final produced = original.productStored(scenario.oldItem);
        expect(produced, greaterThan(1));
        expect(original.stored, 0, reason: 'No processor scalar dual write.');

        expect(
          await select(scenario.type, scenario.newRecipe, t8),
          SelectRecipeResult.ok,
        );
        final switched = building(await saved(), scenario.type);
        expect(switched.activeRecipeId, scenario.newRecipe);
        expect(switched.productStored(scenario.oldItem), produced);
        expect(switched.productStored(scenario.newItem), 0);

        final harvest = await IslandSettleService.harvest(await saved(), t8);
        expect(harvest.gained[scenario.oldItem], produced.floor());
        expect(harvest.gained[scenario.newItem] ?? 0, 0);
        expect(await inventory(scenario.oldItem), produced.floor());
        expect(await inventory(scenario.newItem), 0);
        final remaining = building(await saved(), scenario.type);
        expect(
          remaining.productStored(scenario.oldItem),
          closeTo(produced - produced.floor(), 1e-9),
        );
        expect(remaining.productStored(scenario.newItem), 0);
        if (scenario.type == BuildingType.danFang) {
          expect(harvest.gained['item_lingquanshui'], 32);
        }
      },
    );
  }

  test(
    'harvested fractions stay with the old item through switching and reopening',
    () async {
      final t1 = t0.add(const Duration(hours: 1));
      await IslandSettleService.harvest(await saved(), t1);
      final before = building(await saved(), BuildingType.daZaoTai);
      final oldFraction = before.productStored('item_mojianshi');
      expect(oldFraction, closeTo(0.53, 1e-9));
      expect(
        await select(BuildingType.daZaoTai, 'forge_xinxue', t1),
        SelectRecipeResult.ok,
      );
      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      final reopened = building(await saved(), BuildingType.daZaoTai);
      expect(reopened.productStored('item_mojianshi'), oldFraction);
      expect(reopened.productStored('item_xinxuejiejing'), 0);

      final t3 = t1.add(const Duration(hours: 2));
      await IslandSettleService.settle(await saved(), t3);
      final after = building(await saved(), BuildingType.daZaoTai);
      expect(after.productStored('item_mojianshi'), oldFraction);
      expect(after.productStored('item_xinxuejiejing'), greaterThan(0));
      final harvest = await IslandSettleService.harvest(await saved(), t3);
      expect(harvest.gained['item_mojianshi'] ?? 0, 0);
      expect(
        harvest.gained['item_xinxuejiejing'] ?? 0,
        0,
        reason: 'Fractions of different products cannot combine into an item.',
      );
      expect(after.totalStored, greaterThan(1));
      expect(after.harvestableCount, 0);
    },
  );

  test(
    'switch first settles old recipe and stale replays cannot replace the new state',
    () async {
      final stale = await saved();
      final t8 = t0.add(const Duration(hours: 8));
      expect(
        await select(BuildingType.daZaoTai, 'forge_xinxue', t8, stale: stale),
        SelectRecipeResult.ok,
      );
      final first = building(await saved(), BuildingType.daZaoTai);
      expect(first.productStored('item_mojianshi'), closeTo(12.24, 1e-9));
      expect(first.productStored('item_xinxuejiejing'), 0);
      await IslandSettleService.settle(stale, t8);
      await IslandSettleService.settle(stale, t0);
      expect(
        await select(BuildingType.daZaoTai, 'forge_xinxue', t8, stale: stale),
        SelectRecipeResult.ok,
      );
      final replayed = await saved();
      expect(replayed.islandLastSettledAt!.toUtc(), t8);
      expect(
        building(replayed, BuildingType.daZaoTai).activeRecipeId,
        'forge_xinxue',
      );
      expect(
        building(replayed, BuildingType.daZaoTai).totalStored,
        first.totalStored,
      );

      final results = await Future.wait([
        IslandSettleService.harvest(stale, t8),
        IslandSettleService.harvest(stale, t8),
      ]);
      expect(
        results.fold<int>(
          0,
          (sum, r) => sum + (r.gained['item_mojianshi'] ?? 0),
        ),
        12,
      );
      expect(await inventory('item_mojianshi'), 12);
      expect(await inventory('item_xinxuejiejing'), 0);
    },
  );

  test(
    'concurrent change and harvest preserve old output regardless of transaction order',
    () async {
      final stale = await saved();
      final t8 = t0.add(const Duration(hours: 8));
      await Future.wait([
        select(BuildingType.daZaoTai, 'forge_xinxue', t8, stale: stale),
        IslandSettleService.harvest(stale, t8),
        IslandSettleService.settle(stale, t8),
      ]);
      expect(await inventory('item_mojianshi'), 12);
      expect(await inventory('item_xinxuejiejing'), 0);
      final state = building(await saved(), BuildingType.daZaoTai);
      expect(state.activeRecipeId, 'forge_xinxue');
      expect(state.productStored('item_mojianshi'), closeTo(0.24, 1e-9));
      expect(state.productStored('item_xinxuejiejing'), 0);
    },
  );

  test(
    'rechecks the current founder realm before settling or changing recipe',
    () async {
      final stale = await saved();
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final founder = (await isar.characters.get(stale.founderCharacterId!))!;
        founder.realmTier = RealmTier.xueTu;
        await isar.characters.put(founder);
      });
      expect(
        await select(
          BuildingType.daZaoTai,
          'forge_xinxue',
          t0.add(const Duration(hours: 8)),
          stale: stale,
        ),
        SelectRecipeResult.realmLocked,
      );
      final current = await saved();
      expect(current.islandLastSettledAt!.toUtc(), t0);
      expect(
        building(current, BuildingType.daZaoTai).activeRecipeId,
        'forge_mojianshi',
      );
      expect(building(current, BuildingType.daZaoTai).totalStored, 0);
    },
  );

  test(
    'mixed product stock shares one cap and keeps input states immutable',
    () {
      final cfg = GameRepository.instance.numbers.taohuaIsland;
      final cap = cfg.buildingOf(BuildingType.daZaoTai).capFor(1).toDouble();
      final source = IslandBuildingState()
        ..type = BuildingType.tieJiangChang
        ..stored = 100;
      final processor = IslandBuildingState()
        ..type = BuildingType.daZaoTai
        ..activeRecipeId = 'forge_xinxue'
        ..setProductStored('item_mojianshi', cap - 0.4)
        ..setProductStored('item_xinxuejiejing', 0.2);
      final result = IslandProductionService.settle(
        states: [source, processor],
        config: cfg,
        elapsedHours: 1,
        founderRealmIndex: 3,
      );
      final updated = result.last;
      expect(updated.totalStored, closeTo(cap, 1e-9));
      expect(updated.productStored('item_mojianshi'), cap - 0.4);
      expect(updated.productStored('item_xinxuejiejing'), closeTo(0.4, 1e-9));
      expect(updated.stored, 0);
      expect(processor.productStored('item_xinxuejiejing'), 0.2);
      expect(processor.totalStored, closeTo(cap - 0.2, 1e-9));
    },
  );

  test(
    'same recipe-change schedule produces identical per-item offline and hourly results',
    () async {
      Future<(IslandHarvest, SaveData)> run({required bool hourly}) async {
        final endFirst = t0.add(const Duration(hours: 12));
        final endSecond = t0.add(const Duration(hours: 24));
        if (hourly) {
          for (var hour = 1; hour <= 12; hour++) {
            await IslandSettleService.settle(
              await saved(),
              t0.add(Duration(hours: hour)),
            );
          }
        }
        expect(
          await select(BuildingType.daZaoTai, 'forge_xinxue', endFirst),
          SelectRecipeResult.ok,
        );
        expect(
          await select(BuildingType.danFang, 'brew_liaoshang', endFirst),
          SelectRecipeResult.ok,
        );
        if (hourly) {
          for (var hour = 13; hour <= 24; hour++) {
            await IslandSettleService.settle(
              await saved(),
              t0.add(Duration(hours: hour)),
            );
          }
        }
        final harvest = await IslandSettleService.harvest(
          await saved(),
          endSecond,
        );
        return (harvest, await saved());
      }

      final offline = await run(hourly: false);
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final fresh = await saved();
        fresh.islandBuildings = [];
        fresh.islandLastSettledAt = null;
        await isar.saveDatas.put(fresh);
        await isar.inventoryItems.clear();
      });
      await IslandSettleService.ensureInitialized(await saved(), t0);
      final online = await run(hourly: true);
      expect(online.$1.gained, offline.$1.gained);
      for (final old in offline.$2.islandBuildings) {
        final current = building(online.$2, old.type);
        expect(current.stored, closeTo(old.stored, 1e-9));
        expect(current.activeRecipeId, old.activeRecipeId);
        expect(
          current.productStocks.map((stock) => stock.outputItemId).toSet(),
          old.productStocks.map((stock) => stock.outputItemId).toSet(),
        );
        for (final stock in old.productStocks) {
          expect(
            current.productStored(stock.outputItemId),
            closeTo(stock.stored, 1e-9),
          );
        }
      }
    },
  );

  test(
    'different save slots keep recipe stock and inventory separate',
    () async {
      final t8 = t0.add(const Duration(hours: 8));
      expect(
        await select(BuildingType.daZaoTai, 'forge_xinxue', t8),
        SelectRecipeResult.ok,
      );
      await IslandSettleService.harvest(await saved(), t8);
      await IsarSetup.switchSlot(2, directory: tempDir);
      expect(await inventory('item_mojianshi'), 0);
      await IslandSettleService.ensureInitialized(await saved(), t0);
      await IslandSettleService.harvest(await saved(), t8);
      expect(
        building(await saved(), BuildingType.daZaoTai).activeRecipeId,
        'forge_mojianshi',
      );
      expect(await inventory('item_mojianshi'), 12);
      await IsarSetup.switchSlot(1, directory: tempDir);
      expect(
        building(await saved(), BuildingType.daZaoTai).activeRecipeId,
        'forge_xinxue',
      );
      expect(
        building(
          await saved(),
          BuildingType.daZaoTai,
        ).productStored('item_mojianshi'),
        closeTo(0.24, 1e-9),
      );
      expect(await inventory('item_mojianshi'), 12);
      expect(await inventory('item_xinxuejiejing'), 0);
    },
  );

  test(
    'positive unmigrated stock with a missing recipe aborts without mutating data',
    () async {
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final save = await saved();
        final state = building(save, BuildingType.daZaoTai);
        state.stored = 3.25;
        state.activeRecipeId = 'missing_legacy_recipe';
        await isar.saveDatas.put(save);
      });
      final stale = await saved();
      final t8 = t0.add(const Duration(hours: 8));
      await expectLater(
        select(BuildingType.daZaoTai, 'forge_xinxue', t8),
        throwsStateError,
      );
      await expectLater(
        IslandSettleService.harvest(stale, t8),
        throwsStateError,
      );
      final after = await saved();
      expect(after.islandLastSettledAt!.toUtc(), t0);
      expect(building(after, BuildingType.daZaoTai).stored, 3.25);
      expect(
        building(after, BuildingType.daZaoTai).activeRecipeId,
        'missing_legacy_recipe',
      );
      expect(await inventory('item_xinxuejiejing'), 0);
    },
  );
}
