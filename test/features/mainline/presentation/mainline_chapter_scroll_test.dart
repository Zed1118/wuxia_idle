import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_narrative_manifest.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/features/narrative/presentation/narrative_reader_screen.dart';
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
    Future<MainlineNarrativeManifest> Function()? manifestLoader,
    List<NavigatorObserver> navigatorObservers = const [],
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainlineProgressProvider.overrideWith((ref) async => value),
          mainlineNarrativeManifestProvider.overrideWith(
            (ref) => manifestLoader?.call() ?? Future.value(manifest),
          ),
        ],
        child: MaterialApp(
          navigatorObservers: navigatorObservers,
          home: const StageListScreen(chapterIndex: 1),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpUntilOpeningReader(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(NarrativeReaderScreen).evaluate().isNotEmpty) return;
    }
  }

  Future<void> closeNarrativeReader(WidgetTester tester) async {
    final readerContext = tester.element(find.byType(NarrativeReaderScreen));
    Navigator.of(readerContext).pop();
    await tester.pumpAndSettle();
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

  testWidgets('manifest loading or error never blocks stage selection', (
    tester,
  ) async {
    final pendingManifest = Completer<MainlineNarrativeManifest>();
    await pumpScreen(
      tester,
      size: const Size(1280, 720),
      value: progress(const []),
      manifestLoader: () => pendingManifest.future,
    );

    expect(find.text('山门之外'), findsOneWidget);
    expect(find.text(UiStrings.mainlineNarrativeOpeningLabel), findsNothing);
    var stageInkWell = find.ancestor(
      of: find.text('山门之外'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(stageInkWell.first).onTap, isNotNull);

    await pumpScreen(
      tester,
      size: const Size(1280, 720),
      value: progress(const []),
      manifestLoader: () => Future.error(StateError('manifest unavailable')),
    );

    expect(find.text('山门之外'), findsOneWidget);
    expect(find.text(UiStrings.mainlineNarrativeOpeningLabel), findsNothing);
    stageInkWell = find.ancestor(
      of: find.text('山门之外'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(stageInkWell.first).onTap, isNotNull);
    expect(tester.takeException(), isNull);
    pendingManifest.complete(manifest);
  });

  testWidgets(
    '1280x720 dense Boss row exposes all three links without overflow',
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
        find.text(UiStrings.mainlineNarrativeOpeningLabel),
        findsNWidgets(5),
        reason: 'all available rows include opening, including the dense Boss',
      );
      expect(
        find.text(UiStrings.mainlineNarrativeDefeatLabel),
        findsOneWidget,
        reason:
            'stage_01_04 defeat uses stageCleared because no defeat save exists',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'optional opening is Tab reachable and semantics tap opens only reader',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final observer = _RecordingNavigatorObserver();
      await pumpScreen(
        tester,
        size: const Size(1440, 900),
        value: progress(const []),
        navigatorObservers: [observer],
      );

      final semanticsFinder = find.bySemanticsLabel(
        UiStrings.mainlineNarrativeReadSemantics(
          '山门之外',
          UiStrings.mainlineNarrativeOpeningLabel,
        ),
      );
      final node = tester.getSemantics(semanticsFinder);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
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
      final baseline = observer.pushedRoutes.length;

      tester.semantics.tap(
        find.semantics.byLabel(
          UiStrings.mainlineNarrativeReadSemantics(
            '山门之外',
            UiStrings.mainlineNarrativeOpeningLabel,
          ),
        ),
      );
      await pumpUntilOpeningReader(tester);

      expect(find.byType(NarrativeReaderScreen), findsOneWidget);
      expect(
        observer.pushedRoutes.length,
        baseline + 1,
        reason: 'semantic action must not bubble into the stage-row InkWell',
      );
      expect(tester.takeException(), isNull);
      await closeNarrativeReader(tester);
      semantics.dispose();
    },
  );

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

class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}
