import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/ui/main_menu.dart';
import 'package:wuxia_idle/ui/strings.dart';

/// T32 子提交 3b：[MainMenu] widget 测试（T42 加「问鼎九霄」T49 加「闭关修炼」后扩 8 个）。
///
/// 用例覆盖：
///   - 标题 mainMenuTitle 渲染
///   - 8 个菜单按钮 label + 顺序匹配（主线 / 问鼎九霄 / 闭关修炼 / Phase1 / Phase2 / 角色 / 装备 / 心法）
///   - 共 8 个 InkWell（按钮全部可点）
///   - Tap "Phase 1 战斗测试" → push BattleTestMenu
///   - Tap "Phase 2 调试场景" → push Phase2TestMenu
///
/// 主线 / 问鼎九霄 / 角色 / 装备 / 心法 按钮 push 的页面依赖 Isar，widget test 旁路
/// （与 T28/T31 同决策，沿用挂账 #23）；按钮可点性通过 InkWell 计数 + label
/// 渲染断言覆盖。
void main() {
  Widget app() => const ProviderScope(
        child: MaterialApp(home: MainMenu()),
      );

  testWidgets('标题渲染：mainMenuTitle 可见', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text(UiStrings.mainMenuTitle), findsOneWidget);
  });

  testWidgets('8 个菜单按钮 label 全部可见且顺序正确', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text(UiStrings.mainMenuMainline), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTower), findsOneWidget);
    expect(find.text(UiStrings.mainMenuSeclusion), findsOneWidget);
    expect(find.text(UiStrings.mainMenuPhase1), findsOneWidget);
    expect(find.text(UiStrings.mainMenuPhase2), findsOneWidget);
    expect(find.text(UiStrings.mainMenuCharacterPanel), findsOneWidget);
    expect(find.text(UiStrings.mainMenuInventory), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTechniques), findsOneWidget);

    // 顺序：主线 / 问鼎九霄 / 闭关修炼 / Phase1 / Phase2 / 角色 / 装备 / 心法
    final mainY = tester.getCenter(find.text(UiStrings.mainMenuMainline)).dy;
    final towY = tester.getCenter(find.text(UiStrings.mainMenuTower)).dy;
    final secY = tester.getCenter(find.text(UiStrings.mainMenuSeclusion)).dy;
    final p1Y = tester.getCenter(find.text(UiStrings.mainMenuPhase1)).dy;
    final p2Y = tester.getCenter(find.text(UiStrings.mainMenuPhase2)).dy;
    final chY = tester.getCenter(find.text(UiStrings.mainMenuCharacterPanel)).dy;
    final invY = tester.getCenter(find.text(UiStrings.mainMenuInventory)).dy;
    final tcY = tester.getCenter(find.text(UiStrings.mainMenuTechniques)).dy;
    expect(mainY < towY, isTrue);
    expect(towY < secY, isTrue);
    expect(secY < p1Y, isTrue);
    expect(p1Y < p2Y, isTrue);
    expect(p2Y < chY, isTrue);
    expect(chY < invY, isTrue);
    expect(invY < tcY, isTrue);
  });

  testWidgets('8 个菜单按钮均为 InkWell（可点）', (tester) async {
    await tester.pumpWidget(app());
    expect(find.byType(InkWell), findsNWidgets(8));
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
