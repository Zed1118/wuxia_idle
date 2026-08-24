import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/features/jianghu/presentation/reputation_panel_screen.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/jianghu_map_screen.dart';
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/domain/onboarding_gate.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  Widget mainMenuWith(List<String> clearedStageIds) => ProviderScope(
    overrides: [
      mainlineProgressProvider.overrideWith(
        (ref) async => MainlineProgress()..clearedStageIds = clearedStageIds,
      ),
    ],
    child: const MaterialApp(home: MainMenu()),
  );

  Widget mapWith(List<String> clearedStageIds) => ProviderScope(
    overrides: [
      towerProgressProvider.overrideWith(
        (ref) async => TowerProgress()
          ..saveDataId = 0
          ..highestClearedFloor = 0,
      ),
      mainlineProgressProvider.overrideWith(
        (ref) async => MainlineProgress()..clearedStageIds = clearedStageIds,
      ),
      activeRetreatSessionProvider.overrideWith((ref) async => null),
      mainMenuSaveSnapshotProvider.overrideWith(
        (ref) async => SaveData()..jianghuJourneyUnlocked = false,
      ),
      activeGauntletProvider.overrideWith((ref) async => null),
      activeExpeditionProvider.overrideWith((ref) async => null),
    ],
    child: const MaterialApp(home: JianghuMapScreen()),
  );

  Future<Finder> revealLocation(WidgetTester tester) async {
    final location = find.byKey(
      const ValueKey('jianghu-map-reputation-location'),
    );
    await tester.scrollUntilVisible(
      location,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    return location;
  }

  testWidgets('江湖恩怨不再作为主菜单平铺入口', (tester) async {
    await tester.pumpWidget(mainMenuWith(const [kFirstChapterFinalStageId]));
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.mainMenuJianghu), findsNothing);
  });

  testWidgets('第一章末关前地图显示锁定声望地点且不导航', (tester) async {
    await tester.pumpWidget(mapWith(const []));
    await tester.pump();
    await tester.pump();
    final location = await revealLocation(tester);

    final button = tester.widget<WuxiaInkButton>(location);
    expect(button.locked, isTrue);
    expect(button.disabled, isTrue);
    expect(button.onTap, isNull);
    expect(button.hint, UiStrings.mainMenuSocialLockedHint);
  });

  testWidgets('第一章末关后地图启用声望地点', (tester) async {
    await tester.pumpWidget(mapWith(const [kFirstChapterFinalStageId]));
    await tester.pump();
    await tester.pump();
    final location = await revealLocation(tester);

    final button = tester.widget<WuxiaInkButton>(location);
    expect(button.locked, isFalse);
    expect(button.disabled, isFalse);
    expect(button.onTap, isNotNull);
    expect(find.text(UiStrings.mainMenuJianghu), findsOneWidget);
  });

  testWidgets('地图声望地点进入既有江湖声望面板', (tester) async {
    await tester.pumpWidget(mapWith(const [kFirstChapterFinalStageId]));
    await tester.pump();
    await tester.pump();
    final location = await revealLocation(tester);

    tester.widget<WuxiaInkButton>(location).onTap!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ReputationPanelScreen), findsOneWidget);
  });
}
