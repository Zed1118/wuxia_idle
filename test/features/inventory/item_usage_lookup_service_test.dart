import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/item_usage.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/inventory/application/item_usage_lookup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameRepository repo;
  late ItemUsageLookupService service;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs();
    service = ItemUsageLookupService(repo);
  });

  List<ItemUsageKind> kindsOf(String itemId) =>
      service.usagesFor(itemId).map((u) => u.kind).toList();

  test('突破/修为材料：经验丹反查到修为突破用途', () {
    expect(
      kindsOf('item_jingyandan_small'),
      contains(ItemUsageKind.realmProgress),
    );
  });

  test('普通材料：精铁反查到桃花岛升级与加工用途', () {
    final kinds = kindsOf('item_jingtie');

    expect(kinds, contains(ItemUsageKind.islandBuildingUpgrade));
    expect(kinds, contains(ItemUsageKind.islandRecipeInput));
  });

  test('疗伤丹反查到疗伤调理用途', () {
    expect(kindsOf('item_liaoshangdan'), contains(ItemUsageKind.injuryRelief));
  });

  test('装备材料：磨剑石与心血结晶只反查实际装备消耗', () {
    expect(
      kindsOf('item_mojianshi'),
      contains(ItemUsageKind.equipmentEnhancement),
    );
    expect(
      kindsOf('item_xinxuejiejing'),
      contains(ItemUsageKind.equipmentGuarantee),
    );
  });

  test('银两反查到商店采买与桃花岛升级货币用途', () {
    final kinds = kindsOf('item_silver');

    expect(kinds, contains(ItemUsageKind.shopPurchaseCurrency));
    expect(kinds, contains(ItemUsageKind.islandUpgradeCurrency));
  });

  test('无用途 item 返回空列表', () {
    expect(service.usagesFor('item_unused_fixture'), isEmpty);
  });
}
