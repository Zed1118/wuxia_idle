import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';
import 'package:wuxia_idle/features/narrative/presentation/narrative_reader_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// T36 NarrativeReaderScreen widget 测试。
void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('多段渲染：首段可见 + 「继续」推进到第二段', (tester) async {
    const c = NarrativeContent(
      id: 'x',
      title: '测试章',
      paragraphs: ['第一段', '第二段', '第三段'],
      isPlaceholder: false,
    );
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c,
      fallbackTitle: 'fallback',
    )));

    expect(find.text('测试章'), findsOneWidget);
    expect(find.text('第一段'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('继续'), findsOneWidget);

    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('第二段'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('最后一段按钮变「完成」+ 点击触发 onFinish + pop', (tester) async {
    var finished = false;
    const c = NarrativeContent(
      id: 'x',
      title: null,
      paragraphs: ['只有一段'],
      isPlaceholder: false,
    );
    await tester.pumpWidget(wrap(Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
          builder: (_) => NarrativeReaderScreen(
            content: c,
            fallbackTitle: '兜底标题',
            onFinish: () => finished = true,
          ),
        )),
        child: const Text('open'),
      );
    })));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('兜底标题'), findsOneWidget,
        reason: 'content.title 为 null 时用 fallbackTitle');
    expect(find.text('完成'), findsOneWidget,
        reason: '只有 1 段，首段就是末段');

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    expect(finished, isTrue, reason: 'onFinish 被回调');
    expect(find.text('完成'), findsNothing, reason: '已 pop 回 open 页');
  });

  testWidgets('placeholder 顶部弱提示「⚠ 剧情占位」可见', (tester) async {
    final c = NarrativeContent.placeholder('stage_01_01_opening');
    await tester.pumpWidget(wrap(NarrativeReaderScreen(
      content: c,
      fallbackTitle: '关卡名',
    )));

    expect(find.textContaining('剧情占位'), findsOneWidget);
    expect(find.textContaining('stage_01_01_opening'), findsOneWidget);
  });

  testWidgets('Phase 4 W10 · topBanner 参数：传入则在剧情上方渲染，不传则不存在', (tester) async {
    const c = NarrativeContent(
      id: 'defeat',
      title: '风雨渡口 · 败',
      paragraphs: ['撑伞的人没有追。'],
      isPlaceholder: false,
    );
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c,
      fallbackTitle: 'fb',
      topBanner: Padding(
        padding: EdgeInsets.all(8),
        child: Text('LOSS_BANNER_MARKER'),
      ),
    )));
    expect(find.text('LOSS_BANNER_MARKER'), findsOneWidget,
        reason: 'topBanner 应渲染到剧情上方');
    expect(find.text('撑伞的人没有追。'), findsOneWidget);

    // 不传 topBanner 时不存在
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c,
      fallbackTitle: 'fb',
    )));
    expect(find.text('LOSS_BANNER_MARKER'), findsNothing);
  });

  testWidgets('「跳过」按钮直接 finish + pop', (tester) async {
    var finished = false;
    const c = NarrativeContent(
      id: 'x',
      title: '长',
      paragraphs: ['段1', '段2', '段3', '段4', '段5'],
      isPlaceholder: false,
    );
    await tester.pumpWidget(wrap(Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
          builder: (_) => NarrativeReaderScreen(
            content: c,
            fallbackTitle: 'fb',
            onFinish: () => finished = true,
          ),
        )),
        child: const Text('open'),
      );
    })));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('段1'), findsOneWidget);

    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(find.text('段1'), findsNothing);
  });

  // ── P1 #42 Phase 2 §10 P1.x · mandatory 隐藏「跳过」按钮 ─────────────────

  testWidgets('mandatory=false(默认)→「跳过」按钮可见', (tester) async {
    const c = NarrativeContent(
      id: 'x',
      title: '普通',
      paragraphs: ['段落 A', '段落 B'],
      isPlaceholder: false,
    );
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c,
      fallbackTitle: 'fb',
    )));
    expect(find.text('跳过'), findsOneWidget);
  });

  testWidgets('mandatory=true → 「跳过」按钮不可见(强制引导)', (tester) async {
    const c = NarrativeContent(
      id: 'tutorial',
      title: '师父教学',
      paragraphs: ['段落 A', '段落 B'],
      isPlaceholder: false,
      mandatory: true,
    );
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c,
      fallbackTitle: 'fb',
    )));
    expect(find.text('跳过'), findsNothing);
    expect(find.text('段落 A'), findsOneWidget,
        reason: '首段正常渲染,只 Skip 按钮被隐');
  });

  testWidgets('mandatory=true + 中段「继续」仍可推进', (tester) async {
    const c = NarrativeContent(
      id: 'tutorial',
      title: '强制章',
      paragraphs: ['段 A', '段 B', '段 C'],
      isPlaceholder: false,
      mandatory: true,
    );
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c,
      fallbackTitle: 'fb',
    )));
    expect(find.text('继续'), findsOneWidget);
    expect(find.text('跳过'), findsNothing);

    await tester.tap(find.text('继续'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('段 B'), findsOneWidget);
  });

  testWidgets('mandatory=true + 末段「完成」按钮触发 onFinish + pop',
      (tester) async {
    var finished = false;
    const c = NarrativeContent(
      id: 'tutorial',
      title: '末段强制',
      paragraphs: ['只一段'],
      isPlaceholder: false,
      mandatory: true,
    );
    await tester.pumpWidget(wrap(Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
          builder: (_) => NarrativeReaderScreen(
            content: c,
            fallbackTitle: 'fb',
            onFinish: () => finished = true,
          ),
        )),
        child: const Text('open'),
      );
    })));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('完成'), findsOneWidget);
    expect(find.text('跳过'), findsNothing,
        reason: 'mandatory 末段不显跳过');

    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });

  testWidgets('轻点正文区 → 推进到下一段(VN 式 tap-to-advance)', (tester) async {
    const c = NarrativeContent(
      id: 'x',
      title: '测试章',
      paragraphs: ['第一段', '第二段'],
      isPlaceholder: false,
    );
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c,
      fallbackTitle: 'fb',
    )));
    expect(find.text('第一段'), findsOneWidget);

    await tester.tap(find.text('第一段'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('第二段'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('首段显轻点提示,推进后隐藏(§5.7 提示一次)', (tester) async {
    const c = NarrativeContent(
      id: 'x',
      title: '测试章',
      paragraphs: ['第一段', '第二段'],
      isPlaceholder: false,
    );
    await tester.pumpWidget(wrap(const NarrativeReaderScreen(
      content: c,
      fallbackTitle: 'fb',
    )));
    expect(find.text(UiStrings.narrativeReaderTapHint), findsOneWidget);

    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(UiStrings.narrativeReaderTapHint), findsNothing);
  });
}
