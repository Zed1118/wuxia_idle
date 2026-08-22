import '../../../core/domain/attribute_effect_policy.dart';
import '../../../core/domain/character.dart';
import '../../../data/defs/injury_config.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../injury/application/injury_service.dart';
import '../domain/battle_state.dart';

/// Temporary adapter from the retired 3v3 state to engine-neutral settlement.
/// Delete atomically with the legacy engine after the Route C external gates.
class LegacyBattleInjuryAdapter {
  LegacyBattleInjuryAdapter._();

  static void apply({
    required List<Character> participatingCharacters,
    required BattleState finalState,
    required InjuryConfig config,
    required AttributeEffectRules attributeEffects,
    required bool isVictory,
    required bool isHardFight,
  }) {
    InjuryService.applySettlementInjuries(
      participatingCharacters: participatingCharacters,
      participants: {
        for (final battleCharacter in finalState.leftTeam)
          battleCharacter.characterId: CombatParticipantSnapshot(
            characterId: battleCharacter.characterId,
            currentHp: battleCharacter.currentHp,
            maxHp: battleCharacter.maxHp,
          ),
      },
      config: config,
      attributeEffects: attributeEffects,
      isVictory: isVictory,
      isHardFight: isHardFight,
    );
  }
}
