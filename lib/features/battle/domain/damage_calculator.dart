import 'dart:math';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/numbers_config.dart';
import 'derived_stats.dart';

/// 伤害计算器（phase1_tasks.md T10）。
///
/// 实现 GDD §5.3 / §5.4 / §5.5 全套公式：
/// 闪避判定 → 基础伤害 → 心法修炼度 → 流派克制 → 暴击 → 防御率 → 境界差。
///
/// **公式系数全部从 [NumbersConfig] 读**，不在本文件硬编码 0.4 / 1.0 / 0.7
/// 等魔数（phase1_tasks T10 §581 强制）。包括灵巧流派暴击倍率
/// (`combat.critical.lingqiao_damage_multiplier`)。
///
/// **测试可复现**：[AttackContext.rng] 字段允许注入 [Random.new](seed)，
/// 不传时回退到全局 [Random]。
class DamageCalculator {
  DamageCalculator._();

  /// 计算一次攻击的最终伤害。
  ///
  /// 阶段：
  /// 1. 闪避 roll：若 `roll < defender.evasionRate`，立刻返回 [AttackResult.dodged]。
  /// 2. 基础伤害 = 内力*ifFactor + Σ装备攻击*eqFactor + skill.powerMultiplier。
  /// 3. 修炼度倍率：从 attackerMainTech.cultivationLayer 查 yaml。
  /// 4. 流派克制倍率：从 [SchoolCounterMatrix] 3×3 查表。
  /// 5. 暴击：若 forceCritical 或 `roll < attacker.criticalRate`，应用倍率
  ///    （灵巧流派暴击 ×2.0；其他 ×1.5）。
  /// 6. 防御率：× (1 - defender.defenseRate)。
  /// 7. 境界差修正：高打低乘 attackerMod；低打高乘 defenderMod；同境界 1.0。
  /// 8. 取整 → finalDamage。
  static AttackResult calculate(AttackContext ctx, NumbersConfig n) {
    final rng = ctx.rng ?? Random();

    // === 1. 闪避 ===
    final evasion = CharacterDerivedStats.evasionRate(ctx.defender, n);
    if (rng.nextDouble() < evasion) {
      return AttackResult.dodged(
        evasionRate: evasion,
        breakdown: 'DODGED (evasion=${_fmt(evasion)})',
      );
    }

    // === 2. 基础伤害 ===
    final df = n.combat.damageFormula;
    final eqAtkSum = ctx.attackerEquipped.fold<int>(
      0,
      (sum, e) => sum + CharacterDerivedStats.effectiveEquipmentAttack(e, n),
    );
    final base = ctx.attacker.internalForce * df.internalForceFactor +
        eqAtkSum * df.equipmentAttackFactor +
        ctx.skill.powerMultiplier;

    // === 3. 修炼度倍率 ===
    final cultMult = n.cultivationMultiplier[ctx.attackerMainTech.cultivationLayer];
    if (cultMult == null) {
      throw StateError(
        'numbers.yaml techniques.cultivation.layers 缺 '
        '${ctx.attackerMainTech.cultivationLayer.name} 的 bonus_multiplier',
      );
    }

    // === 4. 流派克制 ===
    final schoolMult = n.schoolCounter.multiplierFor(
      ctx.attackerMainTech.school,
      ctx.defenderMainTech.school,
    );
    final extraEffect = n.schoolCounter.extraEffectFor(
      ctx.attackerMainTech.school,
      ctx.defenderMainTech.school,
    );

    // === 5. 暴击 ===
    final critRate = CharacterDerivedStats.criticalRate(ctx.attacker, n);
    final isCritical = ctx.forceCritical || rng.nextDouble() < critRate;
    final critMult = isCritical
        ? (ctx.attacker.school == TechniqueSchool.lingQiao
            ? n.combat.critical.lingqiaoDamageMultiplier
            : n.combat.critical.baseDamageMultiplier)
        : 1.0;

    // === 6. 防御率 ===
    final defRate = n.defenseRateByTier[ctx.defender.realmTier];
    if (defRate == null) {
      throw StateError(
        'numbers.yaml defenseRateByTier 缺 ${ctx.defender.realmTier.name}',
      );
    }
    final defMult = 1.0 - defRate;

    // === 7. 境界差修正 ===
    // RealmUtils.realmDiffModifier 返回 yaml 段原值 (attacker, defender)；
    // GDD §5.5：高打低用 attacker 放大；低打高用 defender 衰减；同境界 1.0。
    final atkLevel = RealmUtils.absoluteLevelOf(
      ctx.attacker.realmTier,
      ctx.attacker.realmLayer,
    );
    final defLevel = RealmUtils.absoluteLevelOf(
      ctx.defender.realmTier,
      ctx.defender.realmLayer,
    );
    final tierDiff =
        ctx.attacker.realmTier.index - ctx.defender.realmTier.index;
    final mods = RealmUtils.realmDiffModifier(
      ctx.attacker.realmTier,
      ctx.defender.realmTier,
    );
    final realmAttackerMod = mods.$1;
    final realmDefenderMod = mods.$2;
    final double realmMult;
    if (tierDiff > 0) {
      realmMult = realmAttackerMod;
    } else if (tierDiff < 0) {
      realmMult = realmDefenderMod;
    } else {
      realmMult = 1.0;
    }

    // === 8. 合并 ===
    final raw =
        base * cultMult * schoolMult * critMult * defMult * realmMult;
    final finalDamage = raw.toInt();

    final effects = <String>[];
    if (extraEffect != null) effects.add(extraEffect);

    final breakdown =
        '(${ctx.attacker.internalForce}*${_fmt(df.internalForceFactor)}'
        ' + $eqAtkSum'
        ' + ${ctx.skill.powerMultiplier})'
        ' * ${_fmt(cultMult)}'
        ' * ${_fmt(schoolMult)}'
        ' * ${_fmt(critMult)}'
        ' * ${_fmt(defMult)}'
        ' * ${_fmt(realmMult)}'
        ' = $finalDamage'
        ' [atkLv=$atkLevel,defLv=$defLevel]';

    return AttackResult(
      finalDamage: finalDamage,
      isCritical: isCritical,
      isDodged: false,
      schoolCounterMultiplier: schoolMult,
      realmDiffAttackerMod: realmAttackerMod,
      realmDiffDefenderMod: realmDefenderMod,
      cultivationMultiplier: cultMult,
      criticalMultiplier: critMult,
      defenseRate: defRate,
      evasionRate: evasion,
      appliedEffects: effects,
      formulaBreakdown: breakdown,
    );
  }

