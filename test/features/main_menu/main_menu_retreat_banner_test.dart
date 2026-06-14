import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu_retreat_banner.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';

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

  Future<void> pumpBanner(
    WidgetTester tester, {
    required RetreatSession? session,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRetreatSessionProvider.overrideWith((ref) async => session),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MainMenuRetreatBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('有 session → 横幅显示「闭关中」+ 地图名', (tester) async {
    await pumpBanner(tester, session: fakeSession());
    expect(find.textContaining('闭关中'), findsOneWidget);
    expect(find.textContaining('山林'), findsOneWidget);
  });

  testWidgets('无 session → 横幅隐藏', (tester) async {
    await pumpBanner(tester, session: null);
    expect(find.textContaining('闭关中'), findsNothing);
  });
}
