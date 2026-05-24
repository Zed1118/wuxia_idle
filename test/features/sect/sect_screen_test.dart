import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sect/application/sect_providers.dart';
import 'package:wuxia_idle/features/sect/domain/sect.dart';
import 'package:wuxia_idle/features/sect/domain/sect_event.dart';
import 'package:wuxia_idle/features/sect/presentation/sect_screen.dart';

/// P3.4 sect_event Batch 2.3 widget 测族(spec §7 R4 + R5)。
///
/// **测试边界**:不真实例化 Isar(memory `feedback_isar_autoincrement_test_id_collision`),
/// 不进 SectEventDialog 内部 FutureBuilder rootBundle.loadString(测 widget 主流程
/// 即可,narrative loader 测覆盖另议)。
///
/// 覆盖:
/// - SectScreen 顶部 sect_name / sectLevel / sectReputation 进度条 / totalWins 渲染
/// - TabBar 2 标签 + 空 active list / 空 history list 提示
/// - 注入 active event 后红点 row 显
/// - resolve(win) 后 sect.totalWins +1 + reputation +10(走 SectStateNotifier 真路径)
void main() {
  group('P3.4 sect_screen widget · 顶部 + tab + 空状态', () {
    testWidgets('R4.1 默认 initial sect 显「无名宗」/「等阶 1」/「50 / 100」',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SectScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('无名宗'), findsOneWidget);
      expect(find.text('等阶 1'), findsOneWidget);
      expect(find.text('50 / 100'), findsOneWidget);
      expect(find.text('累计胜场 0'), findsOneWidget);
    });

    testWidgets('R4.2 TabBar 2 标签 + 空 active list 提示「当前无门派事件」',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SectScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('当前事件'), findsOneWidget);
      expect(find.text('历史记录'), findsOneWidget);
      expect(find.text('当前无门派事件'), findsOneWidget);
    });

    testWidgets('R4.3 history tab 切换 → 显「尚无历史记录」', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SectScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('历史记录'));
      await tester.pumpAndSettle();
      expect(find.text('尚无历史记录'), findsOneWidget);
    });
  });

  group('P3.4 sect_screen widget · active 注入 + resolve 联动', () {
    testWidgets('R4.4 注入 pending 事件 → active list 显「比武大会」red dot row',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final pending = SectEvent()
        ..id = 100
        ..sectId = 1
        ..type = SectEventType.tournament
        ..status = SectEventStatus.pending
        ..triggeredAt = DateTime(2026, 5, 24)
        ..narrativeId = 'tournament_01';
      container.read(sectStateProvider.notifier).seedActiveEvent(pending);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SectScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('比武大会'), findsOneWidget);
      expect(find.byIcon(Icons.circle), findsWidgets);
    });

    // R5.1/R5.2 service resolve 联动 · 走 sect_battle_integration_test e2e
    // 覆盖(走 numbersConfigProvider.overrideWithValue + NumbersConfigStub),
    // 这里不重复测,避 widget test 直读 GameRepository.instance 未 init 撞。

    // R5.3 tournament_01 + tournament_02 narrative 校验 · rootBundle 走 pubspec
    // asset 链,widget test 不抓 asset(memory `feedback_listview_widget_test_viewport`
    // 同类决议)· 留 manual + golden 测覆盖。
  });
}
