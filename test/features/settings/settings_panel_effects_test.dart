import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/presentation/settings_panel.dart';
import 'package:wuxia_idle/shared/theme/wuxia_app_theme.dart';

void main() {
  setUpAll(_loadVisualFont);
  for (final viewport in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets(
      '$viewport reduced effects persist through keyboard and mouse',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'gameplay.reduceFlashing': true,
          'gameplay.battlePlaybackSpeed': 'brisk',
        });
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final semantics = tester.ensureSemantics();
        try {
          final capture = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: ProviderScope(
                child: MaterialApp(
                  theme: wuxiaAppTheme(),
                  home: Scaffold(
                    body: Builder(
                      builder: (context) => Center(
                        child: TextButton(
                          onPressed: () => SettingsPanel.show(context),
                          child: const Text('open'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          final tile = find.byKey(const ValueKey('settings_reduce_effects'));
          expect(tile, findsOneWidget);
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          expect(tester.widget<SwitchListTile>(tile).value, isFalse);
          expect(tester.getSemantics(tile).label, contains('降低特效密度'));
          expect(_toggleState(tester.getSemantics(tile)), isFalse);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            pointer: 91,
          );
          await mouse.addPointer(location: tester.getCenter(tile));
          await tester.pump();
          expect(
            RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
            SystemMouseCursors.click,
          );
          await mouse.removePointer();
          await tester.tap(tile);
          await tester.pumpAndSettle();
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('gameplay.reduceEffects'), isTrue);
          expect(prefs.getBool('gameplay.reduceFlashing'), isTrue);
          expect(prefs.getString('gameplay.battlePlaybackSpeed'), 'brisk');
          expect(_toggleState(tester.getSemantics(tile)), isTrue);
          final directory = Platform.environment['WUXIA_EFFECTS_VISUAL_OUTPUT'];
          if (directory != null) {
            final boundary =
                capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final file = File(
                '$directory/${viewport.width.toInt()}-settings.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
            });
          }

          // Reach the real switch through keyboard traversal, not its callback.
          FocusManager.instance.primaryFocus?.unfocus();
          for (var i = 0; i < 40; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            final focused = FocusManager.instance.primaryFocus?.context;
            if (focused != null &&
                focused.findAncestorWidgetOfExactType<SwitchListTile>()?.key ==
                    const ValueKey('settings_reduce_effects')) {
              break;
            }
          }
          final focused = FocusManager.instance.primaryFocus?.context;
          expect(
            focused?.findAncestorWidgetOfExactType<SwitchListTile>()?.key,
            const ValueKey('settings_reduce_effects'),
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(prefs.getBool('gameplay.reduceEffects'), isFalse);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}

Future<void> _loadVisualFont() async {
  final path = Platform.environment['WUXIA_EFFECTS_VISUAL_FONT'];
  if (path == null) return;
  final bytes = ByteData.sublistView(await File(path).readAsBytes());
  for (final family in ['Roboto', 'Ahem', 'sans-serif']) {
    await (FontLoader(family)..addFont(Future.value(bytes))).load();
  }
}

bool _toggleState(SemanticsNode node) {
  final toggles = <bool>[];
  bool visit(SemanticsNode current) {
    if (current.flagsCollection.isToggled != ui.Tristate.none) {
      toggles.add(current.flagsCollection.isToggled == ui.Tristate.isTrue);
    }
    current.visitChildren(visit);
    return true;
  }

  visit(node);
  expect(toggles, hasLength(1));
  return toggles.single;
}
