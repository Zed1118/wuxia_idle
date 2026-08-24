import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_narrative_manifest.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  late MainlineNarrativeManifest manifest;

  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
    manifest = await MainlineNarrativeManifest.load(
      loader: (path) => File(path).readAsString(),
    );
  });

  MainlineProgress progress(List<String> cleared) => MainlineProgress()
    ..saveDataId = 1
    ..currentChapterIndex = 1
    ..clearedStageIds = List.of(cleared)
    ..clearedAt = List.generate(cleared.length, (_) => DateTime(2026, 8, 24))
    ..clearedStageCycleKeys = [for (final id in cleared) '$id#1']
    ..clearedChapterCycleKeys = [];

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Size size,
    required MainlineProgress value,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith((ref) async => value),
          mainlineNarrativeManifestProvider.overrideWith(
            (ref) async => manifest,
          ),
        ],
        child: const MaterialApp(home: StageListScreen(chapterIndex: 1)),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('fresh progress exposes only the available stage opening', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      size: const Size(1280, 720),
      value: progress(const []),
    );

    expect(find.text(UiStrings.mainlineNarrativeOpeningLabel), findsOneWidget);
    expect(find.text(UiStrings.mainlineNarrativeVictoryLabel), findsNothing);
    expect(find.text(UiStrings.mainlineNarrativeDefeatLabel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cleared evidence unlocks victory and conservative Boss defeat reading',
    (tester) async {
      await pumpScreen(
        tester,
        size: const Size(1280, 720),
        value: progress(const [
          'stage_01_01',
          'stage_01_02',
          'stage_01_03',
          'stage_01_04',
        ]),
      );

      await tester.scrollUntilVisible(
        find.text(UiStrings.mainlineNarrativeDefeatLabel),
        180,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text(UiStrings.mainlineNarrativeVictoryLabel), findsWidgets);
      expect(
        find.text(UiStrings.mainlineNarrativeDefeatLabel),
        findsOneWidget,
        reason:
            'stage_01_04 defeat uses stageCleared because no defeat save exists',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('optional opening has semantics and activates from keyboard', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(
      tester,
      size: const Size(1440, 900),
      value: progress(const []),
    );

    final semanticsLabel = UiStrings.mainlineNarrativeReadSemantics(
      '山门之外',
      UiStrings.mainlineNarrativeOpeningLabel,
    );
    final semanticsFinder = find.bySemanticsLabel(semanticsLabel);
    expect(semanticsFinder, findsOneWidget);
    final buttonFinder = find.widgetWithText(
      TextButton,
      UiStrings.mainlineNarrativeOpeningLabel,
    );
    final buttonElement = buttonFinder.evaluate().single;
    var reachedByTab = false;
    for (var i = 0; i < 30 && !reachedByTab; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focusedContext = FocusManager.instance.primaryFocus?.context;
      if (focusedContext is! Element) continue;
      focusedContext.visitAncestorElements((ancestor) {
        if (identical(ancestor, buttonElement)) {
          reachedByTab = true;
          return false;
        }
        return true;
      });
    }
    expect(
      reachedByTab,
      isTrue,
      reason: 'optional reading must be Tab reachable',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('山门之外 · 启'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('1440x900 chapter timeline has no overflow', (tester) async {
    await pumpScreen(
      tester,
      size: const Size(1440, 900),
      value: progress(const [
        'stage_01_01',
        'stage_01_02',
        'stage_01_03',
        'stage_01_04',
        'stage_01_05',
      ]),
    );

    expect(find.text(UiStrings.stageListTimelineTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
