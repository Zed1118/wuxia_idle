import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_disposal_service.dart';
import 'package:wuxia_idle/features/equipment/domain/equipment_disposal.dart';

/// Task 2 TDD：装备出售/分解 service 单件验收。
///
/// 沿 shop_service_test 体例：test() 不用 testWidgets
/// (memory: feedback_isar_widget_test_deadlock)。
///
/// 覆盖边界：
/// 1. sell 背包装备 → sold；装备从 isar 删除；银两增加 = sellPrice
/// 2. disassemble 背包装备 → disassembled；装备删除；磨剑石/心血结晶累加
/// 3. sell/disassemble 已装备(ownerCharacterId!=null) → rejectedEquipped；不变
/// 4. sell/disassemble 师承遗物(isLineageHeritage) → rejectedHeritage；不变
/// 5. 不存在的 id → notFound
void main() {
  late Directory tempDir;
  late Isar isar;

  // 出售/分解配置（与 numbers.yaml 初值一致，测试用固定值）
  const cfg = EquipmentDisposalConfig(
    sellPrice: [20, 50, 120, 280, 600, 1200, 2500],
    sellEnhanceFactor: 0.1,
    disassembleMojianshi: [1, 2, 4, 7, 12, 18, 25],
    disassembleXinxuejiejing: [0, 0, 0, 1, 2, 4, 8],
    disassembleEnhanceMojianshiPerLevel: 1,
  );

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_disposal_test_');
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

  /// 帮助：新建背包装备并存入 isar，返回 id。
  Future<int> seedEquipment({
    EquipmentTier tier = EquipmentTier.xunChang,
    int enhanceLevel = 0,
    int? ownerCharacterId,
    bool isLineageHeritage = false,
  }) async {
    final eq = Equipment.create(
      defId: 'equip_test',
      tier: tier,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
      enhanceLevel: enhanceLevel,
      ownerCharacterId: ownerCharacterId,
      isLineageHeritage: isLineageHeritage,
    );
    late int id;
    await isar.writeTxn(() async {
      id = await isar.equipments.put(eq);
    });
    return id;
  }

  EquipmentDisposalService makeService() =>
      EquipmentDisposalService(isar: isar, config: cfg);

  // ──────────────────────────────────────────────────────────────────────────
  // 1. sell 背包装备 → sold；装备删除；银两增加
  // ──────────────────────────────────────────────────────────────────────────
  test('sell 背包装备 → sold；装备从 isar 删除；银两增加 = sellPrice', () async {
    // 寻常货 +0：sellPrice = 20
    final id = await seedEquipment(
      tier: EquipmentTier.xunChang,
      enhanceLevel: 0,
    );

    final result = await makeService().sell(id);

    expect(result, DisposalOutcome.sold);

    // 装备已删
    final eq = await isar.equipments.get(id);
    expect(eq, isNull);

    // 银两新建，quantity = 20
    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver, isNotNull);
    expect(silver!.quantity, 20);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 1b. sell 已有银两行 → 累加
  // ──────────────────────────────────────────────────────────────────────────
  test('sell 时已有 item_silver 行 → quantity 累加', () async {
    // 先写入 100 银两
    await isar.writeTxn(() async {
      await isar.inventoryItems.put(
        InventoryItem()
          ..defId = 'item_silver'
          ..itemType = ItemType.silver
          ..quantity = 100
          ..firstObtainedAt = DateTime(2026, 1, 1)
          ..lastObtainedAt = DateTime(2026, 1, 1),
      );
    });

    // 利器(index=3, base=280) +3 → 280*(1+0.3)=364
    final id = await seedEquipment(tier: EquipmentTier.liQi, enhanceLevel: 3);

    final result = await makeService().sell(id);
    expect(result, DisposalOutcome.sold);

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver!.quantity, 464); // 100 + 364
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. disassemble 背包装备 → disassembled；装备删除；材料累加
  // ──────────────────────────────────────────────────────────────────────────
  test('disassemble 背包装备(神物+12) → disassembled；磨剑石 37；心血结晶 8', () async {
    // 神物(index=6) +12：磨剑石 25+12=37，心血结晶 8
    final id = await seedEquipment(
      tier: EquipmentTier.shenWu,
      enhanceLevel: 12,
    );

    final result = await makeService().disassemble(id);
    expect(result, DisposalOutcome.disassembled);

    // 装备已删
    final eq = await isar.equipments.get(id);
    expect(eq, isNull);

    final mj = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(mj, isNotNull);
    expect(mj!.quantity, 37);

    final xx = await isar.inventoryItems.getByDefId('item_xinxuejiejing');
    expect(xx, isNotNull);
    expect(xx!.quantity, 8);
  });

  test('disassemble 寻常货 +0 → 磨剑石 1；无心血结晶行（xinxuejiejing=0）', () async {
    // 寻常货(index=0)：磨剑石 1，心血结晶 0（不写入）
    final id = await seedEquipment(
      tier: EquipmentTier.xunChang,
      enhanceLevel: 0,
    );

    final result = await makeService().disassemble(id);
    expect(result, DisposalOutcome.disassembled);

    final mj = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(mj!.quantity, 1);

    // xinxuejiejing=0，不应创建行
    final xx = await isar.inventoryItems.getByDefId('item_xinxuejiejing');
    expect(xx, isNull);
  });

  test('disassemble 时已有材料行 → quantity 累加', () async {
    // 先写入 5 磨剑石
    await isar.writeTxn(() async {
      await isar.inventoryItems.put(
        InventoryItem()
          ..defId = 'item_mojianshi'
          ..itemType = ItemType.moJianShi
          ..quantity = 5
          ..firstObtainedAt = DateTime(2026, 1, 1)
          ..lastObtainedAt = DateTime(2026, 1, 1),
      );
    });

    final id = await seedEquipment(
      tier: EquipmentTier.xunChang,
      enhanceLevel: 0,
    );
    await makeService().disassemble(id);

    final mj = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(mj!.quantity, 6); // 5 + 1
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. 已装备(ownerCharacterId != null) → rejectedEquipped；装备/银两不变
  // ──────────────────────────────────────────────────────────────────────────
  test('sell 已装备装备 → rejectedEquipped；装备仍在；银两不变', () async {
    final id = await seedEquipment(ownerCharacterId: 1);

    final result = await makeService().sell(id);
    expect(result, DisposalOutcome.rejectedEquipped);

    final eq = await isar.equipments.get(id);
    expect(eq, isNotNull);

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver, isNull); // 无写入
  });

  test('disassemble 已装备装备 → rejectedEquipped；装备仍在；材料不变', () async {
    final id = await seedEquipment(ownerCharacterId: 42);

    final result = await makeService().disassemble(id);
    expect(result, DisposalOutcome.rejectedEquipped);

    final eq = await isar.equipments.get(id);
    expect(eq, isNotNull);

    final mj = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(mj, isNull);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 4. 师承遗物 → rejectedHeritage；不变
  // ──────────────────────────────────────────────────────────────────────────
  test('sell 师承遗物 → rejectedHeritage；装备仍在；银两不变', () async {
    final id = await seedEquipment(isLineageHeritage: true);

    final result = await makeService().sell(id);
    expect(result, DisposalOutcome.rejectedHeritage);

    final eq = await isar.equipments.get(id);
    expect(eq, isNotNull);

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver, isNull);
  });

  test('disassemble 师承遗物 → rejectedHeritage；装备仍在；材料不变', () async {
    final id = await seedEquipment(isLineageHeritage: true);

    final result = await makeService().disassemble(id);
    expect(result, DisposalOutcome.rejectedHeritage);

    final eq = await isar.equipments.get(id);
    expect(eq, isNotNull);

    final mj = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(mj, isNull);
  });

  test('sell 未来锁定谓词命中 → rejectedLocked；装备仍在；银两不变', () async {
    final id = await seedEquipment();

    final result = await EquipmentDisposalService(
      isar: isar,
      config: cfg,
      isLocked: (eq) => eq.id == id,
    ).sell(id);

    expect(result, DisposalOutcome.rejectedLocked);
    expect(await isar.equipments.get(id), isNotNull);
    expect(await isar.inventoryItems.getByDefId('item_silver'), isNull);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 5. 不存在的 id → notFound
  // ──────────────────────────────────────────────────────────────────────────
  test('sell 不存在的 id → notFound', () async {
    final result = await makeService().sell(999999);
    expect(result, DisposalOutcome.notFound);
  });

  test('disassemble 不存在的 id → notFound', () async {
    final result = await makeService().disassemble(999999);
    expect(result, DisposalOutcome.notFound);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Task 3 批量按品级处置
  // ──────────────────────────────────────────────────────────────────────────

  /// 帮助：同 tier 准备 2 件背包 + 1 件已装备 + 1 件师承遗物，返回 4 个 id。
  Future<({int backpack1, int backpack2, int equipped, int heritage})>
  seedBulkFixture({
    EquipmentTier tier = EquipmentTier.xunChang,
    int enhanceLevel = 0,
  }) async {
    final b1 = await seedEquipment(tier: tier, enhanceLevel: enhanceLevel);
    final b2 = await seedEquipment(tier: tier, enhanceLevel: enhanceLevel);
    final eq = await seedEquipment(
      tier: tier,
      enhanceLevel: enhanceLevel,
      ownerCharacterId: 7,
    );
    final ht = await seedEquipment(
      tier: tier,
      enhanceLevel: enhanceLevel,
      isLineageHeritage: true,
    );
    return (backpack1: b1, backpack2: b2, equipped: eq, heritage: ht);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3a. sellAllOfTier：只处置背包装备，已装备/师承遗物不动
  // ──────────────────────────────────────────────────────────────────────────
  test('sellAllOfTier 寻常货 → count==2；银两==40；已装备/师承仍在 isar', () async {
    // 寻常货 +0：每件出售价 = 20
    final ids = await seedBulkFixture(tier: EquipmentTier.xunChang);

    final result = await makeService().sellAllOfTier(EquipmentTier.xunChang);

    expect(result.count, 2);
    expect(result.totalSilver, 40); // 20 + 20

    // 背包装备已删
    expect(await isar.equipments.get(ids.backpack1), isNull);
    expect(await isar.equipments.get(ids.backpack2), isNull);

    // 已装备 + 师承遗物仍在
    expect(await isar.equipments.get(ids.equipped), isNotNull);
    expect(await isar.equipments.get(ids.heritage), isNotNull);

    // 银两新建 = 40
    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver, isNotNull);
    expect(silver!.quantity, 40);
  });

  test('sellAllOfTier 不同 tier 装备：只出售指定 tier', () async {
    // 准备寻常货 2 件背包
    final b1 = await seedEquipment(tier: EquipmentTier.xunChang);
    final b2 = await seedEquipment(tier: EquipmentTier.xunChang);
    // 准备利器 1 件背包（不应被出售）
    final liQiId = await seedEquipment(tier: EquipmentTier.liQi);

    final result = await makeService().sellAllOfTier(EquipmentTier.xunChang);

    expect(result.count, 2);
    // 利器仍在
    expect(await isar.equipments.get(liQiId), isNotNull);
    expect(await isar.equipments.get(b1), isNull);
    expect(await isar.equipments.get(b2), isNull);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3b. disassembleAllOfTier：只处置背包装备，已装备/师承遗物不动
  // ──────────────────────────────────────────────────────────────────────────
  test(
    'disassembleAllOfTier 宝物(index=5)+0 → count==2；磨剑石==36；心血结晶==8',
    () async {
      // 宝物(index=5)：基础磨剑石=18，心血结晶=4；+0 无强化加成
      // 2 件：磨剑石 18×2=36，心血结晶 4×2=8
      final ids = await seedBulkFixture(tier: EquipmentTier.baoWu);

      final result = await makeService().disassembleAllOfTier(
        EquipmentTier.baoWu,
      );

      expect(result.count, 2);
      expect(result.totalMojianshi, 36);
      expect(result.totalXinxuejiejing, 8);

      // 背包装备已删
      expect(await isar.equipments.get(ids.backpack1), isNull);
      expect(await isar.equipments.get(ids.backpack2), isNull);

      // 已装备 + 师承遗物仍在
      expect(await isar.equipments.get(ids.equipped), isNotNull);
      expect(await isar.equipments.get(ids.heritage), isNotNull);

      // 磨剑石/心血结晶写入
      final mj = await isar.inventoryItems.getByDefId('item_mojianshi');
      expect(mj!.quantity, 36);
      final xx = await isar.inventoryItems.getByDefId('item_xinxuejiejing');
      expect(xx!.quantity, 8);
    },
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 3c. 空 tier → count==0，无写入
  // ──────────────────────────────────────────────────────────────────────────
  test('sellAllOfTier 空 tier → count==0；totalSilver==0；无银两写入', () async {
    // 只放一件其他 tier
    await seedEquipment(tier: EquipmentTier.liQi);

    final result = await makeService().sellAllOfTier(EquipmentTier.xunChang);

    expect(result.count, 0);
    expect(result.totalSilver, 0);

    final silver = await isar.inventoryItems.getByDefId('item_silver');
    expect(silver, isNull); // 无写入
  });

  test('disassembleAllOfTier 空 tier → count==0；无材料写入', () async {
    // 只放一件其他 tier
    await seedEquipment(tier: EquipmentTier.liQi);

    final result = await makeService().disassembleAllOfTier(
      EquipmentTier.xunChang,
    );

    expect(result.count, 0);
    expect(result.totalMojianshi, 0);
    expect(result.totalXinxuejiejing, 0);

    final mj = await isar.inventoryItems.getByDefId('item_mojianshi');
    expect(mj, isNull); // 无写入
  });
}
