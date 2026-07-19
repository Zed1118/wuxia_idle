import '../defs/stage_def.dart';

/// 百草岭深度曲线。全部成长参数与封顶值来自 `data/expeditions.yaml`。
class ExpeditionDepthCurve {
  const ExpeditionDepthCurve({
    required this.firstNode,
    required this.baseMultiplier,
    required this.hpGrowthPerNode,
    required this.attackGrowthPerNode,
    required this.hpMultiplierCap,
    required this.attackMultiplierCap,
    required this.hpValueCap,
    required this.attackValueCap,
  });

  final int firstNode;
  final double baseMultiplier;
  final double hpGrowthPerNode;
  final double attackGrowthPerNode;
  final double hpMultiplierCap;
  final double attackMultiplierCap;
  final int hpValueCap;
  final int attackValueCap;

  factory ExpeditionDepthCurve.fromYaml(Map<String, dynamic> y) {
    final curve = ExpeditionDepthCurve(
      firstNode: (y['first_node'] as num?)?.toInt() ?? 0,
      baseMultiplier: (y['base_multiplier'] as num?)?.toDouble() ?? 0,
      hpGrowthPerNode: (y['hp_growth_per_node'] as num?)?.toDouble() ?? -1,
      attackGrowthPerNode:
          (y['attack_growth_per_node'] as num?)?.toDouble() ?? -1,
      hpMultiplierCap: (y['hp_multiplier_cap'] as num?)?.toDouble() ?? 0,
      attackMultiplierCap:
          (y['attack_multiplier_cap'] as num?)?.toDouble() ?? 0,
      hpValueCap: (y['hp_value_cap'] as num?)?.toInt() ?? 0,
      attackValueCap: (y['attack_value_cap'] as num?)?.toInt() ?? 0,
    );
    if (curve.firstNode <= 0 ||
        curve.baseMultiplier <= 0 ||
        curve.hpGrowthPerNode < 0 ||
        curve.attackGrowthPerNode < 0 ||
        curve.hpMultiplierCap < curve.baseMultiplier ||
        curve.attackMultiplierCap < curve.baseMultiplier ||
        curve.hpValueCap <= 0 ||
        curve.attackValueCap <= 0) {
      throw StateError('expeditions: combat.depth_curve 字段非法');
    }
    return curve;
  }

  int hpAtDepth(int baseValue, int nodeIndex) {
    final depth = (nodeIndex - firstNode).clamp(0, nodeIndex);
    final multiplier = (baseMultiplier + depth * hpGrowthPerNode).clamp(
      baseMultiplier,
      hpMultiplierCap,
    );
    return (baseValue * multiplier).round().clamp(0, hpValueCap);
  }

  int attackAtDepth(int baseValue, int nodeIndex) {
    final depth = (nodeIndex - firstNode).clamp(0, nodeIndex);
    final multiplier = (baseMultiplier + depth * attackGrowthPerNode).clamp(
      baseMultiplier,
      attackMultiplierCap,
    );
    return (baseValue * multiplier).round().clamp(0, attackValueCap);
  }
}

/// 可由稳定 seed 选择的一支百草岭敌队模板。
class ExpeditionEnemyTeam {
  const ExpeditionEnemyTeam({required this.id, required this.enemies});

  final String id;
  final List<EnemyDef> enemies;

  factory ExpeditionEnemyTeam.fromYaml(Map<String, dynamic> y) {
    final id = y['id'] as String? ?? '';
    final enemies = [
      for (final raw in (y['enemies'] as List? ?? const []))
        EnemyDef.fromYaml(Map<String, dynamic>.from(raw as Map)),
    ];
    if (id.isEmpty || enemies.isEmpty) {
      throw StateError('expeditions: combat 敌队 id/enemies 不得为空');
    }
    return ExpeditionEnemyTeam(id: id, enemies: List.unmodifiable(enemies));
  }
}

/// 百草岭配置（§8.2）。纯 Dart 配置，不涉及 Isar schema。
class ExpeditionConfig {
  const ExpeditionConfig({
    required this.normalNodeMinutes,
    required this.eliteNodeMinutes,
    required this.hpRecoverPctPerNode,
    required this.qiRecoverPctPerNode,
    required this.zhangshiPctPerLayer,
    this.baseExpPerBattle = 170,
    this.depthCurve,
    this.normalEnemyTeams = const [],
    this.eliteEnemyTeams = const [],
  });

  final int normalNodeMinutes;
  final int eliteNodeMinutes;
  final double hpRecoverPctPerNode;
  final double qiRecoverPctPerNode;

  /// 瘴蚀每层递减比例（§4.5，第31节点起每5节点+1层，封顶100%）。
  final double zhangshiPctPerLayer;

