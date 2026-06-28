import '../../../core/domain/enums.dart';
import '../../../core/domain/item_source.dart';
import '../../../data/defs/drop_entry.dart';
import '../../../data/game_repository.dart';
import '../../taohua_island/domain/island_building_type.dart';

/// 背包材料来源反查。
///
/// 数据源限定为现有配置与已接入产出路径，不新增经济系统：
/// stage/tower/seclusion dropTable、闭关固定产出、shop.yaml、
/// 装备强化失败/分解产物、桃花岛 source/processor 产出。
class MaterialSourceLookupService {
  const MaterialSourceLookupService(this.repo);

  final GameRepository repo;

  List<ItemSource> sourcesFor(String itemId) {
    final result = <ItemSource>[];
    final keys = <String>{};

    void add(ItemSource source) {
      if (keys.add(source.dedupeKey)) {
        result.add(source);
      }
    }

    _addStageSources(add, itemId);
    _addTowerSources(add, itemId);
    _addSeclusionSources(add, itemId);
    _addShopSources(add, itemId);
    _addEquipmentMaterialSources(add, itemId);
    _addIslandSources(add, itemId);

    return List.unmodifiable(result);
  }

  void _addStageSources(void Function(ItemSource) add, String itemId) {
    for (final stage in repo.stageDefs.values) {
      if (!_containsItem(stage.dropTable, itemId)) continue;
      if (stage.stageType == StageType.mainline && stage.chapterIndex != null) {
        add(
          ItemSource.mainline(
            stageId: stage.id,
            stageName: stage.name,
            chapterIndex: stage.chapterIndex!,
            isBoss: stage.isBossStage,
          ),
        );
      } else {
        add(
          ItemSource.stage(
            stageId: stage.id,
            stageName: stage.name,
            isBoss: stage.isBossStage,
          ),
        );
      }
    }
  }

  void _addTowerSources(void Function(ItemSource) add, String itemId) {
    for (final floor in repo.towerFloors) {
      if (!_containsItem(floor.dropTable, itemId)) continue;
      add(ItemSource.tower(floorIndex: floor.floorIndex, isBoss: floor.isBoss));
    }
  }

  void _addSeclusionSources(void Function(ItemSource) add, String itemId) {
    for (final map in repo.seclusionMaps) {
      final hasFixedOutput =
          itemId == 'item_mojianshi' && map.mojianshiPerHour > 0 ||
          map.itemOutputsPerHour.containsKey(itemId);
      if (hasFixedOutput || _containsItem(map.dropTable, itemId)) {
        add(ItemSource.seclusion(mapName: map.mapName));
      }
    }
  }

  void _addShopSources(void Function(ItemSource) add, String itemId) {
    for (final item in repo.shopItemDefs.values) {
      if (item.itemDefId == itemId) {
        add(ItemSource.shop(shopId: item.id));
      }
    }
  }

  void _addEquipmentMaterialSources(
    void Function(ItemSource) add,
    String itemId,
  ) {
    final type = repo.itemDefs[itemId]?.type ?? ItemType.fromDefId(itemId);
    switch (type) {
      case ItemType.moJianShi:
        add(const ItemSource.equipmentDisassembly());
      case ItemType.xinXueJieJing:
        if (repo.numbers.enhancement.crystalGainPerFailure > 0) {
          add(const ItemSource.enhancementFailure());
        }
        add(const ItemSource.equipmentDisassembly());
      default:
        break;
    }
  }

  void _addIslandSources(void Function(ItemSource) add, String itemId) {
    for (final entry in repo.numbers.taohuaIsland.buildings.entries) {
      final building = entry.value;
      if (building.kind == BuildingKind.source &&
          building.outputItem == itemId) {
        add(ItemSource.islandSource(buildingName: entry.key.name));
      }
      if (building.kind == BuildingKind.processor) {
        for (final recipe in building.recipes) {
          if (recipe.outputItem == itemId) {
            add(ItemSource.islandRecipe(recipeId: recipe.recipeId));
          }
        }
      }
    }
  }

  static bool _containsItem(List<DropEntry> table, String itemId) {
    for (final entry in table) {
      if (entry is ItemDrop && entry.inventoryItemDefId == itemId) {
        return true;
      }
    }
    return false;
  }
}
