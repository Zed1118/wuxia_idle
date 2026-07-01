import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';
import 'package:wuxia_idle/features/debug/presentation/visual_route_host.dart';
import 'package:wuxia_idle/features/inventory/presentation/inventory_screen.dart';

/// 材料经济 P2 新材料用途视觉验收路由接线测(item_use_inventory)。
/// 守三件事:① route 透传到物料 tab(InventoryScreen initialTab=1) ② seed 经验丹
/// 三档/秘籍各按 [ItemType.fromDefId] 前缀匹配真映射(回归 P2 前缀匹配哨兵:
/// item_jingyandan*→jingYanDan / item_scroll_*→techniqueScroll,漏前缀即静默落
/// miscMaterial 失去「使用」按钮) ③ 建祖师保证使用结果有真目标(非 noTarget)。
void main() {
  group('材料经济 P2 验收路由 parse 往返', () {
    test('item_use_inventory → VisualRoute.itemUseInventory', () {
      expect(
        parseVisualRoute('item_use_inventory'),
        VisualRoute.itemUseInventory,
      );
    });
  });

  group('buildVisualTarget · 材料经济 P2 路由', () {
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
      tempDir = await Directory.systemTemp.createTemp('wuxia_visual_itemuse_');
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

    test('item_use_inventory → InventoryScreen(initialTab=1)', () async {
      final target = await buildVisualTarget(
        VisualRoute.itemUseInventory,
        IsarSetup.instance,
      );
      expect(target, isA<InventoryScreen>());
      expect(
        (target as InventoryScreen).initialTab,
        1,
        reason: '验收直开物料 tab 才能截到「使用」按钮 + per-item 道具名',
      );
    });

    test('item_use_confirm_dialog → 使用确认 preview + 同一批道具 seed', () async {
      final target = await buildVisualTarget(
        VisualRoute.itemUseConfirmDialog,
        IsarSetup.instance,
      );
      expect(target.runtimeType.toString(), '_ItemUseConfirmPreview');
      final isar = IsarSetup.instance;
      expect(
        (await isar.inventoryItems.getByDefId(
          'item_jingyandan_small',
        ))?.quantity,
        3,
      );
      expect(
        (await isar.inventoryItems.getByDefId(
          'item_scroll_kai_bei_shou',
        ))?.itemType,
        ItemType.techniqueScroll,
      );
    });

    test('seed 道具各按 fromDefId 前缀匹配真映射(P2 前缀匹配回归哨兵)', () async {
      await buildVisualTarget(VisualRoute.itemUseInventory, IsarSetup.instance);
      final isar = IsarSetup.instance;
      // 经验丹三档共享 jingYanDan(item_jingyandan* 前缀),per-item 名靠 items.yaml。
      for (final defId in const [
        'item_jingyandan_small',
        'item_jingyandan_mid',
        'item_jingyandan_large',
      ]) {
        expect(
          (await isar.inventoryItems.getByDefId(defId))?.itemType,
          ItemType.jingYanDan,
          reason: '$defId 漏 item_jingyandan 前缀即落 miscMaterial,丢「使用」按钮',
        );
      }
      // 秘籍走 item_scroll_ 前缀。
      expect(
        (await isar.inventoryItems.getByDefId(
          'item_scroll_kai_bei_shou',
        ))?.itemType,
        ItemType.techniqueScroll,
        reason: 'item_scroll_ 前缀匹配,漏则丢「使用」按钮',
      );
      // 磨剑石=普通材料,无使用语义(物料 tab 不应显「使用」按钮,对比项)。
      expect(
        (await isar.inventoryItems.getByDefId('item_mojianshi'))?.itemType,
        ItemType.moJianShi,
      );
    });

    test('建祖师(founder 存在)→ 使用经验丹/秘籍有真目标非 noTarget', () async {
      await buildVisualTarget(VisualRoute.itemUseInventory, IsarSetup.instance);
      final founder = await IsarSetup.instance.characters
          .filter()
          .isFounderEqualTo(true)
          .findFirst();
      expect(
        founder,
        isNotNull,
        reason: 'ensureFoundingMasters 须建祖师,否则结果浮层走 noTarget 验不到三态',
      );
    });
  });
}
