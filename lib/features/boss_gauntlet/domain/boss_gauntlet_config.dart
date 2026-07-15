class GauntletStageConfig {
  const GauntletStageConfig({required this.role, required this.enemyTeamId});
  final String role; // 'elite' | 'boss'
  final String enemyTeamId;
}

/// 断魂庄配置（§8.2）。A2 落关次角色/补给上限校验；Phase C 扩展敌队机制/奖励。
class BossGauntletConfig {
  const BossGauntletConfig({required this.stages, required this.supplyCap});

  final List<GauntletStageConfig> stages;
  final int supplyCap;

  factory BossGauntletConfig.fromYaml(Map<String, dynamic> y) {
    final supplyCap = (y['supply_cap'] as num?)?.toInt() ?? 0;
    final rawStages = (y['stages'] as List?) ?? const [];
    final stages = [
      for (final s in rawStages)
        GauntletStageConfig(
          role: (s as Map)['role'] as String? ?? '',
          enemyTeamId: s['enemy_team_id'] as String? ?? '',
        ),
    ];

    if (supplyCap != 3) {
      throw StateError('boss_gauntlets: 补给上限固定为 3，got $supplyCap');
    }
    final eliteCount = stages.where((s) => s.role == 'elite').length;
    final bossCount = stages.where((s) => s.role == 'boss').length;
    if (stages.length != 3 || eliteCount != 2 || bossCount != 1) {
      throw StateError(
        'boss_gauntlets: 三关须恰为两精英+一Boss，got '
        '${stages.length}关 elite=$eliteCount boss=$bossCount',
      );
    }
    for (final s in stages) {
      if (s.enemyTeamId.isEmpty) {
        throw StateError('boss_gauntlets: 关次 enemy_team_id 不得为空');
      }
    }
    return BossGauntletConfig(stages: stages, supplyCap: supplyCap);
  }
}
