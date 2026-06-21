import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/defs/shop_item_def.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/shop/application/shop_service.dart';

/// 材料经济 P1 Task 5：ShopService 购买逻辑验收（TDD）。
///
/// 不走 testWidgets（真 Isar writeTxn 与 FakeAsync 不兼容，
/// memory: feedback_isar_widget_test_deadlock），用普通 test() 直调 service。
///
/// 覆盖边界：
/// 1. 银两充足 → 扣银两 + 入货（原子）
/// 2. 银两不足 → 拒绝，不扣不入
/// 3. 无 item_silver 行（余额 0）→ 拒绝
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
    tempDir = await Directory.systemTemp.createTemp('wuxia_shop_test_');
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

  /// 帮助函数：预置 item_silver 行。
  Future<void> seedSilver(int quantity) async {
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

  // ──────────────────────────────────────────────────────────────────────────
  // 1. 银两充足 → 购买成功
  // ──────────────────────────────────────────────────────────────────────────
  test('银两充足购买成功：扣银两+入货（原子 writeTxn）', () async {
    await seedSilver(100);

    final result = await ShopService.purchase(isar, def: mojianshiDef);

    expect(result.success, true);
    expect(result.reason, isNull);

    // 银两扣减
    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver!.quantity, 70); // 100 - 30 = 70

    // 货品入库
    final item = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(item, isNotNull);
    expect(item!.quantity, 1);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. 银两不足 → 拒绝
  // ──────────────────────────────────────────────────────────────────────────
  test('银两不足拒绝：不扣不入', () async {
    await seedSilver(10); // price=30，不足

    final result = await ShopService.purchase(isar, def: mojianshiDef);

    expect(result.success, false);
    expect(result.reason, PurchaseFailReason.insufficientSilver);

    // 银两原封不动
    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver!.quantity, 10);

    // 货品未入库
    final item = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(item, isNull);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. 无 item_silver 行（余额 0）→ 拒绝
  // ──────────────────────────────────────────────────────────────────────────
  test('无 item_silver 行（余额0）→ 拒绝', () async {
    // 不预置 silver 行

    final result = await ShopService.purchase(isar, def: mojianshiDef);

    expect(result.success, false);
    expect(result.reason, PurchaseFailReason.insufficientSilver);

    // 货品未入库
    final item = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(item, isNull);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 4. 购买后再次购买 → upsert 叠加
  // ──────────────────────────────────────────────────────────────────────────
  test('重复购买同品 → quantity 叠加', () async {
    await seedSilver(100);

    await ShopService.purchase(isar, def: mojianshiDef); // 第 1 次
    await ShopService.purchase(isar, def: mojianshiDef); // 第 2 次

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver!.quantity, 40); // 100 - 30 - 30 = 40

    final item = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(item!.quantity, 2);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 5. 银两恰好等于价格 → 成功（边界）
  // ──────────────────────────────────────────────────────────────────────────
  test('银两恰好等于价格 → 成功，扣至 0', () async {
    await seedSilver(30);

    final result = await ShopService.purchase(isar, def: mojianshiDef);

    expect(result.success, true);

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver!.quantity, 0); // 银两可扣至 0

    final item = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(item!.quantity, 1);
  });
}
