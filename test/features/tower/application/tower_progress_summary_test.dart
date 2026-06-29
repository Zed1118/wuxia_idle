import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_summary.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  TowerProgress progress(int highest) => TowerProgress()
    ..saveDataId = 1
    ..highestClearedFloor = highest
    ..createdAt = DateTime(2026, 6, 29);

  TowerProgressSummary summaryFor(int highest) {
    final p = progress(highest);
    final entries = TowerProgressService.floorList(
      progress: p,
      allFloors: GameRepository.instance.towerFloors,
    );
    return TowerProgressSummary.from(progress: p, entries: entries);
  }

  test('new tower points current floor at 1 and next milestone at floor 5', () {
    final summary = summaryFor(0);

    expect(summary.highestClearedFloor, 0);
    expect(summary.currentFloor, 1);
    expect(summary.progressRatio, 0);
    expect(summary.nextMilestone?.floorIndex, 5);
    expect(summary.nextMilestone?.bossKind, TowerBossKind.minor);
  });

  test('after floor 3 next milestone remains the minor boss at floor 5', () {
    final summary = summaryFor(3);

    expect(summary.highestClearedFloor, 3);
    expect(summary.currentFloor, 4);
    expect(summary.nextMilestone?.floorIndex, 5);
    expect(summary.nextMilestone?.bossKind, TowerBossKind.minor);
  });

  test('completed tower is capped and has no next milestone', () {
    final summary = summaryFor(30);

    expect(summary.isComplete, isTrue);
    expect(summary.highestClearedFloor, 30);
    expect(summary.currentFloor, 30);
    expect(summary.progressRatio, 1);
    expect(summary.nextMilestone, isNull);
  });
}
