import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// M6 心魔余毒战败损失摘要 banner widget 层守卫:
/// 验证 [buildDefeatLossBanner]（VISUAL_ROUTE defeat_inner_demon_residue 与本测
/// 共用入口）对心魔余毒 entry 渲染「余毒未消」段,对 Boss 散功 entry 不渲染。
void main() {
  Widget wrap(List<DefeatLossEntry> entries) => MaterialApp(
        home: Scaffold(body: buildDefeatLossBanner(entries)),
      );

  testWidgets('心魔余毒 entry(residueApplied=true)渲染「余毒未消」段', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(wrap(const [
      DefeatLossEntry(
        characterName: '测试甲',
        internalForceBefore: 1480,
        internalForceAfter: 1258,
        techniqueName: '伏魔禅功',
        residueApplied: true,
      ),
    ]));

    expect(
      find.textContaining(UiStrings.innerDemonResidueNote),
      findsOneWidget,
    );
    // 全余毒 → 上下文感知标题为「心魔反噬」，非「散功代价」。
    expect(find.text(UiStrings.defeatLossTitleInnerDemon), findsOneWidget);
    expect(find.text(UiStrings.defeatLossTitle), findsNothing);
  });

  testWidgets('Boss 散功 entry(residueApplied=false)不渲染余毒段', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(wrap(const [
      DefeatLossEntry(
        characterName: '测试乙',
        internalForceBefore: 2000,
        internalForceAfter: 1000,
        residueApplied: false,
      ),
    ]));

    expect(
      find.textContaining(UiStrings.innerDemonResidueNote),
      findsNothing,
    );
    // Boss 散功（非余毒）→ 标题为「散功代价」，非「心魔反噬」。
    expect(find.text(UiStrings.defeatLossTitle), findsOneWidget);
    expect(find.text(UiStrings.defeatLossTitleInnerDemon), findsNothing);
  });
}
