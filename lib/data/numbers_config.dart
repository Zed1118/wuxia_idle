import '../features/inner_demon/domain/inner_demon_def.dart';
import '../features/light_foot/domain/light_foot_def.dart';
import '../features/mass_battle/domain/mass_battle_def.dart';
import '../features/seclusion/domain/seclusion_map_def.dart';
import '../core/domain/enums.dart';

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

  /// 强化系统配置（numbers.yaml `equipment.enhancement` + `equipment.xinxue_jiejing`，
  /// T20 用）。
  final EnhancementConfig enhancement;

  /// 开锋系统配置（numbers.yaml `equipment.forging`，T21 用）。
  final ForgingConfig forging;

  /// 每阶心法的速度加成（numbers.yaml `techniques.tiers[].speed_bonus`，
  /// 仅主修生效，T09 用）。
  final Map<TechniqueTier, int> techniqueSpeedBonus;

  /// 9 层修炼度对应的伤害倍率（numbers.yaml `techniques.cultivation.layers[].bonus_multiplier`，
  /// 1.00 ~ 3.00，GDD §4.3 / §5.4，T10 最终伤害公式用）。
  final Map<CultivationLayer, double> cultivationMultiplier;

  /// 修炼度升下一层所需的招式使用次数（numbers.yaml
  /// `techniques.cultivation.progress_to_next[].progress_required`，phase2_tasks T24 用）。
  ///
  /// key = from_layer（当前层），value = 升下一层所需 progress。
  /// **仅 8 个 entry**（jiJing 是 9 层中最高层，没有下一层；查询时需先判 layer != jiJing）。
  final Map<CultivationLayer, int> cultivationProgressToNext;

  /// 3×3 流派克制矩阵（numbers.yaml `techniques.schools`，GDD §4.4 / §5.4，T10 用）。
  final SchoolCounterMatrix schoolCounter;

  /// 4 段共鸣度配置（numbers.yaml `equipment.resonance.stages`，GDD §6.4）。
  /// 顺序：生疏 → 趁手 → 默契 → 心剑通灵；最后一段 [maxBattleCount] 为 null（无上限）。
  final List<ResonanceStageConfig> resonanceStages;

  /// 师承遗物的共鸣度保留比例（numbers.yaml `equipment.resonance.inheritance_retention`，
  /// GDD §6.4 = 0.7）。
  final double resonanceInheritanceRetention;

  /// 师承遗物的内力上限加成（numbers.yaml `equipment.lineage_heritage.internal_force_max_bonus`，
  /// GDD §6.1 = 0.05）。
  /// Phase 2 决议：每件 isLineageHeritage=true 装备**独立叠加** +5%（§12 #10 待 Pen
  /// 拍板，本阶段按"独立叠加"实现）。T22 用。
  final double lineageInternalForceMaxBonus;

  /// 祖师爷 buff(P1.1 A1 E.5,GDD §7.1)。
  /// numbers.yaml `inheritance.founder_ancestor_buff`,P1.1 阶段决议方案 E.5.A:
  /// `enabled_when_alive: true` + 玩家本人=祖师身份,自带 sect_wide_buff 给 active
  /// 全员(`apply_to_disciples_only: false`)。Phase 5+ 飞升机制实装时,trigger
  /// 条件扩展(eg. founder.realm >= wuSheng)。
  final FounderAncestorBuff founderAncestorBuff;

  /// 散功代价：原主修心法修炼度保留比例（numbers.yaml `techniques.dispersion.cultivation_penalty`，
  /// GDD §4.3 = 0.5）。
  final double dispersionCultivationPenalty;

  /// 散功代价：当前内力扣减比例（numbers.yaml `techniques.dispersion.internal_force_penalty`，
  /// GDD §4.3 = 0.5，phase2_tasks T25 用）。
  /// 散功后 ch.internalForce = (internalForce * (1 - 此值)).toInt()。
  final double dispersionInternalForcePenalty;

  /// 战败代价：Boss 关战败时角色当前内力扣减比例（numbers.yaml
  /// `techniques.defeat.boss_internal_force_penalty`，Phase 4 W10 = 0.5）。
  /// 战败后 ch.internalForce = (internalForce * (1 - 此值)).toInt()。
  /// 仅 stages.yaml isBossStage=true 的关卡战败时由 DispelService.applyDefeatPenalty 消费。
  final double defeatBossInternalForcePenalty;

  /// 战败代价：Boss 关战败时主修 progress 扣减比例（numbers.yaml
  /// `techniques.defeat.boss_cultivation_penalty`，Phase 4 W10 = 0.5）。
  /// 战败后 mainTech.cultivationProgress = (progress * (1 - 此值)).toInt()，
  /// 再走 layer 反向重算（算法 A，与 DispelService.dispel 一致）。
  final double defeatBossCultivationPenalty;

  /// 心法学习成本（numbers.yaml `techniques.learning_cost`，phase2_tasks T23）。
  /// Demo 阶段固定值：辅修 100 / 主修 500 领悟点。
  final LearningCostConfig learningCost;

  /// 动画时序配置（numbers.yaml `animation`，T15）。
  final AnimationNumbers animation;

  /// 闭关地图配置（numbers.yaml `retreat`，Phase 3 T47）。
  final RetreatConfig retreat;

  /// 农历节日配置（numbers.yaml `festivals`，W16 GDD §12.4 接口预留）。
  ///
  /// 不影响数值红线（GDD §12.4 明文「节日活动：不影响数值」）。仅用于
  /// encounter trigger 维度 + UI「今日节日」chip 显示。fixture 不带
  /// `festivals` 段时 [FestivalConfig.empty]。
  final FestivalConfig festivals;

  /// 心魔系统配置（numbers.yaml `inner_demon`，1.0 P2.2 §12.1）。
  ///
  /// 7 关镜像玩家 character +10-20% 强化 + §5.4 cap + 散功 ×0.5 阉割版失败惩罚。
  /// fixture 不带 `inner_demon` 段时走 [InnerDemonDef.empty]（unlockTriggers/
  /// requiredRealmLayer 均空 → isLayerLocked 始终 false，不破现有升层行为）。
  final InnerDemonDef innerDemon;

  /// 轻功对决配置(1.0 P3.1 §12.3,GDD v1.11)。
  ///
  /// 5 关 stage_light_foot_01..05 跨 yiLiu/jueDing 2 Tier × 3 terrain
  /// (water/rooftop/bamboo)平行支线。fixture 不带 `light_foot` 段时走
  /// [LightFootDef.empty](terrain_modifiers 空 → LightFootStrategy fallback
  /// neutral modifier 不影响 BattleCharacter stat)。
  final LightFootDef lightFoot;

  /// 群战守城配置(1.0 P3.2 §12.3,GDD v1.13)。
  ///
  /// 5 关 stage_mass_battle_01..05 跨 yiLiu/jueDing 2 Tier 平行支线 ·
  /// wave-based 守城(wave_count 1-4 · enemy_counts 5-7 玩家 3 vs 敌「以少胜多」)·
  /// 战前阵型 3 选 1(yanXing/baGua/fengShi)烘焙 leftTeam stat。fixture 不带
  /// `mass_battle` 段时走 [MassBattleDef.empty](formations 空 →
  /// MassBattleStrategy fallback neutral modifier 不影响 BattleCharacter stat)。
  final MassBattleDef massBattle;

  /// numbers.yaml 全量原始 map（已 deep-convert 为 `Map<String, dynamic>`）。
  /// 战斗、装备、闭关等模块强类型化前，先从这里取数。
  final Map<String, dynamic> raw;

  const NumbersConfig({
    required this.version,
    required this.combat,
    required this.levelDiffModifier,
    required this.defenseRateByTier,
    required this.enhancementBonusPerLevel,
    required this.enhancement,
    required this.forging,
    required this.techniqueSpeedBonus,
    required this.cultivationMultiplier,
    required this.cultivationProgressToNext,
    required this.schoolCounter,
    required this.resonanceStages,
    required this.resonanceInheritanceRetention,
    required this.lineageInternalForceMaxBonus,
    required this.founderAncestorBuff,
    required this.dispersionCultivationPenalty,
    required this.dispersionInternalForcePenalty,
    required this.defeatBossInternalForcePenalty,
    required this.defeatBossCultivationPenalty,
    required this.learningCost,
    required this.animation,
    required this.retreat,
    required this.festivals,
    required this.innerDemon,
    required this.lightFoot,
    required this.massBattle,
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
      enhancement: EnhancementConfig.fromYaml(
        enhancement: equipment['enhancement'] as Map<String, dynamic>,
        xinxueJiejing: equipment['xinxue_jiejing'] as Map<String, dynamic>,
      ),
      forging: ForgingConfig.fromYaml(
        equipment['forging'] as Map<String, dynamic>,
      ),
      techniqueSpeedBonus:
          _parseTechniqueSpeedBonus(techniques['tiers'] as List),
      cultivationMultiplier: _parseCultivationMultiplier(
        techniques['cultivation'] as Map<String, dynamic>,
      ),
      cultivationProgressToNext: _parseCultivationProgressToNext(
        techniques['cultivation'] as Map<String, dynamic>,
      ),
      schoolCounter: SchoolCounterMatrix.fromYaml(
        techniques['schools'] as Map<String, dynamic>,
      ),
      resonanceStages: _parseResonanceStages(
        equipment['resonance'] as Map<String, dynamic>,
      ),
      resonanceInheritanceRetention: ((equipment['resonance']
              as Map<String, dynamic>)['inheritance_retention'] as num)
          .toDouble(),
      lineageInternalForceMaxBonus: ((equipment['lineage_heritage']
              as Map<String, dynamic>)['internal_force_max_bonus'] as num)
          .toDouble(),
      founderAncestorBuff: FounderAncestorBuff.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)
                ?['founder_ancestor_buff'] as Map<String, dynamic>?) ??
            const {},
      ),
      dispersionCultivationPenalty: ((techniques['dispersion']
              as Map<String, dynamic>)['cultivation_penalty'] as num)
          .toDouble(),
      dispersionInternalForcePenalty: ((techniques['dispersion']
              as Map<String, dynamic>)['internal_force_penalty'] as num)
          .toDouble(),
      defeatBossInternalForcePenalty: ((techniques['defeat']
              as Map<String, dynamic>)['boss_internal_force_penalty'] as num)
          .toDouble(),
      defeatBossCultivationPenalty: ((techniques['defeat']
              as Map<String, dynamic>)['boss_cultivation_penalty'] as num)
          .toDouble(),
      learningCost: LearningCostConfig.fromYaml(
        techniques['learning_cost'] as Map<String, dynamic>,
      ),
      animation: AnimationNumbers.fromYaml(
        y['animation'] as Map<String, dynamic>,
      ),
      retreat: RetreatConfig.fromYaml(
        y['retreat'] as Map<String, dynamic>,
      ),
      festivals: FestivalConfig.fromYaml(
        y['festivals'] as Map<String, dynamic>?,
      ),
      innerDemon: InnerDemonDef.fromYaml(
        y['inner_demon'] as Map<String, dynamic>?,
      ),
      lightFoot: LightFootDef.fromYaml(
        y['light_foot'] as Map<String, dynamic>?,
      ),
      massBattle: MassBattleDef.fromYaml(
        y['mass_battle'] as Map<String, dynamic>?,
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

  static Map<CultivationLayer, int> _parseCultivationProgressToNext(
    Map<String, dynamic> cultivation,
  ) {
    final entries = cultivation['progress_to_next'] as List;
    final m = <CultivationLayer, int>{};
    for (final e in entries) {
      final fromLayer =
          CultivationLayer.values.byName(e['from_layer'] as String);
      m[fromLayer] = (e['progress_required'] as num).toInt();
    }
    return m;
  }

  static List<ResonanceStageConfig> _parseResonanceStages(
    Map<String, dynamic> resonance,
  ) {
    final stages = resonance['stages'] as List;
    return [
      for (final s in stages)
        ResonanceStageConfig(
          stage: ResonanceStage.values.byName(s['stage'] as String),
          minBattleCount:
              ((s['battle_count_range'] as List)[0] as num).toInt(),
          maxBattleCount:
              ((s['battle_count_range'] as List)[1] as num?)?.toInt(),
          bonusMultiplier: (s['bonus_multiplier'] as num).toDouble(),
          unlocksJointSkill: (s['unlocks_joint_skill'] as bool?) ?? false,
          hasSwordSongEffect: (s['has_sword_song_effect'] as bool?) ?? false,
        ),
    ];
  }
}

