import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/encounter_def.dart';
import 'package:wuxia_idle/data/encounter_event_loader.dart';
import 'package:wuxia_idle/features/encounter/presentation/encounter_dialog.dart';

void main() {
  const def = EncounterDef(
    id: 'fortune_choice_test',
    type: EncounterType.fortuneEvent,
    trigger: EncounterTrigger(),
    baseProbability: 1,
    outcomeMapping: {'lucky': OutcomeDef(type: OutcomeType.none)},
  );

  const content = EncounterContent(
    id: 'fortune_choice_test',
    title: '测试奇遇',
    opening: '山路尽头，有一扇半掩的门。',
    choices: [
      EncounterChoice(
        text: '循迹入门',
        outcomeId: 'lucky',
        body: '门后别有洞天。',
        fortuneRequired: 8,
      ),
    ],
    isPlaceholder: false,
  );

  Future<Future<String?>> pumpDialog(WidgetTester tester, int fortune) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox();
          },
        ),
      ),
    );
    final result = showEncounterDialog(
      context: context,
      def: def,
      content: content,
      fortune: fortune,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return result;
  }

  testWidgets('机缘不足：选项可见但禁用，并显示门槛', (tester) async {
    await pumpDialog(tester, 7);

    expect(find.text('循迹入门'), findsOneWidget);
    expect(find.text('机缘 8'), findsOneWidget);
    final semanticsFinder = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == '循迹入门',
    );
    final semantics = tester.widget<Semantics>(semanticsFinder);
    expect(semantics.properties.enabled, isFalse);

    await tester.tap(find.text('循迹入门'));
    await tester.pump();
    expect(find.text('门后别有洞天。'), findsNothing);
  });

  testWidgets('机缘达标：选项可用并返回既有 outcome id', (tester) async {
    final result = await pumpDialog(tester, 8);

    await tester.tap(find.text('循迹入门'));
    await tester.pumpAndSettle();
    expect(find.text('门后别有洞天。'), findsOneWidget);

    await tester.tap(find.text('行路 →'));
    await tester.pumpAndSettle();
    expect(await result, 'lucky');
  });
}
