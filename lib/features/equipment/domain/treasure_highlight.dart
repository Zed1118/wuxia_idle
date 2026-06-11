import '../../../core/domain/enums.dart';

/// 爆品动画展示用的单件高亮装备快照(从 EquipmentDef 投影,纯数据便于测试)。
class TreasureHighlight {
  final String defId;
  final String name;
  final EquipmentTier tier;
  final EquipmentSlot slot;
  final String iconPath;

  const TreasureHighlight({
    required this.defId,
    required this.name,
    required this.tier,
    required this.slot,
    required this.iconPath,
  });
}

/// 从候选中筛 tier ≥ [minTier] 的最高 tier 那件(并列取首);无则 null。
/// EquipmentTier 声明序即由低到高,用 .index 比较。
TreasureHighlight? pickTreasureHighlight(
    List<TreasureHighlight> candidates, EquipmentTier minTier) {
  TreasureHighlight? best;
  for (final c in candidates) {
    if (c.tier.index < minTier.index) continue;
    if (best == null || c.tier.index > best.tier.index) best = c;
  }
  return best;
}
