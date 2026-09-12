import 'dart:math' as math;

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../data/defs/realm_def.dart';
import '../../../data/numbers_config.dart';
import '../../cultivation/application/character_advancement_service.dart';

typedef PassiveRealmTierChange = ({
  int elapsedMicroseconds,
  RealmTier previousTier,
});

typedef PassiveAccrual = ({
  int experience,
  int mojianshi,
  double experienceRemainder,
  double mojianshiRemainder,
  List<PassiveRealmTierChange> realmTierChanges,
});

/// Integrates the configured rate on the same timeline for a long absence or
/// repeated short settlements. A level-up changes the rate at the first whole
/// experience point which can cause that advancement, not at the next login.
abstract final class PassiveIdleIntegrator {
  // Floating-point roundoff tolerance in one resource unit, not a yield rate.
  static const _roundoff = 1e-9;

  static PassiveAccrual accrue({
    required Character character,
    required int elapsedMicroseconds,
    required PassiveIdleConfig config,
    required double experienceRemainder,
    required double mojianshiRemainder,
    required RealmDef Function(RealmTier, RealmLayer) realmLookup,
    required bool Function(RealmTier, RealmLayer) isLayerLocked,
  }) {
    var remaining = math.max(0, elapsedMicroseconds);
    var experience = 0;
    var mojianshi = 0;
    var expFraction = experienceRemainder;
    var materialFraction = mojianshiRemainder;
    var processedMicroseconds = 0;
    final realmTierChanges = <PassiveRealmTierChange>[];

    while (remaining > 0) {
      final scale = config.realmScaleFor(character.realmTier);
      final expPerHour = config.baseExpPerHour * scale;
      final materialPerHour = config.baseMojianshiPerHour * scale;
      var segment = remaining;
      final next = CharacterAdvancementService.nextLayer(
        character.realmTier,
        character.realmLayer,
      );
      if (expPerHour > 0 &&
          next != null &&
          !isLayerLocked(next.tier, next.layer)) {
        final threshold = realmLookup(
          character.realmTier,
          character.realmLayer,
        ).experienceToNext;
        // Existing advancement consumes a previously locked balance when the
        // next positive experience grant arrives. Preserve that same contract.
        final pointsNeeded = math.max(1, threshold - character.experience);
        final untilAdvancement =
            ((pointsNeeded - expFraction) *
                    Duration.microsecondsPerHour /
                    expPerHour)
                .ceil();
        segment = math.min(segment, math.max(1, untilAdvancement));
      }

      final hours = segment / Duration.microsecondsPerHour;
      final expExact = expFraction + expPerHour * hours;
      final materialExact = materialFraction + materialPerHour * hours;
      final expWhole = _whole(expExact);
      final materialWhole = _whole(materialExact);
      expFraction = math.max(0, expExact - expWhole);
      materialFraction = math.max(0, materialExact - materialWhole);
      experience += expWhole;
      mojianshi += materialWhole;
      processedMicroseconds += segment;
      if (expWhole > 0) {
        final previousTier = character.realmTier;
        CharacterAdvancementService.applyExperience(
          character,
          expWhole,
          realmLookup: realmLookup,
          isLayerLocked: isLayerLocked,
        );
        for (
          var tierIndex = previousTier.index;
          tierIndex < character.realmTier.index;
          tierIndex++
        ) {
          realmTierChanges.add((
            elapsedMicroseconds: processedMicroseconds,
            previousTier: RealmTier.values[tierIndex],
          ));
        }
      }
      remaining -= segment;
    }

    return (
      experience: experience,
      mojianshi: mojianshi,
      experienceRemainder: expFraction,
      mojianshiRemainder: materialFraction,
      realmTierChanges: realmTierChanges,
    );
  }

  static int _whole(double value) {
    final nearest = value.round();
    return (value - nearest).abs() <= _roundoff ? nearest : value.floor();
  }
}
