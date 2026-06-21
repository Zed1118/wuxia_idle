import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/inventory/presentation/inventory_screen.dart';
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 材料经济 P2 T4：背包物料 tab「使用」按钮 widget 测。
///
/// 经验丹 / 秘籍行各有「使用」按钮（共 2），磨剑石行无按钮。
/// 道具名来自 [GameRepository.instance.itemDefs]（items.yaml），按钮可见性
/// 由 [ItemType] 决定。override 物料 / 银两 provider 跳过真 Isar。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  InventoryItem make(String defId, ItemType type, int qty) {
    final now = DateTime(2026, 6, 21);
    return InventoryItem()
      ..defId = defId
      ..itemType = type
      ..quantity = qty
      ..firstObtainedAt = now
      ..lastObtainedAt = now;
  }

  setUpAll(() async {
    await GameRepository.loadAllDefs(loader: (path) async {
      final f = File(path);
      if (!await f.exists()) throw FileSystemException('不存在', path);
      return f.readAsString();
    });
  });

  tearDownAll(GameRepository.resetForTest);

  Future<void> pumpMaterialTab(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final items = <InventoryItem>[
      make('item_mojianshi', ItemType.moJianShi, 12),
      make('item_jingyandan_small', ItemType.jingYanDan, 3),
      make('item_scroll_kai_bei_shou', ItemType.techniqueScroll, 1),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allInventoryItemsProvider.overrideWith((_) async => items),
          silverBalanceProvider.overrideWith((_) async => 0),
        ],
        child: const MaterialApp(home: InventoryScreen(initialTab: 1)),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  testWidgets('经验丹+秘籍行各有「使用」按钮（磨剑石无）', (tester) async {
    await pumpMaterialTab(tester);

    // 凝神丹（item_jingyandan_small）与 开碑手·秘籍 名称由 itemDef 渲染。
    expect(find.textContaining('凝神丹'), findsOneWidget);
    expect(find.textContaining('开碑手·秘籍'), findsOneWidget);

    // 「使用」按钮仅经验丹 + 秘籍两行 → 2 个。
    expect(find.text(UiStrings.itemUseButton), findsNWidgets(2));
  });
}
