import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/chapter_list_screen.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  MainlineProgress progressWithCleared(Iterable<String> stageIds) =>
      MainlineProgress()..clearedStageIds = stageIds.toList(growable: false);

  test('继续江湖按生产解锁链解析当前下一关', () {
    final stage = resolveContinueJianghuStage(
      progressWithCleared(['stage_01_01']),
    );

    expect(stage?.id, 'stage_01_02');
  });

  test('前十五章全通后继续解析第十六章，不把真实 21 章误报完成', () {
    final cleared = GameRepository.instance.stageDefs.values
        .where(
          (stage) =>
              stage.stageType == StageType.mainline &&
              stage.chapterIndex != null &&
              stage.chapterIndex! <= 15,
        )
        .map((stage) => stage.id);

    final stage = resolveContinueJianghuStage(progressWithCleared(cleared));

    expect(stage?.id, 'stage_16_01');
  });

  test('21 章主线全通后没有首次推进目标', () {
    final cleared = GameRepository.instance.stageDefs.values
        .where((stage) => stage.stageType == StageType.mainline)
        .map((stage) => stage.id);

    expect(resolveContinueJianghuStage(progressWithCleared(cleared)), isNull);
  });

  testWidgets('点击继续江湖把当前关交给生产直达执行器', (tester) async {
    String? launchedStageId;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) async => progressWithCleared(['stage_01_01']),
          ),
          activeRetreatSessionProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          home: MainMenu(
            continueJianghuRunnerForTest: (context, ref, stage) async {
              launchedStageId = stage.id;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(UiStrings.mainMenuMainline, '继续江湖');
    await tester.tap(find.text(UiStrings.mainMenuMainline));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(launchedStageId, 'stage_01_02');
    expect(find.byType(MainMenu), findsOneWidget);
  });

  testWidgets('第十六章当前关同步显示在入口状态，不再硬编码十五章', (tester) async {
    final cleared = GameRepository.instance.stageDefs.values
        .where(
          (stage) =>
              stage.stageType == StageType.mainline &&
              stage.chapterIndex != null &&
              stage.chapterIndex! <= 15,
        )
        .map((stage) => stage.id);
    final stage = GameRepository.instance.getStage('stage_16_01');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) async => progressWithCleared(cleared),
          ),
        ],
        child: const MaterialApp(home: MainMenu()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(UiStrings.mainMenuMainlineStatus(16, stage.name)),
      findsOneWidget,
    );
  });

  testWidgets('全主线已通时继续江湖回退章节地图，保留重打入口', (tester) async {
    final cleared = GameRepository.instance.stageDefs.values
        .where((stage) => stage.stageType == StageType.mainline)
        .map((stage) => stage.id);
    var directRunnerCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) async => progressWithCleared(cleared),
          ),
          activeRetreatSessionProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          home: MainMenu(
            continueJianghuRunnerForTest: (context, ref, stage) async {
              directRunnerCalled = true;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text(UiStrings.mainMenuMainline));
    await tester.pump();
    await tester.pump();

    expect(directRunnerCalled, isFalse);
    expect(find.byType(ChapterListScreen), findsOneWidget);
  });

  testWidgets('1280×720 与 1440×900 的继续江湖入口均无布局异常', (tester) async {
    for (final size in const [Size(1280, 720), Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mainlineProgressProvider.overrideWith(
              (ref) async => progressWithCleared(const []),
            ),
          ],
          child: const MaterialApp(home: MainMenu()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('继续江湖'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
