// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attribute_effect_policy.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/skill_usage_entry.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/defs/technique_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';
import 'package:wuxia_idle/features/cultivation/application/cultivation_service.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_event_loader.dart';
import 'package:wuxia_idle/features/encounter/presentation/encounter_dialog.dart';
import 'package:wuxia_idle/features/equipment/application/drop_service.dart';
import 'package:wuxia_idle/features/injury/application/injury_service.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';

import '../support/isar_test_support.dart';
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

Map<String, Object?> _characterSnapshot(Character character) => {
  'id': character.id,
  'name': character.name,
  'realmTier': character.realmTier,
  'realmLayer': character.realmLayer,
  'rarity': character.rarity,
  'lineageRole': character.lineageRole,
  'school': character.school,
  'isFounder': character.isFounder,
  'isActive': character.isActive,
  'isAlive': character.isAlive,
  'internalForce': character.internalForce,
  'internalForceMax': character.internalForceMax,
  'experience': character.experience,
  'experienceToNextLayer': character.experienceToNextLayer,
  'level': character.level,
  'levelExp': character.levelExp,
  'createdAt': character.createdAt,
  'attributes.constitution': character.attributes.constitution,
  'attributes.enlightenment': character.attributes.enlightenment,
  'attributes.agility': character.attributes.agility,
  'attributes.fortune': character.attributes.fortune,
};

({Character base, Character raised}) _createAttributePair(
  ProgressionPlaytestFixture fixture,
  GrowthStage stage, {
  required int id,
  required AttributeKey raisedAttribute,
}) {
  final base = fixture.createCharacter(stage, id: id);
  final raised = fixture.createCharacter(
    stage,
    id: id,
    raisedAttribute: raisedAttribute,
  );
  final targetKey = 'attributes.${raisedAttribute.name}';
  final baseSnapshot = _characterSnapshot(base);
  final raisedSnapshot = _characterSnapshot(raised);
  final baseStructure = Map<String, Object?>.of(baseSnapshot)
    ..remove(targetKey);
  final raisedStructure = Map<String, Object?>.of(raisedSnapshot)
    ..remove(targetKey);

  expect(
    raisedStructure,
    baseStructure,
    reason: 'baseline/raised 除 $targetKey 外必须是严格单变量',
  );
  expect(baseSnapshot[targetKey], 5);
  expect(raisedSnapshot[targetKey], 8);
  expect(base.attributes.total, 20);
  expect(raised.attributes.total, 23);
  return (base: base, raised: raised);
}

TechniqueDef _gangMengTechniqueDef(
  GameRepository repository,
  Character character,
) {
  final tier = RealmUtils.techniqueTierCapOf(character.realmTier);
  return repository.techniqueDefs.values.firstWhere(
    (value) => value.tier == tier && value.school == TechniqueSchool.gangMeng,
  );
}

Technique _techniqueFor(
  GameRepository repository,
  Character owner,
  TechniqueDef def, {
  String? usedSkillId,
  int rawUses = 0,
}) {
  final technique = Technique.create(
    defId: def.id,
    ownerCharacterId: owner.id,
    tier: def.tier,
    school: def.school,
    role: TechniqueRole.main,
    learnedAt: DateTime.utc(2026, 7, 13),
    cultivationLayer: CultivationLayer.zhongCheng,
    cultivationProgressToNext: repository
        .numbers
        .cultivationProgressToNext[CultivationLayer.zhongCheng]!,
  );
  if (usedSkillId != null && rawUses > 0) {
    technique.skillUsageCount.increment(usedSkillId, rawUses);
  }
  return technique;
}

AttackResult _calculateDamage({
  required GameRepository repository,
  required Character attacker,
  required Technique attackerTechnique,
  required SkillDef skill,
  required Character defender,
  required Technique defenderTechnique,
}) => DamageCalculator.calculate(
  AttackContext(
    attacker: attacker,
    attackerEquipped: const [],
    attackerMainTech: attackerTechnique,
    skill: skill,
    defender: defender,
    defenderEquipped: const [],
    defenderMainTech: defenderTechnique,
    forceCritical: true,
    rng: Random(20260713),
  ),
  repository.numbers,
);

