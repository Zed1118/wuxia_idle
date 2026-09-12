import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu_retreat_banner.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/seclusion/presentation/active_retreat_screen.dart';
import '../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  test('横幅复用闭关结算的唯一时长切分函数', () async {
    final source = await File(
      'lib/features/main_menu/presentation/main_menu_retreat_banner.dart',
    ).readAsString();

    expect(source, contains('RetreatSettlementCalculator.splitHours'));
  });

  RetreatSession fakeSession({DateTime? startedAt, int durationHours = 4}) =>
      RetreatSession()
        ..saveDataId = 1
        ..mapType = RetreatMapType.shanLin
        ..durationHours = durationHours
        ..realmTierAtStart = RealmTier.xueTu
        ..startedAt = startedAt ?? DateTime.now()
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
        child: const MaterialApp(home: Scaffold(body: MainMenuRetreatBanner())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('有 session → 横幅显示「闭关中」+ 地图名', (tester) async {
    await pumpBanner(tester, session: fakeSession());
    expect(find.textContaining('闭关中'), findsOneWidget);
    expect(find.textContaining('山林'), findsOneWidget);
  });

  testWidgets('超过 72h → 横幅显示地图圆满与挂机接续', (tester) async {
    final capHours = GameRepository.instance.numbers.retreat.capHours;
    await pumpBanner(
      tester,
      session: fakeSession(
        durationHours: capHours,
        startedAt: DateTime.now().subtract(Duration(hours: capHours + 1)),
      ),
    );
    expect(find.textContaining('地图圆满'), findsOneWidget);
    expect(find.textContaining('挂机接续'), findsOneWidget);
    expect(find.textContaining('收益已满'), findsNothing);
    expect(find.textContaining('剩'), findsNothing);
  });

  testWidgets('无 session → 横幅隐藏', (tester) async {
    await pumpBanner(tester, session: null);
    expect(find.textContaining('闭关中'), findsNothing);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('横幅按会话归属打开旧掌门闭关 $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = fakeSession()..id = 7;
      final owner = Character.create(
        name: 'retired leader',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.biaoZhun,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026),
        isActive: false,
      )..id = 41;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRetreatSessionProvider.overrideWith((ref) async => session),
            retreatOwnerProvider(7).overrideWith((ref) async => owner),
            activeCharacterIdsProvider.overrideWith((ref) async => [99]),
            characterByIdProvider(99).overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MainMenuRetreatBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('闭关中'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ActiveRetreatScreen>(find.byType(ActiveRetreatScreen))
            .characterId,
        41,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
