import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_dialog.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';

void main() {
  testWidgets('渲染标题与正文', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PaperDialog(
          title: '凯旋',
          body: Text('斩 山贼头目 · 历 6 回合'),
          actions: [],
        ),
      ),
    ));
    expect(find.text('凯旋'), findsOneWidget);
    expect(find.text('斩 山贼头目 · 历 6 回合'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actions 内 PlaqueButton 可点', (tester) async {
    var n = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaperDialog(
          title: '强化',
          body: const Text('确认强化？'),
          actions: [PlaqueButton(label: '确认', primary: true, onTap: () => n++)],
        ),
      ),
    ));
    await tester.tap(find.text('确认'));
    expect(n, 1);
  });

  testWidgets('PaperDialog.show 弹出并显标题', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Launcher()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('掉落'), findsOneWidget);
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
            onPressed: () => PaperDialog.show(
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
