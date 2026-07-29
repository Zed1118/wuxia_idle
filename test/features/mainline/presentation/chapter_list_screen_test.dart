import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/chapter_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import '../../../support/test_data.dart';

/// T35 ChapterListScreen widget 测试。
///
/// 不接真实 Isar：mainlineProgressProvider 全 override 为 fixture。
/// setUpAll 加载 GameRepository（service.chapterCompleted 同步函数依赖
/// stageDefs；纯文件加载，与 Isar 无关）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  MainlineProgress mkProgress({List<String> cleared = const []}) {
    return MainlineProgress()
      ..saveDataId = 1
      ..currentChapterIndex = 1
      ..clearedStageIds = List.of(cleared)
      ..clearedAt = List.generate(cleared.length, (_) => DateTime(2026, 5, 11));
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    MainlineProgress p, {
    Size surfaceSize = const Size(1024, 5600),
  }) async {
    // 章节卡加封面条后变高,扩 viewport 让 20 卡全 build(memory
    // feedback_listview_widget_test_viewport;2026-07-28 Ch20 扩章随卡数抬 5300→5600)。
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mainlineProgressProvider.overrideWith((ref) async => p)],
        child: const MaterialApp(home: ChapterListScreen()),
      ),
    );
    await tester.pump(); // 让 FutureProvider 翻转
    await tester.pump();
  }

  List<String> clearedBeforeChapter(int chapterIndex) => [
    for (var chapter = 1; chapter < chapterIndex; chapter++)
      for (var stage = 1; stage <= 5; stage++)
        'stage_${chapter.toString().padLeft(2, '0')}_${stage.toString().padLeft(2, '0')}',
  ];

  testWidgets('全新进度 → 20 章卡渲染,Ch1 进行中 + Ch2-20 锁', (tester) async {
    await pumpScreen(tester, mkProgress());

    expect(find.text(UiStrings.mainlineRouteMapTitle), findsOneWidget);
    expect(find.text(UiStrings.mainlineRouteMapSubtitle), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text(UiStrings.mainlineRouteMapSubtitle),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        ),
      ),
      findsNothing,
      reason: '副标题必须固定在章节横滚区之外',
    );
    expect(find.text(UiStrings.chapter1Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter2Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter3Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter4Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter5Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter6Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter7Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter8Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter9Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter10Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter11Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter12Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter13Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter14Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter15Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter16Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter17Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter19Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter20Title), findsNWidgets(2));
    expect(find.text(UiStrings.chapter21Title), findsNWidgets(2));
    expect(find.text(UiStrings.mainlineRouteCurrent), findsOneWidget);
    expect(find.text(UiStrings.mainlineRouteLocked), findsNWidgets(20));

    expect(
      find.text(UiStrings.chapterStatusInProgress),
      findsOneWidget,
      reason: '只有 Ch1 进行中',
    );
    expect(find.byIcon(Icons.lock), findsNWidgets(20), reason: 'Ch2–Ch21 都锁');
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('Ch1 全通(5 关)→ Ch1 ✓ + Ch2 进行中 + Ch3-21 锁', (tester) async {
    await pumpScreen(
      tester,
      mkProgress(
        cleared: const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_03',
          'stage_01_04',
          'stage_01_05',
        ],
      ),
    );

    expect(
      find.byIcon(Icons.check_circle),
      findsOneWidget,
      reason: 'Ch1 cleared',
    );
    expect(
      find.text(UiStrings.chapterStatusInProgress),
      findsOneWidget,
      reason: 'Ch2 解锁进行中',
    );
    expect(find.byIcon(Icons.lock), findsNWidgets(19), reason: 'Ch3–Ch21 仍锁');
  });

  testWidgets('全 105 关通关 → 21 章都 ✓,无锁', (tester) async {
    final cleared = <String>[
      for (final ch in [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21, //
      ])
        for (final idx in [1, 2, 3, 4, 5])
          'stage_${ch.toString().padLeft(2, '0')}_0$idx',
    ];
    await pumpScreen(tester, mkProgress(cleared: cleared));

    expect(find.byIcon(Icons.check_circle), findsNWidgets(21));
    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.text(UiStrings.chapterStatusInProgress), findsNothing);
  });

  for (final surfaceSize in const [Size(1280, 720), Size(1440, 900)]) {
    testWidgets('${surfaceSize.width.toInt()}宽度 → 路引横滚无溢出且当前章自动可见', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        mkProgress(cleared: clearedBeforeChapter(16)),
        surfaceSize: surfaceSize,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final scroll = find.byKey(const ValueKey('chapter-route-scroll'));
      final currentPanel = find.byKey(const ValueKey('chapter-route-panel-16'));
      expect(scroll, findsOneWidget);
      expect(currentPanel, findsOneWidget);

      final viewportRect = tester.getRect(scroll);
      final currentPanelRect = tester.getRect(currentPanel);
      expect(
        currentPanelRect.left,
        greaterThanOrEqualTo(viewportRect.left - 1),
      );
      expect(currentPanelRect.right, lessThanOrEqualTo(viewportRect.right + 1));
    });
  }

  testWidgets('路引获得焦点后可用左右方向键横向浏览', (tester) async {
    await pumpScreen(tester, mkProgress(), surfaceSize: const Size(1280, 720));
    await tester.pumpAndSettle();

    final focusable = tester.widget<FocusableActionDetector>(
      find.byKey(const ValueKey('chapter-route-focus')),
    );
    focusable.focusNode!.requestFocus();
    await tester.pump();

    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('chapter-route-scroll')),
      matching: find.byType(Scrollable),
    );
    final scrollableState = tester.state<ScrollableState>(scrollable);
    expect(scrollableState.position.pixels, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(scrollableState.position.pixels, greaterThan(0));
  });
}
