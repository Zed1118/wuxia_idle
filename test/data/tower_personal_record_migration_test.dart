import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/tower/domain/tower_personal_record.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

import '../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'tower_personal_record_migration_',
    );
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('0.44 registers the versioned TowerPersonalRecord collection', () {
    expect(
      IsarSetup.schemasForTesting.map((schema) => schema.name),
      contains('TowerPersonalRecord'),
    );
  });

  test('tower personal record remains registered after saveVersion 0.45.0', () {
    expect(IsarSetup.currentSaveVersion, '0.45.0');
  });

  test(
    '0.43 global tower history upgrades without fabricating a participant record',
    () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.instance.saveDatas.get(0))!;
        save.saveVersion = '0.43.0';
        await IsarSetup.instance.saveDatas.put(save);
        await IsarSetup.instance.characters.put(
          Character.create(
            name: '旧档在籍角色但无参战证明',
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            attributes: Attributes(),
            rarity: RarityTier.biaoZhun,
            lineageRole: LineageRole.founder,
            createdAt: DateTime.utc(2026, 8, 1),
            isFounder: true,
          ),
        );
        await IsarSetup.instance.towerProgress.put(
          TowerProgress()
            ..saveDataId = 1
            ..highestClearedFloor = 17
            ..highestClearedAt = DateTime.utc(2026, 8, 31)
            ..perFloorClearTimes = List<int>.filled(17, 1200)
            ..bestClearTime = 1200
            ..createdAt = DateTime.utc(2026, 8, 31),
        );
      });
      await IsarSetup.close();

      await IsarSetup.init(directory: tempDir, inspector: false);
      expect(
        (await IsarSetup.instance.saveDatas.get(0))!.saveVersion,
        '0.45.0',
      );
      expect(await IsarSetup.instance.towerPersonalRecords.count(), 0);
    },
  );
}
