import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/features/home_feed/application/home_feed_providers.dart';
import 'package:wuxia_idle/features/home_feed/presentation/home_feed_screen.dart';

/// P1 #42 · HomeFeedScreen 相对时间 6 档 — 剩余 4 档 edge test。
///
/// 断言策略(feedback_red_line_test_semantics):
/// 只断言格式契约(正则白名单),不固定具体数字或当时的字面值。
///
/// 实际代码格式(strings.dart homeFeedRelativeTime):
///   < 5 min  → 刚才               (已有 test)
///   5-59 min → N 分钟前            (已有 test)
///   同日 ≥60min → 今日 HH:MM       ← 本文件 test A
///   1 日前    → 昨日 HH:MM         ← 本文件 test B
///   2-6 日前  → N 日前             ← 本文件 test C
///   ≥ 7 日    → MM-DD             ← 本文件 test D
void main() {
  group('HomeFeedScreen 相对时间格式 6 档(剩 4 档)', () {
    GameEvent makeEvent(DateTime occurredAt) {
      return GameEvent()
        ..eventType = GameEventType.retreatCompleted
        ..title = '测试事件'
        ..summary = '正文'
        ..occurredAt = occurredAt
        ..isRead = false;
    }

    Future<void> pump(WidgetTester tester, GameEvent event) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          gameEventsFeedProvider().overrideWith((ref) async => [event]),
        ],
        child: const MaterialApp(home: HomeFeedScreen()),
      ));
      await tester.pump();
    }

    Finder findTextMatching(RegExp pattern) {
      return find.byWidgetPredicate((widget) =>
          widget is Text &&
          widget.data != null &&
          pattern.hasMatch(widget.data!));
    }

    testWidgets('今日 HH:MM 档:同日 1h+ 前显 HH:MM 格式', (tester) async {
      final now = DateTime.now();
      // 90 分钟前:同日时显"今日 HH:MM",跨零点时显"昨日 HH:MM"
      // 两者都符合 HH:MM 格式契约,均为合法边界行为
      final event = makeEvent(now.subtract(const Duration(minutes: 90)));
      await pump(tester, event);
      expect(
        findTextMatching(RegExp(r'^(今日|昨日) \d{2}:\d{2}$')),
        findsOneWidget,
      );
    });

    testWidgets('昨日 HH:MM 档:精确 24h 前恒显昨日 HH:MM 格式', (tester) async {
      final now = DateTime.now();
      // 24h 前:daysAgo 必然 == 1,恒触发"昨日 HH:MM"分支,无日期边界歧义
      final event = makeEvent(now.subtract(const Duration(hours: 24)));
      await pump(tester, event);
      expect(
        findTextMatching(RegExp(r'^昨日 \d{2}:\d{2}$')),
        findsOneWidget,
      );
    });

    testWidgets('N 日前档:3 日前显 N 日前格式', (tester) async {
      final now = DateTime.now();
      final event = makeEvent(now.subtract(const Duration(days: 3)));
      await pump(tester, event);
      expect(
        findTextMatching(RegExp(r'^\d+ 日前$')),
        findsOneWidget,
      );
    });

    testWidgets('MM-DD 档:≥7 日前显 MM-DD 格式', (tester) async {
      final now = DateTime.now();
      final event = makeEvent(now.subtract(const Duration(days: 10)));
      await pump(tester, event);
      expect(
        findTextMatching(RegExp(r'^\d{2}-\d{2}$')),
        findsOneWidget,
      );
    });
  });
}
