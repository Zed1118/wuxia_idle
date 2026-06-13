import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/presentation/cycle_select_control.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// E1 周目选择控件测试。
///
/// provider override 喂态（避免 Isar writeTxn 在 testWidgets 内死锁，见 memory
/// feedback_isar_widget_test_deadlock）。只验 glue 读路径：provider → 控件渲染 +
/// onSelectCycle 回调。写路径（recordVictory cycleKey）由 service 层单测覆盖。
void main() {
  const stageId = 'stage_01_05';

  /// 构造 MainlineProgress：给定 stageId 已通的周目编号列表。
  MainlineProgress progressWithCycles(List<int> clearedCycles) {
    final p = MainlineProgress()
      ..saveDataId = 1
      ..clearedStageIds = clearedCycles.contains(1) ? [stageId] : []
      ..clearedAt = clearedCycles.contains(1) ? [DateTime(2026)] : []
      ..clearedStageCycleKeys =
          clearedCycles.map((c) => '$stageId#$c').toList();
    return p;
  }

  Widget host({
    required MainlineProgress progress,
    required int maxCycle,
    ValueChanged<int>? onSelectCycle,
  }) {
    return ProviderScope(
      overrides: [
        mainlineProgressProvider.overrideWith((ref) async => progress),
        numbersConfigProvider.overrideWithValue(
          _NumbersStub(maxCycleMainline: maxCycle),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: CycleSelectControl(
              stageId: stageId,
              onSelectCycle: onSelectCycle,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('未通关（highestCleared=0）→ 渲染空占位，无周目 UI', (tester) async {
    await tester.pumpWidget(host(
      progress: progressWithCycles([]),
      maxCycle: 3,
    ));
    await tester.pumpAndSettle();
    // 控件对未通关关卡不渲染任何周目内容
    expect(find.byType(CycleSelectControl), findsOneWidget);
    expect(find.text(UiStrings.cycleMaxReachedLabel), findsNothing);
    expect(find.text(UiStrings.cycleReplayCurrentSuffix), findsNothing);
    expect(find.text(UiStrings.cycleChallengeNextSuffix), findsNothing);
  });

  testWidgets('第1周目已通，maxCycle=3 → 显示第1周目标签 + 挑战第2周目选项', (tester) async {
    await tester.pumpWidget(host(
      progress: progressWithCycles([1]),
      maxCycle: 3,
    ));
    await tester.pumpAndSettle();
    // 显示当前周目编号标签（含「第1周目」子串）
    expect(
      find.textContaining(UiStrings.cycleNthLabel(1)),
      findsWidgets,
    );
    // 显示挑战下一周目
    expect(
      find.textContaining(UiStrings.cycleChallengeNextLabel(2)),
      findsOneWidget,
    );
    // 显示自动重演后缀
    expect(find.text(UiStrings.cycleReplayCurrentSuffix), findsOneWidget);
  });

  testWidgets('第1周目已通 → 点「挑战第2周目」触发 onSelectCycle(2)', (tester) async {
    int? selected;
    await tester.pumpWidget(host(
      progress: progressWithCycles([1]),
      maxCycle: 3,
      onSelectCycle: (c) => selected = c,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(UiStrings.cycleChallengeNextLabel(2)));
    await tester.pumpAndSettle();
    expect(selected, 2);
  });

  testWidgets('第1周目已通 → 点重演后缀按钮触发 onSelectCycle(1)', (tester) async {
    int? selected;
    await tester.pumpWidget(host(
      progress: progressWithCycles([1]),
      maxCycle: 3,
      onSelectCycle: (c) => selected = c,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.cycleReplayCurrentSuffix));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('第2周目已通，maxCycle=3 → 显示挑战第3周目', (tester) async {
    await tester.pumpWidget(host(
      progress: progressWithCycles([1, 2]),
      maxCycle: 3,
    ));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(UiStrings.cycleChallengeNextLabel(3)),
      findsOneWidget,
    );
  });

  testWidgets('已达最高周目（highestCleared=maxCycle=3）→ 显示已达最高, 无挑战选项', (tester) async {
    await tester.pumpWidget(host(
      progress: progressWithCycles([1, 2, 3]),
      maxCycle: 3,
    ));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.cycleMaxReachedLabel), findsOneWidget);
    // 无「挑战」文本
    expect(find.textContaining('挑战'), findsNothing);
  });

  testWidgets('已达最高周目 → 点重演触发 onSelectCycle(maxCycle)', (tester) async {
    int? selected;
    await tester.pumpWidget(host(
      progress: progressWithCycles([1, 2, 3]),
      maxCycle: 3,
      onSelectCycle: (c) => selected = c,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.cycleReplayCurrentSuffix));
    await tester.pumpAndSettle();
    expect(selected, 3);
  });
}

/// NumbersConfig stub：只实现 cycleEvolution，其他字段走 noSuchMethod。
class _NumbersStub implements NumbersConfig {
  const _NumbersStub({required int maxCycleMainline})
      : _maxCycle = maxCycleMainline;

  final int _maxCycle;

  @override
  CycleEvolutionConfig get cycleEvolution => CycleEvolutionConfig(
        maxCycleMainline: _maxCycle,
        maxCycleTower: 2,
        scalePerCycle: 0.0,
        defenseRateCap: 0.6,
        traits: const CycleTraitsConfig(
          yuti: YutiTraitParams(
              defenseRateBonusC2: 0.0, defenseRateBonusC3: 0.0),
          fanzhen: FanzhenTraitParams(damagePerTick: 0, ticks: 0),
          ningjia: NingjiaTraitParams(critDamageTakenMult: 1.0),
          zhenqi: ZhenqiTraitParams(internalForcePct: 0.0),
          shipo: ShipoTraitParams(chargeSkillId: ''),
        ),
        assignment: const {},
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      '_NumbersStub: 只实现 cycleEvolution, '
      'invoked=${invocation.memberName}');
}
