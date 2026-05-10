import '../models/enums.dart';

/// 招式配置（data_schema.md §5.3，纯 Dart，不入 Isar）。
///
/// `parentTechniqueDefId` 为空时，表示该招式由"武学领悟"独立产出（GDD §7.2）。
class SkillDef {
  final String id;
  final String name;
  final String description;
  final SkillType type;
  final int powerMultiplier;
  final int internalForceCost;
  final int cooldownTurns;
  final bool requiresManualTrigger;
  final String? parentTechniqueDefId;
  final String visualEffect;

  const SkillDef({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.powerMultiplier,
    required this.internalForceCost,
    required this.cooldownTurns,
    required this.requiresManualTrigger,
    this.parentTechniqueDefId,
    required this.visualEffect,
  });

  factory SkillDef.fromYaml(Map<String, dynamic> y) {
    return SkillDef(
      id: y['id'] as String,
      name: y['name'] as String,
      description: y['description'] as String,
      type: SkillType.values.byName(y['type'] as String),
      powerMultiplier: (y['powerMultiplier'] as num).toInt(),
      internalForceCost: (y['internalForceCost'] as num).toInt(),
      cooldownTurns: (y['cooldownTurns'] as num).toInt(),
      requiresManualTrigger: y['requiresManualTrigger'] as bool,
      parentTechniqueDefId: y['parentTechniqueDefId'] as String?,
      visualEffect: y['visualEffect'] as String,
    );
  }

  @override
  String toString() =>
      'SkillDef(id=$id, name=$name, type=${type.name}, power=$powerMultiplier)';
}