/// 祖师爷 buff(P1.1 A1 E.5,GDD §7.1)。numbers.yaml `inheritance.founder_ancestor_buff`。
///
/// 决议方案 E.5.A(2026-05-21):enabled_when_alive: false → true,玩家本人=祖师即享 buff。
/// CLAUDE.md §12.2 #11 v1.5 原决议「Demo 不实装,1.0 版本再设计」对应 P1.1 阶段激活。
///
/// 数值上限(CLAUDE.md §5.4 红线):各 pct 字段 ∈ [0, 0.15] 兜底(单字段 +15% 上限)。
/// Phase 5+ 飞升机制实装时,扩展 `enabled_when_alive` 语义为「founder 飞升后激活」。
class FounderAncestorBuff {
  /// 是否在祖师还活着时即激活(P1.1 简化:true = 玩家本人=祖师自带 buff)。
  /// Phase 5+:false 表示需要飞升才激活(原 GDD §7.1 语义)。
  final bool enabledWhenAlive;

  /// 内力上限 % 加成(基础 × (1 + pct))。
  final double internalForceMaxPct;

  /// 最大血量 % 加成(基础 × (1 + pct))。
  final double maxHpPct;

  /// 暴击率加成(绝对值,直接加到 critRate 后再 clamp,**不乘 base**)。
  final double critRateBonus;

