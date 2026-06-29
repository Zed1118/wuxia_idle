import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/item_source.dart';
import 'package:wuxia_idle/core/domain/item_usage.dart';
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
    expect(find.textContaining('商店采买'), findsOneWidget);
    expect(find.textContaining('江湖商店'), findsOneWidget);
  });
}
