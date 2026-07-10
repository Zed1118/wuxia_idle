import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/equipment/application/enhancement_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_disposal_service.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_inventory_invalidation.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;
  late Isar isar;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_eq_inval_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    isar = IsarSetup.instance;
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<Equipment> seedEquipment({
    EquipmentTier tier = EquipmentTier.xunChang,
    int enhanceLevel = 0,
  }) async {
    final eq = Equipment.create(
      defId: 'test_eq',
      tier: tier,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 7, 9),
      obtainedFrom: 'test',
      baseAttack: 50,
      enhanceLevel: enhanceLevel,
    );
    await isar.writeTxn(() => isar.equipments.put(eq));
    return eq;
  }

  Future<void> seedInventory(String defId, ItemType type, int quantity) async {
    await isar.writeTxn(() async {
      await isar.inventoryItems.put(
        InventoryItem()
          ..defId = defId
          ..itemType = type
          ..quantity = quantity
          ..firstObtainedAt = DateTime(2026, 7, 9)
          ..lastObtainedAt = DateTime(2026, 7, 9),
      );
    });
  }

  test('出售装备后 helper 刷新装备列表、银两数量与商店入口缓存', () async {
    final eq = await seedEquipment();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subs = [
      container.listen(allEquipmentsProvider, (_, _) {}),
      container.listen(allInventoryItemsProvider, (_, _) {}),
      container.listen(silverBalanceProvider, (_, _) {}),
      container.listen(shopUnlockedProvider, (_, _) {}),
      container.listen(
        inventoryQuantityByDefIdProvider('item_silver'),
        (_, _) {},
      ),
      container.listen(
        inventoryQuantityByTypeProvider(ItemType.silver),
        (_, _) {},
      ),
    ];
    addTearDown(() {
      for (final sub in subs) {
        sub.close();
      }
    });

    expect(await container.read(shopUnlockedProvider.future), false);
    expect(await container.read(silverBalanceProvider.future), 0);
    expect(await container.read(allEquipmentsProvider.future), hasLength(1));

    final cfg = GameRepository.instance.numbers.disposal;
    final outcome = await EquipmentDisposalService(
      isar: isar,
      config: cfg,
    ).sell(eq.id);
    expect(outcome, DisposalOutcome.sold);

    final dbSilver = await isar.inventoryItems.getByDefId('item_silver');
    expect(dbSilver!.quantity, 20);
    expect(await isar.equipments.get(eq.id), isNull);

    expect(
      await container.read(shopUnlockedProvider.future),
      false,
      reason: '未失效前商店入口仍会读到当前会话缓存',
    );
    expect(await container.read(silverBalanceProvider.future), 0);

    invalidateAfterEquipmentSale(container.invalidate);

    expect(await container.read(shopUnlockedProvider.future), true);
    expect(await container.read(silverBalanceProvider.future), 20);
    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_silver').future,
      ),
      20,
    );
    expect(await container.read(allEquipmentsProvider.future), isEmpty);
    final items = await container.read(allInventoryItemsProvider.future);
    expect(
      {for (final item in items) item.defId: item.quantity},
      {'item_silver': 20},
    );
  });

  test('分解装备后 helper 刷新装备列表与返还材料数量缓存', () async {
    final eq = await seedEquipment(enhanceLevel: 3);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subs = [
      container.listen(allEquipmentsProvider, (_, _) {}),
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

    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      0,
    );

    final cfg = GameRepository.instance.numbers.disposal;
    final outcome = await EquipmentDisposalService(
      isar: isar,
      config: cfg,
    ).disassemble(eq.id);
    expect(outcome, DisposalOutcome.disassembled);

    final dbMojianshi = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(dbMojianshi!.quantity, 4);

    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      0,
      reason: '未失效前分解返还材料仍会读到当前会话缓存',
    );

    invalidateAfterEquipmentDisassembly(container.invalidate);

    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      4,
    );
    expect(
      await container.read(
        inventoryQuantityByTypeProvider(ItemType.moJianShi).future,
      ),
      4,
    );
    expect(await container.read(allEquipmentsProvider.future), isEmpty);
  });

  test('强化装备后 helper 刷新全背包与强化材料数量缓存', () async {
    final eq = await seedEquipment();
    await seedInventory('item_mojianshi', ItemType.moJianShi, 10);
    await seedInventory('item_xinxuejiejing', ItemType.xinXueJieJing, 1);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subs = [
      container.listen(allEquipmentsProvider, (_, _) {}),
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

    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      10,
    );

    eq.enhanceLevel = 1;
    await EnhancementService(isar: isar).persistResult(
      eq: eq,
      result: const EnhanceResult(
        outcome: EnhanceOutcome.success,
        oldLevel: 0,
        newLevel: 1,
        mojianshiSpent: 5,
      ),
    );

    final dbMojianshi = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(dbMojianshi!.quantity, 5);

    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      10,
      reason: '未失效前强化材料数量仍会读到当前会话缓存',
    );

    invalidateAfterEquipmentEnhancement(container.invalidate);

    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      5,
    );
    final items = await container.read(allInventoryItemsProvider.future);
    expect(
      {for (final item in items) item.defId: item.quantity},
      {'item_mojianshi': 5, 'item_xinxuejiejing': 1},
    );
  });
}
