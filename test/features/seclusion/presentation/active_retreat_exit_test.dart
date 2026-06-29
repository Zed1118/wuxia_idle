import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/active_retreat_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  RetreatSession fakeSession() => RetreatSession()
    ..saveDataId = 1
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..startedAt = DateTime.now()
    ..status = RetreatStatus.active;

  Future<void> pumpActive(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final mapDef = GameRepository.instance.getSeclusionMap(
      RetreatMapType.shanLin,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ActiveRetreatScreen(
                      session: fakeSession(),
                      mapDef: mapDef,
                      characterId: 1,
                      charRealmTier: RealmTier.xueTu,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('闭关屏有返回按钮', (tester) async {
    await pumpActive(tester);
    expect(find.byType(ActiveRetreatScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('闭关中状态牌显示地点、时长与预计收获类型', (tester) async {
    await pumpActive(tester);
    final mapDef = GameRepository.instance.getSeclusionMap(
      RetreatMapType.shanLin,
    );

    expect(find.text(UiStrings.activeRetreatStatusCardTitle), findsOneWidget);
    expect(
      find.text(UiStrings.activeRetreatStatusLocation(mapDef.mapName)),
      findsOneWidget,
    );
    expect(find.textContaining('已闭关：'), findsOneWidget);
    expect(find.text(UiStrings.activeRetreatPlannedHours(4)), findsOneWidget);
    expect(find.text(UiStrings.activeRetreatExpectedTypes), findsOneWidget);
    expect(
      find.textContaining(UiStrings.activeRetreatRewardMojianshi),
      findsOneWidget,
    );
    expect(
      find.textContaining(UiStrings.activeRetreatRewardExperience),
      findsOneWidget,
    );
  });

  testWidgets('Esc 退出闭关屏', (tester) async {
    await pumpActive(tester);
    expect(find.byType(ActiveRetreatScreen), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ActiveRetreatScreen), findsNothing);
  });
}
