import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/application/inventory_providers.dart';
import '../../../core/domain/enums.dart';
import '../../shop/application/shop_providers.dart';

/// 装备库存变更后统一失效的 provider 集合。
///
/// 出售/分解/强化/开锋都会同时改装备表与背包物料表。集中失效避免仓库、
/// 资源总览、材料来源弹层、顶部货币 pill 和主菜单入口继续显示旧数据。
void invalidateAfterEquipmentSale(void Function(ProviderOrFamily) invalidate) {
  _invalidateBase(invalidate);
  _invalidateItem(invalidate, 'item_silver', ItemType.silver);
  invalidate(silverBalanceProvider);
  invalidate(shopUnlockedProvider);
}

void invalidateAfterEquipmentDisassembly(
  void Function(ProviderOrFamily) invalidate,
) {
  _invalidateBase(invalidate);
  _invalidateItem(invalidate, 'item_mojianshi', ItemType.moJianShi);
  _invalidateItem(invalidate, 'item_xinxuejiejing', ItemType.xinXueJieJing);
}

void invalidateAfterEquipmentEnhancement(
  void Function(ProviderOrFamily) invalidate,
) {
  _invalidateBase(invalidate);
  _invalidateItem(invalidate, 'item_mojianshi', ItemType.moJianShi);
  _invalidateItem(invalidate, 'item_xinxuejiejing', ItemType.xinXueJieJing);
  _invalidateItem(invalidate, 'item_duancai', ItemType.miscMaterial);
}

void invalidateAfterEquipmentForging(
  void Function(ProviderOrFamily) invalidate,
) {
  _invalidateBase(invalidate);
  _invalidateItem(invalidate, 'item_kaifeng_fucai', ItemType.miscMaterial);
}

void _invalidateBase(void Function(ProviderOrFamily) invalidate) {
  invalidate(allEquipmentsProvider);
  invalidate(allInventoryItemsProvider);
}

void _invalidateItem(
  void Function(ProviderOrFamily) invalidate,
  String defId,
  ItemType type,
) {
  invalidate(inventoryQuantityByDefIdProvider(defId));
  invalidate(inventoryQuantityByTypeProvider(type));
}
