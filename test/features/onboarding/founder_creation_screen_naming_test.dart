import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/onboarding/presentation/founder_creation_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import "../../support/isar_test_support.dart";

void main() {
  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  testWidgets('名号段渲染 + 掷名按钮填入祖师名', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FounderCreationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 名号段标题在。
    expect(find.text(UiStrings.founderCreateNameSection), findsOneWidget);
    // 掷名按钮存在(祖师名 + 门派名各一)。
    expect(find.text(UiStrings.founderCreateRollName), findsNWidgets(2));

    // 点第一个掷名按钮 → 第一个输入框非空。
    await tester.tap(find.text(UiStrings.founderCreateRollName).first);
    await tester.pumpAndSettle();
    final founderField = tester.widget<TextField>(find.byType(TextField).first);
    expect(founderField.controller!.text.isNotEmpty, true);
  });
}
