import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/meridian_bar.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/stage_progress_row.dart';

/// [StageProgressRow] 布局基元测试（D · 2026-06-12）。
///
/// 验证五要素全渲染、stageName==null 残页式退化、onTap、以及
/// 当前/下一阶/进度三段文案的各种组合。
void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 400, child: child),
        ),
      );

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(child));
  }

  testWidgets('五要素全渲染：标题/阶段名/进度条/当前效果/下一阶/标记',
      (tester) async {
    await pump(
      tester,
      const StageProgressRow(
        title: '青锋剑',
        stageName: '默契',
        ratio: 0.6,
        currentEffect: '伤害 +20%',
        nextEffect: '下一阶 +30%',
        progressText: '战斗 1840/2000',
        tag: '人剑合一',
      ),
    );

    expect(find.text('青锋剑'), findsOneWidget);
    expect(find.text('默契'), findsOneWidget);
    expect(find.byType(MeridianBar), findsOneWidget);
    expect(find.text('伤害 +20%'), findsOneWidget);
    expect(find.text('下一阶 +30%'), findsOneWidget);
    expect(find.text('战斗 1840/2000'), findsOneWidget);
    expect(find.text('人剑合一'), findsOneWidget);
  });

  testWidgets('stageName==null → 残页式退化：无阶段名，仍有标题+进度条',
      (tester) async {
    await pump(
      tester,
      const StageProgressRow(
        title: '裂石掌谱',
        ratio: 0.4,
        tag: '爬塔·第5层',
      ),
    );

    expect(find.text('裂石掌谱'), findsOneWidget);
    expect(find.byType(MeridianBar), findsOneWidget);
    // 来源文案以普通 tag 形式显示（非高亮徽标）
    expect(find.text('爬塔·第5层'), findsOneWidget);
    // 无效果行（currentEffect/nextEffect/progressText 全 null）
    expect(find.text('伤害 +20%'), findsNothing);
  });

  testWidgets('title==null（卡内子段）→ 阶段名领头，无重复实体名',
      (tester) async {
    await pump(
      tester,
      const StageProgressRow(
        stageName: '圆满',
        ratio: 0.7,
        currentEffect: '伤害 ×2.25',
        nextEffect: '下一阶 ×2.50',
      ),
    );

    // 阶段名作为领头标题显示
    expect(find.text('圆满'), findsOneWidget);
    expect(find.byType(MeridianBar), findsOneWidget);
    expect(find.text('伤害 ×2.25'), findsOneWidget);
    expect(find.text('下一阶 ×2.50'), findsOneWidget);
  });

  testWidgets('最高阶：nextEffect=已至极境（金字），无 progressText',
      (tester) async {
    await pump(
      tester,
      const StageProgressRow(
        title: '太祖长拳',
        stageName: '极境',
        ratio: 1.0,
        currentEffect: '伤害 ×3.00',
        nextEffect: '已至极境',
      ),
    );

    expect(find.text('极境'), findsOneWidget);
    expect(find.text('伤害 ×3.00'), findsOneWidget);
    expect(find.text('已至极境'), findsOneWidget);
  });

  testWidgets('高亮标记 tagHighlighted=true → 青底徽标', (tester) async {
    await pump(
      tester,
      const StageProgressRow(
        title: '裂掌',
        stageName: '顺手',
        ratio: 0.5,
        currentEffect: '+5%',
        progressText: '还需 50 次',
        tag: '已装配',
        tagHighlighted: true,
      ),
    );

    expect(find.text('已装配'), findsOneWidget);
    // 高亮徽标包在 Container 内
    final tagText = tester.widget<Text>(find.text('已装配'));
    expect(tagText.style?.color, isNotNull);
  });

  testWidgets('onTap 触发', (tester) async {
    var tapped = false;
    await pump(
      tester,
      StageProgressRow(
        title: '点我',
        ratio: 0.0,
        onTap: () => tapped = true,
      ),
    );

    await tester.tap(find.byType(StageProgressRow));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
