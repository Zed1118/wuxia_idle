import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

BattleCharacter _c() => const BattleCharacter(
      characterId: 1, name: 'a', realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.yuanShu, school: TechniqueSchool.gangMeng,
      maxHp: 1000, currentHp: 1000, maxInternalForce: 500,
      currentInternalForce: 500, speed: 100, criticalRate: 0.0,
      evasionRate: 0.0, defenseRate: 0.1, totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: [], skillCooldowns: {},
      activeBuffs: [], actionPoint: 0, isAlive: true,
      teamSide: 1, slotIndex: 0,
    );

void main() {
  test('蓄力/踉跄字段缺省', () {
    final c = _c();
    expect(c.chargeSkillId, isNull);
    expect(c.chargingSkill, isNull);
    expect(c.chargeTicksRemaining, 0);
    expect(c.staggerTicksRemaining, 0);
  });

  test('copyWith 可设可清', () {
    final c = _c().copyWith(chargeTicksRemaining: 3, staggerTicksRemaining: 2);
    expect(c.chargeTicksRemaining, 3);
    expect(c.staggerTicksRemaining, 2);
    final cleared = c.copyWith(staggerTicksRemaining: 0);
    expect(cleared.staggerTicksRemaining, 0);
  });
}
