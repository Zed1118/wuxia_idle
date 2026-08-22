import '../../jianghu/application/npc_relation_service.dart';
import '../domain/battle_state.dart';

/// Retired 3v3 snapshot adapter for Jianghu enmity multipliers.
/// Delete atomically with the legacy engine after the Route C external gates.
class LegacyEnmityBattleModifier {
  LegacyEnmityBattleModifier._();

  /// SET semantics: each enemy receives its relation multiplier; the first
  /// player receives the maximum multiplier across enemies.
  static Future<(List<BattleCharacter>, List<BattleCharacter>)> bake({
    required NpcRelationService npcService,
    required List<BattleCharacter> leftTeam,
    required List<BattleCharacter> rightTeam,
  }) async {
    if (leftTeam.isEmpty || rightTeam.isEmpty) return (leftTeam, rightTeam);
    final playerCharId = leftTeam.first.characterId;
    if (playerCharId < 0) return (leftTeam, rightTeam);

    var maxMult = 1.0;
    final newRight = <BattleCharacter>[];
    for (final enemy in rightTeam) {
      final mult = await npcService.attackPowerMultFor(
        playerCharId,
        enemy.characterId,
      );
      if (mult > 1.0) {
        newRight.add(
          enemy.copyWith(
            attackPowerMultiplier: mult,
            attackPowerMultiplierSource:
                AttackPowerMultiplierSource.jianghuEnmity,
          ),
        );
        if (mult > maxMult) maxMult = mult;
      } else {
        newRight.add(enemy);
      }
    }

    if (maxMult <= 1.0) return (leftTeam, newRight);
    final newLeft = <BattleCharacter>[
      leftTeam.first.copyWith(
        attackPowerMultiplier: maxMult,
        attackPowerMultiplierSource: AttackPowerMultiplierSource.jianghuEnmity,
      ),
      ...leftTeam.skip(1),
    ];
    return (newLeft, newRight);
  }
}
