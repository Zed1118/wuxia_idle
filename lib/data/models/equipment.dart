import 'package:isar/isar.dart';

import 'enums.dart';
import 'forging_slot.dart';
import 'lore.dart';

part 'equipment.g.dart';

/// 装备实例（data_schema.md §4.3 / GDD §6）。
///
/// `defId` 指向 yaml 中的 EquipmentDef。共鸣度阶段从 `battleCount` 派生，
/// 见文件底部 [EquipmentResonance] extension。
@collection
class Equipment {
  Id id = Isar.autoIncrement;

  @Index()
  late String defId;

  String? customName;

  @Enumerated(EnumType.name)
  late EquipmentTier tier;

  @Enumerated(EnumType.name)
  late EquipmentSlot slot;

  @Enumerated(EnumType.name)
  TechniqueSchool? school;

  int baseAttack = 0;
  int baseHealth = 0;
  int baseSpeed = 0;

  int enhanceLevel = 0;

  @Index()
  int? ownerCharacterId;

  bool isLineageHeritage = false;
  List<int> previousOwnerCharacterIds = [];

  int battleCount = 0;

  /// 长度恒为 3，索引 1/2/3。schema 约定，工厂方法默认填齐。
  List<ForgingSlot> forgingSlots = [];
  List<Lore> lores = [];

  late DateTime obtainedAt;
  late String obtainedFrom;

  Equipment();

  /// 工厂方法：初始化所有 late 字段并填齐 3 个空开锋槽。
  factory Equipment.create({
    required String defId,
    required EquipmentTier tier,
    required EquipmentSlot slot,
    required DateTime obtainedAt,
    required String obtainedFrom,
    String? customName,
    TechniqueSchool? school,
    int baseAttack = 0,
    int baseHealth = 0,
    int baseSpeed = 0,
    int enhanceLevel = 0,
    int? ownerCharacterId,
    bool isLineageHeritage = false,
    List<int>? previousOwnerCharacterIds,
    int battleCount = 0,
    List<ForgingSlot>? forgingSlots,
    List<Lore>? lores,
  }) {
    return Equipment()
      ..defId = defId
      ..tier = tier
      ..slot = slot
      ..obtainedAt = obtainedAt
      ..obtainedFrom = obtainedFrom
      ..customName = customName
      ..school = school
      ..baseAttack = baseAttack
      ..baseHealth = baseHealth
      ..baseSpeed = baseSpeed
      ..enhanceLevel = enhanceLevel
      ..ownerCharacterId = ownerCharacterId
      ..isLineageHeritage = isLineageHeritage
      ..previousOwnerCharacterIds = previousOwnerCharacterIds ?? []
      ..battleCount = battleCount
      ..forgingSlots = forgingSlots ?? _defaultForgingSlots()
      ..lores = lores ?? [];
  }

  static List<ForgingSlot> _defaultForgingSlots() => [
        ForgingSlot()..slotIndex = 1,
        ForgingSlot()..slotIndex = 2,
        ForgingSlot()..slotIndex = 3,
      ];
}

/// 派生属性扩展（不入库，data_schema.md §4.3）。
extension EquipmentResonance on Equipment {
  ResonanceStage get resonanceStage {
    if (battleCount < 100) return ResonanceStage.shengShu;
    if (battleCount < 500) return ResonanceStage.chenShou;
    if (battleCount < 2000) return ResonanceStage.moQi;
    return ResonanceStage.xinJianTongLing;
  }

  /// 共鸣度数值加成（GDD §6.4）。
  double get resonanceBonus {
    switch (resonanceStage) {
      case ResonanceStage.shengShu:
        return 1.0;
      case ResonanceStage.chenShou:
        return 1.10;
      case ResonanceStage.moQi:
        return 1.20;
      case ResonanceStage.xinJianTongLing:
        return 1.30;
    }
  }

  /// 师承传承时调用：保留 70% 共鸣度，标记为遗物。
  void inheritFrom(int previousOwnerId) {
    previousOwnerCharacterIds.add(previousOwnerId);
    battleCount = (battleCount * 0.7).toInt();
    isLineageHeritage = true;
  }
}
