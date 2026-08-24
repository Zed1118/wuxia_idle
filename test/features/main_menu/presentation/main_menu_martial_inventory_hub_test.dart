import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/features/cangjingge/presentation/cangjingge_screen.dart';
import 'package:wuxia_idle/features/inventory/presentation/inventory_screen.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/martial_inventory/presentation/martial_inventory_hub_screen.dart';
import 'package:wuxia_idle/features/technique_panel/presentation/technique_panel_screen.dart';
import 'package:wuxia_idle/features/tutorial/application/tutorial_providers.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  Widget hubApp({required int tutorialStep, List<int> activeIds = const [7]}) {
    return ProviderScope(
      overrides: [
        currentTutorialStepProvider.overrideWith((ref) async => tutorialStep),
        activeCharacterIdsProvider.overrideWith((ref) async => activeIds),
      ],
      child: const MaterialApp(home: MartialInventoryHubScreen()),
    );
  }

  Finder hubButton(String label) => find.byWidgetPredicate(
    (widget) => widget is WuxiaInkButton && widget.label == label,
  );

  Future<void> tapVisibleLabel(WidgetTester tester, String label) async {
    final button = hubButton(label);
    await Scrollable.ensureVisible(
      tester.element(button),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> popRoute(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('主菜单只保留统一武学与行囊入口，不再平铺旧三入口', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainMenu())),
    );

    expect(find.text(UiStrings.mainMenuMartialInventory), findsOneWidget);
    expect(find.text(UiStrings.mainMenuInventory), findsNothing);
    expect(find.text(UiStrings.mainMenuTechniques), findsNothing);
    expect(find.text(UiStrings.mainMenuSkillLibrary), findsNothing);

    await tapVisibleLabel(tester, UiStrings.mainMenuMartialInventory);

    expect(find.byType(MartialInventoryHubScreen), findsOneWidget);
  });

  testWidgets('Hub 四项使用明确的招式、主修、装备、物品合同', (tester) async {
    await tester.pumpWidget(hubApp(tutorialStep: 3));
    await tester.pump();

    expect(hubButton(UiStrings.martialInventorySkills), findsOneWidget);
    expect(hubButton(UiStrings.martialInventoryTechniques), findsOneWidget);
    expect(hubButton(UiStrings.martialInventoryEquipment), findsOneWidget);
    expect(hubButton(UiStrings.martialInventoryItems), findsOneWidget);
  });

  testWidgets('装备与物品分别进入生产 InventoryScreen 的正确 Tab', (tester) async {
    await tester.pumpWidget(hubApp(tutorialStep: 0));
    await tester.pump();

    await tapVisibleLabel(tester, UiStrings.martialInventoryEquipment);
    var inventory = tester.widget<InventoryScreen>(
      find.byType(InventoryScreen),
    );
    expect(inventory.initialTab, 0);

    await popRoute(tester);
    await tapVisibleLabel(tester, UiStrings.martialInventoryItems);
    inventory = tester.widget<InventoryScreen>(find.byType(InventoryScreen));
    expect(inventory.initialTab, 1);
  });

  testWidgets('招式与主修沿用 step 3 门控，装备与物品开局可用', (tester) async {
    await tester.pumpWidget(hubApp(tutorialStep: 0));
    await tester.pump();

    expect(
      tester
          .widget<WuxiaInkButton>(hubButton(UiStrings.martialInventorySkills))
          .disabled,
      isTrue,
    );
    expect(
      tester
          .widget<WuxiaInkButton>(
            hubButton(UiStrings.martialInventoryTechniques),
          )
          .disabled,
      isTrue,
    );
    expect(
      tester
          .widget<WuxiaInkButton>(
            hubButton(UiStrings.martialInventoryEquipment),
          )
          .disabled,
      isFalse,
    );
    expect(
      tester
          .widget<WuxiaInkButton>(hubButton(UiStrings.martialInventoryItems))
          .disabled,
      isFalse,
    );
  });

  testWidgets('step=2 时招式与主修仍保持锁定', (tester) async {
    await tester.pumpWidget(hubApp(tutorialStep: 2));
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .widget<WuxiaInkButton>(hubButton(UiStrings.martialInventorySkills))
          .disabled,
      isTrue,
    );
    expect(
      tester
          .widget<WuxiaInkButton>(
            hubButton(UiStrings.martialInventoryTechniques),
          )
          .disabled,
      isTrue,
    );
  });

  for (final step in const [5, 8]) {
    testWidgets('step=$step 时招式与主修保持向上兼容解锁', (tester) async {
      await tester.pumpWidget(hubApp(tutorialStep: step));
      await tester.pump();
      await tester.pump();

      expect(
        tester
            .widget<WuxiaInkButton>(hubButton(UiStrings.martialInventorySkills))
            .disabled,
        isFalse,
      );
      expect(
        tester
            .widget<WuxiaInkButton>(
              hubButton(UiStrings.martialInventoryTechniques),
            )
            .disabled,
        isFalse,
      );
    });
  }

  testWidgets('active roster 仍 loading 时武学入口 fail closed', (tester) async {
    final activeIds = Completer<List<int>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTutorialStepProvider.overrideWith((ref) async => 5),
          activeCharacterIdsProvider.overrideWith((ref) => activeIds.future),
        ],
        child: const MaterialApp(home: MartialInventoryHubScreen()),
      ),
    );
    await tester.pump();

    expect(
      tester
          .widget<WuxiaInkButton>(hubButton(UiStrings.martialInventorySkills))
          .disabled,
      isTrue,
    );
    expect(
      tester
          .widget<WuxiaInkButton>(
            hubButton(UiStrings.martialInventoryTechniques),
          )
          .disabled,
      isTrue,
    );

    activeIds.complete(const []);
    await tester.pump();
  });

  testWidgets('step 已开放但 active roster 为空时武学入口 fail closed', (tester) async {
    await tester.pumpWidget(hubApp(tutorialStep: 3, activeIds: const []));
    await tester.pump();
    await tester.pump();

    expect(
      tester
          .widget<WuxiaInkButton>(hubButton(UiStrings.martialInventorySkills))
          .disabled,
      isTrue,
    );
    expect(
      tester
          .widget<WuxiaInkButton>(
            hubButton(UiStrings.martialInventoryTechniques),
          )
          .disabled,
      isTrue,
    );
    expect(
      find.text(UiStrings.martialInventoryNoActiveCharacterHint),
      findsNWidgets(2),
    );
  });

  testWidgets('招式与主修把 active roster 第一位角色交给既有生产 Screen', (tester) async {
    await tester.pumpWidget(hubApp(tutorialStep: 3, activeIds: const [41, 7]));
    await tester.pump();

    await tapVisibleLabel(tester, UiStrings.martialInventorySkills);
    expect(
      tester
          .widget<CangJingGeScreen>(find.byType(CangJingGeScreen))
          .characterId,
      41,
    );

    await popRoute(tester);
    await tapVisibleLabel(tester, UiStrings.martialInventoryTechniques);
    expect(
      tester
          .widget<TechniquePanelScreen>(find.byType(TechniquePanelScreen))
          .characterId,
      41,
    );
  });

  testWidgets('1280×720 与 1440×900 的 Hub 均无布局异常', (tester) async {
    for (final size in const [Size(1280, 720), Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(hubApp(tutorialStep: 3));
      await tester.pump();

      expect(find.text(UiStrings.martialInventoryHubTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
