import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/hp_bar.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

void main() {
  testWidgets('compactLabel 对五位数战场数值使用 K 缩写', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HpBar(current: 12345, max: 40000, compactLabel: true),
        ),
      ),
    );

    expect(find.text('12.3K/40K'), findsOneWidget);
  });

  testWidgets('默认详细标签保留完整数值', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HpBar(current: 12345, max: 40000)),
      ),
    );

    expect(find.text('12345 / 40000'), findsOneWidget);
  });

  testWidgets('战场窄条可覆盖为旧纸墨轨并保留绛红语义', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HpBar(
            current: 80,
            max: 100,
            trackColorOverride: Color(0xA62A241D),
            fillColorOverride: WuxiaUi.jiang,
          ),
        ),
      ),
    );

    final track = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('battle.hpBarTrack')),
    );
    final fill = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('battle.hpBarFill')),
    );
    expect(track.color, const Color(0xA62A241D));
    expect(fill.color, WuxiaUi.jiang);
  });
}
