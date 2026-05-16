import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

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

  testWidgets('Ch1 全新进度 → 5 关渲染：01 可挑战 + 02-05 全锁', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    // Ch1 5 关全名渲染
    expect(find.text('山门之外'), findsOneWidget);
    expect(find.text('荒山野店'), findsOneWidget);
    expect(find.text('黑风岭'), findsOneWidget);
    expect(find.text('洛阳城外'), findsOneWidget);
    expect(find.text('风雨渡口'), findsOneWidget);

    // 01 是 available（chip 文案）；02-05 锁（4 个锁图标）
    expect(find.text(UiStrings.stageListAvailable), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(4));
    expect(find.text(UiStrings.stageListPrevHint), findsNWidgets(4),
        reason: '锁关卡显示「通关前一关解锁」副标题');
    expect(find.textContaining(UiStrings.stageListCleared), findsNothing);
  });

  testWidgets('Ch1 通过 01 → 01 cleared + 02 available + 03-05 锁', (tester) async {
    await pumpScreen(
      tester,
      chapterIndex: 1,
      progress: mkProgress(cleared: const ['stage_01_01']),
    );

    expect(find.text(UiStrings.stageListCleared), findsOneWidget);
    expect(find.text(UiStrings.stageListAvailable), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(3));
  });

  testWidgets('点 available 关卡 → 进入剧情阅读屏（T37 流程串联，P1 #1 真实剧情加载）',
      (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    await tester.tap(find.text('山门之外'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // runStageFlow → NarrativeLoader.load('stage_01_01_opening')
    // P1 #1 后 NarrativeLoader 扫 data/narratives/stages/ 子目录，
    // widget test 中 rootBundle 能读到 pubspec 声明的真实 asset →
    // 加载 DeepSeek 写的「山门之外 · 启」，不走 placeholder
    expect(find.textContaining('剧情占位'), findsNothing,
        reason: 'P1 #1 narrative schema 对齐后真实文案已可加载，不再兜底');
    expect(find.text('山门之外 · 启'), findsOneWidget,
        reason: 'DeepSeek narrative title 渲染（stage_01_01_opening.yaml）');
  });
}
