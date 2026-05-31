import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/chapter_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// T35 ChapterListScreen widget 测试。
///
/// 不接真实 Isar：mainlineProgressProvider 全 override 为 fixture。
/// setUpAll 加载 GameRepository（service.chapterCompleted 同步函数依赖
/// stageDefs；纯文件加载，与 Isar 无关）。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  MainlineProgress mkProgress({List<String> cleared = const []}) {
    return MainlineProgress()
      ..saveDataId = 1
      ..currentChapterIndex = 1
      ..clearedStageIds = List.of(cleared)
      ..clearedAt = List.generate(cleared.length, (_) => DateTime(2026, 5, 11));
  }

  Future<void> pumpScreen(WidgetTester tester, MainlineProgress p) async {
    // 章节卡加封面条后变高,扩 viewport 让 6 卡全 build(memory
    // feedback_listview_widget_test_viewport)。
    await tester.binding.setSurfaceSize(const Size(1024, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith((ref) async => p),
        ],
        child: const MaterialApp(home: ChapterListScreen()),
      ),
    );
    await tester.pump(); // 让 FutureProvider 翻转
    await tester.pump();
  }

  testWidgets('全新进度 → 6 章卡渲染,Ch1 进行中 + Ch2/3/4/5/6 锁', (tester) async {
    await pumpScreen(tester, mkProgress());

    expect(find.text(UiStrings.chapter1Title), findsOneWidget);
    expect(find.text(UiStrings.chapter2Title), findsOneWidget);
    expect(find.text(UiStrings.chapter3Title), findsOneWidget);
    expect(find.text(UiStrings.chapter4Title), findsOneWidget);
    expect(find.text(UiStrings.chapter5Title), findsOneWidget);
    expect(find.text(UiStrings.chapter6Title), findsOneWidget);

    expect(find.text(UiStrings.chapterStatusInProgress), findsOneWidget,
        reason: '只有 Ch1 进行中');
    expect(find.byIcon(Icons.lock), findsNWidgets(5),
        reason: 'Ch2 + Ch3 + Ch4 + Ch5 + Ch6 都锁');
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('Ch1 全通(5 关)→ Ch1 ✓ + Ch2 进行中 + Ch3/4/5/6 锁', (tester) async {
    await pumpScreen(
      tester,
      mkProgress(cleared: const [
        'stage_01_01',
        'stage_01_02',
        'stage_01_03',
        'stage_01_04',
        'stage_01_05',
      ]),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget,
        reason: 'Ch1 cleared');
    expect(find.text(UiStrings.chapterStatusInProgress), findsOneWidget,
        reason: 'Ch2 解锁进行中');
    expect(find.byIcon(Icons.lock), findsNWidgets(4),
        reason: 'Ch3 + Ch4 + Ch5 + Ch6 仍锁');
  });

  testWidgets('全 30 关通关 → 6 章都 ✓,无锁', (tester) async {
    final cleared = <String>[
      for (final ch in [1, 2, 3, 4, 5, 6])
        for (final idx in [1, 2, 3, 4, 5]) 'stage_0${ch}_0$idx',
    ];
    await pumpScreen(tester, mkProgress(cleared: cleared));

    expect(find.byIcon(Icons.check_circle), findsNWidgets(6));
    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.text(UiStrings.chapterStatusInProgress), findsNothing);
  });
}
