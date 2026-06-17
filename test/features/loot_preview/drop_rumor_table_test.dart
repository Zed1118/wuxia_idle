// test/features/loot_preview/drop_rumor_table_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';

void main() {
  final table = <DropEntry>[
    const EquipmentDrop(equipmentDefId: 'weapon_a', dropChance: 1.0),
    const EquipmentDrop(equipmentDefId: 'weapon_b', dropChance: 0.30),
    const ItemDrop(
      inventoryItemDefId: 'item_mojianshi',
      quantityMin: 1,
      quantityMax: 3,
      dropChance: 0.05,
    ),
  ];

  test('fromDropTable 映射类型 + 桶（主线）', () {
    final t = DropRumorTable.fromDropTable(table, isFirstClearGated: false);
    expect(t.entries.length, 3);
    expect(t.entries[0].defId, 'weapon_a');
    expect(t.entries[0].isEquipment, true);
    expect(t.entries[0].bucket, DropRumorBucket.changKeDe);
    expect(t.entries[1].bucket, DropRumorBucket.ouKeDe);
    expect(t.entries[2].isEquipment, false);
    expect(t.entries[2].bucket, DropRumorBucket.jiangHuChuanWen);
  });

  test('grouped 按桶排序（首通必得/常可得 → 偶可得 → 少有人得 → 江湖传闻）', () {
    final g = DropRumorTable.fromDropTable(table, isFirstClearGated: false).grouped();
    expect(g.keys.first, DropRumorBucket.changKeDe);
    expect(g.keys.last, DropRumorBucket.jiangHuChuanWen);
  });

  test('topRepresentatives 取最高桶 N 个', () {
    final reps = DropRumorTable.fromDropTable(table, isFirstClearGated: false)
        .topRepresentatives(2);
    expect(reps.length, 2);
    expect(reps[0].defId, 'weapon_a'); // 常可得优先
    expect(reps[1].defId, 'weapon_b'); // 偶可得次之
  });

  test('空表 isEmpty=true', () {
    expect(
      DropRumorTable.fromDropTable(const [], isFirstClearGated: false).isEmpty,
      true,
    );
  });

  test('塔层 1.0 → 首通必得', () {
    final t = DropRumorTable.fromDropTable(table, isFirstClearGated: true);
    expect(t.entries[0].bucket, DropRumorBucket.shouTongBiDe);
  });
}
