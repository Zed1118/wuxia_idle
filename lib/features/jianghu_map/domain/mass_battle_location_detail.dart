import '../../../core/domain/enums.dart';
import '../../loot_preview/domain/drop_rumor.dart';

class MassBattleLocationEnemySummary {
  const MassBattleLocationEnemySummary({
    required this.name,
    required this.school,
  });

  final String name;
  final TechniqueSchool school;
}

class MassBattleLocationDetail {
  const MassBattleLocationDetail({
    required this.clearedRoutes,
    required this.totalRoutes,
    required this.nextStageId,
    required this.nextStageName,
    required this.recommendedRealm,
    required this.formation,
    required this.waveCount,
    required this.enemyTotal,
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
  final Formation? formation;
  final int? waveCount;
  final int? enemyTotal;
  final List<MassBattleLocationEnemySummary> enemies;
  final DropRumorTable? rewardRumor;
  final int? baseExpReward;
  final int eligibleParticipantCount;

  bool get isComplete => nextStageId == null;
  bool get hasEligibleParticipant => eligibleParticipantCount > 0;
}
