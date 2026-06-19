import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/glossary_tip.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_dialog.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  group('GlossaryTip', () {
    testWidgets('包裹 child 且 Tooltip message = 释义', (tester) async {
      await tester.pumpWidget(
        host(
          const GlossaryTip(
            definition: '根骨：决定血量上限根基。',
            child: Text('根骨'),
          ),
        ),
      );

      expect(find.text('根骨'), findsOneWidget);
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, '根骨：决定血量上限根基。');
    });

    testWidgets('长按触发气泡显示释义', (tester) async {
      await tester.pumpWidget(
        host(
          const GlossaryTip(
            definition: '内力：施展招式的根本。',
            child: Text('内力'),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('内力')),
      );
      await tester.pump(const Duration(seconds: 1));
      // Tooltip overlay 弹出后,释义文字出现(label + overlay 两处)
      expect(find.text('内力：施展招式的根本。'), findsWidgets);
      await gesture.up();
    });
  });

  group('GlossaryLabel', () {
    testWidgets('渲染标签文字 + ? 可发现标记 + 释义 tooltip', (tester) async {
      await tester.pumpWidget(
        host(
          const GlossaryLabel(
            label: '身法',
            definition: '身法：决定出手速度与闪避。',
          ),
        ),
      );

      expect(find.text('身法'), findsOneWidget);
      expect(find.text(GlossaryLabel.marker), findsOneWidget);
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, '身法：决定出手速度与闪避。');
    });

    testWidgets('应用传入的 textStyle 到标签', (tester) async {
      await tester.pumpWidget(
        host(
          const GlossaryLabel(
            label: '机缘',
            definition: '机缘：影响奇遇触发。',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('机缘'));
      expect(text.style?.fontSize, 21);
      expect(text.style?.fontWeight, FontWeight.w900);
    });

    testWidgets('点击 ? 标记 → 弹释义浮层', (tester) async {
      await tester.pumpWidget(
        host(
          const GlossaryLabel(
            label: '身法',
            definition: '身法：决定出手速度与闪避。',
          ),
        ),
      );

      await tester.tap(find.text(GlossaryLabel.marker));
      await tester.pumpAndSettle();
      expect(find.byType(PaperDialog), findsOneWidget);
      expect(find.text('身法：决定出手速度与闪避。'), findsWidgets);
    });

    testWidgets('点击标签文字不弹浮层（只裹 marker，保父级点击）', (tester) async {
      await tester.pumpWidget(
        host(
          const GlossaryLabel(
            label: '身法',
            definition: '身法：决定出手速度与闪避。',
          ),
        ),
      );

      await tester.tap(find.text('身法'));
      await tester.pumpAndSettle();
      expect(find.byType(PaperDialog), findsNothing);
    });
  });
}
