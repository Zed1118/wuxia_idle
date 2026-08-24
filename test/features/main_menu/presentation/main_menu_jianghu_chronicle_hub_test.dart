import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/baike/presentation/baike_screen.dart';
import 'package:wuxia_idle/features/battle_record/presentation/battle_record_screen.dart';
import 'package:wuxia_idle/features/character_panel/presentation/lineage_panel_screen.dart';
import 'package:wuxia_idle/features/jianghu_chronicle/presentation/jianghu_chronicle_hub_screen.dart';
import 'package:wuxia_idle/features/jianghu_chronicle/presentation/mainline_location_archive_screen.dart';
import 'package:wuxia_idle/features/jianghu_chronicle/presentation/pending_jianghu_affairs_screen.dart';
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/mainline/presentation/chapter_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  Finder hubButton(String label) => find.byWidgetPredicate(
    (widget) => widget is WuxiaInkButton && widget.label == label,
  );

  Future<void> tapLabel(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Widget hub({
    bool battleRecordUnlocked = true,
    bool equipmentLoreUnlocked = true,
    void Function(Widget screen)? routeObserverForTest,
  }) => MaterialApp(
    home: JianghuChronicleHubScreen(
      battleRecordUnlocked: battleRecordUnlocked,
      equipmentLoreUnlocked: equipmentLoreUnlocked,
      routeObserverForTest: routeObserverForTest,
    ),
  );

  testWidgets('主菜单只保留统一江湖纪事入口，不再平铺旧档案入口', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainMenuSaveSnapshotProvider.overrideWith(
            (ref) async => SaveData()..jianghuJourneyUnlocked = true,
          ),
        ],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.mainMenuJianghuChronicle), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLineage), findsNothing);
    expect(find.text(UiStrings.mainMenuLeaderboard), findsNothing);
    expect(find.text(UiStrings.mainMenuZangjuange), findsNothing);
    expect(find.text(UiStrings.mainMenuBattleRecord), findsNothing);
    expect(find.text(UiStrings.mainMenuWeaponCodex), findsNothing);
    expect(find.text(UiStrings.mainMenuBaike), findsNothing);

    await tapLabel(tester, UiStrings.mainMenuJianghuChronicle);
    expect(find.byType(JianghuChronicleHubScreen), findsOneWidget);
  });

  testWidgets('Hub 明确呈现章节、人物、地点、敌手、装备典故和待处理事项', (tester) async {
    await tester.pumpWidget(hub());
    await tester.pump();

    expect(hubButton(UiStrings.jianghuChronicleChapters), findsOneWidget);
    expect(hubButton(UiStrings.jianghuChronicleCharacters), findsOneWidget);
    expect(hubButton(UiStrings.jianghuChronicleLocations), findsOneWidget);
    expect(hubButton(UiStrings.jianghuChronicleEnemies), findsOneWidget);
    expect(hubButton(UiStrings.jianghuChronicleEquipmentLore), findsOneWidget);
    expect(hubButton(UiStrings.jianghuChroniclePendingAffairs), findsOneWidget);
  });

  testWidgets('六个入口落到既有生产页面或专用只读页面', (tester) async {
    final routes = <Widget>[];
    await tester.pumpWidget(hub(routeObserverForTest: routes.add));
    await tester.pump();

    await tapLabel(tester, UiStrings.jianghuChronicleChapters);
    expect(routes.last, isA<ChapterListScreen>());

    await tapLabel(tester, UiStrings.jianghuChronicleCharacters);
    expect(routes.last, isA<LineagePanelScreen>());

    await tapLabel(tester, UiStrings.jianghuChronicleLocations);
    expect(routes.last, isA<MainlineLocationArchiveScreen>());

    await tapLabel(tester, UiStrings.jianghuChronicleEnemies);
    expect(routes.last, isA<BattleRecordScreen>());

    await tapLabel(tester, UiStrings.jianghuChronicleEquipmentLore);
    expect(routes.last, isA<BaikeScreen>());
    expect((routes.last as BaikeScreen).initialTab, 1);

    await tapLabel(tester, UiStrings.jianghuChroniclePendingAffairs);
    expect(routes.last, isA<PendingJianghuAffairsScreen>());
  });

  testWidgets('敌手与装备典故沿用既有隐藏门控，其他四类仍可达', (tester) async {
    await tester.pumpWidget(
      hub(battleRecordUnlocked: false, equipmentLoreUnlocked: false),
    );
    await tester.pump();

    expect(hubButton(UiStrings.jianghuChronicleEnemies), findsNothing);
    expect(hubButton(UiStrings.jianghuChronicleEquipmentLore), findsNothing);
    expect(hubButton(UiStrings.jianghuChronicleChapters), findsOneWidget);
    expect(hubButton(UiStrings.jianghuChronicleCharacters), findsOneWidget);
    expect(hubButton(UiStrings.jianghuChronicleLocations), findsOneWidget);
    expect(hubButton(UiStrings.jianghuChroniclePendingAffairs), findsOneWidget);
  });

  testWidgets('1280x720 与 1440x900 均无布局异常', (tester) async {
    for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size must be clean');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
