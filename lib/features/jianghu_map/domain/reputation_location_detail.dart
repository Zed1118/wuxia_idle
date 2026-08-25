class ReputationLocationFactionSummary {
  const ReputationLocationFactionSummary({
    required this.id,
    required this.name,
    required this.alignment,
    required this.value,
    required this.tier,
    required this.tierLabel,
  });

  final String id;
  final String name;
  final String alignment;
  final int? value;
  final String? tier;
  final String? tierLabel;
}

class ReputationLocationTierSummary {
  const ReputationLocationTierSummary({
    required this.tier,
    required this.label,
    required this.min,
    required this.max,
  });

  final String tier;
  final String label;
  final int min;
  final int max;
}

/// Read-only production snapshot for the Jianghu reputation location.
class ReputationLocationDetail {
  const ReputationLocationDetail({
    required this.factions,
    required this.tiers,
    required this.stageBossKillDelta,
    required this.stageBossKillRivalDelta,
    required this.encounterNpcDeltaMin,
    required this.encounterNpcDeltaMax,
  });

  final List<ReputationLocationFactionSummary> factions;
  final List<ReputationLocationTierSummary> tiers;
  final int stageBossKillDelta;
  final int stageBossKillRivalDelta;
  final int encounterNpcDeltaMin;
  final int encounterNpcDeltaMax;

  int get trackedFactionCount =>
      factions.where((faction) => faction.value != null).length;
}
