import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/lore.dart';
import 'package:wuxia_idle/features/equipment/domain/equipment_disposal.dart';

void main() {
  // 起始配置（= numbers.yaml disposal 段初值，待真机校）。
  const cfg = EquipmentDisposalConfig(
    sellPrice: [20, 50, 120, 280, 600, 1200, 2500],
    sellEnhanceFactor: 0.1,
    disassembleMojianshi: [1, 2, 4, 7, 12, 18, 25],
    disassembleXinxuejiejing: [0, 0, 0, 1, 2, 4, 8],
    disassembleEnhanceMojianshiPerLevel: 1,
  );

  test('出售价 = 基价 × (1 + 0.1×强化等级) 向下取整', () {
    expect(equipmentSellPrice(EquipmentTier.xunChang, 0, cfg), 20);
    expect(equipmentSellPrice(EquipmentTier.shenWu, 0, cfg), 2500);
    // 神物 +10：2500 × 2.0 = 5000
    expect(equipmentSellPrice(EquipmentTier.shenWu, 10, cfg), 5000);
    // 利器(280) +3：280 × 1.3 = 364
    expect(equipmentSellPrice(EquipmentTier.liQi, 3, cfg), 364);
  });

  test('分解产出 = 品阶基础 + 强化额外磨剑石', () {
    final r0 = equipmentDisassembleRewards(EquipmentTier.xunChang, 0, cfg);
    expect(r0.mojianshi, 1);
    expect(r0.xinxuejiejing, 0);
    final r1 = equipmentDisassembleRewards(EquipmentTier.shenWu, 0, cfg);
    expect(r1.mojianshi, 25);
    expect(r1.xinxuejiejing, 8);
    // 神物 +12：磨剑石 25 + 12×1 = 37，心血结晶 8
    final r2 = equipmentDisassembleRewards(EquipmentTier.shenWu, 12, cfg);
    expect(r2.mojianshi, 37);
    expect(r2.xinxuejiejing, 8);
  });

  group('equipmentProtectionReason', () {
    Equipment eq({
      required int id,
      EquipmentTier tier = EquipmentTier.xunChang,
      bool isLocked = false,
      bool isLineageHeritage = false,
      String obtainedFrom = 'test',
      List<Lore>? lores,
      List<int>? previousOwnerCharacterIds,
    }) => Equipment.create(
      defId: 'eq_$id',
      tier: tier,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 6, 28),
      obtainedFrom: obtainedFrom,
      isLocked: isLocked,
      isLineageHeritage: isLineageHeritage,
      lores: lores,
      previousOwnerCharacterIds: previousOwnerCharacterIds,
    )..id = id;

    test('已装备/锁定/遗物/高阶/受保护来源/典故均返回保护原因', () {
      expect(
        equipmentProtectionReason(eq(id: 1), equippedEquipmentIds: const {1}),
        EquipmentProtectionReason.equipped,
      );
      expect(
        equipmentProtectionReason(
          eq(id: 2, isLocked: true),
          equippedEquipmentIds: const {},
        ),
        EquipmentProtectionReason.locked,
      );
      expect(
        equipmentProtectionReason(
          eq(id: 3, isLineageHeritage: true),
          equippedEquipmentIds: const {},
        ),
        EquipmentProtectionReason.lineageHeritage,
      );
      expect(
        equipmentProtectionReason(
          eq(id: 4, tier: EquipmentTier.zhongQi),
          equippedEquipmentIds: const {},
        ),
        EquipmentProtectionReason.highTier,
      );
      expect(
        equipmentProtectionReason(
          eq(id: 5, obtainedFrom: 'story_reward'),
          equippedEquipmentIds: const {},
          policy: const EquipmentProtectionPolicy(
            protectedObtainedFrom: {'story_reward'},
          ),
        ),
        EquipmentProtectionReason.protectedSource,
      );
      expect(
        equipmentProtectionReason(
          eq(id: 6, lores: [Lore()..text = 'test lore']),
          equippedEquipmentIds: const {},
        ),
        EquipmentProtectionReason.story,
      );
      expect(
        equipmentProtectionReason(
          eq(id: 7, previousOwnerCharacterIds: [99]),
          equippedEquipmentIds: const {},
        ),
        EquipmentProtectionReason.story,
      );
    });
  });
}
