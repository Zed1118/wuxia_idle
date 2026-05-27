import '../../../core/domain/enums.dart';

/// 群战守城配置(1.0 P3.2 §12.3,GDD v1.13,data/numbers.yaml `mass_battle` 段强类型化)。
///
/// 5 关 `stage_mass_battle_01..05` 跨 yiLiu(qiMeng/jingTong/dengFeng)+
/// jueDing(qiMeng/jingTong)2 Tier 平行支线,**不接管 wuSheng 突破链**
/// (`isLayerLocked` 无 massBattle 路径)。
///
/// Schema:
///   - [formations]:3 阵型 × {crit/evasion/defense/damage} delta(**仅玩家 leftTeam**)
///   - [waveIntermission]:wave 间过渡规则(actionPoint reset / HP+IF preserve / cd reset)
///   - [stageFormations]:stage_id → 默认 Formation(玩家未选时 fallback)
///   - [unlockTriggers]:触发关 victory → 下一关 unlock 链(沿 light_foot 体例 `key=触发,value=解锁`)
///
/// fixture 兼容:numbers.yaml 不含 `mass_battle` 段时走 [MassBattleDef.empty]
/// (所有 Map 空 / 默认 neutral modifier,行为同 1.0 P3.2 前)。
class MassBattleDef {
  /// formation → modifier(MassBattleStrategy 烘焙到 leftTeam BattleCharacter stat)。
  final Map<Formation, MassBattleFormationModifier> formations;

  /// wave 间过渡规则(MassBattleStrategy._intermission 消费)。
  final MassBattleWaveIntermission waveIntermission;

  /// stage_id → 默认 Formation(玩家未选时 fallback,沿 stage_terrain 体例)。
  final Map<String, Formation> stageFormations;

  /// 触发关 victory → 下一关 unlock(如 stage_06_05 → stage_mass_battle_01)。
  final Map<String, String> unlockTriggers;

  /// 残血容差(P3.2.B):wave 委派结果 draw 但敌方剩余 HP ≤ 此比例 → 改判 leftWin
  /// (守城清剿叙事;免「末尾 1 残血敌人 KO 不掉」stalemate)。
  /// 范围 [0.0, 1.0],默认 0.05。
  final double residualHpThresholdPct;

  const MassBattleDef({
    required this.formations,
    required this.waveIntermission,
    required this.stageFormations,
    required this.unlockTriggers,
    this.residualHpThresholdPct = 0.05,
  });

  /// numbers.yaml 不含 `mass_battle` 段时的空值(fixture 兼容)。
  factory MassBattleDef.empty() => const MassBattleDef(
        formations: {},
        waveIntermission: MassBattleWaveIntermission.defaults(),
        stageFormations: {},
        unlockTriggers: {},
      );

  factory MassBattleDef.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return MassBattleDef.empty();

    final formations = <Formation, MassBattleFormationModifier>{};
    final formationsYaml = y['formations'] as Map?;
    if (formationsYaml != null) {
      for (final e in formationsYaml.entries) {
        final formation = Formation.values.byName(e.key as String);
        formations[formation] = MassBattleFormationModifier.fromYaml(
          Map<String, dynamic>.from(e.value as Map),
        );
      }
    }

    final waveYaml = y['wave_intermission'] as Map?;
    final waveIntermission = waveYaml == null
        ? const MassBattleWaveIntermission.defaults()
        : MassBattleWaveIntermission.fromYaml(
            Map<String, dynamic>.from(waveYaml),
          );

    final stageFormations = <String, Formation>{};
    final stageYaml = y['stage_formations'] as Map?;
    if (stageYaml != null) {
      for (final e in stageYaml.entries) {
        stageFormations[e.key as String] =
            Formation.values.byName(e.value as String);
      }
    }

    final unlocks = <String, String>{};
    final unlocksYaml = y['unlock_triggers'] as Map?;
    if (unlocksYaml != null) {
      for (final e in unlocksYaml.entries) {
        unlocks[e.key as String] = e.value as String;
      }
    }

    final residualHpThresholdPct =
        (y['residual_hp_threshold_pct'] as num?)?.toDouble() ?? 0.05;

    return MassBattleDef(
      formations: formations,
      waveIntermission: waveIntermission,
      stageFormations: stageFormations,
      unlockTriggers: unlocks,
      residualHpThresholdPct: residualHpThresholdPct,
    );
  }
}

