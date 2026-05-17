import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/baike/presentation/baike_screen.dart';
import 'package:wuxia_idle/features/home_feed/application/home_feed_providers.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// Nightshift T05 · BaikeScreen MainMenu 11 按钮导航 + 见闻 tab 6 档时间 override edge。
///
/// 测试 A/B 用 MainMenu widget 直接 pump（不走 HomeFeedScreen 快速领取链路）。
/// 测试 C 直接 pump BaikeScreen + provider override。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // ── A: MainMenu 11 按钮中含「江湖见闻录」────────────────────────────────
  //
  // 断言约束语义:按钮数 ≥11（InkWell 集合大小），不写位置 index。
  // 「江湖见闻录」存在性通过文案匹配（UiStrings.mainMenuBaike）覆盖。
  testWidgets('A: MainMenu 含 ≥11 个 InkWell 且「江湖见闻录」按钮存在', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainMenu())),
    );
    expect(
      find.byType(InkWell),
      findsAtLeastNWidgets(11),
      reason: 'MainMenu 至少 11 个 _MenuButton（含「江湖见闻录」）',
    );
    expect(find.text(UiStrings.mainMenuBaike), findsOneWidget);
  });

  // ── B: tap「江湖见闻录」→ Navigator.push 到 BaikeScreen ─────────────────
  //
  // 「江湖见闻录」是第 9 个按钮,800×600 默认视口需 ensureVisible 滚入再 tap。
  // BaikeScreen._FeedTab 以 isarProvider=null → gameEventsFeed 立即返回 []，
  // 无持续动画，pumpAndSettle 不死循环。
  testWidgets('B: tap「江湖见闻录」→ 导航到 BaikeScreen（find.byType 验证）',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainMenu())),
    );
    await tester.ensureVisible(find.text(UiStrings.mainMenuBaike));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.mainMenuBaike));
    await tester.pumpAndSettle();
    expect(find.byType(BaikeScreen), findsOneWidget);
  });

  // ── C: 见闻 tab 6 档时间 override 详化 ────────────────────────────────
  //
  // 6 档相对时间对应 UiStrings.homeFeedRelativeTime 的 6 分支：
  //   < 5min  → '刚才'
  //   5-59min → '$N 分钟前'
  //   同日 <24h → '今日 HH:MM'（测试时刻 <3h 前在同日时触发）
  //   daysAgo==1 → '昨日 HH:MM'（26h 前一定跨日）
  //   2-6d → '$N 日前'（3d 前固定此分支）
  //   ≥7d  → 'MM-DD'（10d 前固定此分支）
  //
  // 注意：3h 档可能命中「今日」或「昨日」分支（取决于测试运行时刻），
  // 预计算 expectedLabel 与 widget 内 DateTime.now() 差距 < 1s，分支必然一致。
  testWidgets('C: 见闻 tab 6 档时间格式 override 各档正确渲染', (tester) async {
    final now = DateTime.now();
    final offsets = [
      const Duration(minutes: 2),  // < 5min
      const Duration(minutes: 30), // 5-59min
      const Duration(hours: 3),    // 同日 or 昨日（clock-dependent）
      const Duration(hours: 26),   // daysAgo ≥ 1
      const Duration(days: 3),     // 2-6 days
      const Duration(days: 10),    // ≥ 7 days
    ];

    final events = <GameEvent>[];
    for (var i = 0; i < offsets.length; i++) {
      events.add(
        GameEvent()
          ..eventType = GameEventType.retreatCompleted
          ..title = 'evt_$i'
          ..summary = '摘要 $i'
          ..occurredAt = now.subtract(offsets[i])
          ..isRead = false,
      );
    }

    // 预计算期望文案：与 widget build 时 DateTime.now() 差距 < 1s，分支不变
    final expectedLabels =
        offsets.map((d) => UiStrings.homeFeedRelativeTime(now.subtract(d), now)).toList();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        gameEventsFeedProvider(limit: 50).overrideWith((ref) async => events),
      ],
      child: const MaterialApp(home: BaikeScreen()),
    ));
    await tester.pump();

    for (final label in expectedLabels) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: '时间文案「$label」应渲染在见闻 tab',
      );
    }
  });
}
