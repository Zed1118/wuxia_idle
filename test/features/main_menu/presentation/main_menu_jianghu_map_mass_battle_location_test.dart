import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/jianghu_map_screen.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mass_battle/presentation/mass_battle_screen.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  MainlineProgress progressWith(List<String> clearedStageIds) =>
      MainlineProgress()..clearedStageIds = clearedStageIds;

  Widget mainMenuWith(List<String> clearedStageIds) => ProviderScope(
    overrides: [
      mainlineProgressProvider.overrideWith(
        (ref) async => progressWith(clearedStageIds),
      ),
    ],
    child: const MaterialApp(home: MainMenu()),
  );

  Widget mapWith(List<String> clearedStageIds) => ProviderScope(
    overrides: [
      mainlineProgressProvider.overrideWith(
        (ref) async => progressWith(clearedStageIds),
      ),
      towerProgressProvider.overrideWith(
        (ref) async => TowerProgress()..saveDataId = 0,
      ),
      activeRetreatSessionProvider.overrideWith((ref) async => null),
    ],
    child: const MaterialApp(home: JianghuMapScreen()),
  );

  testWidgets('守城试炼不再作为主菜单平铺入口', (tester) async {
    await tester.pumpWidget(mainMenuWith(const ['stage_06_05']));
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.mainMenuMassBattle), findsNothing);
  });

  testWidgets('新档地图显示锁定的守城地点', (tester) async {
    await tester.pumpWidget(mapWith(const []));
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.mainMenuMassBattle), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLateGameLockedHint), findsNWidgets(2));
  });

  testWidgets('原 Ch6 门槛满足后守城地点进入 MassBattleScreen', (tester) async {
    await tester.pumpWidget(mapWith(const ['stage_06_05']));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text(UiStrings.mainMenuMassBattle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(MassBattleScreen), findsOneWidget);
  });
}
