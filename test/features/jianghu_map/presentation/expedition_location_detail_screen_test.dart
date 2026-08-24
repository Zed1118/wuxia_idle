import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/presentation/expedition_overview_screen.dart';
import 'package:wuxia_idle/features/jianghu_map/application/expedition_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/expedition_location_detail.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/expedition_location_detail_screen.dart';
import 'package:wuxia_idle/shared/battle_shared/enum_localizations.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  ExpeditionLocationDetail detail({bool active = false}) =>
      ExpeditionLocationDetail(
        historicalMaxDepth: 18,
        activeDepth: active ? 12 : null,
        activePolicy: active ? ExpeditionPolicy.xunJiFangYou : null,
        activeDefeated: active,
        recommendedRealm: RealmTier.erLiu,
        normalEnemyTeams: const [
          ExpeditionLocationEnemyTeamSummary(
            id: 'normal_a',
            enemies: [
              ExpeditionLocationEnemySummary(
                name: '百草岭山匪',
                realmTier: RealmTier.sanLiu,
                school: TechniqueSchool.gangMeng,
              ),
            ],
          ),
        ],
        eliteEnemyTeams: const [
          ExpeditionLocationEnemyTeamSummary(
            id: 'elite_a',
            enemies: [
              ExpeditionLocationEnemySummary(
                name: '瘠地药人',
                realmTier: RealmTier.erLiu,
                school: TechniqueSchool.yinRou,
              ),
            ],
          ),
        ],
        coreRewardItemNames: const ['药草', '灵泉水', '银两', '断魂帖'],
        includesExperienceReward: true,
        candidateCount: 4,
        availableCandidateCount: 2,
        activeParticipantNames: active ? const ['沈无归'] : const [],
      );

  ExpeditionRun run() => ExpeditionRun()
    ..saveDataId = 0
    ..policy = ExpeditionPolicy.xunJiFangYou
    ..seed = 7
    ..departedAt = DateTime(2026, 8, 25)
    ..currentNode = 12
    ..defeated = true;

  Widget app({
    ExpeditionLocationDetail? value,
    Object? error,
    ExpeditionRun? activeRun,
  }) => ProviderScope(
    overrides: [
      expeditionLocationDetailProvider.overrideWith(
        (ref) => error == null
            ? Future.value(value ?? detail())
            : Future.error(error),
      ),
      activeExpeditionProvider.overrideWith((ref) async => activeRun),
      expeditionConfigProvider.overrideWithValue(
        GameRepository.instance.expeditionConfig,
      ),
      expeditionCandidatesProvider.overrideWith((ref) async => const []),
      expeditionMaxDepthProvider.overrideWith((ref) async => 18),
    ],
    child: const MaterialApp(home: ExpeditionLocationDetailScreen()),
  );

  testWidgets('展示历史进度、境界、敌方生态、产出、候选人与差遣占用', (tester) async {
    final value = detail();
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    expect(
      find.text(UiStrings.expeditionLocationHistoricalProgress(18)),
      findsOneWidget,
    );
    expect(
      find.text(EnumL10n.realmTier(value.recommendedRealm)),
      findsOneWidget,
    );
    expect(find.textContaining('百草岭山匪'), findsOneWidget);
    expect(find.textContaining('药草'), findsOneWidget);
    expect(
      find.text(
        UiStrings.expeditionLocationParticipantCandidates(
          value.availableCandidateCount,
          value.candidateCount,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.expeditionLocationEntryModeDispatch),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.expeditionLocationExpectedOccupancy),
      findsOneWidget,
    );
    expect(find.text(UiStrings.expeditionLocationEnter), findsOneWidget);
  });

  testWidgets('进行中远征展示深度、战败、方针、真实参与者与续行 CTA', (tester) async {
    final value = detail(active: true);
    await tester.pumpWidget(app(value: value, activeRun: run()));
    await tester.pumpAndSettle();

    expect(
      find.text(UiStrings.expeditionLocationActiveProgress(12, true)),
      findsOneWidget,
    );
    expect(
      find.text(EnumL10n.expeditionPolicy(value.activePolicy!)),
      findsOneWidget,
    );
    expect(find.text('沈无归'), findsOneWidget);
    expect(find.text(UiStrings.expeditionLocationResume), findsOneWidget);

    await tester.tap(find.text(UiStrings.expeditionLocationResume));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ExpeditionOverviewScreen), findsOneWidget);
    expect(find.text(UiStrings.expeditionActiveSection), findsOneWidget);
  });

  testWidgets('provider 异常时 fail closed 且不显示进入 CTA', (tester) async {
    await tester.pumpWidget(app(error: StateError('invalid config')));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.expeditionLocationUnavailable), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expedition-location-detail-enter')),
      findsNothing,
    );
    expect(find.textContaining('invalid config'), findsNothing);
  });

  testWidgets('进入 CTA 仍进入原远征总览派遣态', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.expeditionLocationEnter));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ExpeditionOverviewScreen), findsOneWidget);
    expect(find.text(UiStrings.expeditionDispatchTeamSection), findsOneWidget);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets(
      '常规桌面视口 ${size.width.toInt()}×${size.height.toInt()} 无 overflow',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(app());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ExpeditionLocationDetailScreen), findsOneWidget);
      },
    );
  }
}
