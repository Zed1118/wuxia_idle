import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/equipment_def.dart';
import 'package:wuxia_idle/data/defs/shop_item_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/equipment/application/equipment_source_lookup.dart';
import 'package:wuxia_idle/features/equipment/domain/equipment_source.dart';
import '../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  test('主线 dropTable 反查装备来源', () {
    final sources = EquipmentSourceLookup(
      GameRepository.instance,
    ).sourcesFor('armor_xunchang_bu_yi');

    expect(
      sources,
      contains(
        const EquipmentSource.mainline(
          stageId: 'stage_01_01',
          stageName: '山门之外',
          chapterIndex: 1,
          isBoss: false,
        ),
      ),
    );
  });

  test('爬塔 dropTable 反查装备来源', () {
    final sources = EquipmentSourceLookup(
      GameRepository.instance,
    ).sourcesFor('weapon_xiangyang_chang_jian');

    // 批 A 塔重排:xiangyang_chang_jian 现于 floor 13(sanLiu 普通层)轮转掉落。
    expect(
      sources,
      contains(const EquipmentSource.tower(floorIndex: 13, isBoss: false)),
    );
  });

  test('商店定义反查装备来源', () {
    const def = EquipmentDef(
      id: 'weapon_shop_only',
      name: '铺中剑',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      baseAttackMin: 1,
      baseAttackMax: 1,
      baseHealthMin: 0,
      baseHealthMax: 0,
      baseSpeedMin: 0,
      baseSpeedMax: 0,
      presetLoreIds: [],
      dropSourceTags: [],
      iconPath: 'placeholder',
    );

    final sources = EquipmentSourceLookup.sourcesForEquipmentDef(
      def,
      stages: const [],
      towerFloors: const [],
      seclusionMaps: const [],
      shopItems: const [
        ShopItemDef(
          id: 'shop_weapon_shop_only',
          itemDefId: 'weapon_shop_only',
          itemType: ItemType.miscMaterial,
          price: 100,
          category: 'equipment',
        ),
      ],
    );

    expect(
      sources,
      contains(const EquipmentSource.shop(shopId: 'shop_weapon_shop_only')),
    );
  });

  test('未知来源返回空列表，由 UI 优雅隐藏', () {
    const def = EquipmentDef(
      id: 'weapon_unknown',
      name: '无名剑',
      tier: EquipmentTier.xunChang,
      slot: EquipmentSlot.weapon,
      baseAttackMin: 1,
      baseAttackMax: 1,
      baseHealthMin: 0,
      baseHealthMax: 0,
      baseSpeedMin: 0,
      baseSpeedMax: 0,
      presetLoreIds: [],
      dropSourceTags: [],
      iconPath: 'placeholder',
    );

    final sources = EquipmentSourceLookup.sourcesForEquipmentDef(
      def,
      stages: const [],
      towerFloors: const [],
      seclusionMaps: const [],
      shopItems: const [],
    );

    expect(sources, isEmpty);
  });
}