  /// 修炼度获取速度 % 加成(本批 yaml 占位 + NumbersConfig 字段,**caller 暂不消费**;
  /// Phase 5+ 修炼度路径成熟时接入)。
  final double cultivationProgressPct;

  /// 是否仅对弟子生效(true = 祖师本人不享,false = 全 active 享)。
  /// P1.1 决议 false(GDD §7.1 玩家本人=祖师,自享 buff)。
  final bool applyToDisciplesOnly;

  const FounderAncestorBuff({
    required this.enabledWhenAlive,
    required this.internalForceMaxPct,
    required this.maxHpPct,
    required this.critRateBonus,
    required this.cultivationProgressPct,
    required this.applyToDisciplesOnly,
  });

  /// 全零 disabled 兜底(yaml 段缺失 / sect_wide_buff: null)。
  static const FounderAncestorBuff disabled = FounderAncestorBuff(
    enabledWhenAlive: false,
    internalForceMaxPct: 0,
    maxHpPct: 0,
    critRateBonus: 0,
    cultivationProgressPct: 0,
    applyToDisciplesOnly: false,
  );

  factory FounderAncestorBuff.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return disabled;
    final enabled = (y['enabled_when_alive'] as bool?) ?? false;
    final swb = y['sect_wide_buff'] as Map<String, dynamic>?;
    if (swb == null) {
      return FounderAncestorBuff(
        enabledWhenAlive: enabled,
        internalForceMaxPct: 0,
        maxHpPct: 0,
        critRateBonus: 0,
        cultivationProgressPct: 0,
        applyToDisciplesOnly: false,
      );
    }
    return FounderAncestorBuff(
      enabledWhenAlive: enabled,
      internalForceMaxPct:
          ((swb['internal_force_max_pct'] as num?) ?? 0).toDouble(),
      maxHpPct: ((swb['max_hp_pct'] as num?) ?? 0).toDouble(),
      critRateBonus: ((swb['crit_rate_bonus'] as num?) ?? 0).toDouble(),
      cultivationProgressPct:
          ((swb['cultivation_progress_pct'] as num?) ?? 0).toDouble(),
      applyToDisciplesOnly:
          (swb['apply_to_disciples_only'] as bool?) ?? false,
    );
  }

  /// buff 是否处于激活态(P1.1 简化:enabledWhenAlive 即激活)。
  /// Phase 5+ 飞升实装时本 getter 扩展为「founder 飞升退出 active 后才 true」。
  bool get isActive => enabledWhenAlive;
}