/// 单阵型的 modifier 配置。烘焙到 leftTeam BattleCharacter critRate/evasionRate/
/// defenseRate/attackPowerMultiplier(MassBattleStrategy 入口 `applyFormationTo`)。
/// 数值层沿 LightFootTerrainModifier 体例(P3.1.B damageMultiplier 已接 damage_calculator)。
class MassBattleFormationModifier {
  /// 暴击率 delta(±0.10 量级,clamp ≤0.95)。
  final double criticalRateDelta;

  /// 闪避率 delta(±0.05-0.10 量级,clamp ≤0.95)。
  final double evasionRateDelta;

  /// 防御率 delta(±0.05-0.10 量级,clamp ≤0.95)。
  final double defenseRateDelta;

  /// 伤害乘数(P3.1.B 已接 damage_calculator,沿 LightFoot 体例)。
  final double damageMultiplier;

  const MassBattleFormationModifier({
    required this.criticalRateDelta,
    required this.evasionRateDelta,
    required this.defenseRateDelta,
    required this.damageMultiplier,
  });

  /// 中性 modifier(无阵型 / fixture 兜底,全 0/1)。
  factory MassBattleFormationModifier.neutral() =>
      const MassBattleFormationModifier(
        criticalRateDelta: 0.0,
        evasionRateDelta: 0.0,
        defenseRateDelta: 0.0,
        damageMultiplier: 1.0,
      );

  factory MassBattleFormationModifier.fromYaml(Map<String, dynamic> y) =>
      MassBattleFormationModifier(
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

/// wave 间过渡规则(MassBattleStrategy._intermission 消费)。
///
/// `resetActionPoint=true` 让 wave 间走 tick 不快进(契 §5.5 在线 = 离线);
/// `preserveHp` + `preserveInternalForce` 让守城压力跨 wave 累积;
/// `preserveCooldowns=false` 给玩家下波大招机会。
class MassBattleWaveIntermission {
  /// wave 间 actionPoint 归 0(走 tick 不快进)。
  final bool resetActionPoint;

  /// wave 间 HP 保留(true = 不回血;守城压力累积)。
  final bool preserveHp;

  /// wave 间内力保留(true = 限大招使用频率)。
  final bool preserveInternalForce;

  /// wave 间 cd 保留(false = 重置 cd 给玩家下波大招机会)。
  final bool preserveCooldowns;

  /// 死角色 revive 比例(0.0 = 不 revive,0.30 = 复活至 maxHp × 30%)。
  /// 守城允许中场补给:wave 间死人能短暂回阵,但残血进下波(数量劣势设计意图保留)。
  final double reviveDeadPct;

  /// 活角色 hp 恢复比例(0.0 = preserveHp 走原值,1.0 = 满 heal 到 maxHp)。
  /// 与 preserveHp 取 max(短歇 hp 不低于当前残血)。
  final double aliveHpRecoveryPct;

  /// 活角色内力恢复比例(0.0 = preserveInternalForce 走原值,1.0 = 满恢复)。
  /// 与 preserveInternalForce 取 max(短歇内力不低于当前残值)。
  final double aliveIfRecoveryPct;

  const MassBattleWaveIntermission({
    required this.resetActionPoint,
    required this.preserveHp,
    required this.preserveInternalForce,
    required this.preserveCooldowns,
    this.reviveDeadPct = 0.0,
    this.aliveHpRecoveryPct = 0.0,
    this.aliveIfRecoveryPct = 0.0,
  });

  /// 默认值(fixture / yaml 段缺失时兜底,与 numbers.yaml 显式配置一致)。
  const MassBattleWaveIntermission.defaults()
      : resetActionPoint = true,
        preserveHp = true,
        preserveInternalForce = true,
        preserveCooldowns = false,
        reviveDeadPct = 1.00,
        aliveHpRecoveryPct = 1.00,
        aliveIfRecoveryPct = 0.50;

  factory MassBattleWaveIntermission.fromYaml(Map<String, dynamic> y) =>
      MassBattleWaveIntermission(
        resetActionPoint: (y['reset_action_point'] as bool?) ?? true,
        preserveHp: (y['preserve_hp'] as bool?) ?? true,
        preserveInternalForce:
            (y['preserve_internal_force'] as bool?) ?? true,
        preserveCooldowns: (y['preserve_cooldowns'] as bool?) ?? false,
        reviveDeadPct: (y['revive_dead_pct'] as num?)?.toDouble() ?? 0.0,
        aliveHpRecoveryPct:
            (y['alive_hp_recovery_pct'] as num?)?.toDouble() ?? 0.0,
        aliveIfRecoveryPct:
            (y['alive_if_recovery_pct'] as num?)?.toDouble() ?? 0.0,
      );
}
