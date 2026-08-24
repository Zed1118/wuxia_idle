import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/jianghu_map/application/mass_battle_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/mass_battle_location_detail.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/mass_battle_location_detail_screen.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mass_battle/presentation/mass_battle_screen.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  MassBattleLocationDetail detail({bool complete = false}) {
    final stage = GameRepository.instance.getStage('stage_mass_battle_03');
    return MassBattleLocationDetail(
      clearedRoutes: complete ? 5 : 2,
      totalRoutes: 5,
      nextStageId: complete ? null : stage.id,
      nextStageName: complete ? null : stage.name,
      recommendedRealm: complete ? null : stage.requiredRealm,
      formation: complete ? null : Formation.fengShi,
      waveCount: complete ? null : stage.massBattleWaveCount,
      enemyTotal: complete
          ? null
          : stage.massBattleEnemyCounts!.fold<int>(
              0,
              (sum, value) => sum + value,
            ),
      enemies: complete
          ? const []
          : [
              for (final enemy in stage.enemyTeam)
                MassBattleLocationEnemySummary(
                  name: enemy.name,
                  school: enemy.school,
                ),
            ],
      rewardRumor: complete
          ? null
          : DropRumorTable.fromDropTable(
              stage.dropTable,
              gating: FirstClearGating.wholeChannel,
            ),
      baseExpReward: complete ? null : stage.baseExpReward,
      participantId: 7,
      participantName: '沈掌门',
    );
  }

  Widget app({
    MassBattleLocationDetail? value,
    Object? error,
    RetreatSession? retreat,
  }) => ProviderScope(
    overrides: [
      massBattleLocationDetailProvider.overrideWith(
        (ref) => error == null
            ? Future.value(value ?? detail())
            : Future.error(error),
      ),
      mainlineProgressProvider.overrideWith(
        (ref) async => MainlineProgress()
          ..clearedStageIds = const [
            'stage_06_05',
            'stage_mass_battle_01',
            'stage_mass_battle_02',
          ],
      ),
      activeRetreatSessionProvider.overrideWith((ref) async => retreat),
    ],
    child: const MaterialApp(home: MassBattleLocationDetailScreen()),
  );

  testWidgets('展示守城地点的生产进度、阵势、敌情、奖励与参与者', (tester) async {
    final value = detail();
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    expect(
      find.text(
        UiStrings.massBattleLocationProgress(
          value.clearedRoutes,
          value.totalRoutes,
          value.nextStageName!,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        UiStrings.massBattleLocationBattlePlan(
          value.waveCount!,
          value.enemyTotal!,
          value.formation!,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('沈掌门'), findsOneWidget);
    expect(
      find.text(UiStrings.massBattleLocationEntryModeDirect),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.massBattleLocationExpectedOccupancy),
      findsOneWidget,
    );
    expect(find.text(UiStrings.massBattleLocationEnter), findsOneWidget);
    expect(find.textContaining(value.enemies.first.name), findsOneWidget);
  });

  testWidgets('全通态明确无下一关且仍提供重打入口', (tester) async {
    final value = detail(complete: true);
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    expect(
      find.text(
        UiStrings.massBattleLocationCompleteProgress(
          value.clearedRoutes,
          value.totalRoutes,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.massBattleLocationNoNextStage),
      findsNWidgets(4),
    );
    expect(
      find.byKey(const ValueKey('mass-battle-location-detail-enter')),
      findsOneWidget,
    );
  });

  testWidgets('provider 异常时 fail closed 且不显示进入 CTA', (tester) async {
    await tester.pumpWidget(app(error: StateError('invalid graph')));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.massBattleLocationUnavailable), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mass-battle-location-detail-enter')),
      findsNothing,
    );
    expect(find.textContaining('invalid graph'), findsNothing);
  });

  testWidgets('进入 CTA 经原门禁放行后进入守城关卡列表', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.massBattleLocationEnter));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(MassBattleScreen), findsOneWidget);
  });

  testWidgets('闭关进行中时进入 CTA 被原门禁阻挡', (tester) async {
    final retreat = RetreatSession()
      ..saveDataId = 0
      ..mapType = RetreatMapType.shanLin
      ..startedAt = DateTime(2026, 8, 25);
    await tester.pumpWidget(app(retreat: retreat));
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.massBattleLocationEnter));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.seclusionBattleLockTitle), findsOneWidget);
    expect(find.byType(MassBattleScreen), findsNothing);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('守城地点详情 ${size.width.toInt()}x${size.height.toInt()} 无布局异常', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('mass-battle-location-detail-intel')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.massBattleLocationEnter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
