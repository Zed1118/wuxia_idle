import '../../../core/domain/enums.dart';
import '../../expedition/domain/expedition_run.dart';

class ExpeditionLocationEnemySummary {
  const ExpeditionLocationEnemySummary({
    required this.name,
    required this.realmTier,
    required this.school,
  });

  final String name;
  final RealmTier realmTier;
  final TechniqueSchool school;
}

class ExpeditionLocationEnemyTeamSummary {
  const ExpeditionLocationEnemyTeamSummary({
    required this.id,
    required this.enemies,
  });

  final String id;
  final List<ExpeditionLocationEnemySummary> enemies;
}

/// 百草岭地点详情的只读生产快照。
///
/// [recommendedRealm] 只表示当前 YAML 敌队池的基础最高境界；
/// 高周目还会按已有 realm advance 规则推进，展示层不把它
/// 写成本次会话的精确敌境。
class ExpeditionLocationDetail {
  const ExpeditionLocationDetail({
    required this.historicalMaxDepth,
    required this.activeDepth,
    required this.activePolicy,
    required this.activeCycleIndex,
    required this.activeDefeated,
    required this.recommendedRealm,
    required this.normalNodeMinutes,
    required this.eliteNodeMinutes,
    required this.normalEnemyTeams,
    required this.eliteEnemyTeams,
    required this.coreRewardItemNames,
    required this.includesExperienceReward,
    required this.candidateCount,
    required this.availableCandidateCount,
    required this.activeParticipantNames,
  });

  final int historicalMaxDepth;
  final int? activeDepth;
  final ExpeditionPolicy? activePolicy;
  final int? activeCycleIndex;
  final bool activeDefeated;
  final RealmTier recommendedRealm;
  final int normalNodeMinutes;
  final int eliteNodeMinutes;
  final List<ExpeditionLocationEnemyTeamSummary> normalEnemyTeams;
  final List<ExpeditionLocationEnemyTeamSummary> eliteEnemyTeams;
  final List<String> coreRewardItemNames;
  final bool includesExperienceReward;
  final int candidateCount;
  final int availableCandidateCount;
  final List<String> activeParticipantNames;

  bool get hasActiveRun => activeDepth != null;
}
