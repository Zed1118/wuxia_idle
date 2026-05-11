import '../models/enums.dart';

/// 闭关地图定义（numbers.yaml `retreat.maps[]`，Phase 3 T47）。
///
/// 5 张地图各有不同产出偏向（GDD §8.3），所有产出系数乘以境界缩放后得最终每小时产出。
class SeclusionMapDef {
  final RetreatMapType mapType;
  final String mapName;

  /// 可进入该地图所需的最低境界大阶。
  final RealmTier requiredRealm;

  final double experiencePerHour;
  final double mojianshiPerHour;

  /// 装备掉落概率权重（1.0 = 基础，1.5 = +50%，与 base_equip_drop_probability 相乘）。
  final double equipmentDropRate;

  final double techniqueLearnRate;
  final double internalForceGrowth;

  const SeclusionMapDef({
    required this.mapType,
    required this.mapName,
    required this.requiredRealm,
    required this.experiencePerHour,
    required this.mojianshiPerHour,
    required this.equipmentDropRate,
    required this.techniqueLearnRate,
    required this.internalForceGrowth,
  });

  factory SeclusionMapDef.fromYaml(Map<String, dynamic> y) {
    final outputs = y['base_outputs'] as Map<String, dynamic>;
    return SeclusionMapDef(
      mapType: RetreatMapType.values.byName(y['map_type'] as String),
      mapName: y['map_name'] as String,
      requiredRealm: RealmTier.values.byName(y['required_realm'] as String),
      experiencePerHour: (outputs['experience_per_hour'] as num).toDouble(),
      mojianshiPerHour: (outputs['mojianshi_per_hour'] as num).toDouble(),
      equipmentDropRate: (outputs['equipment_drop_rate'] as num).toDouble(),
      techniqueLearnRate: (outputs['technique_learn_rate'] as num).toDouble(),
      internalForceGrowth: (outputs['internal_force_growth'] as num).toDouble(),
    );
  }
}
