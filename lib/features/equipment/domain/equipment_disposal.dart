import '../../../core/domain/enums.dart';

/// 装备出售/分解配置（numbers.yaml `equipment.disposal`，2026-06-26 红线推翻）。
/// 7 元数组按 [EquipmentTier] index（寻常货=0 … 神物=6）。**初值待真机校**。
class EquipmentDisposalConfig {
  final List<int> sellPrice;
  final double sellEnhanceFactor;
  final List<int> disassembleMojianshi;
  final List<int> disassembleXinxuejiejing;
  final int disassembleEnhanceMojianshiPerLevel;

  const EquipmentDisposalConfig({
    required this.sellPrice,
    required this.sellEnhanceFactor,
    required this.disassembleMojianshi,
    required this.disassembleXinxuejiejing,
    required this.disassembleEnhanceMojianshiPerLevel,
  });

  factory EquipmentDisposalConfig.fromYaml(Map<String, dynamic> y) =>
      EquipmentDisposalConfig(
        sellPrice: (y['sell_price'] as List).map((e) => (e as num).toInt()).toList(),
        sellEnhanceFactor: (y['sell_enhance_factor'] as num).toDouble(),
        disassembleMojianshi: (y['disassemble_mojianshi'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
        disassembleXinxuejiejing: (y['disassemble_xinxuejiejing'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
        disassembleEnhanceMojianshiPerLevel:
            (y['disassemble_enhance_mojianshi_per_level'] as num).toInt(),
      );
}

/// 分解产出（强化材料）。
class DisassembleRewards {
  final int mojianshi;
  final int xinxuejiejing;
  const DisassembleRewards({required this.mojianshi, required this.xinxuejiejing});
}

/// 出售价：基价[tier] × (1 + factor × enhanceLevel) 向下取整。
int equipmentSellPrice(EquipmentTier tier, int enhanceLevel, EquipmentDisposalConfig c) {
  final base = c.sellPrice[tier.index];
  return (base * (1 + c.sellEnhanceFactor * enhanceLevel)).floor();
}

/// 分解产出：品阶基础磨剑石/心血结晶 + 强化额外磨剑石（enhanceLevel × perLevel）。
DisassembleRewards equipmentDisassembleRewards(
    EquipmentTier tier, int enhanceLevel, EquipmentDisposalConfig c) {
  return DisassembleRewards(
    mojianshi: c.disassembleMojianshi[tier.index] +
        enhanceLevel * c.disassembleEnhanceMojianshiPerLevel,
    xinxuejiejing: c.disassembleXinxuejiejing[tier.index],
  );
}
