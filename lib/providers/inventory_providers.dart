import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/isar_setup.dart';
import '../data/models/enums.dart';
import '../data/models/equipment.dart';
import '../data/models/inventory_item.dart';

part 'inventory_providers.g.dart';

/// 背包物品数量（phase2_tasks T29）。
///
/// 按 [ItemType] 查 Isar `InventoryItem` 表，返回 `quantity`（行不存在或
/// quantity 为 0 都返回 0）。磨剑石 / 心血结晶都走这个 provider。
///
/// **不写 Isar**——纯查询；强化扣材料归调用方在 `writeTxn` 内修改 quantity
/// 后 `ref.invalidate(inventoryQuantityByTypeProvider(type))` 触发刷新。
@riverpod
Future<int> inventoryQuantityByType(
  InventoryQuantityByTypeRef ref,
  ItemType type,
) async {
  final item = await IsarSetup.instance.inventoryItems
      .filter()
      .itemTypeEqualTo(type)
      .findFirst();
  return item?.quantity ?? 0;
}

/// 仓库所有装备列表（phase2_tasks T29 §424）。
///
/// 一次性 `findAll` 整表，按 tier 排序方便 UI 分段（T29 仓库页不分页，
/// Demo 装备量上限 30-50 件，整表加载够用）。Phase 5 多存档时再切到
/// `ownerCharacterId` 过滤。
@riverpod
Future<List<Equipment>> allEquipments(AllEquipmentsRef ref) async {
  final list = await IsarSetup.instance.equipments.where().findAll();
  list.sort((a, b) {
    final cmp = b.tier.index.compareTo(a.tier.index);
    if (cmp != 0) return cmp;
    return b.enhanceLevel.compareTo(a.enhanceLevel);
  });
  return list;
}