List<String> _dropSnapshot(DropResult result) => [
  for (final equipment in result.equipments)
    [
      'equipment',
      equipment.defId,
      equipment.tier.name,
      equipment.slot.name,
      equipment.school?.name,
      equipment.baseAttack,
      equipment.baseHealth,
      equipment.baseSpeed,
      equipment.obtainedAt.toUtc().toIso8601String(),
      equipment.obtainedFrom,
    ].join(':'),
  for (final item in result.items)
    ['item', item.defId, item.quantity].join(':'),
];

Future<T> _withTestIsar<T>(Future<T> Function(Isar isar) body) async {
  final tempDir = await Directory.systemTemp.createTemp(
    'wuxia_attribute_role_',
  );
  await IsarSetup.init(directory: tempDir, inspector: false);
  try {
    return await body(IsarSetup.instance);
  } finally {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

Future<bool> _choiceEnabled(
  WidgetTester tester, {
  required EncounterDef def,
  required EncounterContent content,
  required EncounterChoice choice,
  required int fortune,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (buildContext) {
          context = buildContext;
          return const SizedBox();
        },
      ),
    ),
  );
  final result = showEncounterDialog(
    context: context,
    def: def,
    content: content,
    fortune: fortune,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  final semanticsFinder = find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == choice.text,
  );
  final semantics = tester.widget<Semantics>(semanticsFinder);
  final enabled = semantics.properties.enabled ?? false;
  Navigator.of(context, rootNavigator: true).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await result;
  return enabled;
}

final class _FixedRng implements Rng {
  const _FixedRng(this.value);

  final double value;

  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => value;

  @override
  T pick<T>(List<T> list) => list.first;
}

