import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/item_source.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/inventory/application/material_source_lookup_service.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameRepository repo;
  late MaterialSourceLookupService service;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs();
    service = MaterialSourceLookupService(repo);
  });

  List<ItemSourceKind> kindsOf(String itemId) =>
      service.sourcesFor(itemId).map((s) => s.kind).toList();

  test('磨剑石反查到主线、爬塔、闭关、加工、分解与商店来源', () {
    final kinds = kindsOf('item_mojianshi');

    expect(kinds, contains(ItemSourceKind.mainline));
    expect(kinds, contains(ItemSourceKind.tower));
    expect(kinds, contains(ItemSourceKind.seclusion));
    expect(kinds, contains(ItemSourceKind.islandRecipe));
    expect(kinds, contains(ItemSourceKind.equipmentDisassembly));
    expect(kinds, contains(ItemSourceKind.shop));
  });

  test('心血结晶反查到战斗掉落、强化失败、分解、加工与商店来源', () {
    final kinds = kindsOf('item_xinxuejiejing');

    expect(kinds, contains(ItemSourceKind.mainline));
    expect(kinds, contains(ItemSourceKind.tower));
    expect(kinds, contains(ItemSourceKind.enhancementFailure));
    expect(kinds, contains(ItemSourceKind.equipmentDisassembly));
    expect(kinds, contains(ItemSourceKind.islandRecipe));
    expect(kinds, contains(ItemSourceKind.shop));
  });

  test('经验丹反查到配置掉落或固定货架/加工来源', () {
    final largeKinds = kindsOf('item_jingyandan_large');
    expect(largeKinds, contains(ItemSourceKind.mainline));
    expect(largeKinds, contains(ItemSourceKind.tower));

    final smallKinds = kindsOf('item_jingyandan_small');
    expect(smallKinds, contains(ItemSourceKind.shop));
    expect(smallKinds, contains(ItemSourceKind.islandRecipe));
  });

  test('秘籍反查到塔或主线掉落，不误判为商店来源', () {
    final kinds = kindsOf('item_scroll_kai_bei_shou');

    expect(kinds, contains(ItemSourceKind.tower));
    expect(kinds, isNot(contains(ItemSourceKind.shop)));
  });

  test('来源摘要由 UiStrings 统一格式化', () {
    final summary = UiStrings.materialSourceSummary(
      service.sourcesFor('item_mojianshi'),
    );

    expect(summary, startsWith('主要来源：'));
    expect(summary, contains('主线'));
    expect(summary, contains('闭关'));
    expect(summary, contains('装备分解'));
  });
}
