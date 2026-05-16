import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/features/inventory/presentation/inventory_screen.dart';

/// T29 InventoryScreen widget 测试（phase2_tasks.md §433）+ W15 #30 P3 后续 A
/// 物料 Tab 测试。
///
/// 装备 Tab：原 T29 2 用例 + W15 LoreLoader 用例。
/// 物料 Tab：4 用例(empty / 1 行 / 2 行 / Tab 切换)。
/// EnumL10n.itemType 5 映射在 enum_localizations_test.dart 单独覆盖。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Equipment mkEq({
    required int id,
    required EquipmentTier tier,
    required EquipmentSlot slot,
    int enhanceLevel = 0,
  }) {
    return Equipment.create(
      defId: 'test_$id',
      tier: tier,
      slot: slot,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: 50,
      enhanceLevel: enhanceLevel,
    )..id = id;
  }

  InventoryItem mkItem({
    required int id,
    required String defId,
    required ItemType itemType,
    required int quantity,
  }) {
    final now = DateTime(2026, 5, 16);
    return InventoryItem()
      ..id = id
      ..defId = defId
      ..itemType = itemType
      ..quantity = quantity
      ..firstObtainedAt = now
      ..lastObtainedAt = now;
  }

  testWidgets('3 件 / 3 tier 装备 → 3 个 ExpansionTile + +N 全部渲染',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fixtures = [
      mkEq(
        id: 10,
        tier: EquipmentTier.shenWu,
        slot: EquipmentSlot.weapon,
        enhanceLevel: 12,
      ),
      mkEq(
        id: 11,
        tier: EquipmentTier.liQi,
        slot: EquipmentSlot.armor,
        enhanceLevel: 5,
      ),
      mkEq(
        id: 12,
        tier: EquipmentTier.xunChang,
        slot: EquipmentSlot.accessory,
        enhanceLevel: 0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => fixtures),
          allInventoryItemsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // 3 个 tier 中文标题（神物 / 利器 / 寻常货）
    expect(find.text('神物'), findsOneWidget);
    expect(find.text('利器'), findsOneWidget);
    expect(find.text('寻常货'), findsOneWidget);

    // 3 个 +N
    expect(find.text('+12'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    expect(find.text('+0'), findsOneWidget);

    // 3 行 slot 中文
    expect(find.text('武器'), findsOneWidget);
    expect(find.text('护甲'), findsOneWidget);
    expect(find.text('饰品'), findsOneWidget);
  });

  testWidgets('真实 defId → row 显示装备名（#24 fixup 验收）', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final def = GameRepository.instance.getEquipment('weapon_liqi_long_quan');
    final eq = Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: def.baseAttackMin,
      enhanceLevel: 0,
    )..id = 100;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => [eq]),
          allInventoryItemsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('龙泉剑'), findsOneWidget,
        reason: 'inventory row 应渲染 EquipmentDef.name');
  });

  // ─── W15 #30 P3 后续 A · 物料 Tab ─────────────────────────────────────

  testWidgets('物料 Tab 空 → 显示「暂无物料」', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => []),
          allInventoryItemsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 切到物料 Tab
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();

    expect(find.text('暂无物料'), findsOneWidget);
  });

  testWidgets('物料 Tab 单行 → 磨剑石 × N 渲染', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => []),
          allInventoryItemsProvider.overrideWith((ref) async => [
                mkItem(
                  id: 1,
                  defId: 'item_mojianshi',
                  itemType: ItemType.moJianShi,
                  quantity: 2001,
                ),
              ]),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();

    // 分组标题（磨剑石 × 1）+ 行内数量「磨剑石 × 2001」
    expect(find.text('磨剑石 × 2001'), findsOneWidget);
    expect(find.text('item_mojianshi'), findsOneWidget);
    // 不显示其他 itemType 分组
    expect(find.text('心血结晶'), findsNothing);
    expect(find.text('暂无物料'), findsNothing);
  });

  testWidgets('物料 Tab 2 行 / 2 种 → 按 enum 顺序分组（磨剑石在前）', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => []),
          allInventoryItemsProvider.overrideWith((ref) async => [
                mkItem(
                  id: 1,
                  defId: 'item_mojianshi',
                  itemType: ItemType.moJianShi,
                  quantity: 2001,
                ),
                mkItem(
                  id: 2,
                  defId: 'item_xinxuejiejing',
                  itemType: ItemType.xinXueJieJing,
                  quantity: 201,
                ),
              ]),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();

    // 行文案
    expect(find.text('磨剑石 × 2001'), findsOneWidget);
    expect(find.text('心血结晶 × 201'), findsOneWidget);

    // 分组顺序：磨剑石 group 在心血结晶之上(enum index 0 vs 1)
    final mojiTitleY = tester
        .getTopLeft(find.ancestor(
          of: find.text('磨剑石'),
          matching: find.byType(Row),
        ).first)
        .dy;
    final xinxueTitleY = tester
        .getTopLeft(find.ancestor(
          of: find.text('心血结晶'),
          matching: find.byType(Row),
        ).first)
        .dy;
    expect(mojiTitleY, lessThan(xinxueTitleY),
        reason: '磨剑石 group 应在心血结晶 group 之上(ItemType.moJianShi index < xinXueJieJing)');
  });

  testWidgets('quantity == 0 的行被过滤,不显示空 group', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => []),
          allInventoryItemsProvider.overrideWith((ref) async => [
                mkItem(
                  id: 1,
                  defId: 'item_mojianshi',
                  itemType: ItemType.moJianShi,
                  quantity: 0,
                ),
              ]),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();

    expect(find.text('暂无物料'), findsOneWidget,
        reason: 'quantity == 0 的物料行不应出现，整 Tab 显空态');
    expect(find.textContaining('磨剑石'), findsNothing);
  });

  testWidgets('TabBar 2 个 tab 渲染 + 默认 Tab 是装备', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final eq = mkEq(
      id: 10,
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => [eq]),
          allInventoryItemsProvider.overrideWith((ref) async => [
                mkItem(
                  id: 1,
                  defId: 'item_mojianshi',
                  itemType: ItemType.moJianShi,
                  quantity: 5,
                ),
              ]),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 两个 Tab 标签存在
    expect(find.text('装备'), findsOneWidget);
    expect(find.text('物料'), findsOneWidget);

    // 默认是装备 Tab：找到 +N 但还没切到物料,物料行不应可见(在 Tab 外)
    expect(find.text('+0'), findsOneWidget);
  });
}
