import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_action_service.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_invalidation.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_providers.dart';
import 'package:wuxia_idle/features/taohua_island/application/island_settle_service.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';
import "../../support/isar_test_support.dart";
import '../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_island_inval_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final save = (await IsarSetup.instance.saveDatas.get(0))!;
    await IslandSettleService.ensureInitialized(save, DateTime(2026, 7, 9));
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> seedInventory(String defId, int quantity) async {
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(
        InventoryItem()
          ..defId = defId
          ..itemType = ItemType.fromDefId(defId)
          ..quantity = quantity
          ..firstObtainedAt = DateTime(2026, 7, 9)
          ..lastObtainedAt = DateTime(2026, 7, 9),
      );
    });
  }

  test('桃花岛升级后 helper 统一刷新岛务 view、银两与背包数量缓存', () async {
    await seedInventory('item_silver', 1000);
    await seedInventory('item_jingtie', 100);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subs = [
      container.listen(silverBalanceProvider, (_, _) {}),
      container.listen(
        inventoryQuantityByDefIdProvider('item_silver'),
        (_, _) {},
      ),
      container.listen(taohuaIslandViewProvider, (_, _) {}),
    ];
    addTearDown(() {
      for (final sub in subs) {
        sub.close();
      }
    });

    expect(await container.read(silverBalanceProvider.future), 1000);
    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_silver').future,
      ),
      1000,
    );
    expect(
      (await container.read(taohuaIslandViewProvider.future))!.silver,
      1000,
    );

    final save = (await IsarSetup.currentSaveData())!;
    final result = await IslandActionService.upgrade(
      save: save,
      buildingType: BuildingType.tieJiangChang,
      founderRealmIndex: 0,
    );
    expect(result, UpgradeResult.ok);

    final dbSilver = await IsarSetup.instance.inventoryItems.getByDefId(
      'item_silver',
    );
    expect(dbSilver!.quantity, 500, reason: '升级已真实扣除银两');

    expect(
      await container.read(silverBalanceProvider.future),
      1000,
      reason: '未失效前会继续读到当前会话缓存的旧银两',
    );

    invalidateAfterIslandInventoryMutation(container.invalidate);

    expect(await container.read(silverBalanceProvider.future), 500);
    expect(
      await container.read(
        inventoryQuantityByDefIdProvider('item_silver').future,
      ),
      500,
    );
    final refreshedView = await container.read(taohuaIslandViewProvider.future);
    expect(refreshedView!.silver, 500);
    expect(refreshedView.materials['item_jingtie'], 60);
  });
}
