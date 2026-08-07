import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/item_source.dart';
import 'package:wuxia_idle/core/domain/item_usage.dart';
import 'package:wuxia_idle/core/domain/resource_overview_display.dart';
import 'package:wuxia_idle/features/resource_overview/application/resource_overview_providers.dart';
import 'package:wuxia_idle/features/resource_overview/domain/resource_overview_item.dart';
import 'package:wuxia_idle/features/resource_overview/presentation/resource_overview_screen.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_readiness_providers.dart';
import 'package:wuxia_idle/data/defs/sweep_readiness.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  final sweepReadinessFixture = SweepReadinessState(
    points: 42,
    lastRecoveredAt: DateTime(2026),
    config: const SweepReadinessConfig(
      enabled: true,
      maxPoints: 60,
      recoverMinutesPerPoint: 60,
      mainlineStageCost: 1,
    ),
  );

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
          sweepReadinessStatusProvider.overrideWith(
            (ref) async => sweepReadinessFixture,
          ),
        ],
        child: const MaterialApp(home: ResourceOverviewScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.resourceOverviewTitle), findsOneWidget);
    expect(find.text(UiStrings.sweepReadinessPanelTitle), findsOneWidget);
    expect(find.text(UiStrings.sweepReadinessShort(42, 60)), findsOneWidget);
    expect(find.text(UiStrings.resourceOverviewIntro), findsOneWidget);
    expect(find.text('银两'), findsAtLeastNWidgets(1));
    expect(find.text(UiStrings.resourceOverviewQuantity(88)), findsOneWidget);
    expect(find.textContaining('近期去向：多系统共同消耗'), findsOneWidget);
    expect(find.text('桃花岛'), findsOneWidget);
    expect(find.text('采买'), findsOneWidget);
    expect(find.textContaining('商店采买'), findsOneWidget);
    expect(find.textContaining('江湖商店'), findsOneWidget);
    expect(find.textContaining('来源：主要来源：'), findsNothing);
    expect(find.textContaining('来源：江湖商店'), findsOneWidget);
    expect(
      find.text(UiStrings.resourceOverviewSourceDetailTitle),
      findsOneWidget,
    );
    await tester.tap(find.text(UiStrings.resourceOverviewSourceDetailTitle));
    await tester.pumpAndSettle();
    expect(find.text('江湖商店'), findsOneWidget);
  });

  testWidgets('tapping material name opens MaterialSourceSheet', (
    tester,
  ) async {
    const sections = [
      ResourceOverviewSection(
        category: ResourceOverviewCategory.currency,
        items: [],
      ),
      ResourceOverviewSection(
        category: ResourceOverviewCategory.equipmentMaterial,
        items: [
          ResourceOverviewItem(
            defId: 'item_mat_fixture',
            name: '玄铁',
            quantity: 7,
            category: ResourceOverviewCategory.equipmentMaterial,
            usages: [ItemUsage(kind: ItemUsageKind.equipmentEnhancement)],
            sources: [ItemSource.tower(floorIndex: 3, isBoss: false)],
            usageGroups: [ResourceUsageGroup.equipment],
            consumptionDirection: ResourceConsumptionDirection.equipment,
          ),
        ],
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
          sweepReadinessStatusProvider.overrideWith(
            (ref) async => sweepReadinessFixture,
          ),
        ],
        child: const MaterialApp(home: ResourceOverviewScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 入口存在：卡片名称行包在 InkWell 内（材料来源反查接线）。
    final nameText = find.text('玄铁');
    expect(nameText, findsOneWidget);
    expect(
      find.ancestor(of: nameText, matching: find.byType(InkWell)),
      findsOneWidget,
    );

    await tester.tap(nameText);
    await tester.pumpAndSettle();

    // 既有 MaterialSourceSheet 弹出：标题区 + 持有量（sheet 内 GameRepository
    // 未初始化时防御式空来源/空用途占位，不 crash）。
    expect(
      find.text(UiStrings.materialSourceSheetSourcesTitle),
      findsOneWidget,
    );
    expect(find.text(UiStrings.materialSourceSheetOwned(7)), findsOneWidget);
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
          sweepReadinessStatusProvider.overrideWith(
            (ref) async => sweepReadinessFixture,
          ),
        ],
        child: const MaterialApp(home: ResourceOverviewScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('旧卷'), findsOneWidget);
    expect(find.textContaining('爬塔奖励'), findsOneWidget);
    expect(
      find.text(UiStrings.resourceOverviewSourceDetailTitle),
      findsNothing,
    );
  });
}
