import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/jianghu/domain/reputation.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// runStageFlow 展示/交互分支补强（试点 A 单 切片 3）。
///
/// 覆盖对象（stage_entry_flow.dart）：
///   - `_showStageRetryDialog`（L411-434）真实对话框路径：点「再战」pop(true)
///     回循环头重打；点「回去」pop(false) 收兵返回。
///   - Boss 战败损失 banner 链（L139-151）：bossDefeatPenalty 返回非空 entries
///     → lossBanner 生成 → invalidate → 传入战败剧情（L162-176 push 验）。
///   - `_applyBossKillReputation`（L1176-1197）：Boss 胜利 + factionId →
///     所属派系 -delta / 对立阵营 +rivalDelta 真 Isar 落库。
///
/// **FakeAsync 纪律**：前 3 测不 init Isar（全部 hook 走 instanceOrNull==null
/// 早返，与既有 stage_entry_flow_test 同前提）；声望测的真 Isar 交互与流程
/// 触发全部收进 `tester.runAsync`（真时钟区），完成信号用纯 bool 轮询。
void main() {
  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  // ── fixtures ─────────────────────────────────────────────────────────────

  StageDef normalStage() => const StageDef(
    id: 'stage_branch_normal',
    name: '测试普通关',
    stageType: StageType.mainline,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: [],
    isBossStage: false,
    baseExpReward: 0,
    difficultyMultiplier: 1.0,
  );

  StageDef bossStage({String? factionId, String? defeatId}) => StageDef(
    id: 'stage_branch_boss',
    name: '测试 Boss 关',
    stageType: StageType.mainline,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: const [],
    isBossStage: true,
    baseExpReward: 0,
    difficultyMultiplier: 1.0,
    factionId: factionId,
    narrativeDefeatId: defeatId,
  );

  // ── tests ────────────────────────────────────────────────────────────────

  testWidgets('普通关战败 → 真实重试对话框点「再战」→ 重打第二场胜利(L411-434)', (tester) async {
    var battleCount = 0;
    final harness = _FlowHarness(
      stage: normalStage(),
      battleOutcome: () async {
        battleCount++;
        return battleCount == 1
            ? (won: false, surrendered: false)
            : (won: true, surrendered: false);
      },
      // 不注入 stageRetryDeciderForTest → 走真实 _showStageRetryDialog。
      passRetryDecider: false,
    );
    await tester.pumpWidget(harness.build());
    await tester.pump();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    // 真实重试对话框弹出:标题 + 两动作按钮
    expect(find.text(UiStrings.stageRetryTitle), findsOneWidget);
    expect(find.text(UiStrings.stageRetryAction), findsOneWidget);
    expect(find.text(UiStrings.stageRetryBackAction), findsOneWidget);

    await tester.tap(find.text(UiStrings.stageRetryAction));
    await tester.pumpAndSettle();

    expect(battleCount, 2, reason: '再战回循环头重打本场');
    expect(harness.recordedStageId, 'stage_branch_normal', reason: '第二场胜利记录');
    expect(harness.completed, isTrue);
    expect(harness.error, isNull);
  });

  testWidgets('普通关战败 → 对话框点「回去」→ 不重打直接返回(pop false)', (tester) async {
    var battleCount = 0;
    final harness = _FlowHarness(
      stage: normalStage(),
      battleOutcome: () async {
        battleCount++;
        return (won: false, surrendered: false);
      },
      passRetryDecider: false,
    );
    await tester.pumpWidget(harness.build());
    await tester.pump();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.stageRetryTitle), findsOneWidget);

    await tester.tap(find.text(UiStrings.stageRetryBackAction));
    await tester.pumpAndSettle();

    expect(battleCount, 1, reason: '回去不重打');
    expect(harness.recordedStageId, isNull, reason: '战败放弃不记进度');
    expect(harness.completed, isTrue, reason: '流程收兵返回而非卡死');
    expect(harness.error, isNull);
  });

  testWidgets('Boss 战败 + 损失 entries 非空 → 战败剧情 push 带 banner(L139-176)', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();
    StageDef? penaltyStage;
    final harness = _FlowHarness(
      stage: bossStage(defeatId: 'stage_01_05_defeat'),
      battleOutcome: () async => (won: false, surrendered: false),
      bossDefeatPenalty: (stage) async {
        penaltyStage = stage;
        return const [
          DefeatLossEntry(
            characterName: '测试甲',
            internalForceBefore: 3000,
            internalForceAfter: 1500,
            techniqueName: '伏魔禅功',
            oldLayerLabel: '大成',
            newLayerLabel: '小成',
            layersRolledBack: 2,
          ),
        ];
      },
      navigatorObservers: [observer],
    );
    await tester.pumpWidget(harness.build());
    await tester.pump();
    final baseline = observer.pushedRoutes.length;

    await tester.tap(find.text('start'));
    // 不 settle:NarrativeReaderScreen 内部异步易死锁,只验 push 被触发
    // (对齐既有 stage_entry_flow_test 的 victory narrative 测法)。
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(penaltyStage?.id, 'stage_branch_boss', reason: '散功结算以本关调用');
    expect(
      observer.pushedRoutes.length,
      greaterThan(baseline),
      reason: 'narrativeDefeatId 非空 → 战败剧情 MaterialPageRoute 已 push',
    );
    expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
    expect(harness.error, isNull);
  });

  testWidgets(
    'Boss 胜利 + factionId → 派系 -delta / 对立阵营 +rivalDelta(L1176-1197)',
    (tester) async {
      Directory? tempDir;
      final harness = _FlowHarness(
        stage: bossStage(factionId: 'shaolin'),
        battleOutcome: () async => (won: true, surrendered: false),
      );
      await tester.pumpWidget(harness.build());
      await tester.pump();

      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('wuxia_rep_test_');
        await IsarSetup.init(directory: tempDir, inspector: false);
        try {
          await tester.tap(find.text('start'));
          // 流程链在 runAsync 真时钟区推进;完成信号走纯 bool(无帧可查)。
          for (var i = 0; i < 300 && !harness.completed; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          expect(harness.completed, isTrue, reason: 'runStageFlow 胜利链应完成');
          expect(harness.error, isNull);

          final reps = await IsarSetup.instance.reputations.where().findAll();
          final triggers = GameRepository.instance.numbers.jianghu.triggers;
          Reputation? of(String fid) {
            for (final r in reps) {
              if (r.factionId == fid) return r;
            }
            return null;
          }

          final shaolin = of('shaolin');
          expect(shaolin, isNotNull, reason: 'Boss 所属派系应记一条声望');
          expect(
            shaolin!.value,
            -triggers.stageBossKillDelta,
            reason: '所属派系 -stageBossKillDelta',
          );
          // shaolin=orthodox → 对立 evil 阵营 jiaoMen / cijianzhuang 各 +rivalDelta
          for (final rival in ['jiaoMen', 'cijianzhuang']) {
            final r = of(rival);
            expect(r, isNotNull, reason: '对立阵营 $rival 应记一条声望');
            expect(r!.value, triggers.stageBossKillRivalDelta);
          }
          // 中立派系 luLin 不应被动到
          expect(of('luLin'), isNull, reason: '中立派系不进对立阵营名单');
        } finally {
          if (Isar.getInstance('wuxia_save_slot1') != null) {
            await IsarSetup.close();
          }
          IsarSetup.resetForTest();
          if (tempDir != null && await tempDir!.exists()) {
            await tempDir!.delete(recursive: true);
          }
        }
      });
    },
  );
}

