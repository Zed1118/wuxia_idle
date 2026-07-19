import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import 'equipment_slot_occupancy.dart';

// 纯配置 2026-07-19 迁 data/defs(backlog #6 收敛 data→features 反向边);
// export 保持既有 7 生产 + 3 测试 import 点零改动;import 供本文件 calc 函数签名用。
import '../../../data/defs/equipment_disposal_def.dart';
export '../../../data/defs/equipment_disposal_def.dart';

/// 分解产出（强化材料）。
class DisassembleRewards {
  final int mojianshi;
  final int xinxuejiejing;
  const DisassembleRewards({
    required this.mojianshi,
    required this.xinxuejiejing,
  });
}

enum EquipmentProtectionReason {
  currentFormation,
  equipped,
  locked,
  lineageHeritage,
  highTier,
  protectedSource,
  story,
}

/// 装备处置/替换保护策略。
///
/// `zhongQi` 及以上对应爆品门槛，批量整理默认不碰；剧情/里程碑来源由
/// application 层传入既有 [UiStrings] 常量，避免在 domain 层写展示文案。
class EquipmentProtectionPolicy {
  final EquipmentTier? protectTierAtOrAbove;
  final Set<String> protectedObtainedFrom;
  final bool protectPersonalHistory;

  const EquipmentProtectionPolicy({
    this.protectTierAtOrAbove = EquipmentTier.zhongQi,
    this.protectedObtainedFrom = const {},
    this.protectPersonalHistory = true,
  });

  static const defaultPolicy = EquipmentProtectionPolicy();
}

EquipmentProtectionReason? equipmentProtectionReason(
  Equipment equipment, {
  required Set<int> equippedEquipmentIds,
  Set<int> activeFormationEquipmentIds = const {},
  EquipmentProtectionPolicy policy = EquipmentProtectionPolicy.defaultPolicy,
}) {
  if (activeFormationEquipmentIds.contains(equipment.id)) {
    return EquipmentProtectionReason.currentFormation;
  }
  if (isEquipmentEquippedBySlot(equipment, equippedEquipmentIds)) {
    return EquipmentProtectionReason.equipped;
  }
  if (equipment.isLocked) return EquipmentProtectionReason.locked;
  if (equipment.isLineageHeritage) {
    return EquipmentProtectionReason.lineageHeritage;
  }
  final minTier = policy.protectTierAtOrAbove;
  if (minTier != null && equipment.tier.index >= minTier.index) {
    return EquipmentProtectionReason.highTier;
  }
  if (policy.protectedObtainedFrom.contains(equipment.obtainedFrom)) {
    return EquipmentProtectionReason.protectedSource;
  }
  if (policy.protectPersonalHistory &&
      (equipment.lores.isNotEmpty ||
          equipment.previousOwnerCharacterIds.isNotEmpty)) {
    return EquipmentProtectionReason.story;
  }
  return null;
}

bool isEquipmentProtected(
  Equipment equipment, {
  required Set<int> equippedEquipmentIds,
  Set<int> activeFormationEquipmentIds = const {},
  EquipmentProtectionPolicy policy = EquipmentProtectionPolicy.defaultPolicy,
}) =>
    equipmentProtectionReason(
      equipment,
      equippedEquipmentIds: equippedEquipmentIds,
      activeFormationEquipmentIds: activeFormationEquipmentIds,
      policy: policy,
    ) !=
    null;

/// 出售价：基价[tier] × (1 + factor × enhanceLevel) 向下取整。
int equipmentSellPrice(
  EquipmentTier tier,
  int enhanceLevel,
  EquipmentDisposalConfig c,
) {
  final base = c.sellPrice[tier.index];
  return (base * (1 + c.sellEnhanceFactor * enhanceLevel)).floor();
}

/// 分解产出：品阶基础磨剑石/心血结晶 + 强化额外磨剑石（enhanceLevel × perLevel）。
DisassembleRewards equipmentDisassembleRewards(
  EquipmentTier tier,
  int enhanceLevel,
  EquipmentDisposalConfig c,
) {
  return DisassembleRewards(
    mojianshi:
        c.disassembleMojianshi[tier.index] +
        enhanceLevel * c.disassembleEnhanceMojianshiPerLevel,
    xinxuejiejing: c.disassembleXinxuejiejing[tier.index],
  );
}
