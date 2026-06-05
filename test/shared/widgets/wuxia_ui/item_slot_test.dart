import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/item_slot.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/seal_badge.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  ItemSlot slot({
    String? imagePath = 'assets/equipment/x_detail.png',
    int enhanceLevel = 0,
    bool locked = false,
    bool highTier = false,
  }) =>
      ItemSlot(
        imagePath: imagePath,
        name: '青锋剑',
        tierColor: const Color(0xFF566B63),
        equipmentSlot: EquipmentSlot.weapon,
        enhanceLevel: enhanceLevel,
        locked: locked,
        highTier: highTier,
      );

  BoxDecoration cellDeco(WidgetTester tester) => tester
      .widget<Container>(find.descendant(
        of: find.byType(ItemSlot),
        matching: find.byType(Container),
      ))
      .decoration as BoxDecoration;

  testWidgets('渲染名称 + 缺图走 EquipGlyph 不抛异常', (tester) async {
    await tester.pumpWidget(host(slot()));
    expect(tester.takeException(), isNull);
    expect(find.text('青锋剑'), findsOneWidget);
  });

  testWidgets('enhanceLevel>0 显强化朱印 +N', (tester) async {
    await tester.pumpWidget(host(slot(enhanceLevel: 7)));
    expect(find.byType(SealBadge), findsOneWidget);
    expect(find.text('+7'), findsOneWidget);
  });

  testWidgets('enhanceLevel=0 不显朱印', (tester) async {
    await tester.pumpWidget(host(slot(enhanceLevel: 0)));
    expect(find.byType(SealBadge), findsNothing);
  });

  testWidgets('locked 显封条文字', (tester) async {
    await tester.pumpWidget(host(slot(locked: true)));
    expect(find.text('未达境界'), findsOneWidget);
  });

  testWidgets('imagePath=null 直接走 EquipGlyph 占位', (tester) async {
    await tester.pumpWidget(host(slot(imagePath: null)));
    expect(tester.takeException(), isNull);
    expect(find.text('青锋剑'), findsOneWidget);
  });

  testWidgets('highTier=true 金框 + 光晕；false 墨框无光晕', (tester) async {
    await tester.pumpWidget(host(slot(imagePath: null, highTier: true)));
    final hi = cellDeco(tester);
    expect((hi.border as Border).top.color, WuxiaUi.gold);
    expect(hi.boxShadow, isNotEmpty);

    await tester.pumpWidget(host(slot(imagePath: null, highTier: false)));
    final lo = cellDeco(tester);
    expect((lo.border as Border).top.color, WuxiaUi.ink);
    expect(lo.boxShadow, isNull);
  });
}
