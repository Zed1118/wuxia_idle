import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/battle/presentation/stage_auto_play_control.dart';
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

  MainlineProgress mkProgress({
    List<String> cleared = const [],
    List<String> clearedStageCycleKeys = const [],
    List<String> clearedChapterCycleKeys = const [],
  }) {
    return MainlineProgress()
      ..saveDataId = 1
      ..currentChapterIndex = 1
      ..clearedStageIds = List.of(cleared)
      ..clearedStageCycleKeys = List.of(clearedStageCycleKeys)
      ..clearedChapterCycleKeys = List.of(clearedChapterCycleKeys)
      ..clearedAt = List.generate(cleared.length, (_) => DateTime(2026, 5, 11));
  }

  Character mkCharacter({required RealmTier realm}) {
    return Character.create(
      name: 'test hero',
      realmTier: realm,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 5, 11),
    )..id = 7;
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required int chapterIndex,
    required MainlineProgress progress,
    Character? activeCharacter,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith((ref) async => progress),
          if (activeCharacter != null) ...[
            activeCharacterIdsProvider.overrideWith(
              (ref) async => [activeCharacter.id],
            ),
            characterByIdProvider(
              activeCharacter.id,
            ).overrideWith((ref) async => activeCharacter),
          ],
        ],
        child: MaterialApp(home: StageListScreen(chapterIndex: chapterIndex)),
      ),
    );
    await tester.pump();
    await tester.pump();
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
    expect(
      find.text(UiStrings.stageListPrevHint),
      findsNWidgets(4),
      reason: '锁关卡显示「通关前一关解锁」副标题',
    );
    expect(find.textContaining(UiStrings.stageListCleared), findsNothing);
  });

  testWidgets('关卡列表以章节轴呈现并保留原关卡状态', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    expect(find.text(UiStrings.stageListTimelineTitle), findsOneWidget);
    expect(find.text(UiStrings.stageListTimelineHint), findsOneWidget);
    expect(find.text('山门之外'), findsOneWidget);
    expect(find.text(UiStrings.stageListAvailable), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(4));
  });

  testWidgets('Ch1 通过 01 → 01 cleared + 02 available + 03-05 锁', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      chapterIndex: 1,
      progress: mkProgress(cleared: const ['stage_01_01']),
    );

    expect(find.text(UiStrings.stageListCleared), findsOneWidget);
    expect(find.text(UiStrings.stageListAvailable), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(3));
    // 逐关「战斗方式」覆盖 chip 已移除(2026-06-26):已通关关卡不再显该控件。
    expect(
      find.byType(StageAutoPlayControl),
      findsNothing,
      reason: '逐关战斗方式 chip 已删,全局开关在设置面板',
    );
    expect(find.text(UiStrings.stageReplayRouteTitle), findsOneWidget);
    expect(find.text(UiStrings.stageReplayRouteEquipment), findsOneWidget);
    expect(find.text(UiStrings.stageReplayRouteMaterial), findsOneWidget);
  });

  testWidgets('未通关主线行不显示重打收益路线', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    expect(find.text(UiStrings.chapterFarmSpotsTitle), findsNothing);
    expect(find.text(UiStrings.stageReplayRouteTitle), findsNothing);
    expect(find.text(UiStrings.stageReplayRouteEquipment), findsNothing);
    expect(find.text(UiStrings.stageReplayRouteMaterial), findsNothing);
    expect(find.text(UiStrings.stageReplayRouteProficiency), findsNothing);
  });

  testWidgets('选择二周目后关卡行显示敌人词条摘要', (tester) async {
    await pumpScreen(
      tester,
      chapterIndex: 1,
      progress: mkProgress(
        cleared: const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_03',
          'stage_01_04',
          'stage_01_05',
        ],
        clearedStageCycleKeys: const [
          'stage_01_01#1',
          'stage_01_02#1',
          'stage_01_03#1',
          'stage_01_04#1',
          'stage_01_05#1',
        ],
        clearedChapterCycleKeys: const ['ch1#1'],
      ),
    );

    expect(find.textContaining('御体 ·'), findsNothing);

    await tester.tap(find.text(UiStrings.cycleChallengeNextLabel(2)));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('御体 ·'), findsWidgets);
    expect(find.textContaining('真气 ·'), findsWidgets);
  });

  testWidgets('章节未全通 → 不显示章节推荐刷点', (tester) async {
    await pumpScreen(
      tester,
      chapterIndex: 1,
      progress: mkProgress(cleared: const ['stage_01_01']),
    );

    expect(find.text(UiStrings.chapterFarmSpotsTitle), findsNothing);
    expect(find.text(UiStrings.chapterFarmSpotsHint), findsNothing);
  });

  testWidgets('章节全通 → 显示最多两个章节推荐刷点', (tester) async {
    await pumpScreen(
      tester,
      chapterIndex: 1,
      progress: mkProgress(
        cleared: const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_03',
          'stage_01_04',
          'stage_01_05',
        ],
      ),
    );

    expect(find.text(UiStrings.chapterFarmSpotsTitle), findsOneWidget);
    expect(find.text(UiStrings.chapterFarmSpotsHint), findsOneWidget);
    expect(find.text(UiStrings.chapterFarmSpotStage(5)), findsOneWidget);
    expect(find.text('风雨渡口'), findsNWidgets(2));
    expect(find.text(UiStrings.stageReplayRouteProficiency), findsWidgets);
  });

  testWidgets('已通关 Boss 行显示练熟练度路线', (tester) async {
    await pumpScreen(
      tester,
      chapterIndex: 1,
      progress: mkProgress(
        cleared: const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_03',
          'stage_01_04',
          'stage_01_05',
        ],
      ),
    );

    expect(find.text(UiStrings.stageReplayRouteTitle), findsWidgets);
    expect(find.text(UiStrings.stageReplayRouteProficiency), findsWidgets);
  });

  testWidgets('整章可扫荡时显示扫荡前收益预估', (tester) async {
    final progress =
        mkProgress(
            cleared: const [
              'stage_01_01',
              'stage_01_02',
              'stage_01_03',
              'stage_01_04',
              'stage_01_05',
            ],
          )
          ..clearedStageCycleKeys = const [
            'stage_01_01#1',
            'stage_01_02#1',
            'stage_01_03#1',
            'stage_01_04#1',
            'stage_01_05#1',
          ]
          ..clearedChapterCycleKeys = const ['ch1#1'];

    await pumpScreen(tester, chapterIndex: 1, progress: progress);

    expect(find.text(UiStrings.sweepPreviewTitle), findsOneWidget);
    expect(find.text(UiStrings.stageReplayRouteEquipment), findsWidgets);
    expect(
      find.textContaining(UiStrings.sweepPreviewDropsPrefix),
      findsOneWidget,
    );
    expect(
      find.textContaining(UiStrings.sweepPreviewProficiencyPrefix),
      findsOneWidget,
    );
    expect(
      find.textContaining(UiStrings.sweepPreviewMaterialHitsPrefix),
      findsOneWidget,
    );
  });

  testWidgets('当前周目不可扫荡时不显示收益预估', (tester) async {
    await pumpScreen(
      tester,
      chapterIndex: 1,
      progress: mkProgress(cleared: const ['stage_01_01']),
    );

    expect(find.text(UiStrings.sweepPreviewTitle), findsNothing);
    expect(
      find.textContaining(UiStrings.sweepPreviewMaterialHitsPrefix),
      findsNothing,
    );
  });

  testWidgets('关卡行显示推荐整备条：推荐境界 + 判语 + 补强方向', (tester) async {
    await pumpScreen(
      tester,
      chapterIndex: 3,
      progress: mkProgress(
        cleared: const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_03',
          'stage_01_04',
          'stage_01_05',
          'stage_02_01',
          'stage_02_02',
          'stage_02_03',
          'stage_02_04',
          'stage_02_05',
        ],
      ),
      activeCharacter: mkCharacter(realm: RealmTier.sanLiu),
    );

    expect(find.text(UiStrings.stagePrepareLabel), findsWidgets);
    expect(find.text(UiStrings.stagePrepareRecommended('二流')), findsWidgets);
    expect(find.text(UiStrings.difficultyRisky), findsWidgets);
    expect(find.text(UiStrings.stagePrepareLoadoutGap(1)), findsWidgets);
    expect(
      find.byIcon(Icons.info_outline),
      findsWidgets,
      reason: '整备条不应替代或遮挡本关传闻 info 入口',
    );
  });

  testWidgets('点 available 关卡 → 进入剧情阅读屏（T37 流程串联，P1 #1 真实剧情加载）', (
    tester,
  ) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    await tester.tap(find.text('山门之外'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // runStageFlow → NarrativeLoader.load('stage_01_01_opening')
    // P1 #1 后 NarrativeLoader 扫 data/narratives/stages/ 子目录，
    // widget test 中 rootBundle 能读到 pubspec 声明的真实 asset →
    // 加载 DeepSeek 写的「山门之外 · 启」，不走 placeholder
    expect(
      find.textContaining('剧情占位'),
      findsNothing,
      reason: 'P1 #1 narrative schema 对齐后真实文案已可加载，不再兜底',
    );
    expect(
      find.text('山门之外 · 启'),
      findsOneWidget,
      reason: 'DeepSeek narrative title 渲染（stage_01_01_opening.yaml）',
    );
  });

  testWidgets('点行尾 info 图标 → 弹战前情报（含敌阵段）而非纯掉落', (tester) async {
    await pumpScreen(tester, chapterIndex: 1, progress: mkProgress());

    await tester.tap(find.byIcon(Icons.info_outline).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(UiStrings.prebattleIntelEnemySection),
      findsOneWidget,
      reason: 'info 图标升级为战前情报入口，含行内没有的敌阵详列',
    );
  });
}
