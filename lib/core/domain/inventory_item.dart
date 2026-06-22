import 'package:isar_community/isar.dart';

import 'enums.dart';

part 'inventory_item.g.dart';

/// 背包物品（data_schema.md §4.8）。
///
/// 堆叠式：每种物品类型一行，更新 `quantity`。装备和心法不入背包
/// （各自有独立 Collection）。
@collection
class InventoryItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String defId;

  @Enumerated(EnumType.name)
  late ItemType itemType;

  int quantity = 0;

  late DateTime firstObtainedAt;
  late DateTime lastObtainedAt;
}
