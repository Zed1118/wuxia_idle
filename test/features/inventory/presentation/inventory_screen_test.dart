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
import 'package:wuxia_idle/features/shop/application/shop_providers.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/item_slot.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_panel.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_tab.dart';
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
      findsNWidgets(3),
      reason: '装备仓库应按武器/护甲/饰品分成三个宣纸小柜，避免整页空纸面',
    );
    expect(find.byType(ItemSlot), findsNWidgets(3));
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
    // T11 修复:封条文案改具体境界原因(神物 → 需武圣境界),非泛化「未达境界」。
    expect(find.text('需武圣境界'), findsWidgets, reason: '境界不达应显具体境界封条');
    expect(find.text('未达境界'), findsNothing, reason: '不再用泛化文案');
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
    expect(find.textContaining('需'), findsNothing, reason: '武圣可装备寻常货 → 无境界封条');
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
      find.byType(ItemSlot),
      findsWidgets,
      reason: '未知 defId 应降级 ItemSlot 占位',
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

  testWidgets('T11 筛选「已穿戴」→ 只显已穿戴装备', (tester) async {
    final worn =
        mkEq(id: 10, tier: EquipmentTier.liQi, slot: EquipmentSlot.weapon)
          ..ownerCharacterId = 1;
    final free = mkEq(
      id: 11,
      tier: EquipmentTier.liQi,
      slot: EquipmentSlot.armor,
    );
    await pumpInv(tester, equipments: [worn, free]);

    // 默认「全部」→ 两件都显
    expect(find.text('test_10'), findsOneWidget);
    expect(find.text('test_11'), findsOneWidget);

    // 点「已穿戴」筛选 → 只剩 worn
    await tester.tap(find.text('已穿戴'));
    await tester.pumpAndSettle();
    expect(find.text('test_10'), findsOneWidget);
    expect(find.text('test_11'), findsNothing);
  });

  testWidgets('木牌 2 tab + 默认装备 Tab 显部位段', (tester) async {
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
    expect(find.byType(PlaqueTab), findsNWidgets(2));
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
    // T12:物料行带用途说明
    expect(find.textContaining('用于强化装备'), findsOneWidget);
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

  // ─── 银两货币位（材料经济 P1 Task 9） ────────────────────────────────────

  /// pump 含 silverBalanceProvider override 版本。
  Future<void> pumpInvWithSilver(
    WidgetTester tester, {
    required List<Equipment> equipments,
    required List<InventoryItem> items,
    required int silverBalance,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allEquipmentsProvider.overrideWith((ref) async => equipments),
          allInventoryItemsProvider.overrideWith((ref) async => items),
          activeCharacterIdsProvider.overrideWith((ref) async => []),
          silverBalanceProvider.overrideWith((ref) async => silverBalance),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
  }

  testWidgets('银两 item 不进材料分组列表（无「银两」分组标题）', (tester) async {
    await pumpInvWithSilver(
      tester,
      equipments: [],
      items: [
        mkItem(
          id: 1,
          defId: 'item_mojianshi',
          itemType: ItemType.moJianShi,
          quantity: 10,
        ),
        mkItem(
          id: 2,
          defId: 'item_silver',
          itemType: ItemType.silver,
          quantity: 500,
        ),
      ],
      silverBalance: 500,
    );
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();
    // 磨剑石分组正常显示
    expect(find.text('磨剑石 × 10'), findsOneWidget);
    // 银两不应以材料分组形式出现
    expect(find.text('银两'), findsNothing, reason: 'item_silver 不应作为材料分组标题');
  });

  testWidgets('货币顶栏「银两 N」在物料 Tab 可见（silverBalanceLabel）', (tester) async {
    await pumpInvWithSilver(
      tester,
      equipments: [],
      items: [
        mkItem(
          id: 2,
          defId: 'item_silver',
          itemType: ItemType.silver,
          quantity: 888,
        ),
      ],
      silverBalance: 888,
    );
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();
    expect(
      find.text(UiStrings.silverBalanceLabel(888)),
      findsOneWidget,
      reason: '物料 Tab 顶栏应显示银两余额',
    );
  });

  testWidgets('银两为0时货币顶栏显示「银两 0」', (tester) async {
    await pumpInvWithSilver(
      tester,
      equipments: [],
      items: [],
      silverBalance: 0,
    );
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.silverBalanceLabel(0)), findsOneWidget);
  });

  // ─── P2 新材料用途：使用按钮显示条件 + 确认弹窗 ──────────────────────
  // 真机目检本环境无合成点击工具(cliclick/Quartz/AX 全不可用),用 widget 测
  // 锚死「使用」按钮显示条件 + 点击弹确认窗(到 writeTxn 前,不触 Isar 死锁);
  // 点确认后的结果三态由 item_use_service_test 逻辑层兜底。

  testWidgets('P2 使用按钮仅经验丹/秘籍显示·磨剑石无(对比项)', (tester) async {
    await pumpInv(
      tester,
      equipments: [],
      items: [
        mkItem(
          id: 1,
          defId: 'item_jingyandan_small',
          itemType: ItemType.jingYanDan,
          quantity: 3,
        ),
        mkItem(
          id: 2,
          defId: 'item_scroll_kai_bei_shou',
          itemType: ItemType.techniqueScroll,
          quantity: 1,
        ),
        mkItem(
          id: 3,
          defId: 'item_mojianshi',
          itemType: ItemType.moJianShi,
          quantity: 12,
        ),
      ],
    );
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();
    // 经验丹/秘籍 per-item 名(items.yaml)各一行。
    expect(find.text('凝神丹 × 3'), findsOneWidget);
    expect(find.text('开碑手·秘籍 × 1'), findsOneWidget);
    expect(find.text('磨剑石 × 12'), findsOneWidget);
    // 「使用」TextButton 只出现在丹 + 秘籍(2 个),磨剑石行无。
    expect(
      find.widgetWithText(TextButton, UiStrings.itemUseButton),
      findsNWidgets(2),
      reason: '仅 jingYanDan/techniqueScroll 显使用按钮,磨剑石不显',
    );
  });

  testWidgets('P2 点经验丹「使用」→ 弹确认弹窗(per-item 名)', (tester) async {
    await pumpInv(
      tester,
      equipments: [],
      items: [
        mkItem(
          id: 1,
          defId: 'item_jingyandan_mid',
          itemType: ItemType.jingYanDan,
          quantity: 2,
        ),
      ],
    );
    await tester.tap(find.text('物料'));
    await tester.pumpAndSettle();
    // 点物料行的「使用」TextButton(非确认弹窗内 PlaqueButton)。
    await tester.tap(find.widgetWithText(TextButton, UiStrings.itemUseButton));
    await tester.pumpAndSettle();
    // 确认弹窗弹出,正文含 per-item 名(培元丹 = items.yaml name)。
    expect(
      find.text(UiStrings.itemUseConfirmBody('培元丹')),
      findsOneWidget,
      reason: '点使用应弹确认弹窗且显 items.yaml per-item 名',
    );
    expect(find.text(UiStrings.commonCancel), findsOneWidget);
  });
}
