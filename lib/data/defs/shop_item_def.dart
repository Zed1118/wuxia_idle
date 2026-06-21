import '../../core/domain/enums.dart';

/// 江湖商店商品静态定义（P1 材料经济 Task 4，GDD §5.1）。
///
/// 加载源：`data/shop.yaml`。P1 阶段只卖 2 种强化材料：
/// 磨剑石（`item_mojianshi`）和心血结晶（`item_xinxuejiejing`）。
///
/// 设计约束（§5.1 商店）：
/// - 固定标价（无随机/限购/刷新），纯静态 def。
/// - 标价上限 100000 银两（_enforceRedLines 校验）。
class ShopItemDef {
  /// 商品唯一 id，如 `shop_mojianshi`。
  final String id;

  /// 购买后入库的 InventoryItem.defId，如 `item_mojianshi`。
  final String itemDefId;

  /// 商品类型，对应 [ItemType] 枚举。
  final ItemType itemType;

  /// 银两标价（单件）。
  final int price;

  /// 货架分组 key，如 `material`。
  final String category;

  const ShopItemDef({
    required this.id,
    required this.itemDefId,
    required this.itemType,
    required this.price,
    required this.category,
  });

  factory ShopItemDef.fromYaml(Map<String, dynamic> y) => ShopItemDef(
        id: y['id'] as String,
        itemDefId: y['itemDefId'] as String,
        itemType: ItemType.values.byName(y['itemType'] as String),
        price: (y['price'] as num).toInt(),
        category: y['category'] as String,
      );

  @override
  String toString() =>
      'ShopItemDef(id=$id, itemDefId=$itemDefId, price=$price)';
}
