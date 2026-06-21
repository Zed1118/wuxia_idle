import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';

/// 材料经济 P1 Task 6：商店 Riverpod provider 验收（TDD）。
///
/// 不走 testWidgets（避免 Isar writeTxn + FakeAsync 死锁，
/// memory: feedback_isar_widget_test_deadlock），用普通 test() + ProviderContainer。
///
/// 覆盖：
/// 1. silverBalanceProvider：无行→0；有行 quantity=50→50。
/// 2. shopUnlockedProvider：无行→false；有行→true。
/// 3. shopItemListProvider：非空、含 shop_mojianshi。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    // shopItemListProvider 依赖 GameRepository.instance.shopItemDefs
    // 用 File loader 加载真实 shop.yaml（沿 balance_simulator_test 体例）
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_shop_providers_');
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

  // ─────────────────────────────────────────────────────────────────────────
  // 辅助：预置 item_silver 行
  // ─────────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  // 1. silverBalanceProvider
  // ─────────────────────────────────────────────────────────────────────────
  group('silverBalanceProvider', () {
    test('无 item_silver 行 → 0', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final balance = await container.read(silverBalanceProvider.future);
      expect(balance, 0);
    });

    test('有 item_silver 行 quantity=50 → 50', () async {
      await seedSilver(50);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final balance = await container.read(silverBalanceProvider.future);
      expect(balance, 50);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. shopUnlockedProvider
  // ─────────────────────────────────────────────────────────────────────────
  group('shopUnlockedProvider', () {
    test('无 item_silver 行 → false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final unlocked = await container.read(shopUnlockedProvider.future);
      expect(unlocked, false);
    });

    test('有 item_silver 行（曾获得银两）→ true', () async {
      await seedSilver(0); // quantity=0 也算曾获得
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final unlocked = await container.read(shopUnlockedProvider.future);
      expect(unlocked, true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. shopItemListProvider
  // ─────────────────────────────────────────────────────────────────────────
  group('shopItemListProvider', () {
    test('返回非空列表，且含 shop_mojianshi', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final list = container.read(shopItemListProvider);
      expect(list, isNotEmpty);
      expect(list.any((d) => d.id == 'shop_mojianshi'), true);
    });
  });
}
