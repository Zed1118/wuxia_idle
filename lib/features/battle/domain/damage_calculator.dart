import 'dart:math';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/numbers_config.dart';
import '../../../core/domain/skill_usage_entry.dart';
import '../../cultivation/domain/skill_proficiency.dart';
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
    // Character 路径 adapter:解析实体字段 → 调单一真相源 [calculateResolved]。
    // 内力用满值 internalForce · 装备攻击 = Σ effectiveEquipmentAttack ·
    // 防御率走 numbers.yaml 境界 base · attackPowerMultiplier=1.0(无烘焙)。
    final eqAtkSum = ctx.attackerEquipped.fold<int>(
      0,
      (sum, e) => sum + CharacterDerivedStats.effectiveEquipmentAttack(e, n),
    );
    final defRate = n.defenseRateByTier[ctx.defender.realmTier];
    if (defRate == null) {
      throw StateError(
        'numbers.yaml defenseRateByTier 缺 ${ctx.defender.realmTier.name}',
      );
    }
    // 可玩性 P1a:从攻方主修心法 skillUsageCount 派生该招熟练度综合倍率。
    final uses = ctx.attackerMainTech.skillUsageCount.countOf(ctx.skill.id);
    final perSkillPct = ctx.skill.proficiency?.damagePctAt(
            SkillProficiency.stageFor(uses, n.skillProficiency).id) ??
        0.0;
    final profMult =
        SkillProficiency.combinedMult(uses, perSkillPct, n.skillProficiency);
    return calculateResolved(
      attackerInternalForce: ctx.attacker.internalForce,
      attackerEquipmentAttack: eqAtkSum,
      attackerCultivationLayer: ctx.attackerMainTech.cultivationLayer,
      attackerSchool: ctx.attackerMainTech.school,
      defenderSchool: ctx.defenderMainTech.school,
      attackerRealmTier: ctx.attacker.realmTier,
      attackerRealmLayer: ctx.attacker.realmLayer,
      defenderRealmTier: ctx.defender.realmTier,
      defenderRealmLayer: ctx.defender.realmLayer,
      defenderDefenseRate: defRate,
      defenderEvasionRate: CharacterDerivedStats.evasionRate(ctx.defender, n),
      attackerCriticalRate:
          CharacterDerivedStats.criticalRate(ctx.attacker, n),
      attackPowerMultiplier: 1.0,
      skill: ctx.skill,
      n: n,
      rng: ctx.rng ?? Random(),
      forceCritical: ctx.forceCritical,
      proficiencyDamageMult: profMult,
      outputMultiplier: 1.0, // Character 路径无余毒 debuff,固定 1.0
    );
  }

  /// **战斗伤害单一真相源**(§6 公式集中 · P2-c 双路径收敛 2026-05-29)。
  ///
  /// 全部入参已解析为 primitive,不依赖 Character / BattleCharacter / Equipment /
  /// Technique 实体 —— [calculate](Character 路径)与 [DefaultGroundStrategy]
  /// 的 `_calculateInBattle`(BattleCharacter 路径)都只做"字段解析 → 调本函数",
  /// 公式数学(闪避→base→修炼→克制→暴击→防御→境界差→震伤)**仅此一份**,
  /// 改一处即两路径同步,不再隐式 drift(原两份复制违 §6)。
  ///
  /// **两路径口径差异 = 显式参数**(由各自 adapter 决定,非公式内分叉):
  /// - 内力:[calculate] 传满 `internalForce` · 战斗传 `currentInternalForce`(战中扣)
  /// - 防御率:[calculate] 传 numbers.yaml 境界 base · 战斗传 `defenseRate` 缓存
  ///   (叠加相生 defensePct 注入)
  /// - [attackPowerMultiplier]:[calculate] 传 1.0 · 战斗传烘焙值(轻功 terrain /
  ///   群战 formation / 江湖恩怨,P3.1.B 起;default 1.0 无修饰)
  ///
  /// **rng 消费顺序**:先闪避 roll 后暴击 roll(与原两实现一致,保 seed 复现)。
  static AttackResult calculateResolved({
    required int attackerInternalForce,
    required int attackerEquipmentAttack,
    required CultivationLayer attackerCultivationLayer,
    required TechniqueSchool attackerSchool,
    required TechniqueSchool defenderSchool,
    required RealmTier attackerRealmTier,
    required RealmLayer attackerRealmLayer,
    required RealmTier defenderRealmTier,
    required RealmLayer defenderRealmLayer,
    required double defenderDefenseRate,
    required double defenderEvasionRate,
    required double attackerCriticalRate,
    required double attackPowerMultiplier,
    required SkillDef skill,
    required NumbersConfig n,
    required Random rng,
    bool forceCritical = false,
    double proficiencyDamageMult = 1.0,
    /// 凝甲词条(C1):暴击增量衰减系数。default 1.0 = 无凝甲(零回归)。
    /// 0.5 时 effectiveCritMult = 1 + (critMult-1)*0.5，仅影响暴击增量部分。
    double defenderCritDamageTakenMult = 1.0,
    /// M6 心魔余毒:战斗输出乘数(default 1.0=无余毒,零回归)。
    /// 末端乘 mainDamage，与 attackPowerMultiplier / proficiencyDamageMult 并列。
    /// 值由调用方从 BattleCharacter.outputMultiplier 传入，本函数不硬编码 0.95。
    double outputMultiplier = 1.0,
  }) {
    // === 1. 闪避 ===
    if (rng.nextDouble() < defenderEvasionRate) {
      return AttackResult.dodged(
        evasionRate: defenderEvasionRate,
        breakdown: 'DODGED (evasion=${_fmt(defenderEvasionRate)})',
      );
    }

    // === 2. 基础伤害 ===
    final df = n.combat.damageFormula;
    final base = attackerInternalForce * df.internalForceFactor +
        attackerEquipmentAttack * df.equipmentAttackFactor +
        skill.powerMultiplier;

    // === 3. 修炼度倍率 ===
    final cultMult = n.cultivationMultiplier[attackerCultivationLayer];
    if (cultMult == null) {
      throw StateError(
        'numbers.yaml techniques.cultivation.layers 缺 '
        '${attackerCultivationLayer.name} 的 bonus_multiplier',
      );
    }

    // === 4. 流派克制 ===
    final schoolMult =
        n.schoolCounter.multiplierFor(attackerSchool, defenderSchool);
    final extraEffect =
        n.schoolCounter.extraEffectFor(attackerSchool, defenderSchool);

    // === 5. 暴击 ===
    final isCritical = forceCritical || rng.nextDouble() < attackerCriticalRate;
    final critMult = isCritical
        ? (attackerSchool == TechniqueSchool.lingQiao
            ? n.combat.critical.lingqiaoDamageMultiplier
            : n.combat.critical.baseDamageMultiplier)
        : 1.0;
    // 凝甲词条(C1):守方携带 cycle_ningjia 时，暴击增量 × defenderCritDamageTakenMult。
    // 仅压缩暴击「加成部分」(critMult-1)，非暴击(critMult=1.0)时增量=0，乘 mult 无效。
    // default defenderCritDamageTakenMult=1.0 → effectiveCritMult=critMult（零回归）。
    final effectiveCritMult =
        isCritical ? (critMult - 1.0) * defenderCritDamageTakenMult + 1.0 : 1.0;

    // === 6. 防御率 ===
    final defMult = 1.0 - defenderDefenseRate;

    // === 7. 境界差修正 ===
    // RealmUtils.realmDiffModifier 返回 yaml 段原值 (attacker, defender)；
    // GDD §5.5：高打低用 attacker 放大；低打高用 defender 衰减；同境界 1.0。
    final atkLevel =
        RealmUtils.absoluteLevelOf(attackerRealmTier, attackerRealmLayer);
    final defLevel =
        RealmUtils.absoluteLevelOf(defenderRealmTier, defenderRealmLayer);
    final tierDiff = attackerRealmTier.index - defenderRealmTier.index;
    final mods =
        RealmUtils.realmDiffModifier(attackerRealmTier, defenderRealmTier);
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
    // 末端乘 attackPowerMultiplier(default 1.0):沿 cult/school/crit/def/realm
    // 体例,独立维度乘项不进 base 求和(P3.1.B 轻功/群战/恩怨烘焙)。
    // 凝甲:effectiveCritMult = 1+(critMult-1)*defenderCritDamageTakenMult
    //       default mult=1.0 → effectiveCritMult=critMult(零回归)。
    final raw = base *
        cultMult *
        schoolMult *
        effectiveCritMult *
        defMult *
        realmMult *
        attackPowerMultiplier *
        proficiencyDamageMult * // 可玩性 P1a:熟练度综合倍率(已含 130% cap)
        outputMultiplier; // M6 余毒:输出乘数(default 1.0=无余毒)
    final mainDamage = raw.toInt();

    // === 9. 刚猛克阴柔附带震伤(§12.1 #7 v1.4 决议)===
    // 主攻击命中且 attacker=gangMeng / defender=yinRou 时,追加固定 quake_dmg。
    // 穿透守方防御率 + 不被暴击乘(独立加值,不进 raw 乘式)。
    var quakeDamage = 0;
    if (attackerSchool == TechniqueSchool.gangMeng &&
        defenderSchool == TechniqueSchool.yinRou) {
      quakeDamage = n.schoolCounter.gangMengQuake.damage;
    }
    final finalDamage = mainDamage + quakeDamage;

    final effects = <String>[];
    if (extraEffect != null) effects.add(extraEffect);

    final breakdown = '($attackerInternalForce*${_fmt(df.internalForceFactor)}'
        ' + $attackerEquipmentAttack'
        ' + ${skill.powerMultiplier})'
        ' * ${_fmt(cultMult)}'
        ' * ${_fmt(schoolMult)}'
        ' * ${_fmt(effectiveCritMult)}'
        '${effectiveCritMult != critMult ? '(凝甲,原${_fmt(critMult)})' : ''}'
        ' * ${_fmt(defMult)}'
        ' * ${_fmt(realmMult)}'
        '${attackPowerMultiplier != 1.0 ? ' * ${_fmt(attackPowerMultiplier)}' : ''}'
        '${proficiencyDamageMult != 1.0 ? ' * ${_fmt(proficiencyDamageMult)}' : ''}'
        '${outputMultiplier != 1.0 ? ' * ${_fmt(outputMultiplier)}(余毒)' : ''}'
        ' = $mainDamage'
        '${quakeDamage > 0 ? ' + 震伤 $quakeDamage = $finalDamage' : ''}'
        ' [atkLv=$atkLevel,defLv=$defLevel]';

    return AttackResult(
      finalDamage: finalDamage,
      mainDamage: mainDamage,
      quakeDamage: quakeDamage,
      isCritical: isCritical,
      isDodged: false,
      schoolCounterMultiplier: schoolMult,
      realmDiffAttackerMod: realmAttackerMod,
      realmDiffDefenderMod: realmDefenderMod,
      cultivationMultiplier: cultMult,
      criticalMultiplier: critMult,
      defenseRate: defenderDefenseRate,
      evasionRate: defenderEvasionRate,
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
  /// 取整后的最终伤害(主伤害 + 震伤)。被闪避时为 0。
  final int finalDamage;

  /// 主攻击伤害(乘修炼度/克制/暴击/防御/境界差后取整,不含震伤)。
  /// CLAUDE.md §12.1 #7 v1.4 决议:震伤作为独立加值,与主伤害分离便于 log 展示。
  final int mainDamage;

  /// 刚猛克阴柔附带震伤(穿透防御不暴击)。中性/被克/其他流派分支为 0。
  final int quakeDamage;

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
    required this.mainDamage,
    required this.quakeDamage,
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
      mainDamage: 0,
      quakeDamage: 0,
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
