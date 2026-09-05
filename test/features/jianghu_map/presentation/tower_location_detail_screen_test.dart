import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/jianghu_map/application/tower_location_detail_provider.dart';
import 'package:wuxia_idle/features/jianghu_map/domain/tower_location_detail.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/tower_location_detail_screen.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_floor_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ink_button.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  TowerLocationDetail detail({
    bool complete = false,
    int eligibleParticipantCount = 2,
  }) {
    final repository = GameRepository.instance;
    final floor = repository.getTowerFloor(7);
    return TowerLocationDetail(
      highestClearedFloor: complete ? repository.towerMaxFloor : 6,
      totalFloors: repository.towerMaxFloor,
      nextFloorIndex: complete ? null : floor.floorIndex,
      recommendedRealm: complete ? null : floor.requiredRealm,
      enemies: complete
          ? const []
          : [
              for (final enemy in floor.enemyTeam)
                TowerLocationEnemySummary(
                  name: enemy.name,
                  school: enemy.school,
                ),
            ],
      rewardRumor: complete
          ? null
          : DropRumorTable.fromDropTable(
              floor.dropTable,
              gating: FirstClearGating.wholeChannel,
            ),
      baseExpReward: complete ? null : floor.baseExpReward,
      eligibleParticipantCount: eligibleParticipantCount,
    );
  }

  Widget app({
    TowerLocationDetail? value,
    Object? error,
    RetreatSession? retreat,
  }) => ProviderScope(
    overrides: [
      towerLocationDetailProvider.overrideWith(
        (ref) => error == null
            ? Future.value(value ?? detail())
            : Future.error(error),
      ),
      activeRetreatSessionProvider.overrideWith((ref) async => retreat),
    ],
    child: const MaterialApp(home: TowerLocationDetailScreen()),
  );

  testWidgets('展示七类权威地点信息', (tester) async {
    final value = detail();
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.text(UiStrings.towerLocationProgressLabel))
          .style
          ?.color,
      WuxiaUi.muted,
      reason: 'Light paper labels must not inherit pale dark-surface text.',
    );

    expect(
      find.text(
        UiStrings.towerLocationProgress(
          value.highestClearedFloor,
          value.totalFloors,
          value.nextFloorIndex!,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.towerLocationEligibleParticipants(2)),
      findsOneWidget,
    );
    expect(find.text(UiStrings.towerLocationEntryModeDirect), findsOneWidget);
    expect(find.text(UiStrings.towerLocationExpectedOccupancy), findsOneWidget);
    expect(find.text('首次亲自挑战；已通层可差遣历练'), findsOneWidget);
    expect(find.text('差遣期间锁定所选角色及其装配'), findsOneWidget);
    expect(find.text('亲自挑战，不可派遣'), findsNothing);
    expect(find.text(UiStrings.towerLocationEnter), findsOneWidget);
    expect(find.textContaining(value.enemies.first.name), findsOneWidget);
  });

  testWidgets('没有空闲合格参与者时入口 fail closed', (tester) async {
    await tester.pumpWidget(app(value: detail(eligibleParticipantCount: 0)));
    await tester.pumpAndSettle();

    final button = tester.widget<WuxiaInkButton>(
      find.byKey(const ValueKey('tower-location-detail-enter')),
    );
    expect(button.disabled, isTrue);
    expect(button.onTap, isNull);
  });

  testWidgets('登顶态明确无下一层且仍提供重打入口', (tester) async {
    final value = detail(complete: true);
    await tester.pumpWidget(app(value: value));
    await tester.pumpAndSettle();

    expect(
      find.text(
        UiStrings.towerLocationCompleteProgress(
          value.highestClearedFloor,
          value.totalFloors,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(UiStrings.towerLocationNoNextFloor), findsNWidgets(3));
    expect(
      find.byKey(const ValueKey('tower-location-detail-enter')),
      findsOneWidget,
    );
  });

  testWidgets('provider 异常时 fail closed 且不显示进入 CTA', (tester) async {
    await tester.pumpWidget(app(error: StateError('dangling leader')));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.towerLocationUnavailable), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tower-location-detail-enter')),
      findsNothing,
    );
    expect(find.textContaining('dangling leader'), findsNothing);
  });

  testWidgets('进入 CTA 经原门禁放行后进入塔层列表', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.towerLocationEnter));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(TowerFloorListScreen), findsOneWidget);
  });

  testWidgets('有角色闭关时仍进入塔层列表并在逐次选人时精确拦人', (tester) async {
    final retreat = RetreatSession()
      ..saveDataId = 0
      ..mapType = RetreatMapType.shanLin
      ..startedAt = DateTime(2026, 8, 25);
    await tester.pumpWidget(app(retreat: retreat));
    await tester.pumpAndSettle();

    await tester.tap(find.text(UiStrings.towerLocationEnter));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text(UiStrings.seclusionBattleLockTitle), findsNothing);
    expect(find.byType(TowerFloorListScreen), findsOneWidget);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('地点详情 ${size.width.toInt()}x${size.height.toInt()} 无布局异常', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('tower-location-detail-intel')),
        findsOneWidget,
      );
      expect(find.text(UiStrings.towerLocationEnter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
