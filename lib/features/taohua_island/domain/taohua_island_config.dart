import 'island_building_type.dart';

class BuildingConfig {
  final BuildingType type;
  final BuildingKind kind;
  final String? outputItem; // source 专用
  final String? inputItem; // processor 专用
  final double baseRatePerHour; // source 专用，processor 给 0
  final int capBase;
  final int capPerLevel;
  final int maxLevel;
  final int upgradeSilverBase;
  final int upgradeSilverPerLevel;
  final String upgradeMaterialItem;
  final int upgradeMaterialBase;
  final int realmUnlockIndex;
  final List<RecipeDef> recipes; // source 给 const []

  const BuildingConfig({
    required this.type,
    required this.kind,
    this.outputItem,
    this.inputItem,
    required this.baseRatePerHour,
    required this.capBase,
    required this.capPerLevel,
    required this.maxLevel,
    required this.upgradeSilverBase,
    required this.upgradeSilverPerLevel,
    required this.upgradeMaterialItem,
    required this.upgradeMaterialBase,
    required this.realmUnlockIndex,
    required this.recipes,
  });

  /// 当前等级对应的库存上限（level 从 1 开始）
  int capFor(int level) => capBase + (level - 1) * capPerLevel;

  /// 当前等级升级所需银两（level 从 1 开始，level=1 升 2 时消耗）
  int upgradeSilverFor(int level) =>
      upgradeSilverBase + (level - 1) * upgradeSilverPerLevel;

  /// 当前等级升级所需材料数量
  // 材料成本 = base × level（无独立 perLevel 字段，刻意按等级线性递增）
  int upgradeMaterialFor(int level) =>
      upgradeMaterialBase + (level - 1) * upgradeMaterialBase;

  /// 按 recipe_id 查找配方，找不到返回 null
  RecipeDef? recipeById(String id) {
    for (final r in recipes) {
      if (r.recipeId == id) return r;
    }
    return null;
  }

  factory BuildingConfig.fromYaml(BuildingType type, Map<String, dynamic> y) {
    final kindStr = y['kind'] as String;
    final kind = switch (kindStr) {
      'source' => BuildingKind.source,
      'processor' => BuildingKind.processor,
      _ => throw ArgumentError('未知建筑 kind: $kindStr'),
    };

    final String? outputItem =
        kind == BuildingKind.source ? y['output_item'] as String : null;
    final String? inputItem =
        kind == BuildingKind.processor ? y['input_item'] as String : null;
    final double baseRatePerHour = kind == BuildingKind.source
        ? (y['base_rate_per_hour'] as num).toDouble()
        : 0.0;

    final List<RecipeDef> recipes = kind == BuildingKind.processor
        ? (y['recipes'] as List)
            .map((e) => RecipeDef.fromYaml((e as Map).cast<String, dynamic>()))
            .toList()
        : const [];

    return BuildingConfig(
      type: type,
      kind: kind,
      outputItem: outputItem,
      inputItem: inputItem,
      baseRatePerHour: baseRatePerHour,
      capBase: (y['cap_base'] as num).toInt(),
      capPerLevel: (y['cap_per_level'] as num).toInt(),
      maxLevel: (y['max_level'] as num).toInt(),
      upgradeSilverBase: (y['upgrade_silver_base'] as num).toInt(),
      upgradeSilverPerLevel: (y['upgrade_silver_per_level'] as num).toInt(),
      upgradeMaterialItem: y['upgrade_material_item'] as String,
      upgradeMaterialBase: (y['upgrade_material_base'] as num).toInt(),
      realmUnlockIndex: (y['realm_unlock_index'] as num?)?.toInt() ?? 0,
      recipes: recipes,
    );
  }
}

class TaohuaIslandConfig {
  final int capHours;
  final int unlockChapterIndex;
  final Map<BuildingType, BuildingConfig> buildings;

  const TaohuaIslandConfig({
    required this.capHours,
    required this.unlockChapterIndex,
    required this.buildings,
  });

  BuildingConfig buildingOf(BuildingType t) => buildings[t]!;

  factory TaohuaIslandConfig.fromYaml(Map<String, dynamic> y) {
    final capHours = (y['cap_hours'] as num).toInt();
    final unlockChapterIndex = (y['unlock_chapter_index'] as num).toInt();

    final buildingsRaw = y['buildings'] as Map;
    final buildings = <BuildingType, BuildingConfig>{};
    for (final entry in buildingsRaw.entries) {
      final type = buildingTypeFromYamlKey(entry.key as String);
      final bMap = (entry.value as Map).cast<String, dynamic>();
      buildings[type] = BuildingConfig.fromYaml(type, bMap);
    }

    return TaohuaIslandConfig(
      capHours: capHours,
      unlockChapterIndex: unlockChapterIndex,
      buildings: buildings,
    );
  }
}
