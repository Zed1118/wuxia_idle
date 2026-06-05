import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_panel.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('渲染 child', (tester) async {
    await tester.pumpWidget(host(const PaperPanel(child: Text('卷宗'))));
    expect(find.text('卷宗'), findsOneWidget);
  });

  testWidgets('宣纸图缺失走 errorBuilder 不抛异常，child 仍在', (tester) async {
    await tester.pumpWidget(host(const PaperPanel(child: Text('卷宗'))));
    expect(tester.takeException(), isNull);
    expect(find.text('卷宗'), findsOneWidget);
  });

  testWidgets('用作滚动列 tile（无界高度）包 IntrinsicHeight 不抛', (tester) async {
    await tester.pumpWidget(host(
      ListView(children: const [
        IntrinsicHeight(child: PaperPanel(child: Text('行'))),
      ]),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('行'), findsOneWidget);
  });

  testWidgets('默认画墨边外框', (tester) async {
    await tester.pumpWidget(host(const PaperPanel(child: SizedBox())));
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(PaperPanel),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((box.decoration as BoxDecoration).border, isNotNull);
    expect((box.decoration as BoxDecoration).color, WuxiaUi.panelFill);
  });
}
