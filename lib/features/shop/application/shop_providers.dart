import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/character_providers.dart';
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

/// 祖师（founder）当前单层所需经验（balance T3 动态标价）。
///
/// 读 active 角色中 isFounder=true 的 `experienceToNextLayer`。
/// - 无 founder（存档异常）返回 null → UI 隐藏动态价商品或禁用购买。
/// - 随 founder 境界推进，provider invalidate 后自动刷新商店显示价。
@riverpod
Future<int?> founderEtl(Ref ref) async {
  final ids = await ref.watch(activeCharacterIdsProvider.future);
  for (final id in ids) {
    final c = await ref.watch(characterByIdProvider(id).future);
    if (c != null && c.isFounder) return c.experienceToNextLayer;
  }
  return null; // 无 founder（异常存档兜底）
}
