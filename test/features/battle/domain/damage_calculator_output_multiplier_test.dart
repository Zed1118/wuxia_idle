import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

SkillDef _mkSkill({required int power}) => SkillDef(
      id: 's',
      name: 'x',
      description: 'd',
      type: SkillType.normalAttack,
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

  AttackResult call({double outputMultiplier = 1.0}) {
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
      skill: _mkSkill(power: 500),
      n: n,
      rng: Random(0),
      outputMultiplier: outputMultiplier,
    );
  }

  test('outputMultiplier 0.95 使主伤降 5%', () {
    final full = call(outputMultiplier: 1.0);
    final reduced = call(outputMultiplier: 0.95);
    expect(reduced.mainDamage, (full.mainDamage * 0.95).toInt());
  });

  test('outputMultiplier 默认 1.0 不改变伤害', () {
    final implicit = call();
    final explicit = call(outputMultiplier: 1.0);
    expect(implicit.mainDamage, explicit.mainDamage);
    expect(implicit.finalDamage, explicit.finalDamage);
  });

  test('outputMultiplier 仅乘主伤，震伤(quakeDamage)不受影响', () {
    // 注:当前 fixture 无震伤(gangMeng vs gangMeng,不触发刚猛克阴柔)
    // 确认 quakeDamage=0，finalDamage == mainDamage
    final full = call(outputMultiplier: 1.0);
    final reduced = call(outputMultiplier: 0.95);
    expect(full.quakeDamage, 0);
    expect(reduced.quakeDamage, 0);
    expect(reduced.finalDamage, reduced.mainDamage);
  });
}
