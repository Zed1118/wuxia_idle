import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/item_usage.dart';
import 'package:wuxia_idle/core/domain/resource_overview_display.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/resource_overview/application/resource_overview_service.dart';
import 'package:wuxia_idle/features/resource_overview/domain/resource_overview_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs();
  });

  InventoryItem item(String defId, ItemType type, int quantity) {
    return InventoryItem()
      ..defId = defId
      ..itemType = type
      ..quantity = quantity
      ..firstObtainedAt = DateTime(2026)
      ..lastObtainedAt = DateTime(2026);
  }

  ResourceOverviewSection section(
    List<ResourceOverviewSection> sections,
    ResourceOverviewCategory category,
  ) {
    return sections.singleWhere((s) => s.category == category);
  }

  test(
    'builds fixed management categories from existing inventory and defs',
    () {
      final sections = ResourceOverviewService(repo).build([
        item('item_silver', ItemType.silver, 320),
        item('item_mojianshi', ItemType.moJianShi, 18),
        item('item_jingtie', ItemType.miscMaterial, 44),
        item('item_liaoshangdan', ItemType.miscMaterial, 2),
        item('item_scroll_kai_bei_shou', ItemType.techniqueScroll, 1),
      ]);

      expect(sections, hasLength(ResourceOverviewCategory.values.length));

      final currency = section(sections, ResourceOverviewCategory.currency);
      expect(currency.items.single.defId, 'item_silver');
      expect(currency.items.single.quantity, 320);
      expect(
        currency.items.single.usages.map((u) => u.kind),
        contains(ItemUsageKind.shopPurchaseCurrency),
      );
      expect(
        currency.items.single.usageGroups,
        containsAll([ResourceUsageGroup.island, ResourceUsageGroup.shopping]),
      );
      expect(
        currency.items.single.consumptionDirection,
        ResourceConsumptionDirection.mixed,
      );

      final equipment = section(
        sections,
        ResourceOverviewCategory.equipmentMaterial,
      );
      expect(equipment.items.map((i) => i.defId), contains('item_mojianshi'));
      expect(
        equipment.items.map((i) => i.defId),
        contains('item_xinxuejiejing'),
      );
      expect(
        equipment.items.map((i) => i.defId),
        isNot(contains('item_jingtie')),
      );
      final mojianshi = equipment.items.singleWhere(
        (i) => i.defId == 'item_mojianshi',
      );
      expect(mojianshi.usageGroups, [ResourceUsageGroup.equipment]);
      expect(
        mojianshi.consumptionDirection,
        ResourceConsumptionDirection.equipment,
      );

      final island = section(sections, ResourceOverviewCategory.islandProduct);
      expect(island.items.map((i) => i.defId), contains('item_jingtie'));
      expect(island.items.map((i) => i.defId), contains('item_kaifeng_fucai'));

      final pills = section(sections, ResourceOverviewCategory.pill);
      expect(pills.items.map((i) => i.defId), contains('item_liaoshangdan'));
      final recoveryPill = pills.items.singleWhere(
        (i) => i.defId == 'item_liaoshangdan',
      );
      expect(recoveryPill.usageGroups, [ResourceUsageGroup.recovery]);
      expect(
        recoveryPill.consumptionDirection,
        ResourceConsumptionDirection.recovery,
      );
      expect(
        pills.items.map((i) => i.defId),
        contains('item_jingyandan_small'),
      );

      final scrolls = section(sections, ResourceOverviewCategory.scroll);
      expect(
        scrolls.items.map((i) => i.defId),
        contains('item_scroll_kai_bei_shou'),
      );
    },
  );

  test('keeps zero quantity core resources visible for planning', () {
    final sections = ResourceOverviewService(repo).build(const []);

    final equipment = section(
      sections,
      ResourceOverviewCategory.equipmentMaterial,
    );
    final crystal = equipment.items.singleWhere(
      (i) => i.defId == 'item_xinxuejiejing',
    );

    expect(crystal.quantity, 0);
    expect(
      crystal.usages.map((u) => u.kind),
      contains(ItemUsageKind.equipmentGuarantee),
    );
  });
}
