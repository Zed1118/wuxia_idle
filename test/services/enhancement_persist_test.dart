import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/data/models/inventory_item.dart';
import 'package:wuxia_idle/services/enhancement_service.dart';
import 'package:wuxia_idle/utils/rng.dart';

/// T32 #22a EnhancementService.persistResult 真 Isar 落地测试。
///
/// 不走 testWidgets（FakeAsync 与真 Isar 异步 IO 不兼容），用普通 `test()`
/// 直调 service 静态方法，setUp 临时目录 + IsarSetup.init + seed 库存 +
/// 装备，断言 writeTxn 后 row.quantity / equipment.enhanceLevel 真落地。
///
/// 用例（5 个，对应 GDD §6.2/§6.3 强化 + 保底）：
/// - success → equipment.enhanceLevel +1 + mojianshi 行扣 cost
/// - failure → equipment 不变 + mojianshi 扣 penaltyCost + jieJing 行 +1
/// - guarantee success → equipment.enhanceLevel +1 + jieJing 行扣 crystalCost
/// - mojianshi row 不存在 → StateError
/// - jieJing row 不存在（失败路径） → StateError
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_persist_test_');
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

  Future<Equipment> seedEq({int enhanceLevel = 0}) async {
    final eq = Equipment.create(
      defId: 'test_eq',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: 50,
      enhanceLevel: enhanceLevel,
    );
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.equipments.put(eq);
    });
    return eq;
  }

  Future<void> seedInventory({
    required ItemType type,
    required int quantity,
  }) async {
    final item = InventoryItem()
      ..defId = type.name
      ..itemType = type
      ..quantity = quantity
      ..firstObtainedAt = DateTime(2026, 5, 11)
      ..lastObtainedAt = DateTime(2026, 5, 11);
    await IsarSetup.instance.writeTxn(() async {
      await IsarSetup.instance.inventoryItems.put(item);
    });
  }

  Future<int> readQty(ItemType type) async {
    final row = await IsarSetup.instance.inventoryItems
        .filter()
        .itemTypeEqualTo(type)
        .findFirst();
    return row?.quantity ?? 0;
  }

  // ── 1) success 路径 ──────────────────────────────────────────────────

  test('success → eq.enhanceLevel +1 + mojianshi row 扣 cost + jieJing 不变',
      () async {
    await seedInventory(type: ItemType.moJianShi, quantity: 1000);
    await seedInventory(type: ItemType.xinXueJieJing, quantity: 5);
    final eq = await seedEq(enhanceLevel: 20);

    // 用真 service.tryEnhance 拿一个真 result（success）：固定 rng=0
    final config = GameRepository.instance.numbers.enhancement;
    final mojBefore = await readQty(ItemType.moJianShi);
    final result = EnhancementService.tryEnhance(
      eq: eq,
      characterAbsoluteLevel: 49,
      rng: _StubRng(0),
      currentMojianshi: mojBefore,
      config: config,
    );
    expect(result.outcome, EnhanceOutcome.success);

    await EnhancementService.persistResult(
      eq: eq,
      result: result,
      isar: IsarSetup.instance,
    );

    final eqBack = await IsarSetup.instance.equipments.get(eq.id);
    expect(eqBack?.enhanceLevel, 21, reason: 'Equipment 应已 put 回 Isar');

    expect(
      await readQty(ItemType.moJianShi),
      mojBefore - result.mojianshiSpent,
      reason: '磨剑石应扣 cost',
    );
    expect(await readQty(ItemType.xinXueJieJing), 5,
        reason: '成功路径不动结晶');
  });

  // ── 2) failure 路径 ─────────────────────────────────────────────────

  test(
      'failure → eq 不变 + mojianshi 扣 penaltyCost + jieJing +1',
      () async {
    await seedInventory(type: ItemType.moJianShi, quantity: 1000);
    await seedInventory(type: ItemType.xinXueJieJing, quantity: 5);
    final eq = await seedEq(enhanceLevel: 20);

    final config = GameRepository.instance.numbers.enhancement;
    final mojBefore = await readQty(ItemType.moJianShi);
    final result = EnhancementService.tryEnhance(
      eq: eq,
      characterAbsoluteLevel: 49,
      rng: _StubRng(0.99),
      currentMojianshi: mojBefore,
      config: config,
    );
    expect(result.outcome, EnhanceOutcome.failure);

    await EnhancementService.persistResult(
      eq: eq,
      result: result,
      isar: IsarSetup.instance,
    );

    // 失败路径未 put eq（service 也未改 enhanceLevel）
    final eqBack = await IsarSetup.instance.equipments.get(eq.id);
    expect(eqBack?.enhanceLevel, 20, reason: '失败永不破防降级');

    expect(
      await readQty(ItemType.moJianShi),
      mojBefore - result.mojianshiSpent,
      reason: '失败按 penalty 扣材料',
    );
    expect(await readQty(ItemType.xinXueJieJing), 5 + result.crystalsGained,
        reason: '失败必给 ≥1 颗心血结晶');
    expect(result.crystalsGained, greaterThan(0));
  });

  // ── 3) guarantee success 路径 ──────────────────────────────────────

  test('guarantee success → eq.enhanceLevel +1 + jieJing 扣 crystalCost',
      () async {
    await seedInventory(type: ItemType.moJianShi, quantity: 1000);
    await seedInventory(type: ItemType.xinXueJieJing, quantity: 99);
    final eq = await seedEq(enhanceLevel: 14); // +14→+15 段保底可用

    final config = GameRepository.instance.numbers.enhancement;
    final crystalBefore = await readQty(ItemType.xinXueJieJing);
    final result = EnhancementService.useCrystalToGuarantee(
      eq: eq,
      characterAbsoluteLevel: 49,
      currentCrystals: crystalBefore,
      config: config,
    );
    expect(result.outcome, EnhanceOutcome.success);
    expect(result.crystalsSpent, greaterThan(0));

    await EnhancementService.persistResult(
      eq: eq,
      result: result,
      isar: IsarSetup.instance,
    );

    final eqBack = await IsarSetup.instance.equipments.get(eq.id);
    expect(eqBack?.enhanceLevel, 15);

    expect(
      await readQty(ItemType.xinXueJieJing),
      crystalBefore - result.crystalsSpent,
      reason: '保底心血结晶应扣 crystalCost',
    );
  });

  // ── 4) mojianshi row 不存在 → fail-fast ────────────────────────────

  test('mojianshi row 不存在 → StateError', () async {
    // 不 seed mojianshi 行；jieJing 不影响成功路径，但仍 seed 防干扰
    await seedInventory(type: ItemType.xinXueJieJing, quantity: 0);
    final eq = await seedEq(enhanceLevel: 20);

    const result = EnhanceResult(
      outcome: EnhanceOutcome.success,
      oldLevel: 20,
      newLevel: 21,
      mojianshiSpent: 100,
    );

    expect(
      () => EnhancementService.persistResult(
        eq: eq,
        result: result,
        isar: IsarSetup.instance,
      ),
      throwsA(isA<StateError>()),
    );
  });

  // ── 5) jieJing row 不存在（失败路径增结晶）→ fail-fast ──────────────

  test('jieJing row 不存在（失败路径增结晶）→ StateError', () async {
    await seedInventory(type: ItemType.moJianShi, quantity: 1000);
    final eq = await seedEq(enhanceLevel: 20);

    const result = EnhanceResult(
      outcome: EnhanceOutcome.failure,
      oldLevel: 20,
      newLevel: 20,
      mojianshiSpent: 10,
      crystalsGained: 1,
    );

    expect(
      () => EnhancementService.persistResult(
        eq: eq,
        result: result,
        isar: IsarSetup.instance,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

class _StubRng implements Rng {
  final double _value;
  _StubRng(this._value);

  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => _value;

  @override
  T pick<T>(List<T> list) => list.first;
}
