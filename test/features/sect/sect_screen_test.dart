import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sect/application/sect_providers.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';
import 'package:wuxia_idle/features/sect/presentation/sect_screen.dart';

/// P3.4 sect_event Batch 2.3 widget 测族(spec §7 R4 + R5)。
///
/// T19b 重构注:从 SectStateNotifier 内存 state 切到 StreamProvider 真 Isar 路径。
/// widget 测不真实例化 Isar(memory `feedback_isar_widget_test_deadlock` /
/// `feedback_isar_autoincrement_test_id_collision`),走 provider override 注 stub
/// Stream 模拟 Isar 已读出的数据。
void main() {
  Sect defaultSect() => Sect()
    ..id = 1
    ..name = '无名宗'
    ..founderId = 1
    ..sectLevel = 1
    ..sectReputation = 50
    ..totalWins = 0
    ..createdAt = DateTime(2026, 5, 1)
    ..lastEventAt = null;

  ProviderScope withScope({
    required Sect? sect,
    List<SectEvent> active = const [],
    List<SectEvent> historical = const [],
    required Widget child,
  }) =>
      ProviderScope(
        overrides: [
          currentSectProvider.overrideWith((ref) => Stream.value(sect)),
          activeSectEventsProvider
              .overrideWith((ref) => Stream.value(active)),
          historicalSectEventsProvider
              .overrideWith((ref) => Stream.value(historical)),
        ],
        child: child,
      );

  group('P3.4 sect_screen widget · 顶部 + tab + 空状态', () {
    testWidgets('R4.1 默认 sect 显「无名宗」/「等阶 1」/「50 / 100」', (tester) async {
      await tester.pumpWidget(withScope(
        sect: defaultSect(),
        child: const MaterialApp(home: SectScreen()),
      ));
      await tester.pump();

      expect(find.text('无名宗'), findsOneWidget);
      expect(find.text('等阶 1'), findsOneWidget);
      expect(find.text('50 / 100'), findsOneWidget);
      expect(find.text('累计胜场 0'), findsOneWidget);
    });

    testWidgets('R4.2 TabBar 2 标签 + 空 active list 提示「当前无门派事件」',
        (tester) async {
      await tester.pumpWidget(withScope(
        sect: defaultSect(),
        child: const MaterialApp(home: SectScreen()),
      ));
      await tester.pump();

      expect(find.text('当前事件'), findsOneWidget);
      expect(find.text('历史记录'), findsOneWidget);
      expect(find.text('当前无门派事件'), findsOneWidget);
    });

    testWidgets('R4.3 history tab 切换 → 显「尚无历史记录」', (tester) async {
      await tester.pumpWidget(withScope(
        sect: defaultSect(),
        child: const MaterialApp(home: SectScreen()),
      ));
      await tester.pump();

      await tester.tap(find.text('历史记录'));
      await tester.pumpAndSettle();
      expect(find.text('尚无历史记录'), findsOneWidget);
    });
  });

  group('P3.4 sect_screen widget · active 注入 + AsyncValue 三态', () {
    testWidgets('R4.4 注入 pending 事件 → active list 显「比武大会」red dot row',
        (tester) async {
      final pending = SectEvent()
        ..id = 100
        ..sectId = 1
        ..type = SectEventType.tournament
        ..status = SectEventStatus.pending
        ..triggeredAt = DateTime(2026, 5, 24)
        ..narrativeId = 'tournament_01';

      await tester.pumpWidget(withScope(
        sect: defaultSect(),
        active: [pending],
        child: const MaterialApp(home: SectScreen()),
      ));
      await tester.pump();

      expect(find.text('比武大会'), findsOneWidget);
      expect(find.byIcon(Icons.circle), findsWidgets);
    });

    testWidgets('R4.5 sect=null → 显「门派尚未创建」兜底文案', (tester) async {
      await tester.pumpWidget(withScope(
        sect: null,
        child: const MaterialApp(home: SectScreen()),
      ));
      await tester.pump();

      expect(find.text('门派尚未创建'), findsOneWidget);
    });
  });
}
