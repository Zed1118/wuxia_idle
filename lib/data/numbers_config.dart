import 'dart:math' as math;

import '../features/equipment/domain/cycle_drop_bonus.dart';
import '../features/equipment/domain/equipment_disposal.dart';
import '../features/equipment/domain/rare_bonus_drop.dart';
import '../features/injury/domain/injury_config.dart';
import '../features/level/domain/level_config.dart';
import '../features/inner_demon/domain/inner_demon_def.dart';
import '../features/light_foot/domain/light_foot_def.dart';
import '../features/mass_battle/domain/mass_battle_def.dart';
import '../features/seclusion/domain/seclusion_map_def.dart';
import '../features/taohua_island/domain/taohua_island_config.dart';
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

  /// 招式熟练度阶段配置(可玩性 P1a · spec §三/§2.5)。
  /// `combat.skill_proficiency`,全局阶段倍率(末阶 1.30 作综合 cap)。
  final SkillProficiencyConfig skillProficiency;

  /// 招式解锁配置(可玩性 P1a · spec §二)。顶层 `skill_unlock` 段。
  final SkillUnlockConfig skillUnlock;

  /// 爆品展示动画门槛(2026-06-11)。顶层 `treasure_drop` 段。
  final TreasureDropConfig treasureDrop;

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

  /// insightPoints 凝练兑换主修修炼度 progress 的比率（numbers.yaml
  /// `techniques.cultivation.insight_to_cultivation_ratio`，根因A 2026-05-29）。
  /// `progressDelta = floor(insightSpend × ratio)`。
  final double insightToCultivationRatio;

  /// 3×3 流派克制矩阵（numbers.yaml `techniques.schools`，GDD §4.4 / §5.4，T10 用）。
  final SchoolCounterMatrix schoolCounter;

  /// 4 段共鸣度配置（numbers.yaml `equipment.resonance.stages`，GDD §6.4）。
  /// 顺序：生疏 → 趁手 → 默契 → 心剑通灵；最后一段 [maxBattleCount] 为 null（无上限）。
  final List<ResonanceStageConfig> resonanceStages;

  /// 师承遗物的共鸣度保留比例（numbers.yaml `equipment.resonance.inheritance_retention`，
  /// GDD §6.4 = 0.7）。
  final double resonanceInheritanceRetention;

  /// 闭关挂机每小时折算的 battleCount（numbers.yaml
  /// `equipment.resonance.seclusion_battle_count_per_hour`，根因A 2026-05-29）。
  /// 让离线挂机也推进共鸣度（人剑合一），明显低于实战速率以保「实战为主」。
  final int resonanceSeclusionBattleCountPerHour;

  /// 师承遗物的内力上限加成（numbers.yaml `equipment.lineage_heritage.internal_force_max_bonus`，
  /// GDD §6.1 = 0.05）。
  /// Phase 2 决议：每件 isLineageHeritage=true 装备**独立叠加** +5%（§12 #10 待 Pen
  /// 拍板，本阶段按"独立叠加"实现）。T22 用。
  final double lineageInternalForceMaxBonus;

  /// 装备出售/分解配置（numbers.yaml `equipment.disposal`，2026-06-26 红线推翻）。
  /// 7 阶出售价 + 强化倍率 + 分解材料量。
  final EquipmentDisposalConfig disposal;

  /// 祖师爷 buff(P1.1 A1 E.5,GDD §7.1)。
  /// numbers.yaml `inheritance.founder_ancestor_buff`,P1.1 阶段决议方案 E.5.A:
  /// `enabled_when_alive: true` + 玩家本人=祖师身份,自带 sect_wide_buff 给 active
  /// 全员(`apply_to_disciples_only: false`)。Phase 5+ 飞升机制实装时,trigger
  /// 条件扩展(eg. founder.realm >= wuSheng)。
  final FounderAncestorBuff founderAncestorBuff;

  /// 师承遗物 transfer 规则(CLAUDE.md §12.1 #10 v1.5 决议 4 字段 + 2 数量字段)。
  /// numbers.yaml `inheritance.heritage_items`,P2.3 飞升 lib 端真消费。
  /// AscendService.performAscend 走 [piecesPerGenerationMin..Max] 校验 +
  /// [multiDiscipleAllocation]=player_pick 走 UI 玩家分配 + [stackAcrossGenerations]=false
  /// enforce Demo 一代飞升不累代叠。
  final HeritageItems heritageItems;

  /// 飞升 eligibility 触发器(spec p2_3_ascension_spec_2026-05-24 Q4d)。
  /// numbers.yaml `ascension.unlock_triggers`,3 条件并存:cleared_stages 2 关 +
  /// required_realm 境界。AscendService.computeEligibility 消费。
  /// fixture 不带 `ascension` 段时走 [AscensionConfig.empty](canAscend 永 false)。
  final AscensionConfig ascension;

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

  /// 双层伤势系统配置（numbers.yaml `injury`，第八阶段 2026-06-25）。
  ///
  /// 轻伤叠层扣速度 + 重伤惨胜判定 + 疗养时长。
  /// fixture 不带 `injury` 段时走缺省值（[InjuryConfig.fromYaml] 空 map 兜底）。
  final InjuryConfig injury;

  /// 角色等级 Lv 配置（numbers.yaml `level`，第八阶段 2026-06-26）。
  ///
  /// 升级曲线 + per-level maxHp/内力/速度有界加成（hp/内力经 §5.4 clamp 守红线）。
  /// fixture 不带 `level` 段时走缺省值（[LevelConfig.fromYaml] 空 map 兜底=生产初值）。
  final LevelConfig level;

  /// 稀有彩头掉落配置（numbers.yaml `rare_bonus_drop`，第八阶段 E 2026-06-26）。
  ///
  /// 每场战斗额外小概率掉「高于本关 1-2 阶」装备。fixture 不带该段时
  /// [RareBonusDropConfig.empty]（enabled=false → 不掉，不破现有掉落行为）。
  final RareBonusDropConfig rareBonusDrop;

  /// 周目普通掉落材料加成(numbers.yaml `cycle_drop_bonus`,周目平衡 2026-06-26)。
  /// 二周目起材料类掉落数量倍率。fixture 缺该段 → [CycleDropBonusConfig.none]
  /// (倍率 1.0,旧行为不变)。
  final CycleDropBonusConfig cycleDropBonus;

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

  /// P1.2 江湖恩怨 + 声望(GDD §12.1 + §12.2 · spec p1_2_jianghu_enmity_spec_2026-05-24)。
  /// numbers.yaml `jianghu` 段:7 阶 reputation_tiers + enmity_combat_modifier + triggers。
  /// 空段兜底 [JianghuConfig.empty](fixture / 老存档迁移)。
  final JianghuConfig jianghu;

  /// 1.0 P3.4 门派事件配置(spec p3_4_sect_event_spec_2026-05-24 · T19b 升强类型)。
  /// numbers.yaml `sect_event` 段:tournament / reputation / sect_level / active_events_max。
  /// 空段兜底 [SectEventDef.empty](fixture / 老存档迁移)。
  final SectEventDef sectEvent;

  /// 1.0 P4.1 帮派门派配置(spec p4_1_sect_management_spec_2026-05-25 §2)。
  /// numbers.yaml `sect_management` 段:member_cap / rank_promote_threshold /
  /// recruit / territory。空段兜底 [SectManagementConfig.empty]。
  final SectManagementConfig sectManagement;

  /// 奇遇生涯属性加成上限(numbers.yaml
  /// `character.adventure_attribute_bonus.lifetime_cap_per_character`,GDD §4.1)。
  /// #4③ B2:接入 [EncounterService.attributeGainCap],消除该 yaml key 零消费。
  final int adventureAttributeLifetimeCap;

  /// 奇遇 fortune 软概率灵敏度(numbers.yaml `encounter.fortune_sensitivity`,C-W14-1 Q3)。
  /// p = baseProbability * (1 + fortune / sensitivity)。
  /// #4③ B5:从 [EncounterService] 硬编码 20.0 外置。
  final double encounterFortuneSensitivity;

  /// 技能装配大招槽阈值(numbers.yaml `skill_loadout.ultimate_power_threshold`,GDD §6)。
  /// 主修心法招 powerMultiplier ≥ 此值时自动填入大招槽，由 [SkillLoadout.autoFill] 消费。
  final int loadoutUltimatePowerThreshold;

  /// 周目进化配置(P1 cycle_evolution · numbers.yaml `cycle_evolution`)。
  /// 敌人随挂机周目数自动强化；全部参数数据驱动（§5.6 不硬编码）。
  /// fixture 不带 `cycle_evolution` 段时走 [CycleEvolutionConfig.empty]（traitsFor 永空集）。
  final CycleEvolutionConfig cycleEvolution;

  /// M2 范围 B 通用被动离线挂机配置（numbers.yaml `passive_idle`，spec 2026-06-15）。
  final PassiveIdleConfig passiveIdle;

  /// 桃花岛岛屿建筑配置（numbers.yaml `taohua_island`，桃花岛一期）。
  final TaohuaIslandConfig taohuaIsland;

  /// 战报失败诊断阈值（numbers.yaml `battle_report`，spec 2026-06-15）。
  final BattleReportConfig battleReport;

  /// 战后英雄镜头表现参数（第七阶段 批一）。顶层 `post_battle.hero_camera` 段。
  final HeroCameraConfig heroCamera;

  /// 命名弟子拜入触发表（第七阶段批三·队伍成长）。顶层 `lineage_onboarding` 段。
  ///
  /// 开局单人，弟子按主线关卡节点拜入。空段兜底 [LineageOnboardingConfig]（discipleJoins 空）。
  final LineageOnboardingConfig lineageOnboarding;

  /// numbers.yaml 全量原始 map（已 deep-convert 为 `Map<String, dynamic>`）。
  /// 战斗、装备、闭关等模块强类型化前，先从这里取数。
  final Map<String, dynamic> raw;

  const NumbersConfig({
    required this.version,
    required this.combat,
    required this.skillProficiency,
    required this.skillUnlock,
    required this.treasureDrop,
    required this.levelDiffModifier,
    required this.defenseRateByTier,
    required this.enhancementBonusPerLevel,
    required this.enhancement,
    required this.forging,
    required this.techniqueSpeedBonus,
    required this.cultivationMultiplier,
    required this.cultivationProgressToNext,
    required this.insightToCultivationRatio,
    required this.schoolCounter,
    required this.resonanceStages,
    required this.resonanceInheritanceRetention,
    required this.resonanceSeclusionBattleCountPerHour,
    required this.lineageInternalForceMaxBonus,
    required this.disposal,
    required this.founderAncestorBuff,
    required this.heritageItems,
    required this.ascension,
    required this.dispersionCultivationPenalty,
    required this.dispersionInternalForcePenalty,
    required this.defeatBossInternalForcePenalty,
    required this.defeatBossCultivationPenalty,
    required this.learningCost,
    required this.animation,
    required this.retreat,
    required this.festivals,
    required this.injury,
    required this.level,
    required this.rareBonusDrop,
    required this.cycleDropBonus,
    required this.innerDemon,
    required this.lightFoot,
    required this.massBattle,
    required this.jianghu,
    required this.sectEvent,
    required this.sectManagement,
    required this.adventureAttributeLifetimeCap,
    required this.encounterFortuneSensitivity,
    required this.loadoutUltimatePowerThreshold,
    required this.cycleEvolution,
    required this.passiveIdle,
    required this.taohuaIsland,
    required this.battleReport,
    required this.heroCamera,
    required this.lineageOnboarding,
    required this.raw,
  });

  /// F1 里程碑装备授予映射:stageId → dropSourceTags tag(顶层
  /// `milestone_equipment_grants` 段)。从 [raw] 读,缺段兜底空 map。
  /// 飞升 tag(ascension_reward)是终局事件非关卡,不入本表(performAscend 内直调)。
  Map<String, String> get milestoneEquipmentGrants {
    final m = raw['milestone_equipment_grants'] as Map?;
    if (m == null) return const {};
    return m.map((k, v) => MapEntry(k as String, v as String));
  }

  factory NumbersConfig.fromYaml(Map<String, dynamic> y) {
    final meta = y['meta'] as Map<String, dynamic>;
    final combat = y['combat'] as Map<String, dynamic>;
    final realms = y['realms'] as Map<String, dynamic>;
    final equipment = y['equipment'] as Map<String, dynamic>;
    final techniques = y['techniques'] as Map<String, dynamic>;

    return NumbersConfig(
      version: meta['version'] as String,
      combat: CombatNumbers.fromYaml(combat),
      skillProficiency: SkillProficiencyConfig.fromYaml(
        combat['skill_proficiency'] as Map<String, dynamic>?,
      ),
      skillUnlock: SkillUnlockConfig.fromYaml(
        (y['skill_unlock'] as Map?)?.cast<String, dynamic>(),
      ),
      treasureDrop: TreasureDropConfig.fromYaml(
        (y['treasure_drop'] as Map?)?.cast<String, dynamic>(),
      ),
      levelDiffModifier: LevelDiffModifier.fromYaml(
        realms['level_diff_modifier'] as Map<String, dynamic>,
      ),
      defenseRateByTier: _parseDefenseRates(realms['tiers'] as List),
      enhancementBonusPerLevel:
          ((equipment['enhancement'] as Map<String, dynamic>)['bonus_per_level']
                  as num)
              .toDouble(),
      enhancement: EnhancementConfig.fromYaml(
        enhancement: equipment['enhancement'] as Map<String, dynamic>,
        xinxueJiejing: equipment['xinxue_jiejing'] as Map<String, dynamic>,
      ),
      forging: ForgingConfig.fromYaml(
        equipment['forging'] as Map<String, dynamic>,
      ),
      techniqueSpeedBonus: _parseTechniqueSpeedBonus(
        techniques['tiers'] as List,
      ),
      cultivationMultiplier: _parseCultivationMultiplier(
        techniques['cultivation'] as Map<String, dynamic>,
      ),
      cultivationProgressToNext: _parseCultivationProgressToNext(
        techniques['cultivation'] as Map<String, dynamic>,
      ),
      insightToCultivationRatio:
          ((techniques['cultivation']
                      as Map<String, dynamic>)['insight_to_cultivation_ratio']
                  as num)
              .toDouble(),
      schoolCounter: SchoolCounterMatrix.fromYaml(
        techniques['schools'] as Map<String, dynamic>,
      ),
      resonanceStages: _parseResonanceStages(
        equipment['resonance'] as Map<String, dynamic>,
      ),
      resonanceInheritanceRetention:
          ((equipment['resonance']
                      as Map<String, dynamic>)['inheritance_retention']
                  as num)
              .toDouble(),
      resonanceSeclusionBattleCountPerHour:
          ((equipment['resonance']
                      as Map<
                        String,
                        dynamic
                      >)['seclusion_battle_count_per_hour']
                  as num)
              .toInt(),
      lineageInternalForceMaxBonus:
          ((equipment['lineage_heritage']
                      as Map<String, dynamic>)['internal_force_max_bonus']
                  as num)
              .toDouble(),
      disposal: EquipmentDisposalConfig.fromYaml(
        equipment['disposal'] as Map<String, dynamic>,
      ),
      founderAncestorBuff: FounderAncestorBuff.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['founder_ancestor_buff']
                as Map<String, dynamic>?) ??
            const {},
      ),
      heritageItems: HeritageItems.fromYaml(
        ((y['inheritance'] as Map<String, dynamic>?)?['heritage_items']
                as Map<String, dynamic>?) ??
            const {},
      ),
      ascension: AscensionConfig.fromYaml(
        y['ascension'] as Map<String, dynamic>?,
      ),
      dispersionCultivationPenalty:
          ((techniques['dispersion']
                      as Map<String, dynamic>)['cultivation_penalty']
                  as num)
              .toDouble(),
      dispersionInternalForcePenalty:
          ((techniques['dispersion']
                      as Map<String, dynamic>)['internal_force_penalty']
                  as num)
              .toDouble(),
      defeatBossInternalForcePenalty:
          ((techniques['defeat']
                      as Map<String, dynamic>)['boss_internal_force_penalty']
                  as num)
              .toDouble(),
      defeatBossCultivationPenalty:
          ((techniques['defeat']
                      as Map<String, dynamic>)['boss_cultivation_penalty']
                  as num)
              .toDouble(),
      learningCost: LearningCostConfig.fromYaml(
        techniques['learning_cost'] as Map<String, dynamic>,
      ),
      animation: AnimationNumbers.fromYaml(
        y['animation'] as Map<String, dynamic>,
      ),
      retreat: RetreatConfig.fromYaml(y['retreat'] as Map<String, dynamic>),
      festivals: FestivalConfig.fromYaml(
        y['festivals'] as Map<String, dynamic>?,
      ),
      level: LevelConfig.fromYaml(
        (y['level'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      rareBonusDrop: RareBonusDropConfig.fromYaml(
        (y['rare_bonus_drop'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      cycleDropBonus: CycleDropBonusConfig.fromYaml(
        (y['cycle_drop_bonus'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      injury: InjuryConfig.fromYaml(
        (y['injury'] as Map?)?.cast<String, dynamic>() ?? const {},
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
      jianghu: JianghuConfig.fromYaml(y['jianghu'] as Map<String, dynamic>?),
      sectEvent: SectEventDef.fromYaml(
        y['sect_event'] as Map<String, dynamic>?,
      ),
      sectManagement: SectManagementConfig.fromYaml(
        y['sect_management'] as Map<String, dynamic>?,
      ),
      adventureAttributeLifetimeCap:
          (((y['character']
                          as Map<
                            String,
                            dynamic
                          >?)?['adventure_attribute_bonus']
                      as Map<String, dynamic>?)?['lifetime_cap_per_character']
                  as num?)
              ?.toInt() ??
          5,
      encounterFortuneSensitivity:
          ((y['encounter'] as Map<String, dynamic>?)?['fortune_sensitivity']
                  as num?)
              ?.toDouble() ??
          20.0,
      loadoutUltimatePowerThreshold:
          ((y['skill_loadout']
                      as Map<String, dynamic>?)?['ultimate_power_threshold']
                  as num?)
              ?.toInt() ??
          5000,
      cycleEvolution: CycleEvolutionConfig.fromYaml(
        y['cycle_evolution'] as Map<String, dynamic>?,
      ),
      passiveIdle: PassiveIdleConfig.fromYaml(
        y['passive_idle'] as Map<String, dynamic>,
      ),
      taohuaIsland: TaohuaIslandConfig.fromYaml(
        (y['taohua_island'] as Map).cast<String, dynamic>(),
      ),
      battleReport: BattleReportConfig.fromYaml(
        y['battle_report'] as Map<String, dynamic>,
      ),
      heroCamera: HeroCameraConfig.fromYaml(
        ((y['post_battle'] as Map?)?.cast<String, dynamic>()['hero_camera']
                as Map?)
            ?.cast<String, dynamic>(),
      ),
      lineageOnboarding: LineageOnboardingConfig.fromYaml(
        y['lineage_onboarding'] as Map<String, dynamic>?,
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
      final fromLayer = CultivationLayer.values.byName(
        e['from_layer'] as String,
      );
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
          minBattleCount: ((s['battle_count_range'] as List)[0] as num).toInt(),
          maxBattleCount: ((s['battle_count_range'] as List)[1] as num?)
              ?.toInt(),
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
      internalForceMaxPct: ((swb['internal_force_max_pct'] as num?) ?? 0)
          .toDouble(),
      maxHpPct: ((swb['max_hp_pct'] as num?) ?? 0).toDouble(),
      critRateBonus: ((swb['crit_rate_bonus'] as num?) ?? 0).toDouble(),
      cultivationProgressPct: ((swb['cultivation_progress_pct'] as num?) ?? 0)
          .toDouble(),
      applyToDisciplesOnly: (swb['apply_to_disciples_only'] as bool?) ?? false,
    );
  }

  /// buff 是否处于激活态(P1.1 简化:enabledWhenAlive 即激活)。
  /// Phase 5+ 飞升实装时本 getter 扩展为「founder 飞升退出 active 后才 true」。
  bool get isActive => enabledWhenAlive;
}

/// 师承遗物 transfer 规则配置(CLAUDE.md §12.1 #10 v1.5 决议)。
/// numbers.yaml `inheritance.heritage_items`,P2.3 飞升 lib 端真消费 6 字段。
///
/// 4 规则字段(P2.3 spec Batch 3.1 落地):
///   - [transferTrigger] = "ascend_to_wusheng":仅本批触发(non-trigger 路径不传)
///   - [multiDiscipleAllocation] = "player_pick":玩家逐件选 disciple(UI 下拉)
///   - [stackAcrossGenerations] = false:不累代叠加(derived_stats §244 按
///     `isLineageHeritage` instance count 不按 prev len · P5+ R5.8 防回退测 enforce
///     · spec `p5_lineage_full_spec` §Q4)
///   - [conflictSlotResolution] = "auto_swap":P5+ 真实装(AscendService.performAscend
///     副作用 4 真消费 · disciple 端 equipped{Slot}Id 接新遗物 · 旧装 owner 不变入背包
///     语义 · spec `p5_lineage_full_spec` §Q3)
///
/// 2 数量字段:
///   - [piecesPerGenerationMin] = 1 / [piecesPerGenerationMax] = 2:每代传 1-2 件
class HeritageItems {
  final int piecesPerGenerationMin;
  final int piecesPerGenerationMax;
  final String transferTrigger;
  final String multiDiscipleAllocation;
  final bool stackAcrossGenerations;
  final String conflictSlotResolution;

  const HeritageItems({
    required this.piecesPerGenerationMin,
    required this.piecesPerGenerationMax,
    required this.transferTrigger,
    required this.multiDiscipleAllocation,
    required this.stackAcrossGenerations,
    required this.conflictSlotResolution,
  });

  /// 默认值兜底(fixture 不带 `inheritance.heritage_items` 段时)。
  /// 默认 [1,2] 范围 + v1.5 决议 4 字段值,sane fallback。
  static const HeritageItems defaults = HeritageItems(
    piecesPerGenerationMin: 1,
    piecesPerGenerationMax: 2,
    transferTrigger: 'ascend_to_wusheng',
    multiDiscipleAllocation: 'player_pick',
    stackAcrossGenerations: false,
    conflictSlotResolution: 'auto_swap',
  );

  factory HeritageItems.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return defaults;
    return HeritageItems(
      piecesPerGenerationMin:
          (y['pieces_per_generation_min'] as num?)?.toInt() ?? 1,
      piecesPerGenerationMax:
          (y['pieces_per_generation_max'] as num?)?.toInt() ?? 2,
      transferTrigger:
          (y['transfer_trigger'] as String?) ?? 'ascend_to_wusheng',
      multiDiscipleAllocation:
          (y['multi_disciple_allocation'] as String?) ?? 'player_pick',
      stackAcrossGenerations: (y['stack_across_generations'] as bool?) ?? false,
      conflictSlotResolution:
          (y['conflict_slot_resolution'] as String?) ?? 'auto_swap',
    );
  }
}

/// 飞升 eligibility 配置(spec p2_3_ascension_spec_2026-05-24 Q4d)。
/// numbers.yaml `ascension.unlock_triggers`,P2.3 飞升 lib 端真消费 3 条件并存。
///
/// fixture 不带 `ascension` 段(test yaml / 老存档迁移)时走 [AscensionConfig.empty]:
/// [clearedStagesRequired] 空 + [requiredRealmTier]/[requiredRealmLayer] null
/// → AscendService.computeEligibility 永返 canAscend=false(安全兜底)。
class AscensionConfig {
  /// 飞升前必须 cleared 的 stage_id 清单(双关:`stage_inner_demon_07` + `stage_06_05`)。
  final List<String> clearedStagesRequired;

  /// 飞升前 founder 必须达到的境界 tier(Q4d 拍板 wuSheng)。null = 无境界拦截。
  final RealmTier? requiredRealmTier;

  /// 飞升前 founder 必须达到的境界 layer(Q4d 拍板 dengFeng)。null = 无 layer 拦截。
  final RealmLayer? requiredRealmLayer;

  const AscensionConfig({
    required this.clearedStagesRequired,
    required this.requiredRealmTier,
    required this.requiredRealmLayer,
  });

  /// 空配置兜底(fixture / test yaml 不带 `ascension` 段)。
  /// canAscend 永 false,不破现有 fixture 与 e2e test。
  static const AscensionConfig empty = AscensionConfig(
    clearedStagesRequired: [],
    requiredRealmTier: null,
    requiredRealmLayer: null,
  );

  factory AscensionConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return empty;
    final triggers = y['unlock_triggers'] as Map<String, dynamic>?;
    if (triggers == null) return empty;
    final stages =
        (triggers['cleared_stages'] as List?)
            ?.map((e) => e as String)
            .toList(growable: false) ??
        const [];
    final realm = triggers['required_realm'] as Map<String, dynamic>?;
    final tier = realm == null
        ? null
        : RealmTier.values.byName(realm['tier'] as String);
    final layer = realm == null
        ? null
        : RealmLayer.values.byName(realm['layer'] as String);
    return AscensionConfig(
      clearedStagesRequired: List.unmodifiable(stages),
      requiredRealmTier: tier,
      requiredRealmLayer: layer,
    );
  }
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
      crystalGainPerFailure: (xinxueJiejing['gain_per_failure'] as num).toInt(),
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
  }) : _counterTarget = counterTarget,
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
  final EnemyDefaults enemyDefaults;
  final RedLinesConfig redLines;
  final BossChargeConfig bossCharge;
  final ImpactFeedbackConfig impactFeedback;
  final DefenseBreakConfig defenseBreak;
  final WeaknessConfig weakness;

  const CombatNumbers({
    required this.damageFormula,
    required this.maxHpFormula,
    required this.speedFormula,
    required this.critical,
    required this.evasion,
    required this.enemyDefaults,
    required this.redLines,
    required this.bossCharge,
    required this.impactFeedback,
    this.defenseBreak = const DefenseBreakConfig(),
    this.weakness = const WeaknessConfig(),
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
      critical: CriticalConfig.fromYaml(y['critical'] as Map<String, dynamic>),
      evasion: EvasionConfig.fromYaml(y['evasion'] as Map<String, dynamic>),
      enemyDefaults: EnemyDefaults.fromYaml(
        y['enemy_defaults'] as Map<String, dynamic>,
      ),
      redLines: RedLinesConfig.fromYaml(
        y['red_lines'] as Map<String, dynamic>? ?? const {},
      ),
      bossCharge: BossChargeConfig.fromYaml(
        y['boss_charge'] as Map? ?? const {},
      ),
      impactFeedback: ImpactFeedbackConfig.fromYaml(
        y['impact_feedback'] as Map? ?? const {},
      ),
      defenseBreak: DefenseBreakConfig.fromYaml(
        y['defense_break'] as Map? ?? const {},
      ),
      weakness: WeaknessConfig.fromYaml(y['weakness'] as Map? ?? const {}),
    );
  }
}

/// P0 破招:Boss 招牌技蓄力/被破招踉跄配置(numbers.yaml `combat.boss_charge`)。
///
/// fixture（test 简化 numbers yaml）不带 `boss_charge` 段时回落默认值,
/// 沿 [RedLinesConfig.fromYaml] 防御 fallback 体例。
class BossChargeConfig {
  final int defaultChargeTicks;
  final int defaultStaggerTicks;
  final double staggerDefenseDown;

  /// 波A:破招减防加深 cap——staggerDefenseDown × (1 + interrupt_power_pct)
  /// 的有效值不得超过此上限(红线,防御率减伤不破)。
  final double interruptPowerCap;

  const BossChargeConfig({
    required this.defaultChargeTicks,
    required this.defaultStaggerTicks,
    required this.staggerDefenseDown,
    this.interruptPowerCap = 0.5,
  });
  factory BossChargeConfig.fromYaml(Map y) => BossChargeConfig(
    defaultChargeTicks: (y['default_charge_ticks'] as num?)?.toInt() ?? 3,
    defaultStaggerTicks: (y['default_stagger_ticks'] as num?)?.toInt() ?? 2,
    staggerDefenseDown: (y['stagger_defense_down'] as num?)?.toDouble() ?? 0.3,
    interruptPowerCap: (y['interrupt_power_cap'] as num?)?.toDouble() ?? 0.5,
  );
}

/// 第六阶段三人协同:破防开窗参数。fixture 不带该段时回落默认(沿 BossChargeConfig 体例)。
/// 减防幅度由 per-skill SkillDef.defenseBreakPct 提供,全局不再持 defense_down_pct。
class DefenseBreakConfig {
  final int windowTicks;
  const DefenseBreakConfig({this.windowTicks = 3});
  factory DefenseBreakConfig.fromYaml(Map y) => DefenseBreakConfig(
    windowTicks: (y['window_ticks'] as num?)?.toInt() ?? 3,
  );
}

/// 第七阶段批二②:Boss 弱点/抗性乘子值域(numbers.yaml `combat.weakness`)。
///
/// 每个 Boss 的 `schoolDamageTakenMult` 各值须 ∈ [minMult, maxMult]
/// (加载期 GameRepository.enforceWeaknessRedLines 校)。maxMult 守 §5.4 ≤2.0。
/// fixture 不带该段时回落默认(沿 BossChargeConfig / DefenseBreakConfig 体例)。
class WeaknessConfig {
  final double minMult;
  final double maxMult;
  const WeaknessConfig({this.minMult = 0.5, this.maxMult = 2.0});
  factory WeaknessConfig.fromYaml(Map y) => WeaknessConfig(
    minMult: (y['min_mult'] as num?)?.toDouble() ?? 0.5,
    maxMult: (y['max_mult'] as num?)?.toDouble() ?? 2.0,
  );
}

/// 批次 2.4 打击感表现层三档参数（numbers.yaml `combat.impact_feedback`）。
/// 纯表现层（hit-stop 时长 / 镜头震幅 / 全屏闪白 alpha），不影响伤害/逻辑。
/// fixture 不带该段时回落默认值（沿 BossChargeConfig 防御 fallback 体例）。
class ImpactFeedbackConfig {
  final ImpactTierParams light;
  final ImpactTierParams medium;
  final ImpactTierParams heavy;

  const ImpactFeedbackConfig({
    required this.light,
    required this.medium,
    required this.heavy,
  });

  factory ImpactFeedbackConfig.fromYaml(Map y) => ImpactFeedbackConfig(
    light: ImpactTierParams.fromYaml(
      y['light'] as Map? ?? const {},
      defaultHitStopMs: 60,
      defaultShake: 3.0,
      defaultFlash: 0.12,
    ),
    medium: ImpactTierParams.fromYaml(
      y['medium'] as Map? ?? const {},
      defaultHitStopMs: 90,
      defaultShake: 6.0,
      defaultFlash: 0.20,
    ),
    heavy: ImpactTierParams.fromYaml(
      y['heavy'] as Map? ?? const {},
      defaultHitStopMs: 120,
      defaultShake: 10.0,
      defaultFlash: 0.30,
    ),
  );
}

class ImpactTierParams {
  final int hitStopMs;
  final double shakeMagnitude;
  final double flashStrength;

  const ImpactTierParams({
    required this.hitStopMs,
    required this.shakeMagnitude,
    required this.flashStrength,
  });

  factory ImpactTierParams.fromYaml(
    Map y, {
    required int defaultHitStopMs,
    required double defaultShake,
    required double defaultFlash,
  }) => ImpactTierParams(
    hitStopMs: (y['hit_stop_ms'] as num?)?.toInt() ?? defaultHitStopMs,
    shakeMagnitude: (y['shake_magnitude'] as num?)?.toDouble() ?? defaultShake,
    flashStrength: (y['flash_strength'] as num?)?.toDouble() ?? defaultFlash,
  );
}

/// 数值红线 cap 强类型（numbers.yaml `combat.red_lines`，GDD §5.4 硬上限）。
///
/// 单一真相源:替代 derived_stats / stage_battle_setup / game_repository 各自
/// 散落的 15000/20000 字面量。玩家 build（founder buff / 师承遗物 / 心法相生
/// 乘法叠加）可能把派生值推过红线,各 clamp 点统一读这里。
///
/// fixture（test 简化 numbers yaml）不带 `red_lines` 段时回落 §5.4 默认值,
/// 沿 [InnerDemonMirrorCaps.fromYaml] 防御 fallback 体例。
class RedLinesConfig {
  final int playerHpMax;
  final int internalForceMax;
  final int bossHpMax;

  const RedLinesConfig({
    required this.playerHpMax,
    required this.internalForceMax,
    required this.bossHpMax,
  });

  factory RedLinesConfig.fromYaml(Map<String, dynamic> y) {
    return RedLinesConfig(
      playerHpMax: (y['player_hp_max'] as num?)?.toInt() ?? 20000,
      internalForceMax: (y['internal_force_max'] as num?)?.toInt() ?? 15000,
      bossHpMax: (y['boss_hp_max'] as num?)?.toInt() ?? 60000,
    );
  }
}

/// 敌人合成默认值（numbers.yaml `combat.enemy_defaults`，P2-a/b 外部 review）。
///
/// 敌人不持装备/心法，[EnemyDef] → BattleCharacter 时这些字段用统一默认；
/// 从 `stage_battle_setup.dart` 的 hardcode 抽出以遵守 §5.6 不硬编码。
class EnemyDefaults {
  /// 敌人内力相对同境界 RealmDef.internalForceMax 的全局缩放系数（P5.2 对称化平衡旋钮）。
  final double internalForceScale;
  final double criticalRate;
  final double evasionRate;

  const EnemyDefaults({
    required this.internalForceScale,
    required this.criticalRate,
    required this.evasionRate,
  });

  factory EnemyDefaults.fromYaml(Map<String, dynamic> y) {
    final scale = (y['internal_force_scale'] as num).toDouble();
    if (scale <= 0 || scale > 2) {
      throw ArgumentError.value(
        scale,
        'internal_force_scale',
        '敌人内力 scale 必须 ∈ (0, 2]',
      );
    }
    return EnemyDefaults(
      internalForceScale: scale,
      criticalRate: (y['critical_rate'] as num).toDouble(),
      evasionRate: (y['evasion_rate'] as num).toDouble(),
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

  const SpeedFormula({required this.base, required this.agilityFactor});

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

  /// 暴击伤害「信息性上限」——**当前不作运行时 clamp**(审计 C-F2)。暴击倍率在
  /// damage_calculator 走固定档(base 1.5 / 灵巧 2.0),结构上已 ≤ 本值,无 clamp
  /// 分支消费它。保留为 balance 文档参考;若日后加可变倍率分支,需在
  /// DamageCalculator 显式 clamp 到本值才会真正生效。
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
      lingqiaoCriticalBonus: (y['lingqiao_critical_bonus'] as num).toDouble(),
      lingqiaoDamageMultiplier: (y['lingqiao_damage_multiplier'] as num)
          .toDouble(),
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
    final diff2 = TierMod.fromYaml(y['diff_2_tier'] as Map<String, dynamic>);
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

  /// 批次 2.4 后不再被消费：战斗屏震振幅改走 combat.impact_feedback 分档
  /// （light/medium/heavy）。保留字段 + yaml key 避免改既有 fixture/schema；
  /// 若后续确认无任何引用可整体移除。`shakeDurationMs` 仍在用（_shakeCtrl 时长）。
  final double shakeOffsetPx;
  final int shakeDurationMs;
  final double criticalFontScale;
  final int projectileMs;
  final int hitFlashMs;

  /// 关键帧（暴击/大招/合一/破招/击杀）命中后的额外顿帧时长（ms）。常速播放
  /// 下与 impact_feedback 的 hitStopMs 取大者，给「这一下重要」留读条停顿。
  /// 快进/拖招态不触发（沿 hit-stop 既有跳过约定）。
  final int keyMomentHoldMs;

  /// 一键扫荡：连播逐关切换时的关间过场停顿（ms）。战斗本体走
  /// [fastForwardIntervalMs] 快进，本字段只是两场之间喘口气的短停。
  final int sweepInterBattleGapMs;

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
    required this.projectileMs,
    required this.hitFlashMs,
    this.keyMomentHoldMs = 400,
    this.sweepInterBattleGapMs = 150,
  });

  /// 默认值与 numbers.yaml 保持一致，用于测试或无法加载 yaml 的场景。
  static const AnimationNumbers defaults = AnimationNumbers(
    attackRushMs: 150,
    attackHoldMs: 100,
    attackRetreatMs: 150,
    attackRushOffsetPx: 40.0,
    damagePopupFloatPx: 50.0,
    damagePopupMs: 700,
    actionIntervalMs: 1000,
    fastForwardIntervalMs: 100,
    shakeOffsetPx: 3.0,
    shakeDurationMs: 100,
    criticalFontScale: 1.5,
    projectileMs: 260,
    hitFlashMs: 150,
    keyMomentHoldMs: 400,
    sweepInterBattleGapMs: 150,
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
      projectileMs: (y['projectile_ms'] as num?)?.toInt() ?? 260,
      hitFlashMs: (y['hit_flash_ms'] as num?)?.toInt() ?? 150,
      keyMomentHoldMs: (y['key_moment_hold_ms'] as num?)?.toInt() ?? 400,
      sweepInterBattleGapMs:
          (y['sweep_inter_battle_gap_ms'] as num?)?.toInt() ?? 150,
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
    final ziShi =
        rawTimeOfDay.firstWhere(
              (e) => (e as Map)['period'] == 'ziShi',
              orElse: () => <String, dynamic>{'multiplier': 1.0},
            )
            as Map;
    // 正午(period=zhengWu)v1.4 加成定向落到 internal_force_points + 仅 gangMeng 触发。
    final zhengWu =
        rawTimeOfDay.firstWhere(
              (e) => (e as Map)['period'] == 'zhengWu',
              orElse: () => <String, dynamic>{
                'multiplier': 1.0,
                'target_attribute': 'internal_force_points',
                'applies_to_school': 'gangMeng',
              },
            )
            as Map;
    final solarDays = (rawSolar['days_2026'] as List)
        .map((e) {
          final dateStr = (e as Map)['date'] as String;
          final parts = dateStr.split('-');
          return (month: int.parse(parts[1]), day: int.parse(parts[2]));
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
      baseEquipDropProbability: (y['base_equip_drop_probability'] as num)
          .toDouble(),
      baseInternalForcePerHour: (y['base_internal_force_per_hour'] as num)
          .toDouble(),
      baseTechniqueLearnPerHour: (y['base_technique_learn_per_hour'] as num)
          .toDouble(),
      solarTermMultiplier: (rawSolar['multiplier'] as num).toDouble(),
      solarTermDays: solarDays,
      ziShiInternalForceMultiplier: (ziShi['multiplier'] as num).toDouble(),
      zhengWuYangSchoolMultiplier: (zhengWu['multiplier'] as num).toDouble(),
      zhengWuTargetAttribute: zhengWu['target_attribute'] as String,
      zhengWuAppliesToSchool: TechniqueSchool.values.byName(
        zhengWu['applies_to_school'] as String,
      ),
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
      final festival = Festival.values.byName(entry['festival'] as String);
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

/// 江湖恩怨 + 声望配置(P1.2 GDD §12.1 + §12.2)。
/// numbers.yaml `jianghu` 段;空段兜底 [JianghuConfig.empty]。
class JianghuConfig {
  final List<ReputationTierDef> reputationTiers;
  final EnmityCombatModifier enmityCombatModifier;
  final JianghuTriggers triggers;

  const JianghuConfig({
    required this.reputationTiers,
    required this.enmityCombatModifier,
    required this.triggers,
  });

  /// 空配置兜底(fixture / test yaml 不带 `jianghu` 段):
  /// reputation_tiers 空 + enmity 阈值 0 + triggers 0,Service 端表现为 noop。
  static const JianghuConfig empty = JianghuConfig(
    reputationTiers: [],
    enmityCombatModifier: EnmityCombatModifier.empty,
    triggers: JianghuTriggers.empty,
  );

  factory JianghuConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    final tiersRaw = (y['reputation_tiers'] as List?) ?? const [];
    final tiers = <ReputationTierDef>[];
    for (final raw in tiersRaw) {
      tiers.add(
        ReputationTierDef.fromYaml(Map<String, dynamic>.from(raw as Map)),
      );
    }
    return JianghuConfig(
      reputationTiers: List.unmodifiable(tiers),
      enmityCombatModifier: EnmityCombatModifier.fromYaml(
        (y['enmity_combat_modifier'] as Map?)?.cast<String, dynamic>() ??
            const {},
      ),
      triggers: JianghuTriggers.fromYaml(
        (y['triggers'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

/// 单档声望阶定义(P1.2 §2 · 7 阶沿 §5.2)。
class ReputationTierDef {
  final String tier;
  final int min;
  final int max;
  final String label;

  const ReputationTierDef({
    required this.tier,
    required this.min,
    required this.max,
    required this.label,
  });

  factory ReputationTierDef.fromYaml(Map<String, dynamic> y) {
    return ReputationTierDef(
      tier: y['tier'] as String,
      min: (y['min'] as num).toInt(),
      max: (y['max'] as num).toInt(),
      label: y['label'] as String,
    );
  }
}

/// enmity 战斗 modifier(P1.2 §2 Q4=B)。
/// `clamp_max` 防越 §5.4 红线;Service 端 attackPowerMultFor 返值 ≤ 该值。
class EnmityCombatModifier {
  final int threshold;
  final double playerAttackPowerMult;

  /// 对手 NPC 攻击倍率预留;目前仅 schema 占位,实战代码 0 caller(R5 schema 校验已覆盖)。
  final double enemyAttackPowerMult;
  final int severeThreshold;
  final double severeMult;
  final double clampMax;

  const EnmityCombatModifier({
    required this.threshold,
    required this.playerAttackPowerMult,
    required this.enemyAttackPowerMult,
    required this.severeThreshold,
    required this.severeMult,
    required this.clampMax,
  });

  static const EnmityCombatModifier empty = EnmityCombatModifier(
    threshold: 0,
    playerAttackPowerMult: 1.0,
    enemyAttackPowerMult: 1.0,
    severeThreshold: 0,
    severeMult: 1.0,
    clampMax: 1.0,
  );

  factory EnmityCombatModifier.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    return EnmityCombatModifier(
      threshold: (y['threshold'] as num?)?.toInt() ?? 0,
      playerAttackPowerMult:
          (y['player_attack_power_mult'] as num?)?.toDouble() ?? 1.0,
      enemyAttackPowerMult:
          (y['enemy_attack_power_mult'] as num?)?.toDouble() ?? 1.0,
      severeThreshold: (y['severe_threshold'] as num?)?.toInt() ?? 0,
      severeMult: (y['severe_mult'] as num?)?.toDouble() ?? 1.0,
      clampMax: (y['clamp_max'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// 声望累积 trigger 数值(P1.2 §2 Q3=A+B)。
class JianghuTriggers {
  final int stageBossKillDelta;
  final int stageBossKillRivalDelta;
  final int encounterNpcDeltaMin;
  final int encounterNpcDeltaMax;

  const JianghuTriggers({
    required this.stageBossKillDelta,
    required this.stageBossKillRivalDelta,
    required this.encounterNpcDeltaMin,
    required this.encounterNpcDeltaMax,
  });

  static const JianghuTriggers empty = JianghuTriggers(
    stageBossKillDelta: 0,
    stageBossKillRivalDelta: 0,
    encounterNpcDeltaMin: 0,
    encounterNpcDeltaMax: 0,
  );

  factory JianghuTriggers.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    return JianghuTriggers(
      stageBossKillDelta: (y['stage_boss_kill_delta'] as num?)?.toInt() ?? 0,
      stageBossKillRivalDelta:
          (y['stage_boss_kill_rival_delta'] as num?)?.toInt() ?? 0,
      encounterNpcDeltaMin:
          (y['encounter_npc_delta_min'] as num?)?.toInt() ?? 0,
      encounterNpcDeltaMax:
          (y['encounter_npc_delta_max'] as num?)?.toInt() ?? 0,
    );
  }
}

// =============================================================================
// 1.0 P3.4 SectEvent 强类型定义(T19b 技术债清账 · 沿 JianghuConfig 体例)
// =============================================================================

/// 1.0 P3.4 门派事件配置(spec p3_4_sect_event_spec_2026-05-24)。
///
/// 替原 `numbers.raw['sect_event']` dynamic map(沿 P3.4 spec §9 简化路径,
/// T19b 升强类型清账)。空段兜底 [SectEventDef.empty]。
class SectEventDef {
  final SectTournamentDef tournament;
  final SectReputationDef reputation;
  final SectLevelDef sectLevel;
  final int activeEventsMax;

  const SectEventDef({
    required this.tournament,
    required this.reputation,
    required this.sectLevel,
    required this.activeEventsMax,
  });

  static const SectEventDef empty = SectEventDef(
    tournament: SectTournamentDef.empty,
    reputation: SectReputationDef.empty,
    sectLevel: SectLevelDef.empty,
    activeEventsMax: 3,
  );

  factory SectEventDef.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    return SectEventDef(
      tournament: SectTournamentDef.fromYaml(
        (y['tournament'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      reputation: SectReputationDef.fromYaml(
        (y['reputation'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      sectLevel: SectLevelDef.fromYaml(
        (y['sect_level'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      activeEventsMax: (y['active_events_max'] as num?)?.toInt() ?? 3,
    );
  }
}

class SectTournamentDef {
  final double triggerProbability;
  final int cooldownDays;
  final String triggerRealmMin;
  final int expireDays;

  /// B1 接通:tournament 触发时从此池 rng 选一个 `narrativeId`(FK
  /// `data/lore/sect_event/<id>.yaml`)。空池 → tick 不触发(防空 pick 崩)。
  final List<String> narrativeIds;

  const SectTournamentDef({
    required this.triggerProbability,
    required this.cooldownDays,
    required this.triggerRealmMin,
    required this.expireDays,
    this.narrativeIds = const [],
  });

  static const SectTournamentDef empty = SectTournamentDef(
    triggerProbability: 0.0,
    cooldownDays: 30,
    triggerRealmMin: 'yiLiu',
    expireDays: 7,
    narrativeIds: [],
  );

  factory SectTournamentDef.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    return SectTournamentDef(
      triggerProbability: (y['trigger_probability'] as num?)?.toDouble() ?? 0.0,
      cooldownDays: (y['cooldown_days'] as num?)?.toInt() ?? 30,
      triggerRealmMin: (y['trigger_realm_min'] as String?) ?? 'yiLiu',
      expireDays: (y['expire_days'] as num?)?.toInt() ?? 7,
      narrativeIds:
          (y['narrative_ids'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class SectReputationDef {
  final int initial;
  final int winDelta;
  final int lossDelta;
  final int decayPerMonthIdle;
  final int max;
  final int min;

  const SectReputationDef({
    required this.initial,
    required this.winDelta,
    required this.lossDelta,
    required this.decayPerMonthIdle,
    required this.max,
    required this.min,
  });

  static const SectReputationDef empty = SectReputationDef(
    initial: 50,
    winDelta: 10,
    lossDelta: -5,
    decayPerMonthIdle: 5,
    max: 100,
    min: 0,
  );

  factory SectReputationDef.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    return SectReputationDef(
      initial: (y['initial'] as num?)?.toInt() ?? 50,
      winDelta: (y['win_delta'] as num?)?.toInt() ?? 10,
      lossDelta: (y['loss_delta'] as num?)?.toInt() ?? -5,
      decayPerMonthIdle: (y['decay_per_month_idle'] as num?)?.toInt() ?? 5,
      max: (y['max'] as num?)?.toInt() ?? 100,
      min: (y['min'] as num?)?.toInt() ?? 0,
    );
  }
}

class SectLevelDef {
  final int max;
  final int initial;
  final int promoteWinsThreshold;

  const SectLevelDef({
    required this.max,
    required this.initial,
    required this.promoteWinsThreshold,
  });

  static const SectLevelDef empty = SectLevelDef(
    max: 7,
    initial: 1,
    promoteWinsThreshold: 3,
  );

  factory SectLevelDef.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    return SectLevelDef(
      max: (y['max'] as num?)?.toInt() ?? 7,
      initial: (y['initial'] as num?)?.toInt() ?? 1,
      promoteWinsThreshold: (y['promote_wins_threshold'] as num?)?.toInt() ?? 3,
    );
  }
}

/// P4.1 §12.2 帮派门派强类型配置(spec p4_1_sect_management_spec_2026-05-25 §2)。
///
/// 4 子段聚合:[memberCap](Q2=C member 上限沿 sectLevel)+
/// [rankPromoteThreshold](Q5=A 三阶单向阈值)+ [recruit](Q6=D 三维 trigger 概率)+
/// [territory](Q4=A territory cap)。fixture / 老存档 yaml 无 `sect_management`
/// 段时走 [empty] 兜底,数值与 yaml 默认值同(不破任何运行时行为)。
class SectManagementConfig {
  final SectMemberCapConfig memberCap;
  final SectRankPromoteThresholdConfig rankPromoteThreshold;
  final SectRecruitConfig recruit;
  final SectTerritoryNumbersConfig territory;

  const SectManagementConfig({
    required this.memberCap,
    required this.rankPromoteThreshold,
    required this.recruit,
    required this.territory,
  });

  static const SectManagementConfig empty = SectManagementConfig(
    memberCap: SectMemberCapConfig.empty,
    rankPromoteThreshold: SectRankPromoteThresholdConfig.empty,
    recruit: SectRecruitConfig.empty,
    territory: SectTerritoryNumbersConfig.empty,
  );

  factory SectManagementConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    return SectManagementConfig(
      memberCap: SectMemberCapConfig.fromYaml(
        (y['member_cap'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      rankPromoteThreshold: SectRankPromoteThresholdConfig.fromYaml(
        (y['rank_promote_threshold'] as Map?)?.cast<String, dynamic>() ??
            const {},
      ),
      recruit: SectRecruitConfig.fromYaml(
        (y['recruit'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      territory: SectTerritoryNumbersConfig.fromYaml(
        (y['territory'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

/// Sect.memberCount 上限沿 sectLevel 1-7 阶递进(不含 founder 本人)。
class SectMemberCapConfig {
  final List<int> bySectLevel;

  const SectMemberCapConfig({required this.bySectLevel});

  static const SectMemberCapConfig empty = SectMemberCapConfig(
    bySectLevel: [3, 5, 8, 12, 18, 25, 35],
  );

  factory SectMemberCapConfig.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    final raw = y['by_sect_level'] as List?;
    if (raw == null || raw.isEmpty) return empty;
    return SectMemberCapConfig(
      bySectLevel: raw.map((e) => (e as num).toInt()).toList(growable: false),
    );
  }
}

/// SectRank 三阶单向升迁阈值(totalWins 累积贡献 · 玩家手动指派)。
class SectRankPromoteThresholdConfig {
  final int innerMinContribution; // initiate → inner
  final int elderMinContribution; // inner → elder

  const SectRankPromoteThresholdConfig({
    required this.innerMinContribution,
    required this.elderMinContribution,
  });

  static const SectRankPromoteThresholdConfig empty =
      SectRankPromoteThresholdConfig(
        innerMinContribution: 10,
        elderMinContribution: 30,
      );

  factory SectRankPromoteThresholdConfig.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    return SectRankPromoteThresholdConfig(
      innerMinContribution:
          (y['inner_min_contribution'] as num?)?.toInt() ?? 10,
      elderMinContribution:
          (y['elder_min_contribution'] as num?)?.toInt() ?? 30,
    );
  }
}

/// 多维 trigger 招收 softProbability:encounter / stage_boss recruit(战胜招降)/
/// stage_boss fail recover(战败收降 · P5+/1.1 留) / sect_event mission。
class SectRecruitConfig {
  final double encounterBaseProb; // Q6 A
  final double stageBossRecruitProb; // P4.1 1.1 Q6 B · 战胜 Boss 后招降 NPC rng pick
  final double
  stageBossFailRecoverProb; // P4.1 1.1 战败收降:已实装,stage_boss_recruit_hook 真读(全局 0.30)
  final double missionRecruitProb; // Q7 B

  const SectRecruitConfig({
    required this.encounterBaseProb,
    required this.stageBossRecruitProb,
    required this.stageBossFailRecoverProb,
    required this.missionRecruitProb,
  });

  static const SectRecruitConfig empty = SectRecruitConfig(
    encounterBaseProb: 0.15,
    stageBossRecruitProb: 0.40,
    stageBossFailRecoverProb: 0.30,
    missionRecruitProb: 0.50,
  );

  factory SectRecruitConfig.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    return SectRecruitConfig(
      encounterBaseProb: (y['encounter_base_prob'] as num?)?.toDouble() ?? 0.15,
      stageBossRecruitProb:
          (y['stage_boss_recruit_prob'] as num?)?.toDouble() ?? 0.40,
      stageBossFailRecoverProb:
          (y['stage_boss_fail_recover_prob'] as num?)?.toDouble() ?? 0.30,
      missionRecruitProb:
          (y['mission_recruit_prob'] as num?)?.toDouble() ?? 0.50,
    );
  }
}

/// Q4=A 静态 territory yaml + dynamic owner · `Sect.territoryIds.length` cap。
class SectTerritoryNumbersConfig {
  final int demoInitialCount; // `data/territories.yaml` 静态 def 数量
  final List<int> maxPerSectByLevel; // sectLevel 1-7 阶 cap

  const SectTerritoryNumbersConfig({
    required this.demoInitialCount,
    required this.maxPerSectByLevel,
  });

  static const SectTerritoryNumbersConfig empty = SectTerritoryNumbersConfig(
    demoInitialCount: 6,
    maxPerSectByLevel: [1, 2, 3, 5, 8, 12, 18],
  );

  factory SectTerritoryNumbersConfig.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return empty;
    final raw = y['max_per_sect_by_level'] as List?;
    return SectTerritoryNumbersConfig(
      demoInitialCount: (y['demo_initial_count'] as num?)?.toInt() ?? 6,
      maxPerSectByLevel: raw == null || raw.isEmpty
          ? const [1, 2, 3, 5, 8, 12, 18]
          : raw.map((e) => (e as num).toInt()).toList(growable: false),
    );
  }
}

/// 招式熟练度单个阶段(可玩性 P1a · spec §三)。
class SkillProficiencyStageConfig {
  final String id;
  final int minUses;
  final double damageMult;
  const SkillProficiencyStageConfig({
    required this.id,
    required this.minUses,
    required this.damageMult,
  });

  factory SkillProficiencyStageConfig.fromYaml(Map<String, dynamic> y) =>
      SkillProficiencyStageConfig(
        id: y['id'] as String,
        minUses: (y['min_uses'] as num).toInt(),
        damageMult: (y['damage_mult'] as num).toDouble(),
      );
}

/// 招式熟练度阶段配置(可玩性 P1a · spec §三/§2.5)。
/// `combat.skill_proficiency.stages`;末阶 damageMult 作综合加成 cap。
class SkillProficiencyConfig {
  final List<SkillProficiencyStageConfig> stages;
  const SkillProficiencyConfig({required this.stages});

  double get maxDamageMult =>
      stages.map((s) => s.damageMult).reduce((a, b) => a > b ? a : b);

  factory SkillProficiencyConfig.fromYaml(Map<String, dynamic>? y) {
    final raw = (y?['stages'] as List?) ?? const [];
    final stages = raw
        .map(
          (e) => SkillProficiencyStageConfig.fromYaml(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(growable: false);
    // 单调红线:min_uses 严格递增 + damage_mult 不可递减
    for (var i = 1; i < stages.length; i++) {
      if (stages[i].minUses <= stages[i - 1].minUses) {
        throw StateError('skill_proficiency.stages min_uses 必须严格递增');
      }
      if (stages[i].damageMult < stages[i - 1].damageMult) {
        throw StateError('skill_proficiency.stages damage_mult 不可递减');
      }
    }
    return SkillProficiencyConfig(stages: stages);
  }
}

/// 战后英雄镜头表现参数(第七阶段 批一)。顶层 `post_battle.hero_camera` 段。
class HeroCameraConfig {
  final double holdSeconds;
  final double portraitSlidePx;
  final double portraitScaleFrom;
  const HeroCameraConfig({
    required this.holdSeconds,
    required this.portraitSlidePx,
    required this.portraitScaleFrom,
  });

  // 默认须与 numbers.yaml post_battle.hero_camera 保持一致(双源,改一处记得改另一处)。
  static const empty = HeroCameraConfig(
    holdSeconds: 3.0,
    portraitSlidePx: 48,
    portraitScaleFrom: 0.88,
  );

  factory HeroCameraConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    return HeroCameraConfig(
      holdSeconds: (y['hold_seconds'] as num?)?.toDouble() ?? empty.holdSeconds,
      portraitSlidePx:
          (y['portrait_slide_px'] as num?)?.toDouble() ?? empty.portraitSlidePx,
      portraitScaleFrom:
          (y['portrait_scale_from'] as num?)?.toDouble() ??
          empty.portraitScaleFrom,
    );
  }
}

/// 爆品展示动画门槛(2026-06-11)。顶层 `treasure_drop` 段。
class TreasureDropConfig {
  final EquipmentTier minTier;
  const TreasureDropConfig({required this.minTier});

  // 默认须与 numbers.yaml treasure_drop.min_tier 保持一致(双源,改一处记得改另一处)。
  static const empty = TreasureDropConfig(minTier: EquipmentTier.zhongQi);

  factory TreasureDropConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    final name = y['min_tier'] as String?;
    if (name == null) return empty;
    return TreasureDropConfig(minTier: EquipmentTier.values.byName(name));
  }
}

/// 招式解锁配置(可玩性 P1a · spec §二)。顶层 `skill_unlock` 段。
class SkillUnlockConfig {
  final int fragmentThreshold;
  final double towerFragmentDropProb;
  const SkillUnlockConfig({
    required this.fragmentThreshold,
    required this.towerFragmentDropProb,
  });

  static const empty = SkillUnlockConfig(
    fragmentThreshold: 5,
    towerFragmentDropProb: 0.20,
  );

  factory SkillUnlockConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    return SkillUnlockConfig(
      fragmentThreshold: (y['fragment_threshold'] as num?)?.toInt() ?? 5,
      towerFragmentDropProb:
          (y['tower_fragment_drop_prob'] as num?)?.toDouble() ?? 0.20,
    );
  }
}

// =============================================================================
// 周目进化配置 (P1 cycle_evolution · numbers.yaml `cycle_evolution`)
// 全部数值数据驱动（§5.6 不硬编码）。
// =============================================================================

/// 御体词条参数（防御率按周目分档加成）。
class YutiTraitParams {
  final double defenseRateBonusC2;
  final double defenseRateBonusC3;

  const YutiTraitParams({
    required this.defenseRateBonusC2,
    required this.defenseRateBonusC3,
  });

  factory YutiTraitParams.fromYaml(Map<String, dynamic> y) => YutiTraitParams(
    defenseRateBonusC2: (y['defense_rate_bonus_c2'] as num).toDouble(),
    defenseRateBonusC3: (y['defense_rate_bonus_c3'] as num).toDouble(),
  );
}

/// 反震词条参数（受击反伤 DoT）。
class FanzhenTraitParams {
  final int damagePerTick;
  final int ticks;

  const FanzhenTraitParams({required this.damagePerTick, required this.ticks});

  factory FanzhenTraitParams.fromYaml(Map<String, dynamic> y) =>
      FanzhenTraitParams(
        damagePerTick: (y['damage_per_tick'] as num).toInt(),
        ticks: (y['ticks'] as num).toInt(),
      );
}

/// 凝甲词条参数（受暴击伤害减免倍率）。
class NingjiaTraitParams {
  final double critDamageTakenMult;

  const NingjiaTraitParams({required this.critDamageTakenMult});

  factory NingjiaTraitParams.fromYaml(Map<String, dynamic> y) =>
      NingjiaTraitParams(
        critDamageTakenMult: (y['crit_damage_taken_mult'] as num).toDouble(),
      );
}

/// 真气词条参数（内力上限 ×(1+pct)，→ 多放一次大招；非战斗开场回复）。
class ZhenqiTraitParams {
  final double internalForcePct;

  const ZhenqiTraitParams({required this.internalForcePct});

  factory ZhenqiTraitParams.fromYaml(Map<String, dynamic> y) =>
      ZhenqiTraitParams(
        internalForcePct: (y['internal_force_pct'] as num).toDouble(),
      );
}

/// 识破词条参数（复用既有蓄力破招技 id）。
class ShipoTraitParams {
  final String chargeSkillId;

  const ShipoTraitParams({required this.chargeSkillId});

  factory ShipoTraitParams.fromYaml(Map<String, dynamic> y) =>
      ShipoTraitParams(chargeSkillId: y['charge_skill_id'] as String);
}

/// 全部反制词条参数容器（numbers.yaml `cycle_evolution.traits`）。
class CycleTraitsConfig {
  final YutiTraitParams yuti;
  final FanzhenTraitParams fanzhen;
  final NingjiaTraitParams ningjia;
  final ZhenqiTraitParams zhenqi;
  final ShipoTraitParams shipo;

  const CycleTraitsConfig({
    required this.yuti,
    required this.fanzhen,
    required this.ningjia,
    required this.zhenqi,
    required this.shipo,
  });

  factory CycleTraitsConfig.fromYaml(Map<String, dynamic> y) =>
      CycleTraitsConfig(
        yuti: YutiTraitParams.fromYaml(
          (y['yuti'] as Map).cast<String, dynamic>(),
        ),
        fanzhen: FanzhenTraitParams.fromYaml(
          (y['fanzhen'] as Map).cast<String, dynamic>(),
        ),
        ningjia: NingjiaTraitParams.fromYaml(
          (y['ningjia'] as Map).cast<String, dynamic>(),
        ),
        zhenqi: ZhenqiTraitParams.fromYaml(
          (y['zhenqi'] as Map).cast<String, dynamic>(),
        ),
        shipo: ShipoTraitParams.fromYaml(
          (y['shipo'] as Map).cast<String, dynamic>(),
        ),
      );
}

/// 周目进化主配置（numbers.yaml `cycle_evolution`，P1 spec）。
///
/// 敌人随挂机周目数自动强化，全部参数数据驱动（§5.6 不硬编码）。
/// [traitsFor] 纯函数（无 I/O），根据 (cycle, isBoss, isTower) 查 assignment 表
/// 返回该场景激活的词条 id 集合；cycle ≤ 1 时返回空集。
///
/// 解析 assignment 时兼容 yaml int key 与 String key（yaml int key 解析后可能为
/// int 或 String，两者均处理）。
class CycleEvolutionConfig {
  /// 每周目敌人基础属性缩放增幅（如 0.06 = +6%/周目）。
  final double scalePerCycle;

  /// 主线最大周目数。
  final int maxCycleMainline;

  /// 爬塔最大周目数。
  final int maxCycleTower;

  /// 敌人防御率上限（防越 §5.4 红线）。
  final double defenseRateCap;

  /// 反制词条参数容器。
  final CycleTraitsConfig traits;

  /// assignment 表：`{ tableKey → { cycle → [traitId] } }`。
  /// tableKey ∈ {'mainline', 'tower_normal', 'tower_boss'}。
  final Map<String, Map<int, Set<String>>> _assignment;

  const CycleEvolutionConfig({
    required this.scalePerCycle,
    required this.maxCycleMainline,
    required this.maxCycleTower,
    required this.defenseRateCap,
    required this.traits,
    required Map<String, Map<int, Set<String>>> assignment,
  }) : _assignment = assignment;

  /// 空配置兜底（fixture / test yaml 不带 `cycle_evolution` 段时）。
  /// 所有 traitsFor 返回空集，不破坏既有测试。
  static const CycleEvolutionConfig empty = CycleEvolutionConfig(
    scalePerCycle: 0.0,
    maxCycleMainline: 1,
    maxCycleTower: 1,
    defenseRateCap: 0.6,
    traits: CycleTraitsConfig(
      yuti: YutiTraitParams(defenseRateBonusC2: 0.0, defenseRateBonusC3: 0.0),
      fanzhen: FanzhenTraitParams(damagePerTick: 0, ticks: 0),
      ningjia: NingjiaTraitParams(critDamageTakenMult: 1.0),
      zhenqi: ZhenqiTraitParams(internalForcePct: 0.0),
      shipo: ShipoTraitParams(chargeSkillId: ''),
    ),
    assignment: {},
  );

  factory CycleEvolutionConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    return CycleEvolutionConfig(
      scalePerCycle: (y['scale_per_cycle'] as num).toDouble(),
      maxCycleMainline: (y['max_cycle_mainline'] as num).toInt(),
      maxCycleTower: (y['max_cycle_tower'] as num).toInt(),
      defenseRateCap: (y['defense_rate_cap'] as num).toDouble(),
      traits: CycleTraitsConfig.fromYaml(
        (y['traits'] as Map).cast<String, dynamic>(),
      ),
      assignment: _parseAssignment(
        (y['assignment'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  static Map<String, Map<int, Set<String>>> _parseAssignment(
    Map<String, dynamic> raw,
  ) {
    final result = <String, Map<int, Set<String>>>{};
    for (final tableEntry in raw.entries) {
      final tableKey = tableEntry.key; // e.g. 'mainline'
      final tableMap = (tableEntry.value as Map).cast<Object, dynamic>();
      final cycleMap = <int, Set<String>>{};
      for (final cycleEntry in tableMap.entries) {
        // yaml int keys may parse as int or String — handle both
        final cycleKey = cycleEntry.key is int
            ? cycleEntry.key as int
            : int.parse(cycleEntry.key.toString());
        final traitList = (cycleEntry.value as List)
            .map((e) => e as String)
            .toSet();
        cycleMap[cycleKey] = traitList;
      }
      result[tableKey] = cycleMap;
    }
    return result;
  }

  /// 纯函数：返回给定 (cycle, isBoss, isTower) 场景激活的词条 id 集合。
  ///
  /// - cycle ≤ 1 → 空集（无强化）
  /// - 查表顺序：isTower ? (isBoss ? 'tower_boss' : 'tower_normal') : 'mainline'
  /// - 对应 cycle 无 entry → 空集
  Set<String> traitsFor({
    required int cycle,
    required bool isBoss,
    required bool isTower,
  }) {
    if (cycle <= 1) return const {};
    final tableKey = isTower
        ? (isBoss ? 'tower_boss' : 'tower_normal')
        : 'mainline';
    return _assignment[tableKey]?[cycle] ?? const {};
  }
}

/// M2 范围 B 通用被动离线挂机配置（numbers.yaml `passive_idle`）。
class PassiveIdleConfig {
  final double baseMojianshiPerHour;
  final double baseExpPerHour;
  final double realmScalePerTier;
  final int capHours;
  final double minRecapHours;

  const PassiveIdleConfig({
    required this.baseMojianshiPerHour,
    required this.baseExpPerHour,
    required this.realmScalePerTier,
    required this.capHours,
    required this.minRecapHours,
  });

  /// 境界缩放：每升一大境界 ×realmScalePerTier。学徒(index 0)=1.0。
  double realmScaleFor(RealmTier tier) =>
      math.pow(realmScalePerTier, tier.index).toDouble();

  factory PassiveIdleConfig.fromYaml(Map<String, dynamic> y) {
    final base = (y['base_mojianshi_per_hour'] as num).toDouble();
    final exp = (y['base_exp_per_hour'] as num).toDouble();
    final scale = (y['realm_scale_per_tier'] as num).toDouble();
    final cap = (y['cap_hours'] as num).toInt();
    final minRecap = (y['min_recap_hours'] as num).toDouble();
    if (base < 0 || exp < 0 || scale <= 0 || cap <= 0 || minRecap < 0) {
      throw ArgumentError('passive_idle 数值非法: $y');
    }
    return PassiveIdleConfig(
      baseMojianshiPerHour: base,
      baseExpPerHour: exp,
      realmScalePerTier: scale,
      capHours: cap,
      minRecapHours: minRecap,
    );
  }
}

/// 战报失败诊断阈值（spec 2026-06-15-battle-report-diagnosis）。
/// 规则 id/priority 写死在 battle_diagnosis.dart；此处只承载可调阈值。
class BattleReportConfig {
  final double internalWoundPct;
  final double minionDamagePct;
  final double frontlineDeathPhasePct;
  final double survivorHpPct;

  const BattleReportConfig({
    required this.internalWoundPct,
    required this.minionDamagePct,
    required this.frontlineDeathPhasePct,
    required this.survivorHpPct,
  });

  factory BattleReportConfig.fromYaml(Map<String, dynamic> y) {
    double pct(String k) => (y[k] as num).toDouble();
    final iw = pct('internal_wound_pct');
    final md = pct('minion_damage_pct');
    final fd = pct('frontline_death_phase_pct');
    final sv = pct('survivor_hp_pct');
    bool ok(double v) => v > 0 && v <= 1;
    if (!ok(iw) || !ok(md) || !ok(fd) || !ok(sv)) {
      throw ArgumentError('battle_report 阈值须在 (0,1]: $y');
    }
    return BattleReportConfig(
      internalWoundPct: iw,
      minionDamagePct: md,
      frontlineDeathPhasePct: fd,
      survivorHpPct: sv,
    );
  }
}

// =============================================================================
// 第七阶段批三·队伍成长:命名弟子拜入触发表。
// =============================================================================

/// 单个弟子的拜入触发定义。
class DiscipleJoinDef {
  final String stageId;
  final int masterSlotIndex; // masters.yaml slotIndex(1=大弟子/2=二弟子)
  final LineageRole role;
  final String narrativeId;
  const DiscipleJoinDef({
    required this.stageId,
    required this.masterSlotIndex,
    required this.role,
    required this.narrativeId,
  });
  factory DiscipleJoinDef.fromYaml(Map<String, dynamic> y) => DiscipleJoinDef(
    stageId: y['stage_id'] as String,
    masterSlotIndex: (y['master_slot_index'] as num).toInt(),
    role: LineageRole.values.byName(y['role'] as String),
    narrativeId: y['narrative_id'] as String,
  );
}

/// 命名弟子拜入触发表（numbers.yaml `lineage_onboarding`）。
///
/// 开局单人，弟子按主线关卡节点拜入。null yaml → 空配置（default-safe）。
class LineageOnboardingConfig {
  final List<DiscipleJoinDef> discipleJoins;
  const LineageOnboardingConfig({this.discipleJoins = const []});
  Set<String> get joinStageIds => discipleJoins.map((j) => j.stageId).toSet();
  factory LineageOnboardingConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return const LineageOnboardingConfig();
    final raw = (y['disciple_joins'] as List?) ?? const [];
    return LineageOnboardingConfig(
      discipleJoins: raw
          .map(
            (e) =>
                DiscipleJoinDef.fromYaml(Map<String, dynamic>.from(e as Map)),
          )
          .toList(growable: false),
    );
  }
}
