import '../../../core/domain/enums.dart';

/// 心魔系统配置（1.0 P2.2 §12.1，data/numbers.yaml `inner_demon` 段强类型化）。
///
/// 7 关心魔(stage_inner_demon_01..07)拦截 wuSheng 7 层突破：
///   - mirror_buff_per_stage：各关镜像玩家 character 强化比例
///   - mirror_caps：§5.4 数值红线 cap（防玩家 build 超时镜像也超）
///   - failure_penalty：散功 ×0.5 阉割版（GDD §6 半惩罚）
///   - residue_debuff：心魔余毒 buff 效果（闭关 8h 清）
///   - unlock_triggers：触发关 victory → 下一关 unlock 链
///   - required_realm_layer：玩家当前境界达到该 layer 才能进入
///
/// fixture 兼容：numbers.yaml 不含 inner_demon 段时走 [InnerDemonDef.empty]
/// （所有 Map 空、InnerDemonService.isLayerLocked 始终返 false → 行为同 1.0 前）。
class InnerDemonDef {
  /// stage_id → 镜像强化比例（如 stage_inner_demon_01 → 0.10）。
  final Map<String, double> mirrorBuffPerStage;

  /// §5.4 数值红线 cap。
  final InnerDemonMirrorCaps mirrorCaps;

  /// 失败惩罚（散功 ×0.5 阉割版）。
  final InnerDemonFailurePenalty failurePenalty;

  /// 心魔余毒 buff 效果。
  final InnerDemonResidueDebuff residueDebuff;

  /// 触发关 victory → 下一关 unlock 链（如 stage_06_05 → stage_inner_demon_01）。
  final Map<String, String> unlockTriggers;

  /// stage_id → 玩家当前境界达到该 layer 才能进入（如 stage_inner_demon_01 →
  /// wuSheng·qiMeng）。
  final Map<String, RealmCoord> requiredRealmLayer;

  const InnerDemonDef({
    required this.mirrorBuffPerStage,
    required this.mirrorCaps,
    required this.failurePenalty,
    required this.residueDebuff,
    required this.unlockTriggers,
    required this.requiredRealmLayer,
  });

  /// numbers.yaml 不含 `inner_demon` 段时的空值（fixture 兼容 + Demo 路径无心魔）。
  ///
  /// 所有 Map 空 → InnerDemonService.isLayerLocked 始终返 false，不破现有
  /// applyExperience while-loop 升层行为。
  factory InnerDemonDef.empty() => const InnerDemonDef(
        mirrorBuffPerStage: {},
        mirrorCaps: InnerDemonMirrorCaps(
          hpMax: 20000,
          internalForceMax: 15000,
          attackPowerMax: 6000,
        ),
        failurePenalty: InnerDemonFailurePenalty(
          internalForceMultiplier: 0.85,
          mainCultivationMultiplier: 0.90,
          subCultivationMultiplier: 1.00,
          debuffId: 'inner_demon_residue',
          debuffClearViaRetreatHours: 8,
          internalForceFloorPct: 0.50,
        ),
        residueDebuff: InnerDemonResidueDebuff(
          battleOutputMultiplier: 0.95,
          internalForceRecoveryMultiplier: 0.80,
        ),
        unlockTriggers: {},
        requiredRealmLayer: {},
      );

  factory InnerDemonDef.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return InnerDemonDef.empty();

    final mirror = <String, double>{};
    final mirrorYaml = y['mirror_buff_per_stage'] as Map?;
    if (mirrorYaml != null) {
      for (final e in mirrorYaml.entries) {
        mirror[e.key as String] = (e.value as num).toDouble();
      }
    }

    final unlocks = <String, String>{};
    final unlocksYaml = y['unlock_triggers'] as Map?;
    if (unlocksYaml != null) {
      for (final e in unlocksYaml.entries) {
        unlocks[e.key as String] = e.value as String;
      }
    }

    final required = <String, RealmCoord>{};
    final requiredYaml = y['required_realm_layer'] as Map?;
    if (requiredYaml != null) {
      for (final e in requiredYaml.entries) {
        final v = e.value as Map;
        required[e.key as String] = RealmCoord(
          tier: RealmTier.values.byName(v['tier'] as String),
          layer: RealmLayer.values.byName(v['layer'] as String),
        );
      }
    }

