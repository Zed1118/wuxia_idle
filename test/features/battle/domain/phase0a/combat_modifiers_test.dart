import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/combat_modifiers.dart';

void main() {
  group('typed style modifiers', () {
    test('rigid exposes only knockback, posture and breach parameters', () {
      final modifier = GangMengModifier(
        knockbackFactor: 1.2,
        postureDamageFactor: 1.3,
        breachPowerFactor: 1.1,
      );

      expect(modifier.school, TechniqueSchool.gangMeng);
      expect(modifier.knockbackFactor, 1.2);
    });

    test('rejects non-finite or negative factors', () {
      expect(
        () => GangMengModifier(
          knockbackFactor: -1,
          postureDamageFactor: 1,
          breachPowerFactor: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => LingQiaoModifier(
          pursuitFactor: double.nan,
          dodgeTrajectoryFactor: 1,
          recoveryFactor: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => YinRouModifier(
          pullFactor: 1,
          slowFactor: 0,
          internalInjuryFactor: 1,
          controlDurationFactor: 1,
        ),
        throwsArgumentError,
      );
    });

    test('cannot construct a cross-domain parameter set', () {
      expect(
        () => YinRouModifier(
          pullFactor: 1,
          slowFactor: 1,
          internalInjuryFactor: 1,
          controlDurationFactor: 1,
        ),
        returnsNormally,
      );
      // The separate constructors make a rigid modifier unable to accept
      // sinister/ agile fields at compile time.
    });
  });

  group('applyCombatModifiers', () {
    final base = ModifierValues(
      knockback: 10,
      postureDamage: 20,
      breachPower: 30,
      pursuitDistance: 40,
      dodgeTrajectory: 50,
      recoveryDuration: 60,
      pullStrength: 70,
      slowStrength: 80,
      internalInjuryStrength: 90,
      controlDuration: 100,
    );
    final bounds = ModifierBounds(
      knockback: 100,
      postureDamage: 100,
      breachPower: 100,
      pursuitDistance: 100,
      dodgeTrajectory: 100,
      recoveryDuration: 100,
      pullStrength: 100,
      slowStrength: 100,
      internalInjuryStrength: 100,
      controlDuration: 100,
    );

    test('composes only each style legal domain', () {
      final result = applyCombatModifiers(base, bounds, [
        GangMengModifier(
          knockbackFactor: 2,
          postureDamageFactor: 2,
          breachPowerFactor: 2,
        ),
        LingQiaoModifier(
          pursuitFactor: 2,
          dodgeTrajectoryFactor: 2,
          recoveryFactor: 2,
        ),
        YinRouModifier(
          pullFactor: 2,
          slowFactor: 2,
          internalInjuryFactor: 2,
          controlDurationFactor: 2,
        ),
      ]);

      expect(result.knockback, 20);
      expect(result.postureDamage, 40);
      expect(result.pursuitDistance, 80);
      expect(result.recoveryDuration, 100);
      expect(result.pullStrength, 100);
      expect(result.controlDuration, 100);
    });

    test('applies caller-supplied upper bounds without hidden caps', () {
      final result = applyCombatModifiers(
        base,
        bounds.copyWith(knockback: 15, postureDamage: 25),
        [
          GangMengModifier(
            knockbackFactor: 2,
            postureDamageFactor: 2,
            breachPowerFactor: 1,
          ),
        ],
      );

      expect(result.knockback, 15);
      expect(result.postureDamage, 25);
      expect(result.breachPower, 30);
    });

    test('ordered composition is deterministic and repeatable', () {
      final modifiers = <CombatModifier>[
        GangMengModifier(
          knockbackFactor: 1.1,
          postureDamageFactor: 1,
          breachPowerFactor: 1,
        ),
        GangMengModifier(
          knockbackFactor: 1.2,
          postureDamageFactor: 1,
          breachPowerFactor: 1,
        ),
      ];

      final first = applyCombatModifiers(base, bounds, modifiers);
      final second = applyCombatModifiers(base, bounds, modifiers);

      expect(first, second);
      expect(first.knockback, closeTo(13.2, 0.000001));
    });

    test('rejects negative base values and bounds', () {
      expect(
        () => applyCombatModifiers(
          base.copyWith(knockback: -1),
          bounds,
          const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => applyCombatModifiers(
          base,
          bounds.copyWith(knockback: -1),
          const [],
        ),
        throwsArgumentError,
      );
    });
  });
}
