import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_loadout_screen.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/jianghu_map_screen.dart';
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  Widget mainMenuWith(bool unlocked) => ProviderScope(
    overrides: [
      mainMenuSaveSnapshotProvider.overrideWith(
        (ref) async => SaveData()..jianghuJourneyUnlocked = unlocked,
      ),
    ],
    child: const MaterialApp(home: MainMenu()),
  );

  Widget mapWith(bool unlocked) => ProviderScope(
    overrides: [
      mainMenuSaveSnapshotProvider.overrideWith(
        (ref) async => SaveData()..jianghuJourneyUnlocked = unlocked,
      ),
      mainlineProgressProvider.overrideWith((ref) async => MainlineProgress()),
      towerProgressProvider.overrideWith(
        (ref) async => TowerProgress()..saveDataId = 0,
      ),
      activeRetreatSessionProvider.overrideWith((ref) async => null),
    ],
    child: const MaterialApp(home: JianghuMapScreen()),
  );

  testWidgets('断魂庄不再作为主菜单平铺入口', (tester) async {
    await tester.pumpWidget(mainMenuWith(true));
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.gauntletName), findsNothing);
  });

  testWidgets('既有隐藏门满足后地图显示断魂庄地点', (tester) async {
    await tester.pumpWidget(mapWith(true));
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.gauntletName), findsOneWidget);
  });

  testWidgets('地图断魂庄地点进入原 GauntletLoadoutScreen', (tester) async {
    await tester.pumpWidget(mapWith(true));
    await tester.pump();
    await tester.pump();

    final location = find.byKey(
      const ValueKey('jianghu-map-gauntlet-location'),
    );
    await tester.ensureVisible(location);
    await tester.pumpAndSettle();
    tester.widget<WuxiaInkButton>(location).onTap!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(GauntletLoadoutScreen), findsOneWidget);
  });

  testWidgets('既有隐藏门未满足时地图不泄露断魂庄', (tester) async {
    await tester.pumpWidget(mapWith(false));
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.gauntletName), findsNothing);
  });
}
