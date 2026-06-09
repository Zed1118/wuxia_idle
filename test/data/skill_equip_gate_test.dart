import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';

SkillDef _skill({int? tier}) => SkillDef(
      id: 's',
      name: 'x',
      description: 'd',
      type: SkillType.powerSkill,
      powerMultiplier: 1000,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: 'v',
      tier: tier,
    );

void main() {
  test('§5.3:奇遇招 tier(1-7)≤ 境界 index+1 才可装配(沿 equipEncounterSkill 约定)', () {
    // tier 4(名家功)→ 需 realmTier.index >= 3(yiLiu)。
    final s = _skill(tier: 4);
    expect(s.canEquipAtRealm(RealmTier.yiLiu), true); // idx3 >= 3
    expect(s.canEquipAtRealm(RealmTier.erLiu), false); // idx2 < 3
    expect(s.canEquipAtRealm(RealmTier.wuSheng), true); // idx6 >= 3
  });

  test('§5.3:tier 1 招最低境界(xueTu)即可装配', () {
    final s = _skill(tier: 1);
    expect(s.canEquipAtRealm(RealmTier.xueTu), true); // idx0 >= 0
  });

  test('tier null(心法招)→ 恒可(由所属心法 tier 守,非招级)', () {
    final s = _skill(tier: null);
    expect(s.canEquipAtRealm(RealmTier.xueTu), true);
  });
}
