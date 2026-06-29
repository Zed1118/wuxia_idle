import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/image_test_helpers.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('渲染 label 与 hint 两行', (tester) async {
    await tester.pumpWidget(
      host(const WuxiaInkButton(label: '主线', hint: '继续江湖路', onTap: null)),
    );
    expect(find.text('主线'), findsOneWidget);
    expect(find.text('继续江湖路'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsNothing);
  });

  testWidgets('icon 可选渲染为入口图标牌', (tester) async {
    await tester.pumpWidget(
      host(
        const WuxiaInkButton(
          label: '主线',
          hint: '继续江湖路',
          icon: Icons.map_outlined,
          onTap: null,
        ),
      ),
    );
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
  });

  testWidgets('thumbnailPath 渲染入口缩略图且保留图标', (tester) async {
    const path = 'assets/ui/mj/entry_mainline_story_01.png';
    await tester.pumpWidget(
      host(
        const WuxiaInkButton(
          label: '主线',
          hint: '继续江湖路',
          icon: Icons.map_outlined,
          thumbnailPath: path,
          onTap: null,
        ),
      ),
    );
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Image && assetNameOf(w.image) == path),
      findsOneWidget,
    );
  });

  testWidgets('点击触发 onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      host(WuxiaInkButton(label: '心法', hint: 'x', onTap: () => tapped++)),
    );
    await tester.tap(find.byType(WuxiaInkButton));
    expect(tapped, 1);
  });

  testWidgets('固定桌面热区且无 InkWell 水波纹', (tester) async {
    await tester.pumpWidget(
      host(WuxiaInkButton(label: '心法', hint: 'x', onTap: () {})),
    );
    final size = tester.getSize(find.byType(WuxiaInkButton));
    expect(size.height, greaterThanOrEqualTo(WuxiaInkButton.minHeight));
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('disabled 拦截点击且半透明 0.4', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      host(
        WuxiaInkButton(
          label: '门派',
          hint: 'x',
          onTap: () => tapped++,
          disabled: true,
        ),
      ),
    );
    await tester.tap(find.byType(WuxiaInkButton), warnIfMissed: false);
    expect(tapped, 0);
    final opacity = tester.widget<Opacity>(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.4),
    );
    expect(opacity.opacity, 0.4);
  });

  testWidgets('status chip 渲染且超长文本不会撑破', (tester) async {
    await tester.pumpWidget(
      host(
        const WuxiaInkButton(
          label: '问鼎',
          hint: 'x',
          status: '很长很长的状态说明文字',
          onTap: null,
        ),
      ),
    );
    final chip = find.text('很长很长的状态说明文字');
    expect(chip, findsOneWidget);
    expect(tester.getSize(chip).width, lessThanOrEqualTo(116));
  });

  testWidgets('Semantics 与键盘 Enter 激活', (tester) async {
    final handle = tester.ensureSemantics();
    var tapped = 0;
    await tester.pumpWidget(
      host(
        WuxiaInkButton(
          label: '心法',
          hint: 'x',
          onTap: () => tapped++,
          autofocus: true,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(WuxiaInkButton)),
      isSemantics(isButton: true, isEnabled: true),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tapped, 1);
    handle.dispose();
  });

  testWidgets('locked=true 显锁印图标 · false 不显', (tester) async {
    await tester.pumpWidget(
      host(
        const WuxiaInkButton(
          label: '门派',
          hint: 'x',
          onTap: null,
          disabled: true,
          locked: true,
        ),
      ),
    );
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    await tester.pumpWidget(
      host(const WuxiaInkButton(label: '主线', hint: 'x', onTap: null)),
    );
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}
