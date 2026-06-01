import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

BattleCharacter _base({bool isBoss = false}) => BattleCharacter(
      characterId: 1,
      name: '测试',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 100,
      currentHp: 100,
      maxInternalForce: 100,
      currentInternalForce: 100,
      speed: 100,
      criticalRate: 0.05,
      evasionRate: 0.05,
      defenseRate: 0.1,
      totalEquipmentAttack: 100,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
      isBoss: isBoss,
    );

void main() {
  test('isBoss 默认 false', () {
    expect(_base().isBoss, false);
  });

  test('isBoss=true 可构造', () {
    expect(_base(isBoss: true).isBoss, true);
  });

  test('copyWith 保留 isBoss', () {
    final c = _base(isBoss: true).copyWith(currentHp: 50);
    expect(c.isBoss, true);
    expect(c.currentHp, 50);
  });

  test('copyWith 可改 isBoss', () {
    expect(_base().copyWith(isBoss: true).isBoss, true);
  });
}
