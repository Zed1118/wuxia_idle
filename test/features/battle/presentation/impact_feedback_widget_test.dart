import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/impact_glyph_overlay.dart';
import 'package:wuxia_idle/features/battle/presentation/screen_flash.dart';

void main() {
  testWidgets('ImpactGlyphOverlay idle 不渲染单字', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ImpactGlyphOverlay()));
    expect(find.text('震'), findsNothing);
  });

  testWidgets('ImpactGlyphOverlay show 后渲染单字且不溢出 720p', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final key = GlobalKey<ImpactGlyphOverlayState>();
    await tester.pumpWidget(MaterialApp(home: ImpactGlyphOverlay(key: key)));
    key.currentState!.show('震', isEnemy: false);
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('震'), findsWidgets);
    expect(tester.takeException(), isNull);
    // 动画自然落幕（870ms 总时长），settle 不留挂起 timer/controller。
    await tester.pumpAndSettle();
    expect(find.text('震'), findsNothing);
  });

  testWidgets('ImpactGlyphOverlay clear() 立即隐藏 in-flight 击杀字形（破界抢占）',
      (tester) async {
    final key = GlobalKey<ImpactGlyphOverlayState>();
    await tester.pumpWidget(MaterialApp(home: ImpactGlyphOverlay(key: key)));
    key.currentState!.show('斩', isEnemy: false);
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('斩'), findsWidgets, reason: '停留期字形在场');
    // 破界题字抢占 → clear() 同帧撤下击杀字形,让「结界破!」独占中央(不叠字)。
    key.currentState!.clear();
    await tester.pump();
    expect(find.text('斩'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ImpactGlyphOverlay clear() 无 in-flight 题字时为 no-op', (tester) async {
    final key = GlobalKey<ImpactGlyphOverlayState>();
    await tester.pumpWidget(MaterialApp(home: ImpactGlyphOverlay(key: key)));
    key.currentState!.clear();
    await tester.pump();
    expect(find.text('斩'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ScreenFlashOverlay idle 渲染 shrink（无 ColoredBox），flash 后出 ColoredBox',
      (tester) async {
    final key = GlobalKey<ScreenFlashOverlayState>();
    await tester.pumpWidget(MaterialApp(home: ScreenFlashOverlay(key: key)));
    // overlay 自身子树空闲只产 SizedBox.shrink，无 ColoredBox。
    expect(
      find.descendant(
        of: find.byType(ScreenFlashOverlay),
        matching: find.byType(ColoredBox),
      ),
      findsNothing,
    );
    key.currentState!.flash(0.3);
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      find.descendant(
        of: find.byType(ScreenFlashOverlay),
        matching: find.byType(ColoredBox),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    // 120ms 后淡出归零，回到 shrink。
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ScreenFlashOverlay),
        matching: find.byType(ColoredBox),
      ),
      findsNothing,
    );
  });
}