  /// 格式化系数为简洁字符串：1.0 → "1.0"；0.95 → "0.95"；2.5 → "2.5"。
  static String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(1);
    return v.toString();
  }
}

/// 一次攻击的输入（phase1_tasks.md T10 §530）。
///
/// `attackerEquipped` / `defenderEquipped` 传入"当前已穿装备"列表（最多 3 件：
/// 武器/护甲/饰品）；伤害计算只用到 attacker 装备攻击合计，但保留 defender
/// 列表是为后续吸血/反伤/破甲等扩展。
class AttackContext {
  final Character attacker;
  final List<Equipment> attackerEquipped;
  final Technique attackerMainTech;
  final SkillDef skill;

  final Character defender;
  final List<Equipment> defenderEquipped;
  final Technique defenderMainTech;

  /// 测试用：固定为 true 强制走暴击分支，跳过 `roll < criticalRate` 判定。
  final bool forceCritical;

  /// 测试用：注入 `Random(seed)` 让闪避/暴击 roll 可复现。生产传 null。
  final Random? rng;

  const AttackContext({
    required this.attacker,
    required this.attackerEquipped,
    required this.attackerMainTech,
    required this.skill,
    required this.defender,
    required this.defenderEquipped,
    required this.defenderMainTech,
    this.forceCritical = false,
    this.rng,
  });
}

/// 一次攻击的输出（phase1_tasks.md T10 §545）。
class AttackResult {
  /// 取整后的最终伤害。被闪避时为 0。
  final int finalDamage;

  /// 是否暴击。
  final bool isCritical;

  /// 是否被闪避。被闪避时其他系数字段无意义（保留默认 0/1.0）。
  final bool isDodged;

  /// 流派克制倍率（0.75 / 1.0 / 1.25）。
  final double schoolCounterMultiplier;

  /// numbers.yaml `level_diff_modifier.attacker` 段原值（高打低时生效）。
  final double realmDiffAttackerMod;

  /// numbers.yaml `level_diff_modifier.defender` 段原值（低打高时生效）。
  final double realmDiffDefenderMod;

  /// 攻方修炼度倍率（1.0 ~ 3.0）。
  final double cultivationMultiplier;

  /// 暴击伤害倍率（未暴击时 1.0；普通暴击 1.5；灵巧流派暴击 2.0）。
  final double criticalMultiplier;

  /// 守方防御率（GDD §5.5，应用项为 `1 - defenseRate`）。
  final double defenseRate;

  /// 守方闪避率（用于事件日志展示，与命中分支无关）。
  final double evasionRate;

  /// 流派克制成立时附带的额外效果（如 `extra_quake_dmg` / `internal_injury` /
  /// `crit_rate_+0.20`）。中性或被克分支为空。Phase 1 只是字符串打标，
  /// 实际效果在 T11/T12 的状态机里再消费。
  final List<String> appliedEffects;

  /// 调试用公式分解串：`"(800*0.4 + 130 + 500) * 1.0 * 1.25 * 1.5 * 0.85 * 1.0 = 1467"`
  /// （phase1_tasks T10 §577）。
  final String formulaBreakdown;

  const AttackResult({
    required this.finalDamage,
    required this.isCritical,
    required this.isDodged,
    required this.schoolCounterMultiplier,
    required this.realmDiffAttackerMod,
    required this.realmDiffDefenderMod,
    required this.cultivationMultiplier,
    required this.criticalMultiplier,
    required this.defenseRate,
    required this.evasionRate,
    required this.appliedEffects,
    required this.formulaBreakdown,
  });

  /// 闪避结果工厂。
  factory AttackResult.dodged({
    required double evasionRate,
    required String breakdown,
  }) {
    return AttackResult(
      finalDamage: 0,
      isCritical: false,
      isDodged: true,
      schoolCounterMultiplier: 1.0,
      realmDiffAttackerMod: 1.0,
      realmDiffDefenderMod: 1.0,
      cultivationMultiplier: 1.0,
      criticalMultiplier: 1.0,
      defenseRate: 0.0,
      evasionRate: evasionRate,
      appliedEffects: const [],
      formulaBreakdown: breakdown,
    );
  }
}
