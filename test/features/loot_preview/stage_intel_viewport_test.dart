import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mainline/presentation/stage_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_app_theme.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/wuxia_icon_button.dart';

import '../../support/test_data.dart';

void main() {
  final captureDirectory = Platform.environment['WUXIA_INTEL_CAPTURE_DIR'];
  final captureFont = captureDirectory != null && Platform.isMacOS;

  setUpAll(() async {
    await loadTestGameRepository();
    if (captureFont) {
      final bytes = ByteData.sublistView(
        await File('/System/Library/Fonts/STHeiti Medium.ttc').readAsBytes(),
      );
      for (final family in ['IntelCapture', 'Roboto', 'Ahem', 'sans-serif']) {
        await (FontLoader(family)..addFont(Future.value(bytes))).load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  for (final viewport in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('$viewport catalog 情报在常规桌面可读并可用键鼠开关', (tester) async {
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      try {
        final capture = GlobalKey();
        final theme = wuxiaAppTheme();
        final progress = MainlineProgress()
          ..saveDataId = 1
          ..currentChapterIndex = 1;
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: ProviderScope(
              overrides: [
                mainlineProgressProvider.overrideWith((ref) async => progress),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: captureFont
                    ? theme.copyWith(
                        textTheme: theme.textTheme.apply(
                          fontFamily: 'IntelCapture',
                        ),
                      )
                    : theme,
                home: const StageListScreen(chapterIndex: 1),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final summary = UiStrings.stageCatalogEnemySummary(25, 10);
        expect(find.text(summary), findsOneWidget);
        final info = find
            .byWidgetPredicate(
              (widget) =>
                  widget is WuxiaIconButton &&
                  widget.tooltip == UiStrings.prebattleIntelTitle,
            )
            .first;
        await tester.ensureVisible(info);
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(UiStrings.prebattleIntelTitle),
          findsWidgets,
        );
        await _capture(tester, capture, captureDirectory, viewport, 'list');

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: tester.getCenter(info));
        await tester.pump();
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          SystemMouseCursors.click,
        );
        if (viewport.height == 720) {
          await tester.tap(info);
        } else {
          final infoWidget = tester.widget<WuxiaIconButton>(info);
          await _focusByKeyboard<WuxiaIconButton>(
            tester,
            (widget) => identical(widget, infoWidget),
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        }
        await mouse.removePointer();
        await tester.pumpAndSettle();

        final dialog = find.byType(Dialog);
        expect(dialog, findsOneWidget);
        final intelSummary = find.descendant(
          of: dialog,
          matching: find.text(summary),
        );
        expect(intelSummary, findsOneWidget);
        expect(tester.widget<Text>(intelSummary).style?.color, WuxiaUi.ink);
        expect(find.text('3 波 · 共 9 名敌人'), findsNothing);
        final summaryRect = tester.getRect(intelSummary);
        expect(summaryRect.left, greaterThanOrEqualTo(0));
        expect(summaryRect.right, lessThanOrEqualTo(viewport.width));
        expect(summaryRect.top, greaterThanOrEqualTo(0));
        expect(summaryRect.bottom, lessThanOrEqualTo(viewport.height));
        expect(find.text(UiStrings.close).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, capture, captureDirectory, viewport, 'dialog');

        await _focusByKeyboard<PlaqueButton>(
          tester,
          (widget) => widget.label == UiStrings.close,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(dialog, findsNothing);
        expect(find.text(summary), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    });
  }
}

Future<void> _focusByKeyboard<T extends Widget>(
  WidgetTester tester,
  bool Function(T widget) matches,
) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    final focused = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<T>();
    if (focused != null && matches(focused)) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Keyboard traversal did not reach $T');
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String? directory,
  Size viewport,
  String surface,
) async {
  if (directory == null) return;
  final imageProviders = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toList();
  await tester.runAsync(() async {
    await Future.wait(
      imageProviders.map(
        (provider) => precacheImage(provider, boundaryKey.currentContext!),
      ),
    );
  });
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File(
      '$directory/intel-$surface-${viewport.width.toInt()}x${viewport.height.toInt()}.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