/// 强化系统配置（numbers.yaml `equipment.enhancement` + `equipment.xinxue_jiejing`，
/// T20）。
///
/// 解析后的三类查询表：
///   - [successCurve]：成功率 + 失败惩罚（按 targetLevel 区间）
///   - [mojianshiCost]：每次强化消耗（按 targetLevel 区间）
///   - [crystalGuarantees]：心血结晶保底消耗（按 targetLevel 区间，部分段无保底）
///
/// `successRate == null` 表示该段走 [_fallbackFormula]（GDD +20-49 段
/// `max(0.30, 0.50 - 0.02 × (level - 19))`）。targetLevel 指**强化目标等级**
/// （即当前 enhanceLevel + 1）。
class EnhancementConfig {
  final List<EnhanceLevelBracket> successCurve;
  final List<MaterialCostBracket> mojianshiCost;
  final List<CrystalGuaranteeBracket> crystalGuarantees;

  /// 每次强化失败必得心血结晶数（GDD §6.3 = 1）。
  final int crystalGainPerFailure;

  /// 永不破防降级（GDD §6.2 红线）。Phase 2 必须为 true，
  /// false 时 EnhancementService 会 fail-fast。
  final bool neverDegrade;

  const EnhancementConfig({
    required this.successCurve,
    required this.mojianshiCost,
    required this.crystalGuarantees,
    required this.crystalGainPerFailure,
    required this.neverDegrade,
  });

  factory EnhancementConfig.fromYaml({
    required Map<String, dynamic> enhancement,
    required Map<String, dynamic> xinxueJiejing,
  }) {
    return EnhancementConfig(
      successCurve: _parseSuccessCurve(enhancement['success_curve'] as List),
      mojianshiCost: _parseMaterialCost(enhancement['mojianshi_cost'] as List),
      crystalGuarantees: _parseCrystalGuarantees(
        xinxueJiejing['guaranteed_success_costs'] as List,
      ),
      crystalGainPerFailure:
          (xinxueJiejing['gain_per_failure'] as num).toInt(),
      neverDegrade: enhancement['never_degrade'] as bool? ?? true,
    );
  }

  /// 取 [targetLevel]（=enhanceLevel + 1）的成功率。yaml `success_rate: null`
  /// 段走 [_fallbackFormula]（+20-49 段公式）。
  double successRateFor(int targetLevel) {
    final bracket = _findBracket(successCurve, targetLevel);
    return bracket.successRate ?? _fallbackFormula(targetLevel);
  }

  /// 取 [targetLevel] 的失败惩罚类型。
  MaterialPenalty materialPenaltyFor(int targetLevel) =>
      _findBracket(successCurve, targetLevel).materialPenalty;

  /// 取 [targetLevel] 的磨剑石消耗。
  int mojianshiCostFor(int targetLevel) {
    for (final b in mojianshiCost) {
      if (targetLevel >= b.minLevel && targetLevel <= b.maxLevel) {
        return b.cost;
      }
    }
    throw StateError('mojianshi_cost 缺少 targetLevel=$targetLevel 的覆盖区间');
  }

  /// 取 [targetLevel] 的心血结晶保底消耗，null 表示该段无保底（+1-13）。
  int? crystalCostToGuarantee(int targetLevel) {
    for (final b in crystalGuarantees) {
      if (targetLevel >= b.minLevel && targetLevel <= b.maxLevel) {
        return b.crystalCost;
      }
    }
    return null;
  }

  EnhanceLevelBracket _findBracket(
    List<EnhanceLevelBracket> brackets,
    int targetLevel,
  ) {
    for (final b in brackets) {
      if (targetLevel >= b.minLevel && targetLevel <= b.maxLevel) return b;
    }
    throw StateError('success_curve 缺少 targetLevel=$targetLevel 的覆盖区间');
  }

  /// GDD §12 #3 决议：+20-49 段公式 `max(0.30, 0.50 - 0.02 × (level - 19))`。
  static double _fallbackFormula(int targetLevel) {
    final raw = 0.50 - 0.02 * (targetLevel - 19);
    return raw < 0.30 ? 0.30 : raw;
  }

  static List<EnhanceLevelBracket> _parseSuccessCurve(List raw) {
    return [
      for (final e in raw)
        EnhanceLevelBracket(
          minLevel: ((e['level_range'] as List)[0] as num).toInt(),
          maxLevel: ((e['level_range'] as List)[1] as num).toInt(),
          successRate: (e['success_rate'] as num?)?.toDouble(),
          materialPenalty: _parsePenalty(e['material_penalty'] as String),
        ),
    ];
  }

  static List<MaterialCostBracket> _parseMaterialCost(List raw) {
    return [
      for (final e in raw)
        MaterialCostBracket(
          minLevel: ((e['level_range'] as List)[0] as num).toInt(),
          maxLevel: ((e['level_range'] as List)[1] as num).toInt(),
          cost: (e['cost'] as num).toInt(),
        ),
    ];
  }

