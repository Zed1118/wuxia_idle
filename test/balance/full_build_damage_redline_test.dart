import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';

/// 满强化神物 build 普通伤害软红线(2026-06-14 红线语义收口 · 用户拍板分两层)。
///
/// 背景:GDD §5.2/§5.4「普通伤害 ≤8000」是**典型 build 设计目标**,非硬数学界。
/// 满强化(+49 ×3.45)× 满共鸣(心剑通灵 ×1.30)× 双攻击开锋(×1.35)的神物极值
/// build,单武器有效攻击 baseAttack×3.45×1.30×1.35 远超装备攻击基础表值红线 2000;
/// 多部位求和后经武圣极境 ×3.0 修炼度,普攻实战伤害远 >8000。这是**有意的终局
/// 爽感**,不是 bug —— 真正的硬约束是「**配置基础表值不得突破**」+「**实战可见值
/// 不进百万级膨胀(保可读)**」。本测钉死后者:满 build 普攻(含暴击)不进百万。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUp(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });

  /// 构造满 build 装备:+49 强化 + 满共鸣(高 battleCount → 心剑通灵)+ 双攻击开锋槽。
  Equipment maxBuild(EquipmentSlot slot, int baseAttack) => Equipment.create(
        defId: 'probe_${slot.name}',
        tier: EquipmentTier.shenWu,
        slot: slot,
        obtainedAt: DateTime(2026, 6, 14),
        obtainedFrom: 'redline_probe',
        baseAttack: baseAttack,
        enhanceLevel: 49,
        battleCount: 1000000, // → 最高共鸣段(心剑通灵 ×1.30)
        forgingSlots: [
          ForgingSlot()
            ..slotIndex = 1
            ..type = ForgingSlotType.attack
            ..unlocked = true
            ..bonusValue = 15,
          ForgingSlot()
            ..slotIndex = 2
            ..type = ForgingSlotType.attack
            ..unlocked = true
            ..bonusValue = 20,
        ],
      );

  const normal = SkillDef(
    id: 'probe_normal',
    name: '普攻',
    description: '',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: '',
  );

  // ── Task 4.2 红线对照:aoe 大招 vs 同倍率 single 大招 ──
  // A 方案核心不变量:aoe「单次伤害=单体值不抬高」。两技 powerMultiplier 相同,
  // 仅 targetType 不同(aoe 群体 / 单体)。证 aoe 不在单次伤害维度额外加成。
  const aoeUltimate = SkillDef(
    id: 'probe_aoe_ultimate',
    name: '群体大招',
    description: '',
    type: SkillType.powerSkill,
    targetType: TargetType.aoe,
    powerMultiplier: 6000, // 大招级倍率(§5.4 大招 5000+)
    internalForceCost: 200,
    cooldownTurns: 4,
    requiresManualTrigger: false,
    visualEffect: '',
  );

  const singleUltimate = SkillDef(
    id: 'probe_single_ultimate',
    name: '单体大招',
    description: '',
    type: SkillType.powerSkill,
    powerMultiplier: 6000, // 同倍率单体对照
    internalForceCost: 200,
    cooldownTurns: 4,
    requiresManualTrigger: false,
    visualEffect: '',
  );

  /// 满强化神物 build 武圣极境普攻(刚猛克阴柔 1.25 worst-case)。
  ({int totalEqAtk, int nonCrit, int crit}) measureMaxBuild() {
    final n = GameRepository.instance.numbers;
    final totalEqAtk =
        CharacterDerivedStats.effectiveEquipmentAttack(
              maxBuild(EquipmentSlot.weapon, 2000), n) +
            CharacterDerivedStats.effectiveEquipmentAttack(
              maxBuild(EquipmentSlot.accessory, 850), n);

    int calc({required bool crit}) => DamageCalculator.calculateResolved(
          attackerInternalForce: 15000,
          attackerEquipmentAttack: totalEqAtk,
          attackerCultivationLayer: CultivationLayer.jiJing,
          attackerSchool: TechniqueSchool.gangMeng,
          defenderSchool: TechniqueSchool.yinRou, // 刚猛克阴柔 1.25
          attackerRealmTier: RealmTier.wuSheng,
          attackerRealmLayer: RealmLayer.dengFeng,
          defenderRealmTier: RealmTier.wuSheng,
          defenderRealmLayer: RealmLayer.dengFeng,
          defenderDefenseRate: 0.35, // 武圣固定档
          defenderEvasionRate: 0.0,
          attackerCriticalRate: crit ? 1.0 : 0.0,
          attackPowerMultiplier: 1.0,
          skill: normal,
          n: n,
          rng: Random(7),
          forceCritical: crit,
        ).mainDamage;

    return (totalEqAtk: totalEqAtk, nonCrit: calc(crit: false), crit: calc(crit: true));
  }

  group('满强化神物 build 普攻软红线(红线分两层 · 2026-06-14 收口)', () {
    test('硬红线:装备基础表值 ≤ 2000(本 build 用 baseAttack 2000/850 合规)', () {
      // 派生有效攻击(强化/共鸣/开锋后)≫ 2000 是设计放行;红线约束的是
      // 配置基础表值 baseAttack,不是派生值。
      final weaponEff = CharacterDerivedStats.effectiveEquipmentAttack(
          maxBuild(EquipmentSlot.weapon, 2000), GameRepository.instance.numbers);
      expect(weaponEff, greaterThan(2000),
          reason: '派生有效攻击经强化×共鸣×开锋连乘必 ≫ baseAttack(本测点:约 12109)');
    });

    test('坐实「普通伤害 ≤8000 是典型设计目标·非硬数学界」:满 build 普攻远越 8000', () {
      final m = measureMaxBuild();
      expect(m.nonCrit, greaterThan(8000),
          reason: '满强化神物 build 普攻非暴击远超 8000(本测点约 57902)'
              '——证 GDD/CLAUDE §5.4「≤8000」是典型 build 设计目标,非极值 build 硬界');
      expect(m.crit, greaterThan(m.nonCrit), reason: '暴击 > 非暴击');
    });

    test('软红线:满 build 普攻(含暴击)不进百万 < 1000000(唯一硬线·保可读)', () {
      final m = measureMaxBuild();
      // 本测点 calculator 裸值下界:非暴击 ~57902 / 暴击 ~86854(进十万但远不进百万)。
      // 注:此为 calculator 探针,未含 per-skill 熟练度 ×1.30 + terrain/formation/enmity
      // APM 末端乘 + 飞升 +1 阶差距;真实战斗峰值 ~13.5 万(普攻)/~21 万(大招),由
      // test/tools/balance_simulator_test.dart 极值×周目诊断测实测兜底(硬断言不进百万)。
      // 软红线唯一硬线 = 不进百万(2026-06-14 诊断实测峰值 13-21 万后用户拍板,从「不进
      // 十万」放宽,6 位数仍玩家可读)。若未来乘子上调把峰值顶进百万 → 本测+诊断测 FAIL。
      expect(m.crit, lessThan(1000000),
          reason: 'GDD/CLAUDE §5.4 软红线唯一硬线:实战可见伤害不进百万级膨胀');
    });

    // ── Task 4.2 红线对照:aoe 单次伤害不抬高(A 方案核心) ──
    test('A 方案不变量:aoe 大招对单一目标伤害 == 同倍率 single 大招(单次不抬高)', () {
      final n = GameRepository.instance.numbers;
      final totalEqAtk =
          CharacterDerivedStats.effectiveEquipmentAttack(
                maxBuild(EquipmentSlot.weapon, 2000), n) +
              CharacterDerivedStats.effectiveEquipmentAttack(
                maxBuild(EquipmentSlot.accessory, 850), n);

      // 单一真相源 calculateResolved 跑两次:aoe 技 vs single 技,同攻防/同倍率/
      // 同 rng seed/同 forceCritical → 唯一差异只有 skill.targetType。
      int calc(SkillDef skill, {required bool crit}) =>
          DamageCalculator.calculateResolved(
            attackerInternalForce: 15000,
            attackerEquipmentAttack: totalEqAtk,
            attackerCultivationLayer: CultivationLayer.jiJing,
            attackerSchool: TechniqueSchool.gangMeng,
            defenderSchool: TechniqueSchool.yinRou,
            attackerRealmTier: RealmTier.wuSheng,
            attackerRealmLayer: RealmLayer.dengFeng,
            defenderRealmTier: RealmTier.wuSheng,
            defenderRealmLayer: RealmLayer.dengFeng,
            defenderDefenseRate: 0.35,
            defenderEvasionRate: 0.0,
            attackerCriticalRate: crit ? 1.0 : 0.0,
            attackPowerMultiplier: 1.0,
            skill: skill,
            n: n,
            rng: Random(7),
            forceCritical: crit,
          ).mainDamage;

      final aoeNonCrit = calc(aoeUltimate, crit: false);
      final singleNonCrit = calc(singleUltimate, crit: false);
      final aoeCrit = calc(aoeUltimate, crit: true);
      final singleCrit = calc(singleUltimate, crit: true);

      expect(singleNonCrit, greaterThan(0), reason: '对照 single 必须真出伤害');
      expect(aoeNonCrit, equals(singleNonCrit),
          reason: 'A 方案:aoe 大招对单一目标的单次伤害 == 同倍率 single 大招,'
              'aoe 不在单次伤害维度额外抬高(只是命中全体)');
      expect(aoeCrit, equals(singleCrit),
          reason: '暴击路径同理:aoe 单次暴击伤害 == single 暴击伤害');

      // 全体场景(3 敌)总输出不进百万:A 方案下每目标 = 单体峰值(本探针 calculator
      // 裸值,真实战斗大招峰值 ~21 万,见 §5.4),即便 ×3 ≈ 60+ 万级仍 < 100 万。
      // 因单次不抬高,红线本质不受 aoe 冲击——单次峰值已由上面软红线测覆盖,此处只补
      // 「aoe 单次 == single」对照断言,不重复钉单次峰值。
      expect(aoeCrit * 3, lessThan(1000000),
          reason: 'A 方案:3 敌全体场景总输出(每目标=单体峰值×3)仍不进百万');
    });
  });
}
