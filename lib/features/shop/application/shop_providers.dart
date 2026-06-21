import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/inventory_item.dart';
import '../../../data/defs/shop_item_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';

part 'shop_providers.g.dart';

/// 银两余额（材料经济 P1 Task 6，GDD §5.1）。
///
/// 读 Isar `inventoryItems` 表中 defId='item_silver' 行的 quantity。
/// 行不存在（从未获得银两）返回 0。
@riverpod
Future<int> silverBalance(Ref ref) async {
  final item =
      await IsarSetup.instance.inventoryItems.getByDefId('item_silver');
  return item?.quantity ?? 0;
}

/// 商店是否已解锁（材料经济 P1 Task 6，GDD §5.1）。
///
/// 谓词：`item_silver` 行存在即视为「曾获得银两」→ 解锁，沿兵器谱
/// `equipmentCatalogCount > 0` 体例。
/// quantity=0 也算解锁（曾获得过但全花完）。
@riverpod
Future<bool> shopUnlocked(Ref ref) async {
  final item =
      await IsarSetup.instance.inventoryItems.getByDefId('item_silver');
  return item != null;
}

/// 货架商品列表（材料经济 P1 Task 6，GDD §5.1）。
///
/// 同步读 [GameRepository.instance.shopItemDefs]（启动时 loadAllDefs 已加载）。
/// 返回 def 列表，UI 层按 category / price 自行渲染。
@riverpod
List<ShopItemDef> shopItemList(Ref ref) {
  return GameRepository.instance.shopItemDefs.values.toList();
}
