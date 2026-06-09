import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

SkillDef _mkSkill({required int power, required SkillType type}) => SkillDef(
      id: 's',
      name: 'x',
      description: 'd',
      type: type,
      powerMultiplier: power,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: 'v',
    );

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  AttackResult call({double profMult = 1.0}) {
    final n = GameRepository.instance.numbers;
    return DamageCalculator.calculateResolved(
      attackerInternalForce: 1000,
      attackerEquipmentAttack: 100,
      attackerCultivationLayer: CultivationLayer.chuKui,
      attackerSchool: TechniqueSchool.gangMeng,
      defenderSchool: TechniqueSchool.gangMeng,
      attackerRealmTier: RealmTier.sanLiu,
      attackerRealmLayer: RealmLayer.qiMeng,
      defenderRealmTier: RealmTier.sanLiu,
      defenderRealmLayer: RealmLayer.qiMeng,
      defenderDefenseRate: 0.05,
      defenderEvasionRate: 0.0,
      attackerCriticalRate: 0.0,
      attackPowerMultiplier: 1.0,
      skill: _mkSkill(power: 500, type: SkillType.normalAttack),
      n: n,
      rng: Random(0),
      proficiencyDamageMult: profMult,
    );
  }

  test('proficiencyDamageMult=1.30 时主伤害 = 基线 ×1.30', () {
    // base=(1000*0.4+100+500)=1000; *0.95(def)=950; *1.30=1235
    final baseline = call();
    final boosted = call(profMult: 1.30);
    expect(baseline.mainDamage, 950);
    expect(boosted.mainDamage, 1235);
  });

  test('默认 proficiencyDamageMult=1.0 时与旧行为一致(回归守)', () {
    final r = call();
    expect(r.mainDamage, 950);
  });
}
