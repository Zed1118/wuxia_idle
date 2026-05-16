import '../../core/domain/enums.dart';

/// 装备配置（data_schema.md §5.1，纯 Dart，不入 Isar）。
///
/// 由 `GameRepository` 在启动时一次性从 yaml 加载到内存。
class EquipmentDef {
  final String id;
  final String name;
  final EquipmentTier tier;
  final EquipmentSlot slot;
  final TechniqueSchool? schoolBias;
  final int baseAttackMin;
  final int baseAttackMax;
  final int baseHealthMin;
  final int baseHealthMax;
  final int baseSpeedMin;
  final int baseSpeedMax;
  final List<String> presetLoreIds;
  final List<String> dropSourceTags;
  final String iconPath;

  /// 开锋第 3 槽（+19 解锁）可选的专属技能 def id 列表（T21 新增）。
  /// yaml 缺省时为空，UI 表现为"该装备暂无专属技能"。
  final List<String> specialSkillCandidates;

  /// 师承遗物标记（Phase 3 Week 4 T55，GDD §6.1 + §5.3 例外说明）。
  ///
  /// `true` 时：[EquipmentFactory.fromDef] 会自动把生成的 [Equipment.isLineageHeritage]
  /// 设为 true，进而触发 [derived_stats.internalForceMaxWithLineage] 的 +5%
  /// 内力上限 buff（numbers.yaml `lineage_heritage.internal_force_max_bonus`）。
  ///
  /// **三系锁死不放开**：遗物可获得 / 可携带，但徒弟境界未达对应阶时不可装备。
  /// yaml 缺省 false。
  final bool isLineageHeritage;

  const EquipmentDef({
    required this.id,
    required this.name,
    required this.tier,
    required this.slot,
    this.schoolBias,
    required this.baseAttackMin,
    required this.baseAttackMax,
    required this.baseHealthMin,
    required this.baseHealthMax,
    required this.baseSpeedMin,
    required this.baseSpeedMax,
    required this.presetLoreIds,
    required this.dropSourceTags,
    required this.iconPath,
    this.specialSkillCandidates = const [],
    this.isLineageHeritage = false,
  });

  factory EquipmentDef.fromYaml(Map<String, dynamic> y) {
    return EquipmentDef(
      id: y['id'] as String,
      name: y['name'] as String,
      tier: EquipmentTier.values.byName(y['tier'] as String),
      slot: EquipmentSlot.values.byName(y['slot'] as String),
      schoolBias: y['schoolBias'] == null
          ? null
          : TechniqueSchool.values.byName(y['schoolBias'] as String),
      baseAttackMin: (y['baseAttackMin'] as num).toInt(),
      baseAttackMax: (y['baseAttackMax'] as num).toInt(),
      baseHealthMin: (y['baseHealthMin'] as num).toInt(),
      baseHealthMax: (y['baseHealthMax'] as num).toInt(),
      baseSpeedMin: (y['baseSpeedMin'] as num).toInt(),
      baseSpeedMax: (y['baseSpeedMax'] as num).toInt(),
      presetLoreIds: List<String>.from(
        (y['presetLoreIds'] as List? ?? const []).map((e) => e as String),
      ),
      dropSourceTags: List<String>.from(
        (y['dropSourceTags'] as List? ?? const []).map((e) => e as String),
      ),
      iconPath: y['iconPath'] as String,
      specialSkillCandidates: List<String>.from(
        (y['specialSkillCandidates'] as List? ?? const [])
            .map((e) => e as String),
      ),
      isLineageHeritage: (y['isLineageHeritage'] as bool?) ?? false,
    );
  }

  @override
  String toString() =>
      'EquipmentDef(id=$id, name=$name, tier=${tier.name}, slot=${slot.name})';
}
