import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/jianghu_chronicle/presentation/mainline_location_archive_screen.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  MainlineProgress progress(List<String> cleared) => MainlineProgress()
    ..saveDataId = 1
    ..currentChapterIndex = 1
    ..clearedStageIds = List.of(cleared)
    ..clearedAt = List.generate(cleared.length, (_) => DateTime(2026, 8, 25))
    ..clearedStageCycleKeys = [for (final id in cleared) '$id#1']
    ..clearedChapterCycleKeys = const [];

  Future<void> pump(
    WidgetTester tester,
    MainlineProgress value, {
    Size size = const Size(1280, 720),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith((ref) async => value),
        ],
        child: const MaterialApp(home: MainlineLocationArchiveScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('只显示已通或当前可达地点，不泄露锁定关卡与后续章节', (tester) async {
    await pump(tester, progress(const ['stage_01_01']));

    expect(find.text('山门之外'), findsOneWidget);
    expect(find.text('荒山野店'), findsOneWidget);
    expect(find.text('黑风岭'), findsNothing);
    expect(find.text('镖局护送'), findsNothing);
    expect(
      find.text(UiStrings.jianghuChronicleLocationCleared),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.jianghuChronicleLocationAvailable),
      findsOneWidget,
    );
  });

  testWidgets('前章全通后仅开放下一章首个地点', (tester) async {
    await pump(
      tester,
      progress(const [
        'stage_01_01',
        'stage_01_02',
        'stage_01_03',
        'stage_01_04',
        'stage_01_05',
      ]),
    );

    expect(find.text('镖局护送'), findsOneWidget);
    expect(find.text('茶馆论剑'), findsNothing);
  });

  testWidgets('进度加载失败时 fail closed，不展示猜测地点', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith(
            (ref) => Future.error(StateError('broken progress')),
          ),
        ],
        child: const MaterialApp(home: MainlineLocationArchiveScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(UiStrings.jianghuChronicleLocationsUnavailable),
      findsOneWidget,
    );
    expect(find.text('山门之外'), findsNothing);
  });

  testWidgets('1440x900 档案布局无溢出', (tester) async {
    await pump(tester, progress(const []), size: const Size(1440, 900));
    expect(tester.takeException(), isNull);
  });
}
