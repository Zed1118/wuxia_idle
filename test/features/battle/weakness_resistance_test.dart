/// 第七阶段批二②：弱点/抗性流派乘子（defenderSchoolDamageMult）单测。
///
/// 守 §5.4：弱点最大 ≤2.0，默认 1.0 = 零回归。本测只验 DamageCalculator
/// 末端乘项行为（参数已加，caller wiring 在 Task 7）。
library;

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

  AttackResult call({double schoolMult = 1.0}) {
    final n = GameRepository.instance.numbers;
    return DamageCalculator.calculateResolved(
      attackerInternalForce: 1000,
      attackerEquipmentAttack: 100,
      attackerCultivationLayer: CultivationLayer.chuKui,
      attackerSchool: TechniqueSchool.gangMeng,
      // 守方同流派 → schoolMult(克制) = 1.0，隔离弱点乘子。
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
      defenderSchoolDamageMult: schoolMult,
    );
  }

  group('DamageCalculator.defenderSchoolDamageMult(批二②)', () {
    test('默认 1.0 = 零回归（与无参基线一致）', () {
      // base=(1000*0.4+100+500)=1000; *0.95(def)=950。
      expect(call().mainDamage, 950);
    });

    test('1.25 弱点 → mainDamage = 基线 ×1.25', () {
      expect(call(schoolMult: 1.25).mainDamage, (950 * 1.25).toInt());
    });

    test('0.75 抗性 → mainDamage 低于基线', () {
      final base = call().mainDamage;
      final resisted = call(schoolMult: 0.75).mainDamage;
      expect(resisted, lessThan(base));
      expect(resisted, (950 * 0.75).toInt());
    });

    test('finalDamage 比例随乘子单调（容差兜 toInt 取整）', () {
      final base = call().finalDamage;
      final weak = call(schoolMult: 1.25).finalDamage;
      expect(weak / base, closeTo(1.25, 0.01));
    });
  });
}
