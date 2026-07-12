import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attribute_effect_policy.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';

void main() {
  const rules = AttributeEffectRules(
    referenceValue: 5,
    heavyInjuryReductionPerPoint: 0.02,
    heavyInjuryReductionMax: 0.20,
    growthBonusPerPoint: 0.02,
    growthBonusMax: 0.20,
    insightProbabilitySensitivity: 20,
    fortuneProbabilitySensitivity: 20,
    specialChoiceRequired: 8,
  );
  const policy = AttributeEffectPolicy(rules);

  group('constitution', () {
    test(
      'only shortens newly applied heavy-injury duration above reference',
      () {
        expect(policy.heavyInjuryHours(baseHours: 8, constitution: 1), 8);
        expect(policy.heavyInjuryHours(baseHours: 8, constitution: 5), 8);
        expect(policy.heavyInjuryHours(baseHours: 8, constitution: 10), 7.2);
        expect(policy.heavyInjuryHours(baseHours: 8, constitution: 15), 6.4);
        expect(policy.heavyInjuryHours(baseHours: 8, constitution: 99), 6.4);
      },
    );
  });

  group('enlightenment growth', () {
    test('uses reference 5, 2% per point, and 20% cap', () {
      expect(policy.growthMultiplier(enlightenment: 1), 1);
      expect(policy.growthMultiplier(enlightenment: 5), 1);
      expect(policy.growthMultiplier(enlightenment: 10), 1.1);
      expect(policy.growthMultiplier(enlightenment: 15), 1.2);
      expect(policy.growthMultiplier(enlightenment: 99), 1.2);
    });

    test('derives proficiency without changing raw usage count', () {
      expect(policy.effectiveUsageCount(rawUses: 29, enlightenment: 10), 31);
      expect(policy.effectiveUsageCount(rawUses: 10, enlightenment: 15), 12);
    });

    test(
      'cumulative delta does not lose fractional progress between batches',
      () {
        expect(
          policy.effectiveProgressDelta(
            rawBefore: 9,
            rawDelta: 1,
            enlightenment: 10,
          ),
          2,
        );
        expect(
          policy.effectiveProgressDelta(
            rawBefore: 0,
            rawDelta: 10,
            enlightenment: 10,
          ),
          11,
        );
      },
    );
  });

  group('encounter probability', () {
    final attrs = Attributes()
      ..constitution = 5
      ..enlightenment = 5
      ..agility = 5
      ..fortune = 10;

    test('technique insight reads enlightenment', () {
      expect(
        policy.encounterProbability(
          base: 0.5,
          source: EncounterProbabilitySource.enlightenment,
          attributes: attrs,
        ),
        0.625,
      );
    });

    test('ordinary encounter reads fortune and clamps to one', () {
      expect(
        policy.encounterProbability(
          base: 0.5,
          source: EncounterProbabilitySource.fortune,
          attributes: attrs,
        ),
        0.75,
      );
      expect(
        policy.encounterProbability(
          base: 0.9,
          source: EncounterProbabilitySource.fortune,
          attributes: attrs,
        ),
        1,
      );
    });
  });

  group('strict yaml parsing', () {
    test('rejects missing attribute_effects fields', () {
      expect(
        () => AttributeEffectRules.fromYaml(const {}),
        throwsFormatException,
      );
    });

    test('rejects invalid coefficient ranges', () {
      expect(
        () => AttributeEffectRules.fromYaml({
          'reference_value': 5,
          'constitution': {
            'heavy_injury_reduction_per_point': -0.02,
            'heavy_injury_reduction_max': 0.20,
          },
          'enlightenment': {
            'growth_bonus_per_point': 0.02,
            'growth_bonus_max': 0.20,
            'insight_probability_sensitivity': 20,
          },
          'fortune': {
            'encounter_probability_sensitivity': 20,
            'special_choice_required': 8,
          },
        }),
        throwsFormatException,
      );
    });
  });
}
