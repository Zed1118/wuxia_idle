import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/features/home_feed/application/home_feed_providers.dart';
import 'package:wuxia_idle/features/home_feed/presentation/home_feed_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// P1 #42 Phase 3 · HomeFeedScreen 红线契约(widget 层)。
///
/// Riverpod nullable propagation:isarProvider 测试默认 null → feed 空,
/// 验证空态文案 + 快速领取按钮 visible 即可。
void main() {
  testWidgets('空 feed 显占位文案 + 快速领取按钮 visible', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: HomeFeedScreen()),
    ));
    await tester.pump();
    expect(find.text(UiStrings.homeFeedEmptyHint), findsOneWidget);
    expect(find.text(UiStrings.homeFeedQuickClaimLabel), findsOneWidget);
  });

  testWidgets('AppBar 标题 = 江湖见闻', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: HomeFeedScreen()),
    ));
    await tester.pump();
    expect(find.text(UiStrings.homeFeedTitle), findsOneWidget);
  });

  testWidgets('非空 feed 显倒序 title + summary', (tester) async {
    final now = DateTime(2026, 5, 17, 10);
    final events = [
      GameEvent()
        ..eventType = GameEventType.bossDefeated
        ..title = '斩 黑面阎罗'
        ..summary = '于「夜袭山贼营」一战胜 黑面阎罗。'
        ..occurredAt = now
        ..isRead = false,
      GameEvent()
        ..eventType = GameEventType.retreatCompleted
        ..title = '闭关收功'
        ..summary = '主角 于「山林」闭关 6 时。'
        ..occurredAt = now.subtract(const Duration(hours: 2))
        ..isRead = false,
    ];

    await tester.pumpWidget(ProviderScope(
      overrides: [
        gameEventsFeedProvider().overrideWith((ref) async => events),
      ],
      child: const MaterialApp(home: HomeFeedScreen()),
    ));
    await tester.pump();
    expect(find.text('斩 黑面阎罗'), findsOneWidget);
    expect(find.text('闭关收功'), findsOneWidget);
    expect(find.text(UiStrings.homeFeedEmptyHint), findsNothing);
  });

  testWidgets('相对时间 helper:5 分钟内显刚才', (tester) async {
    final now = DateTime.now();
    final event = GameEvent()
      ..eventType = GameEventType.retreatCompleted
      ..title = '测试事件'
      ..summary = '正文'
      ..occurredAt = now.subtract(const Duration(minutes: 2))
      ..isRead = false;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        gameEventsFeedProvider().overrideWith((ref) async => [event]),
      ],
      child: const MaterialApp(home: HomeFeedScreen()),
    ));
    await tester.pump();
    expect(find.text('刚才'), findsOneWidget);
  });

  testWidgets('相对时间 helper:30 分钟前显 N 分钟前', (tester) async {
    final now = DateTime.now();
    final event = GameEvent()
      ..eventType = GameEventType.retreatCompleted
      ..title = '测试事件'
      ..summary = '正文'
      ..occurredAt = now.subtract(const Duration(minutes: 30))
      ..isRead = false;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        gameEventsFeedProvider().overrideWith((ref) async => [event]),
      ],
      child: const MaterialApp(home: HomeFeedScreen()),
    ));
    await tester.pump();
    expect(find.text('30 分钟前'), findsOneWidget);
  });
}
