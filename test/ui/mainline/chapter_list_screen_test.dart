import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/mainline_progress.dart';
import 'package:wuxia_idle/providers/mainline_providers.dart';
import 'package:wuxia_idle/ui/mainline/chapter_list_screen.dart';
import 'package:wuxia_idle/ui/strings.dart';

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
    await tester.binding.setSurfaceSize(const Size(1024, 720));
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

  testWidgets('全新进度 → 3 章卡渲染，Ch1 进行中 + Ch2/3 锁', (tester) async {
    await pumpScreen(tester, mkProgress());

    expect(find.text(UiStrings.chapter1Title), findsOneWidget);
    expect(find.text(UiStrings.chapter2Title), findsOneWidget);
    expect(find.text(UiStrings.chapter3Title), findsOneWidget);

    expect(find.text(UiStrings.chapterStatusInProgress), findsOneWidget,
        reason: '只有 Ch1 进行中');
    expect(find.byIcon(Icons.lock), findsNWidgets(2),
        reason: 'Ch2 + Ch3 都锁');
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('Ch1 全通 → Ch1 ✓ + Ch2 进行中 + Ch3 锁', (tester) async {
    await pumpScreen(
      tester,
      mkProgress(cleared: ['stage_01_01', 'stage_01_02']),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget,
        reason: 'Ch1 cleared');
    expect(find.text(UiStrings.chapterStatusInProgress), findsOneWidget,
        reason: 'Ch2 解锁进行中');
    expect(find.byIcon(Icons.lock), findsOneWidget, reason: 'Ch3 仍锁');
  });

  testWidgets('全 6 关通关 → 3 章都 ✓，无锁', (tester) async {
    await pumpScreen(
      tester,
      mkProgress(cleared: const [
        'stage_01_01',
        'stage_01_02',
        'stage_02_01',
        'stage_02_02',
        'stage_03_01',
        'stage_03_02',
      ]),
    );

    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.text(UiStrings.chapterStatusInProgress), findsNothing);
  });
}
