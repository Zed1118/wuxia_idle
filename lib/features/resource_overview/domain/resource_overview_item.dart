import '../../../core/domain/item_source.dart';
import '../../../core/domain/item_usage.dart';
import '../../../core/domain/resource_overview_display.dart';

enum ResourceOverviewCategory {
  currency,
  equipmentMaterial,
  islandProduct,
  pill,
  scroll,
}

class ResourceOverviewItem {
  const ResourceOverviewItem({
    required this.defId,
    required this.name,
    required this.quantity,
    required this.category,
    required this.usages,
    required this.sources,
    required this.usageGroups,
    required this.consumptionDirection,
  });

  final String defId;
  final String name;
  final int quantity;
  final ResourceOverviewCategory category;
  final List<ItemUsage> usages;
  final List<ItemSource> sources;
  final List<ResourceUsageGroup> usageGroups;
  final ResourceConsumptionDirection consumptionDirection;
}

class ResourceOverviewSection {
  const ResourceOverviewSection({required this.category, required this.items});

  final ResourceOverviewCategory category;
  final List<ResourceOverviewItem> items;
}
