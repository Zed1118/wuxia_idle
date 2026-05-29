import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/narrative_loader.dart';
import 'package:wuxia_idle/features/mainline/presentation/chapter_transition_screen.dart';

/// H2 小套餐 C1:章节翻篇过场屏。把 prologue/epilogue 这批 dead content
/// 接进可达 UI。loadOverride 注入避免依赖 rootBundle assets。
void main() {
  Widget host(ChapterTransitionScreen screen) => MaterialApp(home: screen);

  const sample = ChapterNarrative(
    id: 'chapter_01',
    title: '学武出山',
    prologue: '庆元三年，江南。\n少年姓李，单名一个寒字。',
    epilogue: '路还很长。',
    isPlaceholder: false,
  );

  testWidgets('showEpilogue=false → 显卷首,不显卷尾', (tester) async {
    await tester.pumpWidget(host(ChapterTransitionScreen(
      chapterIndex: 1,
      showEpilogue: false,
      loadOverride: (_) async => sample,
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('庆元三年'), findsOneWidget);
    expect(find.textContaining('路还很长'), findsNothing,
        reason: '章节未通关,卷尾不应解锁');
  });

  testWidgets('showEpilogue=true → 卷首 + 卷尾都显', (tester) async {
    await tester.pumpWidget(host(ChapterTransitionScreen(
      chapterIndex: 1,
      showEpilogue: true,
      loadOverride: (_) async => sample,
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('庆元三年'), findsOneWidget);
    expect(find.textContaining('路还很长'), findsOneWidget);
  });

  testWidgets('placeholder → 弱提示,不崩', (tester) async {
    await tester.pumpWidget(host(ChapterTransitionScreen(
      chapterIndex: 9,
      showEpilogue: true,
      loadOverride: (_) async => ChapterNarrative.placeholder('chapter_09'),
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('庆元三年'), findsNothing);
  });
}
