import '../../../core/domain/enums.dart';

/// 爆品动画展示用的单件高亮装备快照(从 EquipmentDef 投影,纯数据便于测试)。
class TreasureHighlight {
  final String defId;
  final String name;
  final EquipmentTier tier;
  final EquipmentSlot slot;
  final String iconPath;

  /// 掉落实例 roll 出的具体属性(展示用,非 def min/max)。
  final int attack;
  final int health;
  final int speed;

  /// 爆品典故金句(来自 EquipmentDef.tagline)。爆品恒有(加载层红线守),
  /// 但保留可空便于 widget test / 兜底不渲染典故区。
  final String? tagline;

  const TreasureHighlight({
    required this.defId,
    required this.name,
    required this.tier,
    required this.slot,
    required this.iconPath,
    this.attack = 0,
    this.health = 0,
    this.speed = 0,
    this.tagline,
  });
}

/// 从候选中筛 tier ≥ [minTier] 或在 [extraDisplayTiers] 内的装备,取最高 tier 那件
/// (并列取首);无则 null。EquipmentTier 声明序即由低到高,用 .index 比较。
///
/// [extraDisplayTiers]:额外允许展示的 tier 集合(如利器首次获得),不受 minTier 下限约束。
TreasureHighlight? pickTreasureHighlight(
    List<TreasureHighlight> candidates, EquipmentTier minTier,
    {Set<EquipmentTier> extraDisplayTiers = const {}}) {
  TreasureHighlight? best;
  for (final c in candidates) {
    if (c.tier.index < minTier.index && !extraDisplayTiers.contains(c.tier)) {
      continue;
    }
    if (best == null || c.tier.index > best.tier.index) best = c;
  }
  return best;
}