    return InnerDemonDef(
      mirrorBuffPerStage: mirror,
      mirrorCaps: InnerDemonMirrorCaps.fromYaml(
        y['mirror_caps'] as Map<String, dynamic>? ?? const {},
      ),
      failurePenalty: InnerDemonFailurePenalty.fromYaml(
        y['failure_penalty'] as Map<String, dynamic>? ?? const {},
      ),
      residueDebuff: InnerDemonResidueDebuff.fromYaml(
        y['residue_debuff'] as Map<String, dynamic>? ?? const {},
      ),
      unlockTriggers: unlocks,
      requiredRealmLayer: required,
    );
  }
}

/// (tier, layer) record 别名 — 与 character_advancement_service.nextLayer 返回值
/// 同构（避免引入新结构）。
class RealmCoord {
  final RealmTier tier;
  final RealmLayer layer;
  const RealmCoord({required this.tier, required this.layer});

  @override
  bool operator ==(Object other) =>
      other is RealmCoord && other.tier == tier && other.layer == layer;

  @override
  int get hashCode => Object.hash(tier, layer);
}

/// §5.4 数值红线 cap（防玩家 build 超时镜像也超）。
class InnerDemonMirrorCaps {
  final int hpMax;
  final int internalForceMax;
  final int attackPowerMax;
  const InnerDemonMirrorCaps({
    required this.hpMax,
    required this.internalForceMax,
    required this.attackPowerMax,
  });

  factory InnerDemonMirrorCaps.fromYaml(Map<String, dynamic> y) =>
      InnerDemonMirrorCaps(
        hpMax: (y['hp_max'] as num?)?.toInt() ?? 20000,
        internalForceMax: (y['internal_force_max'] as num?)?.toInt() ?? 15000,
        attackPowerMax: (y['attack_power_max'] as num?)?.toInt() ?? 6000,
      );
}

/// 失败惩罚（散功 ×0.5 阉割版，GDD §6 半惩罚）。
class InnerDemonFailurePenalty {
  /// 当前内力扣减比例（new = old × 此值；0.85 = 扣 15%）。
  final double internalForceMultiplier;

  /// 主修心法修炼度扣减比例（new = old × 此值；0.90 = 扣 10%）。
  final double mainCultivationMultiplier;

  /// 辅修不受影响（1.00 = 不动）。
  final double subCultivationMultiplier;

  /// 心魔余毒 debuff id。
  final String debuffId;

  /// 闭关 N 小时清解 debuff。
  final int debuffClearViaRetreatHours;

  /// 内力扣减地板（new 内力不低于 internalForceMax × 此值；防无限重试归零）。
  final double internalForceFloorPct;

  const InnerDemonFailurePenalty({
    required this.internalForceMultiplier,
    required this.mainCultivationMultiplier,
    required this.subCultivationMultiplier,
    required this.debuffId,
    required this.debuffClearViaRetreatHours,
    required this.internalForceFloorPct,
  });

  factory InnerDemonFailurePenalty.fromYaml(Map<String, dynamic> y) =>
      InnerDemonFailurePenalty(
        internalForceMultiplier:
            (y['internal_force_multiplier'] as num?)?.toDouble() ?? 0.85,
        mainCultivationMultiplier:
            (y['main_cultivation_multiplier'] as num?)?.toDouble() ?? 0.90,
        subCultivationMultiplier:
            (y['sub_cultivation_multiplier'] as num?)?.toDouble() ?? 1.00,
        debuffId: y['debuff_id'] as String? ?? 'inner_demon_residue',
        debuffClearViaRetreatHours:
            (y['debuff_clear_via_retreat_hours'] as num?)?.toInt() ?? 8,
        internalForceFloorPct:
            (y['internal_force_floor_pct'] as num?)?.toDouble() ?? 0.50,
      );
}

/// 心魔余毒 buff 效果（闭关 8h 清）。
class InnerDemonResidueDebuff {
  /// 战斗输出乘数（0.95 = -5%）。
  final double battleOutputMultiplier;

  /// 内力恢复乘数（0.80 = -20%）。
  final double internalForceRecoveryMultiplier;

  const InnerDemonResidueDebuff({
    required this.battleOutputMultiplier,
    required this.internalForceRecoveryMultiplier,
  });

  factory InnerDemonResidueDebuff.fromYaml(Map<String, dynamic> y) =>
      InnerDemonResidueDebuff(
        battleOutputMultiplier:
            (y['battle_output_multiplier'] as num?)?.toDouble() ?? 0.95,
        internalForceRecoveryMultiplier:
            (y['internal_force_recovery_multiplier'] as num?)?.toDouble() ??
                0.80,
      );
}
