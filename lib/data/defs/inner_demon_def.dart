import '../../core/domain/enums.dart';
import 'boss_vulnerability_def.dart';

/// 心魔系统配置（1.0 P2.2 §12.1，data/numbers.yaml `inner_demon` 段强类型化）。
///
/// 7 关心魔(stage_inner_demon_01..07)拦截配置的境界层突破：
///   - mirror_buff_per_stage：各关镜像玩家 character 强化比例
///   - mirror_caps：§5.4 数值红线 cap（防玩家 build 超时镜像也超）
///   - failure_penalty：主修修炼度惩罚（内息紊乱走独立配置）
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

  /// 失败惩罚（主修修炼度系数）。
  final InnerDemonFailurePenalty failurePenalty;

  /// 触发关 victory → 下一关 unlock 链。
  final Map<String, String> unlockTriggers;

  /// stage_id → 玩家被拦截时的当前境界层。
  final Map<String, RealmCoord> requiredRealmLayer;

  /// 终局机制型 Boss 批次3 · 高层心魔关（05/06/07）镜像脆弱窗口配置。
  /// stage_id → 承伤乘子 def（窗口外 ×mult 减伤）。空 = 该关镜像无机制（01-04）。
  /// 复用批次1 BossVulnerabilityDef（schema [0.05,1.0]）。
  final Map<String, BossVulnerabilityDef> mirrorVulnerabilityPerStage;

  /// 注入配了 vulnerability 的镜像的蓄力技 id（周期性蓄力开窗，CD 复发）。
  /// null = 无机制化心魔关。配了 mirrorVulnerabilityPerStage 必配此项（否则永不
  /// 开窗=永久免疫无解，fromYaml 跨字段校验 fail-fast）。
  final String? mirrorChargeSkillId;

  /// 机制化心魔（配 vulnerability 的 05/06/07）镜像攻击倍率。
  /// 纯镜像关继续使用 `1 + mirror_buff`；机制关用此倍率避免同款高爆发镜像
  /// 先手秒杀，把挑战重心放回窗口/撑关。
  final double mechanicMirrorAttackMultiplier;

  /// 机制化心魔逐关总输出倍率。未配置的关保持 1.0，避免影响终关生存路线。
  final Map<String, double> mechanicMirrorOutputMultiplierPerStage;

  /// 机制化心魔镜像起手行动条。负数表示延后起手，给爆发流一次窗口。
  /// 纯镜像关仍从 0 起手。
  final int mechanicMirrorStartActionPoint;

  const InnerDemonDef({
    required this.mirrorBuffPerStage,
    required this.mirrorCaps,
    required this.failurePenalty,
    required this.unlockTriggers,
    required this.requiredRealmLayer,
    this.mirrorVulnerabilityPerStage = const {},
    this.mirrorChargeSkillId,
    this.mechanicMirrorAttackMultiplier = 1.0,
    this.mechanicMirrorOutputMultiplierPerStage = const {},
    this.mechanicMirrorStartActionPoint = 0,
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
    failurePenalty: InnerDemonFailurePenalty(mainCultivationMultiplier: 0.90),
    unlockTriggers: {},
    requiredRealmLayer: {},
    mirrorVulnerabilityPerStage: {},
    mirrorChargeSkillId: null,
    mechanicMirrorAttackMultiplier: 1.0,
    mechanicMirrorOutputMultiplierPerStage: {},
    mechanicMirrorStartActionPoint: 0,
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

    final vuln = <String, BossVulnerabilityDef>{};
    final vulnYaml = y['mirror_vulnerability_per_stage'] as Map?;
    if (vulnYaml != null) {
      for (final e in vulnYaml.entries) {
        vuln[e.key as String] = BossVulnerabilityDef.fromYaml(
          Map<String, dynamic>.from(e.value as Map),
        );
      }
    }
    final chargeSkillId = y['mirror_charge_skill_id'] as String?;
    if (vuln.isNotEmpty && chargeSkillId == null) {
      throw StateError(
        'inner_demon: 配了 mirror_vulnerability_per_stage '
        '(${vuln.keys.join(",")}) 但缺 mirror_charge_skill_id（永不开窗=无解）',
      );
    }
    final mechanicAttackMultiplier =
        (y['mechanic_mirror_attack_multiplier'] as num?)?.toDouble() ?? 1.0;
    if (mechanicAttackMultiplier <= 0 || mechanicAttackMultiplier > 1.0) {
      throw StateError(
        'inner_demon.mechanic_mirror_attack_multiplier 必须在 (0,1]，'
        '实际=$mechanicAttackMultiplier',
      );
    }
    final mechanicOutputPerStage = <String, double>{};
    final mechanicOutputYaml =
        y['mechanic_mirror_output_multiplier_per_stage'] as Map?;
    if (mechanicOutputYaml != null) {
      for (final entry in mechanicOutputYaml.entries) {
        final multiplier = (entry.value as num).toDouble();
        if (multiplier <= 0 || multiplier > 1.0) {
          throw StateError(
            'inner_demon.mechanic_mirror_output_multiplier_per_stage '
            '${entry.key} 必须在 (0,1]，实际=$multiplier',
          );
        }
        mechanicOutputPerStage[entry.key as String] = multiplier;
      }
    }
    final mechanicStartActionPoint =
        (y['mechanic_mirror_start_action_point'] as num?)?.toInt() ?? 0;

    return InnerDemonDef(
      mirrorBuffPerStage: mirror,
      mirrorCaps: InnerDemonMirrorCaps.fromYaml(
        y['mirror_caps'] as Map<String, dynamic>? ?? const {},
      ),
      failurePenalty: InnerDemonFailurePenalty.fromYaml(
        y['failure_penalty'] as Map<String, dynamic>? ?? const {},
      ),
      unlockTriggers: unlocks,
      requiredRealmLayer: required,
      mirrorVulnerabilityPerStage: vuln,
      mirrorChargeSkillId: chargeSkillId,
      mechanicMirrorAttackMultiplier: mechanicAttackMultiplier,
      mechanicMirrorOutputMultiplierPerStage: mechanicOutputPerStage,
      mechanicMirrorStartActionPoint: mechanicStartActionPoint,
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

/// 心魔失败惩罚：主修修炼度系数；内息紊乱由独立配置提供。
class InnerDemonFailurePenalty {
  /// 主修心法修炼度扣减比例（new = old × 此值；0.90 = 扣 10%）。
  final double mainCultivationMultiplier;

  const InnerDemonFailurePenalty({required this.mainCultivationMultiplier});

  factory InnerDemonFailurePenalty.fromYaml(Map<String, dynamic> y) {
    const legacyKeys = {
      'internal_force_multiplier',
      'internal_force_floor_pct',
      'sub_cultivation_multiplier',
      'debuff_id',
      'debuff_clear_via_retreat_hours',
    };
    for (final key in legacyKeys) {
      if (y.containsKey(key)) {
        throw FormatException(
          'inner_demon.failure_penalty contains retired key: $key',
        );
      }
    }
    final multiplier = (y['main_cultivation_multiplier'] as num?)?.toDouble();
    if (multiplier == null ||
        !multiplier.isFinite ||
        multiplier <= 0 ||
        multiplier > 1) {
      throw const FormatException(
        'inner_demon.failure_penalty.main_cultivation_multiplier must be in (0,1]',
      );
    }
    return InnerDemonFailurePenalty(mainCultivationMultiplier: multiplier);
  }
}
