import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/founder_creation_def.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/validation/economy_codex_red_lines_validator.dart';
import 'package:wuxia_idle/data/validation/encounter_red_lines_validator.dart';
import 'package:wuxia_idle/data/validation/lineage_recruit_red_lines_validator.dart';
import 'package:wuxia_idle/data/validation/progression_red_lines_validator.dart';
import 'package:wuxia_idle/data/validation/technique_equipment_red_lines_validator.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';

import '../../support/test_data.dart';

void main() {
  late NumbersConfig numbers;
  late NumbersConfig disabledWaveNumbers;

  setUpAll(() async {
    final yaml = parseYamlMap(await loadTestAsset('data/numbers.yaml'));
    numbers = NumbersConfig.fromYaml(yaml);
    disabledWaveNumbers = NumbersConfig.fromYaml(
      Map<String, dynamic>.from(yaml)..remove('mainline_wave'),
    );
  });

  final cases =
      <
        ({
          String name,
          String asset,
          String collection,
          void Function(bool strict) validate,
        })
      >[
        (
          name: 'enforceCodexRedLines',
          asset: 'data/narratives/codex/*.md',
          collection: 'codexEntries',
          validate: (strict) =>
              enforceCodexRedLines(strict: strict, codexEntries: const {}),
        ),
        (
          name: 'enforceShopRedLines',
          asset: 'data/shop.yaml',
          collection: 'shopItemDefs',
          validate: (strict) => enforceShopRedLines(
            strict: strict,
            shopItemDefs: const {},
            itemDefs: const {},
          ),
        ),
        (
          name: 'enforceItemRedLines',
          asset: 'data/items.yaml',
          collection: 'itemDefs',
          validate: (strict) => enforceItemRedLines(
            strict: strict,
            itemDefs: const {},
            numbers: numbers,
          ),
        ),
        (
          name: 'enforceTaohuaIslandRedLines',
          asset: 'data/items.yaml',
          collection: 'itemDefs',
          validate: (strict) => enforceTaohuaIslandRedLines(
            strict: strict,
            itemDefs: const {},
            numbers: numbers,
          ),
        ),
        (
          name: 'enforceSynergyRedLines',
          asset: 'data/synergies.yaml',
          collection: 'synergies',
          validate: (strict) => enforceSynergyRedLines(
            strict: strict,
            synergies: const [],
            techniqueDefs: const {},
          ),
        ),
        (
          name: 'enforceEncounterRedLines',
          asset: 'data/encounters.yaml',
          collection: 'encounterDefs',
          validate: (strict) => enforceEncounterRedLines(
            strict: strict,
            encounterDefs: const {},
            sectCandidates: const {},
          ),
        ),
        (
          name: 'enforceFounderCreationRedLines',
          asset: 'data/founder_creation.yaml',
          collection: 'founderCreation',
          validate: (strict) => enforceFounderCreationRedLines(
            strict: strict,
            founderCreation: FounderCreationConfig.empty,
            techniqueDefs: const {},
            equipmentDefs: const {},
          ),
        ),
        (
          name: 'enforceRecruitCandidateRedLines',
          asset: 'data/recruit_candidates.yaml',
          collection: 'recruitCandidates',
          validate: (strict) => enforceRecruitCandidateRedLines(
            strict: strict,
            recruitCandidates: const {},
            techniqueDefs: const {},
            equipmentDefs: const {},
          ),
        ),
        (
          name: 'enforceSectCandidateRedLines',
          asset: 'data/sect_candidates.yaml',
          collection: 'sectCandidates',
          validate: (strict) => enforceSectCandidateRedLines(
            strict: strict,
            sectCandidates: const {},
            techniqueDefs: const {},
            equipmentDefs: const {},
          ),
        ),
        (
          name: 'enforceLineageOnboardingRedLines',
          asset: 'data/stages.yaml',
          collection: 'existingStageIds',
          validate: (strict) => enforceLineageOnboardingRedLines(
            strict: strict,
            joins: const [],
            existingStageIds: const {},
            masters: const [],
          ),
        ),
        (
          name: 'enforceTowerRedLines',
          asset: 'data/towers.yaml',
          collection: 'towerFloors',
          validate: (strict) => enforceTowerRedLines(
            strict: strict,
            towerFloors: const [],
            skillDefs: const {},
            numbers: numbers,
          ),
        ),
        (
          name: 'enforceMainlineRedLines',
          asset: 'data/stages.yaml',
          collection: 'mainlines',
          validate: (strict) =>
              enforceMainlineRedLines(strict: strict, stageDefs: const {}),
        ),
        (
          name: 'enforceMainlineWaveRedLines',
          asset: 'data/stages.yaml',
          collection: 'mainlines',
          validate: (strict) => enforceMainlineWaveRedLines(
            strict: strict,
            stageDefs: const {},
            numbers: numbers,
          ),
        ),
        (
          name: 'enforceTechniqueRedLines',
          asset: 'data/techniques.yaml',
          collection: 'techniqueDefs',
          validate: (strict) => enforceTechniqueRedLines(
            strict: strict,
            techniqueDefs: const {},
            skillDefs: const {},
          ),
        ),
        (
          name: 'enforceEquipmentRedLines',
          asset: 'data/equipment.yaml',
          collection: 'equipmentDefs',
          validate: (strict) => enforceEquipmentRedLines(
            strict: strict,
            equipmentDefs: const {},
            numbers: numbers,
          ),
        ),
      ];

  for (final testCase in cases) {
    group(testCase.name, () {
      test('strict rejects empty input with asset and collection context', () {
        expect(
          () => testCase.validate(true),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              allOf(contains(testCase.asset), contains(testCase.collection)),
            ),
          ),
        );
      });

      test('fixture allows empty input', () {
        expect(() => testCase.validate(false), returnsNormally);
      });
    });
  }

  group('mainline wave disabled configuration', () {
    test('strict still rejects empty mainlines when waves are disabled', () {
      expect(disabledWaveNumbers.mainlineWave.isEnabled, isFalse);
      expect(
        () => enforceMainlineWaveRedLines(
          strict: true,
          stageDefs: const {},
          numbers: disabledWaveNumbers,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('data/stages.yaml'), contains('mainlines')),
          ),
        ),
      );
    });

    test('strict preserves disabled waves for nonempty mainlines', () {
      const stage = StageDef(
        id: 'stage_without_wave_profile',
        name: 'Fixture stage',
        stageType: StageType.mainline,
        requiredRealm: RealmTier.xueTu,
        enemyTeam: [],
        isBossStage: false,
        baseExpReward: 0,
        difficultyMultiplier: 1,
      );
      expect(
        () => enforceMainlineWaveRedLines(
          strict: true,
          stageDefs: {stage.id: stage},
          numbers: disabledWaveNumbers,
        ),
        returnsNormally,
      );
    });
  });
}
