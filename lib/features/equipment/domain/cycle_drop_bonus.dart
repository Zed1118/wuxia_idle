/// 周目普通掉落材料加成配置(numbers.yaml `cycle_drop_bonus`,周目平衡 2026-06-26)。
///
/// 二周目起(cycle≥2)主线/扫荡普通掉落的「材料类」物品数量按 [materialQtyMultNgPlus]
/// 放大,加大 NG+ 回报。装备/经验丹/秘籍/银两不受影响(见 drop_service
/// `isCycleBonusMaterial`)。守 §5.4:仅放大掉落数量,非战斗数值膨胀。
class CycleDropBonusConfig {
  /// 二周目起材料类掉落数量倍率(≥1.0)。1.0 = 不加成。
  final double materialQtyMultNgPlus;

  const CycleDropBonusConfig({required this.materialQtyMultNgPlus});

  /// 缺省 = 不加成(fixture 不带该段 / yaml 缺失时,旧行为不变)。
  static const none = CycleDropBonusConfig(materialQtyMultNgPlus: 1.0);

  factory CycleDropBonusConfig.fromYaml(Map<String, dynamic> y) {
    if (y.isEmpty) return none;
    return CycleDropBonusConfig(
      materialQtyMultNgPlus:
          (y['material_qty_mult_ng_plus'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// 按周目取材料数量倍率:cycle≥2 用 [materialQtyMultNgPlus],否则 1.0。
  double qtyMultFor(int cycle) => cycle >= 2 ? materialQtyMultNgPlus : 1.0;
}
