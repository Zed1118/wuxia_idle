import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// M6 心魔内息紊乱战败摘要 banner widget 层守卫:
/// 验证 [buildDefeatLossBanner] 对心魔 entry 仅渲染角色名与
/// 内息紊乱，对 Boss 散功 entry 继续渲染旧损失段。
void main() {
  Widget wrap(List<DefeatLossEntry> entries) =>
      MaterialApp(home: Scaffold(body: buildDefeatLossBanner(entries)));

  for (final size in const [Size(1280, 720), Size(1440, 900)]) {
    testWidgets('心魔 entry 仅渲染角色名与内息紊乱 '
        '${size.width.toInt()}×${size.height.toInt()} smoke', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(const [
          DefeatLossEntry(
            characterName: '测试甲',
            internalForceBefore: 1480,
            internalForceAfter: 1258,
            techniqueName: '伏魔禅功',
            residueApplied: true,
          ),
        ]),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('测试甲  ·  ${UiStrings.innerDemonResidueNote}'),
        findsOneWidget,
      );
      expect(
        find.textContaining(UiStrings.defeatInternalForceSegment(1480, 1258)),
        findsNothing,
      );
      expect(
        find.textContaining(UiStrings.defeatTechniqueProgressSegment('伏魔禅功')),
        findsNothing,
      );
      expect(
        find.textContaining(
          UiStrings.defeatTechniqueLayerSegment('伏魔禅功', null, null, 0),
        ),
        findsNothing,
      );
      // 全余毒 → 上下文感知标题为「心魔反噬」，非「散功代价」。
      expect(find.text(UiStrings.defeatLossTitleInnerDemon), findsOneWidget);
      expect(find.text(UiStrings.defeatLossTitle), findsNothing);
    });
  }

  testWidgets('Boss 散功 entry(residueApplied=false)不渲染余毒段', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(const [
        DefeatLossEntry(
          characterName: '测试乙',
          internalForceBefore: 2000,
          internalForceAfter: 1000,
          residueApplied: false,
        ),
      ]),
    );

    expect(find.textContaining(UiStrings.innerDemonResidueNote), findsNothing);
    // Boss 散功（非余毒）→ 标题为「散功代价」，非「心魔反噬」。
    expect(find.text(UiStrings.defeatLossTitle), findsOneWidget);
    expect(find.text(UiStrings.defeatLossTitleInnerDemon), findsNothing);
  });
}