  static List<CrystalGuaranteeBracket> _parseCrystalGuarantees(List raw) {
    return [
      for (final e in raw)
        CrystalGuaranteeBracket(
          minLevel: ((e['level_range'] as List)[0] as num).toInt(),
          maxLevel: ((e['level_range'] as List)[1] as num).toInt(),
          crystalCost: (e['crystal_cost'] as num).toInt(),
        ),
    ];
  }

  static MaterialPenalty _parsePenalty(String s) {
    switch (s) {
      case 'none':
        return MaterialPenalty.none;
      case 'half':
        return MaterialPenalty.half;
      case 'full':
        return MaterialPenalty.full;
      default:
        throw StateError('未知 material_penalty: $s');
    }
  }
}

class EnhanceLevelBracket {
  final int minLevel;
  final int maxLevel;
  final double? successRate;
  final MaterialPenalty materialPenalty;

  const EnhanceLevelBracket({
    required this.minLevel,
    required this.maxLevel,
    required this.successRate,
    required this.materialPenalty,
  });
}

class MaterialCostBracket {
  final int minLevel;
  final int maxLevel;
  final int cost;

  const MaterialCostBracket({
    required this.minLevel,
    required this.maxLevel,
    required this.cost,
  });
}

class CrystalGuaranteeBracket {
  final int minLevel;
  final int maxLevel;
  final int crystalCost;

  const CrystalGuaranteeBracket({
    required this.minLevel,
    required this.maxLevel,
    required this.crystalCost,
  });
}

enum MaterialPenalty { none, half, full }

/// 开锋系统配置（numbers.yaml `equipment.forging`，T21）。
///
/// 3 个槽分别在 +10 / +15 / +19 解锁。槽 2 受 yaml `constraint` 字段约束
/// "不能与开锋一相同类型"，由 [ForgingSlotConfig.excludePreviousSlotType]
/// 标记（解析时识别字符串）。
class ForgingConfig {
  final List<ForgingSlotConfig> slots;

  const ForgingConfig({required this.slots});

  factory ForgingConfig.fromYaml(Map<String, dynamic> y) {
    return ForgingConfig(
      slots: [
        for (final s in y['slots'] as List)
          ForgingSlotConfig.fromYaml(s as Map<String, dynamic>),
      ],
    );
  }

  /// 按 [slotIndex]（1/2/3）取槽配置。越界抛 [StateError]。
  ForgingSlotConfig slotByIndex(int slotIndex) {
    for (final s in slots) {
      if (s.slotIndex == slotIndex) return s;
    }
    throw StateError('ForgingConfig 缺少 slotIndex=$slotIndex 的配置');
  }
}

class ForgingSlotConfig {
  final int slotIndex;
  final int unlockAtEnhanceLevel;
  final List<ForgingSlotType> availableTypes;
  final Map<ForgingSlotType, int> bonusValue;

  /// yaml `constraint` 字段不为空时为 true（当前仅 slot 2 = "不能与开锋一相同类型"）。
  final bool excludePreviousSlotType;

  const ForgingSlotConfig({
    required this.slotIndex,
    required this.unlockAtEnhanceLevel,
    required this.availableTypes,
    required this.bonusValue,
    required this.excludePreviousSlotType,
  });

  factory ForgingSlotConfig.fromYaml(Map<String, dynamic> y) {
    final available = [
      for (final t in y['available_types'] as List)
        ForgingSlotType.values.byName(t as String),
    ];
    final bonusRaw = y['bonus_value'] as Map<String, dynamic>;
    final bonus = <ForgingSlotType, int>{
      for (final e in bonusRaw.entries)
        ForgingSlotType.values.byName(e.key): (e.value as num).toInt(),
    };
    return ForgingSlotConfig(
      slotIndex: (y['slot_index'] as num).toInt(),
      unlockAtEnhanceLevel: (y['unlock_at_enhance_level'] as num).toInt(),
      availableTypes: available,
      bonusValue: bonus,
      excludePreviousSlotType: y['constraint'] != null,
    );
  }
}

/// 单段共鸣度配置（numbers.yaml `equipment.resonance.stages[]`）。
///
/// `maxBattleCount == null` 表示该段为最高段，无 battleCount 上限。
///
/// P1.1 候选 3-b/c:`unlocksJointSkill` + `hasSwordSongEffect` 让 yaml
/// 成 unlock 门槛 source of truth(不靠 enum index hardcode)。
class ResonanceStageConfig {
  final ResonanceStage stage;
  final int minBattleCount;
  final int? maxBattleCount;
  final double bonusMultiplier;
  final bool unlocksJointSkill;
  final bool hasSwordSongEffect;

  const ResonanceStageConfig({
    required this.stage,
    required this.minBattleCount,
    required this.maxBattleCount,
    required this.bonusMultiplier,
    this.unlocksJointSkill = false,
    this.hasSwordSongEffect = false,
  });
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

  /// 刚猛克阴柔附带震伤(CLAUDE.md §12.1 #7 v1.4 决议)。
  final GangMengQuakeConfig gangMengQuake;

  /// 阴柔克灵巧附带内伤 debuff(CLAUDE.md §12.1 #7 v1.4 决议)。
  final YinRouInternalInjuryConfig yinRouInternalInjury;

