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

  testWidgets('showHome 默认显示回主菜单钮,点击触发 onHome', (tester) async {
    var home = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: WuxiaTitleBar(title: '装备仓库', onHome: () => home++),
        body: const SizedBox(),
      ),
    ));
    await tester.tap(find.byIcon(Icons.home_outlined));
    expect(home, 1);
  });

  testWidgets('showHome=false 不显回主菜单钮', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        appBar: WuxiaTitleBar(title: '主菜单', showHome: false),
        body: SizedBox(),
      ),
    ));
    expect(find.byIcon(Icons.home_outlined), findsNothing);
  });

  testWidgets('trailing 槽:传入 widget 渲染于标题栏（页面级帮助入口位）', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        appBar: WuxiaTitleBar(
          title: '装备仓库',
          trailing: Icon(Icons.help_outline, key: Key('trailing-probe')),
        ),
        body: SizedBox(),
      ),
    ));
    expect(find.byKey(const Key('trailing-probe')), findsOneWidget);
  });

  testWidgets('trailing 为 null 不额外渲染', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        appBar: WuxiaTitleBar(title: '装备仓库'),
        body: SizedBox(),
      ),
    ));
    expect(find.byIcon(Icons.help_outline), findsNothing);
  });
}
