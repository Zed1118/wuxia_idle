import '../../../core/domain/enums.dart';
import '../../../data/defs/drop_entry.dart';
import '../../../data/defs/equipment_def.dart';
import '../../../data/defs/shop_item_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../seclusion/domain/seclusion_map_def.dart';
import '../../tower/domain/tower_floor_def.dart';
import '../domain/equipment_source.dart';

class EquipmentSourceLookup {
  const EquipmentSourceLookup(this.repository);

  final GameRepository repository;

  List<EquipmentSource> sourcesFor(String equipmentDefId) {
    final def = repository.getEquipment(equipmentDefId);
    return sourcesForEquipmentDef(
      def,
      stages: repository.stageDefs.values,
      towerFloors: repository.towerFloors,
      seclusionMaps: repository.seclusionMaps,
      shopItems: repository.shopItemDefs.values,
    );
  }

  static List<EquipmentSource> sourcesForEquipmentDef(
    EquipmentDef def, {
    required Iterable<StageDef> stages,
    required Iterable<TowerFloorDef> towerFloors,
    required Iterable<SeclusionMapDef> seclusionMaps,
    required Iterable<ShopItemDef> shopItems,
  }) {
    final sources = <EquipmentSource>[];
    final keys = <String>{};

    void add(EquipmentSource source) {
      if (keys.add(source.dedupeKey)) {
        sources.add(source);
      }
    }

    for (final stage in stages) {
      if (!_containsEquipment(stage.dropTable, def.id)) continue;
      if (stage.stageType == StageType.mainline && stage.chapterIndex != null) {
        add(
          EquipmentSource.mainline(
            stageId: stage.id,
            stageName: stage.name,
            chapterIndex: stage.chapterIndex!,
            isBoss: stage.isBossStage,
          ),
        );
      } else {
        add(
          EquipmentSource.stage(
            stageId: stage.id,
            stageName: stage.name,
            isBoss: stage.isBossStage,
          ),
        );
      }
    }

    for (final floor in towerFloors) {
      if (!_containsEquipment(floor.dropTable, def.id)) continue;
      add(
        EquipmentSource.tower(
          floorIndex: floor.floorIndex,
          isBoss: floor.isBoss,
        ),
      );
    }

    for (final map in seclusionMaps) {
      if (!_containsEquipment(map.dropTable, def.id)) continue;
      add(EquipmentSource.seclusion(mapName: map.mapName));
    }

    for (final item in shopItems) {
      if (item.itemDefId == def.id) {
        add(EquipmentSource.shop(shopId: item.id));
      }
    }

    for (final tag in def.dropSourceTags) {
      final source = _sourceFromTag(tag);
      if (source != null) add(source);
    }

    return sources;
  }

  static bool _containsEquipment(List<DropEntry> table, String equipmentDefId) {
    for (final entry in table) {
      if (entry is EquipmentDrop && entry.equipmentDefId == equipmentDefId) {
        return true;
      }
    }
    return false;
  }

  static EquipmentSource? _sourceFromTag(String tag) {
    if (tag.startsWith('mainline_ch')) {
      return null;
    }
    if (tag.startsWith('tower_')) {
      return null;
    }
    if (tag.contains('shop')) {
      return const EquipmentSource.shop();
    }
    switch (tag) {
      case 'yiLiu_quest':
      case 'jueDing_unlock':
      case 'zongShi_unlock':
      case 'wuSheng_unlock':
      case 'ascension_reward':
      case 'inner_demon_reward':
      case 'mass_battle_merit':
        return EquipmentSource.tag(tag);
      default:
        return null;
    }
  }
}
