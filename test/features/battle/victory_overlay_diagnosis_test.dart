import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/battle_diagnosis.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_overlay.dart';

void main() {
  const diagnosis = BattleDiagnosis(
    ruleId: 'killed_by_charge',
    primaryCause: '被 Boss 蓄力大招击溃',
    dataLines: ['致命一击：蓄力技 700', '内力余量：200/500'],
    suggestions: [
      DiagnosisSuggestion('保留内力、装配破招技。', DiagnosisJumpTarget.skills),
    ],
  );

  Future<void> pump(WidgetTester t, Widget child) async {
    await t.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('败北显诊断主因+数据+按钮', (t) async {
    DiagnosisJumpTarget? jumped;
    await pump(t, VictoryOverlay(
      result: BattleResult.rightWin,
      totalDamage: 100, critCount: 0, totalTicks: 50,
      diagnosis: diagnosis,
      onJump: (target) => jumped = target,
      onContinue: () {},
    ));
    expect(find.text('被 Boss 蓄力大招击溃'), findsOneWidget);
    expect(find.text('致命一击：蓄力技 700'), findsOneWidget);
    expect(find.text('内力余量：200/500'), findsOneWidget);
    expect(find.text('查看技能装配'), findsOneWidget);
    await t.tap(find.text('查看技能装配'));
    expect(jumped, DiagnosisJumpTarget.skills);
  });

  testWidgets('胜利不显诊断块', (t) async {
    await pump(t, VictoryOverlay(
      result: BattleResult.leftWin,
      totalDamage: 100, critCount: 0, totalTicks: 50,
      diagnosis: null,
      onContinue: () {},
    ));
    expect(find.text('被 Boss 蓄力大招击溃'), findsNothing);
  });

  testWidgets('jump==null 的建议只显文案不给按钮', (t) async {
    const noJump = BattleDiagnosis(
      ruleId: 'generic', primaryCause: '惜败',
      dataLines: ['总伤害：100', '总回合：50'],
      suggestions: [DiagnosisSuggestion('调整后再战。', null)],
    );
    await pump(t, VictoryOverlay(
      result: BattleResult.rightWin,
      totalDamage: 100, critCount: 0, totalTicks: 50,
      diagnosis: noJump,
      onContinue: () {},
    ));
    expect(find.text('调整后再战。'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
