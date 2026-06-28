import '../../../core/domain/enums.dart';
import '../../../core/domain/item_usage.dart';
import '../../../data/game_repository.dart';
import '../../taohua_island/domain/island_building_type.dart';

/// 背包资源用途反查。
///
/// 数据源限定为现有配置与已接入的消费路径，不新增经济系统：
/// items.yaml 道具效果、shop.yaml 购买扣银两、numbers.yaml 装备强化/保底、
/// 桃花岛升级/加工消耗。
class ItemUsageLookupService {
  const ItemUsageLookupService(this.repo);

  final GameRepository repo;

  List<ItemUsage> usagesFor(String itemId) {
    final result = <ItemUsage>[];

    _addItemUse(result, itemId);
    _addEquipmentUse(result, itemId);
    _addShopUse(result, itemId);
    _addTaohuaIslandUse(result, itemId);

    return List.unmodifiable(result);
  }

  void _addItemUse(List<ItemUsage> result, String itemId) {
    final def = repo.itemDefs[itemId];
    if (def == null) return;

    switch (def.type) {
      case ItemType.jingYanDan:
        result.add(const ItemUsage(kind: ItemUsageKind.realmProgress));
      case ItemType.techniqueScroll:
        result.add(
          ItemUsage(
            kind: ItemUsageKind.techniqueUnlock,
            targetId: def.unlockSkillId,
          ),
        );
      default:
        if (def.hasRecoveryEffect) {
          result.add(const ItemUsage(kind: ItemUsageKind.injuryRecovery));
        }
    }
  }

  void _addEquipmentUse(List<ItemUsage> result, String itemId) {
    final type = repo.itemDefs[itemId]?.type ?? ItemType.fromDefId(itemId);
    switch (type) {
      case ItemType.moJianShi:
        if (repo.numbers.enhancement.mojianshiCost.isNotEmpty) {
          result.add(const ItemUsage(kind: ItemUsageKind.equipmentEnhancement));
        }
      case ItemType.miscMaterial:
        if (itemId == 'item_duancai' &&
            repo.numbers.enhancement.duancaiCost.isNotEmpty) {
          result.add(const ItemUsage(kind: ItemUsageKind.equipmentEnhancement));
        }
        if (itemId == 'item_kaifeng_fucai' &&
            repo.numbers.forging.slots.any((s) => s.fucaiCost > 0)) {
          result.add(const ItemUsage(kind: ItemUsageKind.equipmentForging));
        }
      case ItemType.xinXueJieJing:
        if (repo.numbers.enhancement.crystalGuarantees.isNotEmpty) {
          result.add(const ItemUsage(kind: ItemUsageKind.equipmentGuarantee));
        }
      default:
        break;
    }
  }

  void _addShopUse(List<ItemUsage> result, String itemId) {
    if (itemId == 'item_silver' && repo.shopItemDefs.isNotEmpty) {
      result.add(const ItemUsage(kind: ItemUsageKind.shopPurchaseCurrency));
    }
  }

  void _addTaohuaIslandUse(List<ItemUsage> result, String itemId) {
    final buildings = repo.numbers.taohuaIsland.buildings.entries;
    var hasSilverUpgrade = false;

    for (final entry in buildings) {
      final building = entry.value;
      if (itemId == 'item_silver' &&
          building.upgradeSilverLevels.any((cost) => cost > 0)) {
        hasSilverUpgrade = true;
      }

      if (building.upgradeMaterialItem == itemId &&
          building.upgradeMaterialBase > 0) {
        result.add(
          ItemUsage(
            kind: ItemUsageKind.islandBuildingUpgrade,
            targetId: entry.key.name,
          ),
        );
      }

      if (building.kind == BuildingKind.processor &&
          building.inputItem == itemId &&
          building.recipes.isNotEmpty) {
        result.add(
          ItemUsage(
            kind: ItemUsageKind.islandRecipeInput,
            targetId: entry.key.name,
          ),
        );
      }
    }

    if (hasSilverUpgrade) {
      result.add(const ItemUsage(kind: ItemUsageKind.islandUpgradeCurrency));
    }
  }
}
