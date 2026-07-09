import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/application/inventory_providers.dart';
import 'shop_providers.dart';

/// 商店购买成功后统一失效的 provider 集合。
///
/// 购买会同时扣 `item_silver` 并增加目标物品；这些数据会被商店、仓库、
/// 材料来源弹层、强化弹窗、顶部货币 pill 读取。集中失效避免当前会话保留旧数量。
void invalidateAfterShopPurchase(void Function(ProviderOrFamily) invalidate) {
  invalidate(silverBalanceProvider);
  invalidate(shopUnlockedProvider);
  invalidate(allInventoryItemsProvider);
  invalidate(inventoryQuantityByTypeProvider);
  invalidate(inventoryQuantityByDefIdProvider);
}
