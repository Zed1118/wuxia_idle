import '../../core/domain/enums.dart';

/// 装备出售/分解配置（numbers.yaml `equipment.disposal`，2026-06-26 红线推翻）。
/// 7 元数组按 [EquipmentTier] index（寻常货=0 … 神物=6）。**初值待真机校**。
///
/// 2026-07-19 自 `features/equipment/domain/equipment_disposal.dart` 逐字迁入
/// （backlog #6：numbers_config 唯一残留 data→features 边收敛；保护/计算逻辑
/// 留在 feature 原文件，经 export 保持既有 import 不破）。
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
        sellPrice: (y['sell_price'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
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
