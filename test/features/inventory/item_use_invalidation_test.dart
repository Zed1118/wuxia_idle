import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/inventory/application/item_use_invalidation.dart';
import 'package:wuxia_idle/features/inventory/application/item_use_service.dart';

import '../../support/isar_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Isar isar;
  late GameRepository repo;

  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await GameRepository.loadAllDefs();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_itemuse_inval_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.put(
        Character.create(
          name: '主角',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes(),
          rarity: RarityTier.values.first,
          lineageRole: LineageRole.founder,
          createdAt: DateTime(2026, 7, 9),
          isFounder: true,
          isActive: true,
          experience: 0,
          experienceToNextLayer: 100,
          internalForceMax: 800,
        ),
      );
      await isar.inventoryItems.put(
        InventoryItem()
          ..defId = 'item_jingyandan_small'
          ..itemType = ItemType.jingYanDan
          ..quantity = 2
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

  test('道具使用后 helper 统一刷新背包列表与单项数量缓存', () async {
    final def = repo.itemDefs['item_jingyandan_small']!;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subs = [
      container.listen(allInventoryItemsProvider, (_, _) {}),
      container.listen(inventoryQuantityByDefIdProvider(def.defId), (_, _) {}),
      container.listen(inventoryQuantityByTypeProvider(def.type), (_, _) {}),
    ];
    addTearDown(() {
      for (final sub in subs) {
        sub.close();
      }
    });

    expect(
      await container.read(inventoryQuantityByDefIdProvider(def.defId).future),
      2,
    );
    expect(
      await container.read(inventoryQuantityByTypeProvider(def.type).future),
      2,
    );

    final result = await ItemUseService.use(
      isar,
      def: def,
      realmLookup: repo.getRealm,
      levelConfig: repo.numbers.level,
    );
    expect(result.kind, ItemUseKind.experienceApplied);

    final dbItem = await isar.inventoryItems.getByDefId(def.defId);
    expect(dbItem!.quantity, 1);

    expect(
      await container.read(inventoryQuantityByDefIdProvider(def.defId).future),
      2,
      reason: '未失效前单项数量仍会读到当前会话缓存',
    );

    invalidateAfterItemUse(
      container.invalidate,
      defId: def.defId,
      itemType: def.type,
    );

    expect(
      await container.read(inventoryQuantityByDefIdProvider(def.defId).future),
      1,
    );
    expect(
      await container.read(inventoryQuantityByTypeProvider(def.type).future),
      1,
    );
    final items = await container.read(allInventoryItemsProvider.future);
    expect(
      {for (final item in items) item.defId: item.quantity},
      {'item_jingyandan_small': 1},
    );
  });
}
