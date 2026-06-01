import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_scene_background.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

Widget _wrap(Widget c) => MaterialApp(home: Scaffold(body: c));

void main() {
  testWidgets('path 非空 → 有背景 Image + scrim 遮罩层', (tester) async {
    await tester.pumpWidget(_wrap(
      const BattleSceneBackground(path: 'assets/scenes/battle_citywall.png')));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    final scrim = find.byWidgetPredicate((w) =>
        w is ColoredBox && w.color == WuxiaColors.battleSceneScrim);
    expect(scrim, findsOneWidget);
  });

  testWidgets('path null → SizedBox.shrink(无 Image 无 scrim)', (tester) async {
    await tester.pumpWidget(_wrap(const BattleSceneBackground(path: null)));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    final scrim = find.byWidgetPredicate((w) =>
        w is ColoredBox && w.color == WuxiaColors.battleSceneScrim);
    expect(scrim, findsNothing);
  });
}
