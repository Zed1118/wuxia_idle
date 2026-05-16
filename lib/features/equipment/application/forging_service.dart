import 'package:isar_community/isar.dart';

import '../../../data/defs/equipment_def.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../data/numbers_config.dart';

/// 开锋结果（phase2_tasks T21）。
enum ForgeResult {
  /// 成功开锋，槽位写入。
  success,

  /// 装备 enhanceLevel 未达解锁等级。
  slotNotUnlocked,

  /// 该槽位已开锋，Phase 2 不允许覆盖。
  alreadyForged,

  /// 类型不在该槽 availableTypes 中（含被槽 1 排除的类型）。
  typeNotAvailable,

  /// 槽 3 specialSkill 缺少 specialSkillId。
  missingSpecialSkillId,

  /// 槽 3 specialSkill 但 EquipmentDef.specialSkillCandidates 为空。
  noSpecialSkillCandidates,

  /// 槽 3 specialSkill 的 id 不在 candidates 列表中。
  invalidSpecialSkillId,
}

/// 开锋服务（GDD §6.5，phase2_tasks T21）。
///
/// 接收 [ForgingConfig] + 可选 [EquipmentDef]（仅槽 3 specialSkill 校验时需要）。
/// in-place 修改 [Equipment.forgingSlots]。
class ForgingService {
  const ForgingService({required this.isar});

  final Isar isar;

  /// 当前可在 [slotIndex] 上开锋的类型列表。
  ///
  /// 返回空列表的两种情况：
  ///   1. enhanceLevel 未达 [ForgingSlotConfig.unlockAtEnhanceLevel]
  ///   2. 槽 2 已被槽 1 排除掉所有可用类型（极端情况，正常 yaml 不会）
  ///
  /// **不**判定该槽是否已开（已开锋的槽返回原 availableTypes，UI 自行判断
  /// "已开锋"状态后置灰）。
  static List<ForgingSlotType> availableTypesForSlot({
    required Equipment eq,
    required int slotIndex,
    required ForgingConfig config,
  }) {
    final slotConfig = config.slotByIndex(slotIndex);
    if (eq.enhanceLevel < slotConfig.unlockAtEnhanceLevel) {
      return const [];
    }

    var types = slotConfig.availableTypes;
    if (slotConfig.excludePreviousSlotType) {
      // 排除前一个槽（slotIndex - 1）已开锋的类型
      final prev = eq.forgingSlots[slotIndex - 2];
      if (prev.unlocked && prev.type != null) {
        types = types.where((t) => t != prev.type).toList(growable: false);
      }
    }
    return types;
  }

  /// 在 [slotIndex] 上开锋指定 [type]。in-place 修改 [eq]。
  ///
  /// [specialSkillId] 仅在 [type] == specialSkill 时必填，且必须在
  /// [def.specialSkillCandidates] 列表中。其他类型时忽略。
  ///
  /// 返回 [ForgeResult] 表示成功或失败原因。失败时 [eq] 不变。
  static ForgeResult forge({
    required Equipment eq,
    required EquipmentDef def,
    required int slotIndex,
    required ForgingSlotType type,
    String? specialSkillId,
    required ForgingConfig config,
  }) {
    final slotConfig = config.slotByIndex(slotIndex);

    if (eq.enhanceLevel < slotConfig.unlockAtEnhanceLevel) {
      return ForgeResult.slotNotUnlocked;
    }

    final slot = eq.forgingSlots[slotIndex - 1];
    if (slot.unlocked) {
      return ForgeResult.alreadyForged;
    }

    final available = availableTypesForSlot(
      eq: eq,
      slotIndex: slotIndex,
      config: config,
    );
    if (!available.contains(type)) {
      return ForgeResult.typeNotAvailable;
    }

    final bonus = slotConfig.bonusValue[type];
    if (bonus == null) {
      return ForgeResult.typeNotAvailable;
    }

    // specialSkill 槽特殊校验
    if (type == ForgingSlotType.specialSkill) {
      if (specialSkillId == null) {
        return ForgeResult.missingSpecialSkillId;
      }
      if (def.specialSkillCandidates.isEmpty) {
        return ForgeResult.noSpecialSkillCandidates;
      }
      if (!def.specialSkillCandidates.contains(specialSkillId)) {
        return ForgeResult.invalidSpecialSkillId;
      }
      slot.specialSkillId = specialSkillId;
    }

    slot.type = type;
    slot.unlocked = true;
    slot.bonusValue = bonus;

    return ForgeResult.success;
  }

  /// T32 #22b：将 [forge] 的 in-place 改写（forgingSlots 修改）落地到 Isar。
  /// 开锋无物料消耗（GDD §6.5），writeTxn 只需 `equipments.put(eq)`。
  Future<void> persistResult({required Equipment eq}) async {
    await isar.writeTxn(() async {
      await isar.equipments.put(eq);
    });
  }
}
