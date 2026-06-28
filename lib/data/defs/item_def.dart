import '../../core/domain/enums.dart';

/// 道具效果定义（材料经济 P2，`data/items.yaml`）。
///
/// - [type] == jingYanDan：必有 [layerFraction]（使用时按当前境界层所需经验的比例推进修炼度）。
/// - [type] == techniqueScroll：必有 [unlockSkillId]（使用时解锁秘传招）。
/// - 疗伤类 miscMaterial：可选 [injuryHealHours] / [residueHealHours] /
///   [clearLightInjury]，用于消耗桃花岛丹房加工产物。
/// 缺对应字段 → fromYaml 抛 StateError（fail fast，沿强校验体例）。
class ItemDef {
  final String defId;
  final ItemType type;
  final String name;
  final double? layerFraction;
  final String? unlockSkillId;
  final double injuryHealHours;
  final double residueHealHours;
  final bool clearLightInjury;

  const ItemDef({
    required this.defId,
    required this.type,
    required this.name,
    this.layerFraction,
    this.unlockSkillId,
    this.injuryHealHours = 0.0,
    this.residueHealHours = 0.0,
    this.clearLightInjury = false,
  });

  bool get hasRecoveryEffect =>
      injuryHealHours > 0 || residueHealHours > 0 || clearLightInjury;

  bool get isUsable =>
      type == ItemType.jingYanDan ||
      type == ItemType.techniqueScroll ||
      hasRecoveryEffect;

  factory ItemDef.fromYaml(Map<String, dynamic> y) {
    final defId = y['defId'] as String;
    final type = ItemType.values.byName(y['type'] as String);
    final name = y['name'] as String;
    final layerFraction = (y['layer_fraction'] as num?)?.toDouble();
    final unlockSkillId = y['unlockSkillId'] as String?;
    final injuryHealHours = (y['injury_heal_hours'] as num?)?.toDouble() ?? 0.0;
    final residueHealHours =
        (y['residue_heal_hours'] as num?)?.toDouble() ?? 0.0;
    final clearLightInjury = y['clear_light_injury'] as bool? ?? false;
    if (type == ItemType.jingYanDan && layerFraction == null) {
      throw StateError('ItemDef $defId: jingYanDan 必须配 layer_fraction');
    }
    if (type == ItemType.techniqueScroll && unlockSkillId == null) {
      throw StateError('ItemDef $defId: techniqueScroll 必须配 unlockSkillId');
    }
    if (injuryHealHours < 0 || residueHealHours < 0) {
      throw StateError('ItemDef $defId: 疗伤小时数不可为负');
    }
    return ItemDef(
      defId: defId,
      type: type,
      name: name,
      layerFraction: layerFraction,
      unlockSkillId: unlockSkillId,
      injuryHealHours: injuryHealHours,
      residueHealHours: residueHealHours,
      clearLightInjury: clearLightInjury,
    );
  }
}
