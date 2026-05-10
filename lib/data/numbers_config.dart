import 'models/enums.dart';

/// 数值总配置（numbers.yaml 全量包装）。
///
/// Phase 1 仅强类型化战斗会用到的 [combat] 与 [levelDiffModifier]，
/// 其余段（equipment / techniques / skills / character / retreat / tower /
/// inheritance / synergies / validation_examples）保留 [raw] 原始 Map，
/// 后续阶段按需逐步强类型化（避免 Phase 1 写一堆用不上的胶水代码，
/// 见 phase1_tasks.md T07 §7.2）。
class NumbersConfig {
  final String version;
  final CombatNumbers combat;
  final LevelDiffModifier levelDiffModifier;

  /// 49 级境界对应大阶的防御率（RealmDef schema §5.8 未含此字段，
  /// 单独按 [RealmTier] 索引）。
  final Map<RealmTier, double> defenseRateByTier;

  /// 装备强化每级加成系数（numbers.yaml `equipment.enhancement.bonus_per_level`，
  /// GDD §6.2 = 0.05）。
  final double enhancementBonusPerLevel;

  /// 每阶心法的速度加成（numbers.yaml `techniques.tiers[].speed_bonus`，
  /// 仅主修生效，T09 用）。
  final Map<TechniqueTier, int> techniqueSpeedBonus;

  /// numbers.yaml 全量原始 map（已 deep-convert 为 `Map<String, dynamic>`）。
  /// 战斗、装备、闭关等模块强类型化前，先从这里取数。
  final Map<String, dynamic> raw;

  const NumbersConfig({
    required this.version,
    required this.combat,
    required this.levelDiffModifier,
    required this.defenseRateByTier,
    required this.enhancementBonusPerLevel,
    required this.techniqueSpeedBonus,
    required this.raw,
  });

  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
    final meta = y['meta'] as Map<String, dynamic>;
    final combat = y['combat'] as Map<String, dynamic>;
    final realms = y['realms'] as Map<String, dynamic>;
    final equipment = y['equipment'] as Map<String, dynamic>;
    final techniques = y['techniques'] as Map<String, dynamic>;

    return NumbersConfig(
      version: meta['version'] as String,
      combat: CombatNumbers.fromYaml(combat),
      levelDiffModifier: LevelDiffModifier.fromYaml(
        realms['level_diff_modifier'] as Map<String, dynamic>,
      ),
      defenseRateByTier: _parseDefenseRates(realms['tiers'] as List),
      enhancementBonusPerLevel: ((equipment['enhancement']
              as Map<String, dynamic>)['bonus_per_level'] as num)
          .toDouble(),
      techniqueSpeedBonus:
          _parseTechniqueSpeedBonus(techniques['tiers'] as List),
      raw: y,
    );
  }

  static Map<RealmTier, double> _parseDefenseRates(List tiers) {
    final m = <RealmTier, double>{};
    for (final t in tiers) {
      final tier = RealmTier.values.byName(t['tier'] as String);
      m[tier] = (t['defense_rate'] as num).toDouble();
    }
    return m;
  }

  static Map<TechniqueTier, int> _parseTechniqueSpeedBonus(List tiers) {
    final m = <TechniqueTier, int>{};
    for (final t in tiers) {
      final tier = TechniqueTier.values.byName(t['tier'] as String);
      m[tier] = (t['speed_bonus'] as num).toInt();
    }
    return m;
  }
}

/// 战斗段强类型（numbers.yaml `combat`）。
class CombatNumbers {
  final DamageFormula damageFormula;
  final MaxHpFormula maxHpFormula;
  final SpeedFormula speedFormula;
  final CriticalConfig critical;
  final EvasionConfig evasion;

  const CombatNumbers({
    required this.damageFormula,
    required this.maxHpFormula,
    required this.speedFormula,
    required this.critical,
    required this.evasion,
  });

  factory CombatNumbers.fromYaml(Map<String, dynamic> y) {
    return CombatNumbers(
      damageFormula: DamageFormula.fromYaml(
        y['damage_formula'] as Map<String, dynamic>,
      ),
      maxHpFormula: MaxHpFormula.fromYaml(
        y['max_hp_formula'] as Map<String, dynamic>,
      ),
      speedFormula: SpeedFormula.fromYaml(
        y['speed_formula'] as Map<String, dynamic>,
      ),
      critical: CriticalConfig.fromYaml(
        y['critical'] as Map<String, dynamic>,
      ),
      evasion: EvasionConfig.fromYaml(
        y['evasion'] as Map<String, dynamic>,
      ),
    );
  }
}

/// 基础伤害公式系数（GDD §5.3，平衡后 `equipment_attack_factor=1.0` /
/// `internal_force_factor=0.4`）。
class DamageFormula {
  final double internalForceFactor;
  final double equipmentAttackFactor;

