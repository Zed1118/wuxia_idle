import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/resource_overview/presentation/resource_overview_screen.dart';
import 'package:wuxia_idle/features/settings/presentation/settings_panel.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_icon_button.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  Widget app() => const ProviderScope(child: MaterialApp(home: MainMenu()));

  Finder cornerTool(String tooltip) => find.byWidgetPredicate(
    (widget) => widget is WuxiaIconButton && widget.tooltip == tooltip,
  );

  testWidgets('资源总览与设置只在右上工具区，不再占玩法卡片或设置分区', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text(UiStrings.mainMenuResourceOverview), findsNothing);
    expect(find.text(UiStrings.mainMenuSettings), findsNothing);
    expect(find.text(UiStrings.mainMenuGroupSettings), findsNothing);
    expect(cornerTool(UiStrings.mainMenuResourceOverview), findsOneWidget);
    expect(cornerTool(UiStrings.mainMenuSettings), findsOneWidget);
    expect(cornerTool(UiStrings.mainMenuQuitTooltip), findsOneWidget);
  });

  testWidgets('资源角落工具仍进入既有 ResourceOverviewScreen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.tap(cornerTool(UiStrings.mainMenuResourceOverview));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ResourceOverviewScreen), findsOneWidget);
  });

  testWidgets('设置角落工具仍打开既有 SettingsPanel', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.tap(cornerTool(UiStrings.mainMenuSettings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(SettingsPanel), findsOneWidget);
  });

  for (final size in [
    const Size(900, 720),
    const Size(1280, 720),
    const Size(1440, 900),
  ]) {
    testWidgets('角落工具布局 ${size.width.toInt()}x${size.height.toInt()} 无异常', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app());
      await tester.pump();

      expect(cornerTool(UiStrings.mainMenuResourceOverview), findsOneWidget);
      expect(cornerTool(UiStrings.mainMenuSettings), findsOneWidget);
      expect(cornerTool(UiStrings.mainMenuQuitTooltip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
