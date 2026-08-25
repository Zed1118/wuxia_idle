import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/activity/domain/activity_occupancy.dart';
import 'package:wuxia_idle/features/lineup/application/disciple_scheduling_provider.dart';
import 'package:wuxia_idle/features/lineup/domain/disciple_scheduling_summary.dart';
import 'package:wuxia_idle/features/lineup/presentation/disciple_scheduling_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  const summary = DiscipleSchedulingSummary(
    leaderId: 10,
    members: [
      DiscipleSchedulingMember(
        characterId: 10,
        name: '沈掌门',
        realmTier: RealmTier.zongShi,
        realmLayer: RealmLayer.qiMeng,
        isLeader: true,
        isAlive: true,
        activity: null,
        portraitPath: null,
      ),
      DiscipleSchedulingMember(
        characterId: 11,
        name: '叶问舟',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.jingTong,
        isLeader: false,
        isAlive: true,
        activity: ActivityKind.retreat,
        portraitPath: null,
      ),
      DiscipleSchedulingMember(
        characterId: 12,
        name: '程青崖',
        realmTier: RealmTier.erLiu,
        realmLayer: RealmLayer.dengFeng,
        isLeader: false,
        isAlive: false,
        activity: null,
        portraitPath: null,
      ),
      DiscipleSchedulingMember(
        characterId: 13,
        name: '季无尘',
        realmTier: RealmTier.erLiu,
        realmLayer: RealmLayer.dengFeng,
        isLeader: false,
        isAlive: true,
        activity: ActivityKind.bossGauntlet,
        portraitPath: null,
      ),
    ],
  );

  Widget app(Future<DiscipleSchedulingSummary> Function(Ref ref) provider) =>
      ProviderScope(
        overrides: [discipleSchedulingProvider.overrideWith(provider)],
        child: const MaterialApp(home: DiscipleSchedulingScreen()),
      );

  testWidgets('展示逐活动选择原则与真实门人状态，不出现三席全局编成', (tester) async {
    await tester.pumpWidget(app((ref) async => summary));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.discipleSchedulingTitle), findsOneWidget);
    expect(
      find.text(UiStrings.discipleSchedulingPerActivityHint),
      findsOneWidget,
    );
    expect(find.text('沈掌门'), findsOneWidget);
    expect(find.text('叶问舟'), findsOneWidget);
    expect(find.text('程青崖'), findsOneWidget);
    expect(find.text('季无尘'), findsOneWidget);
    expect(find.text(UiStrings.discipleSchedulingLeaderTag), findsOneWidget);
    expect(
      find.text(UiStrings.discipleSchedulingActivityRetreat),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.discipleSchedulingActivityGauntlet),
      findsOneWidget,
    );
    expect(find.text(UiStrings.discipleSchedulingUnavailable), findsOneWidget);
    expect(find.text(UiStrings.lineupActiveSection), findsNothing);
    expect(find.byKey(const ValueKey('lineup.formationStage')), findsNothing);
  });

  testWidgets('provider 异常时 fail closed', (tester) async {
    await tester.pumpWidget(
      app((ref) => Future.error(StateError('dangling current member'))),
    );
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.discipleSchedulingLoadError), findsOneWidget);
    expect(find.textContaining('沈掌门'), findsNothing);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()} 无溢出', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app((ref) async => summary));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DiscipleSchedulingScreen), findsOneWidget);
    });
  }
}
