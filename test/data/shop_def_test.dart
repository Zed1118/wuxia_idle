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
      expect(mojian.price > 0, true);
      expect(mojian.itemType, ItemType.moJianShi);

      final xinxue = defs['shop_xinxue_jiejing'];
      expect(xinxue, isNotNull);
      expect(xinxue!.itemDefId, 'item_xinxuejiejing');
      expect(xinxue.price > 0, true);
      expect(xinxue.itemType, ItemType.xinXueJieJing);
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
