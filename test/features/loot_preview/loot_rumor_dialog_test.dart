// test/features/loot_preview/loot_rumor_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/loot_rumor_dialog.dart';
import 'package:wuxia_idle/shared/strings.dart';

Widget _host(Widget body) => MaterialApp(home: Scaffold(body: body));

void main() {
  testWidgets('空表显「本关无固定收获」', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(LootRumorContent(
      table: DropRumorTable.fromDropTable(const [], isFirstClearGated: false),
      currentRealm: RealmTier.sanLiu,
    )));
    expect(find.text(UiStrings.lootNoFixedDrop), findsOneWidget);
  });

  testWidgets('分组列渲染桶名 + 无 % 文本', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final table = DropRumorTable.fromDropTable(const [
      EquipmentDrop(equipmentDefId: 'weapon_a', dropChance: 1.0),
      ItemDrop(inventoryItemDefId: 'item_mojianshi', quantityMin: 1, quantityMax: 1, dropChance: 0.05),
    ], isFirstClearGated: false);
    await tester.pumpWidget(_host(LootRumorContent(table: table, currentRealm: RealmTier.sanLiu)));
    expect(find.text(UiStrings.lootBucketChangKeDe), findsOneWidget);
    expect(find.text(UiStrings.lootBucketJiangHuChuanWen), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('塔层上下文显脚注', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final table = DropRumorTable.fromDropTable(const [
      EquipmentDrop(equipmentDefId: 'weapon_a', dropChance: 1.0),
    ], isFirstClearGated: true);
    await tester.pumpWidget(_host(LootRumorContent(table: table, currentRealm: RealmTier.sanLiu)));
    expect(find.text(UiStrings.lootTowerFirstClearOnlyFooter), findsOneWidget);
    expect(find.text(UiStrings.lootBucketShouTongBiDe), findsOneWidget);
  });
}
