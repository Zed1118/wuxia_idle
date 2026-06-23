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

  test('fromDropTable 映射类型 + 桶（主线 scrollOnly · 无秘籍则不门控）', () {
    final t = DropRumorTable.fromDropTable(
      table,
      gating: FirstClearGating.scrollOnly,
    );
    expect(t.entries.length, 3);
    expect(t.entries[0].defId, 'weapon_a');
    expect(t.entries[0].isEquipment, true);
    expect(t.entries[0].bucket, DropRumorBucket.changKeDe);
    expect(t.entries[1].bucket, DropRumorBucket.ouKeDe);
    expect(t.entries[2].isEquipment, false);
    expect(t.entries[2].bucket, DropRumorBucket.jiangHuChuanWen);
  });

  test('grouped 按桶排序（首通必得/常可得 → 偶可得 → 少有人得 → 江湖传闻）', () {
    final g = DropRumorTable.fromDropTable(
      table,
      gating: FirstClearGating.scrollOnly,
    ).grouped();
    expect(g.keys.first, DropRumorBucket.changKeDe);
    expect(g.keys.last, DropRumorBucket.jiangHuChuanWen);
  });

  test('topRepresentatives 取最高桶 N 个', () {
    final reps = DropRumorTable.fromDropTable(
      table,
      gating: FirstClearGating.scrollOnly,
    ).topRepresentatives(2);
    expect(reps.length, 2);
    expect(reps[0].defId, 'weapon_a'); // 常可得优先
    expect(reps[1].defId, 'weapon_b'); // 偶可得次之
  });

  test('空表 isEmpty=true', () {
    expect(
      DropRumorTable.fromDropTable(
        const [],
        gating: FirstClearGating.scrollOnly,
      ).isEmpty,
      true,
    );
  });

  test('塔层 wholeChannel · 1.0 → 首通必得', () {
    final t = DropRumorTable.fromDropTable(
      table,
      gating: FirstClearGating.wholeChannel,
    );
    expect(t.entries[0].bucket, DropRumorBucket.shouTongBiDe);
  });

  // ── F2(2026-06-23 续48)·主线 per-entry 首通门控核心回归 ─────────────────────
  // 此前主线整表传布尔 false → 秘籍(item_scroll_*,dropChance=1.0)被错归常可得,
  // 实为首通必得(重打不补)。runtime shouldSkipScrollDrop 逐 defId,preview 须同步。
  group('F2 · 主线 scrollOnly 逐条门控（秘籍门控、装备不门控）', () {
    final mixed = <DropEntry>[
      const EquipmentDrop(equipmentDefId: 'weapon_a', dropChance: 1.0),
      const ItemDrop(
        inventoryItemDefId: 'item_scroll_guan_shan_ba_ji',
        quantityMin: 1,
        quantityMax: 1,
        dropChance: 1.0,
      ),
    ];

    test('同表内：秘籍→首通必得，装备 1.0→常可得', () {
      final t = DropRumorTable.fromDropTable(
        mixed,
        gating: FirstClearGating.scrollOnly,
      );
      final byDef = {for (final e in t.entries) e.defId: e.bucket};
      expect(
        byDef['item_scroll_guan_shan_ba_ji'],
        DropRumorBucket.shouTongBiDe,
      );
      expect(byDef['weapon_a'], DropRumorBucket.changKeDe);
    });

    test('含秘籍 → hasFirstClearGatedEntry=true（驱动主线脚注）', () {
      final t = DropRumorTable.fromDropTable(
        mixed,
        gating: FirstClearGating.scrollOnly,
      );
      expect(t.hasFirstClearGatedEntry, true);
    });

    test('无秘籍 → hasFirstClearGatedEntry=false（不显脚注）', () {
      final t = DropRumorTable.fromDropTable(
        const [EquipmentDrop(equipmentDefId: 'weapon_a', dropChance: 1.0)],
        gating: FirstClearGating.scrollOnly,
      );
      expect(t.hasFirstClearGatedEntry, false);
    });

    test('wholeChannel：秘籍与装备 1.0 同为首通必得（整渠道门控）', () {
      final t = DropRumorTable.fromDropTable(
        mixed,
        gating: FirstClearGating.wholeChannel,
      );
      expect(
        t.entries.every((e) => e.bucket == DropRumorBucket.shouTongBiDe),
        true,
      );
    });
  });
}
