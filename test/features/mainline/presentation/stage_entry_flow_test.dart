import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';

/// W17 #F · runStageFlow widget integration 测试（@visibleForTesting DI 注入）。
///
/// 设计对齐 `test/features/tower/presentation/tower_entry_flow_test.dart`:
/// 全部测试走 battleRunnerForTest / victoryRecorderForTest /
/// bossDefeatPenaltyForTest 三路 DI;不接真实 Isar,不接真实战斗引擎。
///
/// 测试层 fixture 均用空 enemyTeam(encounter hook 早返)+ null narrativeId
/// (NarrativeLoader / NarrativeReaderScreen 全跳过)。case 5 用真实
/// narrativeVictoryId + [_RecordingNavigatorObserver] 验 push 触发(对齐
/// `docs/handoff/wuxia_navigator_observer_mock_pattern_2026-05-17.md`)。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ── fixtures ─────────────────────────────────────────────────────────────

  StageDef normalStage({
    String? openingId,
    String? victoryId,
    String? defeatId,
  }) =>
      StageDef(
        id: 'stage_test_normal',
        name: '测试普通关',
        stageType: StageType.mainline,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: const [],
        isBossStage: false,
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
        narrativeOpeningId: openingId,
        narrativeVictoryId: victoryId,
        narrativeDefeatId: defeatId,
      );

  StageDef bossStage({
    String? openingId,
    String? victoryId,
    String? defeatId,
  }) =>
      StageDef(
        id: 'stage_test_boss',
        name: '测试 Boss 关',
        stageType: StageType.mainline,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: const [],
        isBossStage: true,
        baseExpReward: 0,
        difficultyMultiplier: 1.0,
        narrativeOpeningId: openingId,
        narrativeVictoryId: victoryId,
        narrativeDefeatId: defeatId,
      );

  Widget harness({
    required StageDef stage,
    required Future<bool> Function() battleRunner,
    Future<({bool won, bool surrendered})> Function()? battleOutcome,
    Future<bool> Function()? stageRetryDecider,
    Future<void> Function(String stageId)? victoryRecorder,
    Future<List<DefeatLossEntry>> Function(StageDef stage)? bossDefeatPenalty,
    List<NavigatorObserver> navigatorObservers = const [],
  }) {
    return ProviderScope(
      child: MaterialApp(
        navigatorObservers: navigatorObservers,
        home: _HarnessPage(
          stage: stage,
          battleRunner: battleRunner,
          battleOutcome: battleOutcome,
          // 默认不重试,避免普通关战败测试卡在真实重试对话框。
          stageRetryDecider: stageRetryDecider ?? (() async => false),
          victoryRecorder: victoryRecorder ?? (_) async {},
          bossDefeatPenalty:
              bossDefeatPenalty ?? ((_) async => const <DefeatLossEntry>[]),
        ),
      ),
    );
  }

  // ── tests ────────────────────────────────────────────────────────────────

  testWidgets('普通关胜利 → victoryRecorder 以正确 stageId 被调用', (tester) async {
    String? recordedStageId;

    await tester.pumpWidget(harness(
      stage: normalStage(),
      battleRunner: () async => true,
      victoryRecorder: (stageId) async {
        recordedStageId = stageId;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(recordedStageId, equals('stage_test_normal'));
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('普通关失败 → victoryRecorder / bossDefeatPenalty 均不调',
      (tester) async {
    bool victoryCalled = false;
    bool defeatCalled = false;

    await tester.pumpWidget(harness(
      stage: normalStage(),
      battleRunner: () async => false,
      victoryRecorder: (_) async {
        victoryCalled = true;
      },
      bossDefeatPenalty: (_) async {
        defeatCalled = true;
        return const [];
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(victoryCalled, isFalse, reason: '普通关失败不走 victory 链');
    expect(defeatCalled, isFalse,
        reason: '普通关非 Boss,_applyBossDefeatPenalty 不调(免费试错)');
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('Boss 关胜利 → victoryRecorder 以 Boss stageId 被调用', (tester) async {
    String? recordedStageId;

    await tester.pumpWidget(harness(
      stage: bossStage(),
      battleRunner: () async => true,
      victoryRecorder: (stageId) async {
        recordedStageId = stageId;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(recordedStageId, equals('stage_test_boss'));
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('Boss 关失败 → bossDefeatPenalty 以 stage 调用,victoryRecorder 不调',
      (tester) async {
    bool victoryCalled = false;
    StageDef? penaltyStage;

    await tester.pumpWidget(harness(
      stage: bossStage(),
      battleRunner: () async => false,
      victoryRecorder: (_) async {
        victoryCalled = true;
      },
      bossDefeatPenalty: (stage) async {
        penaltyStage = stage;
        return const [];
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(victoryCalled, isFalse);
    expect(penaltyStage?.id, equals('stage_test_boss'));
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('Boss 关投降 → victoryRecorder / bossDefeatPenalty 均不调(主动放弃无惩罚)',
      (tester) async {
    bool victoryCalled = false;
    bool penaltyCalled = false;

    await tester.pumpWidget(harness(
      stage: bossStage(),
      battleRunner: () async => false,
      battleOutcome: () async => (won: false, surrendered: true),
      victoryRecorder: (_) async {
        victoryCalled = true;
      },
      bossDefeatPenalty: (_) async {
        penaltyCalled = true;
        return const [];
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(victoryCalled, isFalse, reason: '投降不记胜利');
    expect(penaltyCalled, isFalse, reason: '投降跳过 Boss 散功(主动放弃无惩罚)');
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('普通关战败 → 选「再战」重打 → 第二场胜利记录(M3)', (tester) async {
    var battleCount = 0;
    String? recordedStageId;

    await tester.pumpWidget(harness(
      stage: normalStage(),
      battleRunner: () async => false, // 未用(battleOutcome 覆盖)
      battleOutcome: () async {
        battleCount++;
        // 第一场败 → 重试 → 第二场胜。
        return battleCount == 1
            ? (won: false, surrendered: false)
            : (won: true, surrendered: false);
      },
      stageRetryDecider: () async => true, // 选「再战」
      victoryRecorder: (stageId) async {
        recordedStageId = stageId;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(battleCount, 2, reason: '战败一场 + 重试一场');
    expect(recordedStageId, equals('stage_test_normal'), reason: '第二场胜利记录进度');
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets(
      '胜利 + narrativeVictoryId → 触发 victory narrative push '
      '(NavigatorObserver 验,不 settle 子屏)', (tester) async {
    // W17 #31 NavigatorObserver mock 套路:不 settle 子屏避免 NarrativeReaderScreen
    // 内部异步死锁,只验 Navigator.push 本身被触发。
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(harness(
      stage: normalStage(victoryId: 'stage_01_01_victory'),
      battleRunner: () async => true,
      navigatorObservers: [observer],
    ));
    await tester.pump();

    // baseline:initial HarnessPage push 已记录
    final baseline = observer.pushedRoutes.length;

    await tester.tap(find.text('start'));
    // 单帧推进 runStageFlow:battle mock + recordVictory mock +
    // applyVictoryResolution 因 IsarSetup 未 init 返 null(跳过 dialog)+
    // NarrativeLoader.load(真实 asset)+ push narrative 子屏。
    // 多帧 pump 让 NarrativeLoader async 完成,不 settle 避免子屏 CPI 死锁。
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      observer.pushedRoutes.length,
      greaterThan(baseline),
      reason: 'victory narrative MaterialPageRoute 应已 push',
    );
    expect(
      observer.pushedRoutes.last,
      isA<MaterialPageRoute<void>>(),
    );
  });
}

/// runStageFlow 触发宿主(对齐 tower_entry_flow_test 的 _HarnessPage)。
///
/// 按钮 "start" 触发流程;完成后显示 "done";异常时显示 "error: $e"。
class _HarnessPage extends ConsumerStatefulWidget {
  const _HarnessPage({
    required this.stage,
    required this.battleRunner,
    required this.battleOutcome,
    required this.stageRetryDecider,
    required this.victoryRecorder,
    required this.bossDefeatPenalty,
  });

  final StageDef stage;
  final Future<bool> Function() battleRunner;
  final Future<({bool won, bool surrendered})> Function()? battleOutcome;
  final Future<bool> Function() stageRetryDecider;
  final Future<void> Function(String stageId) victoryRecorder;
  final Future<List<DefeatLossEntry>> Function(StageDef stage)
      bossDefeatPenalty;

  @override
  ConsumerState<_HarnessPage> createState() => _HarnessPageState();
}

class _HarnessPageState extends ConsumerState<_HarnessPage> {
  String _status = 'idle';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_status),
          TextButton(
            onPressed: () async {
              setState(() => _status = 'running');
              try {
                await runStageFlow(
                  context: context,
                  ref: ref,
                  stage: widget.stage,
                  battleRunnerForTest: widget.battleRunner,
                  battleOutcomeForTest: widget.battleOutcome,
                  stageRetryDeciderForTest: widget.stageRetryDecider,
                  victoryRecorderForTest: widget.victoryRecorder,
                  bossDefeatPenaltyForTest: widget.bossDefeatPenalty,
                );
                if (mounted) setState(() => _status = 'done');
              } catch (e) {
                if (mounted) setState(() => _status = 'error: $e');
              }
            },
            child: const Text('start'),
          ),
        ],
      ),
    );
  }
}

/// 记录 Navigator.push 调用的 observer(W17 #31 销账套路)。
/// 见 docs/handoff/wuxia_navigator_observer_mock_pattern_2026-05-17.md。
class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}
