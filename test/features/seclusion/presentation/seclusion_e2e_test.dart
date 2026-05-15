import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/models/enums.dart';
import 'package:wuxia_idle/data/models/equipment.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/active_retreat_screen.dart';
import 'package:wuxia_idle/features/seclusion/presentation/retreat_result_screen.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_map_list_screen.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_setup_screen.dart';
import 'package:wuxia_idle/providers/isar_provider.dart';
import 'package:wuxia_idle/services/encounter_service.dart';
import 'package:wuxia_idle/ui/strings.dart';

/// W15 Phase 5 #2 · 闭关 widget e2e test(销 #28 老挂账)。
///
/// 3 屏 Consumer 化后,通过 override `seclusionServiceProvider` 注入 fake
/// service,绕过 native Isar zone 边界(W6 drift 5 轮探路无解的原因)。
///
/// 覆盖 e2e 关键导航:
///   1. List → 点击可入地图 → push SetupScreen
///   2. Setup → 点击「开始闭关」 → pushReplacement ActiveScreen
///   3. Active(已 done)→ 点击「收功」 → pushReplacement ResultScreen
class _FakeSeclusionService implements SeclusionService {
  RetreatSession? activeSession;
  late RetreatSession Function() startFactory;
  late RetreatOutputs Function() completeFactory;
  int startCallCount = 0;
  int completeCallCount = 0;

  @override
  Isar get isar => throw UnimplementedError('fake: isar 不应被访问');

  @override
  EncounterService? get encounterService => null;

  @override
  Future<RetreatSession?> getActiveSession(int saveDataId) async =>
      activeSession;

  @override
  Future<RetreatSession> startRetreat({
    required RetreatMapType mapType,
    required int durationHours,
    required int saveDataId,
    required int characterId,
    required RealmTier charRealmTier,
    required List<dynamic> maps,
    required DateTime now,
  }) async {
    startCallCount++;
    return startFactory();
  }

