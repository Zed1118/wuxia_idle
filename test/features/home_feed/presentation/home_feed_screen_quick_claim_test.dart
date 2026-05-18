import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/features/home_feed/application/home_feed_providers.dart';
import 'package:wuxia_idle/features/home_feed/presentation/home_feed_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// NavigatorObserver 子类,记录 pushReplacement 次数。
///
/// `didReplace` 在 Navigator 内同步调用,无需 pump 额外帧即可读取结果。
class _RouteObserver extends NavigatorObserver {
  int replacementCount = 0;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacementCount++;
  }
}

/// 生成 n 条 unread GameEvent 用于 feed fixture。
List<GameEvent> _unreadEvents(int n) {
  final base = DateTime(2026, 5, 17, 12);
  return List.generate(
    n,
    (i) => GameEvent()
      ..eventType = GameEventType.bossDefeated
      ..title = '事件$i'
      ..summary = '摘要$i'
      ..occurredAt = base.subtract(Duration(hours: i))
      ..isRead = false,
  );
}

/// 封装 pumpWidget — A/C 测试用(isarProvider 默认 null,markAllFeedRead no-op)。
Future<_RouteObserver> _pumpScreen(
  WidgetTester tester, {
  required List<GameEvent> events,
}) async {
  final obs = _RouteObserver();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      gameEventsFeedProvider().overrideWith((ref) async => events),
    ],
    child: MaterialApp(
      navigatorObservers: [obs],
      home: const HomeFeedScreen(),
    ),
  ));
  await tester.pump(); // FutureProvider data 到达 → 渲染 feed
  return obs;
}

void main() {
  group('HomeFeedScreen 快速领取按钮行为', () {
    testWidgets('A: 空 list 点快速领取——按钮 visible, tap 不抛异常, pushReplacement 触发',
        (tester) async {
      final obs = await _pumpScreen(tester, events: const []);

      expect(find.text(UiStrings.homeFeedQuickClaimLabel), findsOneWidget);

      // isarProvider = null → markAllFeedRead 立即 no-op，不写 Isar 事务
      await tester.tap(find.text(UiStrings.homeFeedQuickClaimLabel));
      await tester.pump(); // microtask: async continuation 运行
      await tester.pump(); // frame: navigator 重建

      expect(obs.replacementCount, greaterThan(0));
    });

    testWidgets(
        'B: 非空 list 点快速领取——markAllFeedRead 路径经过(isar=null no-op), pushReplacement 触发',
        (tester) async {
      // 注:本批本想用真 Isar spy 验证 markAllFeedRead 副作用,但 widget test 环境
      // 下 isar.writeTxn 与 Flutter event loop 死锁(测试 10min timeout 确认)。
      // markAllFeedRead 真实副作用语义由独立 unit test
      // home_feed_providers_mark_all_edge_test.dart 用 test() (非 testWidgets) +
      // 真 Isar 完整覆盖(3 case)。本 widget test 只验路径经过 + 导航,不重复 spy。
      final obs = await _pumpScreen(tester, events: _unreadEvents(3));

      expect(find.text('事件0'), findsOneWidget);

      // navigation 在 await markAllFeedRead 之后触发 ↔ markAllFeedRead 代码路径已被遍历
      await tester.tap(find.text(UiStrings.homeFeedQuickClaimLabel));
      await tester.pump();
      await tester.pump();

      expect(obs.replacementCount, greaterThan(0));
    });

    testWidgets('C: 重复点快速领取——记录当前行为（代码无显式防抖）', (tester) async {
      final obs = await _pumpScreen(tester, events: _unreadEvents(1));

      final btn = find.text(UiStrings.homeFeedQuickClaimLabel);
      // 注：`await tester.tap()` 之间 Dart 事件循环会排干微任务。
      // 第 1 次 await tap 后，onTap() 续体已运行并触发 Navigator.pushReplacement；
      // 第 2 次 tap 时按钮所在 HomeFeedScreen 已被替换，finder 在新页面按语义命中
      // 同名文本但该 widget 不在 hit-test 路径（warnIfMissed: false 消除噪音）。
      // 代码无显式防抖，当前机制：页面切换后 context.mounted==false 阻止再次导航。
      // 断言：至少 1 次 pushReplacement 发生（记录现状，不强行要求等于 1）。
      await tester.tap(btn);
      await tester.tap(btn, warnIfMissed: false);
      await tester.pump();
      await tester.pump();

      expect(obs.replacementCount, greaterThan(0));
    });
  });
}
