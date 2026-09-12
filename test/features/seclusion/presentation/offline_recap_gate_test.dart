import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/seclusion/presentation/active_retreat_screen.dart';
import 'package:wuxia_idle/features/seclusion/presentation/offline_recap_gate.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/shared/strings.dart';
import '../../../support/test_data.dart';

/// M2「归来」卡启动挂钩 wiring 测试。照搬 L3 guardBattleEntry 的
/// provider override 模式。注入固定 now 保证「已满」判定确定。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  RetreatSession fakeSession() => RetreatSession()
    ..id = 7
    ..saveDataId = 1
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..realmTierAtStart = RealmTier.xueTu
    ..startedAt = DateTime(2026, 5, 11, 10)
    ..status = RetreatStatus.active;

  Character fakeChar() => Character.create(
    name: 'hero',
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes(),
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: 500,
  )..id = 10;

  Future<void> pumpGate(
    WidgetTester tester, {
    required RetreatSession? session,
    required DateTime now,
    bool ownerUnavailable = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeRetreatSessionProvider.overrideWith((ref) async => session),
          activeCharacterIdsProvider.overrideWith((ref) async => [99]),
          characterByIdProvider(99).overrideWith((ref) async => null),
          if (session != null)
            retreatOwnerProvider(session.id).overrideWith((ref) async {
              if (ownerUnavailable) throw StateError('missing retreat owner');
              return fakeChar()..isActive = false;
            }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    maybeShowOfflineRecap(context: context, ref: ref, now: now),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('无 active session → 不弹归来卡', (tester) async {
    await pumpGate(tester, session: null, now: DateTime(2026, 5, 11, 15));
    expect(find.text(UiStrings.offlineRecapTitle), findsNothing);
  });

  testWidgets('有已满 active session（挂 5h ≥ 4h）→ 弹归来卡 + 地图名', (tester) async {
    await pumpGate(
      tester,
      session: fakeSession(),
      now: DateTime(2026, 5, 11, 15), // started 10:00 + 5h
    );
    expect(find.text(UiStrings.offlineRecapTitle), findsOneWidget);
    expect(find.textContaining('山林'), findsOneWidget);
    expect(find.text(UiStrings.offlineRecapGoCollect), findsOneWidget);
  });

  testWidgets('离开不足阈值（30 分钟）→ 不弹归来卡', (tester) async {
    await pumpGate(
      tester,
      session: fakeSession(),
      now: DateTime(2026, 5, 11, 10, 30), // started + 30min < 1h
    );
    expect(find.text(UiStrings.offlineRecapTitle), findsNothing);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('归来卡按会话归属打开旧掌门闭关 $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpGate(
        tester,
        session: fakeSession(),
        now: DateTime(2026, 5, 11, 15),
      );
      await tester.tap(find.text(UiStrings.offlineRecapGoCollect));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ActiveRetreatScreen>(find.byType(ActiveRetreatScreen))
            .characterId,
        10,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('归属缺失时保留会话并提示,不猜测当前角色', (tester) async {
    await pumpGate(
      tester,
      session: fakeSession(),
      now: DateTime(2026, 5, 11, 15),
      ownerUnavailable: true,
    );
    expect(find.byType(ActiveRetreatScreen), findsNothing);
    expect(find.text(UiStrings.offlineRecapTitle), findsNothing);
    expect(find.textContaining('missing retreat owner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
