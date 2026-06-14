import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/auto_play_toggle.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('override=null + globalDefault=true → 显示「自动」+「随设置」弱标记',
      (tester) async {
    await tester.pumpWidget(_host(AutoPlayToggle(
      overrideMode: null,
      globalDefault: true,
      onChanged: (_) {},
    )));
    expect(find.text(UiStrings.stageAutoPlayAuto), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayFollowSuffix), findsOneWidget);
    // 印章 glyph:挂机自动态显「自」字朱印
    expect(find.text(UiStrings.stageAutoPlaySealAuto), findsOneWidget);
  });

  testWidgets('override=false → 显示「拖招」且无「随设置」标记(已 pin 不跟随)',
      (tester) async {
    await tester.pumpWidget(_host(AutoPlayToggle(
      overrideMode: false,
      globalDefault: true,
      onChanged: (_) {},
    )));
    expect(find.text(UiStrings.stageAutoPlayManual), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayFollowSuffix), findsNothing);
    // 印章 glyph:允许拖招态显「拖」字朱印
    expect(find.text(UiStrings.stageAutoPlaySealManual), findsOneWidget);
  });

  testWidgets('点击 → 弹三选项菜单(跟随/挂机自动/允许拖招)', (tester) async {
    await tester.pumpWidget(_host(AutoPlayToggle(
      overrideMode: null,
      globalDefault: true,
      onChanged: (_) {},
    )));
    await tester.tap(find.byType(AutoPlayToggle));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.stageAutoPlayMenuFollow), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayMenuAuto), findsOneWidget);
    expect(find.text(UiStrings.stageAutoPlayMenuManual), findsOneWidget);
  });

  testWidgets('选「允许拖招」→ onChanged(false)', (tester) async {
    bool? captured;
    var called = false;
    await tester.pumpWidget(_host(AutoPlayToggle(
      overrideMode: null,
      globalDefault: true,
      onChanged: (v) {
        called = true;
        captured = v;
      },
    )));
    await tester.tap(find.byType(AutoPlayToggle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.stageAutoPlayMenuManual));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(captured, isFalse);
  });

  testWidgets('选「跟随设置」→ onChanged(null)(回到跟随态,非 null 哨兵丢回调)',
      (tester) async {
    bool? captured = true;
    var called = false;
    await tester.pumpWidget(_host(AutoPlayToggle(
      overrideMode: true,
      globalDefault: true,
      onChanged: (v) {
        called = true;
        captured = v;
      },
    )));
    await tester.tap(find.byType(AutoPlayToggle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.stageAutoPlayMenuFollow));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(captured, isNull);
  });
}
