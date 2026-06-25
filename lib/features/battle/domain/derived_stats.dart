import '../../../data/game_repository.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/technique.dart';
import '../../../data/numbers_config.dart';

/// 境界派生工具（phase1_tasks.md T08）。
///
/// 所有方法纯函数，从 [GameRepository.instance] 读 49 行 RealmDef 表与
/// numbers.yaml 的 `levelDiffModifier`，**不硬编码任何数值**。
///
/// **差 3+ 阶 attacker 修正**：numbers.yaml `diff_3_or_more.attacker: null`，
/// 数据层 [LevelDiffModifier.fromYaml] 兜底为 `1.0`（GDD §5.5「已碾压无须放大」），
/// 公式层直接走数据层 [LevelDiffModifier.diff3OrMore]，**不再硬编码 1.0**。
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
      _ => mod.diff3OrMore,
    };
    return (tm.attacker, tm.defender);
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

  /// 该大境界对应的可修炼心法品阶上限（GDD §5.3 三系锁死）。
  ///
  /// 与 [equipmentTierCapOf] 同源（RealmDef 同时持有装备 / 心法两个 cap），
  /// 同大境界 7 层共用同一 `techniqueTierCap`。
  static TechniqueTier techniqueTierCapOf(RealmTier tier) {
    final r = GameRepository.instance.realms
        .firstWhere((r) => r.tier == tier,
            orElse: () =>
                throw StateError('未找到境界 ${tier.name} 的 RealmDef'));
    return r.techniqueTierCap;
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
  ///
  /// **P1.1 A1 E.5**:可选 `founderBuffActive=true` 时叠加 `founder_ancestor_buff.max_hp_pct`
  /// (apply_to_disciples_only=false 时 founder 自身也享)。caller 端按 active 状态注入。
  static int maxHp(
    Character c,
    List<Equipment> equipped,
    NumbersConfig n, {
    bool founderBuffActive = false,
  }) {
    final f = n.combat.maxHpFormula;
    var hp = f.base.toDouble();
    hp += c.internalForce * f.internalForceFactor;
    hp += c.attributes.constitution * f.constitutionFactor;
    for (final eq in equipped) {
      hp += effectiveEquipmentHp(eq, n);
    }
    if (founderBuffActive &&
        _founderBuffAppliesTo(c, n.founderAncestorBuff)) {
      hp *= (1.0 + n.founderAncestorBuff.maxHpPct);
    }
    // 第八阶段·角色等级 Lv:平直加成 (level-1)×per_level(level 1 = 0,新角色不白给),
    // 不被 founder/相生乘子缩放;加在 clamp 前 → §5.4 血量红线硬守(满 Lv 极值靠 clamp 兜底)。
    hp += (c.level - 1) * n.level.bonusMaxHpPerLevel;
    // §5.4 血量红线 clamp(单一真相源 numbers.yaml combat.red_lines,与
    // stage_battle_setup / inner_demon_def 同源):founder buff(玩家自享 +5%)/
    // 心法相生 hpPct(+0.20)乘法可把血量推过红线,battle_state 直接调本方法塞进
    // 战斗,源头 clamp 守红线(P1-b 同源 · review 补 · 2026-05-29 消 hardcode)。
    return hp.clamp(0, n.combat.redLines.playerHpMax).toInt();
  }

  /// 判定祖师爷 buff 是否作用于角色 [c](P1.1 A1 E.5)。
  /// `apply_to_disciples_only=true` 时仅 disciple 享受;false 时全 active 享。
  static bool _founderBuffAppliesTo(Character c, FounderAncestorBuff buff) {
    if (!buff.isActive) return false;
    if (buff.applyToDisciplesOnly && c.isFounder) return false;
    return true;
  }

  /// 出手速度 = base + 身法*agFactor + Σ装备速度 + 主修心法 speed_bonus。
  /// 辅修不计速度（phase1_tasks T09 §512）。
  ///
  /// **第八阶段·轻伤 debuff**：可选 `lightInjuryStacks`（默认 0），末端
  /// 扣减 `stacks × lightSpeedPenaltyPerStack`，clamp 到 0 防负数。
  static int speed(
    Character c,
    List<Equipment> equipped,
    Technique mainTech,
    NumbersConfig n, {
    int lightInjuryStacks = 0,
  }) {
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
    // 第八阶段·角色等级 Lv:平直加成 (level-1)×per_level(速度无红线)。
    sp += (c.level - 1) * n.level.bonusSpeedPerLevel;
    // 轻伤减速：末端扣减，clamp 到 0。
    if (lightInjuryStacks > 0) {
      sp -= lightInjuryStacks * n.injury.lightSpeedPenaltyPerStack;
      if (sp < 0) sp = 0;
    }
    return sp.toInt();
  }

  /// 暴击率 = baseRate + 身法*perPointRate（再加灵巧流派 +20% bonus），
  /// **最后**统一 clamp 到 [0, maxRate]（phase1_tasks T09 §514）。
  ///
  /// `school` 取自角色当前主修流派（[Character.school]，可空：无主修时按基础算）。
  /// 灵巧 +0.20 来自 yaml `combat.critical.lingqiao_critical_bonus`，不硬编码。
  ///
  /// **P1.1 A1 E.5**:可选 `founderBuffActive=true` 时叠加 `crit_rate_bonus`(绝对值
  /// 直接加,clamp 前)。jingong 流派 + buff 同时存在时累加叠加,clamp 兜底防破 maxRate。
  static double criticalRate(
    Character c,
    NumbersConfig n, {
    bool founderBuffActive = false,
  }) {
    final cfg = n.combat.critical;
    var rate = cfg.baseRate + c.attributes.agility * cfg.agilityPerPointRate;
    if (c.school == TechniqueSchool.lingQiao) {
      rate += cfg.lingqiaoCriticalBonus;
    }
    if (founderBuffActive &&
        _founderBuffAppliesTo(c, n.founderAncestorBuff)) {
      rate += n.founderAncestorBuff.critRateBonus;
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
    final resonance = eq.resonanceBonus(n);
    final forgePct = _forgingBonusPct(eq, ForgingSlotType.attack);
    return (eq.baseAttack * enhance * resonance * (1 + forgePct)).toInt();
  }

  /// 装备血量同样应用强化倍率 + 共鸣倍率（phase1_tasks T09 §513）。
  /// 血量没有"开锋槽位加成"类型（forging.slots 中无 `hp` 类型）。
  static int effectiveEquipmentHp(Equipment eq, NumbersConfig n) {
    final enhance = 1 + eq.enhanceLevel * n.enhancementBonusPerLevel;
    final resonance = eq.resonanceBonus(n);
    return (eq.baseHealth * enhance * resonance).toInt();
  }

  /// 装备速度 = baseSpeed × 强化 × 共鸣 × (1 + Σspeed 开锋槽位百分比 / 100)。
  static int effectiveEquipmentSpeed(Equipment eq, NumbersConfig n) {
    final enhance = 1 + eq.enhanceLevel * n.enhancementBonusPerLevel;
    final resonance = eq.resonanceBonus(n);
    final forgePct = _forgingBonusPct(eq, ForgingSlotType.speed);
    return (eq.baseSpeed * enhance * resonance * (1 + forgePct)).toInt();
  }

  /// 累加指定 [type] 的开锋槽位 bonusValue（百分比，如 15 表示 +15%），返回小数（0.15）。
  /// 仅 `unlocked == true` 的槽位计入。
  static double _forgingBonusPct(Equipment eq, ForgingSlotType type) {
    var sum = 0;
    for (final s in eq.forgingSlots) {
      if (s.unlocked && s.type == type) sum += s.bonusValue;
    }
    return sum / 100.0;
  }

  /// 跨**全身装备**累加指定 [type] 的开锋槽位 bonusValue（百分比小数，15→0.15）。
  /// 区别于单件 [_forgingBonusPct]：pierce/lifesteal 是攻方整体战斗属性
  /// （穿透/回血），非单件攻速加成，故全装备求和。仅 `unlocked` 槽计入。
  static double forgingAggregatePct(
      List<Equipment> equipped, ForgingSlotType type) {
    var sum = 0;
    for (final eq in equipped) {
      for (final s in eq.forgingSlots) {
        if (s.unlocked && s.type == type) sum += s.bonusValue;
      }
    }
    return sum / 100.0;
  }

  /// 内力上限（含师承遗物 +5% 叠加，phase2_tasks T22 / GDD §6.1）。
  ///
  /// `Character.internalForceMax` 是基础值（由境界 / 心法 / 修为决定，调用方
  /// 已算好）。本方法在其上叠加每件 [Equipment.isLineageHeritage] 装备的
  /// `lineageInternalForceMaxBonus`（默认 0.05 / 件，独立叠加）。
  ///
  /// 例：基础 10000 + 4 件师承遗物 → 10000 × 1.20 = 12000。
  ///
  /// **P1.1 A1 E.5**:可选 `founderBuffActive=true` 时叠加
  /// `founder_ancestor_buff.internal_force_max_pct`(继师承叠加后再乘)。
  /// caller 端按 active 状态注入。
  static int internalForceMaxWithLineage(
    Character c,
    List<Equipment> equipped,
    NumbersConfig n, {
    bool founderBuffActive = false,
    bool heavyInjured = false,
  }) {
    final heritageCount =
        equipped.where((e) => e.isLineageHeritage).length;
    var mult = 1.0 + heritageCount * n.lineageInternalForceMaxBonus;
    if (founderBuffActive &&
        _founderBuffAppliesTo(c, n.founderAncestorBuff)) {
      mult *= (1.0 + n.founderAncestorBuff.internalForceMaxPct);
    }
    // 第八阶段·重伤 debuff：内力上限乘 (1 - penalty_pct)，在 clamp 之前注入。
    if (heavyInjured) {
      mult *= (1.0 - n.injury.heavyInternalForceMaxPenaltyPct);
    }
    // §5.4 内力红线 clamp(单一真相源 numbers.yaml combat.red_lines,与
    // stage_battle_setup / game_repository 同源):battle_state 直接调本方法塞进
    // 战斗,不经 stage_battle_setup 的 modifier clamp;founder buff(玩家自享 +5%)+
    // 师承遗物(+5%/件)乘法可把上限推过红线(实测 4 件 +founder = 18900),源头
    // clamp 守红线(P1-b · review 补 · 2026-05-29 消 hardcode)。
    // 第八阶段·角色等级 Lv:平直加成 (level-1)×per_level,不被 mult 缩放;
    // 加在 clamp 前 → §5.4 内力红线硬守(满 Lv 极值靠 clamp 兜底)。
    final levelBonus = (c.level - 1) * n.level.bonusInternalForceMaxPerLevel;
    return (c.internalForceMax * mult + levelBonus)
        .clamp(0, n.combat.redLines.internalForceMax)
        .toInt();
  }
}
