// test/features/loot_preview/loot_summary_line_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/loot_summary_line.dart';
import 'package:wuxia_idle/shared/strings.dart';

Widget _host(Widget body) => MaterialApp(home: Scaffold(body: body));

void main() {
  testWidgets('空表显「本关无固定收获」', (tester) async {
    await tester.pumpWidget(_host(LootSummaryLine(
      table: DropRumorTable.fromDropTable(const [],
          gating: FirstClearGating.scrollOnly),
    )));
    expect(find.textContaining(UiStrings.lootNoFixedDrop), findsOneWidget);
  });

  testWidgets('有掉落显前缀「可能收获：」+ 无 %', (tester) async {
    final table = DropRumorTable.fromDropTable(const [
      ItemDrop(inventoryItemDefId: 'item_mojianshi', quantityMin: 1, quantityMax: 1, dropChance: 1.0),
    ], gating: FirstClearGating.scrollOnly);
    await tester.pumpWidget(_host(LootSummaryLine(table: table)));
    expect(find.textContaining(UiStrings.lootSummaryPrefix), findsOneWidget);
    expect(find.textContaining('磨剑石'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}
