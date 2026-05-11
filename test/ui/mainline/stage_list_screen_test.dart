import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/mainline_progress.dart';
import 'package:wuxia_idle/providers/mainline_providers.dart';
import 'package:wuxia_idle/ui/mainline/stage_list_screen.dart';
import 'package:wuxia_idle/ui/strings.dart';

/// T35 StageListScreen widget 测试。
///
/// 不接真实 Isar：mainlineProgressProvider override 为 fixture，
/// chapterStagesProvider 走真 service.availableStages（依赖 GameRepository）。
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

  Future<void> pumpScreen(
    WidgetTester tester, {
    required int chapterIndex,
    required MainlineProgress progress,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1024, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith((ref) async => progress),
        ],
        child: MaterialApp(home: StageListScreen(chapterIndex: chapterIndex)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Ch1 全新进度 → 01 可挑战 + 02 锁 + 提示文案', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    // 01 关名 + 02 关名都渲染
    expect(find.text('山道试剑'), findsOneWidget);
    expect(find.text('林间伏击'), findsOneWidget);

    // 01 是 available（chip 文案）；02 锁
    expect(find.text(UiStrings.stageListAvailable), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.text(UiStrings.stageListPrevHint), findsOneWidget,
        reason: '锁关卡显示「通关前一关解锁」副标题');
    expect(find.textContaining(UiStrings.stageListCleared), findsNothing);
  });

  testWidgets('Ch1 通过 01 → 01 cleared + 02 available', (tester) async {
    await pumpScreen(
      tester,
      chapterIndex: 1,
      progress: mkProgress(cleared: const ['mainline_test_01']),
    );

    expect(find.text(UiStrings.stageListCleared), findsOneWidget);
    expect(find.text(UiStrings.stageListAvailable), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('点 available 关卡 → 进入剧情阅读屏（T37 流程串联，缺文件走 placeholder）',
      (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    await tester.tap(find.text('山道试剑'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // runStageFlow → NarrativeLoader.load('mainline_test_01_opening')
    // widget test 中 rootBundle 不可用 → 兜底 placeholder → 推 NarrativeReaderScreen
    expect(find.textContaining('剧情占位'), findsOneWidget,
        reason: 'placeholder 弱提示标识进入了 NarrativeReaderScreen');
    expect(find.textContaining('mainline_test_01_opening'), findsOneWidget);
  });
}
