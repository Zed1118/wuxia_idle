import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_floor_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// T42 TowerFloorListScreen widget 测试（不接真实 Isar）。
///
/// - towerProgressProvider / towerFloorListProvider 均 override 为 fixture
/// - 需要查看多层的测试使用 4000px 高视口，确保所有 30 行在视口内
///   （content ~1800px < 4000px → maxScrollExtent=0 → auto-scroll 无效）
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() {
    // _TowerBattleHost / StageAutoPlayControl 入口决策读 SharedPreferences
    // (per-stage override + 全局设置);无 mock 时 getInstance() 会 hang。
    SharedPreferences.setMockInitialValues({});
  });

  TowerProgress mkProgress({
    int highest = 0,
    int attempts = 0,
    int defeats = 0,
  }) {
    return TowerProgress()
      ..saveDataId = 1
      ..highestClearedFloor = highest
      ..highestClearedAt = highest > 0 ? DateTime(2026, 5, 11) : null
      ..totalAttempts = attempts
      ..totalDefeats = defeats
      ..createdAt = DateTime(2026, 5, 11);
  }

  List<TowerFloorEntry> mkFloorList(TowerProgress progress) {
    return TowerProgressService.floorList(
      progress: progress,
      allFloors: GameRepository.instance.towerFloors,
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required TowerProgress progress,
    Size surfaceSize = const Size(1024, 720),
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final entries = mkFloorList(progress);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          towerProgressProvider.overrideWith((ref) async => progress),
          towerFloorListProvider.overrideWith((ref) async => entries),
        ],
        child: const MaterialApp(home: TowerFloorListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('全新进度：顶部进度卡显示 0/30 + 第1层可挑战', (tester) async {
    final progress = mkProgress();
    await pumpScreen(tester, progress: progress);

    expect(find.text(UiStrings.towerProgressCleared(0)), findsOneWidget);
    expect(find.text(UiStrings.towerProgressAttempts(0)), findsOneWidget);
    expect(find.text(UiStrings.towerProgressDefeats(0)), findsOneWidget);
    expect(find.text(UiStrings.towerSpineTitle), findsOneWidget);
    expect(find.text(UiStrings.towerFloorLabel(1)), findsOneWidget);
    expect(find.text(UiStrings.towerFloorChallenge), findsOneWidget);
  });

  testWidgets('三态分布：已通 3 层 → cleared / available / locked 同时可见', (
    tester,
  ) async {
    final progress = mkProgress(highest: 3, attempts: 3);
    // 4000px 视口：30 行全部可见，auto-scroll 被 clamp 到 0
    await pumpScreen(
      tester,
      progress: progress,
      surfaceSize: const Size(1024, 4000),
    );

    // floor 1 cleared（check_circle）
    expect(find.text(UiStrings.towerFloorLabel(1)), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsWidgets);

    // floor 4 available（「挑战」chip）
    expect(find.text(UiStrings.towerFloorLabel(4)), findsOneWidget);
    expect(find.text(UiStrings.towerFloorChallenge), findsOneWidget);

    // floor 5 locked（锁图标 + 副标题）
    expect(find.text(UiStrings.towerFloorLabel(5)), findsOneWidget);
    expect(find.text(UiStrings.towerFloorLocked), findsWidgets);
  });

  testWidgets('Boss 层视觉差异：第5层（小 Boss）显示「小 Boss」chip', (tester) async {
    // highest=0：floor 1 available，floor 5 locked + minor boss
    final progress = mkProgress();
    // 720px 视口足够看到前 ~12 层（每层约 60px），floor5 在 ~300px 内
    await pumpScreen(tester, progress: progress);

    expect(find.text(UiStrings.towerBossMinor), findsOneWidget);
  });

  testWidgets('点 available 层 → 进入战斗准备（Isar 未初始化显示准备失败）', (tester) async {
    final progress = mkProgress();
    await pumpScreen(tester, progress: progress);

    await tester.tap(find.text(UiStrings.towerFloorLabel(1)));
    await tester.pumpAndSettle();

    expect(find.textContaining('战斗准备失败'), findsOneWidget);
  });

  testWidgets('点 locked 层 → 无响应（无 dialog / 无导航）', (tester) async {
    final progress = mkProgress(highest: 0);
    await pumpScreen(tester, progress: progress);

    await tester.tap(find.text(UiStrings.towerFloorLabel(2)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('战斗准备失败'), findsNothing);
  });

  testWidgets('整塔30层已通 → 扫荡按钮高亮且标签带周目「第 1 周目」', (tester) async {
    final progress = mkProgress(highest: 30, attempts: 30);
    await pumpScreen(tester, progress: progress);

    expect(find.text(UiStrings.sweepTowerButtonCycle(1)), findsOneWidget);
    expect(find.text(UiStrings.sweepLockedHintCycle(1)), findsNothing);
  });

  testWidgets('已通一周目、二周目整塔未通 → 扫荡按钮灰显 + 周目门槛提示(§5.7 灰掉不隐藏)',
      (tester) async {
    // 已通第1周目(maxClearedCycle=1)→ 推进到第2周目(currentCycleIndex=2,
    // highestClearedFloor 归 0)→ 灰显提示「第2周目需先手工通关」。
    final progress = mkProgress(highest: 0)
      ..maxClearedCycle = 1
      ..currentCycleIndex = 2;
    await pumpScreen(tester, progress: progress);

    expect(find.text(UiStrings.sweepLockedHintCycle(2)), findsOneWidget);
    expect(find.text(UiStrings.sweepTowerButtonCycle(2)), findsNothing);
  });

  testWidgets('全新塔(从未通关) → 扫荡按钮整块隐藏(不在全新塔堆砌锁定按钮)', (tester) async {
    final progress = mkProgress(highest: 0);
    await pumpScreen(tester, progress: progress);

    expect(find.text(UiStrings.sweepLockedHintCycle(1)), findsNothing);
    expect(find.text(UiStrings.sweepTowerButtonCycle(1)), findsNothing);
  });

  testWidgets('点 cleared 层 → 弹重打确认 dialog，确认后进入战斗准备', (tester) async {
    final progress = mkProgress(highest: 3, attempts: 3);
    // 4000px 确保 floor 1（cleared）可见
    await pumpScreen(
      tester,
      progress: progress,
      surfaceSize: const Size(1024, 4000),
    );

    await tester.tap(find.text(UiStrings.towerFloorLabel(1)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(UiStrings.towerReplayBody), findsOneWidget);

    await tester.tap(find.text(UiStrings.towerReplayConfirm));
    await tester.pumpAndSettle();

    expect(find.textContaining('战斗准备失败'), findsOneWidget);
  });
}
