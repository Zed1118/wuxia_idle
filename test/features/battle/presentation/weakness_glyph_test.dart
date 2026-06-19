import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/impact_glyph_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 第七阶段批二② Task 7-B：会心题字（弱点命中走单字 glyph overlay）。
void main() {
  test('UiStrings.weaknessHitGlyph == 会心(2 字，适配单字 glyph box)', () {
    expect(UiStrings.weaknessHitGlyph, '会心');
  });

  testWidgets('会心 glyph 经 ImpactGlyphOverlay.show 渲染且不溢出 720p',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final key = GlobalKey<ImpactGlyphOverlayState>();
    await tester.pumpWidget(MaterialApp(home: ImpactGlyphOverlay(key: key)));
    key.currentState!.show(UiStrings.weaknessHitGlyph, isEnemy: false);
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text(UiStrings.weaknessHitGlyph), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.weaknessHitGlyph), findsNothing);
  });
}
