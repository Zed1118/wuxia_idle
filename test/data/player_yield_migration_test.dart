import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/island_building_state.dart';
import 'package:wuxia_idle/core/domain/island_building_type.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';
import 'package:wuxia_idle/data/defs/taohua_island_config.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';

import '../fixtures/legacy_player_yield.dart';
import '../support/isar_test_support.dart';
import '../support/test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late GameRepository repository;
  final createdAt = DateTime(2026, 9, 1, 8);
  final lastOnlineAt = DateTime(2026, 9, 2, 9);
  final islandAt = DateTime(2026, 9, 2, 7, 30);

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'player_yield_migration_',
    );
  });

  tearDown(() async {
    if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  List<BuildingConfig> processors() => repository
      .numbers
      .taohuaIsland
      .buildings
      .values
      .where((building) => building.kind == BuildingKind.processor)
      .toList();

  Future<void> seedLegacy({
    int slotId = 1,
    DateTime? presenceAt,
    List<LegacyPlayerYieldIslandBuildingState>? buildings,
  }) async {
    final legacy = await Isar.open(
      [LegacyPlayerYieldSaveDataSchema, LegacyPlayerYieldCharacterSchema],
      directory: directory.path,
      name: 'wuxia_save_slot$slotId',
      inspector: false,
    );
    try {
      await legacy.writeTxn(() async {
        await legacy.collection<LegacyPlayerYieldSaveData>().put(
          LegacyPlayerYieldSaveData()
            ..saveVersion = '0.49.0'
            ..slotId = slotId
            ..slotName = 'legacy-slot-$slotId'
            ..createdAt = createdAt
            ..lastSavedAt = lastOnlineAt
            ..lastOnlineAt = presenceAt ?? lastOnlineAt
            ..founderCharacterId = 1
            ..activeCharacterIds = [1]
            ..recruitedDiscipleIds = [2]
            ..totalPassiveExperience = 47
            ..totalPassiveMojianshi = 31
            ..totalPlaySeconds = 1234
            ..gauntletRunSerial = 17
            ..expeditionRunSerial = 29
            ..skillUnlockProgress = [
              SkillUnlockEntry()
                ..skillId = 'skill_gangmeng_jichu_basic'
                ..fragmentCount = 3
                ..unlocked = true,
            ]
            ..islandBuildings = buildings ?? []
            ..islandLastSettledAt = islandAt,
        );
        await legacy.collection<LegacyPlayerYieldCharacter>().putAll([
          for (final id in [1, 2])
            LegacyPlayerYieldCharacter()
              ..id = id
              ..name = 'slot-$slotId-character-$id'
              ..realmTier = RealmTier.xueTu
              ..realmLayer = RealmLayer.qiMeng
              ..attributes = Attributes()
              ..lineageRole = id == 1
                  ? LineageRole.founder
                  : LineageRole.disciple
              ..isFounder = id == 1
              ..isActive = id == 1
              ..experience = 10 * slotId + id
              ..createdAt = createdAt,
        ]);
      });
    } finally {
      await legacy.close();
    }
  }

  Future<T> inspectRaw<T>(int slotId, Future<T> Function(Isar) read) async {
    final raw = await Isar.open(
      IsarSetup.schemasForTesting,
      directory: directory.path,
      name: 'wuxia_save_slot$slotId',
      inspector: false,
    );
    try {
      return await read(raw);
    } finally {
      await raw.close();
    }
  }

  Future<Map<String, Object?>> snapshot(Isar isar) async {
    final save = (await isar.saveDatas.get(0))!;
    final characters = [...await isar.characters.where().findAll()]
      ..sort((left, right) => left.id.compareTo(right.id));
    return {
      'version': save.saveVersion,
      'slot': save.slotId,
      'name': save.slotName,
      'created': save.createdAt,
      'saved': save.lastSavedAt,
      'presence': save.lastOnlineAt,
      'anchor': save.passiveLastSettledAt,
      'materialFraction': save.passiveMojianshiRemainder,
      'expTotal': save.totalPassiveExperience,
      'materialTotal': save.totalPassiveMojianshi,
      'playSeconds': save.totalPlaySeconds,
      'gauntletSerial': save.gauntletRunSerial,
      'expeditionSerial': save.expeditionRunSerial,
      'islandAnchor': save.islandLastSettledAt,
      'skills': [
        for (final skill in save.skillUnlockProgress)
          [skill.skillId, skill.fragmentCount, skill.unlocked],
      ],
      'buildings': [
        for (final building in save.islandBuildings)
          [
            building.type,
            building.level,
            building.stored,
            building.activeRecipeId,
            [
              for (final stock in building.productStocks)
                [stock.outputItemId, stock.stored],
            ],
          ],
      ],
      'characters': [
        for (final character in characters)
          [
            character.id,
            character.name,
            character.realmTier,
            character.realmLayer,
            character.experience,
            character.passiveExperienceRemainder,
            character.internalForceMax,
            character.injuryHoursRemaining,
            character.isAlive,
            character.attributes.total,
          ],
      ],
    };
  }

  test(
    'legacy fixtures retain every 0.49 property and omit only the new yield fields',
    () {
      expect(LegacyPlayerYieldSaveDataSchema.name, 'SaveData');
      expect(LegacyPlayerYieldCharacterSchema.name, 'Character');
      expect(
        LegacyPlayerYieldIslandBuildingStateSchema.name,
        'IslandBuildingState',
      );
      expect(
        LegacyPlayerYieldSaveDataSchema.properties.keys.toSet(),
        SaveDataSchema.properties.keys.toSet()
          ..removeAll({'passiveLastSettledAt', 'passiveMojianshiRemainder'}),
      );
      expect(
        LegacyPlayerYieldCharacterSchema.properties.keys.toSet(),
        CharacterSchema.properties.keys.toSet()
          ..remove('passiveExperienceRemainder'),
      );
      expect(
        LegacyPlayerYieldIslandBuildingStateSchema.properties.keys.toSet(),
        IslandBuildingStateSchema.properties.keys.toSet()
          ..remove('productStocks'),
      );
      for (final (oldSchema, currentSchema) in <(Schema, Schema)>[
        (LegacyPlayerYieldSaveDataSchema, SaveDataSchema),
        (LegacyPlayerYieldCharacterSchema, CharacterSchema),
        (LegacyPlayerYieldIslandBuildingStateSchema, IslandBuildingStateSchema),
      ]) {
        for (final property in oldSchema.properties.values) {
          expect(
            property.type,
            currentSchema.properties[property.name]!.type,
            reason: '${oldSchema.name}.${property.name}',
          );
        }
      }
    },
  );

  test(
    'real 0.49 stock identity, fractions and established presence survive 0.50 and repeated reopen',
    () async {
      final configs = repository.numbers.taohuaIsland.buildings.values.toList();
      var processorIndex = 0;
      final legacyBuildings = [
        for (final config in configs)
          LegacyPlayerYieldIslandBuildingState()
            ..type = config.type
            ..level = 2
            ..stored = config.kind == BuildingKind.source
                ? 12.25
                : [9.0, 2.625, 0.75][processorIndex++ % 3]
            ..activeRecipeId = config.kind == BuildingKind.processor
                ? config.recipes.last.recipeId
                : null,
      ];
      await seedLegacy(buildings: legacyBuildings);
      await inspectRaw(1, (raw) async {
        final save = (await raw.saveDatas.get(0))!;
        expect(save.saveVersion, '0.49.0');
        expect(save.passiveLastSettledAt, isNull);
        expect(save.passiveMojianshiRemainder.isNaN, isTrue);
        final characters = await raw.characters.where().findAll();
        expect(characters, hasLength(2));
        for (final character in characters) {
          expect(character.passiveExperienceRemainder.isNaN, isTrue);
          expect(character.experience, 10 + character.id);
          expect(character.injuryHoursRemaining, 0);
        }
        expect(
          save.islandBuildings.every(
            (building) => building.productStocks.isEmpty,
          ),
          isTrue,
        );
      });

      await IsarSetup.init(directory: directory, inspector: false);
      final isar = IsarSetup.instance;
      final save = (await isar.saveDatas.get(0))!;
      expect(save.saveVersion, '0.50.0');
      expect(save.passiveLastSettledAt, lastOnlineAt);
      expect(save.passiveMojianshiRemainder, 0);
      expect(save.lastOnlineAt, lastOnlineAt);
      expect(save.islandLastSettledAt, islandAt);
      expect(save.totalPassiveExperience, 47);
      expect(save.totalPassiveMojianshi, 31);
      expect(save.gauntletRunSerial, 17);
      expect(save.expeditionRunSerial, 29);
      expect(save.islandBuildings, hasLength(legacyBuildings.length));
      for (final original in legacyBuildings) {
        final migrated = save.islandBuildings.singleWhere(
          (row) => row.type == original.type,
        );
        final config = repository.numbers.taohuaIsland.buildingOf(
          original.type,
        );
        expect(migrated.level, original.level);
        expect(migrated.activeRecipeId, original.activeRecipeId);
        if (config.kind == BuildingKind.source) {
          expect(migrated.stored, original.stored);
          expect(migrated.productStocks, isEmpty);
        } else {
          final output = config
              .recipeById(original.activeRecipeId!)!
              .outputItem;
          expect(migrated.stored, 0);
          expect(migrated.productStocks, hasLength(1));
          expect(migrated.productStocks.single.outputItemId, output);
          expect(migrated.productStocks.single.stored, original.stored);
        }
      }
      for (final character in await isar.characters.where().findAll()) {
        expect(character.passiveExperienceRemainder, 0);
        expect(character.experience, 10 + character.id);
      }
      final after = await snapshot(isar);
      for (var reopen = 0; reopen < 2; reopen++) {
        await IsarSetup.close();
        await IsarSetup.init(directory: directory, inspector: false);
        expect(await snapshot(IsarSetup.instance), after);
      }
    },
  );

  test(
    'unestablished creation timestamp does not retroactively grant an idle window',
    () async {
      await seedLegacy(presenceAt: createdAt);
      await IsarSetup.init(directory: directory, inspector: false);
      final isar = IsarSetup.instance;
      expect((await isar.saveDatas.get(0))!.passiveLastSettledAt, isNull);
      final boundary = createdAt.add(const Duration(days: 3));
      expect(
        await OfflinePassiveService.settleWindow(isar: isar, now: boundary),
        isNull,
      );
      final save = (await isar.saveDatas.get(0))!;
      expect(save.passiveLastSettledAt, boundary);
      expect(save.totalPassiveExperience, 47);
      expect(save.totalPassiveMojianshi, 31);
      expect((await isar.characters.get(1))!.experience, 11);
    },
  );

  for (final missingRecipe in [null, 'missing-legacy-recipe']) {
    test(
      'positive stock with recipe=$missingRecipe rolls back version, earlier stocks and sentinel repair',
      () async {
        final good = processors()[0];
        final bad = processors()[1];
        await seedLegacy(
          buildings: [
            LegacyPlayerYieldIslandBuildingState()
              ..type = good.type
              ..level = 3
              ..stored = 8.5
              ..activeRecipeId = good.recipes.first.recipeId,
            LegacyPlayerYieldIslandBuildingState()
              ..type = bad.type
              ..level = 2
              ..stored = 2.75
              ..activeRecipeId = missingRecipe,
          ],
        );
        await expectLater(
          IsarSetup.init(directory: directory, inspector: false),
          throwsStateError,
        );
        expect(IsarSetup.instanceOrNull, isNull);
        await inspectRaw(1, (raw) async {
          final save = (await raw.saveDatas.get(0))!;
          expect(save.saveVersion, '0.49.0');
          expect(save.passiveLastSettledAt, isNull);
          expect(save.passiveMojianshiRemainder.isNaN, isTrue);
          expect(save.lastOnlineAt, lastOnlineAt);
          expect(save.islandLastSettledAt, islandAt);
          expect(save.islandBuildings.map((building) => building.stored), [
            8.5,
            2.75,
          ]);
          expect(
            save.islandBuildings.every(
              (building) => building.productStocks.isEmpty,
            ),
            isTrue,
          );
          expect(save.islandBuildings.last.activeRecipeId, missingRecipe);
          for (final character in await raw.characters.where().findAll()) {
            expect(character.passiveExperienceRemainder.isNaN, isTrue);
            expect(character.experience, 10 + character.id);
          }
          await raw.writeTxn(() async {
            save.islandBuildings.last.activeRecipeId =
                bad.recipes.last.recipeId;
            await raw.saveDatas.put(save);
          });
        });
        await IsarSetup.init(directory: directory, inspector: false);
        final repaired = (await IsarSetup.currentSaveData())!;
        expect(repaired.saveVersion, '0.50.0');
        expect(
          repaired.islandBuildings.first.productStored(
            good.recipes.first.outputItem,
          ),
          8.5,
        );
        expect(
          repaired.islandBuildings.last.productStored(
            bad.recipes.last.outputItem,
          ),
          2.75,
        );
      },
    );
  }

  test(
    'finite current-schema fractions and existing product identity survive migration and current-version reopen',
    () async {
      final config = processors().first;
      await seedLegacy(
        buildings: [
          LegacyPlayerYieldIslandBuildingState()
            ..type = config.type
            ..stored = 3.25
            ..activeRecipeId = config.recipes.first.recipeId,
        ],
      );
      await IsarSetup.init(directory: directory, inspector: false);
      final anchor = lastOnlineAt.subtract(const Duration(minutes: 15));
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.instance.saveDatas.get(0))!
          ..saveVersion = '0.49.0'
          ..passiveLastSettledAt = anchor
          ..passiveMojianshiRemainder = 0.375;
        // The selected recipe can differ from a previously stored output.
        save.islandBuildings.single.activeRecipeId =
            config.recipes.last.recipeId;
        await IsarSetup.instance.saveDatas.put(save);
        for (final id in [1, 2]) {
          final character = (await IsarSetup.instance.characters.get(id))!
            ..passiveExperienceRemainder = id == 1 ? 0.625 : 0.875;
          await IsarSetup.instance.characters.put(character);
        }
      });
      for (var reopen = 0; reopen < 2; reopen++) {
        await IsarSetup.close();
        await IsarSetup.init(directory: directory, inspector: false);
        final save = (await IsarSetup.currentSaveData())!;
        expect(save.saveVersion, '0.50.0');
        expect(save.passiveLastSettledAt, anchor);
        expect(save.passiveMojianshiRemainder, 0.375);
        expect(
          (await IsarSetup.instance.characters.get(
            1,
          ))!.passiveExperienceRemainder,
          0.625,
        );
        expect(
          (await IsarSetup.instance.characters.get(
            2,
          ))!.passiveExperienceRemainder,
          0.875,
        );
        expect(save.islandBuildings.single.productStocks, hasLength(1));
        expect(
          save.islandBuildings.single.productStocks.single.outputItemId,
          config.recipes.first.outputItem,
        );
        expect(save.islandBuildings.single.productStocks.single.stored, 3.25);
        expect(
          save.islandBuildings.single.activeRecipeId,
          config.recipes.last.recipeId,
        );
      }
    },
  );

  test(
    'opening one real legacy slot cannot migrate or copy another slot yield ledger',
    () async {
      final config = processors().first;
      for (final slot in [1, 2]) {
        await seedLegacy(
          slotId: slot,
          presenceAt: lastOnlineAt.add(Duration(hours: slot)),
          buildings: [
            LegacyPlayerYieldIslandBuildingState()
              ..type = config.type
              ..level = slot
              ..stored = slot + 0.25
              ..activeRecipeId = slot == 1
                  ? config.recipes.first.recipeId
                  : config.recipes.last.recipeId,
          ],
        );
      }
      await IsarSetup.init(directory: directory, inspector: false, slotId: 1);
      final slot1 = await snapshot(IsarSetup.instance);
      await IsarSetup.close();
      await inspectRaw(2, (raw) async {
        final save = (await raw.saveDatas.get(0))!;
        expect(save.saveVersion, '0.49.0');
        expect(save.islandBuildings.single.stored, 2.25);
        expect(save.islandBuildings.single.productStocks, isEmpty);
        expect(save.passiveMojianshiRemainder.isNaN, isTrue);
      });
      await IsarSetup.init(directory: directory, inspector: false, slotId: 2);
      final save2 = (await IsarSetup.currentSaveData())!;
      expect(save2.slotId, 2);
      expect(
        save2.passiveLastSettledAt,
        lastOnlineAt.add(const Duration(hours: 2)),
      );
      expect(
        save2.islandBuildings.single.productStocks.single.outputItemId,
        config.recipes.last.outputItem,
      );
      expect(save2.islandBuildings.single.productStocks.single.stored, 2.25);
      expect((await IsarSetup.instance.characters.get(1))!.experience, 21);
      await IsarSetup.close();
      await IsarSetup.init(directory: directory, inspector: false, slotId: 1);
      expect(await snapshot(IsarSetup.instance), slot1);
      expect((await IsarSetup.instance.characters.get(1))!.experience, 11);
    },
  );
}
