import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/application/tower_providers.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/features/tower/presentation/leaderboard_screen.dart';
import 'package:wuxia_idle/features/tower/presentation/tower_floor_list_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

import '../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TowerProgress progress() {
    return TowerProgress()
      ..saveDataId = 1
      ..highestClearedFloor = 5
      ..highestClearedAt = DateTime(2026, 8, 25)
      ..totalAttempts = 8
      ..totalDefeats = 2
      ..bestClearTime = 12000
      ..createdAt = DateTime(2026, 8, 25);
  }

  Future<void> pumpTower(WidgetTester tester) async {
    final towerProgress = progress();
    final floors = TowerProgressService.floorList(
      progress: towerProgress,
      allFloors: GameRepository.instance.towerFloors,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          towerProgressProvider.overrideWith((ref) async => towerProgress),
          towerFloorListProvider.overrideWith((ref) async => floors),
        ],
        child: const MaterialApp(home: TowerFloorListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('九霄塔标题栏提供可访问的排行榜动作', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTower(tester);

    final action = find.byKey(const ValueKey('tower-leaderboard-action'));
    expect(action, findsOneWidget);
    expect(
      find.descendant(
        of: action,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == UiStrings.mainMenuLeaderboard &&
              widget.properties.button == true,
        ),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip(UiStrings.mainMenuLeaderboard), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('点击九霄塔排行榜动作进入现有本地排行榜页', (tester) async {
    await pumpTower(tester);

    await tester.tap(find.byKey(const ValueKey('tower-leaderboard-action')));
    await tester.pumpAndSettle();

    expect(find.byType(LeaderboardScreen), findsOneWidget);
    expect(find.text(UiStrings.leaderboardHighestLayer), findsOneWidget);
    expect(find.text('5 ${UiStrings.leaderboardLayerSuffix}'), findsOneWidget);
  });
}
