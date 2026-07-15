import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

import '../support/isar_test_support.dart';

void main() {
  setUpAll(initializeTestIsarCore);

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_if_qi_migration_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) {
      await IsarSetup.close();
    }
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('0.35 旧档保护性补满永久内力并迁移心魔余毒', () async {
    final character = Character.create(
      name: '旧档角色',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026),
      internalForce: 700,
      internalForceMax: 3500,
      innerDemonResidueHoursRemaining: 8,
    )..id = 42;
    await IsarSetup.instance.writeTxn(() async {
      final save = await IsarSetup.currentSaveData();
      save!.saveVersion = '0.35.0';
      await IsarSetup.instance.saveDatas.put(save);
      await IsarSetup.instance.characters.put(character);
    });

    await IsarSetup.close();
    await IsarSetup.init(directory: tempDir, inspector: false);

    final migrated = await IsarSetup.instance.characters.get(42);
    expect(migrated!.internalForce, 3500);
    expect(migrated.innerBreathDisorderHoursRemaining, 8);
    expect(migrated.innerDemonResidueHoursRemaining, 0);
    expect((await IsarSetup.currentSaveData())!.saveVersion, '0.37.0');
  });
}
