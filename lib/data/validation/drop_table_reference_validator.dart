import '../../core/domain/enums.dart';
import '../../features/tower/domain/tower_floor_def.dart';
import '../defs/drop_entry.dart';
import '../defs/stage_def.dart';

abstract final class DropTableReferenceValidator {
  static void validate({
    required Map<String, StageDef> stageDefs,
    required List<TowerFloorDef> towerFloors,
    required Set<String> equipmentIds,
  }) {
    void check(String owner, List<DropEntry> table) {
      for (final entry in table) {
        switch (entry) {
          case EquipmentDrop(:final equipmentDefId):
            if (!equipmentIds.contains(equipmentDefId)) {
              throw StateError(
                '$owner dropTable 悬空 equipmentDefId=$equipmentDefId'
                '（不在 equipment.yaml，runtime 取装备会崩）',
              );
            }
          case ItemDrop(:final inventoryItemDefId):
            if (ItemType.fromDefId(inventoryItemDefId) ==
                ItemType.miscMaterial) {
              throw StateError(
                '$owner dropTable 悬空 inventoryItemDefId=$inventoryItemDefId'
                '（ItemType.fromDefId 兜底 miscMaterial，疑似拼错/未注册物品）',
              );
            }
        }
      }
    }

    for (final stage in stageDefs.values) {
      check('stage ${stage.id}', stage.dropTable);
    }
    for (final floor in towerFloors) {
      check('tower floor ${floor.floorIndex}', floor.dropTable);
    }
  }
}