  @override
  Future<RetreatOutputs> completeRetreat({
    required RetreatSession session,
    required int characterId,
    required RealmTier charRealmTier,
    required dynamic config,
    required List<dynamic> maps,
    required DateTime now,
    dynamic rng,
  }) async {
    completeCallCount++;
    return completeFactory();
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
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  RetreatSession mkSession({
    DateTime? startedAt,
    int durationHours = 1,
    RetreatMapType mapType = RetreatMapType.shanLin,
  }) {
    return RetreatSession()
      ..id = 1
      ..saveDataId = 1
      ..mapType = mapType
      ..durationHours = durationHours
      ..startedAt = startedAt ?? DateTime.now().subtract(const Duration(hours: 2))
      ..completedAt = null
      ..status = RetreatStatus.active
      ..actualRewards = [];
  }

  Future<void> pumpList(
    WidgetTester tester, {
    required _FakeSeclusionService fake,
    RealmTier charRealmTier = RealmTier.xueTu,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seclusionServiceProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
          home: SeclusionMapListScreen(
            charRealmTier: charRealmTier,
            characterId: 1,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // ─── e2e #1 ────────────────────────────────────────────────────────────────

  testWidgets('e2e: list 点击可入山林 → push SetupScreen', (tester) async {
    final fake = _FakeSeclusionService();
    await pumpList(tester, fake: fake);

    expect(find.byType(SeclusionMapListScreen), findsOneWidget);

    await tester.tap(find.text('山林'));
    await tester.pumpAndSettle();

    expect(find.byType(SeclusionSetupScreen), findsOneWidget);
    // setup 屏可见开始按钮
    expect(find.text(UiStrings.seclusionSetupStartButton), findsOneWidget);
  });

  // ─── e2e #2 ────────────────────────────────────────────────────────────────

  testWidgets('e2e: setup 点击「开始闭关」 → pushReplacement ActiveScreen',
      (tester) async {
    final session = mkSession();
    final fake = _FakeSeclusionService()..startFactory = () => session;
    await pumpList(tester, fake: fake);

    // List → Setup
    await tester.tap(find.text('山林'));
    await tester.pumpAndSettle();
    expect(find.byType(SeclusionSetupScreen), findsOneWidget);

    // 点击「开始闭关」
    await tester.tap(find.text(UiStrings.seclusionSetupStartButton));
    await tester.pumpAndSettle();

    // 应导航到 Active(pushReplacement 替换 Setup)
    expect(fake.startCallCount, 1);
    expect(find.byType(ActiveRetreatScreen), findsOneWidget);
    expect(find.byType(SeclusionSetupScreen), findsNothing);
  });

  // ─── e2e #3 ────────────────────────────────────────────────────────────────

  testWidgets('e2e: active(已 done)点收功 → pushReplacement ResultScreen',
      (tester) async {
    // session 已超时(2h elapsed > 1h plan → done=true)
    final session = mkSession();
    final outputs = (
      actualHours: 1.0,
      mojianshi: 100,
      equipmentDrops: <Equipment>[],
      experiencePoints: 50,
      techniqueLearnPoints: 5,
      internalForcePoints: 30,
    );
    final fake = _FakeSeclusionService()..completeFactory = () => outputs;
    final def = GameRepository.instance.getSeclusionMap(RetreatMapType.shanLin);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seclusionServiceProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
          home: ActiveRetreatScreen(
            session: session,
            mapDef: def,
            characterId: 1,
            charRealmTier: RealmTier.xueTu,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ActiveRetreatScreen), findsOneWidget);
    // done=true 时按钮文案为「收功」
    expect(find.text(UiStrings.activeRetreatCollect), findsOneWidget);

    await tester.tap(find.text(UiStrings.activeRetreatCollect));
    await tester.pumpAndSettle();

    expect(fake.completeCallCount, 1);
    expect(find.byType(RetreatResultScreen), findsOneWidget);
    expect(find.byType(ActiveRetreatScreen), findsNothing);
  });

  // ─── e2e #4 ────────────────────────────────────────────────────────────────

  testWidgets('e2e: active(未 done)点提前收功 → confirm dialog → 确认后导航',
      (tester) async {
    // session 未超时(0.5h elapsed < 1h plan)
    final session = mkSession(
      startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      durationHours: 1,
    );
    final outputs = (
      actualHours: 0.5,
      mojianshi: 50,
      equipmentDrops: <Equipment>[],
      experiencePoints: 25,
      techniqueLearnPoints: 2,
      internalForcePoints: 15,
    );
    final fake = _FakeSeclusionService()..completeFactory = () => outputs;
    final def = GameRepository.instance.getSeclusionMap(RetreatMapType.shanLin);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seclusionServiceProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
          home: ActiveRetreatScreen(
            session: session,
            mapDef: def,
            characterId: 1,
            charRealmTier: RealmTier.xueTu,
          ),
        ),
      ),
    );
    await tester.pump();

    // 未 done 时按钮文案为「提前收功」
    expect(find.text(UiStrings.activeRetreatEarlyCollect), findsOneWidget);

    await tester.tap(find.text(UiStrings.activeRetreatEarlyCollect));
    await tester.pumpAndSettle();

    // 弹出 confirm dialog
    expect(find.text(UiStrings.activeRetreatConfirmTitle), findsOneWidget);
    expect(find.text(UiStrings.activeRetreatConfirm), findsOneWidget);
    expect(find.text(UiStrings.activeRetreatCancel), findsOneWidget);

    // 取消 → 留在 active 屏,不调 completeRetreat
    await tester.tap(find.text(UiStrings.activeRetreatCancel));
    await tester.pumpAndSettle();
    expect(fake.completeCallCount, 0);
    expect(find.byType(ActiveRetreatScreen), findsOneWidget);

    // 再次点击 + 确认 → 导航到 Result
    await tester.tap(find.text(UiStrings.activeRetreatEarlyCollect));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.activeRetreatConfirm));
    await tester.pumpAndSettle();

    expect(fake.completeCallCount, 1);
    expect(find.byType(RetreatResultScreen), findsOneWidget);
  });

}
