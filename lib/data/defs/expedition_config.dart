/// 百草岭配置（§8.2）。A2 只落校验不变式与顶层字段；Phase B 扩展节点权重/深度
/// 曲线/奖励表（纯 Dart，无 schema 迁移）。
class ExpeditionConfig {
  const ExpeditionConfig({
    required this.normalNodeMinutes,
    required this.eliteNodeMinutes,
    required this.hpRecoverPctPerNode,
    required this.qiRecoverPctPerNode,
    required this.zhangshiPctPerLayer,
    this.baseExpPerBattle = 170,
  });

  final int normalNodeMinutes;
  final int eliteNodeMinutes;
  final double hpRecoverPctPerNode;
  final double qiRecoverPctPerNode;

  /// 瘴蚀每层递减比例（§4.5，第31节点起每5节点+1层，封顶100%）。
  final double zhangshiPctPerLayer;

  /// 每场战斗基础经验（§4.4/§6.1）。batch3 联合经济探针拍板中档=170
  /// （Lv100→170 ~18天专挂）；`ExpeditionRules.rewardsForNode` 从此读，
  /// settle 结算 exp 奖励按此缩放。
  final int baseExpPerBattle;

  factory ExpeditionConfig.fromYaml(Map<String, dynamic> y) {
    final normal = (y['normal_node_minutes'] as num?)?.toInt() ?? 0;
    final elite = (y['elite_node_minutes'] as num?)?.toInt() ?? 0;
    final hp = (y['hp_recover_pct_per_node'] as num?)?.toDouble() ?? 0.0;
    final qi = (y['qi_recover_pct_per_node'] as num?)?.toDouble() ?? 0.0;
    final zhangshi = (y['zhangshi_pct_per_layer'] as num?)?.toDouble() ?? 0.0;
    final baseExp = (y['base_exp_per_battle'] as num?)?.toInt() ?? 170;

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
    return ExpeditionConfig(
      normalNodeMinutes: normal,
      eliteNodeMinutes: elite,
      hpRecoverPctPerNode: hp,
      qiRecoverPctPerNode: qi,
      zhangshiPctPerLayer: zhangshi,
      baseExpPerBattle: baseExp,
    );
  }
}
