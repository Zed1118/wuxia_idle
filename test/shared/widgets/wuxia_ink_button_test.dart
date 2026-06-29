import 'package:flutter/material.dart';
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

  testWidgets('Semantics 标记入口为 button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const WuxiaInkButton(label: '主线', hint: '继续江湖路', onTap: null)),
    );
    expect(
      tester.getSemantics(find.byType(WuxiaInkButton)),
      isSemantics(isButton: true, isEnabled: true),
    );
    handle.dispose();
  });

  testWidgets('icon 入口真实 hitbox 高度不低于 76px', (tester) async {
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
    expect(
      tester.getSize(find.byType(WuxiaInkButton)).height,
      greaterThanOrEqualTo(76),
    );
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
