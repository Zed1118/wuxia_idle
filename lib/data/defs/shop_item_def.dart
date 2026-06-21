import '../../core/domain/enums.dart';

/// 江湖商店商品静态定义（P1 材料经济 Task 4，GDD §5.1）。
///
/// 加载源：`data/shop.yaml`。
///
/// **标价二选一（balance T3 经验丹动态标价）**：
/// - 固定标价商品（磨剑石/心血结晶）：`price != null`，`priceLayerFraction == null`。
/// - 动态标价商品（经验丹）：`price == null`，`priceLayerFraction != null`。
///   实际价格 = `(founderEtl × priceLayerFraction).round()`，由 [ShopService.effectivePrice] 计算。
///
/// 设计约束（§5.1 商店）：
/// - 固定标价商品上限 100000 银两（_enforceRedLines 校验）。
/// - 动态标价商品不做上限校验（由 ETL 上限间接约束）。
class ShopItemDef {
  /// 商品唯一 id，如 `shop_mojianshi`。
  final String id;

  /// 购买后入库的 InventoryItem.defId，如 `item_mojianshi`。
  final String itemDefId;

  /// 商品类型，对应 [ItemType] 枚举。
  final ItemType itemType;

  /// 银两固定标价（单件）。磨剑石/心血结晶等绝对价值材料使用。
  /// [priceLayerFraction] 非空时本字段为 null。
  final int? price;

  /// 动态标价系数（经验丹等随境界缩放商品使用）。
  /// 实际价格 = `(founderEtl × priceLayerFraction).round()`。
  /// [price] 非空时本字段为 null。
  final double? priceLayerFraction;

  /// 货架分组 key，如 `material`。
  final String category;

  const ShopItemDef({
    required this.id,
    required this.itemDefId,
    required this.itemType,
    this.price,
    this.priceLayerFraction,
    required this.category,
  }) : assert(
          (price != null) != (priceLayerFraction != null),
          'ShopItemDef must have exactly one of price or priceLayerFraction',
        );

  factory ShopItemDef.fromYaml(Map<String, dynamic> y) {
    final hasPrice = y.containsKey('price') && y['price'] != null;
    final hasFraction = y.containsKey('price_layer_fraction') &&
        y['price_layer_fraction'] != null;

    if (!hasPrice && !hasFraction) {
      throw StateError(
        'ShopItemDef ${y['id']}: must have either price or price_layer_fraction',
      );
    }
    if (hasPrice && hasFraction) {
      throw StateError(
        'ShopItemDef ${y['id']}: cannot have both price and price_layer_fraction',
      );
    }

    return ShopItemDef(
      id: y['id'] as String,
      itemDefId: y['itemDefId'] as String,
      itemType: ItemType.values.byName(y['itemType'] as String),
      price: hasPrice ? (y['price'] as num).toInt() : null,
      priceLayerFraction:
          hasFraction ? (y['price_layer_fraction'] as num).toDouble() : null,
      category: y['category'] as String,
    );
  }

  /// 是否为动态定价商品（随 founder ETL 浮动）。
  bool get isDynamicPrice => priceLayerFraction != null;

  @override
  String toString() =>
      'ShopItemDef(id=$id, itemDefId=$itemDefId, '
      'price=$price, priceLayerFraction=$priceLayerFraction)';
}
