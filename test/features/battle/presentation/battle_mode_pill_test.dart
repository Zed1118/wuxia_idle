import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_header.dart';
import 'package:wuxia_idle/shared/theme/combat_typography.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('T1～T5 字阶集中且最小辅助字不低于9px', () {
    expect(
      const [
        BattleTypography.t1,
        BattleTypography.t2,
        BattleTypography.t3,
        BattleTypography.t4,
        BattleTypography.t5,
      ],
      const [24, 17, 14, 11, 9],
    );
    expect(BattleTypography.t5, greaterThanOrEqualTo(9));
    expect(BattleTypography.uiFallback, contains('Microsoft YaHei'));
    expect(BattleTypography.displayFallback, contains('SimSun'));
    expect(BattleTypography.tabularFigures, isNotEmpty);
  });

  testWidgets('纯自动模式说明托管轮转职责', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BattleModePill(allowPlayerIntervention: false)),
      ),
    );

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, UiStrings.battleAutoModeHint);
    expect(find.text('自动'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('battle_auto_mode')),
    );
    expect(semantics.label, UiStrings.battleAutoMode);
    expect(semantics.value, UiStrings.battleAutoMode);
    expect(semantics.hint, UiStrings.battleAutoModeHint);
  });

  testWidgets('可点选模式说明预支行动与重新回势代价', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BattleModePill(allowPlayerIntervention: true)),
      ),
    );

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, UiStrings.battleAutoInterventionHint);
    expect(find.text(UiStrings.battleAutoModeShort), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('battle_auto_mode')),
    );
    expect(semantics.label, UiStrings.battleAutoMode);
    expect(semantics.value, UiStrings.battleAutoIntervention);
    expect(semantics.hint, UiStrings.battleAutoInterventionHint);
  });

  testWidgets('顶栏控制使用无图标圆章且点击区不小于36', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleHeaderIconButton(
            icon: Icons.list_alt,
            label: UiStrings.battleLogShort,
            tooltip: UiStrings.battleLog,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('日志'), findsOneWidget);
    final size = tester.getSize(find.byType(BattleHeaderIconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(36));
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.style?.shape?.resolve({}), isA<StadiumBorder>());
    expect(button.tooltip, UiStrings.battleLog);
    expect(find.byIcon(Icons.list_alt), findsNothing);
  });

  testWidgets('顶栏圆章可 Tab 走到并由 Enter 激活', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleHeaderIconButton(
            icon: Icons.list_alt,
            label: UiStrings.battleLogShort,
            tooltip: UiStrings.battleLog,
            onPressed: () => pressed++,
          ),
        ),
      ),
    );

    final semantics = tester
        .getSemantics(find.byType(IconButton))
        .getSemanticsData();
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    // 弱断言「有东西拿到焦点」证明不了顶栏可达:焦点必须真落在圆章子树内。
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    expect(focusedContext, isNotNull);
    expect(
      focusedContext!.findAncestorWidgetOfExactType<BattleHeaderIconButton>(),
      isNotNull,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressed, 1);
  });

  testWidgets('顶栏圆章禁用时不吃键盘焦点', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BattleHeaderIconButton(
            icon: Icons.list_alt,
            label: UiStrings.battleLogShort,
            tooltip: UiStrings.battleLog,
            onPressed: null,
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final focusedContext = FocusManager.instance.primaryFocus?.context;
    expect(
      focusedContext?.findAncestorWidgetOfExactType<BattleHeaderIconButton>(),
      isNull,
    );
  });
}
