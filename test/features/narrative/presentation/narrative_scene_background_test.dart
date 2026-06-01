import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/narrative/presentation/narrative_scene_background.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

Widget _wrap(Widget c) => MaterialApp(home: Scaffold(body: c));

void main() {
  testWidgets('path 非空 → 有背景 Image + scrim 遮罩层', (tester) async {
    await tester.pumpWidget(_wrap(const NarrativeSceneBackground(
        path: 'assets/scenes/narrative_stage_01_01.png')));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    final scrim = find.byWidgetPredicate((w) =>
        w is ColoredBox && w.color == WuxiaColors.narrativeSceneScrim);
    expect(scrim, findsOneWidget);
  });

  testWidgets('path null → SizedBox.shrink(无 Image 无 scrim)', (tester) async {
    await tester.pumpWidget(_wrap(const NarrativeSceneBackground(path: null)));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    final scrim = find.byWidgetPredicate((w) =>
        w is ColoredBox && w.color == WuxiaColors.narrativeSceneScrim);
    expect(scrim, findsNothing);
  });
}
