import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/app_exit.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/paper_dialog.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';

void main() {
  late int quitCalls;

  setUp(() {
    quitCalls = 0;
    AppExit.quit = () => quitCalls++;
  });

  tearDown(() {
    // 复位成 no-op,避免后续测试误触真退出。
    AppExit.quit = () {};
  });

  testWidgets('退出入口弹二次确认框,不立即退出', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Host()));
    await tester.tap(find.text('quit'));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.quitConfirmMessage), findsOneWidget);
    expect(find.byType(PaperDialog), findsOneWidget);
    expect(find.byType(PlaqueButton), findsNWidgets(2));
    expect(quitCalls, 0);
  });

  testWidgets('确认框点「再想想」关闭且不退出', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Host()));
    await tester.tap(find.text('quit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.quitCancelAction));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.quitConfirmMessage), findsNothing);
    expect(quitCalls, 0);
  });

  testWidgets('确认框点「退出」调用 quit', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Host()));
    await tester.tap(find.text('quit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.quitConfirmAction));
    await tester.pumpAndSettle();

    expect(quitCalls, 1);
  });
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => AppExit.confirmAndQuit(ctx),
          child: const Text('quit'),
        ),
      ),
    );
  }
}
