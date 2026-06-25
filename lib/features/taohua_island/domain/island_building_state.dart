import 'island_building_type.dart';

/// 单个桃花岛建筑的运行时状态（纯 Dart 可变类）。
///
/// Task 5 再加 Isar `@embedded` 注解；本任务保持纯逻辑、零持久化依赖，
/// 以便 [IslandProductionService.settle] 可在无 Isar 环境下被单测覆盖。
class IslandBuildingState {
  BuildingType type;
  int level;

  /// 库存量。原料建筑（kind==source）= 原料量；
  /// 加工建筑（kind==processor）= 成品量。
  /// 内部全程保持 double，只有收取（Task 6）才 floor。
  double stored;

  /// processor 选中的配方 id；null = 未生产。source 建筑恒为 null。
  String? activeRecipeId;

  IslandBuildingState({
    required this.type,
    this.level = 1,
    this.stored = 0,
    this.activeRecipeId,
  });

  /// 深拷贝（基本类型全值拷贝，无嵌套引用）。
  IslandBuildingState copy() => IslandBuildingState(
        type: type,
        level: level,
        stored: stored,
        activeRecipeId: activeRecipeId,
      );
}
