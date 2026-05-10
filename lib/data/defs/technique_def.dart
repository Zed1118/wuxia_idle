import '../models/enums.dart';

/// 心法配置（data_schema.md §5.2，纯 Dart，不入 Isar）。
class TechniqueDef {
  final String id;
  final String name;
  final TechniqueTier tier;
  final TechniqueSchool school;
  final String description;
  final List<String> skillIds;
  final double internalForceGrowthBonus;
  final int speedBonus;
  final List<String> acquireSourceTags;

  const TechniqueDef({
    required this.id,
    required this.name,
    required this.tier,
    required this.school,
    required this.description,
    required this.skillIds,
    required this.internalForceGrowthBonus,
    required this.speedBonus,
    required this.acquireSourceTags,
  });

  factory TechniqueDef.fromYaml(Map<String, dynamic> y) {
    return TechniqueDef(
      id: y['id'] as String,
      name: y['name'] as String,
      tier: TechniqueTier.values.byName(y['tier'] as String),
      school: TechniqueSchool.values.byName(y['school'] as String),
      description: y['description'] as String,
      skillIds: List<String>.from(
        (y['skillIds'] as List? ?? const []).map((e) => e as String),
      ),
      internalForceGrowthBonus:
          (y['internalForceGrowthBonus'] as num).toDouble(),
      speedBonus: (y['speedBonus'] as num).toInt(),
      acquireSourceTags: List<String>.from(
        (y['acquireSourceTags'] as List? ?? const []).map((e) => e as String),
      ),
    );
  }

  @override
  String toString() =>
      'TechniqueDef(id=$id, name=$name, tier=${tier.name}, school=${school.name})';
}
