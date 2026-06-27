/// 背包资源的既有消费用途。
///
/// 只描述“会花掉该 item”的系统入口；掉落来源、商店售卖来源、分解产物不放在这里。
enum ItemUsageKind {
  realmProgress,
  techniqueUnlock,
  equipmentEnhancement,
  equipmentGuarantee,
  shopPurchaseCurrency,
  islandUpgradeCurrency,
  islandBuildingUpgrade,
  islandRecipeInput,
}

class ItemUsage {
  final ItemUsageKind kind;
  final String? targetId;

  const ItemUsage({required this.kind, this.targetId});
}
