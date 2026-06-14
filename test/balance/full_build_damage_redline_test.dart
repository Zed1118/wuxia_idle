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

    test('软红线:满 build 普攻(含暴击)不进十万 < 100000(保可读·与大招暴击同档)', () {
      final m = measureMaxBuild();
      // 本测点:非暴击 ~57902 / 暴击 ~86854,均「几万」不进十万,13% 余量。
      // 若未来强化/共鸣/开锋乘子或修炼度上调把满 build 普攻顶进十万 → 本测 FAIL,
      // 提示战力进入「不可读膨胀」区,需重新评估红线(GDD §5.4 软红线语义)。
      // 注:此为 calculator 裸值;terrain/formation/enmity 的 APM 末端乘叠加另由
      // test/audit/cross_system_damage_test.dart 审计。
      expect(m.crit, lessThan(100000),
          reason: 'GDD/CLAUDE §5.4 软红线:实战可见伤害不进十万(绝对天花板不进百万)');
    });
  });
}
