import 'battle_result.dart';

/// Engine-neutral terminal health for one combatant.
final class CombatParticipantSnapshot {
  const CombatParticipantSnapshot({
    required this.characterId,
    required this.currentHp,
    required this.maxHp,
  });

  final int characterId;
  final int currentHp;
  final int maxHp;

  bool get isAlive => currentHp > 0;
}

/// One semantic skill cast used by post-combat progression.
final class CombatSkillCastSnapshot {
  const CombatSkillCastSnapshot({
    required this.tick,
    required this.characterId,
    required this.skillId,
  });

  final int tick;
  final int characterId;
  final String skillId;
}

/// Engine-neutral terminal input consumed by rewards and progression.
///
/// Legacy 3v3 and Phase 0A each adapt their own runtime state into this value;
/// downstream settlement must not reach back into an engine-specific provider.
final class CombatSettlementSnapshot {
  CombatSettlementSnapshot({
    required this.result,
    required this.totalTicks,
    required this.hadActions,
    required List<CombatParticipantSnapshot> participants,
    required List<CombatSkillCastSnapshot> skillCasts,
    required this.totalDamage,
    required this.criticalCount,
    required Map<int, int> damageByCharacterId,
  }) : participants = List.unmodifiable(participants),
       skillCasts = List.unmodifiable(skillCasts),
       damageByCharacterId = Map.unmodifiable(damageByCharacterId);

  final BattleResult? result;
  final int totalTicks;
  final bool hadActions;
  final List<CombatParticipantSnapshot> participants;
  final List<CombatSkillCastSnapshot> skillCasts;
  final int totalDamage;
  final int criticalCount;
  final Map<int, int> damageByCharacterId;

  bool get isFinished => result != null;

  Set<int> get participantCharacterIds => {
    for (final participant in participants) participant.characterId,
  };

  CombatParticipantSnapshot? participantFor(int characterId) {
    for (final participant in participants) {
      if (participant.characterId == characterId) return participant;
    }
    return null;
  }
}
