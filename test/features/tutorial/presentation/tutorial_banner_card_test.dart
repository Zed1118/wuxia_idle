import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/tutorial/domain/tutorial_hint_def.dart';
import 'package:wuxia_idle/features/tutorial/presentation/tutorial_banner_card.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/colors.dart';

/// P1 #42 Phase 2 §10 P1.y · TutorialBannerCard widget 红线。
///
/// **本文件仅渲染 case**:isarProvider 默认 null,onTap 路径短路(不接真 Isar)。
///
/// onTap → markHintRead 端到端串接验证留 [main_menu_test] 走真 Isar 端到端 case
/// (memory `feedback_isar_widget_test_deadlock`:testWidgets 内 `isar.writeTxn`
/// 与 Flutter event loop 死锁,markHintRead 业务路径已被 tutorial_service_test
/// 5 case 覆盖,本批不重复验)。
void main() {
  group('渲染', () {
    testWidgets('step 6 → title + body + Icon people_outline 可见', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TutorialBannerCard(hint: TutorialHintDef.step6),
            ),
          ),
        ),
      );
      expect(find.text(UiStrings.tutorialHintStep6Title), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep6Body), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('step 7 → title + body + Icon auto_awesome 可见', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TutorialBannerCard(hint: TutorialHintDef.step7),
            ),
          ),
        ),
      );
      expect(find.text(UiStrings.tutorialHintStep7Title), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep7Body), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('step 8 → title + body + Icon flash_on_outlined 可见',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TutorialBannerCard(hint: TutorialHintDef.step8),
            ),
          ),
        ),
      );
      expect(find.text(UiStrings.tutorialHintStep8Title), findsOneWidget);
      expect(find.text(UiStrings.tutorialHintStep8Body), findsOneWidget);
      expect(find.byIcon(Icons.flash_on_outlined), findsOneWidget);
    });

    testWidgets('红点存在(Positioned + hpLow circle)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TutorialBannerCard(hint: TutorialHintDef.step6),
            ),
          ),
        ),
      );

      // 找 hpLow 颜色的 Container(独有 banner 红点用)。
      final containers = tester.widgetList<Container>(find.byType(Container));
      final reddots = containers.where((c) {
        final dec = c.decoration;
        if (dec is! BoxDecoration) return false;
        return dec.color == WuxiaColors.hpLow && dec.shape == BoxShape.circle;
      });
      expect(reddots.length, 1, reason: '应仅有 1 个红点');
    });
  });

  testWidgets('InkWell 存在(onTap 触发路径)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TutorialBannerCard(hint: TutorialHintDef.step6),
          ),
        ),
      ),
    );
    expect(find.byType(InkWell), findsOneWidget,
        reason: 'banner 必须能点击触发 markHintRead');
  });

  // ─── 边界 & 派生(纯 unit test,不用 testWidgets) ───────────────────────

  group('派生', () {
    test('byStep 正向 — 6/7/8 各返回对应 instance', () {
      final h6 = TutorialHintDef.byStep(6);
      expect(h6, isNotNull, reason: 'step 6 应存在');
      expect(h6!.step, 6);
      expect(h6.title, UiStrings.tutorialHintStep6Title);

      final h7 = TutorialHintDef.byStep(7);
      expect(h7, isNotNull, reason: 'step 7 应存在');
      expect(h7!.step, 7);
      expect(h7.title, UiStrings.tutorialHintStep7Title);

      final h8 = TutorialHintDef.byStep(8);
      expect(h8, isNotNull, reason: 'step 8 应存在');
      expect(h8!.step, 8);
      expect(h8.title, UiStrings.tutorialHintStep8Title);
    });

    test('byStep(99) → null fallback', () {
      expect(TutorialHintDef.byStep(99), isNull,
          reason: '超出 6-8 范围返回 null');
    });
  });

  group('边界', () {
    test('byStep(5) → null(step 6 下界 -1)', () {
      expect(TutorialHintDef.byStep(5), isNull);
    });

    test('byStep(9) → null(step 8 上界 +1)', () {
      expect(TutorialHintDef.byStep(9), isNull);
    });

    test('byStep(-1) → null(负值越界)', () {
      expect(TutorialHintDef.byStep(-1), isNull);
    });
  });
}
