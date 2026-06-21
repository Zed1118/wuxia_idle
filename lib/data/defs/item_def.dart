import '../../core/domain/enums.dart';

/// 道具效果定义（材料经济 P2，`data/items.yaml`）。
///
/// - [type] == jingYanDan：必有 [experience]（使用时加角色经验）。
/// - [type] == techniqueScroll：必有 [unlockSkillId]（使用时解锁秘传招）。
/// 缺对应字段 → fromYaml 抛 StateError（fail fast，沿强校验体例）。
class ItemDef {
  final String defId;
  final ItemType type;
  final String name;
  final int? experience;
  final String? unlockSkillId;

  const ItemDef({
    required this.defId,
    required this.type,
    required this.name,
    this.experience,
    this.unlockSkillId,
  });

  factory ItemDef.fromYaml(Map<String, dynamic> y) {
    final defId = y['defId'] as String;
    final type = ItemType.values.byName(y['type'] as String);
    final name = y['name'] as String;
    final experience = (y['experience'] as num?)?.toInt();
    final unlockSkillId = y['unlockSkillId'] as String?;
    if (type == ItemType.jingYanDan && experience == null) {
      throw StateError('ItemDef $defId: jingYanDan 必须配 experience');
    }
    if (type == ItemType.techniqueScroll && unlockSkillId == null) {
      throw StateError('ItemDef $defId: techniqueScroll 必须配 unlockSkillId');
    }
    return ItemDef(
      defId: defId,
      type: type,
      name: name,
      experience: experience,
      unlockSkillId: unlockSkillId,
    );
  }
}
