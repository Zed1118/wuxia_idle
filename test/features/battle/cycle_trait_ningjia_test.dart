import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

/// C1 凝甲词条单元测试。
///
/// 覆盖两个语义：
/// 1. 暴击时 defenderCritDamageTakenMult=0.5 → 暴击增量减半，
///    effectiveCritMult = 1 + (baseMult-1)*0.5；
/// 2. 非暴击时 defenderCritDamageTakenMult 不影响伤害（两参数值结果相同）。

const kPower = 500;
const kIfForce = 1000;
const kEqAtk = 100;
const kDefRate = 0.05;

SkillDef mkNingjiaSkill() => const SkillDef(
      id: 's_ningjia',
      name: '测试招',
      description: 'test',
      type: SkillType.normalAttack,
      powerMultiplier: kPower,
      internalForceCost: 0,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: 'v',
    );

AttackResult callCalc({
  required bool forceCritical,
  required double defenderCritDamageTakenMult,
}) {
  final n = GameRepository.instance.numbers;
  return DamageCalculator.calculateResolved(
    attackerInternalForce: kIfForce,
    attackerEquipmentAttack: kEqAtk,
    attackerCultivationLayer: CultivationLayer.chuKui,
    attackerSchool: TechniqueSchool.gangMeng,
    defenderSchool: TechniqueSchool.gangMeng,
    attackerRealmTier: RealmTier.sanLiu,
    attackerRealmLayer: RealmLayer.qiMeng,
    defenderRealmTier: RealmTier.sanLiu,
    defenderRealmLayer: RealmLayer.qiMeng,
    defenderDefenseRate: kDefRate,
    defenderEvasionRate: 0.0,
    attackerCriticalRate: 0.0, // 关闭随机暴击，由 forceCritical 控制
    attackPowerMultiplier: 1.0,
    skill: mkNingjiaSkill(),
    n: n,
    rng: Random(0),
    forceCritical: forceCritical,
    defenderCritDamageTakenMult: defenderCritDamageTakenMult,
  );
}

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  test('凝甲:暴击伤害增量减半(forceCritical + mult=0.5)', () {
    final n = GameRepository.instance.numbers;
    final baseMult = n.combat.critical.baseDamageMultiplier; // e.g. 1.5

    final baseline = callCalc(forceCritical: true, defenderCritDamageTakenMult: 1.0);
    final ningjia = callCalc(forceCritical: true, defenderCritDamageTakenMult: 0.5);

    // effectiveCritMult when mult=1.0 = baseMult
    // effectiveCritMult when mult=0.5 = 1 + (baseMult - 1) * 0.5
    final effectiveCritHalved = 1.0 + (baseMult - 1.0) * 0.5;

    // base = ifForce*ifFactor + eqAtk*eqFactor + power
    final df = n.combat.damageFormula;
    final base = kIfForce * df.internalForceFactor +
        kEqAtk * df.equipmentAttackFactor +
        kPower;
    final cultMult = n.cultivationMultiplier[CultivationLayer.chuKui]!;
    final schoolMult = n.schoolCounter.multiplierFor(
        TechniqueSchool.gangMeng, TechniqueSchool.gangMeng);
    final defMult = 1.0 - kDefRate;

    final expectedBaseline = (base * cultMult * schoolMult * baseMult * defMult).toInt();
    final expectedNingjia = (base * cultMult * schoolMult * effectiveCritHalved * defMult).toInt();

    expect(baseline.mainDamage, expectedBaseline,
        reason: '凝甲 mult=1.0 基线应与完整暴击倍率一致');
    expect(ningjia.mainDamage, expectedNingjia,
        reason: '凝甲 mult=0.5 伤害应体现暴击增量减半');
    expect(ningjia.mainDamage, lessThan(baseline.mainDamage),
        reason: '凝甲减伤后必须低于基线');
    // 两者均 isCritical=true
    expect(baseline.isCritical, isTrue);
    expect(ningjia.isCritical, isTrue);
  });

  test('凝甲:非暴击时 defenderCritDamageTakenMult 无效果', () {
    final normal10 = callCalc(forceCritical: false, defenderCritDamageTakenMult: 1.0);
    final normal05 = callCalc(forceCritical: false, defenderCritDamageTakenMult: 0.5);

    expect(normal10.mainDamage, normal05.mainDamage,
        reason: '非暴击时凝甲 mult 不影响伤害');
    expect(normal10.isCritical, isFalse);
    expect(normal05.isCritical, isFalse);
  });

  test('凝甲:从 numbers.cycleEvolution.traits.ningjia 读取参数值', () {
    final n = GameRepository.instance.numbers;
    // 验证 yaml 里配置的值是 0.5（不硬编码，而是从 config 读）
    expect(n.cycleEvolution.traits.ningjia.critDamageTakenMult, 0.5,
        reason: 'numbers.yaml cycle_evolution.traits.ningjia.crit_damage_taken_mult 应为 0.5');
  });

  test('凝甲:默认参数 1.0 与无参数行为完全一致(零回归)', () {
    // 不传 defenderCritDamageTakenMult（默认 1.0）vs 显式 1.0
    final n = GameRepository.instance.numbers;
    final defaultParam = DamageCalculator.calculateResolved(
      attackerInternalForce: kIfForce,
      attackerEquipmentAttack: kEqAtk,
      attackerCultivationLayer: CultivationLayer.chuKui,
      attackerSchool: TechniqueSchool.gangMeng,
      defenderSchool: TechniqueSchool.gangMeng,
      attackerRealmTier: RealmTier.sanLiu,
      attackerRealmLayer: RealmLayer.qiMeng,
      defenderRealmTier: RealmTier.sanLiu,
      defenderRealmLayer: RealmLayer.qiMeng,
      defenderDefenseRate: kDefRate,
      defenderEvasionRate: 0.0,
      attackerCriticalRate: 0.0,
      attackPowerMultiplier: 1.0,
      skill: mkNingjiaSkill(),
      n: n,
      rng: Random(0),
      forceCritical: true,
      // defenderCritDamageTakenMult 不传 → 默认 1.0
    );
    final explicit10 = callCalc(forceCritical: true, defenderCritDamageTakenMult: 1.0);

    expect(defaultParam.mainDamage, explicit10.mainDamage,
        reason: '默认 defenderCritDamageTakenMult=1.0 应与显式传 1.0 结果相同');
  });
}
