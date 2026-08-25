import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/jianghu_map/application/light_foot_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/light_foot_location_detail.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/light_foot_location_detail_screen.dart';
import 'package:wuxia_idle/features/light_foot/presentation/light_foot_screen.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  LightFootLocationDetail detail({bool complete = false}) {
    final stage = GameRepository.instance.getStage('stage_light_foot_03');
    return LightFootLocationDetail(
      clearedRoutes: complete ? 5 : 2,
      totalRoutes: 5,
      nextStageId: complete ? null : stage.id,
      nextStageName: complete ? null : stage.name,
      recommendedRealm: complete ? null : stage.requiredRealm,
      terrainBiome: complete ? null : stage.terrainBiome,
      enemies: complete
          ? const []
          : [
              for (final enemy in stage.enemyTeam)
                LightFootLocationEnemySummary(
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
      eligibleParticipantCount: 2,
    );
  }

  Widget app({
    LightFootLocationDetail? value,
    Object? error,
    RetreatSession? retreat,
  }) => ProviderScope(
    overrides: [
      lightFootLocationDetailProvider.overrideWith(
        (ref) => error == null
            ? Future.value(value ?? detail())
            : Future.error(error),
      ),
      mainlineProgressProvider.overrideWith(
        (ref) async => MainlineProgress()
          ..clearedStageIds = const [
            'stage_06_05',
            'stage_light_foot_01',
            'stage_light_foot_02',
          ],
      ),
      activeRetreatSessionProvider.overrideWith((ref) async => retreat),
    ],
    child: const MaterialApp(home: LightFootLocationDetailScreen()),
  );

  testWidgets('展示轻功地点的七类权威信息', (tester) async {
    final value = detail();
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    expect(
      find.text(
        UiStrings.lightFootLocationProgress(
          value.clearedRoutes,
          value.totalRoutes,
          value.nextStageName!,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.lightFootLocationEligibleParticipants(2)),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.lightFootLocationEntryModeDirect),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.lightFootLocationExpectedOccupancy),
      findsOneWidget,
    );
    expect(find.text(UiStrings.lightFootLocationEnter), findsOneWidget);
    expect(find.textContaining(value.enemies.first.name), findsOneWidget);
  });

  testWidgets('全通态明确无下一路且仍提供重打入口', (tester) async {
    final value = detail(complete: true);
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    expect(
      find.text(
        UiStrings.lightFootLocationCompleteProgress(
          value.clearedRoutes,
          value.totalRoutes,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(UiStrings.lightFootLocationNoNextRoute), findsNWidgets(4));
    expect(
      find.byKey(const ValueKey('light-foot-location-detail-enter')),
      findsOneWidget,
    );
  });

  testWidgets('provider 异常时 fail closed 且不显示进入 CTA', (tester) async {
    await tester.pumpWidget(app(error: StateError('dangling leader')));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.lightFootLocationUnavailable), findsOneWidget);
    expect(
      find.byKey(const ValueKey('light-foot-location-detail-enter')),
      findsNothing,
    );
    expect(find.textContaining('dangling leader'), findsNothing);
  });

  testWidgets('没有空闲合格参与者时入口 fail closed', (tester) async {
    final value = LightFootLocationDetail(
      clearedRoutes: detail().clearedRoutes,
      totalRoutes: detail().totalRoutes,
      nextStageId: detail().nextStageId,
      nextStageName: detail().nextStageName,
      recommendedRealm: detail().recommendedRealm,
      terrainBiome: detail().terrainBiome,
      enemies: detail().enemies,
      rewardRumor: detail().rewardRumor,
      baseExpReward: detail().baseExpReward,
      eligibleParticipantCount: 0,
    );
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    final button = tester.widget<WuxiaInkButton>(
      find.byKey(const ValueKey('light-foot-location-detail-enter')),
    );
    expect(button.disabled, isTrue);
    expect(button.onTap, isNull);
  });

  testWidgets('进入 CTA 经原门禁放行后进入轻功关卡列表', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.lightFootLocationEnter));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(LightFootScreen), findsOneWidget);
  });

  testWidgets('掌门闭关时地点入口仍允许空闲门人进入逐次选人', (tester) async {
    final retreat = RetreatSession()
      ..saveDataId = 0
      ..mapType = RetreatMapType.shanLin
      ..startedAt = DateTime(2026, 8, 25);
    await tester.pumpWidget(app(retreat: retreat));
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.lightFootLocationEnter));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.seclusionBattleLockTitle), findsNothing);
    expect(find.byType(LightFootScreen), findsOneWidget);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('轻功地点详情 ${size.width.toInt()}x${size.height.toInt()} 无布局异常', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('light-foot-location-detail-intel')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.lightFootLocationEnter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
