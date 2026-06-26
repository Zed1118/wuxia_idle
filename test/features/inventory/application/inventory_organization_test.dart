import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/inventory/application/inventory_organization.dart';

void main() {
  Equipment eq({
    required int id,
    required EquipmentTier tier,
    required EquipmentSlot slot,
    DateTime? obtainedAt,
    int enhanceLevel = 0,
    int? ownerCharacterId,
    bool isLineageHeritage = false,
  }) {
    return Equipment.create(
      defId: 'eq_$id',
      tier: tier,
      slot: slot,
      obtainedAt: obtainedAt ?? DateTime(2026, 6, id),
      obtainedFrom: 'test',
      enhanceLevel: enhanceLevel,
      ownerCharacterId: ownerCharacterId,
      isLineageHeritage: isLineageHeritage,
    )..id = id;
  }

  group('organizeInventoryEquipments', () {
    test('按类型/阶位/状态组合筛选，并按强化等级降序排序', () {
      final result = organizeInventoryEquipments(
        [
          eq(
            id: 1,
            tier: EquipmentTier.liQi,
            slot: EquipmentSlot.weapon,
            enhanceLevel: 2,
          ),
          eq(
            id: 2,
            tier: EquipmentTier.liQi,
            slot: EquipmentSlot.weapon,
            enhanceLevel: 8,
          ),
          eq(
            id: 3,
            tier: EquipmentTier.liQi,
            slot: EquipmentSlot.armor,
            enhanceLevel: 9,
          ),
          eq(
            id: 4,
            tier: EquipmentTier.baoWu,
            slot: EquipmentSlot.weapon,
            enhanceLevel: 20,
          ),
          eq(
            id: 5,
            tier: EquipmentTier.liQi,
            slot: EquipmentSlot.weapon,
            ownerCharacterId: 1,
          ),
        ],
        const InventoryEquipmentQuery(
          slot: InventorySlotFilter.weapon,
          tier: InventoryTierFilter.liQi,
          ownership: InventoryOwnershipFilter.free,
          sort: InventoryEquipmentSort.enhanceDesc,
        ),
      );

      expect(result.map((e) => e.id), [2, 1]);
    });

    test('按入手时间新到旧排序，平手时用 id 稳定破平', () {
      final sameTime = DateTime(2026, 6, 26);
      final result = organizeInventoryEquipments(
        [
          eq(id: 1, tier: EquipmentTier.xunChang, slot: EquipmentSlot.weapon),
          eq(
            id: 3,
            tier: EquipmentTier.xunChang,
            slot: EquipmentSlot.weapon,
            obtainedAt: sameTime,
          ),
          eq(
            id: 2,
            tier: EquipmentTier.xunChang,
            slot: EquipmentSlot.weapon,
            obtainedAt: sameTime,
          ),
        ],
        const InventoryEquipmentQuery(
          sort: InventoryEquipmentSort.obtainedDesc,
        ),
      );

      expect(result.map((e) => e.id), [3, 2, 1]);
    });
  });

  group('bulk disposal candidates', () {
    test('排除已装备、师承遗物和未来锁定谓词命中的装备', () {
      final free = eq(
        id: 1,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
      );
      final equipped = eq(
        id: 2,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        ownerCharacterId: 1,
      );
      final heritage = eq(
        id: 3,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        isLineageHeritage: true,
      );
      final futureLocked = eq(
        id: 4,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
      );

      expect(isBulkDisposalCandidate(free), isTrue);
      expect(isBulkDisposalCandidate(equipped), isFalse);
      expect(isBulkDisposalCandidate(heritage), isFalse);
      expect(
        isBulkDisposalCandidate(futureLocked, isLocked: (e) => e.id == 4),
        isFalse,
      );
    });

    test('按品阶建立候选计划，仅统计可批量处理装备', () {
      final plan = buildBulkDisposalPlan([
        eq(id: 1, tier: EquipmentTier.liQi, slot: EquipmentSlot.weapon),
        eq(id: 2, tier: EquipmentTier.liQi, slot: EquipmentSlot.armor),
        eq(
          id: 3,
          tier: EquipmentTier.liQi,
          slot: EquipmentSlot.weapon,
          ownerCharacterId: 1,
        ),
        eq(id: 4, tier: EquipmentTier.baoWu, slot: EquipmentSlot.weapon),
      ]);

      expect(plan.tiers, [EquipmentTier.baoWu, EquipmentTier.liQi]);
      expect(plan.itemsFor(EquipmentTier.liQi).map((e) => e.id), [2, 1]);
      expect(plan.itemsFor(EquipmentTier.baoWu).map((e) => e.id), [4]);
    });
  });
}
