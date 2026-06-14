import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
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

  // ─────────────────────────────────────────────────────────────────────────────
  // in-battle e2e：证明 buff→param 链路在真实战斗结算中激活
  //
  // 策略：
  //   - 攻方高 criticalRate(1.0)保证每击必暴，跑 10 tick 取总伤害
  //   - 对比守方 WITH 'cycle_ningjia' vs WITHOUT(两场独立战，同 seed)
  //   - ningjia 守方受到的伤害必须更低（暴击增量被减半）
  //   - 此断言只在 _calculateInBattle 的 activeBuffs.contains('cycle_ningjia')
  //     分支真正走到时才能成立，直接证明了 buff→param→结算的完整路径
  // ─────────────────────────────────────────────────────────────────────────────

  test('凝甲 in-battle e2e：'
      '攻方 critRate=1.0 对 ningjia 守方总伤害 < 无 buff 守方（buff→param 链路生效）', () {
    final n = GameRepository.instance.numbers;
    const seed = 42;

    // 攻方：高内力 + 高装备攻击 + criticalRate=1.0（必暴）
    final attacker = _mkBCNingjia(charId: 1, teamSide: 0).copyWith(
      actionPoint: 1000, // 立即出手
      criticalRate: 1.0, // 必定暴击
      evasionRate: 0.0,
    );

    // 守方 A：携带 cycle_ningjia，暴击增量应减半
    // maxHp 设大，防止一击秒杀（需要多次命中才能累积差异）
    final defenderWithNingjia = _mkBCNingjia(charId: 11, teamSide: 1).copyWith(
      activeBuffs: ['cycle_ningjia'],
      evasionRate: 0.0,
      actionPoint: 0, // 让攻方先手
      maxHp: 50000,
      currentHp: 50000,
    );

    // 守方 B：无 buff，承受完整暴击伤害（同等 HP）
    final defenderWithout = _mkBCNingjia(charId: 12, teamSide: 1).copyWith(
      activeBuffs: const [],
      evasionRate: 0.0,
      actionPoint: 0,
      maxHp: 50000,
      currentHp: 50000,
    );

    // 场景 A：攻方 vs 凝甲守方，跑 5 tick（允许多次出手，两场 seed 完全一致）
    var stateA = BattleState.initial(
      leftTeam: [attacker],
      rightTeam: [defenderWithNingjia],
    );
    for (var i = 0; i < 5; i++) {
      stateA = BattleEngine.tick(stateA, n, rng: Random(seed + i));
    }

    // 场景 B：攻方 vs 无 buff 守方，跑 5 tick（相同 seed）
    var stateB = BattleState.initial(
      leftTeam: [attacker],
      rightTeam: [defenderWithout],
    );
    for (var i = 0; i < 5; i++) {
      stateB = BattleEngine.tick(stateB, n, rng: Random(seed + i));
    }

    final hpNingjia = stateA.rightTeam.first.currentHp;
    final hpWithout = stateB.rightTeam.first.currentHp;

    // 凝甲守方 HP 剩余应更多（挨打更少）
    // 即：ningjia 守方受到伤害 < 无 buff 守方受到伤害
    final damageToNingjia = 50000 - hpNingjia;
    final damageToWithout = 50000 - hpWithout;

    // 两场都必须有暴击命中发生（否则结论无意义）
    final critsInA = stateA.actionLog
        .where((a) => a.attackResult?.isCritical == true)
        .length;
    expect(critsInA, greaterThan(0),
        reason: '场景 A 必须有暴击命中才能验证凝甲效果');

    expect(
      damageToNingjia,
      lessThan(damageToWithout),
      reason: '凝甲守方 critDamageTakenMult=0.5 → 暴击增量减半 → '
          '受到总伤害应低于无 buff 守方\n'
          '  ningjia 受伤=$damageToNingjia, 无buff 受伤=$damageToWithout',
    );
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

// ─────────────────────────────────────────────────────────────────────────────
// in-battle e2e fixture helper（与 fanzhen_test 体例对齐）
// ─────────────────────────────────────────────────────────────────────────────

BattleCharacter _mkBCNingjia({
  required int charId,
  required int teamSide,
  int slotIndex = 0,
}) {
  final n = GameRepository.instance.numbers;
  final c = Character.create(
    name: '${teamSide == 0 ? "左" : "右"}$slotIndex',
    realmTier: RealmTier.erLiu,
    realmLayer: RealmLayer.yuanShu,
    attributes: Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: 3000,
    school: TechniqueSchool.gangMeng,
  )
    ..id = charId
    ..internalForceMax = 3000
    ..mainSkillId1 = 'skill_gangmeng_mingjia_basic'
    ..assistSkillId = 'skill_gangmeng_mingjia_skill'
    ..ultimateSkillId = 'skill_gangmeng_mingjia_ult';
  final eq = Equipment.create(
    defId: 'test',
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026, 1, 1),
    obtainedFrom: 'test',
    baseAttack: 580,
  );
  final tech = Technique.create(
    defId: 'tech_gangmeng_mingjia',
    ownerCharacterId: charId,
    tier: TechniqueTier.mingJiaGong,
    school: TechniqueSchool.gangMeng,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 1, 1),
    cultivationLayer: CultivationLayer.zhongCheng,
  );
  return BattleCharacter.fromCharacter(
    character: c,
    equipped: [eq],
    mainTechnique: tech,
    numbers: n,
    teamSide: teamSide,
    slotIndex: slotIndex,
  );
}
