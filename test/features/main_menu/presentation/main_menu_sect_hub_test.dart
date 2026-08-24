import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/character_panel/presentation/character_panel_screen.dart';
import 'package:wuxia_idle/features/expedition/presentation/expedition_overview_screen.dart';
import 'package:wuxia_idle/features/lineup/presentation/team_lineup_screen.dart';
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_map_list_screen.dart';
import 'package:wuxia_idle/features/sect/presentation/sect_hub_screen.dart';
import 'package:wuxia_idle/features/sect/presentation/sect_screen.dart';
import 'package:wuxia_idle/features/taohua_island/presentation/taohua_island_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  Character character({int id = 41, RealmTier tier = RealmTier.yiLiu}) =>
      Character.create(
        name: '沈砚',
        realmTier: tier,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes()
          ..constitution = 5
          ..enlightenment = 5
          ..agility = 5
          ..fortune = 5,
        rarity: RarityTier.tianCai,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 8, 25),
      )..id = id;

  Widget hubApp({
    List<int> activeIds = const [41, 7],
    Character? activeCharacter,
    bool seclusionLocked = false,
    bool taohuaLocked = false,
    bool sectLocked = false,
    bool expeditionUnlocked = true,
    void Function(Widget screen)? routeObserverForTest,
  }) {
    final current = activeCharacter ?? character();
    return ProviderScope(
      overrides: [
        activeCharacterIdsProvider.overrideWith((ref) async => activeIds),
        if (activeIds.isNotEmpty)
          characterByIdProvider(
            activeIds.first,
          ).overrideWith((ref) async => current),
      ],
      child: MaterialApp(
        home: SectHubScreen(
          seclusionLocked: seclusionLocked,
          taohuaLocked: taohuaLocked,
          sectLocked: sectLocked,
          expeditionUnlocked: expeditionUnlocked,
          routeObserverForTest: routeObserverForTest,
        ),
      ),
    );
  }

  Finder hubButton(String label) => find.byWidgetPredicate(
    (widget) => widget is WuxiaInkButton && widget.label == label,
  );

  Future<void> tapVisibleLabel(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('主菜单只保留统一宗门入口，不再平铺旧五入口', (tester) async {
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

    expect(find.text(UiStrings.mainMenuSectHub), findsOneWidget);
    expect(find.text(UiStrings.mainMenuCharacterPanel), findsNothing);
    expect(find.text(UiStrings.mainMenuSeclusion), findsNothing);
    expect(find.text(UiStrings.mainMenuTaohuaIsland), findsNothing);
    expect(find.text(UiStrings.mainMenuSect), findsNothing);
    expect(find.text(UiStrings.mainMenuExpedition), findsNothing);

    await tapVisibleLabel(tester, UiStrings.mainMenuSectHub);
    expect(find.byType(SectHubScreen), findsOneWidget);
  });

  testWidgets('Hub 明确呈现角色、调度、闭关、疗伤、远征、生产与门派事务', (tester) async {
    await tester.pumpWidget(hubApp());
    await tester.pump();

    expect(hubButton(UiStrings.sectHubCharacters), findsOneWidget);
    expect(hubButton(UiStrings.sectHubLineup), findsOneWidget);
    expect(hubButton(UiStrings.sectHubSeclusion), findsOneWidget);
    expect(hubButton(UiStrings.sectHubHealing), findsOneWidget);
    expect(hubButton(UiStrings.sectHubExpedition), findsOneWidget);
    expect(hubButton(UiStrings.sectHubProduction), findsOneWidget);
    expect(hubButton(UiStrings.sectHubAffairs), findsOneWidget);
  });

  testWidgets('角色档案与伤势疗养使用 active roster 第一位角色', (tester) async {
    final routes = <Widget>[];
    await tester.pumpWidget(hubApp(routeObserverForTest: routes.add));
    await tester.pump();

    await tapVisibleLabel(tester, UiStrings.sectHubCharacters);
    expect((routes.single as CharacterPanelScreen).characterId, 41);

    await tapVisibleLabel(tester, UiStrings.sectHubHealing);
    expect((routes.last as CharacterPanelScreen).characterId, 41);
  });

  testWidgets('门人调度进入既有 TeamLineupScreen', (tester) async {
    final routes = <Widget>[];
    await tester.pumpWidget(hubApp(routeObserverForTest: routes.add));
    await tester.pump();

    await tapVisibleLabel(tester, UiStrings.sectHubLineup);
    expect(routes.single, isA<TeamLineupScreen>());
  });

  testWidgets('闭关把同一 active 角色 ID 与境界传入既有地图屏', (tester) async {
    final routes = <Widget>[];
    await tester.pumpWidget(
      hubApp(
        activeCharacter: character(tier: RealmTier.zongShi),
        routeObserverForTest: routes.add,
      ),
    );
    await tester.pump();

    await tapVisibleLabel(tester, UiStrings.sectHubSeclusion);
    final screen = routes.single as SeclusionMapListScreen;
    expect(screen.characterId, 41);
    expect(screen.charRealmTier, RealmTier.zongShi);
  });

  testWidgets('远征、生产与门派事务复用既有生产 Screen', (tester) async {
    final routes = <Widget>[];
    await tester.pumpWidget(hubApp(routeObserverForTest: routes.add));
    await tester.pump();

    await tapVisibleLabel(tester, UiStrings.sectHubExpedition);
    expect(routes.last, isA<ExpeditionOverviewScreen>());

    await tapVisibleLabel(tester, UiStrings.sectHubProduction);
    expect(routes.last, isA<TaohuaIslandScreen>());

    await tapVisibleLabel(tester, UiStrings.sectHubAffairs);
    expect(routes.last, isA<SectScreen>());
  });

  testWidgets('既有闭关、远征、桃花岛与门派事务门控在 Hub 内保持', (tester) async {
    await tester.pumpWidget(
      hubApp(
        seclusionLocked: true,
        taohuaLocked: true,
        sectLocked: true,
        expeditionUnlocked: false,
      ),
    );
    await tester.pump();

    expect(
      tester
          .widget<WuxiaInkButton>(hubButton(UiStrings.sectHubSeclusion))
          .disabled,
      isTrue,
    );
    expect(
      tester
          .widget<WuxiaInkButton>(hubButton(UiStrings.sectHubProduction))
          .disabled,
      isTrue,
    );
    expect(
      tester
          .widget<WuxiaInkButton>(hubButton(UiStrings.sectHubAffairs))
          .disabled,
      isTrue,
    );
    expect(hubButton(UiStrings.sectHubExpedition), findsNothing);
  });

  testWidgets('闭关在 step 5 后保持向上兼容开放', (tester) async {
    await tester.pumpWidget(hubApp(seclusionLocked: false));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<WuxiaInkButton>(hubButton(UiStrings.sectHubSeclusion))
          .disabled,
      isFalse,
    );
  });

  testWidgets('active roster loading 时角色、疗伤与闭关 fail closed', (tester) async {
    final ids = Completer<List<int>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) => ids.future),
        ],
        child: const MaterialApp(
          home: SectHubScreen(
            seclusionLocked: false,
            taohuaLocked: false,
            sectLocked: false,
            expeditionUnlocked: true,
          ),
        ),
      ),
    );
    await tester.pump();

    for (final label in [
      UiStrings.sectHubCharacters,
      UiStrings.sectHubHealing,
      UiStrings.sectHubSeclusion,
    ]) {
      expect(tester.widget<WuxiaInkButton>(hubButton(label)).disabled, isTrue);
    }

    ids.complete(const []);
    await tester.pump();
  });

  testWidgets('active roster 为空时依赖角色的三入口 fail closed', (tester) async {
    await tester.pumpWidget(hubApp(activeIds: const []));
    await tester.pump();
    await tester.pump();

    for (final label in [
      UiStrings.sectHubCharacters,
      UiStrings.sectHubHealing,
      UiStrings.sectHubSeclusion,
    ]) {
      expect(tester.widget<WuxiaInkButton>(hubButton(label)).disabled, isTrue);
    }
  });

  testWidgets('active roster 首位角色悬空时不回退硬编码角色', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeCharacterIdsProvider.overrideWith((ref) async => const [41]),
          characterByIdProvider(41).overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: SectHubScreen(
            seclusionLocked: false,
            taohuaLocked: false,
            sectLocked: false,
            expeditionUnlocked: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    for (final label in [
      UiStrings.sectHubCharacters,
      UiStrings.sectHubHealing,
      UiStrings.sectHubSeclusion,
    ]) {
      expect(tester.widget<WuxiaInkButton>(hubButton(label)).disabled, isTrue);
    }
  });

  testWidgets('1280×720 与 1440×900 的宗门 Hub 均无布局异常', (tester) async {
    for (final size in const [Size(1280, 720), Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(hubApp());
      await tester.pump();

      expect(find.text(UiStrings.sectHubTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
