import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/hero_camera_overlay.dart';
import 'package:wuxia_idle/shared/strings.dart';

// 测试用 HeroCameraData 工厂
HeroCameraData _data({String? portraitPath}) => HeroCameraData(
      portraitPath: portraitPath,
      heroName: '祖师',
      realmLabel: '宗师·化境',
      bossName: '黑袍人',
      topDamage: 12345,
    );

void main() {
  // 确保测试结束后清理所有 pending timer（全部用 pump 推到 auto-dismiss 触发点）
  const holdMs = 3200; // > 默认 3.0s fallback，足够覆盖 delayed

  group('HeroCameraOverlay 渲染', () {
    testWidgets('渲染英雄名号 + 击破题字（有 portraitPath）', (tester) async {
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCameraOverlay(
              data: _data(portraitPath: 'assets/test_placeholder.png'),
              onDone: () => doneCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      // 英雄名号
      expect(find.text('祖师'), findsOneWidget);
      // 境界副标
      expect(find.text('宗师·化境'), findsOneWidget);
      // 击破题字（heroCameraDefeated('黑袍人')）
      expect(find.textContaining('黑袍人'), findsOneWidget);
      // 本场最强 badge
      expect(find.text(UiStrings.heroCameraTopOutput), findsOneWidget);

      // 推进让 auto-dismiss timer 触发，避免 pending timer 报错
      await tester.pump(const Duration(milliseconds: holdMs));
      expect(doneCalled, isTrue);
    });

    testWidgets('portraitPath==null 时不抛异常、名号仍渲染', (tester) async {
      bool doneCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCameraOverlay(
              data: _data(),
              onDone: () => doneCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      // 无异常
      expect(tester.takeException(), isNull);
      // 名号仍显示
      expect(find.text('祖师'), findsOneWidget);

      // 推进 timer
      await tester.pump(const Duration(milliseconds: holdMs));
      expect(doneCalled, isTrue);
    });
  });

  group('HeroCameraOverlay 交互', () {
    testWidgets('点击触发 onDone，且 timer 不二次调用（once-guard）', (tester) async {
      var doneCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCameraOverlay(
              data: _data(),
              onDone: () => doneCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      // 点击 overlay 本身
      await tester.tap(find.byType(HeroCameraOverlay));
      await tester.pump();
      expect(doneCount, 1);

      // 推进剩余 timer（点击后 _done=true，timer 触发须被 once-guard 拦下）
      await tester.pump(const Duration(milliseconds: holdMs));
      expect(doneCount, 1); // 仍只 1 次，timer 未重复触发
      expect(tester.takeException(), isNull);
    });

    testWidgets('timer 先触发后点击不二次调用（对称 once-guard）', (tester) async {
      var doneCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroCameraOverlay(
              data: _data(),
              onDone: () => doneCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      // 先让 auto-dismiss timer 触发
      await tester.pump(const Duration(milliseconds: holdMs));
      expect(doneCount, 1);

      // 再点击：_done 已 true，应被拦下
      await tester.tap(find.byType(HeroCameraOverlay));
      await tester.pump();
      expect(doneCount, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