/// 流程触发 harness:与既有 stage_entry_flow_test 的 _HarnessPage 同体例,
/// 额外暴露 battleCount / recordedStageId / completed / error 纯字段供断言,
/// 且允许「不注入 stageRetryDeciderForTest」走真实重试对话框。
class _FlowHarness {
  _FlowHarness({
    required this.stage,
    required this.battleOutcome,
    this.passRetryDecider = true,
    this.bossDefeatPenalty,
    this.navigatorObservers = const [],
  });

  final StageDef stage;
  final Future<({bool won, bool surrendered})> Function() battleOutcome;
  final bool passRetryDecider;
  final Future<List<DefeatLossEntry>> Function(StageDef stage)?
  bossDefeatPenalty;
  final List<NavigatorObserver> navigatorObservers;

  String? recordedStageId;
  var completed = false;
  String? error;

  Widget build() {
    return ProviderScope(
      child: MaterialApp(
        navigatorObservers: navigatorObservers,
        home: _HarnessPage(this),
      ),
    );
  }
}

class _HarnessPage extends ConsumerStatefulWidget {
  const _HarnessPage(this.harness);
  final _FlowHarness harness;

  @override
  ConsumerState<_HarnessPage> createState() => _HarnessPageState();
}

class _HarnessPageState extends ConsumerState<_HarnessPage> {
  String _status = 'idle';

  @override
  Widget build(BuildContext context) {
    final h = widget.harness;
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
                  stage: h.stage,
                  battleOutcomeForTest: h.battleOutcome,
                  stageRetryDeciderForTest: h.passRetryDecider
                      ? (() async => false)
                      : null,
                  victoryRecorderForTest: (stageId) async {
                    h.recordedStageId = stageId;
                  },
                  bossDefeatPenaltyForTest:
                      h.bossDefeatPenalty ??
                      ((_) async => const <DefeatLossEntry>[]),
                );
                h.completed = true;
                if (mounted) setState(() => _status = 'done');
              } catch (e) {
                h.error = e.toString();
                h.completed = true;
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

/// 记录 Navigator.push 调用的 observer(对齐既有 _RecordingNavigatorObserver)。
class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}
