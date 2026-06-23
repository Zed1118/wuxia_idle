import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/shop_item_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  group('ShopItemDef', () {
    test('fromYaml 解析磨剑石', () {
      final def = ShopItemDef.fromYaml({
        'id': 'shop_mojianshi',
        'itemDefId': 'item_mojianshi',
        'itemType': 'moJianShi',
        'price': 30,
        'category': 'material',
      });
      expect(def.id, 'shop_mojianshi');
      expect(def.itemDefId, 'item_mojianshi');
      expect(def.itemType, ItemType.moJianShi);
      expect(def.price, 30);
      expect(def.category, 'material');
    });

    test('fromYaml 解析心血结晶', () {
      final def = ShopItemDef.fromYaml({
        'id': 'shop_xinxue_jiejing',
        'itemDefId': 'item_xinxuejiejing',
        'itemType': 'xinXueJieJing',
        'price': 120,
        'category': 'material',
      });
      expect(def.id, 'shop_xinxue_jiejing');
      expect(def.itemDefId, 'item_xinxuejiejing');
      expect(def.itemType, ItemType.xinXueJieJing);
      expect(def.price, 120);
    });
  });

  group('GameRepository.loadAllDefs（shop.yaml 集成）', () {
    test('shop.yaml 加载为 ShopItemDef 且标价>0', () async {
      await GameRepository.loadAllDefs(loader: fileLoader);
      final defs = GameRepository.instance.shopItemDefs;
      expect(defs.isNotEmpty, true);

      final mojian = defs['shop_mojianshi'];
      expect(mojian, isNotNull);
      expect(mojian!.itemDefId, 'item_mojianshi');
      expect(mojian.price! > 0, true);
      expect(mojian.itemType, ItemType.moJianShi);

      final xinxue = defs['shop_xinxue_jiejing'];
      expect(xinxue, isNotNull);
      expect(xinxue!.itemDefId, 'item_xinxuejiejing');
      expect(xinxue.price! > 0, true);
      expect(xinxue.itemType, ItemType.xinXueJieJing);
    });

    test('shop.yaml 含经验丹小/中（动态标价）', () async {
      await GameRepository.loadAllDefs(loader: fileLoader);
      final defs = GameRepository.instance.shopItemDefs;
      final small = defs['shop_jingyandan_small'];
      final mid = defs['shop_jingyandan_mid'];
      expect(small?.itemType, ItemType.jingYanDan);
      expect(small?.isDynamicPrice, true);
      expect(small?.priceLayerFraction, 1.0);
      expect(mid?.isDynamicPrice, true);
      expect(mid?.priceLayerFraction, 2.5);
      // 动态价商品 price 字段为 null
      expect(small?.price, isNull);
      expect(mid?.price, isNull);
    });

    test('秘籍不在 shop（§5.7）', () async {
      await GameRepository.loadAllDefs(loader: fileLoader);
      final defs = GameRepository.instance.shopItemDefs;
      expect(
        defs.values.any((d) => d.itemDefId.startsWith('item_scroll_')),
        isFalse,
      );
    });

    test('秘籍上架 shop → 抛 StateError（§5.7 守门，F8）', () async {
      final Map<String, String> memOverrides = {
        'data/shop.yaml': '''
shop:
  - id: shop_evil_scroll
    itemDefId: item_scroll_kai_bei_shou
    itemType: techniqueScroll
    price: 100
    category: material
''',
      };
      Future<String> hybridLoader(String path) async {
        if (memOverrides.containsKey(path)) return memOverrides[path]!;
        return fileLoader(path);
      }
      await expectLater(
        GameRepository.loadAllDefs(loader: hybridLoader),
        throwsA(isA<StateError>()
            .having((e) => e.toString(), 'message', contains('§5.7'))),
      );
    });

    test('大还丹（大档经验丹 layer_fraction=1.0）上架 shop → 抛 StateError（§5.7 守门，F8）',
        () async {
      final Map<String, String> memOverrides = {
        'data/shop.yaml': '''
shop:
  - id: shop_evil_dahuandan
    itemDefId: item_jingyandan_large
    itemType: jingYanDan
    price_layer_fraction: 1.0
    category: pill
''',
      };
      Future<String> hybridLoader(String path) async {
        if (memOverrides.containsKey(path)) return memOverrides[path]!;
        return fileLoader(path);
      }
      await expectLater(
        GameRepository.loadAllDefs(loader: hybridLoader),
        throwsA(isA<StateError>()
            .having((e) => e.toString(), 'message', contains('§5.7'))),
      );
    });

    test('凝神丹/培元丹（小/中档 layer_fraction<1.0）上架 shop → 不因 §5.7 抛（正例，F8）',
        () async {
      // 生产 shop.yaml 本就含小/中档,直接加载不应触发 §5.7 守门。
      await GameRepository.loadAllDefs(loader: fileLoader);
      final defs = GameRepository.instance.shopItemDefs;
      expect(defs['shop_jingyandan_small'], isNotNull);
      expect(defs['shop_jingyandan_mid'], isNotNull);
    });

    test('_enforceRedLines 标价超 100000 抛 StateError', () async {
      // 用内存 loader 构造超标价条目，只提供 shop.yaml 其余 yaml 走文件
      final Map<String, String> memOverrides = {
        'data/shop.yaml': '''
shop:
  - id: shop_overpriced
    itemDefId: item_mojianshi
    itemType: moJianShi
    price: 999999
    category: material
''',
      };

      Future<String> hybridLoader(String path) async {
        if (memOverrides.containsKey(path)) return memOverrides[path]!;
        return fileLoader(path);
      }

      expect(
        () async => GameRepository.loadAllDefs(loader: hybridLoader),
        throwsA(isA<StateError>()),
      );
    });
  });
}
