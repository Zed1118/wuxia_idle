import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/defs/shop_item_def.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/shop/application/shop_invalidation.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';
import 'package:wuxia_idle/features/shop/application/shop_service.dart';

void main() {
  late Directory tempDir;
  late Isar isar;

  const mojianshiDef = ShopItemDef(
    id: 'shop_mojianshi',
    itemDefId: 'item_mojianshi',
    itemType: ItemType.moJianShi,
    price: 30,
    category: 'material',
  );

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_shop_inval_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.inventoryItems.put(
        InventoryItem()
          ..defId = 'item_silver'
          ..itemType = ItemType.silver
          ..quantity = 100
          ..firstObtainedAt = DateTime(2026, 7, 9)
          ..lastObtainedAt = DateTime(2026, 7, 9),
      );
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

  test('商店购买后 helper 统一刷新银两、背包列表与材料数量缓存', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subs = [
      container.listen(silverBalanceProvider, (_, _) {}),
      container.listen(allInventoryItemsProvider, (_, _) {}),
      container.listen(
        inventoryQuantityByTypeProvider(ItemType.moJianShi),
        (_, _) {},
      ),
      container.listen(
        inventoryQuantityByDefIdProvider('item_mojianshi'),
        (_, _) {},
      ),
    ];
    addTearDown(() {
      for (final sub in subs) {
        sub.close();
      }
    });

    expect(await container.read(silverBalanceProvider.future), 100);
    expect(
      await container.read(
        inventoryQuantityByTypeProvider(ItemType.moJianShi).future,
      ),
      0,
    );
    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      0,
    );

    final result = await ShopService.purchase(
      isar,
      def: mojianshiDef,
      founderEtl: null,
    );
    expect(result.success, true);

    final dbSilver = await isar.inventoryItems.getByDefId('item_silver');
    final dbMojianshi = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(dbSilver!.quantity, 70);
    expect(dbMojianshi!.quantity, 1);

    expect(
      await container.read(
        inventoryQuantityByTypeProvider(ItemType.moJianShi).future,
      ),
      0,
      reason: '未失效前单项材料数量仍会读到当前会话缓存',
    );

    invalidateAfterShopPurchase(container.invalidate);

    expect(await container.read(silverBalanceProvider.future), 70);
    expect(
      await container.read(
        inventoryQuantityByTypeProvider(ItemType.moJianShi).future,
      ),
      1,
    );
    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_mojianshi').future,
      ),
      1,
    );
    final items = await container.read(allInventoryItemsProvider.future);
    expect(
      {for (final item in items) item.defId: item.quantity},
      {'item_silver': 70, 'item_mojianshi': 1},
    );
  });
}
