import '../../../core/domain/enums.dart';
import '../../boss_gauntlet/domain/boss_gauntlet_run.dart';

class GauntletLocationEnemySummary {
  const GauntletLocationEnemySummary({
    required this.name,
    required this.school,
  });

  final String name;
  final TechniqueSchool school;
}

class GauntletLocationStageSummary {
  const GauntletLocationStageSummary({
    required this.ordinal,
    required this.isBoss,
    required this.enemies,
  });

  final int ordinal;
  final bool isBoss;
  final List<GauntletLocationEnemySummary> enemies;
}

class GauntletLocationDetail {
  const GauntletLocationDetail({
    required this.clearedCyclesMax,
    required this.totalStages,
    required this.activeStage,
    required this.activePhase,
    required this.recommendedRealm,
    required this.stages,
    required this.rewardSkillName,
    required this.rewardEquipmentNames,
    required this.firstClearRewardExp,
    required this.firstClearRewardInsight,
    required this.eliteRewardExp,
    required this.ticketCount,
    required this.supplyCap,
    required this.candidateCount,
    required this.availableCandidateCount,
    required this.activeParticipantNames,
  });

  final int clearedCyclesMax;
  final int totalStages;
  final int? activeStage;
  final GauntletPhase? activePhase;
  final RealmTier recommendedRealm;
  final List<GauntletLocationStageSummary> stages;
  final String rewardSkillName;
  final List<String> rewardEquipmentNames;
  final int firstClearRewardExp;
  final int firstClearRewardInsight;
  final int eliteRewardExp;
  final int ticketCount;
  final int supplyCap;
  final int candidateCount;
  final int availableCandidateCount;
  final List<String> activeParticipantNames;

  bool get hasActiveRun => activeStage != null;
}