  const DamageFormula({
    required this.internalForceFactor,
    required this.equipmentAttackFactor,
  });

  factory DamageFormula.fromYaml(Map<String, dynamic> y) {
    return DamageFormula(
      internalForceFactor: (y['internal_force_factor'] as num).toDouble(),
      equipmentAttackFactor: (y['equipment_attack_factor'] as num).toDouble(),
    );
  }
}

/// 最大血量公式系数（GDD §5.6，平衡后 `internal_force_factor=0.7` /
/// `constitution_factor=500`）。
class MaxHpFormula {
  final int base;
  final double internalForceFactor;
  final int constitutionFactor;

  const MaxHpFormula({
    required this.base,
    required this.internalForceFactor,
    required this.constitutionFactor,
  });

  factory MaxHpFormula.fromYaml(Map<String, dynamic> y) {
    return MaxHpFormula(
      base: (y['base'] as num).toInt(),
      internalForceFactor: (y['internal_force_factor'] as num).toDouble(),
      constitutionFactor: (y['constitution_factor'] as num).toInt(),
    );
  }
}

/// 出手速度公式（GDD §5.6 原值）。
class SpeedFormula {
  final int base;
  final int agilityFactor;

  const SpeedFormula({
    required this.base,
    required this.agilityFactor,
  });

  factory SpeedFormula.fromYaml(Map<String, dynamic> y) {
    return SpeedFormula(
      base: (y['base'] as num).toInt(),
      agilityFactor: (y['agility_factor'] as num).toInt(),
    );
  }
}

/// 暴击率与暴击伤害（GDD §4.4 / §5.4）。
class CriticalConfig {
  final double baseRate;
  final double agilityPerPointRate;
  final double maxRate;
  final double baseDamageMultiplier;
  final double maxDamageMultiplier;

  const CriticalConfig({
    required this.baseRate,
    required this.agilityPerPointRate,
    required this.maxRate,
    required this.baseDamageMultiplier,
    required this.maxDamageMultiplier,
  });

  factory CriticalConfig.fromYaml(Map<String, dynamic> y) {
    return CriticalConfig(
      baseRate: (y['base_rate'] as num).toDouble(),
      agilityPerPointRate: (y['agility_per_point_rate'] as num).toDouble(),
      maxRate: (y['max_rate'] as num).toDouble(),
      baseDamageMultiplier: (y['base_damage_multiplier'] as num).toDouble(),
      maxDamageMultiplier: (y['max_damage_multiplier'] as num).toDouble(),
    );
  }
}

/// 闪避率（GDD §5.6）。
class EvasionConfig {
  final double agilityPerPointRate;
  final double maxRate;

  const EvasionConfig({
    required this.agilityPerPointRate,
    required this.maxRate,
  });

  factory EvasionConfig.fromYaml(Map<String, dynamic> y) {
    return EvasionConfig(
      agilityPerPointRate: (y['agility_per_point_rate'] as num).toDouble(),
      maxRate: (y['max_rate'] as num).toDouble(),
    );
  }
}

/// 境界差距修正（GDD §5.5，强制规则）。
///
/// `diff3OrMore.attacker` 在 yaml 里是 `null`（"已碾压无需放大"），
/// 此处按 phase1_tasks T07 提示默认取 [diff2.attacker] 作为兜底（≈2.5）。
class LevelDiffModifier {
  final TierMod sameTier;
  final TierMod diff1;
  final TierMod diff2;
  final TierMod diff3OrMore;

  const LevelDiffModifier({
    required this.sameTier,
    required this.diff1,
    required this.diff2,
    required this.diff3OrMore,
  });

  factory LevelDiffModifier.fromYaml(Map<String, dynamic> y) {
    final diff2 =
        TierMod.fromYaml(y['diff_2_tier'] as Map<String, dynamic>);
    final raw3 = y['diff_3_or_more'] as Map<String, dynamic>;
    return LevelDiffModifier(
      sameTier: TierMod.fromYaml(y['same_tier'] as Map<String, dynamic>),
      diff1: TierMod.fromYaml(y['diff_1_tier'] as Map<String, dynamic>),
      diff2: diff2,
      diff3OrMore: TierMod(
        attacker: (raw3['attacker'] as num?)?.toDouble() ?? diff2.attacker,
        defender: (raw3['defender'] as num).toDouble(),
      ),
    );
  }
}

/// 单条境界差修正（攻 / 守两个系数）。
class TierMod {
  final double attacker;
  final double defender;

  const TierMod({required this.attacker, required this.defender});

  factory TierMod.fromYaml(Map<String, dynamic> y) {
    return TierMod(
      attacker: (y['attacker'] as num).toDouble(),
      defender: (y['defender'] as num).toDouble(),
    );
  }
}
