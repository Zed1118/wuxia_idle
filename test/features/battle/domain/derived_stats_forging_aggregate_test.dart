import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';

ForgingSlot _slot(ForgingSlotType type, int bonus, {bool unlocked = true, int idx = 1}) =>
    ForgingSlot()
      ..slotIndex = idx
      ..type = type
      ..unlocked = unlocked
      ..bonusValue = bonus;

Equipment _eq(List<ForgingSlot> slots) => Equipment.create(
      defId: 'weapon_test',
      tier: EquipmentTier.zhongQi,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
      forgingSlots: slots,
    );

void main() {
  group('forgingAggregatePct 跨全身装备求和', () {
    test('空装备列表 → 0', () {
      expect(CharacterDerivedStats.forgingAggregatePct([], ForgingSlotType.pierce), 0.0);
    });
    test('单件 pierce 15 → 0.15', () {
      final eqs = [_eq([_slot(ForgingSlotType.pierce, 15)])];
      expect(CharacterDerivedStats.forgingAggregatePct(eqs, ForgingSlotType.pierce), 0.15);
    });
    test('两件 pierce 15+20 → 0.35', () {
      final eqs = [
        _eq([_slot(ForgingSlotType.pierce, 15)]),
        _eq([_slot(ForgingSlotType.pierce, 20, idx: 2)]),
      ];
      expect(CharacterDerivedStats.forgingAggregatePct(eqs, ForgingSlotType.pierce), 0.35);
    });
    test('未解锁槽不计入', () {
      final eqs = [_eq([_slot(ForgingSlotType.pierce, 20, unlocked: false)])];
      expect(CharacterDerivedStats.forgingAggregatePct(eqs, ForgingSlotType.pierce), 0.0);
    });
    test('类型过滤:查 lifesteal 不计 pierce 槽', () {
      final eqs = [_eq([_slot(ForgingSlotType.pierce, 20), _slot(ForgingSlotType.lifesteal, 10, idx: 2)])];
      expect(CharacterDerivedStats.forgingAggregatePct(eqs, ForgingSlotType.lifesteal), 0.10);
    });
  });
}
