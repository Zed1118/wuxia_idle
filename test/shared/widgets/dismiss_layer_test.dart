import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/dismiss_layer.dart';

/// [DismissLayer] 行为锁:整屏跳过器必须**点击与键盘都能关**。
///
/// 立项背景(2026-07-30 桌面语义量测):过场题字/英雄镜头/拜入浮层/闭关题字/
/// 领悟浮层/闪屏 6 处此前只有裸 `GestureDetector.onTap`,零键盘处理——
/// 发布目标是 Windows,只用键盘的玩家跳不过过场。
void main() {
  Future<int> pumpAndSend(WidgetTester tester, LogicalKeyboardKey? key) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DismissLayer(
          onDismiss: () => count++,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    if (key != null) {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }
    return count;
  }

  testWidgets('Esc 关得掉', (tester) async {
    expect(await pumpAndSend(tester, LogicalKeyboardKey.escape), 1);
  });

  testWidgets('Enter 关得掉', (tester) async {
    expect(await pumpAndSend(tester, LogicalKeyboardKey.enter), 1);
  });

  testWidgets('空格关得掉', (tester) async {
    expect(await pumpAndSend(tester, LogicalKeyboardKey.space), 1);
  });

  testWidgets('小键盘回车关得掉', (tester) async {
    expect(await pumpAndSend(tester, LogicalKeyboardKey.numpadEnter), 1);
  });

  testWidgets('无关按键不触发(防误关)', (tester) async {
    expect(await pumpAndSend(tester, LogicalKeyboardKey.keyA), 0);
    expect(await pumpAndSend(tester, LogicalKeyboardKey.arrowLeft), 0);
    expect(await pumpAndSend(tester, LogicalKeyboardKey.tab), 0);
  });

  testWidgets('点击仍然关得掉(不能因为加键盘就把原来的点击弄丢)', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DismissLayer(
          onDismiss: () => count++,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    await tester.tap(find.byType(DismissLayer));
    await tester.pump();
    expect(count, 1);
  });

  testWidgets('autofocus:false 时不抢焦点(嵌进有真按钮的界面时用)', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(focusNode: node, autofocus: true, child: const Text('别处')),
            DismissLayer(
              autofocus: false,
              onDismiss: () {},
              child: const SizedBox(width: 10, height: 10),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });

  testWidgets('长按连发不重复触发(只吃 KeyDown,不吃 repeat/up)', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DismissLayer(
          onDismiss: () => count++,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    // sendKeyEvent = down + up 一整轮;抬起那半程不应再触发一次。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(count, 1);
  });
}
