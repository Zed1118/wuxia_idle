import '../../core/domain/enums.dart';

/// 道具效果定义（材料经济 P2，`data/items.yaml`）。
///
/// - [type] == jingYanDan：必有 [layerFraction]（使用时按当前境界层所需经验的比例推进修炼度）。
/// - [type] == techniqueScroll：必有 [unlockSkillId]（使用时解锁秘传招）。
/// - [healInjuryHours] / [clearLightInjuryStacks]：疗伤调理品效果。
/// 缺对应字段 → fromYaml 抛 StateError（fail fast，沿强校验体例）。
class ItemDef {
  final String defId;
  final ItemType type;
  final String name;
  final double? layerFraction;
  final String? unlockSkillId;
  final double? healInjuryHours;
  final bool clearLightInjuryStacks;

  const ItemDef({
    required this.defId,
    required this.type,
    required this.name,
    this.layerFraction,
    this.unlockSkillId,
    this.healInjuryHours,
    this.clearLightInjuryStacks = false,
  });

  factory ItemDef.fromYaml(Map<String, dynamic> y) {
    final defId = y['defId'] as String;
    final type = ItemType.values.byName(y['type'] as String);
    final name = y['name'] as String;
    final layerFraction = (y['layer_fraction'] as num?)?.toDouble();
    final unlockSkillId = y['unlockSkillId'] as String?;
    final healInjuryHours = (y['heal_injury_hours'] as num?)?.toDouble();
    final clearLightInjuryStacks =
        y['clear_light_injury_stacks'] as bool? ?? false;
    if (type == ItemType.jingYanDan && layerFraction == null) {
      throw StateError('ItemDef $defId: jingYanDan 必须配 layer_fraction');
    }
    if (type == ItemType.techniqueScroll && unlockSkillId == null) {
      throw StateError('ItemDef $defId: techniqueScroll 必须配 unlockSkillId');
    }
    return ItemDef(
      defId: defId,
      type: type,
      name: name,
      layerFraction: layerFraction,
      unlockSkillId: unlockSkillId,
      healInjuryHours: healInjuryHours,
      clearLightInjuryStacks: clearLightInjuryStacks,
    );
  }

  bool get hasInjuryReliefEffect =>
      (healInjuryHours != null && healInjuryHours! > 0) ||
      clearLightInjuryStacks;
}
