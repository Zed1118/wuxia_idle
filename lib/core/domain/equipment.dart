import 'package:isar_community/isar.dart';

import '../../data/numbers_config.dart';
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

  /// §5.3 三系锁死:装备阶 ≤ 角色境界阶才可上身(EquipmentTier 与 RealmTier
  /// index 一一对应 · 例 二流 idx2 → 最多装 好家伙 idx2)。
  ///
  /// **师承遗物不例外**(CLAUDE.md §5.3):虽自带传承 buff,徒弟境界未达对应阶时
  /// 仍不可装备 —— 只能 owner 持有(背包)/观摩,等够阶再上身。飞升 auto_swap
  /// (AscendService.performAscend)上身前必经此守卫,否则武圣神物会落到低境界徒弟。
  bool isEquippableAtRealm(RealmTier realmTier) => tier.index <= realmTier.index;
}

/// 派生属性扩展（不入库，data_schema.md §4.3）。
///
/// 阈值/倍率/继承保留比例全部从 [NumbersConfig] 读，不硬编码（GDD §5.6）。
extension EquipmentResonance on Equipment {
  /// 当前 [battleCount] 落入的共鸣段。
  /// 顺序遍历 yaml `equipment.resonance.stages`，命中第一个 `[min, max)` 区间。
  /// 最高段 `maxBattleCount == null` 表示无上限。
  ResonanceStage resonanceStage(NumbersConfig n) {
    for (final s in n.resonanceStages) {
      final inMin = battleCount >= s.minBattleCount;
      final inMax = s.maxBattleCount == null || battleCount < s.maxBattleCount!;
      if (inMin && inMax) return s.stage;
    }
    return n.resonanceStages.last.stage;
  }

  /// 共鸣度数值加成（GDD §6.4，1.0 / 1.10 / 1.20 / 1.30）。
  double resonanceBonus(NumbersConfig n) {
    final stage = resonanceStage(n);
    return n.resonanceStages
        .firstWhere((s) => s.stage == stage)
        .bonusMultiplier;
  }

  /// 师承传承时调用：保留 [NumbersConfig.resonanceInheritanceRetention]
  /// (=0.7) 的 battleCount，标记为遗物。
  ///
  /// **Isar fixed-length list 兼容**(memory `feedback_isar_pitfalls`):从 Isar
  /// 读取的实例 `previousOwnerCharacterIds` 是 fixed-length,不能 `.add()`。
  /// 必须 reassign 新 list(`[...old, new]`)而非 mutate(P2.3 飞升暴露的 bug)。
  void inheritFrom(int previousOwnerId, NumbersConfig n) {
    previousOwnerCharacterIds = [
      ...previousOwnerCharacterIds,
      previousOwnerId,
    ];
    battleCount = (battleCount * n.resonanceInheritanceRetention).toInt();
    isLineageHeritage = true;
  }
}
