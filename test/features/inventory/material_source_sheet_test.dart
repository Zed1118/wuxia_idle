import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/item_source.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/equipment/presentation/enhance_dialog.dart';
import 'package:wuxia_idle/features/inventory/presentation/inventory_screen.dart';
import 'package:wuxia_idle/features/inventory/presentation/material_source_sheet.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 材料来源反查一期（MaterialSourceSheet · 夜间批 L）widget 测试。
///
/// 覆盖：
/// 1. sheet 渲染：来源分组行（磨剑石 → 装备分解等）+ 用途行 + 持有量头部；
/// 2. 空来源/空用途各一行占位文案（未知 defId 走占位路径）；
/// 3. 挂点①强化对话框：点「材料」chip → sheet 出现；
/// 4. 挂点⑤背包物料 tile：点名称行 → sheet 出现。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    required String itemId,
    int? quantity,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MaterialSourceSheet(itemId: itemId, quantity: quantity),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('MaterialSourceSheet 渲染', () {
    testWidgets('磨剑石 → 名称+持有量+来源分组行+用途行', (tester) async {
      await pumpSheet(tester, itemId: 'item_mojianshi', quantity: 42);

      expect(find.text('磨剑石'), findsOneWidget);
      expect(
        find.text(UiStrings.materialSourceSheetOwned(42)),
        findsOneWidget,
      );
      expect(
        find.text(UiStrings.materialSourceSheetSourcesTitle),
        findsOneWidget,
      );
      // 来源行多（磨剑石掉落面广），「用途」段在视口下方，先滚到再断言。
      await tester.scrollUntilVisible(
        find.text(UiStrings.materialSourceSheetUsagesTitle),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(
        find.text(UiStrings.materialSourceSheetUsagesTitle),
        findsOneWidget,
      );
      // 来源：磨剑石必含「装备分解」途径行（派生服务保证）
      await tester.scrollUntilVisible(
        find.text(UiStrings.itemSourceLabel(
          const ItemSource.equipmentDisassembly(),
        )),
        -200,
        scrollable: find.byType(Scrollable),
      );
      expect(
        find.text(UiStrings.itemSourceLabel(
          const ItemSource.equipmentDisassembly(),
        )),
        findsWidgets,
      );
      // 用途：装备强化
      await tester.scrollUntilVisible(
        find.text('装备强化'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('装备强化'), findsOneWidget);
      // 无空态占位
      expect(
        find.text(UiStrings.materialSourceSheetEmptySources),
        findsNothing,
      );
      expect(
        find.text(UiStrings.materialSourceSheetEmptyUsages),
        findsNothing,
      );
    });

    testWidgets('未知 defId → 空来源/空用途各一行占位', (tester) async {
      await pumpSheet(tester, itemId: 'item_unknown_never_exists');

      expect(
        find.text(UiStrings.materialSourceSheetEmptySources),
        findsOneWidget,
      );
      expect(
        find.text(UiStrings.materialSourceSheetEmptyUsages),
        findsOneWidget,
      );
    });
  });

  group('挂点', () {
    testWidgets('①强化对话框:点「材料」chip → 来源 sheet 出现', (tester) async {
      final eq = Equipment.create(
        defId: 'test_eq',
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.weapon,
        obtainedAt: DateTime(2026, 7, 5),
        obtainedFrom: 'test',
        baseAttack: 50,
        enhanceLevel: 5,
      )..id = 1;

      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryQuantityByDefIdProvider(
              'item_duancai',
            ).overrideWith((ref) async => 100),
            inventoryQuantityByTypeProvider(
              ItemType.moJianShi,
            ).overrideWith((ref) async => 999),
            inventoryQuantityByTypeProvider(
              ItemType.xinXueJieJing,
            ).overrideWith((ref) async => 3),
          ],
          child: MaterialApp(
            home: Scaffold(body: Center(child: EnhanceDialog(equipment: eq))),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialSourceSheet), findsNothing);
      await tester.tap(find.text(UiStrings.metricMaterial));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MaterialSourceSheet), findsOneWidget);
      expect(find.text('磨剑石'), findsOneWidget);
      expect(
        find.text(UiStrings.materialSourceSheetOwned(999)),
        findsOneWidget,
      );
      expect(
        find.text(UiStrings.materialSourceSheetSourcesTitle),
        findsOneWidget,
      );
    });

    testWidgets('⑤背包物料 tile:点名称行 → 来源 sheet 出现', (tester) async {
      final now = DateTime(2026, 7, 5);
      final item = InventoryItem()
        ..id = 1
        ..defId = 'item_mojianshi'
        ..itemType = ItemType.moJianShi
        ..quantity = 77
        ..firstObtainedAt = now
        ..lastObtainedAt = now;

      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allEquipmentsProvider.overrideWith((ref) async => []),
            allInventoryItemsProvider.overrideWith((ref) async => [item]),
            activeCharacterIdsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: InventoryScreen()),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      await tester.tap(find.text(UiStrings.inventoryTabMaterial));
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialSourceSheet), findsNothing);
      await tester.tap(
        find.text(UiStrings.materialQuantity('磨剑石', 77)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MaterialSourceSheet), findsOneWidget);
      expect(
        find.text(UiStrings.materialSourceSheetOwned(77)),
        findsOneWidget,
      );
      expect(
        find.text(UiStrings.materialSourceSheetSourcesTitle),
        findsOneWidget,
      );
    });
  });
}
