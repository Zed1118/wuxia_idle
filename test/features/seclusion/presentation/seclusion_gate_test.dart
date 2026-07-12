import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service_providers.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/domain/seclusion_map_def.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../../../support/test_data.dart';

class _FailingSeclusionService implements SeclusionService {
  int completeCallCount = 0;

  @override
  Isar get isar => throw UnimplementedError('fake: isar should not be read');

  @override
  EncounterService? get encounterService => null;

  @override
  Future<RetreatSession?> getActiveSession(int saveDataId) async => null;

  @override
  Future<RetreatSession> startRetreat({
    required RetreatMapType mapType,
    int? durationHours,
    required int saveDataId,
    required int characterId,
    required RealmTier charRealmTier,
    required List<SeclusionMapDef> maps,
    required DateTime now,
  }) => throw UnimplementedError();

  @override
  Future<RetreatResult> completeRetreat({
    required RetreatSession session,
    required int characterId,
    RealmTier? charRealmTier,
    required RetreatConfig config,
    required List<SeclusionMapDef> maps,
    required DateTime now,
    Rng? rng,
  }) async {
    completeCallCount++;
    throw StateError('already completed');
  }

  @override
  Future<void> abandonRetreat({
    required RetreatSession session,
    required int characterId,
    required DateTime now,
  }) async {}
}

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  RetreatSession fakeSession() => RetreatSession()
    ..saveDataId = 1
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..realmTierAtStart = RealmTier.xueTu
    ..startedAt = DateTime(2026, 1, 1)
    ..status = RetreatStatus.active;

  Future<bool> pumpGuard(
    WidgetTester tester, {
    required RetreatSession? session,
  }) async {
    var allowed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRetreatSessionProvider.overrideWith((ref) async => session),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => guardBattleEntry(
                  context: context,
                  ref: ref,
                  onAllowed: () => allowed = true,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return allowed;
  }

  testWidgets('无 active session → onAllowed 调用、无拦截弹窗', (tester) async {
    final allowed = await pumpGuard(tester, session: null);
    expect(allowed, isTrue);
    expect(find.text(UiStrings.seclusionBattleLockTitle), findsNothing);
  });

  testWidgets('有 active session → 拦截弹窗、onAllowed 不调用', (tester) async {
    final allowed = await pumpGuard(tester, session: fakeSession());
    expect(allowed, isFalse);
    expect(find.text(UiStrings.seclusionBattleLockTitle), findsOneWidget);
    expect(find.text(UiStrings.seclusionBattleLockEndEarly), findsOneWidget);
  });

  testWidgets('提前出关结算冲突被捕获并显示失败提示', (tester) async {
    final session = fakeSession()..id = 9;
    final fake = _FailingSeclusionService();
    final character = Character.create(
      name: '测试角色',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes()
        ..constitution = 5
        ..enlightenment = 5
        ..agility = 5
        ..fortune = 5,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 7, 13),
    )..id = 1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRetreatSessionProvider.overrideWith((ref) async => session),
          seclusionServiceProvider.overrideWithValue(fake),
          activeCharacterIdsProvider.overrideWith((ref) async => [1]),
          characterByIdProvider(1).overrideWith((ref) async => character),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => guardBattleEntry(
                  context: context,
                  ref: ref,
                  onAllowed: () {},
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.seclusionBattleLockEndEarly));
    await tester.pumpAndSettle();

    expect(fake.completeCallCount, 1);
    expect(find.textContaining('already completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
