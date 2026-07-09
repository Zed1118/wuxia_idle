import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/post_combat_invalidation.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_providers.dart';
import 'package:wuxia_idle/features/battle_record/application/boss_memory_service.dart';
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';
import 'package:wuxia_idle/features/weapon_codex/application/equipment_catalog_providers.dart';
import 'package:wuxia_idle/features/weapon_codex/application/equipment_catalog_service.dart';

/// 体检批3 P0-5：战后结算统一失效 helper 验收（TDD）。
///
/// 病理：主菜单三个隐藏入口门控 provider（shopUnlocked / equipmentCatalogCount /
/// bossMemoryCount）+ 银两余额在战斗/扫荡结算路径从不被 invalidate，
/// 首次获银两/装备/杀 Boss 后当次会话入口永不解锁（重启才见）。
///
/// 测法：ProviderContainer + 永久 listener 防 autoDispose 回收缓存
/// （否则每次 read 都是全新计算，测不出 invalidate 的作用，
/// memory: feedback_battle_determinism_test_via_notifier）。
/// helper 接受 `void Function(ProviderOrFamily)`，生产传 ref.invalidate，
/// 测试传 container.invalidate，无 WidgetRef 耦合。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_post_combat_inval_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> seedSilver(int quantity) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final item = InventoryItem()
        ..defId = 'item_silver'
        ..itemType = ItemType.silver
        ..quantity = quantity
        ..firstObtainedAt = DateTime(2026, 1, 1)
        ..lastObtainedAt = DateTime(2026, 1, 1);
      await isar.inventoryItems.put(item);
    });
  }

  Future<void> seedInventoryItem({
    required String defId,
    required ItemType type,
    required int quantity,
  }) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final item = InventoryItem()
        ..defId = defId
        ..itemType = type
        ..quantity = quantity
        ..firstObtainedAt = DateTime(2026, 1, 1)
        ..lastObtainedAt = DateTime(2026, 1, 1);
      await isar.inventoryItems.put(item);
    });
  }

  test('首次获银两 → helper 失效 shopUnlockedProvider → 商店入口解锁', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // 永久 listener 保持 provider alive，否则 autoDispose 每次 read 全新算，测不出缓存失效。
    final sub = container.listen(shopUnlockedProvider, (_, _) {});
    addTearDown(sub.close);

    expect(await container.read(shopUnlockedProvider.future), false);

    await seedSilver(0); // quantity=0 也算「曾获得银两」

    // 未 invalidate 前仍读到缓存的 false（正是 bug 现场）。
    expect(await container.read(shopUnlockedProvider.future), false);

    // 战后结算 helper 失效门控。
    invalidateAfterCombatSettlement(container.invalidate);

    expect(await container.read(shopUnlockedProvider.future), true);
  });

  test('首次获装备 → helper 失效 equipmentCatalogCountProvider → 兵器谱入口解锁', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(equipmentCatalogCountProvider, (_, _) {});
    addTearDown(sub.close);

    expect(await container.read(equipmentCatalogCountProvider.future), 0);

    await EquipmentCatalogService(isar: IsarSetup.instance).recordAcquisitions(
      saveDataId: IsarSetup.currentSlotId,
      defIds: const ['eq_test_sword'],
      from: 'test',
      now: DateTime(2026, 1, 1),
    );

    expect(await container.read(equipmentCatalogCountProvider.future), 0);

    invalidateAfterCombatSettlement(container.invalidate);

    expect(await container.read(equipmentCatalogCountProvider.future), 1);
  });

  test('首次杀 Boss → helper 失效 bossMemoryCountProvider → 战绩册入口解锁', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(bossMemoryCountProvider, (_, _) {});
    addTearDown(sub.close);

    expect(await container.read(bossMemoryCountProvider.future), 0);

    await BossMemoryService(isar: IsarSetup.instance).recordBossVictory(
      saveDataId: IsarSetup.currentSlotId,
      bossKey: 'mainline_boss_test',
      source: BossMemorySource.mainline,
      groupIndex: 1,
      bossName: '测试 Boss',
      totalDamage: 1000,
      critCount: 2,
      totalTicks: 30,
      rosterNames: const ['甲'],
      rosterPortraits: const ['p1'],
      now: DateTime(2026, 1, 1),
    );

    expect(await container.read(bossMemoryCountProvider.future), 0);

    invalidateAfterCombatSettlement(container.invalidate);

    expect(await container.read(bossMemoryCountProvider.future), 1);
  });

  test('战后掉落物品 → helper 失效背包列表与数量派生 provider', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subs = [
      container.listen(allInventoryItemsProvider, (_, _) {}),
      container.listen(
        inventoryQuantityByDefIdProvider('item_mojianshi'),
        (_, _) {},
      ),
      container.listen(
        inventoryQuantityByTypeProvider(ItemType.moJianShi),
        (_, _) {},
      ),
    ];
    addTearDown(() {
      for (final sub in subs) {
        sub.close();
      }
    });

    expect(await container.read(allInventoryItemsProvider.future), isEmpty);
    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      0,
    );
    expect(
      await container.read(
        inventoryQuantityByTypeProvider(ItemType.moJianShi).future,
      ),
      0,
    );

    await seedInventoryItem(
      defId: 'item_mojianshi',
      type: ItemType.moJianShi,
      quantity: 3,
    );

    expect(await container.read(allInventoryItemsProvider.future), isEmpty);
    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      0,
    );
    expect(
      await container.read(
        inventoryQuantityByTypeProvider(ItemType.moJianShi).future,
      ),
      0,
    );

    invalidateAfterCombatSettlement(container.invalidate);

    final refreshed = await container.read(allInventoryItemsProvider.future);
    expect(
      refreshed.singleWhere((i) => i.defId == 'item_mojianshi').quantity,
      3,
    );
    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      3,
    );
    expect(
      await container.read(
        inventoryQuantityByTypeProvider(ItemType.moJianShi).future,
      ),
      3,
    );
  });
}
