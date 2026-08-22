import '../../../shared/battle_shared/combat_settlement_snapshot.dart';

/// Engine-neutral combat statistics consumed by settlement UI and archives.
class CombatStatsSummary {
  final int totalDamage;
  final int critCount;
  final int totalTicks;

  const CombatStatsSummary({
    required this.totalDamage,
    required this.critCount,
    required this.totalTicks,
  });

  factory CombatStatsSummary.fromSettlement(
    CombatSettlementSnapshot settlement,
  ) => CombatStatsSummary(
    totalDamage: settlement.totalDamage,
    critCount: settlement.criticalCount,
    totalTicks: settlement.totalTicks,
  );
}
