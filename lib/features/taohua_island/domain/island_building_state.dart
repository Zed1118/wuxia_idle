import 'package:isar_community/isar.dart';

import 'island_building_type.dart';

part 'island_building_state.g.dart';

/// 单个桃花岛建筑的运行时状态（嵌入 SaveData）。
///
/// @embedded 类要求无参默认构造，字段全有默认值。
/// [IslandProductionService.settle] 通过 [copy] 操作副本，不改原对象。
@embedded
class IslandBuildingState {
  @Enumerated(EnumType.name)
  BuildingType type = BuildingType.tieJiangChang;

  int level = 1;

  /// 库存量。原料建筑（kind==source）= 原料量；
  /// 加工建筑（kind==processor）= 成品量。
  /// 内部全程保持 double，只有收取（Task 6）才 floor。
  double stored = 0;

  /// processor 选中的配方 id；null = 未生产。source 建筑恒为 null。
  String? activeRecipeId;

  /// 深拷贝（基本类型全值拷贝，无嵌套引用）。
  IslandBuildingState copy() => IslandBuildingState()
    ..type = type
    ..level = level
    ..stored = stored
    ..activeRecipeId = activeRecipeId;
}

/// 便捷构造函数（让调用方能用命名参数保持可读性）。
extension IslandBuildingStateFactory on IslandBuildingState {
  static IslandBuildingState create({
    required BuildingType type,
    int level = 1,
    double stored = 0,
    String? activeRecipeId,
  }) =>
      IslandBuildingState()
        ..type = type
        ..level = level
        ..stored = stored
        ..activeRecipeId = activeRecipeId;
}
