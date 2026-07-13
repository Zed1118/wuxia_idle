// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attribute_effect_policy.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';

import '../support/progression_playtest_fixture.dart';
import '../support/test_data.dart';

void recordAttributeObservation(
  GrowthStage stage,
  String metric,
  num baseline,
  num raised,
) {
  print(['attribute_role', stage.name, metric, baseline, raised].join(','));
}

void main() {
  late GameRepository repository;
  late ProgressionPlaytestFixture fixture;
  late AttributeEffectPolicy policy;

  setUpAll(() async {
    repository = await loadTestGameRepository();
    fixture = ProgressionPlaytestFixture(repository);
    policy = AttributeEffectPolicy(repository.numbers.attributeEffects);
  });

  for (final stage in GrowthStage.values) {
    test('${stage.name}: constitution shortens new heavy injury duration', () {
      final base = fixture.createCharacter(stage, id: 100 + stage.index);
      final raised = fixture.createCharacter(
        stage,
        id: 200 + stage.index,
        raisedAttribute: AttributeKey.constitution,
      );
      final hoursBase = policy.heavyInjuryHours(
        baseHours: repository.numbers.injury.heavyRecoveryHours,
        constitution: base.attributes.constitution,
      );
      final hoursRaised = policy.heavyInjuryHours(
        baseHours: repository.numbers.injury.heavyRecoveryHours,
        constitution: raised.attributes.constitution,
      );
      recordAttributeObservation(
        stage,
        'constitution_heavy_injury_hours',
        hoursBase,
        hoursRaised,
      );
      expect(hoursRaised, lessThan(hoursBase));
    });

    test(
      '${stage.name}: enlightenment improves all three growth entrances',
      () {
        final base = fixture.createCharacter(stage, id: 300 + stage.index);
        final raised = fixture.createCharacter(
          stage,
          id: 400 + stage.index,
          raisedAttribute: AttributeKey.enlightenment,
        );
        final usageBase = policy.effectiveUsageCount(
          rawUses: 100,
          enlightenment: base.attributes.enlightenment,
        );
        final usageRaised = policy.effectiveUsageCount(
          rawUses: 100,
          enlightenment: raised.attributes.enlightenment,
        );
        final progressBase = policy.effectiveProgressDelta(
          rawBefore: 20,
          rawDelta: 50,
          enlightenment: base.attributes.enlightenment,
        );
        final progressRaised = policy.effectiveProgressDelta(
          rawBefore: 20,
          rawDelta: 50,
          enlightenment: raised.attributes.enlightenment,
        );
        final encounterBase = policy.encounterProbability(
          base: 0.2,
          source: EncounterProbabilitySource.enlightenment,
          attributes: base.attributes,
        );
        final encounterRaised = policy.encounterProbability(
          base: 0.2,
          source: EncounterProbabilitySource.enlightenment,
          attributes: raised.attributes,
        );
        recordAttributeObservation(
          stage,
          'enlightenment_effective_usage',
          usageBase,
          usageRaised,
        );
        recordAttributeObservation(
          stage,
          'enlightenment_progress_delta',
          progressBase,
          progressRaised,
        );
        recordAttributeObservation(
          stage,
          'enlightenment_encounter_probability',
          encounterBase,
          encounterRaised,
        );
        expect(usageRaised, greaterThan(usageBase));
        expect(progressRaised, greaterThan(progressBase));
        expect(encounterRaised, greaterThan(encounterBase));
      },
    );

    test(
      '${stage.name}: agility raises speed/evasion but never critical rate',
      () {
        final base = fixture.createCharacter(stage, id: 500 + stage.index);
        final raised = fixture.createCharacter(
          stage,
          id: 600 + stage.index,
          raisedAttribute: AttributeKey.agility,
        );
        final tier = RealmUtils.techniqueTierCapOf(base.realmTier);
        final def = repository.techniqueDefs.values.firstWhere(
          (value) =>
              value.tier == tier && value.school == TechniqueSchool.gangMeng,
        );
        Technique techniqueFor(int id) => Technique.create(
          defId: def.id,
          ownerCharacterId: id,
          tier: def.tier,
          school: def.school,
          role: TechniqueRole.main,
          learnedAt: DateTime.utc(2026, 7, 13),
          cultivationLayer: CultivationLayer.zhongCheng,
        );

        final speedBase = CharacterDerivedStats.speed(
          base,
          const [],
          techniqueFor(base.id),
          repository.numbers,
        );
        final speedRaised = CharacterDerivedStats.speed(
          raised,
          const [],
          techniqueFor(raised.id),
          repository.numbers,
        );
        final evasionBase = CharacterDerivedStats.evasionRate(
          base,
          repository.numbers,
        );
        final evasionRaised = CharacterDerivedStats.evasionRate(
          raised,
          repository.numbers,
        );
        final criticalBase = CharacterDerivedStats.criticalRate(
          base,
          repository.numbers,
        );
        final criticalRaised = CharacterDerivedStats.criticalRate(
          raised,
          repository.numbers,
        );
        recordAttributeObservation(
          stage,
          'agility_speed',
          speedBase,
          speedRaised,
        );
        recordAttributeObservation(
          stage,
          'agility_evasion_rate',
          evasionBase,
          evasionRaised,
        );
        recordAttributeObservation(
          stage,
          'agility_critical_rate',
          criticalBase,
          criticalRaised,
        );
        expect(speedRaised, greaterThan(speedBase));
        expect(evasionRaised, greaterThan(evasionBase));
        expect(criticalRaised, criticalBase);
      },
    );

    test(
      '${stage.name}: fortune changes fortune encounters but not combat stats',
      () {
        final base = fixture.createCharacter(stage, id: 700 + stage.index);
        final raised = fixture.createCharacter(
          stage,
          id: 800 + stage.index,
          raisedAttribute: AttributeKey.fortune,
        );
        final encounterBase = policy.encounterProbability(
          base: 0.2,
          source: EncounterProbabilitySource.fortune,
          attributes: base.attributes,
        );
        final encounterRaised = policy.encounterProbability(
          base: 0.2,
          source: EncounterProbabilitySource.fortune,
          attributes: raised.attributes,
        );
        final hpBase = CharacterDerivedStats.maxHp(
          base,
          const [],
          repository.numbers,
        );
        final hpRaised = CharacterDerivedStats.maxHp(
          raised,
          const [],
          repository.numbers,
        );
        final evasionBase = CharacterDerivedStats.evasionRate(
          base,
          repository.numbers,
        );
        final evasionRaised = CharacterDerivedStats.evasionRate(
          raised,
          repository.numbers,
        );
        final criticalBase = CharacterDerivedStats.criticalRate(
          base,
          repository.numbers,
        );
        final criticalRaised = CharacterDerivedStats.criticalRate(
          raised,
          repository.numbers,
        );
        recordAttributeObservation(
          stage,
          'fortune_encounter_probability',
          encounterBase,
          encounterRaised,
        );
        recordAttributeObservation(stage, 'fortune_max_hp', hpBase, hpRaised);
        recordAttributeObservation(
          stage,
          'fortune_evasion_rate',
          evasionBase,
          evasionRaised,
        );
        recordAttributeObservation(
          stage,
          'fortune_critical_rate',
          criticalBase,
          criticalRaised,
        );
        expect(encounterRaised, greaterThan(encounterBase));
        expect(hpRaised, hpBase);
        expect(evasionRaised, evasionBase);
        expect(criticalRaised, criticalBase);
      },
    );
  }
}
