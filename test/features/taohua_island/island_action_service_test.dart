import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_action_service.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_settle_service.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';

/// IslandActionService 升级+选配方 测试。
///
/// 体例同 island_settle_service_test：setUpAll + Isar 临时目录 + test()。

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_island_action_');
    await IsarSetup.init(directory: tempDir, inspector: false);

    // 初始化桃花岛（建 4 建筑）
    final isar = IsarSetup.instance;
    final save = (await isar.saveDatas.get(0))!;
    await IslandSettleService.ensureInitialized(save, DateTime(2026, 6, 25));
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ── helper：给背包写入指定 item ──────────────────────────────────────────
  Future<void> seedInventory(String defId, int quantity) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final existing = await isar.inventoryItems.getByDefId(defId);
      if (existing != null) {
        existing.quantity = quantity;
        await isar.inventoryItems.put(existing);
      } else {
        final itemType = ItemType.fromDefId(defId);
        await isar.inventoryItems.put(
          InventoryItem()
            ..defId = defId
            ..itemType = itemType
            ..quantity = quantity
            ..firstObtainedAt = DateTime.now()
            ..lastObtainedAt = DateTime.now(),
        );
      }
    });
  }

  // ── helper：读背包数量 ────────────────────────────────────────────────────
  Future<int> inventoryQty(String defId) async {
    final item =
        await IsarSetup.instance.inventoryItems.getByDefId(defId);
    return item?.quantity ?? 0;
  }

  // ── helper：读建筑等级 ────────────────────────────────────────────────────
  Future<int> buildingLevel(BuildingType type) async {
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    return save.islandBuildings.firstWhere((b) => b.type == type).level;
  }

  // ── helper：读建筑 activeRecipeId ────────────────────────────────────────
  Future<String?> activeRecipeId(BuildingType type) async {
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    return save.islandBuildings.firstWhere((b) => b.type == type).activeRecipeId;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // upgrade 测试组
  // ════════════════════════════════════════════════════════════════════════════

  // ── T1: upgrade 成功 ──────────────────────────────────────────────────────
  test('T1: upgrade 成功 → level+1、银两/材料被扣', () async {
    // 铁匠厂 level1 升级需：silver=500，material=item_jingtie×40
    await seedInventory('item_silver', 1000);
    await seedInventory('item_jingtie', 100);

    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final result = await IslandActionService.upgrade(
      save: save,
      buildingType: BuildingType.tieJiangChang,
      founderRealmIndex: 0,
    );

    expect(result, UpgradeResult.ok);
    expect(await buildingLevel(BuildingType.tieJiangChang), 2,
        reason: 'level 应升到 2');
    expect(await inventoryQty('item_silver'), 500,
        reason: '银两被扣 500');
    expect(await inventoryQty('item_jingtie'), 60,
        reason: '精铁被扣 40');
  });

  // ── T2: maxLevelReached ───────────────────────────────────────────────────
  test('T2: maxLevelReached → 拒绝，level/银两/材料不变', () async {
    // 把建筑等级手动设为 max_level=5
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final s = (await isar.saveDatas.get(0))!;
      s.islandBuildings
          .firstWhere((b) => b.type == BuildingType.tieJiangChang)
          .level = 5;
      await isar.saveDatas.put(s);
    });

    await seedInventory('item_silver', 9999);
    await seedInventory('item_jingtie', 9999);

    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final result = await IslandActionService.upgrade(
      save: save,
      buildingType: BuildingType.tieJiangChang,
      founderRealmIndex: 0,
    );

    expect(result, UpgradeResult.maxLevelReached);
    expect(await buildingLevel(BuildingType.tieJiangChang), 5,
        reason: 'level 不应变化');
    expect(await inventoryQty('item_silver'), 9999,
        reason: '银两不扣');
    expect(await inventoryQty('item_jingtie'), 9999,
        reason: '材料不扣');
  });

  // ── T3: notEnoughSilver → 拒绝，无副作用 ─────────────────────────────────
  test('T3: notEnoughSilver → 拒绝，level/银两/材料原子不变', () async {
    // 银两不足（只给 100，需要 500）
    await seedInventory('item_silver', 100);
    await seedInventory('item_jingtie', 999);

    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final result = await IslandActionService.upgrade(
      save: save,
      buildingType: BuildingType.tieJiangChang,
      founderRealmIndex: 0,
    );

    expect(result, UpgradeResult.notEnoughSilver);
    expect(await buildingLevel(BuildingType.tieJiangChang), 1,
        reason: 'level 不变');
    expect(await inventoryQty('item_silver'), 100,
        reason: '银两不扣');
    expect(await inventoryQty('item_jingtie'), 999,
        reason: '材料不扣');
  });

  // ── T4: notEnoughMaterial → 拒绝，无副作用 ───────────────────────────────
  test('T4: notEnoughMaterial → 拒绝，level/银两/材料原子不变', () async {
    // 材料不足（只给 10，需要 40）
    await seedInventory('item_silver', 9999);
    await seedInventory('item_jingtie', 10);

    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final result = await IslandActionService.upgrade(
      save: save,
      buildingType: BuildingType.tieJiangChang,
      founderRealmIndex: 0,
    );

    expect(result, UpgradeResult.notEnoughMaterial);
    expect(await buildingLevel(BuildingType.tieJiangChang), 1,
        reason: 'level 不变');
    expect(await inventoryQty('item_silver'), 9999,
        reason: '银两不扣');
    expect(await inventoryQty('item_jingtie'), 10,
        reason: '材料不扣');
  });

  // ── T5: realmLocked（建筑 realmUnlockIndex > founderRealmIndex）───────────
  // 当前配置全部 realm_unlock_index=0，此场景需伪造场景：
  // 用打造台 (processor)，人为 set level=4，然后让我们改用一个 realm>0 的建筑。
  // 由于所有建筑 realmUnlockIndex==0，此检查实际上在当前配置下永不触发，
  // 但代码路径须测。使用 founderRealmIndex=-1 让 0 > -1 触发。
  test('T5: realmLocked（founderRealmIndex 低于 buildingCfg.realmUnlockIndex）→ 拒绝', () async {
    await seedInventory('item_silver', 9999);
    await seedInventory('item_jingtie', 9999);

    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    // founderRealmIndex=-1 使 realmUnlockIndex=0 > -1 → realmLocked
    final result = await IslandActionService.upgrade(
      save: save,
      buildingType: BuildingType.tieJiangChang,
      founderRealmIndex: -1,
    );

    expect(result, UpgradeResult.realmLocked);
    expect(await buildingLevel(BuildingType.tieJiangChang), 1,
        reason: 'level 不变');
    expect(await inventoryQty('item_silver'), 9999,
        reason: '银两不扣');
    expect(await inventoryQty('item_jingtie'), 9999,
        reason: '材料不扣');
  });

  // ════════════════════════════════════════════════════════════════════════════
  // selectRecipe 测试组
  // ════════════════════════════════════════════════════════════════════════════

  // ── T6: selectRecipe 成功（realm0 配方）─────────────────────────────────
  test('T6: selectRecipe 成功 → activeRecipeId 更新', () async {
    // 打造台默认激活 forge_mojianshi，切换到同一个（或另一个同 realm 配方）
    // 先验证默认值
    expect(await activeRecipeId(BuildingType.daZaoTai), 'forge_mojianshi');

    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final result = await IslandActionService.selectRecipe(
      save: save,
      buildingType: BuildingType.daZaoTai,
      recipeId: 'forge_mojianshi',
      founderRealmIndex: 0,
    );

    expect(result, SelectRecipeResult.ok);
    expect(await activeRecipeId(BuildingType.daZaoTai), 'forge_mojianshi');
  });

  // ── T7: selectRecipe realmLocked → activeRecipeId 不变 ──────────────────
  test('T7: selectRecipe realmLocked（高阶配方+低境界）→ 拒绝，activeRecipeId 不变', () async {
    // forge_xinxue 的 realm_unlock_index=3，founderRealmIndex=0 → realmLocked
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final result = await IslandActionService.selectRecipe(
      save: save,
      buildingType: BuildingType.daZaoTai,
      recipeId: 'forge_xinxue',
      founderRealmIndex: 0,
    );

    expect(result, SelectRecipeResult.realmLocked);
    expect(await activeRecipeId(BuildingType.daZaoTai), 'forge_mojianshi',
        reason: 'activeRecipeId 不应变化');
  });

  // ── T8: selectRecipe notProcessor → 拒绝 ─────────────────────────────────
  test('T8: selectRecipe notProcessor（source 建筑）→ 拒绝', () async {
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final result = await IslandActionService.selectRecipe(
      save: save,
      buildingType: BuildingType.tieJiangChang, // source 建筑
      recipeId: 'forge_mojianshi',
      founderRealmIndex: 0,
    );

    expect(result, SelectRecipeResult.notProcessor);
  });

  // ── T9: selectRecipe recipeNotFound → 拒绝 ───────────────────────────────
  test('T9: selectRecipe recipeNotFound → 拒绝', () async {
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final result = await IslandActionService.selectRecipe(
      save: save,
      buildingType: BuildingType.daZaoTai,
      recipeId: 'nonexistent_recipe',
      founderRealmIndex: 0,
    );

    expect(result, SelectRecipeResult.recipeNotFound);
    expect(await activeRecipeId(BuildingType.daZaoTai), 'forge_mojianshi',
        reason: 'activeRecipeId 不应变化');
  });

  // ── T10: selectRecipe 成功切换到高阶配方（境界够）──────────────────────
  test('T10: selectRecipe 高阶配方+高境界 → 成功切换 activeRecipeId', () async {
    // forge_xinxue realm_unlock_index=3，founderRealmIndex=3 → 可选
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    final result = await IslandActionService.selectRecipe(
      save: save,
      buildingType: BuildingType.daZaoTai,
      recipeId: 'forge_xinxue',
      founderRealmIndex: 3,
    );

    expect(result, SelectRecipeResult.ok);
    expect(await activeRecipeId(BuildingType.daZaoTai), 'forge_xinxue',
        reason: 'activeRecipeId 应切换到 forge_xinxue');
  });
}
