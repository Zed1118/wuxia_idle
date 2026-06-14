import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/selected_cycle_provider.dart';
import 'package:wuxia_idle/features/battle/presentation/cycle_select_control.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 周目按章选择控件测试(战斗交互重做 Phase 2,从 per-stage 上移到章层)。
///
/// provider override 喂态(避免 Isar writeTxn 在 testWidgets 内死锁,见 memory
/// feedback_isar_widget_test_deadlock)。验 glue:章级 clearedChapterCycleKeys →
/// 控件渲染 + 点击写 selectedChallengeCycleProvider(本控件只设状态,不进战斗)。
void main() {
  const chapterKey = 'ch1';

  /// 构造 MainlineProgress:给定该章已通的周目编号列表(写 chapterCycleKeys)。
  MainlineProgress progressWithCycles(List<int> clearedCycles) {
    final p = MainlineProgress()
      ..saveDataId = 1
      ..clearedChapterCycleKeys =
          clearedCycles.map((c) => '$chapterKey#$c').toList();
    return p;
  }

  ProviderContainer makeContainer({
    required MainlineProgress progress,
    required int maxCycle,
  }) {
    return ProviderContainer(
      overrides: [
        mainlineProgressProvider.overrideWith((ref) async => progress),
        numbersConfigProvider.overrideWithValue(
          _NumbersStub(maxCycleMainline: maxCycle),
        ),
      ],
    );
  }

  Widget host(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: Center(child: CycleSelectControl(chapterKey: chapterKey)),
        ),
      ),
    );
  }

  testWidgets('整章未通（highestCleared=0）→ 渲染空占位，无周目 UI', (tester) async {
    final c = makeContainer(progress: progressWithCycles([]), maxCycle: 3);
    addTearDown(c.dispose);
    await tester.pumpWidget(host(c));
    await tester.pumpAndSettle();
    expect(find.byType(CycleSelectControl), findsOneWidget);
    expect(find.text(UiStrings.cycleMaxReachedLabel), findsNothing);
    expect(find.text(UiStrings.cycleReplayCurrentSuffix), findsNothing);
    expect(find.text(UiStrings.cycleChallengeNextSuffix), findsNothing);
  });

  testWidgets('第1周目已通，maxCycle=3 → 显示第1周目标签 + 挑战第2周目选项', (tester) async {
    final c = makeContainer(progress: progressWithCycles([1]), maxCycle: 3);
    addTearDown(c.dispose);
    await tester.pumpWidget(host(c));
    await tester.pumpAndSettle();
    expect(find.textContaining(UiStrings.cycleNthLabel(1)), findsWidgets);
    expect(
      find.textContaining(UiStrings.cycleChallengeNextLabel(2)),
      findsOneWidget,
    );
    expect(find.text(UiStrings.cycleReplayCurrentSuffix), findsOneWidget);
  });

  testWidgets('第1周目已通 → 默认选中「回放第1周目」(highest)', (tester) async {
    final c = makeContainer(progress: progressWithCycles([1]), maxCycle: 3);
    addTearDown(c.dispose);
    await tester.pumpWidget(host(c));
    await tester.pumpAndSettle();
    // 默认选中态 = highest(=1),无显式选择 → provider 仍 null,resolve 时用 highest。
    expect(c.read(selectedChallengeCycleProvider(chapterKey)), isNull);
    // 选中态在「回放」按钮上显勾标。
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('点「挑战第2周目」→ 写 selectedChallengeCycleProvider=2', (tester) async {
    final c = makeContainer(progress: progressWithCycles([1]), maxCycle: 3);
    addTearDown(c.dispose);
    await tester.pumpWidget(host(c));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(UiStrings.cycleChallengeNextLabel(2)));
    await tester.pumpAndSettle();
    expect(c.read(selectedChallengeCycleProvider(chapterKey)), 2);
  });

  testWidgets('点「回放第1周目」→ 写 selectedChallengeCycleProvider=1', (tester) async {
    final c = makeContainer(progress: progressWithCycles([1]), maxCycle: 3);
    addTearDown(c.dispose);
    await tester.pumpWidget(host(c));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.cycleReplayCurrentSuffix));
    await tester.pumpAndSettle();
    expect(c.read(selectedChallengeCycleProvider(chapterKey)), 1);
  });

  testWidgets('第2周目已通，maxCycle=3 → 显示挑战第3周目', (tester) async {
    final c = makeContainer(progress: progressWithCycles([1, 2]), maxCycle: 3);
    addTearDown(c.dispose);
    await tester.pumpWidget(host(c));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(UiStrings.cycleChallengeNextLabel(3)),
      findsOneWidget,
    );
  });

  testWidgets('已达最高周目（highest=maxCycle=3）→ 显示已达最高, 无挑战选项', (tester) async {
    final c =
        makeContainer(progress: progressWithCycles([1, 2, 3]), maxCycle: 3);
    addTearDown(c.dispose);
    await tester.pumpWidget(host(c));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.cycleMaxReachedLabel), findsOneWidget);
    expect(find.textContaining('挑战'), findsNothing);
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
