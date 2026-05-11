import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/ui/main_menu.dart';
import 'package:wuxia_idle/ui/strings.dart';

/// T32 子提交 3b：[MainMenu] widget 测试。
///
/// 5 用例覆盖：
///   - 标题 mainMenuTitle 渲染
///   - 5 个菜单按钮 label + 顺序匹配（Phase1 / Phase2 / 角色 / 装备 / 心法）
///   - 共 5 个 InkWell（按钮全部可点）
///   - Tap "Phase 1 战斗测试" → push BattleTestMenu（无 Isar 依赖，可直接 settle）
///   - Tap "Phase 2 调试场景" → push Phase2TestMenu（同上，AppBar 含 phase2MenuTitle）
///
/// 角色 / 装备 / 心法 3 个按钮 push 的页面依赖 Isar，widget test 旁路（与 T28/T31
/// 同决策，沿用挂账 #23）；按钮可点性通过 InkWell 计数 + label 渲染断言覆盖。
void main() {
  Widget app() => const ProviderScope(
        child: MaterialApp(home: MainMenu()),
      );

  testWidgets('标题渲染：mainMenuTitle 可见', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text(UiStrings.mainMenuTitle), findsOneWidget);
  });

  testWidgets('5 个菜单按钮 label 全部可见且顺序正确', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text(UiStrings.mainMenuPhase1), findsOneWidget);
    expect(find.text(UiStrings.mainMenuPhase2), findsOneWidget);
    expect(find.text(UiStrings.mainMenuCharacterPanel), findsOneWidget);
    expect(find.text(UiStrings.mainMenuInventory), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTechniques), findsOneWidget);

    // 顺序断言：按钮在屏幕上从上到下依次为 Phase1 / Phase2 / 角色 / 装备 / 心法
    final p1Y = tester.getCenter(find.text(UiStrings.mainMenuPhase1)).dy;
    final p2Y = tester.getCenter(find.text(UiStrings.mainMenuPhase2)).dy;
    final chY = tester.getCenter(find.text(UiStrings.mainMenuCharacterPanel)).dy;
    final invY = tester.getCenter(find.text(UiStrings.mainMenuInventory)).dy;
    final tcY = tester.getCenter(find.text(UiStrings.mainMenuTechniques)).dy;
    expect(p1Y < p2Y, isTrue);
    expect(p2Y < chY, isTrue);
    expect(chY < invY, isTrue);
    expect(invY < tcY, isTrue);
  });

  testWidgets('5 个菜单按钮均为 InkWell（可点）', (tester) async {
    await tester.pumpWidget(app());
    // _MenuButton 内每个用 1 个 InkWell；外层 MaterialApp 不引入 Scaffold drawer
    // 等其他 InkWell。预期恰好 5 个。
    expect(find.byType(InkWell), findsNWidgets(5));
  });

  testWidgets('tap Phase 1 战斗测试 → 进入 BattleTestMenu（找到 testMenuTitle / scenarioA）',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text(UiStrings.mainMenuPhase1));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.testMenuTitle), findsOneWidget);
    expect(find.text(UiStrings.scenarioA), findsOneWidget);
  });

  testWidgets('tap Phase 2 调试场景 → 进入 Phase2TestMenu（找到 scenarioP1 等 4 场景）',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text(UiStrings.mainMenuPhase2));
    await tester.pumpAndSettle();

    // Phase2TestMenu AppBar title 与 MainMenu 按钮 label 同字符串，
    // 用 4 场景按钮 label 区分（这些只在 Phase2TestMenu 出现）。
    expect(find.text(UiStrings.scenarioP1), findsOneWidget);
    expect(find.text(UiStrings.scenarioP2), findsOneWidget);
    expect(find.text(UiStrings.scenarioP3), findsOneWidget);
    expect(find.text(UiStrings.scenarioP4), findsOneWidget);
  });
}
