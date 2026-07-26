import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_dialog.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';

void main() {
  testWidgets('渲染标题与正文', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PaperDialog(
            title: '凯旋',
            body: Text('斩 山贼头目 · 历 6 回合'),
            actions: [],
          ),
        ),
      ),
    );
    expect(find.text('凯旋'), findsOneWidget);
    expect(find.text('斩 山贼头目 · 历 6 回合'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actions 内 PlaqueButton 可点', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaperDialog(
            title: '强化',
            body: const Text('确认强化？'),
            actions: [
              PlaqueButton(label: '确认', primary: true, onTap: () => n++),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('确认'));
    expect(n, 1);
  });

  testWidgets('动作区窄宽度可换行,避免按钮文字溢出', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: PaperDialog(
                title: '收功',
                body: Text('确认离开闭关？'),
                actions: [
                  PlaqueButton(label: '继续闭关', onTap: null),
                  PlaqueButton(label: '收功离开', onTap: null),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PaperDialog.show 弹出并显标题', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Launcher()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('掉落'), findsOneWidget);
  });

  testWidgets('深色全局主题下 Material 组件继承浅宣纸主题', (tester) async {
    late ThemeData dialogTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: PaperDialog(
            title: '设置',
            body: Builder(
              builder: (context) {
                dialogTheme = Theme.of(context);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.tune),
                      title: Text('显示'),
                      subtitle: Text('窗口设置'),
                    ),
                    SwitchListTile(
                      title: const Text('全屏'),
                      value: true,
                      onChanged: (_) {},
                    ),
                    Slider(value: 0.5, onChanged: (_) {}),
                  ],
                );
              },
            ),
            actions: const [],
          ),
        ),
      ),
    );

    expect(dialogTheme.brightness, Brightness.light);
    expect(dialogTheme.colorScheme.surface, WuxiaUi.paper);
    expect(dialogTheme.colorScheme.onSurface, WuxiaUi.ink);
    expect(dialogTheme.listTileTheme.textColor, WuxiaUi.ink);
    expect(dialogTheme.listTileTheme.iconColor, WuxiaUi.ink2);
    expect(
      dialogTheme.switchTheme.trackColor!.resolve({WidgetState.selected}),
      WuxiaUi.jiang,
    );
    expect(dialogTheme.sliderTheme.activeTrackColor, WuxiaUi.jiang);
    expect(tester.takeException(), isNull);
  });
}

class _Launcher extends StatelessWidget {
  const _Launcher();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => PaperDialog.show<void>(
              ctx,
              title: '掉落',
              body: const Text('青锋剑'),
              actions: const [],
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}
