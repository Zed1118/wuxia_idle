import '../../core/domain/enums.dart';

/// 师徒角色定义（GDD §7.1，Phase 3 Week 4 T53）。
///
/// Demo 阶段固定 3 角色：祖师（slotIndex=0, founder）+ 大弟子（slotIndex=1, disciple）
/// + 二弟子（slotIndex=2, disciple）。祖师=玩家本人，由 T54 seedMasterDisciple
/// 复用既有 Character；2 弟子新建。
///
/// 决策依据：`docs/handoff/week4_d_minimal_spec_2026-05-13.md` 方案 A。
/// 飞升机制 Demo 不做，`defaultRealm` 严格 `< wuSheng`（GameRepository 红线校验）。
class MasterDef {
  final String id;
  final LineageRole lineageRole;
  final int slotIndex;
  final RealmTier defaultRealm;
  final RealmLayer defaultLayer;
  final AttributeProfile attributeProfile;
  final List<String> startingTechniqueIds;
  final List<String> startingEquipmentIds;
  final bool enabledInDemo;

  const MasterDef({
    required this.id,
    required this.lineageRole,
    required this.slotIndex,
    required this.defaultRealm,
    required this.defaultLayer,
    required this.attributeProfile,
    required this.startingTechniqueIds,
    required this.startingEquipmentIds,
    required this.enabledInDemo,
  });

  factory MasterDef.fromYaml(Map<String, dynamic> y) {
    return MasterDef(
      id: y['id'] as String,
      lineageRole: LineageRole.values.byName(y['lineageRole'] as String),
      slotIndex: (y['slotIndex'] as num).toInt(),
      defaultRealm: RealmTier.values.byName(y['defaultRealm'] as String),
      defaultLayer: RealmLayer.values.byName(y['defaultLayer'] as String),
      attributeProfile: AttributeProfile.fromYaml(
        Map<String, dynamic>.from(y['attributeProfile'] as Map),
      ),
      startingTechniqueIds: List<String>.from(
        (y['startingTechniqueIds'] as List? ?? const [])
            .map((e) => e as String),
      ),
      startingEquipmentIds: List<String>.from(
        (y['startingEquipmentIds'] as List? ?? const [])
            .map((e) => e as String),
      ),
      enabledInDemo: (y['enabledInDemo'] as bool?) ?? true,
    );
  }

  @override
  String toString() =>
      'MasterDef(id=$id, role=${lineageRole.name}, slot=$slotIndex, '
      'realm=${defaultRealm.name}/${defaultLayer.name})';
}

/// 师徒角色 4 属性模板（GDD §4.1，单项 [1,10]，总和 [16,24]）。
///
/// 与 [Attributes] (Isar @embedded) 字段对齐但独立类型，避免 def 层污染 Isar。
class AttributeProfile {
  final int constitution;
  final int enlightenment;
  final int agility;
  final int fortune;

  const AttributeProfile({
    required this.constitution,
    required this.enlightenment,
    required this.agility,
    required this.fortune,
  });

  factory AttributeProfile.fromYaml(Map<String, dynamic> y) {
    return AttributeProfile(
      constitution: (y['constitution'] as num).toInt(),
      enlightenment: (y['enlightenment'] as num).toInt(),
      agility: (y['agility'] as num).toInt(),
      fortune: (y['fortune'] as num).toInt(),
    );
  }

  int get total => constitution + enlightenment + agility + fortune;
}
