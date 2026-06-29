import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_icon_button.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('小图标使用 44×44 桌面热区', (tester) async {
    await tester.pumpWidget(
      host(
        WuxiaIconButton(
          icon: Icons.edit_outlined,
          tooltip: '重命名',
          onPressed: () {},
        ),
      ),
    );
    final size = tester.getSize(find.byType(WuxiaIconButton));
    expect(size.width, WuxiaIconButton.size);
    expect(size.height, WuxiaIconButton.size);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  testWidgets('点击与键盘 Enter 均可激活', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      host(
        WuxiaIconButton(
          icon: Icons.delete_outline,
          tooltip: '删除',
          onPressed: () => n++,
          autofocus: true,
        ),
      ),
    );
    await tester.tap(find.byType(WuxiaIconButton));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(n, 2);
  });

  testWidgets('disabled 保留语义但不可用', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const WuxiaIconButton(
          icon: Icons.restore_outlined,
          tooltip: '恢复',
          onPressed: null,
        ),
      ),
    );
    final buttonSemantics = find.descendant(
      of: find.byType(WuxiaIconButton),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true,
      ),
    );
    expect(
      tester.getSemantics(buttonSemantics),
      isSemantics(isButton: true, isEnabled: false),
    );
    handle.dispose();
  });
}
