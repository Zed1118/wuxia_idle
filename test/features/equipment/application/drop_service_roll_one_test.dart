import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

class _ConstRng implements Rng {
  _ConstRng(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  T pick<T>(List<T> list) => list[0];
}

void main() {
  EquipmentDef def(String id) => EquipmentDef(
    id: id,
    name: id,
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    baseAttackMin: 1,
    baseAttackMax: 1,
    baseHealthMin: 0,
    baseHealthMax: 0,
    baseSpeedMin: 0,
    baseSpeedMax: 0,
    presetLoreIds: const [],
    dropSourceTags: const [],
    iconPath: '',
  );

  DropService svc() => DropService(
    equipmentDefLookup: def,
    defaultObtainedFrom: 'T',
    now: () => DateTime(2026, 6, 24),
  );

  test('空表返回 null', () {
    expect(svc().rollOneWeighted(const [], _ConstRng(0.0)), isNull);
  });

  test('命中按权重抽恰好 1 件（roll=0.0 落第 1 条）', () {
    final table = [
      const EquipmentDrop(equipmentDefId: 'a', dropChance: 1.0),
      const EquipmentDrop(equipmentDefId: 'b', dropChance: 1.0),
    ];
    final eq = svc().rollOneWeighted(table, _ConstRng(0.0));
    expect(eq, isNotNull);
    expect(eq!.defId, 'a');
  });

  test('等权区间边界:roll 落首/中/尾/跨区间点各归其位(严格 < 语义)', () {
    // 只测 roll=0.0 单点对「恒返第一条」「反序遍历」等实现同样成立。
    // 生产语义:roll×total 逐条累计,严格小于才命中 → 恰落累计边界时归下一条。
    final table = [
      const EquipmentDrop(equipmentDefId: 'a', dropChance: 1.0),
      const EquipmentDrop(equipmentDefId: 'b', dropChance: 1.0),
    ];
    final cases = {
      0.0: 'a', // 区间首
      0.49: 'a', // a 区间中
      0.5: 'b', // 恰跨边界(1.0-1.0=0 不 <0)→ 归下一条
      0.99: 'b', // b 区间尾
      1.0: 'b', // 上界:浮点兜底落 last
    };
    for (final e in cases.entries) {
      final eq = svc().rollOneWeighted(table, _ConstRng(e.key));
      expect(eq?.defId, e.value, reason: 'roll=${e.key} 应落 ${e.value}');
    }
  });

  test('非等权区间边界(1:3):累计边界严格落入下一条', () {
    final table = [
      const EquipmentDrop(equipmentDefId: 'a', dropChance: 1.0),
      const EquipmentDrop(equipmentDefId: 'b', dropChance: 3.0),
    ];
    final cases = {
      0.24: 'a', // a 区间内(0.96<1.0)
      0.25: 'b', // 恰跨边界(1.0-1.0=0 不 <0)→ 归 b
      0.75: 'b', // b 区间中
      0.999: 'b', // b 区间尾
    };
    for (final e in cases.entries) {
      final eq = svc().rollOneWeighted(table, _ConstRng(e.key));
      expect(eq?.defId, e.value, reason: 'roll=${e.key} 应落 ${e.value}');
    }
  });

  test('忽略非 EquipmentDrop 条目', () {
    final table = [
      const ItemDrop(
        inventoryItemDefId: 'item_x',
        quantityMin: 1,
        quantityMax: 1,
        dropChance: 1.0,
      ),
    ];
    expect(svc().rollOneWeighted(table, _ConstRng(0.0)), isNull);
  });
}
