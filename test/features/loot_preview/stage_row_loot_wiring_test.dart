// test/features/loot_preview/stage_row_loot_wiring_test.dart
//
// Task 8: 验证 _StageRow 正确接入掉落传闻简版行 + info 角标。
// 通过 StageListScreen 端到端渲染（镜像 stage_list_screen_test.dart 模式）。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

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
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
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

  testWidgets('关卡行显示掉落传闻简版行（有掉落显前缀，无掉落显占位）', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    // stage_01_01 无 dropTable → 应显「本关无固定收获」；其他关卡有掉落显前缀。
    // 至少一行掉落传闻文案（前缀 OR 无固定收获）出现 5 次（5 关各一行）。
    final summaryCount = tester
            .widgetList(find.textContaining(UiStrings.lootSummaryPrefix))
            .length +
        tester
            .widgetList(find.textContaining(UiStrings.lootNoFixedDrop))
            .length;
    expect(summaryCount, greaterThanOrEqualTo(5),
        reason: '5 关每关都应渲染一行掉落传闻（前缀 or 无固定收获）');
  });

  testWidgets('点击 info 角标 → 弹出「本关传闻」对话框', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    // 找到第一个 info 角标并点击
    await tester.tap(find.byIcon(Icons.info_outline).first);
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.lootRumorDialogTitle), findsOneWidget,
        reason: '点击 info 角标后应弹出掉落传闻对话框');
  });
}
