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

  /// 9 层修炼度对应的伤害倍率（numbers.yaml `techniques.cultivation.layers[].bonus_multiplier`，
  /// 1.00 ~ 3.00，GDD §4.3 / §5.4，T10 最终伤害公式用）。
  final Map<CultivationLayer, double> cultivationMultiplier;

  /// 3×3 流派克制矩阵（numbers.yaml `techniques.schools`，GDD §4.4 / §5.4，T10 用）。
  final SchoolCounterMatrix schoolCounter;

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
    required this.cultivationMultiplier,
    required this.schoolCounter,
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
      cultivationMultiplier: _parseCultivationMultiplier(
        techniques['cultivation'] as Map<String, dynamic>,
      ),
      schoolCounter: SchoolCounterMatrix.fromYaml(
        techniques['schools'] as Map<String, dynamic>,
      ),
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

  static Map<CultivationLayer, double> _parseCultivationMultiplier(
    Map<String, dynamic> cultivation,
  ) {
    final layers = cultivation['layers'] as List;
    final m = <CultivationLayer, double>{};
    for (final l in layers) {
      final layer = CultivationLayer.values.byName(l['layer'] as String);
      m[layer] = (l['bonus_multiplier'] as num).toDouble();
    }
    return m;
  }
}

/// 3×3 流派克制矩阵（numbers.yaml `techniques.schools`）。
///
/// 关系：刚猛 → 阴柔；阴柔 → 灵巧；灵巧 → 刚猛。
/// `multiplierFor(attacker, defender)`：
/// - attacker 克 defender → [counter]（1.25）
/// - attacker 被 defender 克 → [countered]（0.75）
/// - 同流派或非克制关系 → [neutral]（1.00）
///
/// **不要写嵌套 if-else**（phase1_tasks T10 §583）。本类用 attacker→target 单向
/// 查表 + `multiplierFor` 双向判断 + `extraEffectFor` 取克制特效字符串。
class SchoolCounterMatrix {
  /// `_counterTarget[A] == B` 表示 A 单向克制 B。
  final Map<TechniqueSchool, TechniqueSchool> _counterTarget;

  /// `_extraEffect[A]` 是 A 触发克制时附带的额外效果字符串（如 `extra_quake_dmg`）。
  final Map<TechniqueSchool, String> _extraEffect;

  /// 克制方伤害倍率（GDD §4.4，1.25）。
  final double counter;

  /// 被克制方伤害倍率（0.75）。
  final double countered;

  /// 中性 / 同流派伤害倍率（1.00）。
  final double neutral;

  const SchoolCounterMatrix({
    required Map<TechniqueSchool, TechniqueSchool> counterTarget,
    required Map<TechniqueSchool, String> extraEffect,
    required this.counter,
    required this.countered,
    required this.neutral,
  })  : _counterTarget = counterTarget,
        _extraEffect = extraEffect;

  factory SchoolCounterMatrix.fromYaml(Map<String, dynamic> y) {
    final relations = y['counter_relations'] as List;
    final tgt = <TechniqueSchool, TechniqueSchool>{};
    final eff = <TechniqueSchool, String>{};
    var counter = 0.0;
    for (final r in relations) {
      final atk = TechniqueSchool.values.byName(r['attacker'] as String);
      final t = TechniqueSchool.values.byName(r['target'] as String);
      tgt[atk] = t;
      eff[atk] = r['extra_effect'] as String;
      // 所有 counter_relations 的 damage_multiplier 一致，取最后一条即可
      counter = (r['damage_multiplier'] as num).toDouble();
    }
    return SchoolCounterMatrix(
      counterTarget: tgt,
      extraEffect: eff,
      counter: counter,
      countered: (y['countered_multiplier'] as num).toDouble(),
      neutral: (y['neutral_multiplier'] as num).toDouble(),
    );
  }

  /// attacker → defender 的伤害倍率。
  double multiplierFor(TechniqueSchool attacker, TechniqueSchool defender) {
    if (_counterTarget[attacker] == defender) return counter;
    if (_counterTarget[defender] == attacker) return countered;
    return neutral;
  }

  /// attacker 克制 defender 时的额外效果字符串；否则返回 null。
  String? extraEffectFor(TechniqueSchool attacker, TechniqueSchool defender) {
    if (_counterTarget[attacker] == defender) return _extraEffect[attacker];
    return null;
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
