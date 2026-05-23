import '../../../core/domain/enums.dart';

/// 轻功对决配置(1.0 P3.1 §12.3,GDD v1.11,data/numbers.yaml `light_foot` 段强类型化)。
///
/// 5 关 `stage_light_foot_01..05` 跨 yiLiu(qiMeng/jingTong/dengFeng)+
/// jueDing(qiMeng/jingTong)2 Tier × 3 terrain(water/rooftop/bamboo)
/// 平行支线,**不接管 wuSheng 突破链**(`isLayerLocked` 无 lightFoot 路径)。
///
/// Schema:
///   - [terrainModifiers]:3 terrain × {crit/evasion/defense/damage} delta(双方对等)
///   - [stageTerrain]:stage_id → TerrainBiome 映射(冗余于 stages.yaml,加速 lookup)
///   - [unlockTriggers]:触发关 victory → 下一关 unlock 链
///
/// fixture 兼容:numbers.yaml 不含 `light_foot` 段时走 [LightFootDef.empty]
/// (所有 Map 空 / 默认 0 delta,行为同 1.0 P3 前)。
class LightFootDef {
  /// terrain → modifier(LightFootStrategy 烘焙到 BattleCharacter stat 入参)。
  final Map<TerrainBiome, LightFootTerrainModifier> terrainModifiers;

  /// stage_id → terrainBiome(冗余于 stages.yaml `terrainBiome` 字段)。
  final Map<String, TerrainBiome> stageTerrain;

  /// 触发关 victory → 下一关 unlock(如 stage_06_05 → stage_light_foot_01)。
  final Map<String, String> unlockTriggers;

  const LightFootDef({
    required this.terrainModifiers,
    required this.stageTerrain,
    required this.unlockTriggers,
  });

  /// numbers.yaml 不含 `light_foot` 段时的空值(fixture 兼容)。
  factory LightFootDef.empty() => const LightFootDef(
        terrainModifiers: {},
        stageTerrain: {},
        unlockTriggers: {},
      );

  factory LightFootDef.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return LightFootDef.empty();

    final modifiers = <TerrainBiome, LightFootTerrainModifier>{};
    final modifiersYaml = y['terrain_modifiers'] as Map?;
    if (modifiersYaml != null) {
      for (final e in modifiersYaml.entries) {
        final biome = TerrainBiome.values.byName(e.key as String);
        modifiers[biome] = LightFootTerrainModifier.fromYaml(
          Map<String, dynamic>.from(e.value as Map),
        );
      }
    }

    final stageTerrain = <String, TerrainBiome>{};
    final stageYaml = y['stage_terrain'] as Map?;
    if (stageYaml != null) {
      for (final e in stageYaml.entries) {
        stageTerrain[e.key as String] =
            TerrainBiome.values.byName(e.value as String);
      }
    }

    final unlocks = <String, String>{};
    final unlocksYaml = y['unlock_triggers'] as Map?;
    if (unlocksYaml != null) {
      for (final e in unlocksYaml.entries) {
        unlocks[e.key as String] = e.value as String;
      }
    }

    return LightFootDef(
      terrainModifiers: modifiers,
      stageTerrain: stageTerrain,
      unlockTriggers: unlocks,
    );
  }
}

/// 单 terrain 的 modifier 配置。烘焙到 BattleCharacter critRate/evasionRate/
/// defenseRate(LightFootStrategy 入口 _bake),damage_multiplier 留 P3.1.B
/// 子批接 damage_calculator(本批 YAGNI,3 项 delta 已能拉开分布)。
class LightFootTerrainModifier {
  /// 暴击率 delta(±0.10 量级,clamp ≤0.95)。
  final double criticalRateDelta;

  /// 闪避率 delta(±0.15-0.20 量级,clamp ≤0.95)。
  final double evasionRateDelta;

  /// 防御率 delta(±0.05-0.10 量级,clamp ≤0.95)。
  final double defenseRateDelta;

  /// 伤害乘数(P3.1.B 子批接 damage_calculator,本批不消费但加载)。
  final double damageMultiplier;

  const LightFootTerrainModifier({
    required this.criticalRateDelta,
    required this.evasionRateDelta,
    required this.defenseRateDelta,
    required this.damageMultiplier,
  });

  /// 中性 modifier(无地形 / 默认平地,全 0/1)。
  factory LightFootTerrainModifier.neutral() => const LightFootTerrainModifier(
        criticalRateDelta: 0.0,
        evasionRateDelta: 0.0,
        defenseRateDelta: 0.0,
        damageMultiplier: 1.0,
      );

  factory LightFootTerrainModifier.fromYaml(Map<String, dynamic> y) =>
      LightFootTerrainModifier(
        criticalRateDelta:
            (y['critical_rate_delta'] as num?)?.toDouble() ?? 0.0,
        evasionRateDelta:
            (y['evasion_rate_delta'] as num?)?.toDouble() ?? 0.0,
        defenseRateDelta:
            (y['defense_rate_delta'] as num?)?.toDouble() ?? 0.0,
        damageMultiplier:
            (y['damage_multiplier'] as num?)?.toDouble() ?? 1.0,
      );
}
