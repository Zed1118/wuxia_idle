import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_progress.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

import '../fixtures/legacy_missing_fields.dart';
import '../support/isar_test_support.dart';

void main() {
  test(
    'an entirely absent embedded property instantiates its constructor defaults',
    () async {
      await initializeTestIsarCore();
      final dir = await Directory.systemTemp.createTemp('isar_missing_object_');
      Isar? db;
      try {
        expect(
          AbsentCharacterPropertiesSchema.properties,
          isNot(contains('attributes')),
        );
        db = await Isar.open(
          [AbsentCharacterPropertiesSchema],
          directory: dir.path,
          name: 'absent_object',
          inspector: false,
        );
        await db.writeTxn(
          () => db!.collection<AbsentCharacterProperties>().put(
            AbsentCharacterProperties(),
          ),
        );
        await db.close();
        db = await Isar.open(
          [CharacterSchema],
          directory: dir.path,
          name: 'absent_object',
          inspector: false,
        );
        expect((await db.characters.get(1))!.attributes.constitution, 5);
      } finally {
        if (db?.isOpen ?? false) await db!.close();
        await dir.delete(recursive: true);
      }
    },
  );
  test(
    'real omitted fields: primitive, enum, list and embedded values',
    () async {
      await initializeTestIsarCore();
      final dir = await Directory.systemTemp.createTemp('isar_missing_types_');
      Isar? db;
      try {
        db = await Isar.open(
          [
            MissingCharacterSchema,
            MissingEquipmentSchema,
            MissingEncounterProgressSchema,
            MissingMainlineListsSchema,
            MissingTowerCycleSchema,
          ],
          directory: dir.path,
          name: 'types',
          inspector: false,
        );
        await db.writeTxn(() async {
          await db!.collection<MissingCharacter>().putAll([
            MissingCharacter()..id = 1,
            MissingCharacter()
              ..id = 2
              ..attributes = MissingAttributes(),
          ]);
          await db.collection<MissingEquipment>().put(
            MissingEquipment()
              ..id = 1
              ..lores = [MissingLore()],
          );
          await db.collection<MissingEncounterProgress>().put(
            MissingEncounterProgress()
              ..id = 1
              ..biomeMinutes = [MissingBiomeMinutes()],
          );
          await db.collection<MissingMainlineLists>().put(
            MissingMainlineLists(),
          );
          await db.collection<MissingTowerCycle>().put(MissingTowerCycle());
        });
        await db.close();
        db = await Isar.open(
          [
            CharacterSchema,
            EquipmentSchema,
            EncounterProgressSchema,
            MainlineProgressSchema,
            TowerProgressSchema,
          ],
          directory: dir.path,
          name: 'types',
          inspector: false,
        );
        final character = (await db.characters.get(1))!;
        final nested = (await db.characters.get(2))!;
        final lore = (await db.equipments.get(1))!.lores.single;
        final biome = (await db.encounterProgress.get(1))!.biomeMinutes.single;

        expect(character.internalForce, -9223372036854775808);
        expect(character.injuryHoursRemaining.isNaN, isTrue);
        expect(character.isActive, isFalse);
        expect(character.isAlive, isFalse);
        expect(character.name, '');
        expect(character.createdAt.microsecondsSinceEpoch, 0);
        expect(character.rarity, RarityTier.values.first);
        expect(character.realmTier, RealmTier.values.first);
        expect(character.school, isNull);
        expect(character.assistTechniqueIds, isEmpty);
        expect(character.learnedSkillIds, isEmpty);
        expect(character.mainTechniqueId, isNull);
        expect(character.portraitPath, isNull);
        expect((await db.mainlineProgress.get(1))!.clearedAt, isEmpty);
        expect((await db.towerProgress.get(1))!.highestClearedAt, isNull);
        expect(character.attributes.constitution, 5);
        expect(nested.attributes.constitution, -9223372036854775808);
        expect(lore.isPreset, isFalse);
        expect(lore.addedAt.microsecondsSinceEpoch, 0);
        expect(lore.triggerEventDesc, isNull);
        expect(biome.biome, EncounterBiome.values.first);
        expect(biome.minutes, -9223372036854775808);
        expect((await db.encounterProgress.get(1))!.schoolKillCounts, isEmpty);
        // ignore: avoid_print
        print(
          'MISSING TYPES: int=${character.internalForce}; '
          'double=${character.injuryHoursRemaining}; '
          'bool(false/true)=${character.isActive}/${character.isAlive}; '
          'String="${character.name}"; DateTime=${character.createdAt.toUtc()}; '
          'name-enum=${character.rarity}; ordinal-enum=${biome.biome}; '
          'List<int>/List<String>/List<DateTime>/List<embedded>=[]; '
          'null embedded=constructor, present embedded missing int=minLong',
        );
      } finally {
        if (db?.isOpen ?? false) await db!.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
