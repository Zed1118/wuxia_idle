import '../domain/tower_floor_def.dart';
import '../domain/tower_progress.dart';
import 'tower_progress_service.dart';

/// Pure read model for the tower progress header.
///
/// It derives display-only milestone state from persisted [TowerProgress] plus
/// the configured floor list. It must not own progression, reward, or unlock
/// rules.
class TowerProgressSummary {
  const TowerProgressSummary({
    required this.highestClearedFloor,
    required this.currentFloor,
    required this.totalFloors,
    required this.nextMilestone,
  });

  final int highestClearedFloor;
  final int currentFloor;
  final int totalFloors;
  final TowerFloorDef? nextMilestone;

  bool get isComplete => totalFloors > 0 && highestClearedFloor >= totalFloors;

  bool get hasAnyClear => highestClearedFloor > 0;

  double get progressRatio {
    if (totalFloors <= 0) return 0;
    return (highestClearedFloor / totalFloors).clamp(0.0, 1.0);
  }

  static TowerProgressSummary from({
    required TowerProgress progress,
    required List<TowerFloorEntry> entries,
  }) {
    final total = entries.length;
    final highest = progress.highestClearedFloor.clamp(0, total);
    final current = highest >= total ? total : highest + 1;

    TowerFloorDef? nextMilestone;
    for (final entry in entries) {
      final floor = entry.def.floorIndex;
      if (floor <= highest) continue;
      if (entry.def.isBoss || floor == total) {
        nextMilestone = entry.def;
        break;
      }
    }

    return TowerProgressSummary(
      highestClearedFloor: highest,
      currentFloor: current,
      totalFloors: total,
      nextMilestone: nextMilestone,
    );
  }
}
