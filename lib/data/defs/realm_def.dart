import '../../core/domain/enums.dart';

/// 境界配置（data_schema.md §5.8，纯 Dart，不入 Isar）。
///
/// 49 个 RealmDef 平铺一张表，由 (tier, layer) 或 absoluteLevel 索引。
/// `equipmentTierCap` / `techniqueTierCap` 是三系锁死的硬约束面（GDD §5.3）。
class RealmDef {
  final RealmTier tier;
  final RealmLayer layer;
  final int absoluteLevel;
  final int internalForceMax;
  final int experienceToNext;
  final EquipmentTier equipmentTierCap;
  final TechniqueTier techniqueTierCap;

  const RealmDef({
    required this.tier,
    required this.layer,
    required this.absoluteLevel,
    required this.internalForceMax,
    required this.experienceToNext,
    required this.equipmentTierCap,
    required this.techniqueTierCap,
  });

  factory RealmDef.fromYaml(Map<String, dynamic> y) {
    return RealmDef(
      tier: RealmTier.values.byName(y['tier'] as String),
      layer: RealmLayer.values.byName(y['layer'] as String),
      absoluteLevel: (y['absoluteLevel'] as num).toInt(),
      internalForceMax: (y['internalForceMax'] as num).toInt(),
      experienceToNext: (y['experienceToNext'] as num).toInt(),
      equipmentTierCap:
          EquipmentTier.values.byName(y['equipmentTierCap'] as String),
      techniqueTierCap:
          TechniqueTier.values.byName(y['techniqueTierCap'] as String),
    );
  }

  @override
  String toString() =>
      'RealmDef(${tier.name}/${layer.name}, lv=$absoluteLevel, '
      'ifMax=$internalForceMax, eqCap=${equipmentTierCap.name}, '
      'techCap=${techniqueTierCap.name})';
}
