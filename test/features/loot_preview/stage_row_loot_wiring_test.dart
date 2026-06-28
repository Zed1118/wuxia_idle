// test/features/loot_preview/stage_row_loot_wiring_test.dart
//
// Task 8: 验证 _StageRow 正确接入掉落传闻简版行 + info 角标。
// 通过 StageListScreen 端到端渲染（镜像 stage_list_screen_test.dart 模式）。
import 'dart:io';

import 'package:flutter/gestures.dart';
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
    // 高度足够容纳全部关卡行，避免列表滚动截断 LootSummaryLine。
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

  testWidgets('关卡行显示行内推荐境界与掉落传闻', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    expect(
      tester
          .widgetList(
            find.textContaining(UiStrings.previewRecommendedRealmLabel),
          )
          .length,
      greaterThanOrEqualTo(5),
      reason: '5 关每关都应直接渲染推荐境界',
    );
    expect(
      find.textContaining(UiStrings.lootBucketChangKeDe),
      findsWidgets,
      reason: '行内掉落传闻应显示分桶文字，不再只显示「可能收获」前缀',
    );

    // 主线关卡行不应出现仅属于爬塔首通必得 bucket 的标签。
    expect(find.text(UiStrings.lootBucketShouTongBiDe), findsNothing);
  });

  testWidgets('关卡标题区直接显示推荐境界与分桶掉落，悬停不再弹预览浮层', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    expect(
      find.textContaining(UiStrings.previewRecommendedRealmLabel),
      findsWidgets,
      reason: '推荐境界应直接显示在每个关卡行标题区域内，而不是只在悬浮预览里',
    );
    expect(
      find.textContaining(UiStrings.lootBucketChangKeDe),
      findsWidgets,
      reason: '掉落爆率分桶应直接显示在关卡行内，不依赖悬浮预览',
    );
    expect(
      find.text(UiStrings.previewRareBonusHint),
      findsNothing,
      reason: '旧悬浮预览内容不应常驻显示',
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('山门之外')));
    await tester.pumpAndSettle();

    expect(
      find.text(UiStrings.previewRareBonusHint),
      findsNothing,
      reason: '关卡行悬停不应再弹出独立掉落/推荐境界浮层',
    );
  });

  testWidgets('点击 info 角标 → 弹出「本关传闻」对话框', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    // 找到第一个 info 角标并点击
    await tester.tap(find.byIcon(Icons.info_outline).first);
    await tester.pumpAndSettle();

    expect(
      find.text(UiStrings.lootRumorDialogTitle),
      findsOneWidget,
      reason: '点击 info 角标后应弹出掉落传闻对话框',
    );
  });
}
