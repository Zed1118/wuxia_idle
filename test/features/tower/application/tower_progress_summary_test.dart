import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_service.dart';
import 'package:wuxia_idle/features/tower/application/tower_progress_summary.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import '../../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
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

  // 批 A 塔 49 层重排:首个 Boss 位 = tier 中点 floor 4(minor,结构规则见
  // progression_red_lines_validator);顶层与里程碑断言从生产数据派生不写死。
  test('new tower points current floor at 1 and next milestone at floor 4', () {
    final summary = summaryFor(0);

    expect(summary.highestClearedFloor, 0);
    expect(summary.currentFloor, 1);
    expect(summary.progressRatio, 0);
    expect(summary.nextMilestone?.floorIndex, 4);
    expect(summary.nextMilestone?.bossKind, TowerBossKind.minor);
  });

  test('after floor 3 next milestone remains the minor boss at floor 4', () {
    final summary = summaryFor(3);

    expect(summary.highestClearedFloor, 3);
    expect(summary.currentFloor, 4);
    expect(summary.nextMilestone?.floorIndex, 4);
    expect(summary.nextMilestone?.bossKind, TowerBossKind.minor);
  });

  test('completed tower is capped and has no next milestone', () {
    final maxFloor = GameRepository.instance.towerMaxFloor;
    final summary = summaryFor(maxFloor);

    expect(summary.isComplete, isTrue);
    expect(summary.highestClearedFloor, maxFloor);
    expect(summary.currentFloor, maxFloor);
    expect(summary.progressRatio, 1);
    expect(summary.nextMilestone, isNull);
  });
}
