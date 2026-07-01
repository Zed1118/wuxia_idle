import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';
import 'package:wuxia_idle/features/debug/presentation/visual_route_host.dart';
import 'package:wuxia_idle/features/inventory/presentation/inventory_screen.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/shop/presentation/shop_screen.dart';

/// 材料经济 P1 视觉验收路由接线测(shop / inventory_currency / main_menu_shop)。
/// 守两件事:① route 透传到正确目标屏 ② seed helper 用 [ItemType.fromDefId] 真映射
/// 入库银两 → itemType 必须是 [ItemType.silver](本批修的 fromDefId 漏 item_silver
/// 落 miscMaterial 兜底 bug 的回归哨兵)。
void main() {
  group('材料经济 P1 验收路由 parse 往返', () {
    test('shop / inventory_currency / main_menu_shop → 对应枚举', () {
      expect(parseVisualRoute('shop'), VisualRoute.shop);
      expect(
        parseVisualRoute('inventory_currency'),
        VisualRoute.inventoryCurrency,
      );
      expect(parseVisualRoute('main_menu_shop'), VisualRoute.mainMenuShop);
    });
  });

  group('buildVisualTarget · 材料经济 P1 路由', () {
    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (path) => File(path).readAsString(),
        );
      }
    });

    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_visual_shop_');
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      if (Isar.getInstance('wuxia_save_slot1') != null) {
        await IsarSetup.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'shop → ShopScreen + 种银两 80(itemType=silver 非 miscMaterial)',
      () async {
        final target = await buildVisualTarget(
          VisualRoute.shop,
          IsarSetup.instance,
        );
        expect(target, isA<ShopScreen>());
        final silver = await IsarSetup.instance.inventoryItems.getByDefId(
          'item_silver',
        );
        expect(silver, isNotNull);
        expect(silver!.quantity, 80);
        expect(
          silver.itemType,
          ItemType.silver,
          reason:
              '银两 seed 必须走 fromDefId 真映射为 silver,'
              '落 miscMaterial 即本批已修 bug 回归',
        );
      },
    );

    test('shop_buy_confirm → 购买确认 preview + 种银两 80', () async {
      final target = await buildVisualTarget(
        VisualRoute.shopBuyConfirm,
        IsarSetup.instance,
      );
      expect(target.runtimeType.toString(), '_ShopBuyConfirmPreview');
      final silver = await IsarSetup.instance.inventoryItems.getByDefId(
        'item_silver',
      );
      expect(silver?.quantity, 80);
      expect(silver?.itemType, ItemType.silver);
    });

    test(
      'inventory_currency → InventoryScreen(initialTab=1) + 银两不入材料网格类型',
      () async {
        final target = await buildVisualTarget(
          VisualRoute.inventoryCurrency,
          IsarSetup.instance,
        );
        expect(target, isA<InventoryScreen>());
        expect(
          (target as InventoryScreen).initialTab,
          1,
          reason: '验收直开物料 tab 才能截到货币位顶栏',
        );
        // 三类物品各自入库,itemType 各按 fromDefId 真映射。
        final isar = IsarSetup.instance;
        expect(
          (await isar.inventoryItems.getByDefId('item_silver'))?.itemType,
          ItemType.silver,
        );
        expect(
          (await isar.inventoryItems.getByDefId('item_mojianshi'))?.itemType,
          ItemType.moJianShi,
        );
        expect(
          (await isar.inventoryItems.getByDefId(
            'item_xinxuejiejing',
          ))?.itemType,
          ItemType.xinXueJieJing,
        );
      },
    );

    test('main_menu_shop → MainMenu + 种银两 200 解锁商店入口', () async {
      final target = await buildVisualTarget(
        VisualRoute.mainMenuShop,
        IsarSetup.instance,
      );
      expect(target, isA<MainMenu>());
      final silver = await IsarSetup.instance.inventoryItems.getByDefId(
        'item_silver',
      );
      expect(silver?.quantity, 200);
      expect(silver?.itemType, ItemType.silver);
    });

    test('同 defId 重复 seed(hub 多次点选)复用 id 不撞 unique 索引', () async {
      // 连跑两次 shop 路由,模拟 hub 重复点选;quantity 覆盖,不抛 unique 冲突。
      await buildVisualTarget(VisualRoute.shop, IsarSetup.instance);
      await buildVisualTarget(VisualRoute.shop, IsarSetup.instance);
      final rows = (await IsarSetup.instance.inventoryItems.where().findAll())
          .where((it) => it.defId == 'item_silver')
          .toList();
      expect(rows.length, 1, reason: 'upsert 复用 id,不产生重复行');
      expect(rows.first.quantity, 80);
    });
  });
}
