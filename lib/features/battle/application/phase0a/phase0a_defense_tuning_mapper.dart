import '../../../../data/numbers_config.dart';
import '../../domain/phase0a/defense_resolution.dart';
import '../../domain/phase0a/phase0a_defense_tuning.dart';

/// Maps the explicit numbers.yaml defense TUNING into the shared Phase0A
/// runtime contract.
///
/// Migrated encounter hosts that construct adapters themselves must use this
/// mapper once and pass the returned value to both player and enemy adapters.
/// The mapper deliberately does not infer mechanics from skill ids or visual
/// effects, and returns null for a disabled/empty defense section.
abstract final class Phase0aDefenseTuningMapper {
  const Phase0aDefenseTuningMapper._();

  static Phase0aDefenseTuning? fromNumbers(NumbersConfig numbers) =>
      fromArena(numbers.phase0aArena);

  static Phase0aDefenseTuning? fromArena(Phase0aArenaConfig arena) {
    final config = arena.defense;
    if (config.shieldAbsorption <= 0 &&
        config.parryWindowTicks <= 0 &&
        config.dodgeIframeTicks <= 0) {
      return null;
    }

    AttackDefenseFlags flags(Phase0aDefenseFlagsConfig value) =>
        AttackDefenseFlags(
          blockable: value.blockable,
          parryable: value.parryable,
          reflectable: value.reflectable,
          dodgeable: value.dodgeable,
          interruptible: value.interruptible,
        );

    return Phase0aDefenseTuning(
      shieldAbsorption: config.shieldAbsorption,
      shieldDurationTicks: config.shieldDurationTicks,
      parryWindowTicks: config.parryWindowTicks,
      counterDamage: config.counterDamage,
      counterUpperBound: config.counterUpperBound,
      dodgeIframeTicks: config.dodgeIframeTicks,
      dodgeDistance: config.dodgeDistance,
      defenseCooldownSeconds: config.defenseCooldownSeconds,
      basicAttackFlags: flags(config.basicAttackFlags),
      skillAttackFlags: flags(config.skillAttackFlags),
    );
  }
}
