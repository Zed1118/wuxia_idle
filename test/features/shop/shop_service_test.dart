import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/defs/shop_item_def.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/shop/application/shop_service.dart';

/// 材料经济 P1 Task 5：ShopService 购买逻辑验收（TDD）。
/// 材料经济 balance T3：经验丹动态标价验收（TDD）。
///
/// 不走 testWidgets（真 Isar writeTxn 与 FakeAsync 不兼容，
/// memory: feedback_isar_widget_test_deadlock），用普通 test() 直调 service。
///
/// 覆盖边界：
/// 1. 银两充足 → 扣银两 + 入货（原子）
/// 2. 银两不足 → 拒绝，不扣不入
/// 3. 无 item_silver 行（余额 0）→ 拒绝
/// 4. [T3] effectivePrice 材料商品 → 固定 price
/// 5. [T3] effectivePrice 经验丹 → etl × fraction
/// 6. [T3] 经验丹购买按动态价扣银两
/// 7. [T3] 高 etl 时经验丹动态价更高
/// 8. [T3] 余额不足动态价 → 拒绝
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

  // T3: 经验丹 def（动态标价）
  const jingYanDanSmallDef = ShopItemDef(
    id: 'shop_jingyandan_small',
    itemDefId: 'item_jingyandan_small',
    itemType: ItemType.jingYanDan,
    priceLayerFraction: 1.0,
    category: 'pill',
  );

  const jingYanDanMidDef = ShopItemDef(
    id: 'shop_jingyandan_mid',
    itemDefId: 'item_jingyandan_mid',
    itemType: ItemType.jingYanDan,
    priceLayerFraction: 2.5,
    category: 'pill',
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

    final result = await ShopService.purchase(
      isar,
      def: mojianshiDef,
      founderEtl: null, // 材料不需 etl
    );

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

    final result = await ShopService.purchase(
      isar,
      def: mojianshiDef,
      founderEtl: null,
    );

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

    final result = await ShopService.purchase(
      isar,
      def: mojianshiDef,
      founderEtl: null,
    );

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

    await ShopService.purchase(isar, def: mojianshiDef, founderEtl: null); // 第 1 次
    await ShopService.purchase(isar, def: mojianshiDef, founderEtl: null); // 第 2 次

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

    final result = await ShopService.purchase(
      isar,
      def: mojianshiDef,
      founderEtl: null,
    );

    expect(result.success, true);

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver!.quantity, 0); // 银两可扣至 0

    final item = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(item!.quantity, 1);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // [T3] 6. effectivePrice：材料 → 固定 price
  // ──────────────────────────────────────────────────────────────────────────
  test('[T3] effectivePrice：材料商品返回固定 price，不受 etl 影响', () {
    expect(ShopService.effectivePrice(mojianshiDef, 0), 30);
    expect(ShopService.effectivePrice(mojianshiDef, 500), 30);
    expect(ShopService.effectivePrice(mojianshiDef, 9999), 30);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // [T3] 7. effectivePrice：经验丹（小）= etl × 1.0 取整
  // ──────────────────────────────────────────────────────────────────────────
  test('[T3] effectivePrice：经验丹小档 = etl × 1.0', () {
    expect(ShopService.effectivePrice(jingYanDanSmallDef, 100), 100);
    expect(ShopService.effectivePrice(jingYanDanSmallDef, 300), 300);
    expect(ShopService.effectivePrice(jingYanDanSmallDef, 1000), 1000);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // [T3] 8. effectivePrice：经验丹（中）= etl × 2.5 取整
  // ──────────────────────────────────────────────────────────────────────────
  test('[T3] effectivePrice：经验丹中档 = etl × 2.5', () {
    expect(ShopService.effectivePrice(jingYanDanMidDef, 100), 250);
    expect(ShopService.effectivePrice(jingYanDanMidDef, 400), 1000);
    // 取整验证
    expect(ShopService.effectivePrice(jingYanDanMidDef, 101), (101 * 2.5).round());
  });

  // ──────────────────────────────────────────────────────────────────────────
  // [T3] 9. 高 etl 时经验丹动态价更高
  // ──────────────────────────────────────────────────────────────────────────
  test('[T3] 高 etl 时经验丹价格更高（兑换率恒定）', () {
    final lowEtlPrice = ShopService.effectivePrice(jingYanDanSmallDef, 100);
    final highEtlPrice = ShopService.effectivePrice(jingYanDanSmallDef, 1000);
    expect(highEtlPrice, greaterThan(lowEtlPrice));
  });

  // ──────────────────────────────────────────────────────────────────────────
  // [T3] 10. 经验丹购买按动态价扣银两
  // ──────────────────────────────────────────────────────────────────────────
  test('[T3] 经验丹购买：按 etl×fraction 动态价扣银两', () async {
    const etl = 200;
    // small: 200 × 1.0 = 200
    await seedSilver(500);

    final result = await ShopService.purchase(
      isar,
      def: jingYanDanSmallDef,
      founderEtl: etl,
    );

    expect(result.success, true);

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver!.quantity, 300); // 500 - 200 = 300

    final item = await isar.inventoryItems.getByDefId('item_jingyandan_small');
    expect(item!.quantity, 1);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // [T3] 11. 余额不足动态价 → 拒绝
  // ──────────────────────────────────────────────────────────────────────────
  test('[T3] 经验丹余额不足动态价 → 拒绝', () async {
    const etl = 500;
    // small: 500 × 1.0 = 500，银两只有 300
    await seedSilver(300);

    final result = await ShopService.purchase(
      isar,
      def: jingYanDanSmallDef,
      founderEtl: etl,
    );

    expect(result.success, false);
    expect(result.reason, PurchaseFailReason.insufficientSilver);

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver!.quantity, 300); // 原封不动

    final item = await isar.inventoryItems.getByDefId('item_jingyandan_small');
    expect(item, isNull);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // [T3] 12. founderEtl=null 购买经验丹 → pricingUnavailable 失败
  // ──────────────────────────────────────────────────────────────────────────
  test('[T3] founderEtl=null 购买动态定价商品 → pricingUnavailable', () async {
    await seedSilver(9999);

    final result = await ShopService.purchase(
      isar,
      def: jingYanDanSmallDef,
      founderEtl: null, // 无 founder，无法定价
    );

    expect(result.success, false);
    expect(result.reason, PurchaseFailReason.pricingUnavailable);

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver!.quantity, 9999); // 不扣钱

    final item = await isar.inventoryItems.getByDefId('item_jingyandan_small');
    expect(item, isNull);
  });
}
