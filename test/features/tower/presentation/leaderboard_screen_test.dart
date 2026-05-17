import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/leaderboard_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// P0.2 #40 Phase 4 LeaderboardScreen widget test。
///
/// 全部走 [towerProgressProvider] override 注入 fake TowerProgress;
/// 不接真 Isar(对齐 tower_entry_flow_test 体例 line 53)。
void main() {
  TowerProgress mkProgress({
    int highest = 0,
    int? bestClearTimeMs,
    int totalAttempts = 0,
    int totalDefeats = 0,
    List<int>? perFloorClearTimes,
  }) {
    return TowerProgress()
      ..saveDataId = 1
      ..highestClearedFloor = highest
      ..highestClearedAt = highest > 0 ? DateTime(2026, 5, 17) : null
      ..totalAttempts = totalAttempts
      ..totalDefeats = totalDefeats
      ..createdAt = DateTime(2026, 5, 11)
      ..perFloorClearTimes = perFloorClearTimes ?? const []
      ..bestClearTime = bestClearTimeMs
      ..lastClearedAt = highest > 0 ? DateTime(2026, 5, 17) : null;
  }

  Widget app(TowerProgress p) {
    return ProviderScope(
      overrides: [
        towerProgressProvider.overrideWith((ref) async => p),
      ],
      child: const MaterialApp(home: LeaderboardScreen()),
    );
  }

  testWidgets('空态(highest=0)显示「尚未通关任何爬塔层」', (tester) async {
    await tester.pumpWidget(app(mkProgress()));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.leaderboardEmpty), findsOneWidget);
    expect(find.text(UiStrings.leaderboardHighestLayer), findsNothing,
        reason: '空态不显 3 指标 tile');
  });

  testWidgets('通 5 层 + 3 指标全显(highestFloor/bestClearTime/totalAttempts)', (tester) async {
    await tester.pumpWidget(app(mkProgress(
      highest: 5,
      bestClearTimeMs: 12000, // 12 秒
      totalAttempts: 8,
      perFloorClearTimes: const [15000, 18000, 12000, 14000, 20000],
    )));
    await tester.pumpAndSettle();
    expect(find.text('5 ${UiStrings.leaderboardLayerSuffix}'), findsOneWidget,
        reason: 'highestClearedFloor=5 显「5 层」');
    expect(find.text(UiStrings.leaderboardBestClearTime), findsOneWidget);
    expect(find.text('12 秒'), findsOneWidget,
        reason: 'bestClearTimeMs=12000 → 12 秒(< 60s 走 seconds 格式)');
    expect(find.text(UiStrings.leaderboardTotalAttempts), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('bestClearTime null → 显示「—」(无通关耗时数据)', (tester) async {
    await tester.pumpWidget(app(mkProgress(
      highest: 1,
      bestClearTimeMs: null, // 边界值:首通字段未写(理论不可达但兜底)
      totalAttempts: 1,
    )));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.leaderboardBestClearTime), findsOneWidget);
    expect(find.text(UiStrings.leaderboardNoData), findsOneWidget,
        reason: 'bestClearTime null 走 NoData 占位');
  });

  testWidgets('totalDefeats > 0 → 显胜率;== 0 不显(派生指标条件渲染)', (tester) async {
    // 有失败 → 显胜率
    await tester.pumpWidget(app(mkProgress(
      highest: 3,
      bestClearTimeMs: 5000,
      totalAttempts: 10,
      totalDefeats: 3, // wins = 7,winRate = 70%
    )));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.leaderboardWinRate), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
  });

  testWidgets('totalDefeats == 0 → 不显胜率(GDD 反留存焦虑,不必每屏挂派生指标)', (tester) async {
    await tester.pumpWidget(app(mkProgress(
      highest: 3,
      bestClearTimeMs: 5000,
      totalAttempts: 3,
      totalDefeats: 0,
    )));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.leaderboardWinRate), findsNothing);
  });

  testWidgets('耗时 >= 60s → 显「X 分 Y 秒」格式', (tester) async {
    await tester.pumpWidget(app(mkProgress(
      highest: 10,
      bestClearTimeMs: 125000, // 2 分 5 秒
      totalAttempts: 15,
    )));
    await tester.pumpAndSettle();
    expect(find.text('2 分 5 秒'), findsOneWidget,
        reason: '125000 ms = 125 秒 = 2 分 5 秒');
  });
}
