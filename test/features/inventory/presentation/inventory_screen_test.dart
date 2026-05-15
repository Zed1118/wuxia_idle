import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/providers/inventory_providers.dart';
import 'package:wuxia_idle/features/inventory/presentation/inventory_screen.dart';

/// T29 InventoryScreen widget 测试（phase2_tasks.md §433）。
///
/// 1 用例：3 件不同 tier 装备 → 按 tier 分段 ExpansionTile 渲染，每行显示 +N。
/// 与 [enhance_dialog_test] 4 用例合计 5+ 通过 §433 验收。
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
}
