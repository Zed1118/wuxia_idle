import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/splash/presentation/splash_screen.dart';

void main() {
  const nextKey = Key('splash-next');

  Widget host({
    required Completer<void> loadCompleter,
    Duration minDisplay = Duration.zero,
    void Function()? onBuildNext,
  }) {
    return MaterialApp(
      home: SplashScreen(
        minDisplay: minDisplay,
        loadDefinitions: () => loadCompleter.future,
        nextScreenBuilder: (_) {
          onBuildNext?.call();
          return const Scaffold(body: SizedBox(key: nextKey));
        },
      ),
    );
  }

  testWidgets('加载未完成时点击不导航', (tester) async {
    final loadCompleter = Completer<void>();
    await tester.pumpWidget(host(loadCompleter: loadCompleter));
    await tester.pump();

    await tester.tap(find.byType(SplashScreen));
    await tester.pump();

    expect(find.byKey(nextKey), findsNothing);

    loadCompleter.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(nextKey), findsOneWidget);
  });

  testWidgets('加载完成且最短展示结束后自动导航', (tester) async {
    final loadCompleter = Completer<void>();
    await tester.pumpWidget(
      host(
        loadCompleter: loadCompleter,
        minDisplay: const Duration(milliseconds: 100),
      ),
    );

    loadCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 99));
    expect(find.byKey(nextKey), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(nextKey), findsOneWidget);
  });

  testWidgets('加载完成后点击可跳过剩余展示时长', (tester) async {
    final loadCompleter = Completer<void>();
    await tester.pumpWidget(
      host(
        loadCompleter: loadCompleter,
        minDisplay: const Duration(seconds: 1),
      ),
    );
    loadCompleter.complete();
    await tester.pump();

    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(nextKey), findsOneWidget);
  });

  testWidgets('连续点击只构造一次目的页', (tester) async {
    final loadCompleter = Completer<void>();
    var nextBuildCount = 0;
    await tester.pumpWidget(
      host(
        loadCompleter: loadCompleter,
        minDisplay: const Duration(seconds: 1),
        onBuildNext: () => nextBuildCount++,
      ),
    );
    loadCompleter.complete();
    await tester.pump();

    final rootGesture = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(SplashScreen),
        matching: find.byType(GestureDetector),
      ),
    );
    rootGesture.onTap!.call();
    rootGesture.onTap!.call();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(nextBuildCount, 1);
    expect(find.byKey(nextKey), findsOneWidget);
  });
}
