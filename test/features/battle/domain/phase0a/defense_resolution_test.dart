import 'package:flutter_test/flutter_test.dart';

import 'package:wuxia_idle/features/battle/domain/phase0a/defense_resolution.dart';

void main() {
  group('AttackDefenseFlags', () {
    test('derives unblockable only when block and parry are both absent', () {
      final flags = AttackDefenseFlags(
        blockable: false,
        parryable: false,
        reflectable: false,
        dodgeable: true,
        interruptible: true,
      );

      expect(flags.isUnblockable, isTrue);
    });

    test('keeps parry independent from block', () {
      final flags = AttackDefenseFlags(
        blockable: false,
        parryable: true,
        reflectable: false,
        dodgeable: true,
        interruptible: true,
      );

      expect(flags.blockable, isFalse);
      expect(flags.parryable, isTrue);
      expect(flags.isUnblockable, isFalse);
    });
  });

  group('resolveDefense', () {
    final openFlags = AttackDefenseFlags(
      blockable: true,
      parryable: true,
      reflectable: true,
      dodgeable: true,
      interruptible: true,
    );

    DefenseInput input({
      AttackDefenseFlags? flags,
      bool dodgeSucceeded = false,
      bool parrySucceeded = false,
      bool redirectSucceeded = false,
      bool blockSucceeded = false,
      double incomingHpDamage = 100,
      double incomingPostureDamage = 20,
      double shieldAbsorption = 0,
      double blockDamageMultiplier = 1,
      double baseMitigationFraction = 0,
      double counterDamage = 0,
      double counterUpperBound = 0,
    }) => DefenseInput(
      flags: flags ?? openFlags,
      incomingHpDamage: incomingHpDamage,
      incomingPostureDamage: incomingPostureDamage,
      dodgeSucceeded: dodgeSucceeded,
      parrySucceeded: parrySucceeded,
      redirectSucceeded: redirectSucceeded,
      blockSucceeded: blockSucceeded,
      shieldAbsorption: shieldAbsorption,
      blockDamageMultiplier: blockDamageMultiplier,
      baseMitigationFraction: baseMitigationFraction,
      counterDamage: counterDamage,
      counterUpperBound: counterUpperBound,
    );

    test('uses dodge before every later defense branch', () {
      final result = resolveDefense(
        input(
          dodgeSucceeded: true,
          parrySucceeded: true,
          redirectSucceeded: true,
          blockSucceeded: true,
          counterDamage: 50,
          counterUpperBound: 60,
        ),
      );

      expect(result.branch, DefenseBranch.dodge);
      expect(result.incomingHpDamage, 0);
      expect(result.incomingPostureDamage, 0);
      expect(result.counterDamage, 0);
    });

    test('keeps parry and redirect separate', () {
      final parry = resolveDefense(
        input(
          parrySucceeded: true,
          redirectSucceeded: true,
          counterDamage: 17,
          counterUpperBound: 40,
        ),
      );
      final redirect = resolveDefense(
        input(
          redirectSucceeded: true,
          counterDamage: 17,
          counterUpperBound: 40,
        ),
      );

      expect(parry.branch, DefenseBranch.parry);
      expect(parry.counterDamage, 17);
      expect(parry.wasRedirected, isFalse);
      expect(redirect.branch, DefenseBranch.redirect);
      expect(redirect.counterDamage, 0);
      expect(redirect.wasRedirected, isTrue);
    });

    test('applies shield, block, then base mitigation to HP and posture', () {
      final result = resolveDefense(
        input(
          blockSucceeded: true,
          incomingHpDamage: 100,
          incomingPostureDamage: 20,
          shieldAbsorption: 30,
          blockDamageMultiplier: 0.5,
          baseMitigationFraction: 0.2,
        ),
      );

      expect(result.branch, DefenseBranch.blockOrShield);
      expect(result.incomingHpDamage, 16);
      expect(result.incomingPostureDamage, 8);
    });

    test('uses base mitigation when no earlier branch succeeds', () {
      final result = resolveDefense(
        input(
          incomingHpDamage: 100,
          incomingPostureDamage: 20,
          baseMitigationFraction: 0.25,
        ),
      );

      expect(result.branch, DefenseBranch.baseMitigation);
      expect(result.incomingHpDamage, 75);
      expect(result.incomingPostureDamage, 15);
    });

    test('never copies high Boss inbound damage into a counter', () {
      final result = resolveDefense(
        input(
          parrySucceeded: true,
          incomingHpDamage: 900000,
          counterDamage: 23,
          counterUpperBound: 31,
        ),
      );

      expect(result.incomingHpDamage, 0);
      expect(result.counterDamage, 23);
      expect(result.counterDamage, isNot(900000));
      expect(result.nonRecursive, isTrue);
      expect(result.canCrit, isFalse);
      expect(result.canLifesteal, isFalse);
      expect(result.canTriggerOnHitReflect, isFalse);
    });

    test('caps standard counter damage with caller supplied upper bound', () {
      final result = resolveDefense(
        input(blockSucceeded: true, counterDamage: 80, counterUpperBound: 12),
      );

      expect(result.counterDamage, 12);
      expect(result.nonRecursive, isTrue);
    });

    test('rejects negative damage and invalid mitigation values', () {
      expect(() => input(incomingHpDamage: -1), throwsArgumentError);
      expect(() => input(baseMitigationFraction: 1.1), throwsArgumentError);
      expect(() => input(blockDamageMultiplier: -0.1), throwsArgumentError);
    });

    test('clamps finite damage at double boundary after scaling', () {
      final result = resolveDefense(
        input(
          blockSucceeded: true,
          incomingHpDamage: double.maxFinite,
          incomingPostureDamage: double.maxFinite,
          blockDamageMultiplier: 2,
        ),
      );

      expect(result.incomingHpDamage, double.maxFinite);
      expect(result.incomingPostureDamage, double.maxFinite);
      expect(result.incomingHpDamage.isFinite, isTrue);
      expect(result.incomingPostureDamage.isFinite, isTrue);
    });

    test('same typed input produces a deterministic result', () {
      final request = input(
        blockSucceeded: true,
        shieldAbsorption: 9,
        blockDamageMultiplier: 0.4,
        baseMitigationFraction: 0.1,
        counterDamage: 6,
        counterUpperBound: 7,
      );

      expect(resolveDefense(request), resolveDefense(request));
    });
  });
}
