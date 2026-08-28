import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/baike/presentation/baike_screen.dart';
import 'package:wuxia_idle/features/splash/presentation/splash_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import '../../../support/test_data.dart';

void main() {
  testWidgets('生产启动完成定义加载后才可到达百科典故页', (tester) async {
    GameRepository.resetForTest();
    expect(GameRepository.isLoaded, isFalse);
    final definitionsGate = Completer<void>();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SplashScreen(
            minDisplay: Duration.zero,
            loadDefinitions: () => definitionsGate.future,
            nextScreenBuilder: _buildLoreScreen,
          ),
        ),
      ),
    );

    expect(find.byType(BaikeScreen), findsNothing);
    await tester.runAsync(loadTestGameRepository);
    definitionsGate.complete();
    await tester.pumpAndSettle();

    expect(GameRepository.isLoaded, isTrue);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(BaikeScreen), findsOneWidget);
    expect(find.text(UiStrings.baikeLoreEmpty), findsNothing);
    expect(find.byType(ListView), findsAtLeastNWidgets(1));
  });
}

Widget _buildLoreScreen(BuildContext context) {
  expect(GameRepository.isLoaded, isTrue);
  return const BaikeScreen(initialTab: 1);
}
