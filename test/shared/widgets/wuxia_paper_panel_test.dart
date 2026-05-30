import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_paper_panel.dart';

/// Phase B WuxiaPaperPanel widget 测：渲染 child / errorBuilder 守 / 墨边开关。
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  BoxDecoration rootDeco(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(WuxiaPaperPanel),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  testWidgets('渲染 child', (tester) async {
    await tester.pumpWidget(host(const WuxiaPaperPanel(child: Text('卷轴内容'))));
    expect(find.text('卷轴内容'), findsOneWidget);
  });

  testWidgets('宣纸图加载失败走 errorBuilder 不抛异常，child 仍在', (tester) async {
    await tester.pumpWidget(host(const WuxiaPaperPanel(child: Text('内容'))));
    expect(tester.takeException(), isNull);
    expect(find.text('内容'), findsOneWidget);
  });

  testWidgets('默认 showBorder=true 画 inkPanelEdge 墨边', (tester) async {
    await tester.pumpWidget(host(const WuxiaPaperPanel(child: SizedBox())));
    expect(rootDeco(tester).border, isNotNull);
  });

  testWidgets('showBorder=false 不画墨边外框', (tester) async {
    await tester.pumpWidget(
      host(const WuxiaPaperPanel(showBorder: false, child: SizedBox())),
    );
    expect(rootDeco(tester).border, isNull);
  });
}
