import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/main_menu/application/main_menu_status_summary_provider.dart';
import 'package:wuxia_idle/features/main_menu/presentation/main_menu_status_summary.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_providers.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';
import 'package:wuxia_idle/features/seclusion/presentation/seclusion_gate.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_state.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  Character character({
    required int id,
    required String name,
    int experience = 0,
    int experienceToNextLayer = 100,
    int lightInjuryStacks = 0,
    double injuryHoursRemaining = 0,
    double residueHours = 0,
  }) => Character.create(
    name: name,
    realmTier: RealmTier.xueTu,
    realmLayer: RealmLayer.qiMeng,
    attributes: Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 5,
    rarity: RarityTier.xunChang,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 6, 29),
    experience: experience,
    experienceToNextLayer: experienceToNextLayer,
    lightInjuryStacks: lightInjuryStacks,
    injuryHoursRemaining: injuryHoursRemaining,
    innerDemonResidueHoursRemaining: residueHours,
  )..id = id;

  RetreatSession retreat() => RetreatSession()
    ..saveDataId = 1
    ..mapType = RetreatMapType.shanLin
    ..durationHours = 4
    ..startedAt = DateTime.now().subtract(const Duration(minutes: 30))
    ..status = RetreatStatus.active;

  SaveData islandSave(double stored) {
    final building = IslandBuildingState()
      ..type = BuildingType.tieJiangChang
      ..stored = stored;
    return SaveData()..islandBuildings = [building];
  }

  MainlineProgress progress(List<String> cleared) => MainlineProgress()
    ..saveDataId = 1
    ..currentChapterIndex = 1
    ..clearedStageIds = cleared
    ..clearedAt = [for (final _ in cleared) DateTime(2026, 6, 29)];

  test('provider returns at most five items in fixed priority order', () async {
    final injured = character(
      id: 1,
      name: '甲',
      lightInjuryStacks: 1,
      injuryHoursRemaining: 3.5,
    );
    final ready = character(
      id: 2,
      name: '乙',
      experience: 120,
      experienceToNextLayer: 100,
    );

    final container = ProviderContainer(
      overrides: [
        activeRetreatSessionProvider.overrideWith((ref) async => retreat()),
        mainMenuSaveSnapshotProvider.overrideWith(
          (ref) async => islandSave(2.8),
        ),
        activeCharacterIdsProvider.overrideWith((ref) async => [1, 2]),
        characterByIdProvider(1).overrideWith((ref) async => injured),
        characterByIdProvider(2).overrideWith((ref) async => ready),
        mainlineProgressProvider.overrideWith(
          (ref) async => progress(['stage_01_01']),
        ),
      ],
    );
    addTearDown(container.dispose);

    final items = await container.read(mainMenuStatusSummaryProvider.future);

    expect(items, hasLength(5));
    expect(items.map((e) => e.kind), [
      MainMenuStatusKind.retreat,
      MainMenuStatusKind.island,
      MainMenuStatusKind.injury,
      MainMenuStatusKind.breakthrough,
      MainMenuStatusKind.mainline,
    ]);
    expect(items[1].detail, UiStrings.mainMenuStatusIslandDetail(2));
    expect(items[3].detail, UiStrings.mainMenuStatusBreakthroughDetail('乙'));
  });

  test(
    'provider falls back to next mainline target when no urgent status',
    () async {
      final founder = character(id: 1, name: '祖师', experience: 10);
      final container = ProviderContainer(
        overrides: [
          activeRetreatSessionProvider.overrideWith((ref) async => null),
          mainMenuSaveSnapshotProvider.overrideWith(
            (ref) async => islandSave(0.5),
          ),
          activeCharacterIdsProvider.overrideWith((ref) async => [1]),
          characterByIdProvider(1).overrideWith((ref) async => founder),
          mainlineProgressProvider.overrideWith(
            (ref) async => progress(['stage_01_01']),
          ),
        ],
      );
      addTearDown(container.dispose);

      final items = await container.read(mainMenuStatusSummaryProvider.future);

      expect(items, hasLength(1));
      expect(items.single.kind, MainMenuStatusKind.mainline);
      expect(
        items.single.detail,
        UiStrings.mainMenuStatusMainlineDetail(1, '荒山野店'),
      );
    },
  );

  testWidgets('panel renders summary and tap triggers Navigator.push', (
    tester,
  ) async {
    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mainMenuStatusSummaryProvider.overrideWith(
            (ref) async => const [
              MainMenuStatusSummaryItem(
                kind: MainMenuStatusKind.mainline,
                route: MainMenuStatusRoute.mainline,
                title: UiStrings.mainMenuStatusMainlineTitle,
                detail: UiStrings.mainMenuStatusMainlineCompleteDetail,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const Scaffold(body: MainMenuStatusSummaryPanel()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(UiStrings.mainMenuStatusSummaryTitle), findsOneWidget);
    expect(find.text(UiStrings.mainMenuStatusMainlineTitle), findsOneWidget);
    expect(
      find.text(UiStrings.mainMenuStatusMainlineCompleteDetail),
      findsOneWidget,
    );

    await tester.tap(find.text(UiStrings.mainMenuStatusMainlineTitle));
    await tester.pump();

    expect(observer.pushedRoutes.length, 2);
    expect(observer.pushedRoutes.last, isA<MaterialPageRoute<void>>());
  });
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}
