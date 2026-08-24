import '../../activity/domain/activity_occupancy.dart';
import '../../boss_gauntlet/domain/boss_gauntlet_run.dart';

class SectItineraryOccupiedMember {
  const SectItineraryOccupiedMember({
    required this.characterId,
    required this.name,
    required this.activity,
  });

  final int characterId;
  final String name;
  final ActivityKind activity;
}

class SectItinerarySummary {
  const SectItinerarySummary({
    required this.leaderId,
    required this.leaderName,
    required this.occupiedMembers,
    required this.expeditionDepth,
    required this.expeditionDefeated,
    required this.gauntletStage,
    required this.gauntletPhase,
  });

  final int leaderId;
  final String leaderName;
  final List<SectItineraryOccupiedMember> occupiedMembers;

  /// null 表示当前无 active 远征。
  final int? expeditionDepth;
  final bool expeditionDefeated;

  /// null 表示当前无 active 断魂庄会话。
  final int? gauntletStage;
  final GauntletPhase? gauntletPhase;
}
