import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_title_bar.dart';

void main() {
  testWidgets('可作 Scaffold.appBar 用，渲染标题', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: WuxiaTitleBar(title: '角色档案', onBack: () {}),
        body: const SizedBox(),
      ),
    ));
    expect(find.text('角色档案'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onBack 非空显返回钮并可点', (tester) async {
    var back = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: WuxiaTitleBar(title: '装备仓库', onBack: () => back++),
        body: const SizedBox(),
      ),
    ));
    await tester.tap(find.byIcon(Icons.subdirectory_arrow_left));
    expect(back, 1);
  });

  testWidgets('onBack 为 null 不显返回钮', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        appBar: WuxiaTitleBar(title: '主菜单'),
        body: SizedBox(),
      ),
    ));
    expect(find.byIcon(Icons.subdirectory_arrow_left), findsNothing);
  });
}
