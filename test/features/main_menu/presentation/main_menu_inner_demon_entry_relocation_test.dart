import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  Widget appWithCleared(List<String> clearedStageIds) => ProviderScope(
    overrides: [
      mainlineProgressProvider.overrideWith(
        (ref) async => MainlineProgress()..clearedStageIds = clearedStageIds,
      ),
    ],
    child: const MaterialApp(home: MainMenu()),
  );

  for (final scenario in <String, List<String>>{
    '心魔尚未解锁': const <String>[],
    '心魔原门槛已满足': const <String>['stage_06_05'],
  }.entries) {
    testWidgets('${scenario.key}时主菜单均不显示心魔入口', (tester) async {
      await tester.pumpWidget(appWithCleared(scenario.value));
      await tester.pump();
      await tester.pump();

      expect(find.text(UiStrings.mainMenuInnerDemon), findsNothing);
    });
  }
}
