import '../../../core/domain/enums.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/item_usage.dart';
import '../../../core/domain/resource_overview_display.dart';
import '../../../data/game_repository.dart';
import '../../inventory/application/item_usage_lookup_service.dart';
import '../../inventory/application/material_source_lookup_service.dart';
import '../../taohua_island/domain/island_building_type.dart';
import '../domain/resource_overview_item.dart';

class ResourceOverviewService {
  const ResourceOverviewService(this.repo);

  final GameRepository repo;

  List<ResourceOverviewSection> build(List<InventoryItem> inventoryItems) {
    final quantities = {
      for (final item in inventoryItems) item.defId: item.quantity,
    };
    final usageLookup = ItemUsageLookupService(repo);
    final sourceLookup = MaterialSourceLookupService(repo);
    final idsByCategory = <ResourceOverviewCategory, Set<String>>{
      for (final category in ResourceOverviewCategory.values)
        category: <String>{},
    };

    idsByCategory[ResourceOverviewCategory.currency]!.add('item_silver');
    idsByCategory[ResourceOverviewCategory.equipmentMaterial]!.addAll([
      'item_mojianshi',
      'item_xinxuejiejing',
    ]);

    _addIslandProducts(idsByCategory[ResourceOverviewCategory.islandProduct]!);

    for (final def in repo.itemDefs.values) {
      if (def.type == ItemType.jingYanDan || def.hasRecoveryEffect) {
        idsByCategory[ResourceOverviewCategory.pill]!.add(def.defId);
      }
      if (def.type == ItemType.techniqueScroll) {
        idsByCategory[ResourceOverviewCategory.scroll]!.add(def.defId);
      }
    }

    return [
      for (final category in ResourceOverviewCategory.values)
        ResourceOverviewSection(
          category: category,
          items: _itemsFor(
            category: category,
            ids: idsByCategory[category]!,
            quantities: quantities,
            usageLookup: usageLookup,
            sourceLookup: sourceLookup,
          ),
        ),
    ];
  }

  void _addIslandProducts(Set<String> ids) {
    for (final building in repo.numbers.taohuaIsland.buildings.values) {
      ids.add(building.upgradeMaterialItem);
      if (building.kind == BuildingKind.source) {
        if (building.outputItem case final id?) {
          ids.add(id);
        }
      }
      if (building.kind == BuildingKind.processor) {
        if (building.inputItem case final id?) {
          ids.add(id);
        }
        if (building.secondaryInputItem case final id?) {
          ids.add(id);
        }
        for (final recipe in building.recipes) {
          ids.add(recipe.outputItem);
        }
      }
    }
  }

  List<ResourceOverviewItem> _itemsFor({
    required ResourceOverviewCategory category,
    required Set<String> ids,
    required Map<String, int> quantities,
    required ItemUsageLookupService usageLookup,
    required MaterialSourceLookupService sourceLookup,
  }) {
    final items = [
      for (final id in ids)
        if (repo.itemDefs[id] case final def?)
          _itemFor(
            id: id,
            name: def.name,
            quantity: quantities[id] ?? 0,
            category: category,
            usageLookup: usageLookup,
            sourceLookup: sourceLookup,
          ),
    ];

    items.sort((a, b) {
      final qty = b.quantity.compareTo(a.quantity);
      if (qty != 0) return qty;
      return a.name.compareTo(b.name);
    });
    return List.unmodifiable(items);
  }

  ResourceOverviewItem _itemFor({
    required String id,
    required String name,
    required int quantity,
    required ResourceOverviewCategory category,
    required ItemUsageLookupService usageLookup,
    required MaterialSourceLookupService sourceLookup,
  }) {
    final usages = usageLookup.usagesFor(id);
    final sources = sourceLookup.sourcesFor(id);
    final usageGroups = _usageGroupsFor(usages);
    return ResourceOverviewItem(
      defId: id,
      name: name,
      quantity: quantity,
      category: category,
      usages: usages,
      sources: sources,
      usageGroups: usageGroups,
      consumptionDirection: _directionFor(usageGroups),
    );
  }

  List<ResourceUsageGroup> _usageGroupsFor(List<ItemUsage> usages) {
    final groups = <ResourceUsageGroup>{};
    for (final usage in usages) {
      switch (usage.kind) {
        case ItemUsageKind.realmProgress:
        case ItemUsageKind.techniqueUnlock:
          groups.add(ResourceUsageGroup.cultivation);
        case ItemUsageKind.equipmentEnhancement:
        case ItemUsageKind.equipmentForging:
        case ItemUsageKind.equipmentGuarantee:
          groups.add(ResourceUsageGroup.equipment);
        case ItemUsageKind.islandUpgradeCurrency:
        case ItemUsageKind.islandBuildingUpgrade:
        case ItemUsageKind.islandRecipeInput:
          groups.add(ResourceUsageGroup.island);
        case ItemUsageKind.injuryRecovery:
          groups.add(ResourceUsageGroup.recovery);
        case ItemUsageKind.shopPurchaseCurrency:
          groups.add(ResourceUsageGroup.shopping);
      }
    }
    return List.unmodifiable([
      for (final group in ResourceUsageGroup.values)
        if (groups.contains(group)) group,
    ]);
  }

  ResourceConsumptionDirection _directionFor(List<ResourceUsageGroup> groups) {
    if (groups.isEmpty) return ResourceConsumptionDirection.none;
    if (groups.length > 1) return ResourceConsumptionDirection.mixed;
    return switch (groups.single) {
      ResourceUsageGroup.cultivation =>
        ResourceConsumptionDirection.cultivation,
      ResourceUsageGroup.equipment => ResourceConsumptionDirection.equipment,
      ResourceUsageGroup.island => ResourceConsumptionDirection.island,
      ResourceUsageGroup.recovery => ResourceConsumptionDirection.recovery,
      ResourceUsageGroup.shopping => ResourceConsumptionDirection.shopping,
    };
  }
}
