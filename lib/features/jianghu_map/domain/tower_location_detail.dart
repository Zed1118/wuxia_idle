import '../../../core/domain/enums.dart';
import '../../loot_preview/domain/drop_rumor.dart';

class TowerLocationEnemySummary {
  const TowerLocationEnemySummary({required this.name, required this.school});

  final String name;
  final TechniqueSchool school;
}

/// 九霄塔地点详情的只读生产快照。
///
/// [nextFloorIndex] 为 null 表示已登顶；此时下一层情报字段也必须为 null/空。
class TowerLocationDetail {
  const TowerLocationDetail({
    required this.highestClearedFloor,
    required this.totalFloors,
    required this.nextFloorIndex,
    required this.recommendedRealm,
    required this.enemies,
    required this.rewardRumor,
    required this.baseExpReward,
    required this.participantId,
    required this.participantName,
  });

  final int highestClearedFloor;
  final int totalFloors;
  final int? nextFloorIndex;
  final RealmTier? recommendedRealm;
  final List<TowerLocationEnemySummary> enemies;
  final DropRumorTable? rewardRumor;
  final int? baseExpReward;
  final int participantId;
  final String participantName;

  bool get isComplete => nextFloorIndex == null;
}
