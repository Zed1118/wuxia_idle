import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/yaml_loader.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final overrides = <String, String?>{};

  Future<String> fixtureLoader(String path) async {
    if (overrides.containsKey(path)) {
      final raw = overrides[path];
      if (raw == null) throw FileSystemException('Missing fixture asset', path);
      return raw;
    }
    return File(path).readAsString();
  }

  setUp(() {
    overrides.clear();
    rootBundle.clear();
    GameRepository.resetForTest();
    // Exercise loader == null through the actual rootBundle channel. In-memory
    // corruption never modifies the shipped YAML or bypasses production mode.
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
      message,
    ) async {
      final path = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      if (overrides.containsKey(path)) {
        final raw = overrides[path];
        return raw == null
            ? null
            : ByteData.sublistView(Uint8List.fromList(utf8.encode(raw)));
      }
      final file = File(path);
      return await file.exists()
          ? ByteData.sublistView(await file.readAsBytes())
          : null;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    );
    rootBundle.clear();
    GameRepository.resetForTest();
  });

  Matcher assetFailure(String path, [List<String> details = const []]) =>
      isA<FormatException>().having(
        (e) => e.message,
        'asset and error context',
        allOf([contains(path), ...details.map(contains)]),
      );

  const optionalAssets = [
    'data/encounter_skills.yaml',
    'data/founder_creation.yaml',
    'data/founder_names.yaml',
    'data/recruit_candidates.yaml',
    'data/sect_candidates.yaml',
    'data/encounters.yaml',
    'data/synergies.yaml',
    'data/territories.yaml',
    'data/factions.yaml',
    'data/shop.yaml',
    'data/items.yaml',
    'data/expeditions.yaml',
    'data/boss_gauntlets.yaml',
  ];

  test(
    'production rootBundle loads the complete shipped configuration',
    () async {
      final repo = await GameRepository.loadAllDefs();
      expect(repo.recruitCandidates, hasLength(3));
      expect(repo.sectCandidates, hasLength(6));
      expect(repo.encounterSkillIds, isNotEmpty);
      expect(repo.combatRuntimeBindings, isNotNull);
    },
  );

  for (final path in optionalAssets) {
    test('production rejects malformed $path with source context', () async {
      overrides[path] = '[unterminated';
      await expectLater(
        GameRepository.loadAllDefs(),
        throwsA(assetFailure(path)),
      );
      expect(GameRepository.isLoaded, isFalse);
    });

    test('production rejects missing $path with source context', () async {
      overrides[path] = null;
      await expectLater(
        GameRepository.loadAllDefs(),
        throwsA(assetFailure(path)),
      );
      expect(GameRepository.isLoaded, isFalse);
    });
  }

  for (final pool in ['recruit', 'sect']) {
    final path = 'data/${pool}_candidates.yaml';
    for (final field in ['startingTechniqueIds', 'startingEquipmentIds']) {
      for (final strict in [true, false]) {
        test('$pool $field dangling reference: strict=$strict', () async {
          final yaml = parseYamlMap(await File(path).readAsString());
          final first = (yaml['${pool}_candidates'] as List).first as Map;
          final candidateId = first['id'] as String;
          final missingId = 'missing_${pool}_$field';
          first[field] = [missingId];
          // JSON is valid YAML and preserves all other fixture fields.
          overrides[path] = jsonEncode(yaml);
          if (strict) {
            await expectLater(
              GameRepository.loadAllDefs(),
              throwsA(assetFailure(path, [candidateId, missingId, field])),
            );
            expect(GameRepository.isLoaded, isFalse);
          } else {
            final repo = await GameRepository.loadAllDefs(
              loader: fixtureLoader,
            );
            expect(
              pool == 'recruit' ? repo.recruitCandidates : repo.sectCandidates,
              isEmpty,
            );
          }
        });
      }
    }

    test('fixture may omit $path without throwing', () async {
      overrides[path] = null;
      final repo = await GameRepository.loadAllDefs(loader: fixtureLoader);
      expect(
        pool == 'recruit' ? repo.recruitCandidates : repo.sectCandidates,
        isEmpty,
      );
    });

    test(
      'production empty $pool pool reaches strict red-line validation',
      () async {
        overrides[path] = '${pool}_candidates: []';
        await expectLater(
          GameRepository.loadAllDefs(),
          throwsA(
            isA<StateError>().having((e) => e.message, 'asset', contains(path)),
          ),
        );
      },
    );
  }

  test('fixtures may omit all optional YAML assets', () async {
    for (final path in optionalAssets) {
      overrides[path] = null;
    }
    // A fixture omitting the gauntlet also omits skills owned by that module;
    // retaining them would correctly fail the existing source-mount red line.
    final skills = parseYamlMap(await File('data/skills.yaml').readAsString());
    (skills['skills'] as List).removeWhere(
      (skill) => skill['source'] == 'gauntlet',
    );
    overrides['data/skills.yaml'] = jsonEncode(skills);
    final repo = await GameRepository.loadAllDefs(loader: fixtureLoader);
    expect(repo.encounterSkillIds, isEmpty);
    expect(repo.recruitCandidates, isEmpty);
    expect(repo.sectCandidates, isEmpty);
    expect(repo.encounterDefs, isEmpty);
    expect(repo.synergies, isEmpty);
    expect(repo.factionDefs, isEmpty);
    expect(repo.territoryDefs, isEmpty);
    expect(repo.shopItemDefs, isEmpty);
    expect(repo.itemDefs, isEmpty);
    expect(repo.founderCreation.schools, isEmpty);
    expect(repo.founderNames.founderSurnames, isEmpty);
    expect(repo.expeditionConfig, isNull);
    expect(repo.bossGauntletConfig, isNull);
  });

  test(
    'four legacy fixture loaders retain malformed-content fallback',
    () async {
      for (final path in [
        'data/encounter_skills.yaml',
        'data/recruit_candidates.yaml',
        'data/sect_candidates.yaml',
        'data/encounters.yaml',
      ]) {
        overrides[path] = '[unterminated';
      }
      final repo = await GameRepository.loadAllDefs(loader: fixtureLoader);
      expect(repo.encounterSkillIds, isEmpty);
      expect(repo.recruitCandidates, isEmpty);
      expect(repo.sectCandidates, isEmpty);
      expect(repo.encounterDefs, isEmpty);
    },
  );

  test(
    'fixture encounter skill read StateError is preserved unchanged',
    () async {
      final failure = StateError('Encounter skill fixture loader failed');
      await expectLater(
        GameRepository.loadAllDefs(
          loader: (path) {
            if (path == 'data/encounter_skills.yaml') throw failure;
            return fixtureLoader(path);
          },
        ),
        throwsA(same(failure)),
      );
    },
  );

  for (final raw in ['{}', 'factions: []']) {
    for (final strict in [true, false]) {
      test('faction empty configuration $raw: strict=$strict', () async {
        overrides['data/factions.yaml'] = raw;
        if (!strict) {
          final repo = await GameRepository.loadAllDefs(loader: fixtureLoader);
          expect(repo.factionDefs, isEmpty);
          return;
        }
        if (raw == '{}') {
          await expectLater(
            GameRepository.loadAllDefs(),
            throwsA(assetFailure('data/factions.yaml')),
          );
        } else {
          final stages = parseYamlMap(
            await File('data/stages.yaml').readAsString(),
          );
          final source =
              (stages['stages'] as List).firstWhere(
                    (stage) => stage['factionId'] != null,
                  )
                  as Map;
          await expectLater(
            GameRepository.loadAllDefs(),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'source and dangling faction reference',
                allOf(
                  contains('factions.yaml'),
                  contains(source['id']),
                  contains(source['factionId']),
                ),
              ),
            ),
          );
        }
      });
    }
  }
}
