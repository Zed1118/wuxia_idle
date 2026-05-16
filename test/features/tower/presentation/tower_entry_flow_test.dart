import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_entry_flow.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// T43 runTowerFlow widget 测试（@visibleForTesting DI 注入）。
///
/// 全部测试走 battleRunnerForTest / clearRecorderForTest / defeatRecorderForTest
/// 三路 DI；不接真实 Isar，不接真实战斗引擎。
///
/// 测试层 fixture 均用空 enemyTeam + null narrativeId，
/// 确保 StageBattleSetup / NarrativeLoader 完全绕过。
void main() {
  // ── fixtures ─────────────────────────────────────────────────────────────

  const normalFloor = TowerFloorDef(
    floorIndex: 1,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: [],
  );

  const bossFloor = TowerFloorDef(
    floorIndex: 5,
    requiredRealm: RealmTier.xueTu,
    enemyTeam: [],
    bossKind: TowerBossKind.minor,
    // narrativeOpeningId / narrativeVictoryId null → narrative 阶段全跳过
  );

  TowerProgress mkProgress({int highest = 0}) => TowerProgress()
    ..saveDataId = 1
    ..highestClearedFloor = highest
    ..totalAttempts = 0
    ..totalDefeats = 0
    ..createdAt = DateTime(2026, 5, 11);

  Widget harness({
    required TowerFloorDef floor,
    required Future<bool> Function() battleRunner,
    required Future<TowerClearResult> Function(int floorIndex) clearRecorder,
    required Future<void> Function() defeatRecorder,
    TowerProgress? progress,
  }) {
    final prog = progress ?? mkProgress();
    return ProviderScope(
      overrides: [
        towerProgressProvider.overrideWith((ref) async => prog),
      ],
      child: MaterialApp(
        home: _HarnessPage(
          floor: floor,
          battleRunner: battleRunner,
          clearRecorder: clearRecorder,
          defeatRecorder: defeatRecorder,
        ),
      ),
    );
  }

  // ── tests ─────────────────────────────────────────────────────────────────

  testWidgets('普通层胜利 → clearRecorder 以正确 floorIndex 被调用', (tester) async {
    int? recordedFloor;

    await tester.pumpWidget(harness(
      floor: normalFloor,
      battleRunner: () async => true,
      clearRecorder: (floorIndex) async {
        recordedFloor = floorIndex;
        return (isFirstClear: true, highestAfter: floorIndex);
      },
      defeatRecorder: () async {},
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    // 胜利 dialog 出现 → 确认
    expect(find.text(UiStrings.towerVictoryConfirm), findsOneWidget);
    await tester.tap(find.text(UiStrings.towerVictoryConfirm));
    await tester.pumpAndSettle();

    expect(recordedFloor, equals(normalFloor.floorIndex));
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('普通层失败 → defeatRecorder 被调用，clearRecorder 不被调用', (tester) async {
    bool defeatCalled = false;
    bool clearCalled = false;

    await tester.pumpWidget(harness(
      floor: normalFloor,
      battleRunner: () async => false,
      clearRecorder: (floorIndex) async {
        clearCalled = true;
        return (isFirstClear: false, highestAfter: 0);
      },
      defeatRecorder: () async {
        defeatCalled = true;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    expect(defeatCalled, isTrue);
    expect(clearCalled, isFalse);
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('首通（isFirstClear: true）→ 流程正常完成不报错', (tester) async {
    await tester.pumpWidget(harness(
      floor: normalFloor,
      battleRunner: () async => true,
      clearRecorder: (floorIndex) async =>
          (isFirstClear: true, highestAfter: floorIndex),
      defeatRecorder: () async {},
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    // 胜利 dialog（首通）→ 确认
    await tester.tap(find.text(UiStrings.towerVictoryConfirm));
    await tester.pumpAndSettle();

    expect(find.text('done'), findsOneWidget);
    expect(find.textContaining('error'), findsNothing);
  });

  testWidgets('重打（isFirstClear: false）→ 流程同样正常完成', (tester) async {
    await tester.pumpWidget(harness(
      floor: normalFloor,
      battleRunner: () async => true,
      clearRecorder: (floorIndex) async =>
          (isFirstClear: false, highestAfter: normalFloor.floorIndex),
      defeatRecorder: () async {},
      progress: mkProgress(highest: normalFloor.floorIndex),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    // 胜利 dialog（重打）→ 确认
    await tester.tap(find.text(UiStrings.towerVictoryConfirm));
    await tester.pumpAndSettle();

    expect(find.text('done'), findsOneWidget);
    expect(find.textContaining('error'), findsNothing);
  });

  testWidgets('Boss 层（无 narrative）胜利 → clearRecorder 以 Boss floorIndex 被调用',
      (tester) async {
    int? recordedFloor;

    await tester.pumpWidget(harness(
      floor: bossFloor,
      battleRunner: () async => true,
      clearRecorder: (floorIndex) async {
        recordedFloor = floorIndex;
        return (isFirstClear: true, highestAfter: floorIndex);
      },
      defeatRecorder: () async {},
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    // 胜利 dialog（Boss 层首通）→ 确认
    await tester.tap(find.text(UiStrings.towerVictoryConfirm));
    await tester.pumpAndSettle();

    expect(recordedFloor, equals(bossFloor.floorIndex));
    expect(find.text('done'), findsOneWidget);
  });
}

/// runTowerFlow 触发宿主。
///
/// 按钮 "start" 触发流程；完成后显示 "done"；异常时显示 "error: $e"。
class _HarnessPage extends ConsumerStatefulWidget {
  const _HarnessPage({
    required this.floor,
    required this.battleRunner,
    required this.clearRecorder,
    required this.defeatRecorder,
  });

  final TowerFloorDef floor;
  final Future<bool> Function() battleRunner;
  final Future<TowerClearResult> Function(int floorIndex) clearRecorder;
  final Future<void> Function() defeatRecorder;

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
                await runTowerFlow(
                  context: context,
                  ref: ref,
                  floor: widget.floor,
                  battleRunnerForTest: widget.battleRunner,
                  clearRecorderForTest: widget.clearRecorder,
                  defeatRecorderForTest: widget.defeatRecorder,
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