  const SchoolCounterMatrix({
    required Map<TechniqueSchool, TechniqueSchool> counterTarget,
    required Map<TechniqueSchool, String> extraEffect,
    required this.counter,
    required this.countered,
    required this.neutral,
    required this.gangMengQuake,
    required this.yinRouInternalInjury,
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
      gangMengQuake: GangMengQuakeConfig.fromYaml(
        y['gang_meng_quake'] as Map<String, dynamic>,
      ),
      yinRouInternalInjury: YinRouInternalInjuryConfig.fromYaml(
        y['yin_rou_internal_injury'] as Map<String, dynamic>,
      ),
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

/// 刚猛克阴柔额外震伤配置(numbers.yaml `combat.schools.gang_meng_quake`)。
///
/// CLAUDE.md §12.1 #7 v1.4 决议:主攻击命中后追加固定 damage,与主伤害同 tick 叠加。
/// 穿透守方防御率(`piercesDefense=true`),不被暴击乘(`piercesCritical=true`),
/// 主攻击闪避则震伤不触发(`followsMainHit=true`)。
class GangMengQuakeConfig {
  final int damage;
  final bool piercesDefense;
  final bool piercesCritical;
  final bool followsMainHit;

  const GangMengQuakeConfig({
    required this.damage,
    required this.piercesDefense,
    required this.piercesCritical,
    required this.followsMainHit,
  });

  factory GangMengQuakeConfig.fromYaml(Map<String, dynamic> y) {
    return GangMengQuakeConfig(
      damage: (y['damage'] as num).toInt(),
      piercesDefense: y['pierces_defense'] as bool,
      piercesCritical: y['pierces_critical'] as bool,
      followsMainHit: y['follows_main_hit'] as bool,
    );
  }
}

/// 阴柔克灵巧内伤 debuff 配置(numbers.yaml `combat.schools.yin_rou_internal_injury`)。
///
/// CLAUDE.md §12.1 #7 v1.4 决议:主攻击命中后在守方身上施加内伤槽,
/// `turnsPersist` 守方 tick 内每 tick 扣 `damagePerTick` 固定值。
/// 穿透防御率(`piercesDefense=true`),可致死。
/// 同源刷新(`stackRule=refresh`):重复触发重置 turns 不叠层。
class YinRouInternalInjuryConfig {
  final int turnsPersist;
  final int damagePerTick;
  final bool piercesDefense;
  final String stackRule;
  final bool followsMainHit;

  const YinRouInternalInjuryConfig({
    required this.turnsPersist,
    required this.damagePerTick,
    required this.piercesDefense,
    required this.stackRule,
    required this.followsMainHit,
  });

  factory YinRouInternalInjuryConfig.fromYaml(Map<String, dynamic> y) {
    return YinRouInternalInjuryConfig(
      turnsPersist: (y['turns_persist'] as num).toInt(),
      damagePerTick: (y['damage_per_tick'] as num).toInt(),
      piercesDefense: y['pierces_defense'] as bool,
      stackRule: y['stack_rule'] as String,
      followsMainHit: y['follows_main_hit'] as bool,
    );
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

  /// 灵巧流派额外暴击率（GDD §4.4 = 0.20，T09 用）。
  final double lingqiaoCriticalBonus;

  /// 灵巧流派暴击时的伤害倍率（phase1_tasks T10 §584 简化为 2.0，T10 用）。
  final double lingqiaoDamageMultiplier;

  const CriticalConfig({
    required this.baseRate,
    required this.agilityPerPointRate,
    required this.maxRate,
    required this.baseDamageMultiplier,
    required this.maxDamageMultiplier,
    required this.lingqiaoCriticalBonus,
    required this.lingqiaoDamageMultiplier,
  });

  factory CriticalConfig.fromYaml(Map<String, dynamic> y) {
    return CriticalConfig(
      baseRate: (y['base_rate'] as num).toDouble(),
      agilityPerPointRate: (y['agility_per_point_rate'] as num).toDouble(),
      maxRate: (y['max_rate'] as num).toDouble(),
      baseDamageMultiplier: (y['base_damage_multiplier'] as num).toDouble(),
      maxDamageMultiplier: (y['max_damage_multiplier'] as num).toDouble(),
      lingqiaoCriticalBonus:
          (y['lingqiao_critical_bonus'] as num).toDouble(),
      lingqiaoDamageMultiplier:
          (y['lingqiao_damage_multiplier'] as num).toDouble(),
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
/// 数据层兜底为 `1.0`（单位元，与公式层 GDD §5.5「不放大」语义统一）。
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
        attacker: (raw3['attacker'] as num?)?.toDouble() ?? 1.0,
        defender: (raw3['defender'] as num).toDouble(),
      ),
    );
  }
}

/// 动画时序配置（numbers.yaml `animation`，T15）。
///
/// 所有时间单位 ms，位移单位逻辑像素。提供 [defaults] 常量供测试和 fallback 使用。
class AnimationNumbers {
  final int attackRushMs;
  final int attackHoldMs;
  final int attackRetreatMs;
  final double attackRushOffsetPx;
  final double damagePopupFloatPx;
  final int damagePopupMs;
  final int actionIntervalMs;
  final int fastForwardIntervalMs;
  final double shakeOffsetPx;
  final int shakeDurationMs;
  final double criticalFontScale;

  const AnimationNumbers({
    required this.attackRushMs,
    required this.attackHoldMs,
    required this.attackRetreatMs,
    required this.attackRushOffsetPx,
    required this.damagePopupFloatPx,
    required this.damagePopupMs,
    required this.actionIntervalMs,
    required this.fastForwardIntervalMs,
    required this.shakeOffsetPx,
    required this.shakeDurationMs,
    required this.criticalFontScale,
  });

  /// 默认值与 numbers.yaml 保持一致，用于测试或无法加载 yaml 的场景。
  static const AnimationNumbers defaults = AnimationNumbers(
    attackRushMs: 150,
    attackHoldMs: 100,
    attackRetreatMs: 150,
    attackRushOffsetPx: 40.0,
    damagePopupFloatPx: 50.0,
    damagePopupMs: 800,
    actionIntervalMs: 800,
    fastForwardIntervalMs: 100,
    shakeOffsetPx: 3.0,
    shakeDurationMs: 100,
    criticalFontScale: 1.5,
  );

  int get attackTotalMs => attackRushMs + attackHoldMs + attackRetreatMs;

  factory AnimationNumbers.fromYaml(Map<String, dynamic> y) {
    return AnimationNumbers(
      attackRushMs: (y['attack_rush_ms'] as num).toInt(),
      attackHoldMs: (y['attack_hold_ms'] as num).toInt(),
      attackRetreatMs: (y['attack_retreat_ms'] as num).toInt(),
      attackRushOffsetPx: (y['attack_rush_offset_px'] as num).toDouble(),
      damagePopupFloatPx: (y['damage_popup_float_px'] as num).toDouble(),
      damagePopupMs: (y['damage_popup_ms'] as num).toInt(),
      actionIntervalMs: (y['action_interval_ms'] as num).toInt(),
      fastForwardIntervalMs: (y['fast_forward_interval_ms'] as num).toInt(),
      shakeOffsetPx: (y['shake_offset_px'] as num).toDouble(),
      shakeDurationMs: (y['shake_duration_ms'] as num).toInt(),
      criticalFontScale: (y['critical_font_scale'] as num).toDouble(),
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

/// 心法学习成本（numbers.yaml `techniques.learning_cost`，phase2_tasks T23）。
///
/// Demo 阶段统一固定值，按 [TechniqueRole] 区分主修 / 辅修。领悟点来源待
/// GDD §7.2 武学领悟系统实装；本配置仅描述消耗端。
class LearningCostConfig {
  final int assist;
  final int main;

  const LearningCostConfig({required this.assist, required this.main});

  factory LearningCostConfig.fromYaml(Map<String, dynamic> y) {
    return LearningCostConfig(
      assist: (y['assist'] as num).toInt(),
      main: (y['main'] as num).toInt(),
    );
  }

  /// 按 [role] 取消耗。
  int costFor(TechniqueRole role) {
    switch (role) {
      case TechniqueRole.main:
        return main;
      case TechniqueRole.assist:
        return assist;
    }
  }
}

/// 闭关系统配置（numbers.yaml `retreat`，Phase 3 T47）。
///
/// 包含 5 张地图定义、可选时长、境界缩放系数、封顶小时数、
/// 基础装备掉落概率、节气日加成、子时内力加成（#30 闭关 3 维度接 service）。
class RetreatConfig {
  final List<SeclusionMapDef> maps;

  /// 可选闭关时长（小时），通常 [1, 4, 12]。
  final List<int> durationHours;

  /// 每升一大境界，产出倍率乘以此系数（默认 1.3）。
  final double realmScalePerTier;

  /// 离线结算封顶小时数（超出部分不累积）。
  final int capHours;

  /// 基础装备触发概率，与地图 equipmentDropRate 相乘后为最终掉落概率。
  final double baseEquipDropProbability;

  /// 内力每小时基础点数（#30）。
  final double baseInternalForcePerHour;

  /// 心法领悟每小时基础点数（#30）。
  final double baseTechniqueLearnPerHour;

  /// 节气日加成倍率（默认 1.30，全产出 +30%）。
  final double solarTermMultiplier;

  /// 节气日清单（公历 month/day，§12 #13 方案 A 决议:不引入农历库，
  /// 年际偏差仅 1 天可接受）。每条 `(month, day)` 元组。
  final List<({int month, int day})> solarTermDays;

  /// 子时内力加成倍率（默认 1.20，只乘 internalForcePoints 维度，不乘其他产出）。
  final double ziShiInternalForceMultiplier;

  /// 正午阳刚加成倍率(默认 1.20,CLAUDE.md §12.1 #7 v1.4 决议)。
  final double zhengWuYangSchoolMultiplier;

  /// 正午阳刚加成的目标产出维度(本批决议 internal_force_points)。
  final String zhengWuTargetAttribute;

  /// 正午阳刚加成生效的角色主修流派(本批决议 gangMeng)。
  final TechniqueSchool zhengWuAppliesToSchool;

  const RetreatConfig({
    required this.maps,
    required this.durationHours,
    required this.realmScalePerTier,
    required this.capHours,
    required this.baseEquipDropProbability,
    required this.baseInternalForcePerHour,
    required this.baseTechniqueLearnPerHour,
    required this.solarTermMultiplier,
    required this.solarTermDays,
    required this.ziShiInternalForceMultiplier,
    required this.zhengWuYangSchoolMultiplier,
    required this.zhengWuTargetAttribute,
    required this.zhengWuAppliesToSchool,
  });

  factory RetreatConfig.fromYaml(Map<String, dynamic> y) {
    final rawMaps = y['maps'] as List;
    final rawDurations = y['durations'] as List;
    final rawSolar = y['solar_term_bonus'] as Map<String, dynamic>;
    final rawTimeOfDay = y['time_of_day_bonus'] as List;
    // 提取子时（period=ziShi）的 multiplier，effect=internal_force_growth
    final ziShi = rawTimeOfDay.firstWhere(
      (e) => (e as Map)['period'] == 'ziShi',
      orElse: () => <String, dynamic>{'multiplier': 1.0},
    ) as Map;
    // 正午(period=zhengWu)v1.4 加成定向落到 internal_force_points + 仅 gangMeng 触发。
    final zhengWu = rawTimeOfDay.firstWhere(
      (e) => (e as Map)['period'] == 'zhengWu',
      orElse: () => <String, dynamic>{
        'multiplier': 1.0,
        'target_attribute': 'internal_force_points',
        'applies_to_school': 'gangMeng',
      },
    ) as Map;
    final solarDays = (rawSolar['days_2026'] as List)
        .map((e) {
          final dateStr = (e as Map)['date'] as String;
          final parts = dateStr.split('-');
          return (
            month: int.parse(parts[1]),
            day: int.parse(parts[2]),
          );
        })
        .toList(growable: false);
    return RetreatConfig(
      maps: [
        for (final m in rawMaps)
          SeclusionMapDef.fromYaml(m as Map<String, dynamic>),
      ],
      durationHours: [
        for (final d in rawDurations) (d['hours'] as num).toInt(),
      ],
      realmScalePerTier: (y['realm_scale_per_tier'] as num).toDouble(),
      capHours: (y['cap_hours'] as num).toInt(),
      baseEquipDropProbability:
          (y['base_equip_drop_probability'] as num).toDouble(),
      baseInternalForcePerHour:
          (y['base_internal_force_per_hour'] as num).toDouble(),
      baseTechniqueLearnPerHour:
          (y['base_technique_learn_per_hour'] as num).toDouble(),
      solarTermMultiplier: (rawSolar['multiplier'] as num).toDouble(),
      solarTermDays: solarDays,
      ziShiInternalForceMultiplier: (ziShi['multiplier'] as num).toDouble(),
      zhengWuYangSchoolMultiplier: (zhengWu['multiplier'] as num).toDouble(),
      zhengWuTargetAttribute: zhengWu['target_attribute'] as String,
      zhengWuAppliesToSchool:
          TechniqueSchool.values.byName(zhengWu['applies_to_school'] as String),
    );
  }

  /// 当前日期是否落在节气日（按 month/day 比对，忽略年份 — 方案 A 跨年容忍 1 天偏差）。
  bool isSolarTermDay(DateTime when) {
    for (final d in solarTermDays) {
      if (when.month == d.month && when.day == d.day) return true;
    }
    return false;
  }

  /// 给定境界大阶的产出缩放倍率：`realmScalePerTier ^ tier.index`。
  ///
  /// [RealmTier.xueTu].index == 0 → 1.0；
  /// [RealmTier.zongShi].index == 5 → 1.3^5 ≈ 3.71。
  double realmScaleFor(RealmTier tier) {
    if (tier.index == 0) return 1.0;
    var scale = 1.0;
    for (var i = 0; i < tier.index; i++) {
      scale *= realmScalePerTier;
    }
    return scale;
  }
}

/// 农历节日配置（numbers.yaml `festivals`，W16 GDD §12.4 接口预留）。
///
/// **不影响数值红线**（GDD §12.4 明文「节日活动：不影响数值」）—— 仅作为
/// encounter trigger 维度 + UI「今日节日」chip 显示来源。
///
/// 农历转公历每年不同，先 hardcode 2026 年，后续年份扩 yaml 加 `days_YYYY` 段
/// (沿用 [RetreatConfig.solarTermDays] 体例)。**不引入农历库**，与 §12 #13
/// 决议保持一致。
///
/// fixture 不带 `festivals` 段（test yaml）时构造 [FestivalConfig.empty]：
/// [festivalOn] 永远返回 null（无任何节日触发），不破坏既有 fixture。
class FestivalConfig {
  /// 节日日期清单。`(festival, month, day)` 三元组按 yaml 顺序保留。
  final List<({Festival festival, int month, int day})> days;

  const FestivalConfig({required this.days});

  /// 空配置（fixture / test yaml 不带 festivals 段时用）。
  static const FestivalConfig empty = FestivalConfig(days: []);

  factory FestivalConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return empty;
    final rawDays = y['days_2026'] as List?;
    if (rawDays == null) return empty;
    final parsed = <({Festival festival, int month, int day})>[];
    for (final raw in rawDays) {
      final entry = raw as Map;
      final festival =
          Festival.values.byName(entry['festival'] as String);
      final dateStr = entry['date'] as String;
      final parts = dateStr.split('-');
      parsed.add((
        festival: festival,
        month: int.parse(parts[1]),
        day: int.parse(parts[2]),
      ));
    }
    return FestivalConfig(days: List.unmodifiable(parsed));
  }

  /// 给定日期是否为节日。按 month/day 比对（忽略年份，沿用 solarTermDays 体例）。
  /// 同 month/day 多个节日的情况（实际中不会发生）返回**第一个**命中。
  Festival? festivalOn(DateTime when) {
    for (final d in days) {
      if (when.month == d.month && when.day == d.day) return d.festival;
    }
    return null;
  }
}
