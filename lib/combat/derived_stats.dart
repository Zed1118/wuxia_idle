import '../data/game_repository.dart';
import '../data/models/character.dart';
import '../data/models/enums.dart';
import '../data/models/equipment.dart';
import '../data/models/technique.dart';
import '../data/numbers_config.dart';

/// 境界派生工具（phase1_tasks.md T08）。
///
/// 所有方法纯函数，从 [GameRepository.instance] 读 49 行 RealmDef 表与
/// numbers.yaml 的 `levelDiffModifier`，**不硬编码任何数值**。
///
/// **差 3+ 阶 attacker 修正的公式语义**：
/// numbers.yaml `diff_3_or_more.attacker: null`，T07 NumbersConfig 把它兜底
/// 为 `diff2.attacker`(=2.5) 仅为数据层字段非空保证；公式层按 GDD §5.5 +
/// phase1_tasks T08 §470 取 `1.0`（"已经被碾压无须放大"），不读这个字段。
class RealmUtils {
  RealmUtils._();

  /// absoluteLevel（1-49），从 RealmDef 表查。
  static int absoluteLevelOf(RealmTier tier, RealmLayer layer) {
    return GameRepository.instance.getRealm(tier, layer).absoluteLevel;
  }

  /// 给定攻方/守方大境界，返回 `(attacker, defender)` 修正系数。
  ///
  /// 取 `|attackerTier.index - defenderTier.index|` 查 numbers.yaml
  /// `level_diff_modifier`：
  /// - 0：(1.0, 1.0)
  /// - 1：(1.4, 0.7)
  /// - 2：(2.5, 0.3)
  /// - 3+：(1.0, 0.05)
  ///
  /// 上层根据攻方境界高于/低于守方决定用 attacker 还是 defender 系数
  /// （GDD §5.5：高打低用 attacker 放大；低打高用 defender 衰减）。
  static (double attacker, double defender) realmDiffModifier(
    RealmTier attackerTier,
    RealmTier defenderTier,
  ) {
    final mod = GameRepository.instance.numbers.levelDiffModifier;
    final absDiff = (attackerTier.index - defenderTier.index).abs();
    final tm = switch (absDiff) {
      0 => mod.sameTier,
      1 => mod.diff1,
      2 => mod.diff2,
      _ => null,
    };
    if (tm != null) return (tm.attacker, tm.defender);
    return (1.0, mod.diff3OrMore.defender);
  }

  /// 该层境界的内力上限（RealmDef.internalForceMax）。
  static int internalForceMaxOf(RealmTier tier, RealmLayer layer) {
    return GameRepository.instance.getRealm(tier, layer).internalForceMax;
  }

  /// 该大境界的基础防御率（同大境界 7 层共用，从 numbers.yaml 取）。
  static double defenseRateOf(RealmTier tier) {
    final r = GameRepository.instance.numbers.defenseRateByTier[tier];
    if (r == null) {
      throw StateError('numbers.yaml defenseRateByTier 缺 ${tier.name}');
    }
    return r;
  }

  /// 该大境界对应的可装备品阶上限（GDD §5.3 三系锁死）。
  ///
  /// 同大境界 7 层共用同一 `equipmentTierCap`，取 tier 下任一 RealmDef 即可。
  static EquipmentTier equipmentTierCapOf(RealmTier tier) {
    final r = GameRepository.instance.realms
        .firstWhere((r) => r.tier == tier,
            orElse: () =>
                throw StateError('未找到境界 ${tier.name} 的 RealmDef'));
    return r.equipmentTierCap;
  }

  /// 强化等级上限 = absoluteLevel（GDD §6.2，最高 49）。
  static int maxEnhanceLevelOf(Character c) {
    return absoluteLevelOf(c.realmTier, c.realmLayer);
  }
}

/// 角色派生属性（phase1_tasks.md T09）。
///
/// 全部公式从 [NumbersConfig] 读系数，**不硬编码 0.4 / 0.7 / 0.05 等魔数**。
/// 装备/心法的"开锋系数 + 强化倍率 + 共鸣倍率"按乘法连乘（phase1_tasks T09 §515）。
class CharacterDerivedStats {
  CharacterDerivedStats._();

  /// 最大血量 = base + 内力*ifFactor + 根骨*conFactor + Σ装备血量(应用强化/共鸣)。
  /// 系数全部来自 numbers.yaml `combat.max_hp_formula`。
  static int maxHp(
    Character c,
    List<Equipment> equipped,
    NumbersConfig n,
  ) {
    final f = n.combat.maxHpFormula;
    var hp = f.base.toDouble();
    hp += c.internalForce * f.internalForceFactor;
    hp += c.attributes.constitution * f.constitutionFactor;
    for (final eq in equipped) {
      hp += effectiveEquipmentHp(eq, n);
    }
    return hp.toInt();
  }

