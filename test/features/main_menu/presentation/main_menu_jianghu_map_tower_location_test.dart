import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/jianghu_map_screen.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  Widget app() => const ProviderScope(child: MaterialApp(home: MainMenu()));

  testWidgets('九霄塔不再作为主菜单平铺入口', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text(UiStrings.mainMenuTower), findsNothing);
  });

  testWidgets('继续江湖卡片提供次级江湖地图动作', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text(UiStrings.mainMenuJianghuMapAction), findsOneWidget);
  });

  testWidgets('次级地图动作进入 JianghuMapScreen，不抢占继续江湖主动作', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.tap(find.text(UiStrings.mainMenuJianghuMapAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(JianghuMapScreen), findsOneWidget);
  });
}
