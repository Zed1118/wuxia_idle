import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_loadout_screen.dart';
import 'package:wuxia_idle/features/jianghu_map/application/gauntlet_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/gauntlet_location_detail.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/gauntlet_location_detail_screen.dart';
import 'package:wuxia_idle/shared/battle_shared/enum_localizations.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  GauntletLocationDetail detail({bool active = false}) =>
      GauntletLocationDetail(
        clearedCyclesMax: 2,
        totalStages: 3,
        activeStage: active ? 2 : null,
        activePhase: active ? GauntletPhase.interlude : null,
        recommendedRealm: RealmTier.erLiu,
        stages: const [
          GauntletLocationStageSummary(
            ordinal: 1,
            isBoss: false,
            enemies: [
              GauntletLocationEnemySummary(
                name: '苏无咎',
                school: TechniqueSchool.lingQiao,
              ),
            ],
          ),
          GauntletLocationStageSummary(
            ordinal: 2,
            isBoss: false,
            enemies: [
              GauntletLocationEnemySummary(
                name: '石镇岳',
                school: TechniqueSchool.gangMeng,
              ),
            ],
          ),
          GauntletLocationStageSummary(
            ordinal: 3,
            isBoss: true,
            enemies: [
              GauntletLocationEnemySummary(
                name: '闻九针',
                school: TechniqueSchool.yinRou,
              ),
            ],
          ),
        ],
        rewardSkillName: '锁脉针法',
        rewardEquipmentNames: const ['锁脉囊', '镇岳铁衣', '摄魂铃'],
        firstClearRewardExp: 300,
        firstClearRewardInsight: 20,
        eliteRewardExp: 50,
        ticketCount: 3,
        supplyCap: 3,
        candidateCount: 4,
        availableCandidateCount: 2,
        activeParticipantNames: active ? const ['沈无归'] : const [],
      );

  Widget app({GauntletLocationDetail? value, Object? error}) => ProviderScope(
    overrides: [
      gauntletLocationDetailProvider.overrideWith(
        (ref) => error == null
            ? Future.value(value ?? detail())
            : Future.error(error),
      ),
      gauntletConfigProvider.overrideWithValue(
        GameRepository.instance.bossGauntletConfig,
      ),
      gauntletCandidatesProvider.overrideWith((ref) async => const []),
      gauntletLoadoutInfoProvider.overrideWith(
        (ref) async => const GauntletLoadoutInfo(ticketCount: 0, supplies: []),
      ),
      activeGauntletProvider.overrideWith((ref) async => null),
    ],
    child: const MaterialApp(home: GauntletLocationDetailScreen()),
  );

  testWidgets('展示断魂庄进度、境界、三关敌情、奖励与可用参与者', (tester) async {
    final value = detail();
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    expect(
      find.text(
        UiStrings.gauntletLocationProgress(
          value.clearedCyclesMax,
          value.totalStages,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(EnumL10n.realmTier(value.recommendedRealm)),
      findsOneWidget,
    );
    expect(find.textContaining('苏无咎'), findsOneWidget);
    expect(find.textContaining('锁脉针法'), findsOneWidget);
    expect(
      find.text(
        UiStrings.gauntletLocationParticipantCandidates(
          value.availableCandidateCount,
          value.candidateCount,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.gauntletLocationEntryModeDirect),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.gauntletLocationExpectedOccupancy),
      findsOneWidget,
    );
    expect(find.text(UiStrings.gauntletLocationEnter), findsOneWidget);
  });

  testWidgets('进行中庄局展示关次、阶段、真实参与者和续行 CTA', (tester) async {
    final value = detail(active: true);
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    expect(
      find.text(
        UiStrings.gauntletLocationActiveProgress(
          value.activeStage!,
          value.totalStages,
          UiStrings.gauntletPhaseInterlude,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('沈无归'), findsOneWidget);
    expect(find.text(UiStrings.gauntletLocationResume), findsOneWidget);
  });

  testWidgets('provider 异常时 fail closed 且不显示进入 CTA', (tester) async {
    await tester.pumpWidget(app(error: StateError('invalid config')));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.gauntletLocationUnavailable), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gauntlet-location-detail-enter')),
      findsNothing,
    );
    expect(find.textContaining('invalid config'), findsNothing);
  });

  testWidgets('进入 CTA 仍进入原断魂庄整备屏', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.gauntletLocationEnter));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(GauntletLoadoutScreen), findsOneWidget);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('断魂庄地点详情 ${size.width.toInt()}x${size.height.toInt()} 无布局异常', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('gauntlet-location-detail-intel')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.gauntletLocationEnter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
