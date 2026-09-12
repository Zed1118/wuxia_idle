import 'package:isar_community/isar.dart';

import 'island_building_type.dart';

part 'island_building_state.g.dart';

/// A produced item's identity remains fixed when the next recipe changes.
@embedded
class IslandProductStock {
  String outputItemId = '';
  double stored = 0;

  IslandProductStock copy() => IslandProductStock()
    ..outputItemId = outputItemId
    ..stored = stored;
}

/// 单个桃花岛建筑的运行时状态（嵌入 SaveData）。
///
/// @embedded 类要求无参默认构造，字段全有默认值。
/// [IslandProductionService.settle] 通过 [copy] 操作副本，不改原对象。
@embedded
class IslandBuildingState {
  @Enumerated(EnumType.name)
  // @embedded 占位默认值,实际建筑类型由初始化/补建流程覆盖
  BuildingType type = BuildingType.tieJiangChang;

  int level = 1;

  /// Source inventory. The legacy processor scalar is cleared by migration;
  /// new processor production writes only [productStocks].
  double stored = 0;

  List<IslandProductStock> productStocks = [];

  /// processor 选中的配方 id；null = 未生产。source 建筑恒为 null。
  String? activeRecipeId;

  /// All products share the building's existing storage capacity.
  @ignore
  double get totalStored =>
      stored +
      productStocks.fold<double>(0, (sum, stock) => sum + stock.stored);

  /// Count separately floored products; fractions of different items never mix.
  @ignore
  int get harvestableCount =>
      stored.floor() +
      productStocks.fold<int>(0, (sum, stock) => sum + stock.stored.floor());

  double productStored(String outputItemId) => productStocks
      .where((stock) => stock.outputItemId == outputItemId)
      .fold<double>(0, (sum, stock) => sum + stock.stored);

  void setProductStored(String outputItemId, double amount) {
    if (outputItemId.isEmpty || !amount.isFinite || amount < 0) {
      throw StateError('Invalid island product stock: $outputItemId / $amount');
    }
    productStocks = [
      for (final stock in productStocks)
        if (stock.outputItemId != outputItemId) stock.copy(),
      if (amount > 0)
        IslandProductStock()
          ..outputItemId = outputItemId
          ..stored = amount,
    ];
  }

  /// 深拷贝（基本类型全值拷贝，无嵌套引用）。
  IslandBuildingState copy() => IslandBuildingState()
    ..type = type
    ..level = level
    ..stored = stored
    ..productStocks = productStocks.map((stock) => stock.copy()).toList()
    ..activeRecipeId = activeRecipeId;
}