  /// 每场战斗基础经验（§4.4/§6.1）。
  final int baseExpPerBattle;

  final ExpeditionDepthCurve? depthCurve;
  final List<ExpeditionEnemyTeam> normalEnemyTeams;
  final List<ExpeditionEnemyTeam> eliteEnemyTeams;

  factory ExpeditionConfig.fromYaml(Map<String, dynamic> y) {
    final normal = (y['normal_node_minutes'] as num?)?.toInt() ?? 0;
    final elite = (y['elite_node_minutes'] as num?)?.toInt() ?? 0;
    final hp = (y['hp_recover_pct_per_node'] as num?)?.toDouble() ?? 0.0;
    final qi = (y['qi_recover_pct_per_node'] as num?)?.toDouble() ?? 0.0;
    final zhangshi = (y['zhangshi_pct_per_layer'] as num?)?.toDouble() ?? 0.0;
    final baseExp = (y['base_exp_per_battle'] as num?)?.toInt() ?? 170;
    final combat = Map<String, dynamic>.from(y['combat'] as Map? ?? const {});
    final depthCurve = ExpeditionDepthCurve.fromYaml(
      Map<String, dynamic>.from(combat['depth_curve'] as Map? ?? const {}),
    );
    List<ExpeditionEnemyTeam> parseTeams(String key) => [
      for (final raw in (combat[key] as List? ?? const []))
        ExpeditionEnemyTeam.fromYaml(Map<String, dynamic>.from(raw as Map)),
    ];
    final normalTeams = parseTeams('normal_enemy_teams');
    final eliteTeams = parseTeams('elite_enemy_teams');

    if (normal <= 0 || elite <= 0) {
      throw StateError('expeditions: 节点时长必须为正 (normal=$normal elite=$elite)');
    }
    if (baseExp <= 0) {
      throw StateError('expeditions: base_exp_per_battle 必须为正 (got $baseExp)');
    }
    for (final e in {'hp': hp, 'qi': qi, 'zhangshi': zhangshi}.entries) {
      if (e.value < 0 || e.value > 1) {
        throw StateError('expeditions: ${e.key} 比例须 ∈ [0,1]，got ${e.value}');
      }
    }
    if (normalTeams.isEmpty || eliteTeams.isEmpty) {
      throw StateError('expeditions: 普通/险关敌队池均不得为空');
    }
    final teamIds = [...normalTeams, ...eliteTeams].map((team) => team.id);
    if (teamIds.toSet().length != teamIds.length) {
      throw StateError('expeditions: combat 敌队 id 必须唯一');
    }
    return ExpeditionConfig(
      normalNodeMinutes: normal,
      eliteNodeMinutes: elite,
      hpRecoverPctPerNode: hp,
      qiRecoverPctPerNode: qi,
      zhangshiPctPerLayer: zhangshi,
      baseExpPerBattle: baseExp,
      depthCurve: depthCurve,
      normalEnemyTeams: List.unmodifiable(normalTeams),
      eliteEnemyTeams: List.unmodifiable(eliteTeams),
    );
  }

  /// 稳定 seed 选队，再按同一 YAML 深度曲线缩放基础 HP/攻击。
  List<EnemyDef> enemiesForNode({
    required int nodeIndex,
    required int nodeSeed,
    required bool elite,
  }) {
    final curve = depthCurve;
    final pool = elite ? eliteEnemyTeams : normalEnemyTeams;
    if (curve == null || pool.isEmpty) {
      throw StateError('expeditions: combat 配置未加载');
    }
    final team = pool[nodeSeed.abs() % pool.length];
    return [
      for (final enemy in team.enemies)
        EnemyDef(
          id: enemy.id,
          name: enemy.name,
          realmTier: enemy.realmTier,
          realmLayer: enemy.realmLayer,
          school: enemy.school,
          baseHp: curve.hpAtDepth(enemy.baseHp, nodeIndex),
          baseAttack: curve.attackAtDepth(enemy.baseAttack, nodeIndex),
          baseSpeed: enemy.baseSpeed,
          skillIds: enemy.skillIds,
          iconPath: enemy.iconPath,
          isBoss: enemy.isBoss,
          chargeSkillId: enemy.chargeSkillId,
          bossPhases: enemy.bossPhases,
          cycleBossPhases: enemy.cycleBossPhases,
          schoolDamageTakenMult: enemy.schoolDamageTakenMult,
          guardianWard: enemy.guardianWard,
          vulnerability: enemy.vulnerability,
          cycleVulnerability: enemy.cycleVulnerability,
        ),
    ];
  }
}
