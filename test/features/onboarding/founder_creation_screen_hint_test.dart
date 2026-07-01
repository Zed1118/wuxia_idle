import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/onboarding/presentation/founder_creation_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  testWidgets('祖师塑形确认区显示决策可逆提示', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FounderCreationScreen()),
      ),
    );
    // pump 两次触发初始 build；不用 pumpAndSettle 以免触发语义树联动断言。
    await tester.pump();
    await tester.pump();
    expect(
      find.text(UiStrings.founderCreateReversibleHint),
      findsOneWidget,
      reason: '确认区应显示决策可逆说明',
    );
  });
}
