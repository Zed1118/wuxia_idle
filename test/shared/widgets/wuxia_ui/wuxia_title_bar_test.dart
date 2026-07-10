import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_icon_button.dart';
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
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(back, 1);
  });

  testWidgets('onBack 为 null 不显返回钮', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        appBar: WuxiaTitleBar(title: '主菜单'),
        body: SizedBox(),
      ),
    ));
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('返回和主页动作使用统一 44x44 热区、tooltip 与按钮语义', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: WuxiaTitleBar(
          title: '装备仓库',
          onBack: () {},
          onHome: () {},
          showSeal: false,
        ),
        body: const SizedBox(),
      ),
    ));

    final backButton = find.ancestor(
      of: find.byIcon(Icons.arrow_back),
      matching: find.byType(WuxiaIconButton),
    );
    final homeButton = find.ancestor(
      of: find.byIcon(Icons.home_outlined),
      matching: find.byType(WuxiaIconButton),
    );
    Finder buttonSemantics(Finder button) => find.descendant(
      of: button,
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true,
      ),
    );

    expect(backButton, findsOneWidget);
    expect(homeButton, findsOneWidget);
    expect(tester.getSize(backButton), const Size.square(WuxiaIconButton.size));
    expect(tester.getSize(homeButton), const Size.square(WuxiaIconButton.size));
    expect(find.byTooltip(UiStrings.titleBarBack), findsOneWidget);
    expect(find.byTooltip(UiStrings.titleBarHome), findsOneWidget);
    expect(
      tester.getSemantics(buttonSemantics(backButton)),
      isSemantics(
        label: UiStrings.titleBarBack,
        isButton: true,
        isEnabled: true,
      ),
    );
    expect(
      tester.getSemantics(buttonSemantics(homeButton)),
      isSemantics(
        label: UiStrings.titleBarHome,
        isButton: true,
        isEnabled: true,
      ),
    );
    semantics.dispose();
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
