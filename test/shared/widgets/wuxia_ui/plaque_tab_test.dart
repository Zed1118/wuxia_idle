import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_tab.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('渲染 label', (tester) async {
    await tester.pumpWidget(
      host(const PlaqueTab(label: '祖师', selected: true, onTap: null)),
    );
    expect(find.text('祖师'), findsOneWidget);
  });

  testWidgets('点击触发 onTap', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      host(PlaqueTab(label: '大弟子', selected: false, onTap: () => n++)),
    );
    await tester.tap(find.byType(PlaqueTab));
    expect(n, 1);
  });

  testWidgets('Semantics 标记 button + selected', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const PlaqueTab(label: '祖师', selected: true, onTap: null)),
    );
    expect(
      tester.getSemantics(find.byType(PlaqueTab)),
      isSemantics(isButton: true, isSelected: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('键盘 Enter 激活 onTap(autofocus)', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      host(
        PlaqueTab(
          label: '大弟子',
          selected: false,
          onTap: () => n++,
          autofocus: true,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(n, 1);
  });

  testWidgets('真实 hitbox 高度不低于 36px', (tester) async {
    await tester.pumpWidget(
      host(const PlaqueTab(label: '祖师', selected: true, onTap: null)),
    );
    expect(
      tester.getSize(find.byType(PlaqueTab)).height,
      greaterThanOrEqualTo(36),
    );
  });

  testWidgets('选中态字色与未选不同（朱漆 vs 木色）', (tester) async {
    await tester.pumpWidget(
      host(const PlaqueTab(label: 'A', selected: true, onTap: null)),
    );
    final onColor = tester.widget<Text>(find.text('A')).style!.color;
    await tester.pumpWidget(
      host(const PlaqueTab(label: 'B', selected: false, onTap: null)),
    );
    final offColor = tester.widget<Text>(find.text('B')).style!.color;
    expect(onColor, isNot(offColor));
  });
}
