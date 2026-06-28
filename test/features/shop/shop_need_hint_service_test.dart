import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/item_source.dart';
import 'package:wuxia_idle/core/domain/item_usage.dart';
import 'package:wuxia_idle/data/defs/shop_item_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/shop/application/shop_need_hint_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameRepository repo;
  late ShopNeedHintService service;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
    service = ShopNeedHintService(repo);
  });

  Character character({
    required String name,
    required bool isFounder,
    double injuryHours = 0,
  }) {
    return Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
      createdAt: DateTime(2026, 6, 29),
      isFounder: isFounder,
      isActive: true,
      injuryHoursRemaining: injuryHours,
    );
  }

  test('经验丹提示具体品名、当前祖师与修为突破用途', () {
    final def = repo.shopItemDefs['shop_jingyandan_small']!;
    final hint = service.hintFor(
      def: def,
      activeCharacters: [
        character(name: '沈青', isFounder: true),
        character(name: '陆小刀', isFounder: false),
      ],
    );

    expect(hint.displayName, '凝神丹');
    expect(hint.showCurrentUsers, true);
    expect(hint.currentUserNames, ['沈青']);
    expect(
      hint.usages.map((usage) => usage.kind),
      contains(ItemUsageKind.realmProgress),
    );
  });

  test('强化材料提示装备消耗系统并排除商店自身来源', () {
    final def = repo.shopItemDefs['shop_mojianshi']!;
    final hint = service.hintFor(
      def: def,
      activeCharacters: [character(name: '沈青', isFounder: true)],
    );

    expect(hint.displayName, '磨剑石');
    expect(hint.showCurrentUsers, false);
    expect(
      hint.usages.map((usage) => usage.kind),
      contains(ItemUsageKind.equipmentEnhancement),
    );
    expect(
      hint.alternateSources.map((source) => source.kind),
      isNot(contains(ItemSourceKind.shop)),
    );
    expect(hint.alternateSources, isNotEmpty);
  });

  test('疗伤物品只提示真正受伤的当前角色', () {
    final def = repo.itemDefs['item_liaoshangdan']!;
    final shopLike = ShopItemDef(
      id: 'shop_liaoshangdan_test',
      itemDefId: def.defId,
      itemType: def.type,
      price: 1,
      category: 'pill',
    );
    final hint = service.hintFor(
      def: shopLike,
      activeCharacters: [
        character(name: '沈青', isFounder: true),
        character(name: '陆小刀', isFounder: false, injuryHours: 4),
      ],
    );

    expect(hint.showCurrentUsers, true);
    expect(hint.currentUserNames, ['陆小刀']);
    expect(
      hint.usages.map((usage) => usage.kind),
      contains(ItemUsageKind.injuryRecovery),
    );
  });
}
