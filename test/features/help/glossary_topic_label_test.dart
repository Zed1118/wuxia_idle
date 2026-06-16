import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/help/domain/help_topic.dart';
import 'package:wuxia_idle/features/help/presentation/glossary_topic_label.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/glossary_tip.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  group('GlossaryTopicLabel', () {
    testWidgets('渲染 topic 的 label + ? marker + tooltip 短释义', (tester) async {
      await tester.pumpWidget(
        host(const GlossaryTopicLabel(topic: HelpTopic.constitution)),
      );

      expect(find.text(UiStrings.attrConstitution), findsOneWidget);
      expect(find.text(GlossaryLabel.marker), findsOneWidget);
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, UiStrings.glossaryConstitution);
    });

    testWidgets('装备侧 topic（强化）label + 释义来自 catalog', (tester) async {
      await tester.pumpWidget(
        host(const GlossaryTopicLabel(topic: HelpTopic.strengthening)),
      );

      expect(find.text(UiStrings.tabEnhance), findsOneWidget);
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, UiStrings.glossaryStrengthening);
    });

    testWidgets('应用传入的 textStyle 到标签', (tester) async {
      await tester.pumpWidget(
        host(
          const GlossaryTopicLabel(
            topic: HelpTopic.school,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text(UiStrings.labelSchool));
      expect(text.style?.fontSize, 19);
      expect(text.style?.fontWeight, FontWeight.w900);
    });
  });
}
