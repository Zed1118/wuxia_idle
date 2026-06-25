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
  final List<int> upgradeSilverLevels; // 节奏 B：per-level 升级银两曲线，长度 = maxLevel-1
  final List<int> upgradeRealmLevels; // 节奏 B：每级升级的境界 gate，长度 = maxLevel-1
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
    required this.upgradeSilverLevels,
    required this.upgradeRealmLevels,
    required this.upgradeMaterialItem,
    required this.upgradeMaterialBase,
    required this.realmUnlockIndex,
    required this.recipes,
  });

  /// 当前等级对应的库存上限（level 从 1 开始）
  int capFor(int level) => capBase + (level - 1) * capPerLevel;

  /// 当前等级升级所需银两（level 从 1 开始，level=1 升 2 时消耗）。
  /// 节奏 B：per-level 显式曲线（前低后高陡增），index = level-1。
  int upgradeSilverFor(int level) => upgradeSilverLevels[level - 1];

  /// 升到 level+1 所需的祖师境界 index（节奏 B：按等级分阶 gate）。
  int upgradeRealmFor(int level) => upgradeRealmLevels[level - 1];

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
      upgradeSilverLevels: (y['upgrade_silver_levels'] as List)
          .map((e) => (e as num).toInt())
          .toList(),
      upgradeRealmLevels: (y['upgrade_realm_levels'] as List)
          .map((e) => (e as num).toInt())
          .toList(),
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

  /// 桃花岛配置红线校验。违规时 throw [StateError]。
  ///
  /// 校验规则：
  /// - 所有 cap_base / cap_per_level ≥ 0；max_level ≥ 1；source.base_rate_per_hour ≥ 0。
  /// - processor 必须有 ≥1 recipe；source 必须有 output_item。
  /// - 每个 recipe：input_per_output > 0；rate_per_hour ≥ 0；realm_unlock_index ∈ [0, 6]。
  /// - 跨引用：recipe.output_item、source.output_item、processor.input_item ∈ [knownItemDefIds]。
  /// - 供应自洽：每个 processor 的 input_item 必须能被某个 source 的 output_item 供应。
  /// - 节奏 B：upgrade_silver_levels / upgrade_realm_levels 长度须 = max_level-1；
  ///   upgrade_realm_levels 各项 ∈ [0, 6] 且单调非减（境界 gate 不可倒退）。
  static void validate(TaohuaIslandConfig cfg, Set<String> knownItemDefIds) {
    final sourceOutputItems = <String>{};

    for (final entry in cfg.buildings.entries) {
      final b = entry.value;
      final label = entry.key.name;

      // 通用数值约束
      if (b.capBase < 0) {
        throw StateError('taohua_island: 建筑 $label cap_base ${b.capBase} < 0');
      }
      if (b.capPerLevel < 0) {
        throw StateError(
            'taohua_island: 建筑 $label cap_per_level ${b.capPerLevel} < 0');
      }
      if (b.maxLevel < 1) {
        throw StateError(
            'taohua_island: 建筑 $label max_level ${b.maxLevel} < 1');
      }

      // 节奏 B：升级曲线/境界 gate 数组长度须 = max_level-1（每级一项）
      final expectedLen = b.maxLevel - 1;
      if (b.upgradeSilverLevels.length != expectedLen) {
        throw StateError(
            'taohua_island: 建筑 $label upgrade_silver_levels 长度 '
            '${b.upgradeSilverLevels.length} ≠ max_level-1 ($expectedLen)');
      }
      if (b.upgradeRealmLevels.length != expectedLen) {
        throw StateError(
            'taohua_island: 建筑 $label upgrade_realm_levels 长度 '
            '${b.upgradeRealmLevels.length} ≠ max_level-1 ($expectedLen)');
      }
      for (var i = 0; i < b.upgradeRealmLevels.length; i++) {
        final r = b.upgradeRealmLevels[i];
        if (r < 0 || r > 6) {
          throw StateError(
              'taohua_island: 建筑 $label upgrade_realm_levels[$i] $r 须 ∈ [0, 6]');
        }
        if (i > 0 && r < b.upgradeRealmLevels[i - 1]) {
          throw StateError(
              'taohua_island: 建筑 $label upgrade_realm_levels 须单调非减'
              '（境界 gate 不可倒退）');
        }
      }

      if (b.kind == BuildingKind.source) {
        // source 必须有 output_item，且 rate ≥ 0
        // 防御:正常 fromYaml 路径 source 必有 output_item,此处兜手动构造
        final out = b.outputItem;
        if (out == null || out.isEmpty) {
          throw StateError('taohua_island: source 建筑 $label 缺少 output_item');
        }
        if (!knownItemDefIds.contains(out)) {
          throw StateError(
              'taohua_island: source 建筑 $label output_item "$out" 不在 knownItemDefIds');
        }
        if (b.baseRatePerHour < 0) {
          throw StateError(
              'taohua_island: source 建筑 $label base_rate_per_hour ${b.baseRatePerHour} < 0');
        }
        sourceOutputItems.add(out);
      } else {
        // processor 必须有 ≥1 recipe 且有 input_item
        final inp = b.inputItem;
        if (inp == null || inp.isEmpty) {
          throw StateError('taohua_island: processor 建筑 $label 缺少 input_item');
        }
        if (!knownItemDefIds.contains(inp)) {
          throw StateError(
              'taohua_island: processor 建筑 $label input_item "$inp" 不在 knownItemDefIds');
        }
        if (b.recipes.isEmpty) {
          throw StateError(
              'taohua_island: processor 建筑 $label 没有任何 recipe（至少 1 个）');
        }
        for (final r in b.recipes) {
          if (r.inputPerOutput <= 0) {
            throw StateError(
                'taohua_island: recipe ${r.recipeId} input_per_output ${r.inputPerOutput} 须 > 0');
          }
          if (r.ratePerHour < 0) {
            throw StateError(
                'taohua_island: recipe ${r.recipeId} rate_per_hour ${r.ratePerHour} < 0');
          }
          if (r.realmUnlockIndex < 0 || r.realmUnlockIndex > 6) {
            throw StateError(
                'taohua_island: recipe ${r.recipeId} realm_unlock_index '
                '${r.realmUnlockIndex} 须 ∈ [0, 6]');
          }
          if (!knownItemDefIds.contains(r.outputItem)) {
            throw StateError(
                'taohua_island: recipe ${r.recipeId} output_item '
                '"${r.outputItem}" 不在 knownItemDefIds');
          }
        }
      }
    }

    // 供应自洽：每个 processor 的 input_item 须有某个 source 产出
    for (final entry in cfg.buildings.entries) {
      final b = entry.value;
      if (b.kind != BuildingKind.processor) continue;
      final inp = b.inputItem!;
      if (!sourceOutputItems.contains(inp)) {
        throw StateError(
            'taohua_island: processor 建筑 ${entry.key.name} 的 input_item "$inp" '
            '没有任何 source 建筑供应');
      }
    }
  }

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
