import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
import 'package:wuxia_idle/features/inventory/presentation/inventory_screen.dart';
import 'package:wuxia_idle/shared/widgets/equipment_glyph.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/section_header.dart';

/// InventoryScreen widget 测试。
///
/// 装备 Tab（P0-4b 仓库格子化重写 2026-06-04）：按部位分组网格
/// （武器/护甲/饰品三段）+ 格子图标 contain + tier 边框 + 强化徽章 +
/// 境界锁灰化 + 缺图 EquipGlyph 占位。物料 Tab：4 用例不变。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Attributes mkAttrs() => Attributes()
    ..constitution = 5
    ..enlightenment = 5
    ..agility = 5
    ..fortune = 5;

  Character mkCharacter({int id = 1, RealmTier realmTier = RealmTier.xueTu}) {
    return Character.create(
      name: '测试者',
      realmTier: realmTier,
      realmLayer: RealmLayer.qiMeng,
      attributes: mkAttrs(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 5, 11),
      internalForce: 200,
      internalForceMax: 500,
      school: TechniqueSchool.gangMeng,
    )..id = id;
  }

  Equipment mkEq({
    required int id,
    required EquipmentTier tier,
    required EquipmentSlot slot,
    String? defId,
    int enhanceLevel = 0,
    bool isLineageHeritage = false,
  }) {
    return Equipment.create(
      defId: defId ?? 'test_$id',
      tier: tier,
      slot: slot,
      obtainedAt: DateTime(2026, 5, 11),
      obtainedFrom: 'test',
      baseAttack: 50,
      enhanceLevel: enhanceLevel,
      isLineageHeritage: isLineageHeritage,
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

  /// 装备 Tab 通用 pump（默认无玩家角色 → 不锁;可传 player 验境界锁）。
  Future<void> pumpInv(
    WidgetTester tester, {
    required List<Equipment> equipments,
    List<InventoryItem> items = const [],
    Character? player,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => equipments),
          allInventoryItemsProvider.overrideWith((ref) async => items),
          activeCharacterIdsProvider.overrideWith(
            (ref) async => player == null ? [] : [player.id],
          ),
          if (player != null)
            characterByIdProvider(
              player.id,
            ).overrideWith((ref) async => player),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
  }

  // ─── 装备 Tab（P0-4b 格子化） ─────────────────────────────────────────

  testWidgets('装备 Tab 按部位分组：武器/护甲/饰品三段标题', (tester) async {
    await pumpInv(
      tester,
      equipments: [
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
          enhanceLevel: 3,
        ),
      ],
    );
    expect(find.text('武器'), findsOneWidget);
    expect(find.text('护甲'), findsOneWidget);
    expect(find.text('饰品'), findsOneWidget);
    // 分组头容器语言换 UI kit SectionHeader（callsite 试点）
    expect(find.byType(SectionHeader), findsNWidgets(3));
    expect(
      find.byType(PaperPanel),
      findsOneWidget,
      reason: 'SectionHeader 的墨色标题和 ink_divider 需落在宣纸 panel 上',
    );
    // 强化徽章（>0 显示）
    expect(find.text('+12'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('真实 defId → 格子显示装备名 + 图标', (tester) async {
    final def = GameRepository.instance.getEquipment('weapon_liqi_long_quan');
    final eq = mkEq(id: 100, tier: def.tier, slot: def.slot, defId: def.id);
    await pumpInv(tester, equipments: [eq]);
    expect(find.text('龙泉剑'), findsOneWidget, reason: '格子应渲染 EquipmentDef.name');
    expect(
      find.byType(Image),
      findsWidgets,
      reason: '格子应 Image.asset(iconPath)',
    );
  });

  testWidgets('境界不达装备 → 灰化 + 锁图标', (tester) async {
    // 神物装备 + 学徒境界玩家 → 不可装备
    final eq = mkEq(
      id: 20,
      tier: EquipmentTier.shenWu,
      slot: EquipmentSlot.weapon,
      defId: 'weapon_shenwu_tian_wen_jian',
    );
    await pumpInv(
      tester,
      equipments: [eq],
      player: mkCharacter(realmTier: RealmTier.xueTu),
    );
    expect(find.byIcon(Icons.lock_outline), findsWidgets, reason: '境界不达应显锁图标');
    expect(find.byType(ColorFiltered), findsWidgets, reason: '不可装备应灰化');
  });

  testWidgets('境界达标装备 → 无锁', (tester) async {
    final eq = mkEq(
      id: 21,
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      defId: 'weapon_xunchang_tie_jian',
    );
    await pumpInv(
      tester,
      equipments: [eq],
      player: mkCharacter(realmTier: RealmTier.wuSheng),
    );
    expect(
      find.byIcon(Icons.lock_outline),
      findsNothing,
      reason: '武圣可装备寻常货 → 无锁',
    );
  });

  testWidgets('缺图/未知 defId → 走 EquipGlyph 占位不崩', (tester) async {
    await pumpInv(
      tester,
      equipments: [
        mkEq(id: 30, tier: EquipmentTier.baoWu, slot: EquipmentSlot.accessory),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(
      find.byType(EquipGlyph),
      findsWidgets,
      reason: '未知 defId 应降级 EquipGlyph',
    );
  });

  testWidgets('师承遗物 → 显师承标记', (tester) async {
    final eq = mkEq(
      id: 40,
      tier: EquipmentTier.baoWu,
      slot: EquipmentSlot.weapon,
      defId: 'weapon_baowu_bing_po_zhen',
      isLineageHeritage: true,
    );
    await pumpInv(tester, equipments: [eq]);
    expect(find.byIcon(Icons.auto_awesome), findsWidgets, reason: '师承遗物应显标记');
  });

  testWidgets('TabBar 2 tab + 默认装备 Tab 显部位段', (tester) async {
    await pumpInv(
      tester,
      equipments: [
        mkEq(id: 10, tier: EquipmentTier.xunChang, slot: EquipmentSlot.weapon),
      ],
      items: [
        mkItem(
          id: 1,
          defId: 'item_mojianshi',
          itemType: ItemType.moJianShi,
          quantity: 5,
        ),
      ],
    );
    expect(find.text('装备'), findsOneWidget);
    expect(find.text('物料'), findsOneWidget);
    // 默认装备 Tab：武器段标题可见;物料行在另一 Tab 不可见
    expect(find.text('武器'), findsOneWidget);
    expect(find.textContaining('磨剑石 ×'), findsNothing);
  });

  // ─── 物料 Tab（不变） ─────────────────────────────────────────────────

  testWidgets('物料 Tab 空 → 显示「暂无物料」', (tester) async {
    await pumpInv(tester, equipments: []);
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();
    expect(find.text('暂无物料'), findsOneWidget);
  });

  testWidgets('物料 Tab 单行 → 磨剑石 × N 渲染', (tester) async {
    await pumpInv(
      tester,
      equipments: [],
      items: [
        mkItem(
          id: 1,
          defId: 'item_mojianshi',
          itemType: ItemType.moJianShi,
          quantity: 2001,
        ),
      ],
    );
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();
    expect(find.text('磨剑石 × 2001'), findsOneWidget);
    expect(find.text('item_mojianshi'), findsNothing);
    expect(find.text('心血结晶'), findsNothing);
    expect(find.text('暂无物料'), findsNothing);
  });

  testWidgets('物料 Tab 2 行 / 2 种 → 按 enum 顺序分组（磨剑石在前）', (tester) async {
    await pumpInv(
      tester,
      equipments: [],
      items: [
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
      ],
    );
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();
    expect(find.text('磨剑石 × 2001'), findsOneWidget);
    expect(find.text('心血结晶 × 201'), findsOneWidget);
    final mojiTitleY = tester
        .getTopLeft(
          find.ancestor(of: find.text('磨剑石'), matching: find.byType(Row)).first,
        )
        .dy;
    final xinxueTitleY = tester
        .getTopLeft(
          find
              .ancestor(of: find.text('心血结晶'), matching: find.byType(Row))
              .first,
        )
        .dy;
    expect(mojiTitleY, lessThan(xinxueTitleY));
  });

  testWidgets('物料 quantity == 0 的行被过滤', (tester) async {
    await pumpInv(
      tester,
      equipments: [],
      items: [
        mkItem(
          id: 1,
          defId: 'item_mojianshi',
          itemType: ItemType.moJianShi,
          quantity: 0,
        ),
      ],
    );
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();
    expect(find.text('暂无物料'), findsOneWidget);
    expect(find.textContaining('磨剑石'), findsNothing);
  });
}
