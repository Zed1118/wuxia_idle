import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_providers.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_providers.dart';
import 'package:wuxia_idle/features/jianghu_map/presentation/jianghu_map_screen.dart';
import 'package:wuxia_idle/features/light_foot/presentation/light_foot_screen.dart';
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/mass_battle/presentation/mass_battle_screen.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_floor_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

  TowerProgress progressAt(int highest) => TowerProgress()
    ..saveDataId = 0
    ..highestClearedFloor = highest;

  Widget app({
    int highest = 6,
    List<String> clearedStageIds = const [],
    bool journeyUnlocked = false,
    BossGauntletRun? activeGauntlet,
  }) => ProviderScope(
    overrides: [
      towerProgressProvider.overrideWith((ref) async => progressAt(highest)),
      mainlineProgressProvider.overrideWith(
        (ref) async => MainlineProgress()..clearedStageIds = clearedStageIds,
      ),
      activeRetreatSessionProvider.overrideWith((ref) async => null),
      mainMenuSaveSnapshotProvider.overrideWith(
        (ref) async => SaveData()..jianghuJourneyUnlocked = journeyUnlocked,
      ),
      activeGauntletProvider.overrideWith((ref) async => activeGauntlet),
      activeExpeditionProvider.overrideWith((ref) async => null),
    ],
    child: const MaterialApp(home: JianghuMapScreen()),
  );

  test('九霄塔地点状态继续读取生产塔数据', () {
    expect(
      jianghuMapTowerStatus(progressAt(6)),
      UiStrings.mainMenuTowerBossStatus(6, 7),
    );
  });

  testWidgets('地图显示九霄塔地点与生产进度状态', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text(UiStrings.jianghuMapTitle), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTower), findsOneWidget);
    expect(find.text(UiStrings.mainMenuTowerBossStatus(6, 7)), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLightFoot), findsOneWidget);
    expect(find.text(UiStrings.mainMenuLateGameLockedHint), findsNWidgets(2));
    expect(find.text(UiStrings.mainMenuMassBattle), findsOneWidget);
    expect(find.text(UiStrings.mainMenuJianghu), findsOneWidget);
  });

  test('轻功地点锁定和进度从生产链派生', () {
    final locked = jianghuMapLightFootLocationState(MainlineProgress());
    expect(locked.locked, isTrue);
    expect(locked.status, UiStrings.mainMenuLateGameLockedHint);

    final inconsistent = jianghuMapLightFootLocationState(
      MainlineProgress()..clearedStageIds = const ['stage_light_foot_01'],
    );
    expect(inconsistent.locked, isTrue);
    expect(inconsistent.status, UiStrings.mainMenuLateGameLockedHint);

    final progressed = jianghuMapLightFootLocationState(
      MainlineProgress()
        ..clearedStageIds = const [
          'stage_06_05',
          'stage_light_foot_01',
          'stage_light_foot_02',
        ],
    );
    expect(progressed.locked, isFalse);
    expect(progressed.status, UiStrings.jianghuMapLightFootProgress(2, 5));
  });

  test('守城地点锁定和进度从生产链派生', () {
    final locked = jianghuMapMassBattleLocationState(MainlineProgress());
    expect(locked.locked, isTrue);
    expect(locked.status, UiStrings.mainMenuLateGameLockedHint);

    final inconsistent = jianghuMapMassBattleLocationState(
      MainlineProgress()..clearedStageIds = const ['stage_mass_battle_01'],
    );
    expect(inconsistent.locked, isTrue);
    expect(inconsistent.status, UiStrings.mainMenuLateGameLockedHint);

    final progressed = jianghuMapMassBattleLocationState(
      MainlineProgress()
        ..clearedStageIds = const [
          'stage_06_05',
          'stage_mass_battle_01',
          'stage_mass_battle_02',
        ],
    );
    expect(progressed.locked, isFalse);
    expect(progressed.status, UiStrings.jianghuMapMassBattleProgress(2, 5));
  });

  test('断魂庄地点状态读取进行中庄局关次与阶段', () {
    expect(jianghuMapGauntletStatus(null), isNull);

    final run = BossGauntletRun()
      ..saveDataId = 0
      ..seed = 7
      ..currentStage = 2
      ..sessionPhase = GauntletPhase.interlude;
    expect(
      jianghuMapGauntletStatus(run),
      UiStrings.gauntletResumeHint(2, UiStrings.gauntletPhaseInterlude),
    );
  });

  testWidgets('断魂庄地点显示进行中庄局状态', (tester) async {
    final run = BossGauntletRun()
      ..saveDataId = 0
      ..seed = 7
      ..currentStage = 3
      ..sessionPhase = GauntletPhase.awaitingRewardChoice;
    await tester.pumpWidget(app(journeyUnlocked: true, activeGauntlet: run));
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.gauntletName), findsOneWidget);
    expect(
      find.text(
        UiStrings.gauntletResumeHint(3, UiStrings.gauntletPhaseAwaitingReward),
      ),
      findsOneWidget,
    );
  });

  testWidgets('九霄塔地点仍经生产入口进入 TowerFloorListScreen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.tap(find.text(UiStrings.mainMenuTower));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(TowerFloorListScreen), findsOneWidget);
  });

  testWidgets('轻功地点在原 Ch6 门槛前保持锁定且不导航', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text(UiStrings.mainMenuLightFoot));
    await tester.pump();

    expect(find.byType(LightFootScreen), findsNothing);
  });

  testWidgets('守城地点在原 Ch6 门槛前保持锁定且不导航', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text(UiStrings.mainMenuMassBattle));
    await tester.pump();

    expect(find.byType(MassBattleScreen), findsNothing);
  });

  for (final size in [const Size(1280, 720), const Size(1440, 900)]) {
    testWidgets('江湖地图 ${size.width.toInt()}x${size.height.toInt()} 无布局异常', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(journeyUnlocked: true));
      await tester.pump();

      expect(find.text(UiStrings.mainMenuTower), findsOneWidget);
      expect(find.text(UiStrings.mainMenuLightFoot), findsOneWidget);
      expect(find.text(UiStrings.mainMenuMassBattle), findsOneWidget);
      expect(find.text(UiStrings.gauntletName), findsOneWidget);
      expect(find.text(UiStrings.expeditionBaicaoName), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('jianghu-map-reputation-location')),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text(UiStrings.mainMenuJianghu), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
