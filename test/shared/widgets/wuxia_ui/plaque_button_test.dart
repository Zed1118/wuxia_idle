import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  FocusableActionDetector fad(WidgetTester tester) => tester.widget(
        find.descendant(
          of: find.byType(PlaqueButton),
          matching: find.byType(FocusableActionDetector),
        ),
      );

  testWidgets('渲染 label', (tester) async {
    await tester.pumpWidget(host(const PlaqueButton(label: '强化', onTap: null)));
    expect(find.text('强化'), findsOneWidget);
  });

  testWidgets('点击触发 onTap', (tester) async {
    var n = 0;
    await tester.pumpWidget(host(PlaqueButton(label: '继续', onTap: () => n++)));
    await tester.tap(find.byType(PlaqueButton));
    expect(n, 1);
  });

  testWidgets('disabled 拦截点击且半透明', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      host(PlaqueButton(label: '卸下', onTap: () => n++, disabled: true)),
    );
    await tester.tap(find.byType(PlaqueButton), warnIfMissed: false);
    expect(n, 0);
    final op = tester.widget<Opacity>(find.byType(Opacity));
    expect(op.opacity, 0.4);
  });

  testWidgets('无外层 Material 时也不红屏(overlay/dialog 安全)', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: PlaqueButton(label: '继续', onTap: null)),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('继续'), findsOneWidget);
  });

  // P2-6(2026-06-29 审查修复):木牌不该有 Material 灰色水波纹,改按下暗层。
  testWidgets('去除 InkWell 水波纹', (tester) async {
    await tester.pumpWidget(host(PlaqueButton(label: '确认', onTap: () {})));
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('按下显暗层(AnimatedOpacity 由 0→1),抬起复位', (tester) async {
    await tester.pumpWidget(host(PlaqueButton(label: '确认', onTap: () {})));
    AnimatedOpacity overlay() => tester.widget<AnimatedOpacity>(
          find.byType(AnimatedOpacity),
        );
    expect(overlay().opacity, 0.0, reason: '初始无按下暗层');

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PlaqueButton)),
    );
    await tester.pump();
    expect(overlay().opacity, greaterThan(0.0), reason: '按下显暗层');

    await gesture.up();
    await tester.pump();
    expect(overlay().opacity, 0.0, reason: '抬起复位');
  });

  // 2026-06-29 桌面语义补强(§8.2 UI 验收):GestureDetector 改造后补回
  // Semantics(button)/键盘激活/focus/cursor。
  testWidgets('Semantics 标记为可用 button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(PlaqueButton(label: '确认', onTap: () {})));
    expect(
      tester.getSemantics(find.byType(PlaqueButton)),
      isSemantics(isButton: true, isEnabled: true),
    );
    handle.dispose();
  });

  testWidgets('disabled → Semantics button 但不可用', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(PlaqueButton(label: '卸下', onTap: () {}, disabled: true)),
    );
    expect(
      tester.getSemantics(find.byType(PlaqueButton)),
      isSemantics(isButton: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('键盘 Enter 激活 onTap(autofocus)', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      host(PlaqueButton(label: '继续', onTap: () => n++, autofocus: true)),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(n, 1);
  });

  testWidgets('键盘 Space 激活 onTap(autofocus)', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      host(PlaqueButton(label: '继续', onTap: () => n++, autofocus: true)),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(n, 1);
  });

  testWidgets('disabled → 键盘 Enter 不激活', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      host(PlaqueButton(
        label: '卸下',
        onTap: () => n++,
        disabled: true,
        autofocus: true,
      )),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(n, 0);
  });

  testWidgets('鼠标 cursor:可用=click / disabled=basic', (tester) async {
    await tester.pumpWidget(host(PlaqueButton(label: '确认', onTap: () {})));
    expect(fad(tester).mouseCursor, SystemMouseCursors.click);

    await tester.pumpWidget(
      host(PlaqueButton(label: '卸下', onTap: () {}, disabled: true)),
    );
    expect(fad(tester).mouseCursor, SystemMouseCursors.basic);
  });
}