void main() {
  late GameRepository repository;
  late ProgressionPlaytestFixture fixture;
  late AttributeEffectPolicy policy;
  late EncounterDef insightEncounter;
  late EncounterDef fortuneEncounter;
  late EncounterContent fortuneContent;
  late EncounterChoice fortuneChoice;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
    fixture = ProgressionPlaytestFixture(repository);
    policy = AttributeEffectPolicy(repository.numbers.attributeEffects);
    insightEncounter = repository.findEncounter('bamboo_listen_rain')!;
    fortuneEncounter = repository.findEncounter('du_ke_wen_dao')!;
    fortuneContent = await EncounterEventLoader.load(fortuneEncounter.id);
    fortuneChoice = fortuneContent.choices.firstWhere(
      (choice) => choice.fortuneRequired == 8,
    );
    expect(fortuneContent.isPlaceholder, isFalse);
  });

  for (final stage in GrowthStage.values) {
    test(
      '${stage.name}: constitution raises hp and shortens real heavy injury',
      () {
        final pair = _createAttributePair(
          fixture,
          stage,
          id: 100 + stage.index,
          raisedAttribute: AttributeKey.constitution,
        );
        final hoursBase = policy.heavyInjuryHours(
          baseHours: repository.numbers.injury.heavyRecoveryHours,
          constitution: pair.base.attributes.constitution,
        );
        final hoursRaised = policy.heavyInjuryHours(
          baseHours: repository.numbers.injury.heavyRecoveryHours,
          constitution: pair.raised.attributes.constitution,
        );
        final hpBase = CharacterDerivedStats.maxHp(
          pair.base,
          const [],
          repository.numbers,
        );
        final hpRaised = CharacterDerivedStats.maxHp(
          pair.raised,
          const [],
          repository.numbers,
        );

        final defeatedState = BattleState.initial(
          leftTeam: const [],
          rightTeam: const [],
        );
        for (final character in [pair.base, pair.raised]) {
          InjuryService.applyBattleInjuries(
            participatingCharacters: [character],
            finalState: defeatedState,
            config: repository.numbers.injury,
            attributeEffects: repository.numbers.attributeEffects,
            isVictory: false,
            isHardFight: true,
          );
        }

        recordAttributeObservation(
          stage,
          'constitution_heavy_injury_hours',
          hoursBase,
          hoursRaised,
        );
        recordAttributeObservation(
          stage,
          'constitution_injury_service_hours',
          pair.base.injuryHoursRemaining,
          pair.raised.injuryHoursRemaining,
        );
        recordAttributeObservation(
          stage,
          'constitution_max_hp',
          hpBase,
          hpRaised,
        );
        expect(pair.base.injuryHoursRemaining, hoursBase);
        expect(pair.raised.injuryHoursRemaining, hoursRaised);
        expect(
          pair.raised.injuryHoursRemaining,
          lessThan(pair.base.injuryHoursRemaining),
        );
        expect(pair.raised.lightInjuryStacks, pair.base.lightInjuryStacks);
        expect(hpRaised, greaterThan(hpBase));
      },
    );

    test(
      '${stage.name}: enlightenment improves cultivation, proficiency damage, and insight encounter',
      () async {
        final pair = _createAttributePair(
          fixture,
          stage,
          id: 300 + stage.index,
          raisedAttribute: AttributeKey.enlightenment,
        );
        final usageBase = policy.effectiveUsageCount(
          rawUses: 100,
          enlightenment: pair.base.attributes.enlightenment,
        );
        final usageRaised = policy.effectiveUsageCount(
          rawUses: 100,
          enlightenment: pair.raised.attributes.enlightenment,
        );
        final progressBase = policy.effectiveProgressDelta(
          rawBefore: 20,
          rawDelta: 50,
          enlightenment: pair.base.attributes.enlightenment,
        );
        final progressRaised = policy.effectiveProgressDelta(
          rawBefore: 20,
          rawDelta: 50,
          enlightenment: pair.raised.attributes.enlightenment,
        );
        final encounterBase = policy.encounterProbability(
          base: 0.2,
          source: EncounterProbabilitySource.enlightenment,
          attributes: pair.base.attributes,
        );
        final encounterRaised = policy.encounterProbability(
          base: 0.2,
          source: EncounterProbabilitySource.enlightenment,
          attributes: pair.raised.attributes,
        );

        final def = _gangMengTechniqueDef(repository, pair.base);
        final skill = repository.getSkill(def.skillIds.first);
        final cultivationBase = _techniqueFor(repository, pair.base, def);
        final cultivationRaised = _techniqueFor(repository, pair.raised, def);
        CultivationService.recordSkillUsage(
          tech: cultivationBase,
          skillId: skill.id,
          progressToNextMap: repository.numbers.cultivationProgressToNext,
          delta: 50,
          attributePolicy: policy,
          enlightenment: pair.base.attributes.enlightenment,
        );
        CultivationService.recordSkillUsage(
          tech: cultivationRaised,
          skillId: skill.id,
          progressToNextMap: repository.numbers.cultivationProgressToNext,
          delta: 50,
          attributePolicy: policy,
          enlightenment: pair.raised.attributes.enlightenment,
        );

        final damageBaseTechnique = _techniqueFor(
          repository,
          pair.base,
          def,
          usedSkillId: skill.id,
          rawUses: 95,
        );
        final damageRaisedTechnique = _techniqueFor(
          repository,
          pair.raised,
          def,
          usedSkillId: skill.id,
          rawUses: 95,
        );
        expect(
          damageRaisedTechnique.ownerCharacterId,
          damageBaseTechnique.ownerCharacterId,
        );
        final defender = fixture.createCharacter(stage, id: 900 + stage.index)
          ..attributes.agility = 0;
        final defenderTechnique = _techniqueFor(
          repository,
          defender,
          _gangMengTechniqueDef(repository, defender),
        );
        final damageBase = _calculateDamage(
          repository: repository,
          attacker: pair.base,
          attackerTechnique: damageBaseTechnique,
          skill: skill,
          defender: defender,
          defenderTechnique: defenderTechnique,
        );
        final damageRaised = _calculateDamage(
          repository: repository,
          attacker: pair.raised,
          attackerTechnique: damageRaisedTechnique,
          skill: skill,
          defender: defender,
          defenderTechnique: defenderTechnique,
        );

        final serviceTriggered = await _withTestIsar((isar) async {
          final service = EncounterService(
            isar: isar,
            attributeEffects: repository.numbers.attributeEffects,
          );
          final saveDataId = 3000 + stage.index;
          await service.getOrCreate(saveDataId: saveDataId);
          await service.recordKill(
            saveDataId: saveDataId,
            defeatedSchools: List.filled(100, TechniqueSchool.lingQiao),
          );
          final baseResult = await service.evaluateTriggers(
            saveDataId: saveDataId,
            attributes: pair.base.attributes,
            encounters: [insightEncounter],
            rng: const _FixedRng(0.53),
          );
          final raisedResult = await service.evaluateTriggers(
            saveDataId: saveDataId,
            attributes: pair.raised.attributes,
            encounters: [insightEncounter],
            rng: const _FixedRng(0.53),
          );
          return (
            base: baseResult?.id == insightEncounter.id ? 1 : 0,
            raised: raisedResult?.id == insightEncounter.id ? 1 : 0,
          );
        });

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
        recordAttributeObservation(
          stage,
          'enlightenment_cultivation_service_progress',
          cultivationBase.cultivationProgress,
          cultivationRaised.cultivationProgress,
        );
        recordAttributeObservation(
          stage,
          'enlightenment_proficiency_damage',
          damageBase.finalDamage,
          damageRaised.finalDamage,
        );
        recordAttributeObservation(
          stage,
          'enlightenment_encounter_service_triggered',
          serviceTriggered.base,
          serviceTriggered.raised,
        );
        expect(usageRaised, greaterThan(usageBase));
        expect(progressRaised, greaterThan(progressBase));
        expect(encounterRaised, greaterThan(encounterBase));
        expect(
          cultivationRaised.skillUsageCount.countOf(skill.id),
          cultivationBase.skillUsageCount.countOf(skill.id),
        );
        expect(
          cultivationRaised.cultivationProgress,
          greaterThan(cultivationBase.cultivationProgress),
        );
        expect(damageBase.isDodged, isFalse);
        expect(damageRaised.isDodged, isFalse);
        expect(damageRaised.finalDamage, greaterThan(damageBase.finalDamage));
        expect(serviceTriggered.base, 0);
        expect(serviceTriggered.raised, 1);
      },
    );

    test(
      '${stage.name}: agility raises speed/evasion but never critical rate',
      () {
        final pair = _createAttributePair(
          fixture,
          stage,
          id: 500 + stage.index,
          raisedAttribute: AttributeKey.agility,
        );
        final def = _gangMengTechniqueDef(repository, pair.base);
        final techniqueBase = _techniqueFor(repository, pair.base, def);
        final techniqueRaised = _techniqueFor(repository, pair.raised, def);
        expect(
          techniqueRaised.ownerCharacterId,
          techniqueBase.ownerCharacterId,
        );

        final speedBase = CharacterDerivedStats.speed(
          pair.base,
          const [],
          techniqueBase,
          repository.numbers,
        );
        final speedRaised = CharacterDerivedStats.speed(
          pair.raised,
          const [],
          techniqueRaised,
          repository.numbers,
        );
        final evasionBase = CharacterDerivedStats.evasionRate(
          pair.base,
          repository.numbers,
        );
        final evasionRaised = CharacterDerivedStats.evasionRate(
          pair.raised,
          repository.numbers,
        );
        final criticalBase = CharacterDerivedStats.criticalRate(
          pair.base,
          repository.numbers,
        );
        final criticalRaised = CharacterDerivedStats.criticalRate(
          pair.raised,
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
      '${stage.name}: fortune gates real encounters without combat or drop leakage',
      () async {
        final pair = _createAttributePair(
          fixture,
          stage,
          id: 700 + stage.index,
          raisedAttribute: AttributeKey.fortune,
        );
        final encounterBase = policy.encounterProbability(
          base: 0.2,
          source: EncounterProbabilitySource.fortune,
          attributes: pair.base.attributes,
        );
        final encounterRaised = policy.encounterProbability(
          base: 0.2,
          source: EncounterProbabilitySource.fortune,
          attributes: pair.raised.attributes,
        );
        final hpBase = CharacterDerivedStats.maxHp(
          pair.base,
          const [],
          repository.numbers,
        );
        final hpRaised = CharacterDerivedStats.maxHp(
          pair.raised,
          const [],
          repository.numbers,
        );
        final evasionBase = CharacterDerivedStats.evasionRate(
          pair.base,
          repository.numbers,
        );
        final evasionRaised = CharacterDerivedStats.evasionRate(
          pair.raised,
          repository.numbers,
        );
        final criticalBase = CharacterDerivedStats.criticalRate(
          pair.base,
          repository.numbers,
        );
        final criticalRaised = CharacterDerivedStats.criticalRate(
          pair.raised,
          repository.numbers,
        );

        final serviceTriggered = await _withTestIsar((isar) async {
          final service = EncounterService(
            isar: isar,
            attributeEffects: repository.numbers.attributeEffects,
          );
          final saveDataId = 7000 + stage.index;
          await service.getOrCreate(saveDataId: saveDataId);
          final baseResult = await service.evaluateTriggers(
            saveDataId: saveDataId,
            attributes: pair.base.attributes,
            encounters: [fortuneEncounter],
            rng: const _FixedRng(0.65),
          );
          final raisedResult = await service.evaluateTriggers(
            saveDataId: saveDataId,
            attributes: pair.raised.attributes,
            encounters: [fortuneEncounter],
            rng: const _FixedRng(0.65),
          );
          return (
            base: baseResult?.id == fortuneEncounter.id ? 1 : 0,
            raised: raisedResult?.id == fortuneEncounter.id ? 1 : 0,
          );
        });
        final def = _gangMengTechniqueDef(repository, pair.base);
        final skill = repository.getSkill(def.skillIds.first);
        final techniqueBase = _techniqueFor(repository, pair.base, def);
        final techniqueRaised = _techniqueFor(repository, pair.raised, def);
        expect(
          techniqueRaised.ownerCharacterId,
          techniqueBase.ownerCharacterId,
        );
        final defender = fixture.createCharacter(stage, id: 1100 + stage.index)
          ..attributes.agility = 0;
        final defenderTechnique = _techniqueFor(
          repository,
          defender,
          _gangMengTechniqueDef(repository, defender),
        );
        final damageBase = _calculateDamage(
          repository: repository,
          attacker: pair.base,
          attackerTechnique: techniqueBase,
          skill: skill,
          defender: defender,
          defenderTechnique: defenderTechnique,
        );
        final damageRaised = _calculateDamage(
          repository: repository,
          attacker: pair.raised,
          attackerTechnique: techniqueRaised,
          skill: skill,
          defender: defender,
          defenderTechnique: defenderTechnique,
        );
        final fixedNow = DateTime.utc(2026, 7, 13);
        final dropService = DropService(
          equipmentDefLookup: repository.getEquipment,
          now: () => fixedNow,
        );
        final stageDef = repository.getStage('stage_01_01');
        final dropsBase = dropService.rollDrops(
          stageDef,
          DefaultRng(seed: 20260713),
        );
        final dropsRaised = dropService.rollDrops(
          stageDef,
          DefaultRng(seed: 20260713),
        );
        final dropSnapshotBase = _dropSnapshot(dropsBase);
        final dropSnapshotRaised = _dropSnapshot(dropsRaised);
        recordAttributeObservation(
          stage,
          'fortune_encounter_probability',
          encounterBase,
          encounterRaised,
        );
        recordAttributeObservation(
          stage,
          'fortune_encounter_service_triggered',
          serviceTriggered.base,
          serviceTriggered.raised,
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
        recordAttributeObservation(
          stage,
          'fortune_deterministic_damage',
          damageBase.finalDamage,
          damageRaised.finalDamage,
        );
        recordAttributeObservation(
          stage,
          'fortune_drop_result_count',
          dropSnapshotBase.length,
          dropSnapshotRaised.length,
        );
        expect(encounterRaised, greaterThan(encounterBase));
        expect(serviceTriggered.base, 0);
        expect(serviceTriggered.raised, 1);
        expect(hpRaised, hpBase);
        expect(evasionRaised, evasionBase);
        expect(criticalRaised, criticalBase);
        expect(damageBase.isDodged, isFalse);
        expect(damageRaised.isDodged, isFalse);
        expect(damageRaised.finalDamage, damageBase.finalDamage);
        expect(dropSnapshotRaised, dropSnapshotBase);
      },
    );

    testWidgets(
      '${stage.name}: fortune unlocks a real threshold-eight choice',
      (tester) async {
        final pair = _createAttributePair(
          fixture,
          stage,
          id: 700 + stage.index,
          raisedAttribute: AttributeKey.fortune,
        );
        final choiceBase = await _choiceEnabled(
          tester,
          def: fortuneEncounter,
          content: fortuneContent,
          choice: fortuneChoice,
          fortune: pair.base.attributes.fortune,
        );
        final choiceRaised = await _choiceEnabled(
          tester,
          def: fortuneEncounter,
          content: fortuneContent,
          choice: fortuneChoice,
          fortune: pair.raised.attributes.fortune,
        );
        recordAttributeObservation(
          stage,
          'fortune_choice_enabled',
          choiceBase ? 1 : 0,
          choiceRaised ? 1 : 0,
        );
        expect(choiceBase, isFalse);
        expect(choiceRaised, isTrue);
      },
    );
  }
}
