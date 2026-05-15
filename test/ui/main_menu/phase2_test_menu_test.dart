import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/ui/debug/phase2_test_menu.dart';
import 'package:wuxia_idle/ui/strings.dart';

/// T32 子提交 3d：[Phase2TestMenu] widget 测试（T54 扩到 5 按钮含 P5 师徒；
/// W12 fix 扩到 6 按钮含 VC W7-W11；W14-3 扩到 7 按钮含 VC14_3 奇遇 skill 视觉验收；
/// W15-r2 扩到 9 按钮含 VC15-r2 tier 5-7 装备入背包；
/// W15-resonance 扩到 10 按钮含 VC15-res 共鸣/强化/开锋光谱）。
///
/// 4 用例覆盖：
///   - 10 场景按钮 label + hint 全部可见且顺序正确
///     (P1 → P2 → P3 → P4 → P5 → VC → VC14_3 → VC-EVENT → VC15-r2 → VC15-res)
///   - AppBar 标题 phase2MenuTitle 可见
///   - 10 个 _ScenarioButton InkWell 可点
///   - tap P1 → seedP1 在 widget test 环境 IsarSetup 未 init → catch 后 SnackBar
///     显示「种子失败」（覆盖 _seedAndPush 完整 try/catch/finally 流程 + UI 反馈）
///
/// **测试旁路**：真正的 push 到 InventoryScreen / TechniquePanelScreen 不在
/// widget test 跑（这些页面依赖真 Isar，沿用挂账 #23 决策）。push 跳转目标的
/// 正确性已在 MainMenu test 中通过 tap Phase2 → 找到 scenarioP1 验证（即
/// Phase2TestMenu 路由可达）；按钮 onTap 内部的 seedAndPush 流程由本测覆盖。
void main() {
  Widget app() => const ProviderScope(
        child: MaterialApp(home: Phase2TestMenu()),
      );

  testWidgets('AppBar 标题 phase2MenuTitle 可见', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text(UiStrings.phase2MenuTitle), findsOneWidget);
  });

  testWidgets('10 场景按钮 label + hint 全部可见且顺序正确', (tester) async {
    // VC15-res 在 1280×720 默认 surface 下可能贴底,扩大测试 viewport 容纳 10 按钮。
    await tester.binding.setSurfaceSize(const Size(1280, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());

    // label
    expect(find.text(UiStrings.scenarioP1), findsOneWidget);
    expect(find.text(UiStrings.scenarioP2), findsOneWidget);
    expect(find.text(UiStrings.scenarioP3), findsOneWidget);
    expect(find.text(UiStrings.scenarioP4), findsOneWidget);
    expect(find.text(UiStrings.scenarioP5), findsOneWidget);
    expect(find.text(UiStrings.scenarioVc), findsOneWidget);
    expect(find.text(UiStrings.scenarioVc14_3), findsOneWidget);
    expect(find.text(UiStrings.scenarioVcEvent), findsOneWidget);
    expect(find.text(UiStrings.scenarioVc15R2), findsOneWidget);
    expect(find.text(UiStrings.scenarioVc15Resonance), findsOneWidget);

    // hint(10 段全部不重复,作为独立断言)
    expect(find.text(UiStrings.hintP1), findsOneWidget);
    expect(find.text(UiStrings.hintP2), findsOneWidget);
    expect(find.text(UiStrings.hintP3), findsOneWidget);
    expect(find.text(UiStrings.hintP4), findsOneWidget);
    expect(find.text(UiStrings.hintP5), findsOneWidget);
    expect(find.text(UiStrings.hintVc), findsOneWidget);
    expect(find.text(UiStrings.hintVc14_3), findsOneWidget);
    expect(find.text(UiStrings.hintVcEvent), findsOneWidget);
    expect(find.text(UiStrings.hintVc15R2), findsOneWidget);
    expect(find.text(UiStrings.hintVc15Resonance), findsOneWidget);

    // 顺序:从上到下 P1 → P2 → P3 → P4 → P5 → VC → VC14_3 → VC-EVENT → VC15-r2 → VC15-res
    final p1Y = tester.getCenter(find.text(UiStrings.scenarioP1)).dy;
    final p2Y = tester.getCenter(find.text(UiStrings.scenarioP2)).dy;
    final p3Y = tester.getCenter(find.text(UiStrings.scenarioP3)).dy;
    final p4Y = tester.getCenter(find.text(UiStrings.scenarioP4)).dy;
    final p5Y = tester.getCenter(find.text(UiStrings.scenarioP5)).dy;
    final vcY = tester.getCenter(find.text(UiStrings.scenarioVc)).dy;
    final vc14_3Y = tester.getCenter(find.text(UiStrings.scenarioVc14_3)).dy;
    final vcEventY = tester.getCenter(find.text(UiStrings.scenarioVcEvent)).dy;
    final vc15R2Y = tester.getCenter(find.text(UiStrings.scenarioVc15R2)).dy;
    final vc15ResY =
        tester.getCenter(find.text(UiStrings.scenarioVc15Resonance)).dy;
    expect(p1Y < p2Y, isTrue);
    expect(p2Y < p3Y, isTrue);
    expect(p3Y < p4Y, isTrue);
    expect(p4Y < p5Y, isTrue);
    expect(p5Y < vcY, isTrue);
    expect(vcY < vc14_3Y, isTrue);
    expect(vc14_3Y < vcEventY, isTrue);
    expect(vcEventY < vc15R2Y, isTrue);
    expect(vc15R2Y < vc15ResY, isTrue);
  });

  testWidgets('10 个场景按钮均为 InkWell(可点)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());
    // AppBar 默认 implyLeading 在 home 模式下不渲染 back button;10 个 _ScenarioButton
    // 各 1 个 InkWell,预期恰好 10 个。
    expect(find.byType(InkWell), findsNWidgets(10));
  });

  testWidgets('tap P1 → IsarSetup 未 init → SnackBar 显示「种子失败」',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text(UiStrings.scenarioP1));
    // 注意：不要 pumpAndSettle（SnackBar 动画无限循环；改用有限 pump + duration）。
    // 一次 pump 触发 onTap 启动 seedAndPush → seed throws → catch 调
    // ScaffoldMessenger.showSnackBar → 第二次 pump 完成 SnackBar 入场动画。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Phase2SeedService(isar: IsarSetup.instance).seedP1 走 IsarSetup.instance，widget test 环境未 init
    // → 抛 StateError；_seedAndPush catch 后 SnackBar 文案含「种子失败」前缀。
    expect(
      find.textContaining('种子失败'),
      findsOneWidget,
      reason: 'IsarSetup 未初始化时应弹错误 SnackBar，验证 _seedAndPush 兜底',
    );
  });
}
