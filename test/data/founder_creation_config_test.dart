
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import '../support/test_data.dart';

void main() {
  test('founder_creation.yaml 覆盖三流派且命盘池可抽 3 份', () async {
    final repo = await loadTestGameRepository();

    final config = repo.founderCreation;
    expect(config.schools.map((e) => e.school).toSet().length, 3);
    expect(config.origins.length, greaterThanOrEqualTo(3));
    expect(config.fatePool.length, greaterThanOrEqualTo(3));

    for (final school in config.schools) {
      expect(
        school.startingEquipmentIds,
        hasLength(3),
        reason: '${school.id} 应有武器/护甲/饰品三件起手装备',
      );
      final equips = school.startingEquipmentIds
          .map((id) => repo.equipmentDefs[id]!)
          .toList();
      expect(equips.map((e) => e.slot).toSet(), EquipmentSlot.values.toSet());
      for (final equip in equips) {
        expect(equip.tier, EquipmentTier.xunChang);
        if (equip.slot == EquipmentSlot.weapon) {
          expect(equip.schoolBias, school.school);
        }
      }
    }

    for (final fate in config.fatePool) {
      expect(fate.attributeProfile.total, inInclusiveRange(16, 24));
      expect(fate.attributeProfile.constitution, inInclusiveRange(1, 10));
      expect(fate.attributeProfile.enlightenment, inInclusiveRange(1, 10));
      expect(fate.attributeProfile.agility, inInclusiveRange(1, 10));
      expect(fate.attributeProfile.fortune, inInclusiveRange(1, 10));
    }
  });
}
