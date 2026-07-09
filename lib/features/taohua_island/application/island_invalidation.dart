import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/application/inventory_providers.dart';
import '../../shop/application/shop_providers.dart';
import 'island_providers.dart';

/// 桃花岛操作后统一失效的 provider 集合。
///
/// 升级会扣银两/材料，收取会写入物产；这些数据同时被桃花岛 view、仓库、
/// 资源总览、顶部货币 pill 读取。集中失效避免操作后当前会话仍显示旧库存。
void invalidateAfterIslandInventoryMutation(
  void Function(ProviderOrFamily) invalidate,
) {
  invalidate(taohuaIslandViewProvider);
  invalidate(allInventoryItemsProvider);
  invalidate(inventoryQuantityByTypeProvider);
  invalidate(inventoryQuantityByDefIdProvider);
  invalidate(silverBalanceProvider);
  invalidate(shopUnlockedProvider);
}
