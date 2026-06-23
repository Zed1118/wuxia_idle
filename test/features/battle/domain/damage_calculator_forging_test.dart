import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

const _skill = SkillDef(
  id: 's_pierce_test',
  name: 'x',
  description: 'd',
  type: SkillType.normalAttack,
  powerMultiplier: 500,
  internalForceCost: 0,
  cooldownTurns: 0,
  requiresManualTrigger: false,
  visualEffect: 'v',
);

void main() {
  late dynamic n;
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
    n = GameRepository.instance.numbers;
  });

  AttackResult call({
    double pierce = 0.0,
    double lifesteal = 0.0,
    bool crit = false,
  }) =>
      DamageCalculator.calculateResolved(
        attackerInternalForce: 5000,
        attackerEquipmentAttack: 1000,
        attackerCultivationLayer: CultivationLayer.xiaoCheng,
        attackerSchool: TechniqueSchool.gangMeng,
        defenderSchool: TechniqueSchool.gangMeng,
        attackerRealmTier: RealmTier.jueDing,
        attackerRealmLayer: RealmLayer.qiMeng,
        defenderRealmTier: RealmTier.jueDing,
        defenderRealmLayer: RealmLayer.qiMeng,
        defenderDefenseRate: 0.30,
        defenderEvasionRate: 0.0,
        attackerCriticalRate: 0.0,
        attackPowerMultiplier: 1.0,
        skill: _skill,
        n: n,
        rng: Random(1),
        forceCritical: crit,
        attackerPiercePct: pierce,
        attackerLifestealPct: lifesteal,
      );

  test('破甲绝对减:def0.30 pierce0.20 → 有效0.10(伤害高于无破甲)', () {
    final base = call();
    final pierced = call(pierce: 0.20);
    // base uses defMult=0.70, pierced uses defMult=0.90
    // pierced.mainDamage = base.mainDamage * 0.90 / 0.70 (rounded)
    expect(pierced.mainDamage, (base.mainDamage * 0.90 / 0.70).round());
  });

  test('破甲 clamp 0 下界:pierce > def → 防御率归零不为负', () {
    // pierce=0.50 > def=0.30 → effectiveDefRate=0 → same as pierce=0.30 (also → 0)
    expect(call(pierce: 0.50).mainDamage, call(pierce: 0.30).mainDamage);
  });

  test('默认 pierce=0 零回归', () {
    expect(call().mainDamage, call(pierce: 0.0).mainDamage);
  });

  test('破甲标记进 appliedEffects', () {
    expect(call(pierce: 0.20).appliedEffects, contains('armor_pierce'));
    expect(call().appliedEffects, isNot(contains('armor_pierce')));
  });

  test('吸血量 = mainDamage × lifesteal(floor)', () {
    final r = call(lifesteal: 0.15);
    expect(r.lifestealHeal, (r.mainDamage * 0.15).floor());
  });

  test('lifesteal=0 → lifestealHeal 0', () {
    expect(call().lifestealHeal, 0);
  });
}
