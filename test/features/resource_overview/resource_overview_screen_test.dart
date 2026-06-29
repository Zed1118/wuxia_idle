import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/item_source.dart';
import 'package:wuxia_idle/core/domain/item_usage.dart';
import 'package:wuxia_idle/core/domain/resource_overview_display.dart';
import 'package:wuxia_idle/features/resource_overview/application/resource_overview_providers.dart';
import 'package:wuxia_idle/features/resource_overview/domain/resource_overview_item.dart';
import 'package:wuxia_idle/features/resource_overview/presentation/resource_overview_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('renders grouped read-only resource cards with use and source', (
    tester,
  ) async {
    const sections = [
      ResourceOverviewSection(
        category: ResourceOverviewCategory.currency,
        items: [
          ResourceOverviewItem(
            defId: 'item_silver',
            name: '银两',
            quantity: 88,
            category: ResourceOverviewCategory.currency,
            usages: [
              ItemUsage(kind: ItemUsageKind.shopPurchaseCurrency),
              ItemUsage(kind: ItemUsageKind.islandUpgradeCurrency),
            ],
            sources: [ItemSource.shop(shopId: 'fixture')],
            usageGroups: [
              ResourceUsageGroup.island,
              ResourceUsageGroup.shopping,
            ],
            consumptionDirection: ResourceConsumptionDirection.mixed,
          ),
        ],
      ),
      ResourceOverviewSection(
        category: ResourceOverviewCategory.equipmentMaterial,
        items: [],
      ),
      ResourceOverviewSection(
        category: ResourceOverviewCategory.islandProduct,
        items: [],
      ),
      ResourceOverviewSection(
        category: ResourceOverviewCategory.pill,
        items: [],
      ),
      ResourceOverviewSection(
        category: ResourceOverviewCategory.scroll,
        items: [],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resourceOverviewProvider.overrideWith((ref) async => sections),
        ],
        child: const MaterialApp(home: ResourceOverviewScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(UiStrings.resourceOverviewTitle), findsOneWidget);
    expect(find.text(UiStrings.resourceOverviewIntro), findsOneWidget);
    expect(find.text('银两'), findsAtLeastNWidgets(1));
    expect(find.text(UiStrings.resourceOverviewQuantity(88)), findsOneWidget);
    expect(find.textContaining('近期去向：多系统共同消耗'), findsOneWidget);
    expect(find.text('桃花岛'), findsOneWidget);
    expect(find.text('采买'), findsOneWidget);
    expect(find.textContaining('商店采买'), findsOneWidget);
    expect(find.textContaining('江湖商店'), findsOneWidget);
    expect(
      find.text(UiStrings.resourceOverviewSourceDetailTitle),
      findsOneWidget,
    );
    await tester.tap(find.text(UiStrings.resourceOverviewSourceDetailTitle));
    await tester.pumpAndSettle();
    expect(find.text('江湖商店'), findsOneWidget);
  });

  testWidgets('keeps scroll source details collapsed into summary only', (
    tester,
  ) async {
    const sections = [
      ResourceOverviewSection(
        category: ResourceOverviewCategory.currency,
        items: [],
      ),
      ResourceOverviewSection(
        category: ResourceOverviewCategory.equipmentMaterial,
        items: [],
      ),
      ResourceOverviewSection(
        category: ResourceOverviewCategory.islandProduct,
        items: [],
      ),
      ResourceOverviewSection(
        category: ResourceOverviewCategory.pill,
        items: [],
      ),
      ResourceOverviewSection(
        category: ResourceOverviewCategory.scroll,
        items: [
          ResourceOverviewItem(
            defId: 'item_scroll_fixture',
            name: '旧卷',
            quantity: 1,
            category: ResourceOverviewCategory.scroll,
            usages: [ItemUsage(kind: ItemUsageKind.techniqueUnlock)],
            sources: [ItemSource.tower(floorIndex: 10, isBoss: true)],
            usageGroups: [ResourceUsageGroup.cultivation],
            consumptionDirection: ResourceConsumptionDirection.cultivation,
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resourceOverviewProvider.overrideWith((ref) async => sections),
        ],
        child: const MaterialApp(home: ResourceOverviewScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('旧卷'), findsOneWidget);
    expect(find.textContaining('爬塔奖励'), findsOneWidget);
    expect(
      find.text(UiStrings.resourceOverviewSourceDetailTitle),
      findsNothing,
    );
  });
}
