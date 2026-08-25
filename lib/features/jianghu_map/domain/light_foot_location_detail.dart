import '../../../core/domain/enums.dart';
import '../../loot_preview/domain/drop_rumor.dart';

class LightFootLocationEnemySummary {
  const LightFootLocationEnemySummary({
    required this.name,
    required this.school,
  });

  final String name;
  final TechniqueSchool school;
}

/// 轻功试炼地点详情的只读生产快照。
///
/// [nextStageId] 为 null 表示五条路线已全部通过；此时下一路线
/// 情报字段也必须为 null/空。
class LightFootLocationDetail {
  const LightFootLocationDetail({
    required this.clearedRoutes,
    required this.totalRoutes,
    required this.nextStageId,
    required this.nextStageName,
    required this.recommendedRealm,
    required this.terrainBiome,
    required this.enemies,
    required this.rewardRumor,
    required this.baseExpReward,
    required this.eligibleParticipantCount,
  });

  final int clearedRoutes;
  final int totalRoutes;
  final String? nextStageId;
  final String? nextStageName;
  final RealmTier? recommendedRealm;
  final TerrainBiome? terrainBiome;
  final List<LightFootLocationEnemySummary> enemies;
  final DropRumorTable? rewardRumor;
  final int? baseExpReward;
  final int eligibleParticipantCount;

  bool get isComplete => nextStageId == null;
  bool get hasEligibleParticipant => eligibleParticipantCount > 0;
}
