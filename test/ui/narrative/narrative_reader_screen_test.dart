import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';
import 'package:wuxia_idle/ui/narrative/narrative_reader_screen.dart';

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
    final c = NarrativeContent.placeholder('mainline_test_01_opening');
    await tester.pumpWidget(wrap(NarrativeReaderScreen(
      content: c,
      fallbackTitle: '关卡名',
    )));

    expect(find.textContaining('剧情占位'), findsOneWidget);
    expect(find.textContaining('mainline_test_01_opening'), findsOneWidget);
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
}
