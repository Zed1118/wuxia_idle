import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_seed.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

import '../fixtures/legacy_missing_fields.dart';
import '../fixtures/legacy_numeric_fields.dart';
import '../support/isar_numeric_field_evidence.dart';
import '../support/isar_test_support.dart';
import '../support/test_data.dart';

void main() {
  late Directory dir;
  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('isar_missing_boundary_');
  });
  tearDown(() async {
    if (IsarSetup.instanceOrNull != null) await IsarSetup.close();
    await dir.delete(recursive: true);
  });

  Future<void> seedCharacter({bool deferred = false, int slotId = 1}) async {
    final old = await Isar.open(
      [
        Legacy048SaveDataSchema,
        if (deferred)
          MissingCharacterMaxAndBirthSchema
        else
          MissingCharacterSchema,
      ],
      directory: dir.path,
      name: 'wuxia_save_slot1',
      inspector: false,
    );
    try {
      await old.writeTxn(() async {
        await old.collection<Legacy048SaveData>().put(
          Legacy048SaveData()
            ..slotId = slotId
            ..saveVersion = '0.35.0',
        );
        if (deferred) {
          await old.collection<MissingCharacterMaxAndBirth>().put(
            MissingCharacterMaxAndBirth(),
          );
        } else {
          await old.collection<MissingCharacter>().put(
            MissingCharacter()..id = 1,
          );
        }
      });
    } finally {
      await old.close();
    }
  }

  test(
    '0.35 missing breath and bonus are normalized before legacy duration and rarity calculations',
    () async {
      await seedCharacter();
      await IsarSetup.init(directory: dir, inspector: false);
      final character = (await IsarSetup.instance.characters.get(1))!;
      expect(character.innerBreathDisorderHoursRemaining, 6);
      expect(character.innerDemonResidueHoursRemaining, 0);
      expect(character.internalForce, 750);
      expect(character.internalForceMax, 750);
      expect(character.attributeBonusFromAdventure, 0);
      expect(character.rarity, RarityTier.biaoZhun);
      await IsarSetup.close();
      await IsarSetup.init(directory: dir, inspector: false);
      expect(
        (await IsarSetup.instance.characters.get(
          1,
        ))!.innerBreathDisorderHoursRemaining,
        6,
      );
    },
  );

  test(
    'deferred maximum and birth attributes do not poison legitimate force or rarity',
    () async {
      await seedCharacter(deferred: true);
      await IsarSetup.init(directory: dir, inspector: false);
      final character = (await IsarSetup.instance.characters.get(1))!;
      expect(character.internalForce, 123);
      expect(character.rarity, RarityTier.jueShi);
      expect(character.internalForceMax, -9223372036854775808);
      expect(character.attributes.constitution, -9223372036854775808);
    },
  );

  test(
    '0.41 missing tower cycle is repaired before receipt creation; no negative cycle keys',
    () async {
      final old = await Isar.open(
        [Legacy048SaveDataSchema, MissingTowerCycleSchema],
        directory: dir.path,
        name: 'wuxia_save_slot1',
        inspector: false,
      );
      try {
        await old.writeTxn(() async {
          await old.collection<Legacy048SaveData>().put(
            Legacy048SaveData()..saveVersion = '0.41.0',
          );
          await old.collection<MissingTowerCycle>().put(MissingTowerCycle());
        });
      } finally {
        await old.close();
      }
      await IsarSetup.init(directory: dir, inspector: false);
      expect(
        (await IsarSetup.instance.towerProgress.get(1))!.currentCycleIndex,
        1,
      );
      final receipts = await IsarSetup.instance.rewardClaimReceipts
          .where()
          .findAll();
      expect(receipts.map((r) => r.contentId).toSet(), {
        'tower_floor_1_cycle_1',
        'tower_floor_2_cycle_1',
      });
      await IsarSetup.close();
      await IsarSetup.init(directory: dir, inspector: false);
      expect(
        await IsarSetup.instance.rewardClaimReceipts.count(),
        receipts.length,
      );
    },
  );

  test(
    'failed older segment rolls back both normalization and version',
    () async {
      await seedCharacter(slotId: 9);
      await expectLater(
        IsarSetup.init(directory: dir, inspector: false),
        throwsStateError,
      );
      final raw = await Isar.open(
        IsarSetup.schemasForTesting,
        directory: dir.path,
        name: 'wuxia_save_slot1',
        inspector: false,
      );
      try {
        expect((await raw.saveDatas.get(0))!.saveVersion, '0.35.0');
        expect(
          (await raw.characters.get(
            1,
          ))!.innerBreathDisorderHoursRemaining.isNaN,
          isTrue,
        );
        expect(
          (await raw.characters.get(1))!.innerDemonResidueHoursRemaining,
          6,
        );
      } finally {
        await raw.close();
      }
    },
  );

  Future<void> seedAll(int slotId) async {
    final old = await Isar.open(
      legacyNumericSchemas,
      directory: dir.path,
      name: 'wuxia_save_slot$slotId',
      inspector: false,
    );
    try {
      await seedLegacyNumericRows(old, slotId: slotId);
    } finally {
      await old.close();
    }
  }

  test(
    'slot 1 migration leaves slot 2 bytes untouched and each slot migrates independently',
    () async {
      await seedAll(1);
      await seedAll(2);
      final other = File('${dir.path}/wuxia_save_slot2.isar');
      final before = await other.readAsBytes();
      await IsarSetup.init(directory: dir, inspector: false);
      expect((await IsarSetup.currentSaveData())!.expeditionRunSerial, 0);
      await IsarSetup.close();
      expect(await other.readAsBytes(), before);
      await IsarSetup.init(slotId: 2, directory: dir, inspector: false);
      final save = (await IsarSetup.currentSaveData())!;
      expect(save.slotId, 2);
      expect(save.expeditionRunSerial, 0);
    },
  );

  test(
    'non-sentinel numbers, existing seeds and ambiguous false/enum/date values stay unchanged',
    () async {
      await seedAll(1);
      final raw = await Isar.open(
        IsarSetup.schemasForTesting,
        directory: dir.path,
        name: 'wuxia_save_slot1',
        inspector: false,
      );
      try {
        await raw.writeTxn(() async {
          for (final field in numericFieldEvidence) {
            await field.write(raw, field.isDouble ? -0.5 : -1);
          }
          final save = (await raw.saveDatas.get(0))!
            ..expeditionRunSerial = -9223372036854775807;
          await raw.saveDatas.put(save);
          final expedition = (await raw.expeditionRuns.get(1))!
            ..seed = -9223372036854775807;
          await raw.expeditionRuns.put(expedition);
          final gauntlet = (await raw.bossGauntletRuns.get(1))!..seed = 8202;
          await raw.bossGauntletRuns.put(gauntlet);
          final character = (await raw.characters.get(1))!
            ..isAlive = false
            ..rarity = RarityTier.values.first
            ..injuryHoursRemaining = double.infinity;
          await raw.characters.put(character);
          final equipment = (await raw.equipments.get(1))!;
          equipment.lores.single
            ..isPreset = false
            ..addedAt = DateTime.fromMillisecondsSinceEpoch(0);
          await raw.equipments.put(equipment);
        });
      } finally {
        await raw.close();
      }
      await IsarSetup.init(directory: dir, inspector: false);
      final db = IsarSetup.instance;
      for (final field in numericFieldEvidence) {
        final expected = field.key == 'SaveData.expeditionRunSerial'
            ? -9223372036854775807
            : field.key == 'Character.injuryHoursRemaining'
            ? double.infinity
            : field.isDouble
            ? -0.5
            : -1;
        expect(await field.read(db), everyElement(expected), reason: field.key);
      }
      expect((await db.expeditionRuns.get(1))!.seed, -9223372036854775807);
      expect((await db.bossGauntletRuns.get(1))!.seed, 8202);
      expect((await db.characters.get(1))!.isAlive, isFalse);
      expect((await db.characters.get(1))!.rarity, RarityTier.values.first);
      final lore = (await db.equipments.get(1))!.lores.single;
      expect(lore.isPreset, isFalse);
      expect(lore.addedAt.microsecondsSinceEpoch, 0);
    },
  );

  test(
    'minLong plus one is an ordinary negative value and the node seed uses its low 32 bits',
    () {
      const minimum = -9223372036854775808;
      expect(minimum + 1, -9223372036854775807);
      expect(() => Random(minimum + 1).nextInt(100), returnsNormally);
      for (final serial in [1, 2, 17]) {
        expect(
          ExpeditionSeed.forNode(
            saveId: 1,
            runSerial: minimum + serial,
            node: 3,
          ),
          ExpeditionSeed.forNode(saveId: 1, runSerial: serial, node: 3),
        );
      }
      expect(
        ExpeditionSeed.forNode(saveId: 1, runSerial: minimum + 1, node: 3),
        isNot(
          ExpeditionSeed.forNode(saveId: 1, runSerial: minimum + 2, node: 3),
        ),
      );
    },
  );
}
