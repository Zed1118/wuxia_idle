import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('leftWin 显金「胜」+ 统计 + 继续', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(VictoryOverlay(
      result: BattleResult.leftWin,
      totalDamage: 12000, critCount: 3, totalTicks: 18,
      onContinue: () => tapped = true,
    )));
    expect(find.text(UiStrings.victoryTitle), findsOneWidget);
    expect(find.text(UiStrings.victorySubtitle), findsOneWidget);
    // 大题字金色
    final title = tester.widget<Text>(find.text(UiStrings.victoryTitle));
    expect(title.style?.color, WuxiaColors.resultHighlight);
    // 统计含总伤
    expect(find.textContaining('12000'), findsOneWidget);
    await tester.tap(find.text(UiStrings.battleContinue));
    expect(tapped, isTrue);
  });

  testWidgets('rightWin 显绛红「败」', (tester) async {
    await tester.pumpWidget(_wrap(VictoryOverlay(
      result: BattleResult.rightWin,
      totalDamage: 5000, critCount: 1, totalTicks: 9,
      onContinue: () {},
    )));
    expect(find.text(UiStrings.defeatTitle), findsOneWidget);
    final title = tester.widget<Text>(find.text(UiStrings.defeatTitle));
    expect(title.style?.color, WuxiaColors.gangMeng);
  });

  testWidgets('draw 也走败样式', (tester) async {
    await tester.pumpWidget(_wrap(VictoryOverlay(
      result: BattleResult.draw,
      totalDamage: 0, critCount: 0, totalTicks: 5,
      onContinue: () {},
    )));
    expect(find.text(UiStrings.defeatTitle), findsOneWidget);
  });

  testWidgets('遮罩用径向渐变 vignette 而非整屏纯黑（P0-2 Task8）', (tester) async {
    await tester.pumpWidget(_wrap(VictoryOverlay(
      result: BattleResult.leftWin,
      totalDamage: 1, critCount: 0, totalTicks: 1,
      onContinue: () {},
    )));
    final deco = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.gradient is RadialGradient);
    expect(deco.gradient, isA<RadialGradient>());
  });
}