  /// 出手速度 = base + 身法*agFactor + Σ装备速度 + 主修心法 speed_bonus。
  /// 辅修不计速度（phase1_tasks T09 §512）。
  static int speed(
    Character c,
    List<Equipment> equipped,
    Technique mainTech,
    NumbersConfig n,
  ) {
    final f = n.combat.speedFormula;
    var sp = f.base.toDouble();
    sp += c.attributes.agility * f.agilityFactor;
    for (final eq in equipped) {
      sp += effectiveEquipmentSpeed(eq, n);
    }
    final bonus = n.techniqueSpeedBonus[mainTech.tier];
    if (bonus == null) {
      throw StateError(
        'numbers.yaml techniques.tiers 缺 ${mainTech.tier.name} 的 speed_bonus',
      );
    }
    sp += bonus;
    return sp.toInt();
  }

  /// 暴击率 = baseRate + 身法*perPointRate（再加灵巧流派 +20% bonus），
  /// **最后**统一 clamp 到 [0, maxRate]（phase1_tasks T09 §514）。
  ///
  /// `school` 取自角色当前主修流派（[Character.school]，可空：无主修时按基础算）。
  static double criticalRate(Character c, NumbersConfig n) {
    final cfg = n.combat.critical;
    var rate = cfg.baseRate + c.attributes.agility * cfg.agilityPerPointRate;
    if (c.school == TechniqueSchool.lingQiao) {
      rate += _lingQiaoCriticalBonus;
    }
    return rate.clamp(0.0, cfg.maxRate);
  }

  /// 闪避率 = 身法*perPointRate，clamp 到 [0, maxRate]。
  static double evasionRate(Character c, NumbersConfig n) {
    final cfg = n.combat.evasion;
    final rate = c.attributes.agility * cfg.agilityPerPointRate;
    return rate.clamp(0.0, cfg.maxRate);
  }

  /// 装备攻击 = baseAttack × (1 + enhanceLevel × bonusPerLevel)
  ///         × resonanceBonus × (1 + Σattack 开锋槽位百分比 / 100)
  /// **乘法连乘**，phase1_tasks T09 §515 钉死。
  /// 寻常货 +0 共鸣生疏无开锋时返回 baseAttack（验收 §508）。
  static int effectiveEquipmentAttack(Equipment eq, NumbersConfig n) {
    final enhance = 1 + eq.enhanceLevel * n.enhancementBonusPerLevel;
    final resonance = eq.resonanceBonus;
    final forgePct = _forgingBonusPct(eq, ForgingSlotType.attack);
    return (eq.baseAttack * enhance * resonance * (1 + forgePct)).toInt();
  }

  /// 装备血量同样应用强化倍率 + 共鸣倍率（phase1_tasks T09 §513）。
  /// 血量没有"开锋槽位加成"类型（forging.slots 中无 `hp` 类型）。
  static int effectiveEquipmentHp(Equipment eq, NumbersConfig n) {
    final enhance = 1 + eq.enhanceLevel * n.enhancementBonusPerLevel;
    final resonance = eq.resonanceBonus;
    return (eq.baseHealth * enhance * resonance).toInt();
  }

  /// 装备速度 = baseSpeed × 强化 × 共鸣 × (1 + Σspeed 开锋槽位百分比 / 100)。
  static int effectiveEquipmentSpeed(Equipment eq, NumbersConfig n) {
    final enhance = 1 + eq.enhanceLevel * n.enhancementBonusPerLevel;
    final resonance = eq.resonanceBonus;
    final forgePct = _forgingBonusPct(eq, ForgingSlotType.speed);
    return (eq.baseSpeed * enhance * resonance * (1 + forgePct)).toInt();
  }

  /// 灵巧流派暴击率额外 +20%（GDD §4.4）。这是"流派"级语义系数，
  /// 不在 numbers.yaml `combat.critical` 段——独立写在此处。
  static const double _lingQiaoCriticalBonus = 0.20;

  /// 累加指定 [type] 的开锋槽位 bonusValue（百分比，如 15 表示 +15%），返回小数（0.15）。
  /// 仅 `unlocked == true` 的槽位计入。
  static double _forgingBonusPct(Equipment eq, ForgingSlotType type) {
    var sum = 0;
    for (final s in eq.forgingSlots) {
      if (s.unlocked && s.type == type) sum += s.bonusValue;
    }
    return sum / 100.0;
  }
}
