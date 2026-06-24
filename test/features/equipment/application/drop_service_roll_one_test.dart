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

  test('忽略非 EquipmentDrop 条目', () {
    final table = [
      const ItemDrop(
          inventoryItemDefId: 'item_x', quantityMin: 1, quantityMax: 1,
          dropChance: 1.0),
    ];
    expect(svc().rollOneWeighted(table, _ConstRng(0.0)), isNull);
  });
}
