import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/equipment/domain/cycle_drop_bonus.dart';

/// 周目平衡 2026-06-26：普通掉落材料加成纯逻辑 TDD。
void main() {
  group('CycleDropBonusConfig', () {
    test('fromYaml 解析 + qtyMultFor 按周目', () {
      final c = CycleDropBonusConfig.fromYaml({'material_qty_mult_ng_plus': 1.5});
      expect(c.materialQtyMultNgPlus, 1.5);
      expect(c.qtyMultFor(1), 1.0, reason: '一周目不加成');
      expect(c.qtyMultFor(2), 1.5, reason: '二周目起加成');
      expect(c.qtyMultFor(3), 1.5);
    });

    test('fromYaml 空 map → none(倍率 1.0)', () {
      expect(CycleDropBonusConfig.fromYaml(const {}).materialQtyMultNgPlus, 1.0);
    });
  });

  group('isCycleBonusMaterial', () {
    test('材料类(miscMaterial/磨剑石/心血结晶)→ true', () {
      expect(isCycleBonusMaterial(ItemType.miscMaterial), isTrue);
      expect(isCycleBonusMaterial(ItemType.moJianShi), isTrue);
      expect(isCycleBonusMaterial(ItemType.xinXueJieJing), isTrue);
    });
    test('经验丹/秘籍/银两 → false(不随周目放量)', () {
      expect(isCycleBonusMaterial(ItemType.jingYanDan), isFalse);
      expect(isCycleBonusMaterial(ItemType.techniqueScroll), isFalse);
      expect(isCycleBonusMaterial(ItemType.silver), isFalse);
    });
  });

  group('applyCycleMaterialBonus', () {
    const cfg = CycleDropBonusConfig(materialQtyMultNgPlus: 1.5);

    DropResult drops() => const DropResult(equipments: [], items: [
          ItemDropResult(defId: 'item_jingtie', quantity: 4), // miscMaterial
          ItemDropResult(defId: 'item_mojianshi', quantity: 3), // 磨剑石
          ItemDropResult(defId: 'item_silver', quantity: 100), // 银两(不加成)
          ItemDropResult(defId: 'item_scroll_qing', quantity: 1), // 秘籍(不加成)
        ]);

    test('cycle 1 → 原样不动', () {
      final r = applyCycleMaterialBonus(drops(), 1, cfg);
      expect(r.items.map((e) => e.quantity).toList(), [4, 3, 100, 1]);
    });

    test('cycle 2 → 材料类 ×1.5 向下取整、银两/秘籍不变', () {
      final r = applyCycleMaterialBonus(drops(), 2, cfg);
      // 4×1.5=6 / 3×1.5=4(floor) / 银两 100 不变 / 秘籍 1 不变。
      expect(r.items.map((e) => e.quantity).toList(), [6, 4, 100, 1]);
    });

    test('倍率 1.0(none)→ 原样返回', () {
      final r = applyCycleMaterialBonus(drops(), 2, CycleDropBonusConfig.none);
      expect(r.items.map((e) => e.quantity).toList(), [4, 3, 100, 1]);
    });

    test('加成后不低于原值(防 floor 把 1 个材料抹成 0)', () {
      const single = DropResult(equipments: [], items: [
        ItemDropResult(defId: 'item_jingtie', quantity: 1),
      ]);
      // 1×1.5=1.5 floor=1，等于原值（不减）。
      final r = applyCycleMaterialBonus(single, 2, cfg);
      expect(r.items.single.quantity, 1);
    });

    test('装备列表原样透传', () {
      final r = applyCycleMaterialBonus(drops(), 2, cfg);
      expect(r.equipments, isEmpty);
    });
  });
}
